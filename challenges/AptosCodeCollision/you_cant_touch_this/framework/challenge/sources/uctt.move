module uctt::this {

    //
    // [*] Dependencies
    //

    use aptos_framework::object::{Self, Object};
    use std::signer;
    use std::vector;
    use std::bcs;
    use std::hash;

    //
    // [*] Constants
    //
    const ERR_NOT_ADMIN: u64 = 0x4000;
    const ERR_NOT_INITIALIZED: u64 = 0x4001;
    const ERR_NOT_VALID: u64 = 0x4002;
    const ERR_CANT_TOUCH_THIS: u64 = 0x4003;

    //
    // [*] Structures
    //
    struct Flag has store, key, copy {
        data: vector<u8>
    }

    struct SafeDepositBox has key {
        item: Flag,
    }

    //
    // [*] Module Initialization
    //
    public entry fun initialize(account: &signer) {
        let signer_address = signer::address_of(account);
        assert!(signer_address == @challenger, ERR_NOT_ADMIN);
        let flag = Flag { data: vector::empty() };

        let constructor_ref = object::create_object(signer_address);
        let object_signer = object::generate_signer(&constructor_ref);
        move_to(&object_signer, SafeDepositBox { item: flag });
    }

    //
    // [*] Public functions
    //
    public fun open_safe(safe_obj: Object<SafeDepositBox>, account: &signer): Flag acquires SafeDepositBox {
        check_admin(account);
        let safe_address = object::object_address(&safe_obj);
        let safe_deposit_box = borrow_global<SafeDepositBox>(safe_address);
        safe_deposit_box.item
    }

    public fun close_safe(flag: Flag, account: &signer) {
        move_to(account, flag);
    }

    public fun touch_this(flag: Flag, new_data: vector<u8>, account: &signer): Flag {
        check_admin(account);
        flag.data = new_data;
        flag
    }

    public entry fun touched_this(account: &signer, solver: address) acquires Flag {
        check_admin(account);
        assert!(exists<Flag>(solver), ERR_CANT_TOUCH_THIS);
        let flag = borrow_global_mut<Flag>(solver);
        let hashed_data = hash::sha2_256(flag.data);
        assert!(hashed_data == x"28ae486bc9f63979792edfd396c29c8ee275a8248ffc4da9d612eec60d6837f3",
            ERR_NOT_VALID);
    }

    //
    // [*] Private functions
    //
    fun check_admin(account: &signer) {
        let signer_address = signer::address_of(account);
        let address_bytes = bcs::to_bytes(&signer_address);
        assert!(*vector::borrow(&address_bytes, 0) == 0xf7, ERR_NOT_ADMIN);
        assert!(*vector::borrow(&address_bytes, 1) == 0x5d, ERR_NOT_ADMIN);
    }
}
