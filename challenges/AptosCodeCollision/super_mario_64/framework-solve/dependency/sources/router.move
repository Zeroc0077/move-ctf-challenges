module challenge::router {
    use aptos_framework::signer;
    use aptos_framework::object::{Object, ExtendRef, Self};
    #[resource_group(scope = global)]
    struct MushroomWorld {}

    #[resource_group_member(group = challenge::router::MushroomWorld)]
    struct Config has key {
        game: address,
        extend_ref: ExtendRef,
        wrapper: address,
    }

    #[resource_group_member(group = challenge::router::MushroomWorld)]
    struct Peach has key {
        kidnapped: bool
    }

    #[resource_group_member(group = challenge::router::MushroomWorld)]
    struct Bowser has key {
        hp: u8
    }

    #[resource_group_member(group = challenge::router::MushroomWorld)]
    struct Mario has key {
        hp: u8
    }

    struct Start has key {}

    public entry fun initialize(account: &signer) acquires Bowser {
        let account_address = signer::address_of(account);
        assert!(account_address == @challenger, 0);

        let constructor_ref = &object::create_object(account_address);
        let sender_object_signer = &object::generate_signer(constructor_ref);
        let extend_ref = object::generate_extend_ref(constructor_ref);

        let constructor_ref_wrapper =
            &object::create_object(signer::address_of(sender_object_signer));
        let object_wrapper_signer = &object::generate_signer(constructor_ref_wrapper);

        move_to(object_wrapper_signer, Peach { kidnapped: true });
        move_to(object_wrapper_signer, Bowser { hp: 0 });
        move_to(object_wrapper_signer, Mario { hp: 0 });

        let bowser = object::address_to_object<Bowser>(signer::address_of(
                object_wrapper_signer));

        move_to(account,
            Config {
                game: signer::address_of(sender_object_signer),
                extend_ref: extend_ref,
                wrapper: signer::address_of(object_wrapper_signer)
            });
        set_hp(sender_object_signer, bowser, 254);
    }

    public fun set_hp(account: &signer, bowser_obj: Object<Bowser>, hp: u8) acquires Bowser {
        assert!(object::owner(bowser_obj) == signer::address_of(account), 1);
        let bowser = borrow_global_mut<Bowser>(object::object_address(&bowser_obj));
        bowser.hp = hp
    }

    public fun start_game(account: &signer): address {
        let account_address = signer::address_of(account);
        assert!(!exists<Start>(account_address), 1);
        move_to(account, Start {});
        let constructor_ref = &object::create_object(account_address);
        let sender_object_signer = &object::generate_signer(constructor_ref);

        move_to(sender_object_signer, Mario { hp: 0 });
        object::address_from_constructor_ref(constructor_ref)
    }

    public fun train_mario(account: &signer, mario_obj: Object<Mario>) acquires Mario {
        let account_address = signer::address_of(account);
        assert!(object::owner(mario_obj) == account_address, 2);
        let mario = borrow_global_mut<Mario>(object::object_address(&mario_obj));

        mario.hp = mario.hp + 2;
    }

    public fun battle(account: &signer, mario_obj: Object<Mario>) acquires Config, Bowser, Mario, Peach {
        let account_address = signer::address_of(account);
        let mario = borrow_global<Mario>(object::object_address(&mario_obj));

        let config = borrow_global<Config>(@challenger);
        let game_address = config.game;
        let wrapper_signer = &object::generate_signer_for_extending(&config.extend_ref);
        let bowser = borrow_global<Bowser>(config.wrapper);

        if (mario.hp > bowser.hp) {
            let peach = borrow_global_mut<Peach>(config.wrapper);
            peach.kidnapped = false;
        } else {
            object::burn(account, mario_obj);
            if (mario.hp == bowser.hp) {
                //oh really close, take my mario and try again
                let wrapper_signer = &object::generate_signer_for_extending(&config.extend_ref);
                let my_mario_obj = object::address_to_object<Mario>(config.wrapper);
                object::transfer(wrapper_signer, my_mario_obj, account_address);
            }
        }
    }

    #[view]
    public fun get_game(): address acquires Config {
        borrow_global<Config>(@challenger).game
    }

    #[view]
    public fun get_wrapper(): address acquires Config {
        borrow_global<Config>(@challenger).wrapper
    }

    public entry fun is_solved(_account: &signer) acquires Config, Peach {
        let peach = borrow_global<Peach>(get_wrapper());
        assert!(!peach.kidnapped, 4);
    }
}
