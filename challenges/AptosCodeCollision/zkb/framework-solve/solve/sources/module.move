module solution::exploit {

    use zkb::verify;
    use std::bcs;
    use std::vector;

    public entry fun solve(account: &signer) {
        let know = verify::get_knowledge();
        let bytes = bcs::to_bytes(&know);
        let secret_value = vector::borrow(&bytes, 0);
        verify::prove(&mut know, (*secret_value as u64), account);
    }
}
