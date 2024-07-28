module solution::exploit {
    use challenge::welcome;

    public entry fun solve(account: &signer) {
        welcome::solve(account);
    }
}
