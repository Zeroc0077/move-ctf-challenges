module 0x1337::source {
    public fun a0() : vector<u8> {
        magic_1(b"etpkw", 4)
    }
    
    public fun a1() : vector<u8> {
        magic_2(b"zrn^", 1)
    }
    
    public fun a10() : vector<u8> {
        magic_2(b"bW", 10)
    }
    
    public fun a2() : vector<u8> {
        magic_3(b"_uoy")
    }
    
    public fun a3() : vector<u8> {
        magic_1(b"i`wd", 1)
    }
    
    public fun a4() : vector<u8> {
        magic_2(b"]jc_", 2)
    }
    
    public fun a5() : vector<u8> {
        magic_1(b"qmfg", 3)
    }
    
    public fun a6() : vector<u8> {
        magic_3(b"woh_")
    }
    
    public fun a7() : vector<u8> {
        magic_2(b"^sn^", 1)
    }
    
    public fun a8() : vector<u8> {
        magic_1(b"qwa[", 4)
    }
    
    public fun a9() : vector<u8> {
        magic_3(b"ever")
    }
    
    public fun get_flag() : vector<u8> {
        let v0 = a0();
        0x1::vector::append<u8>(&mut v0, a1());
        0x1::vector::append<u8>(&mut v0, a2());
        0x1::vector::append<u8>(&mut v0, a3());
        0x1::vector::append<u8>(&mut v0, a4());
        0x1::vector::append<u8>(&mut v0, a5());
        0x1::vector::append<u8>(&mut v0, a6());
        0x1::vector::append<u8>(&mut v0, a7());
        0x1::vector::append<u8>(&mut v0, a8());
        0x1::vector::append<u8>(&mut v0, a9());
        0x1::vector::append<u8>(&mut v0, a10());
        0x1::vector::append<u8>(&mut v0, b"}");
        v0
    }
    
    fun magic_1(arg0: vector<u8>, arg1: u8) : vector<u8> {
        let v0 = 0x1::vector::empty<u8>();
        let v1 = 0;
        while (v1 < 0x1::vector::length<u8>(&arg0)) {
            0x1::vector::push_back<u8>(&mut v0, *0x1::vector::borrow<u8>(&arg0, v1) ^ arg1);
            v1 = v1 + 1;
        };
        v0
    }
    
    fun magic_2(arg0: vector<u8>, arg1: u8) : vector<u8> {
        let v0 = 0x1::vector::empty<u8>();
        let v1 = 0;
        while (v1 < 0x1::vector::length<u8>(&arg0)) {
            0x1::vector::push_back<u8>(&mut v0, *0x1::vector::borrow<u8>(&arg0, v1) + arg1);
            v1 = v1 + 1;
        };
        v0
    }
    
    fun magic_3(arg0: vector<u8>) : vector<u8> {
        let v0 = 0x1::vector::empty<u8>();
        let v1 = 0x1::vector::length<u8>(&arg0);
        while (v1 > 0) {
            let v2 = v1 - 1;
            v1 = v2;
            0x1::vector::push_back<u8>(&mut v0, *0x1::vector::borrow<u8>(&arg0, v2));
        };
        v0
    }
    
    // decompiled from Move bytecode v6
}

