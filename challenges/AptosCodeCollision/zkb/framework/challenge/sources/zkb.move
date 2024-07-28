module zkb::verify {

    //
    // [*] Dependencies
    //

    use std::signer;

    //
    // [*] Constants
    //
    const ERR_NOT_ADMIN: u64 = 0x4000;
    const ERR_NOT_INITIALIZED: u64 = 0x4001;
    const ERR_NOT_PROVED: u64 = 0x4002;

    //
    // [*] Structures
    //
    struct ProofStatus has key, store {
        proofs: u64
    }

    struct Knowledge has key, drop, copy {
        value: u64
    }

    //
    // [*] Module Initialization
    //
    public entry fun initialize(account: &signer) {
        assert!(signer::address_of(account) == @challenger, ERR_NOT_ADMIN);
        move_to(account, ProofStatus { proofs: 0 });
        move_to(account, Knowledge { value: 0 });
    }

    //
    // [*] Public functions
    //
    public fun prove(
        knowledge: &mut Knowledge, secret_number: u64, _account: &signer
    ) acquires ProofStatus {
        if (knowledge.value != 0) {
            if (knowledge.value == secret_number) {
                if (exists<ProofStatus>(@challenger)) {
                    let challenge_status = borrow_global_mut<ProofStatus>(@challenger);
                    challenge_status.proofs = challenge_status.proofs + 1;
                    knowledge.value = 0;
                };
            };
        };
    }

    public entry fun set_knowledge(account: &signer, value: u64) acquires Knowledge {
        assert!(signer::address_of(account) == @challenger, ERR_NOT_ADMIN);
        assert!(exists<Knowledge>(@challenger), ERR_NOT_INITIALIZED);
        let knowledge = borrow_global_mut<Knowledge>(@challenger);
        knowledge.value = value;
    }

    public entry fun is_proved(_account: &signer) acquires ProofStatus {
        assert!(exists<ProofStatus>(@challenger), ERR_NOT_INITIALIZED);
        let challenge_status = borrow_global_mut<ProofStatus>(@challenger);
        assert!(challenge_status.proofs >= 3, ERR_NOT_PROVED);
    }

    #[view]
    public fun get_knowledge(): Knowledge acquires Knowledge {
        assert!(exists<Knowledge>(@challenger), ERR_NOT_INITIALIZED);
        *borrow_global<Knowledge>(@challenger)
    }
}
