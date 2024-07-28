module solution::exploit {
    use challenge::router;
    use challenge::pool::{Self, LiquidityPool};
    use aptos_framework::fungible_asset;
    use aptos_framework::primary_fungible_store;

    use aptos_framework::object::{Self, Object};
    use std::vector;

    // osec, movebit, zellic, jdz init to 1337

    public entry fun solve(account: &signer) {
        let pools = pool::all_pools();
        vector::remove<Object<LiquidityPool>>(&mut pools, 0);
        vector::remove<Object<LiquidityPool>>(&mut pools, 0);
        // init hold: 100, 100, 10, 0
        // let (osec_fa, movebit_fa, zellic_fa, jbz_fa) = router::free_mint(account);
        // let osec_metadata = fungible_asset::metadata_from_asset(&osec_fa);
        // let movebit_metadata = fungible_asset::metadata_from_asset(&movebit_fa);
        // let zellic_metadata = fungible_asset::metadata_from_asset(&zellic_fa);
        // let jbz_metadata = fungible_asset::metadata_from_asset(&jbz_fa);
        // let addr1 = pool::liquidity_pool_address(osec_metadata, movebit_metadata, false);

        // let zero1 = fungible_asset::zero(osec_metadata);
        // let zero2 = fungible_asset::zero(movebit_metadata);
        // let zero1_metadata = fungible_asset::metadata_from_asset(&zero1);
        // let zero2_metadata = fungible_asset::metadata_from_asset(&zero2);
        // primary_fungible_store::ensure_primary_store_exists(addr1, zero1_metadata);
        // primary_fungible_store::ensure_primary_store_exists(addr1, zero2_metadata);


        // primary_fungible_store::deposit(signer::address_of(account), zero1);
        // primary_fungible_store::deposit(signer::address_of(account), zero2);
        // primary_fungible_store::deposit(signer::address_of(account), osec_fa);
        // primary_fungible_store::deposit(signer::address_of(account), movebit_fa);
        // primary_fungible_store::deposit(signer::address_of(account), zellic_fa);
        // primary_fungible_store::deposit(signer::address_of(account), jbz_fa);
    }
}
