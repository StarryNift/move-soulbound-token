module move_soulbound_token::ecdsa {
    use std::vector;

    use sui::address;
    use sui::ed25519;
    use sui::object::{Self, ID};

    const EINVAILID_MINT_SIGNATURE: u64 = 0;

    fun verify_mint_data(
        sender: address,
        nft_config_id: &ID,
        signature: vector<u8>,
        public_key: vector<u8>
    ): bool {
        let signed_data = vector::empty<u8>();

        vector::append(&mut signed_data, address::to_bytes(sender));
        vector::append(&mut signed_data, object::id_to_bytes(nft_config_id));

        ed25519::ed25519_verify(&signature, &public_key, &signed_data)
    }

    public fun assert_mint_signature_valid(
        sender: address,
        nft_config_id: &ID,
        signature: vector<u8>,
        public_key: vector<u8>
    ) {
        assert!(verify_mint_data(sender, nft_config_id, signature, public_key), EINVAILID_MINT_SIGNATURE)
    }
}
