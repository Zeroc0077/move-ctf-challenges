module challenge::flag {

    friend challenge::router;

    struct ChallengeStatus has key {
        is_solved: bool,
    }

    public(friend) entry fun create(account: &signer) {
        move_to(account, ChallengeStatus { is_solved: false, })
    }

    public(friend) entry fun modify_value() acquires ChallengeStatus {
        let challenge_status = borrow_global_mut<ChallengeStatus>(@challenger);
        challenge_status.is_solved = true;

    }

    public(friend) entry fun assert_solved() acquires ChallengeStatus {
        let challenge_status = borrow_global_mut<ChallengeStatus>(@challenger);
        assert!(challenge_status.is_solved, 1);

    }
}
