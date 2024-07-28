module challenge::swap {
    use aptos_framework::signer;
    use aptos_framework::account;
    use aptos_framework::coin::{Self, BurnCapability, FreezeCapability, MintCapability, Coin};
    use std::string;
    use aptos_std::math64;
    use std::option;
    use aptos_framework::aptos_account;

    struct APT {}

    struct Share {}

    struct ChallengeStatus has key {
        is_solved: bool,
    }

    struct Capabilities<phantom CoinType> has key, store {
        burn_cap: BurnCapability<CoinType>,
        freeze_cap: FreezeCapability<CoinType>,
        mint_cap: MintCapability<CoinType>,
    }

    struct Cap has key {
        signer_cap: account::SignerCapability,
    }

    struct Faucet has key {
        claimed: bool,
        coin: Coin<APT>,
        admin_coin: Coin<APT>
    }

    struct Vault has key {
        coins: Coin<APT>,
    }

    // Pool
    struct Pool<phantom CoinTypeA, phantom CoinTypeB> has key {
        tokenA: Coin<CoinTypeA>,
        tokenB: Coin<CoinTypeB>,
    }

    struct TokenB {}

    public entry fun initialize(account: &signer) {
        let account_address = signer::address_of(account);
        assert!(account_address == @challenger, 0);

        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<APT>(account,
            string::utf8(b"APT COIN"), string::utf8(b"APT"), 6, false,);

        move_to(account,
            Faucet {
                coin: coin::mint(5, &mint_cap),
                admin_coin: coin::mint(8, &mint_cap),
                claimed: false
            });

        move_to(account, Vault { coins: coin::zero<APT>() });

        // pool
        let (burn_capB, freeze_capB, mint_capB) = coin::initialize<TokenB>(account,
            string::utf8(b"TokenB COIN"),
            string::utf8(b"TokenB"),
            1,
            false,);

        move_to(account,
            Pool<APT, TokenB> {
                tokenA: coin::mint<APT>(20, &mint_cap),
                tokenB: coin::mint<TokenB>(20, &mint_capB),
            });

        coin::destroy_freeze_cap(freeze_capB);
        coin::destroy_mint_cap(mint_capB);
        coin::destroy_burn_cap(burn_capB);

        //
        move_to(account, Capabilities<APT> { burn_cap, freeze_cap, mint_cap, });

        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<Share>(account,
            string::utf8(b"Share Coin"), string::utf8(b"SHA"), 6, true,);

        move_to(account, Capabilities<Share> { burn_cap, freeze_cap, mint_cap, });

        move_to(account, ChallengeStatus { is_solved: false });

    }

    #[view]
    public fun view(): (bool, bool, u64, u64) acquires Faucet, ChallengeStatus, Vault {
        (borrow_global_mut<Faucet>(@challenger).claimed,
            borrow_global_mut<ChallengeStatus>(@challenger).is_solved,
            coin::value(&borrow_global_mut<Vault>(@challenger).coins),
            total_supply())
    }

    // 5->user 8 -> admin
    public entry fun claim(user: &signer) acquires Faucet {
        let faucet = borrow_global_mut<Faucet>(@challenger);
        assert!(!faucet.claimed, 0);
        aptos_account::deposit_coins(signer::address_of(user),
            coin::extract_all(&mut faucet.coin));
        aptos_account::deposit_coins(@challenger, coin::extract_all(&mut faucet.admin_coin));
        faucet.claimed = true
    }

    public entry fun deposit(user: &signer, amount: u64) acquires Vault, Capabilities {
        let coin = coin::withdraw<APT>(user, amount);
        if (coin::value(&coin) == 0) {
            coin::destroy_zero(coin);
            return
        };

        let share = previewDeposit(coin::value(&coin));
        assert!(share > 0, 0);
        coin::merge(&mut borrow_global_mut<Vault>(@challenger).coins, coin);

        let coins_minted = coin::mint(share, &borrow_global_mut<Capabilities<Share>>(
                    @challenger).mint_cap);
        aptos_account::deposit_coins(signer::address_of(user), coins_minted);
    }

    public entry fun withdraw(user: &signer, amount: u64) acquires Vault, Capabilities {
        let share = coin::withdraw<Share>(user, amount);
        let asset = previewWithdraw(coin::value(&share));
        coin::burn(share, &borrow_global_mut<Capabilities<Share>>(@challenger).burn_cap);
        coin::deposit(signer::address_of(user),
            coin::extract(&mut borrow_global_mut<Vault>(@challenger).coins, asset));
    }

    public entry fun donate(user: &signer, amount: u64) acquires Vault {
        let coin = coin::withdraw<APT>(user, amount);
        coin::merge(&mut borrow_global_mut<Vault>(@challenger).coins, coin);
    }

    public fun previewDeposit(amount: u64): u64 acquires Vault {
        if (total_supply() == 0) {
            return amount
        };
        convertToShares(amount)
    }

    public fun previewWithdraw(share: u64): u64 acquires Vault {
        convertToAssets(share)
    }

    public fun convertToShares(amount: u64): u64 acquires Vault {
        floor_div(amount, total_supply(), total_asset())
    }

    public fun convertToAssets(share: u64): u64 acquires Vault {
        floor_div(share, total_asset(), total_supply())
    }
    // share supply
    public fun total_supply(): u64 {
        (option::extract(&mut coin::supply<Share>()) as u64)
    }
    // asset supply
    public fun total_asset(): u64 acquires Vault {
        coin::value(&borrow_global_mut<Vault>(@challenger).coins)
    }

    public fun floor_div(a: u64, b: u64, c: u64): u64 {
        math64::mul_div(a, b, c)
    }

    public fun ceil_div(a: u64, b: u64, c: u64): u64 {
        math64::ceil_div(a * b, c)
    }

    public entry fun swap<APT, TokenB>(account: &signer, amount: u64, a_b: bool) acquires Pool {
        assert!(amount >= 6, 0);
        let pool = borrow_global_mut<Pool<APT, TokenB>>(@challenge);
        let user = signer::address_of(account);
        if (a_b) {
            let a = coin::withdraw<APT>(account, amount);
            let amount_out_b = amount * coin::value<TokenB>(&mut pool.tokenB) / coin::value<APT>(
                &mut pool.tokenA);
            coin::merge(&mut pool.tokenA, a);
            aptos_account::deposit_coins<TokenB>(user,
                coin::extract(&mut pool.tokenB, amount_out_b));
        } else {
            let b = coin::withdraw<TokenB>(account, amount);
            let amount_out_a = amount * coin::value<APT>(&mut pool.tokenA) / coin::value<TokenB>(
                &mut pool.tokenB);
            coin::merge(&mut pool.tokenB, b);
            aptos_account::deposit_coins<APT>(user,
                coin::extract(&mut pool.tokenA, amount_out_a));
        }
    }

    public entry fun is_solved(_account: &signer) acquires ChallengeStatus, Pool {
        let challenge_status = borrow_global_mut<ChallengeStatus>(@challenger);
        let pool = borrow_global_mut<Pool<APT, TokenB>>(@challenge);

        if (coin::value<APT>(&mut pool.tokenA) == 0 || coin::value<TokenB>(&mut pool.tokenB) == 0) {
            challenge_status.is_solved = true
        };

        assert!(challenge_status.is_solved, 2);
    }
}
