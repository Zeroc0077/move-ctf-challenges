module challenge::router {
    use challenge::package_manager;
    use challenge::pool::{Self, LiquidityPool};
    use challenge::fa;
    use aptos_framework::signer::address_of;
    use aptos_framework::vector;
    use aptos_framework::object::{Self, Object};
    use aptos_framework::fungible_asset::{Self, Metadata, FungibleAsset};

    public entry fun initialize(account: &signer) {
        assert!(address_of(account) == @challenger, 0);
        package_manager::initialize(account);
        pool::initialize();
        let (osec_metadata, movebit_metadata, zellic_metadata, jbz_metadata) = fa::initialize();
        create_pool(osec_metadata, movebit_metadata, false);
        create_pool(zellic_metadata, jbz_metadata, true);
    }

    public fun free_mint(account: &signer)
        : (FungibleAsset, FungibleAsset, FungibleAsset,
        FungibleAsset) {
        fa::mint(account)
    }

    fun create_pool(
        token1: Object<Metadata>, token2: Object<Metadata>, is_stable: bool
    ) {
        pool::create(token1, token2, is_stable);
    }

    public fun swap_a_2_b(
        token_1: FungibleAsset, token_2: Object<Metadata>, is_stable: bool,
    ): FungibleAsset {
        let pool = object::address_to_object<LiquidityPool>(pool::liquidity_pool_address(
                fungible_asset::metadata_from_asset(&token_1), token_2, is_stable));
        pool::swap_a_2_b(&pool, token_1, is_stable)
    }

    public fun swap_b_2_a(
        token_1: Object<Metadata>, token_2: FungibleAsset, is_stable: bool,
    ): FungibleAsset {
        let pool = object::address_to_object<LiquidityPool>(pool::liquidity_pool_address(token_1,
                fungible_asset::metadata_from_asset(&token_2), is_stable));
        pool::swap_b_2_a(&pool, token_2, is_stable)
    }

    public fun claim_fees(
        account: &signer, token_1: Object<Metadata>, token_2: Object<Metadata>, is_stable: bool
    ): (FungibleAsset, FungibleAsset) {
        let pool = object::address_to_object<LiquidityPool>(pool::liquidity_pool_address(token_1,
                token_2, is_stable));
        pool::claim_fees(account, &pool)
    }

    public fun balance(
        token_1: Object<Metadata>, token_2: Object<Metadata>, is_stable: bool
    ): (u64, u64) {
        let pool = object::address_to_object<LiquidityPool>(pool::liquidity_pool_address(token_1,
                token_2, is_stable));
        (pool::balance_1(&pool), pool::balance_2(&pool))
    }

    public fun fees(
        token_1: Object<Metadata>, token_2: Object<Metadata>, is_stable: bool
    ): (u128, u128) {
        let pool = object::address_to_object<LiquidityPool>(pool::liquidity_pool_address(token_1,
                token_2, is_stable));
        (pool::fees_1(&pool), pool::fees_2(&pool))
    }

    public entry fun is_solved(_account: &signer) {
        let pools = pool::all_pools();
        let length = vector::length(&pools);
        let i = 0;
        while (i < length) {
            let pool = vector::borrow(&mut pools, i);
            assert!(0 == pool::get_total_fees(pool), 0);
            assert!(0 == pool::balance_1(pool), 0);
            assert!(0 == pool::balance_2(pool), 0);
            i = i + 1;

        };
    }
}
