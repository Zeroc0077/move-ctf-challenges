module challenge::pool {
    use aptos_framework::object::{Self, Object, ConstructorRef};
    use aptos_framework::primary_fungible_store;
    use aptos_framework::fungible_asset::{Self, FungibleAsset, Metadata,};
    use aptos_framework::signer::address_of;
    use aptos_std::smart_vector::{Self, SmartVector};
    use std::string::{Self, String};
    use std::vector;
    use aptos_framework::math64;
    use aptos_framework::comparator;
    use challenge::package_manager;

    friend challenge::router;

    const FEE_SCALE: u64 = 10000;

    struct LiquidityPoolConfigs has key {
        all_pools: SmartVector<Object<LiquidityPool>>,
        is_paused: bool,
        fee_manager: address,
        pauser: address,
        pending_fee_manager: address,
        pending_pauser: address,
        stable_fee_bps: u64,
        volatile_fee_bps: u64,
    }

    struct LiquidityPool has key {
        metadata_1: Object<Metadata>,
        metadata_2: Object<Metadata>,
        fees_1: u128,
        fees_2: u128,
        swap_fee: u64,
        is_stable: bool,
    }

    public(friend) fun initialize() {
        let swap_signer = &package_manager::get_signer();
        move_to(swap_signer,
            LiquidityPoolConfigs {
                all_pools: smart_vector::new(),
                is_paused: false,
                fee_manager: package_manager::get_address(),
                pauser: package_manager::get_address(),
                pending_fee_manager: @0x0,
                pending_pauser: @0x0,
                stable_fee_bps: 100, // 1%
                volatile_fee_bps: 200, // 2%
            });
    }

    public(friend) fun create(
        token_1: Object<Metadata>, token_2: Object<Metadata>, is_stable: bool,
    ): Object<LiquidityPool> acquires LiquidityPoolConfigs {
        if (!is_sorted(token_1, token_2)) {
            return create(token_2, token_1, is_stable)
        };
        let configs = mut_liquidity_pool_config();

        let pool_constructor_ref = create_pool(token_1, token_2, is_stable);
        let pool_signer = &object::generate_signer(pool_constructor_ref);
        let pool_address = address_of(pool_signer);
        primary_fungible_store::ensure_primary_store_exists(pool_address, token_1);
        primary_fungible_store::ensure_primary_store_exists(pool_address, token_2);
        move_to(pool_signer,
            LiquidityPool {
                metadata_1: token_1,
                metadata_2: token_2,
                fees_1: 0,
                fees_2: 0,
                swap_fee: if (is_stable) {
                    configs.stable_fee_bps
                } else {
                    configs.volatile_fee_bps
                },
                is_stable,
            });
        let pool =
            object::object_from_constructor_ref<LiquidityPool>(pool_constructor_ref);
        smart_vector::push_back(&mut configs.all_pools, pool);

        pool
    }

    public(friend) fun swap_a_2_b(
        pool: &Object<LiquidityPool>, from: FungibleAsset, is_stable: bool
    ): FungibleAsset acquires LiquidityPool, LiquidityPoolConfigs {
        assert!(!liquidity_pool_config().is_paused, 0);

        let from_token = fungible_asset::metadata_from_asset(&from);
        let amount_in = fungible_asset::amount(&from);
        let (amount_out, fees_amount) = get_amount_out(pool, from_token, amount_in);

        let k_before = calculate_constant_k(pool);
        let pool_data = mut_liquidity_pool_data(pool);

        let swap_signer = &package_manager::get_signer();
        let swap_address = address_of(swap_signer);
        let fees_amount = (fees_amount as u128);
        let out = if (from_token == pool_data.metadata_1) {
            primary_fungible_store::deposit(swap_address, from);
            pool_data.fees_1 = pool_data.fees_1 + fees_amount;
            primary_fungible_store::withdraw(swap_signer, pool_data.metadata_2, amount_out)
        } else {
            primary_fungible_store::deposit(swap_address, from);
            pool_data.fees_2 = pool_data.fees_2 + fees_amount;
            primary_fungible_store::withdraw(swap_signer, pool_data.metadata_1, amount_out)
        };

        let k_after = calculate_constant_k(pool);

        if (!is_stable) {
            assert!(k_before != k_after, 0);
        };
        out
    }

    public(friend) fun swap_b_2_a(
        pool: &Object<LiquidityPool>, from: FungibleAsset, is_stable: bool
    ): FungibleAsset acquires LiquidityPool, LiquidityPoolConfigs {
        assert!(!liquidity_pool_config().is_paused, 0);

        let from_token = fungible_asset::metadata_from_asset(&from);
        let amount_in = fungible_asset::amount(&from);
        let (amount_out, fees_amount) = get_amount_out(pool, from_token, amount_in);

        let k_before = calculate_constant_k(pool);
        let pool_data = mut_liquidity_pool_data(pool);

        let swap_signer = &package_manager::get_signer();
        let swap_address = address_of(swap_signer);
        let fees_amount = (fees_amount as u128);
        let out = if (from_token == pool_data.metadata_2) {
            primary_fungible_store::deposit(swap_address, from);
            pool_data.fees_2 = pool_data.fees_2 + fees_amount;
            primary_fungible_store::withdraw(swap_signer, pool_data.metadata_1, amount_out)
        } else {
            primary_fungible_store::deposit(swap_address, from);
            pool_data.fees_1 = pool_data.fees_1 + fees_amount;
            primary_fungible_store::withdraw(swap_signer, pool_data.metadata_2, amount_out)
        };

        let k_after = calculate_constant_k(pool);
        if (!is_stable) {
            assert!(k_before != k_after, 0);
        };

        out
    }

    public(friend) fun claim_fees(
        account: &signer, pool: &Object<LiquidityPool>
    ): (FungibleAsset, FungibleAsset) acquires LiquidityPool, LiquidityPoolConfigs {

        let pool_configs = liquidity_pool_config();
        assert!(address_of(account) == pool_configs.fee_manager, 0);

        let pool_data = mut_liquidity_pool_data(pool);

        let claimable_1 = pool_data.fees_1;
        let claimable_2 = pool_data.fees_2;

        let swap_signer = &package_manager::get_signer();
        let fees_1 = if (claimable_1 > 0) {
            primary_fungible_store::withdraw(swap_signer, pool_data.metadata_2, (
                    claimable_1 as u64
                ))
        } else {
            fungible_asset::zero(pool_data.metadata_2)
        };
        let fees_2 = if (claimable_2 > 0) {
            primary_fungible_store::withdraw(swap_signer, pool_data.metadata_1, (
                    claimable_2 as u64
                ))
        } else {
            fungible_asset::zero(pool_data.metadata_1)
        };
        pool_data.fees_1 = 0;
        pool_data.fees_2 = 0;

        (fees_1, fees_2)
    }

    public entry fun set_pauser(pauser: &signer, new_pauser: address) acquires LiquidityPoolConfigs {
        let pool_configs = mut_liquidity_pool_config();
        assert!(pool_configs.pauser == address_of(pauser), 0);
        pool_configs.pending_pauser = new_pauser;
    }

    public entry fun accept_pauser(new_pauser: &signer) acquires LiquidityPoolConfigs {
        let pool_configs = mut_liquidity_pool_config();
        assert!(address_of(new_pauser) == pool_configs.pending_pauser, 0);
        pool_configs.pauser = pool_configs.pending_pauser;
        pool_configs.pending_pauser = @0x0;
    }

    public entry fun set_pause(pauser: &signer, is_paused: bool) acquires LiquidityPoolConfigs {
        let pool_configs = mut_liquidity_pool_config();
        assert!(pool_configs.pauser == address_of(pauser), 0);
        pool_configs.is_paused = is_paused;
    }

    public entry fun set_fee_manager(
        fee_manager: &signer, new_fee_manager: address
    ) acquires LiquidityPoolConfigs {
        let pool_configs = mut_liquidity_pool_config();
        assert!(address_of(fee_manager) == new_fee_manager, 0);
        pool_configs.pending_fee_manager = new_fee_manager;
    }

    public entry fun accept_fee_manager(new_fee_manager: &signer) acquires LiquidityPoolConfigs {
        let pool_configs = mut_liquidity_pool_config();
        assert!(address_of(new_fee_manager) == pool_configs.pending_fee_manager, 0);
        pool_configs.fee_manager = pool_configs.pending_fee_manager;
        pool_configs.pending_fee_manager = @0x0;
    }

    public fun liquidity_pool_address(
        token_1: Object<Metadata>, token_2: Object<Metadata>, is_stable: bool,
    ): address {
        object::create_object_address(&package_manager::get_address(),
            get_pool_seeds(token_1, token_2, is_stable))
    }

    public fun balance_1(pool: &Object<LiquidityPool>): u64 acquires LiquidityPool {
        let metadata_1 = liquidity_pool_data(pool).metadata_1;
        primary_fungible_store::balance(package_manager::get_address(), metadata_1)
    }

    public fun balance_2(pool: &Object<LiquidityPool>): u64 acquires LiquidityPool {
        let metadata_2 = liquidity_pool_data(pool).metadata_2;
        primary_fungible_store::balance(package_manager::get_address(), metadata_2)
    }

    public fun fees_1(pool: &Object<LiquidityPool>): u128 acquires LiquidityPool {
        let pool_data = liquidity_pool_data(pool);
        pool_data.fees_1
    }

    public fun fees_2(pool: &Object<LiquidityPool>): u128 acquires LiquidityPool {
        let pool_data = liquidity_pool_data(pool);
        pool_data.fees_2
    }

    public fun get_amount_out(
        pool: &Object<LiquidityPool>, from: Object<Metadata>, amount_in: u64,
    ): (u64, u64) acquires LiquidityPool {

        let reserve_1 = (balance_1(pool) as u256);
        let reserve_2 = (balance_2(pool) as u256);
        let pool_data = liquidity_pool_data(pool);

        let (reserve_in, reserve_out) =
            if (from == pool_data.metadata_1) { (reserve_1, reserve_2) }
            else { (reserve_2, reserve_1) };

        let fees_amount = math64::mul_div(amount_in, pool_data.swap_fee, FEE_SCALE);
        let amount_in = ((amount_in - fees_amount) as u256);
        let amount_out =
            if (pool_data.is_stable) {
                let k = calculate_constant_k(pool);
                reserve_out - get_y(amount_in + reserve_in, k, reserve_out)
            } else {
                amount_in * reserve_out / (reserve_in + amount_in)
            };
        ((amount_out as u64), fees_amount)
    }

    #[view]
    public fun is_sorted(token_1: Object<Metadata>, token_2: Object<Metadata>): bool {
        let token_1_addr = object::object_address(&token_1);
        let token_2_addr = object::object_address(&token_2);
        comparator::is_smaller_than(&comparator::compare(&token_1_addr, &token_2_addr))
    }

    #[view]
    public fun all_pools(): vector<Object<LiquidityPool>> acquires LiquidityPoolConfigs {
        let all_pools = &liquidity_pool_config().all_pools;
        let results = vector[];
        let len = smart_vector::length(all_pools);
        let i = 0;
        while (i < len) {
            vector::push_back(&mut results, *smart_vector::borrow(all_pools, i));
            i = i + 1;
        };
        results
    }

    public fun get_total_fees(pool: &Object<LiquidityPool>): u128 acquires LiquidityPool {
        let pool_data = liquidity_pool_data(pool);
        pool_data.fees_1 + pool_data.fees_2
    }

    fun get_y(x0: u256, xy: u256, y: u256): u256 {
        let i = 0;
        while (i < 255) {
            let y_prev = y;
            let k = f(x0, y);
            if (k < xy) {
                let dy = (xy - k) / d(x0, y);
                y = y + dy;
            } else {
                let dy = (k - xy) / d(x0, y);
                y = y - dy;
            };
            if (y > y_prev) {
                if (y - y_prev <= 1) {
                    return y
                }
            } else {
                if (y_prev - y <= 1) {
                    return y
                }
            };
            i = i + 1;
        };
        y
    }

    // inline functionss
    inline fun create_pool(
        token_1: Object<Metadata>, token_2: Object<Metadata>, is_stable: bool,
    ): &ConstructorRef {
        let seeds = get_pool_seeds(token_1, token_2, is_stable);
        let lp_token_constructor_ref = &object::create_named_object(&package_manager::get_signer(),
            seeds);

        lp_token_constructor_ref
    }

    inline fun get_pool_seeds(
        token_1: Object<Metadata>, token_2: Object<Metadata>, _is_stable: bool
    ): vector<u8> {
        let token_symbol = lp_token_name(token_1, token_2);
        let seeds = *string::bytes(&token_symbol);
        seeds
    }

    inline fun lp_token_name(
        token_1: Object<Metadata>, token_2: Object<Metadata>
    ): String {
        let token_symbol = string::utf8(b"LP-");
        string::append(&mut token_symbol, fungible_asset::symbol(token_1));
        string::append_utf8(&mut token_symbol, b"-");
        string::append(&mut token_symbol, fungible_asset::symbol(token_2));
        token_symbol
    }

    inline fun mut_liquidity_pool_config(): &mut LiquidityPoolConfigs acquires LiquidityPoolConfigs {
        borrow_global_mut<LiquidityPoolConfigs>(package_manager::get_address())
    }

    inline fun liquidity_pool_config(): &LiquidityPoolConfigs acquires LiquidityPoolConfigs {
        borrow_global<LiquidityPoolConfigs>(package_manager::get_address())
    }

    inline fun liquidity_pool_data<T: key>(pool: &Object<T>): &LiquidityPool acquires LiquidityPool {
        borrow_global<LiquidityPool>(object::object_address(pool))
    }

    inline fun mut_liquidity_pool_data<T: key>(pool: &Object<T>): &mut LiquidityPool acquires LiquidityPool {
        borrow_global_mut<LiquidityPool>(object::object_address(pool))
    }

    inline fun calculate_constant_k(pool: &Object<LiquidityPool>): u256 acquires LiquidityPool {
        let r1 = (balance_1(pool) as u256);
        let r2 = (balance_2(pool) as u256);

        if (liquidity_pool_data(pool).is_stable) {
            r1 * r1 * r1 * r2 + r2 * r2 * r2 * r1
        } else {
            r1 * r2
        }
    }

    inline fun f(x0: u256, y: u256): u256 {

        x0 * (y * y * y) + (x0 * x0 * x0) * y
    }

    inline fun d(x0: u256, y: u256): u256 {
        3 * x0 * (y * y) + (x0 * x0 * x0)
    }
}
