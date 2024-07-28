module challenge::router {
    use aptos_framework::option;
    use aptos_std::crypto_algebra::deserialize;
    use aptos_std::bls12381_algebra::{Fr, FormatFrLsb, FormatG1Compr, FormatG2Compr, G1, G2, Gt,};
    use challenge::groth16;
    use challenge::flag;
    use aptos_std::crypto_algebra::Element;

    public entry fun initialize(account: &signer) {
        flag::create(account);
    }

    public fun solve(_account: &signer, value: vector<u8>) {
        let vk_alpha_g1 =
            option::extract(&mut deserialize<G1, FormatG1Compr>(&x"9819f632fa8d724e351d25081ea31ccf379991ac25c90666e07103fffb042ed91c76351cd5a24041b40e26d231a5087e"));
        let vk_beta_g2 =
            option::extract(
                &mut deserialize<G2, FormatG2Compr>(
                    &x"871f36a996c71a89499ffe99aa7d3f94decdd2ca8b070dbb467e42d25aad918af6ec94d61b0b899c8f724b2b549d99fc1623a0e51b6cfbea220e70e7da5803c8ad1144a67f98934a6bf2881ec6407678fd52711466ad608d676c60319a299824"));
        let vk_gamma_g2 =
            option::extract(
                &mut deserialize<G2, FormatG2Compr>(
                    &x"96750d8445596af8d679487c7267ae9734aeac584ace191d225680a18ecff8ebae6dd6a5fd68e4414b1611164904ee120363c2b49f33a873d6cfc26249b66327a0de03e673b8139f79809e8b641586cde9943fa072ee5ed701c81b3fd426c220"));
        let vk_delta_g2 =
            option::extract(
                &mut deserialize<G2, FormatG2Compr>(
                    &x"8d3ac832f2508af6f01872ada87ea66d2fb5b099d34c5bac81e7482c956276dfc234c8d2af5fd2394b5440d0708a2c9f124a53c0755e9595cf9f8adade5deefcb8a574a67debd3b74d08c49c23ddc14cd6d48b65dce500c8a5d330e760fe85bb"));
        let vk_gamma_abc_g1: vector<Element<G1>> = vector[
            option::extract(&mut deserialize<G1, FormatG1Compr>(&x"b0df760d0f2d67fdff69d0ed3a0653dd8808df3c407ea4d0e27f8612c3fbb748cb4372d33cac512ee5ef4ee1683c3fe5")),
            option::extract(&mut deserialize<G1, FormatG1Compr>(&x"96ec80d6b1050bbfc209f727678acce8788c05475771daffdd444ad8786c7a40195d859850fe2e72be3054e9fb8ce805")),];
        let public_inputs: vector<Element<Fr>> = vector[
            option::extract(&mut deserialize<Fr, FormatFrLsb>(&x"0ee291cfc951388c3c7f7c85ff2dfd42bbc66a6b4acaef9a5a51ce955125a74f")),];
        let proof_a =
            option::extract(&mut deserialize<G1, FormatG1Compr>(&x"af3bae9476fa1140f3d7abdefdb6ff43eeed6ffea029c7b2a53d2569826edddbaa624f95ffccd1e00a0b32cc6befa68b"));
        let proof_b =
            option::extract(
                &mut deserialize<G2, FormatG2Compr>(
                    &x"5794bfa226fcaa25cd003711ccabe8259a64a1bf9ee1b25fcc6bebd8fe743fcca891bf334bb0a4aacc77f6d12faefbac8be2efbdfeabfaa8687fe3bcaf92174b35aafadbece3b3cf3afcbeefa644188d3cefcbdf0fd01844f805cddcbbcf855b"));
        let proof_c = option::extract(&mut deserialize<G1, FormatG1Compr>(&value));

        groth16::verify_proof<G1, G2, Gt, Fr>(&vk_alpha_g1,
            &vk_beta_g2,
            &vk_gamma_g2,
            &vk_delta_g2,
            &vk_gamma_abc_g1,
            &public_inputs,
            &proof_a,
            &proof_b,
            &proof_c);
        flag::modify_value();
    }

    public entry fun is_solved(_account: &signer) {
        flag::assert_solved();
    }
}
