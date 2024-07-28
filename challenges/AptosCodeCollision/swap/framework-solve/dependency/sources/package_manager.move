module challenge::package_manager {
    use aptos_framework::object::{Self, ExtendRef};
    use aptos_framework::signer::address_of;

    friend challenge::router;
    friend challenge::pool;
    friend challenge::fa;

    struct Config has key {
        extend_ref: ExtendRef,
    }

    public(friend) fun initialize(account: &signer) {
        let constructor_ref = object::create_sticky_object(address_of(account));
        move_to(account, Config { extend_ref: object::generate_extend_ref(&constructor_ref), });
    }

    public(friend) fun get_signer(): signer acquires Config {
        object::generate_signer_for_extending(&borrow_global<Config>(@challenger).extend_ref)
    }

    public(friend) fun get_address(): address acquires Config {
        address_of(&object::generate_signer_for_extending(&borrow_global<Config>(
                        @challenger).extend_ref))
    }
}
