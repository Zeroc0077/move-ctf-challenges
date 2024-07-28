module challenge::sage {

    use aptos_framework::signer;
    use std::vector;

    struct ChallengeStatus has key {
        is_solved: bool,
    }

    public entry fun initialize(account: &signer) {
        let account_address = signer::address_of(account);
        assert!(account_address == @challenger, 0);
        move_to(account, ChallengeStatus { is_solved: false })

    }

    public entry fun challenge(m: vector<u64>, n: vector<u64>) acquires ChallengeStatus {

        let flag: vector<u64> = vector[
            12, 0, 7, 7, 37, 20, 25, 39, 10, 6, 35, 25, 43, 43, 26, 12, 28, 34, 37, 5, 22,
            9, 25, 4, 31, 8, 40, 38, 3, 27, 3, 24, 8, 0, 23, 38, 10, 5, 2, 16, 11, 37, 28,
            0, 18, 2, 12, 27, 40, 3, 11, 32, 24, 14, 2, 20, 12, 38, 30, 17, 21, 37, 26, 37,
            12, 28, 12, 27, 34, 24, 18, 32];

        if (build(m, n) == flag) {
            let challenge_status = borrow_global_mut<ChallengeStatus>(@challenger);
            challenge_status.is_solved = true;
        }
    }

    fun build(m: vector<u64>, n: vector<u64>): vector<u64> {
        let m1 = copy m;
        let text = &mut m1;
        let text_length = vector::length(text);
        assert!(text_length > 3, 0);

        if (text_length % 3 != 0) {
            if (3 - (text_length % 3) == 2) {
                vector::push_back(text, 0);
                vector::push_back(text, 0);
                text_length = text_length + 2;
            } else {
                vector::push_back(text, 0);
                text_length = text_length + 1;
            }
        };

        let next_text = vector::empty<u64>();
        vector::push_back(&mut next_text, 42);
        vector::push_back(&mut next_text, 11);
        vector::push_back(&mut next_text, 13);
        vector::push_back(&mut next_text, 16);
        vector::push_back(&mut next_text, 13);
        vector::push_back(&mut next_text, 62);
        vector::push_back(&mut next_text, 72);
        vector::push_back(&mut next_text, 13);
        vector::push_back(&mut next_text, 12);
        vector::append(&mut next_text, *text);
        text_length = text_length + 9;

        let n2 = copy n;
        let r = &mut n2;
        let x11 = *vector::borrow(r, 0);
        let x12 = *vector::borrow(r, 1);
        let x13 = *vector::borrow(r, 2);
        let x21 = *vector::borrow(r, 3);
        let x22 = *vector::borrow(r, 4);
        let x23 = *vector::borrow(r, 5);
        let x31 = *vector::borrow(r, 6);
        let x32 = *vector::borrow(r, 7);
        let x33 = *vector::borrow(r, 8);

        assert!(vector::length(r) == 9, 0);
        let i: u64 = 0;
        let end_text = vector::empty<u64>();
        while (i < text_length) {
            let y11 = *vector::borrow(&mut next_text, i + 0);
            let y21 = *vector::borrow(&mut next_text, i + 1);
            let y31 = *vector::borrow(&mut next_text, i + 2);

            let z11 = ((x11 + y31) * (x12 + y11) + (x13 * y21)) % 44;
            let z21 = ((x21 + y31) * (x22 + y11) + (x23 * y21)) % 44;
            let z31 = ((x31 + y31) * (x32 + y11) + (x33 * y21)) % 44;

            vector::push_back(&mut end_text, z11);
            vector::push_back(&mut end_text, z21);
            vector::push_back(&mut end_text, z31);

            i = i + 3;
        };

        end_text
    }

    public entry fun is_solved() acquires ChallengeStatus {
        let challenge_status = borrow_global_mut<ChallengeStatus>(@challenger);
        assert!(challenge_status.is_solved, 2);
    }
}
