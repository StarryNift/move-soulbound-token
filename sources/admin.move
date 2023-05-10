module move_soulbound_token::admin {
    use std::vector;

    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    // =================== Error =================

    const EWrongAdmin: u64 = 0;
    const EWrongFreeze: u64 = 1;

    // =================== Struct =================

    /// Contract config
    struct Contract has key, store {
        id: UID,
        // Contract admin address
        owner: address,
        // Signer publicKey
        signer: vector<u8>,
        // Contract freeze state
        freeze: bool,
    }

    // =================== Function =================

    /// Initial admin contract
    fun init(ctx: &mut TxContext) {
        transfer::share_object(Contract {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            signer: vector::empty(),
            freeze: false,
        });
    }

    /// Get signer public key
    public fun get_signer_public_key(contract: &Contract): vector<u8> {
        contract.signer
    }

    /// Check must be admin
    public fun assert_admin(contract: &Contract, ctx: &mut TxContext) {
        assert!(
            contract.owner == tx_context::sender(ctx), EWrongAdmin,
        );
    }

    /// Check contract not freeze
    public fun assert_not_freeze(contract: &Contract) {
        assert!(!contract.freeze, EWrongFreeze);
    }

    /// Set owner address
    public entry fun set_contract_owner(contract: &mut Contract, new_owner: address, ctx: &mut TxContext) {
        assert_admin(contract, ctx);
        contract.owner = new_owner;
    }

    /// Set signer public key
    public entry fun set_contract_signer_public_key(
        contract: &mut Contract,
        public_key: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert_admin(contract, ctx);
        contract.signer = public_key;
    }

    /// Freezen contract / Unfreeze contract
    public entry fun toggle_contract_freeze(contract: &mut Contract, ctx: &mut TxContext) {
        assert_admin(contract, ctx);
        contract.freeze = !contract.freeze;
    }
}
