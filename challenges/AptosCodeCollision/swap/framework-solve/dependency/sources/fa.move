module challenge::fa {
    use aptos_framework::object::{Self, Object};
    use aptos_framework::primary_fungible_store;
    use aptos_framework::fungible_asset::{Self, Metadata, MintRef, FungibleAsset};
    use aptos_framework::option;
    use aptos_framework::string::utf8;
    use challenge::package_manager;

    friend challenge::router;

    const OSEC: vector<u8> = b"OSEC";
    const MOVEBIT: vector<u8> = b"MOVEBIT";
    const ZELLIC: vector<u8> = b"ZELLIC";
    const JBZ: vector<u8> = b"JBZ";

    struct MintManaged has key, drop {
        osec_mint_ref: MintRef,
        movebit_mint_ref: MintRef,
        zellic_mint_ref: MintRef,
        jbz_mint_ref: MintRef,
    }

    public(friend) fun initialize()
        : (Object<Metadata>, Object<Metadata>, Object<Metadata>, Object<Metadata>) {

        let constructor_ref = &object::create_named_object(&package_manager::get_signer(), OSEC);
        primary_fungible_store::create_primary_store_enabled_fungible_asset(constructor_ref,
            option::none(),
            utf8(OSEC),
            utf8(OSEC),
            9,
            utf8(b"http://example.com/favicon.ico"),
            utf8(b"https://ctf.aptosfoundation.org/"),);

        let osec_mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
        let osec_fa = fungible_asset::mint(&osec_mint_ref, 1337);
        let osec_metadata = fungible_asset::metadata_from_asset(&osec_fa);
        primary_fungible_store::deposit(package_manager::get_address(), osec_fa);

        let constructor_ref = &object::create_named_object(&package_manager::get_signer(),
            MOVEBIT);
        primary_fungible_store::create_primary_store_enabled_fungible_asset(constructor_ref,
            option::none(),
            utf8(MOVEBIT),
            utf8(MOVEBIT),
            9,
            utf8(b"http://example.com/favicon.ico"),
            utf8(b"https://ctf.aptosfoundation.org/"),);

        let movebit_mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
        let movebit_fa = fungible_asset::mint(&movebit_mint_ref, 1337);
        let movebit_metadata = fungible_asset::metadata_from_asset(&movebit_fa);

        primary_fungible_store::deposit(package_manager::get_address(), movebit_fa);

        let constructor_ref = &object::create_named_object(&package_manager::get_signer(),
            ZELLIC);
        primary_fungible_store::create_primary_store_enabled_fungible_asset(constructor_ref,
            option::none(),
            utf8(ZELLIC),
            utf8(ZELLIC),
            9,
            utf8(b"http://example.com/favicon.ico"),
            utf8(b"https://ctf.aptosfoundation.org/"),);

        let zellic_mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
        let zellic_fa = fungible_asset::mint(&zellic_mint_ref, 1337);
        let zellic_metadata = fungible_asset::metadata_from_asset(&zellic_fa);

        primary_fungible_store::deposit(package_manager::get_address(), zellic_fa);

        let constructor_ref =
            &object::create_named_object(&package_manager::get_signer(), JBZ);
        primary_fungible_store::create_primary_store_enabled_fungible_asset(constructor_ref,
            option::none(),
            utf8(JBZ),
            utf8(JBZ),
            9,
            utf8(b"http://example.com/favicon.ico"),
            utf8(b"https://ctf.aptosfoundation.org/"),);

        let jbz_mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
        let jbz_fa = fungible_asset::mint(&jbz_mint_ref, 1337);
        let jbz_metadata = fungible_asset::metadata_from_asset(&jbz_fa);

        primary_fungible_store::deposit(package_manager::get_address(), jbz_fa);

        move_to(&package_manager::get_signer(),
            MintManaged { osec_mint_ref, movebit_mint_ref, zellic_mint_ref, jbz_mint_ref, });

        (osec_metadata, movebit_metadata, zellic_metadata, jbz_metadata)
    }

    public(friend) fun mint(_account: &signer)
        : (FungibleAsset, FungibleAsset, FungibleAsset,
        FungibleAsset) acquires MintManaged {
        let MintManaged { osec_mint_ref, movebit_mint_ref, zellic_mint_ref, jbz_mint_ref } = move_from(
            package_manager::get_address());
        (fungible_asset::mint(&osec_mint_ref, 100),
            fungible_asset::mint(&movebit_mint_ref, 100),
            fungible_asset::mint(&zellic_mint_ref, 10),
            fungible_asset::mint(&jbz_mint_ref, 0))
    }
}
