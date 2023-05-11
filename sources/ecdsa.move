module move_soulbound_token::ecdsa {
    use std::vector;

    use sui::address;
    use sui::bcs;
    use sui::ed25519;

    const EINVAILID_MINT_SIGNATURE: u64 = 0;

    fun verify_mint_data(
        buyer: address,
        nonce: u64,
        signature: vector<u8>,
        public_key: vector<u8>
    ): bool {
        let signed_data = vector::empty<u8>();

        vector::append(&mut signed_data, address::to_bytes(buyer));
        vector::append(&mut signed_data, bcs::to_bytes(&nonce));

        ed25519::ed25519_verify(&signature, &public_key, &signed_data)
    }

    public fun assert_mint_signature_valid(
        buyer: address,
        nonce: u64,
        signature: vector<u8>,
        public_key: vector<u8>
    ) {
        assert!(verify_mint_data(buyer, nonce, signature, public_key), EINVAILID_MINT_SIGNATURE)
    }
}
