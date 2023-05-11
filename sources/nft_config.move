module move_soulbound_token::nft_config {
    use std::string::{String, bytes};

    use move_soulbound_token::admin::{Contract, assert_admin};
    use sui::event;
    use sui::object::{Self, UID, ID, uid_to_inner};
    use sui::transfer;
    use sui::tx_context::TxContext;
    use sui::url::{Self, Url};
    use std::vector;

    // =================== Error =================

    const EWrongAddressExisted: u64 = 0;
    const EWrongMaxSupply: u64 = 1;

    // =================== Struct =================

    /// NFT attributes
    struct Attributes has copy, store, drop {
        reward_index: String,
        campaign_id: String,
        campaign_name: String,
    }

    /// NFT config
    struct NFTConfig has key, store {
        id: UID,
        name: String,
        description: String,
        img_url: Url,
        max_supply: u64,
        attributes: Attributes,
        creators: vector<address>,
    }

    // =================== Event =================

    struct CreateNFTConfigEvent has copy, drop {
        id: ID,
        name: String,
        description: String,
        img_url: Url,
        attributes: Attributes,
    }

    // =================== Function =================

    public fun get_nft_id(nft_config: &NFTConfig): ID {
        uid_to_inner(&nft_config.id)
    }

    public fun get_nft_name(nft_config: &NFTConfig): String {
        nft_config.name
    }

    public fun get_nft_description(nft_config: &NFTConfig): String {
        nft_config.description
    }

    public fun get_nft_img_url(nft_config: &NFTConfig): Url {
        nft_config.img_url
    }

    public fun get_nft_reward_index(nft_config: &NFTConfig): String {
        nft_config.attributes.reward_index
    }

    public fun get_nft_campaign_id(nft_config: &NFTConfig): String {
        nft_config.attributes.campaign_id
    }

    public fun get_nft_campaign_name(nft_config: &NFTConfig): String {
        nft_config.attributes.campaign_name
    }

    public fun add_creator(nft_config: &mut NFTConfig, user: address) {
        let is_exists = vector::contains(&nft_config.creators, &user);
        assert!(!is_exists, EWrongAddressExisted);

        if (nft_config.max_supply > 0) {
            let creator_len = vector::length(&nft_config.creators);
            assert!(nft_config.max_supply > creator_len, EWrongMaxSupply);
        };

        vector::push_back(&mut nft_config.creators, user);
    }

    /// Create NFT config
    public entry fun create_nft_config(
        contract: &Contract,
        name: String,
        description: String,
        img_url: String,
        reward_index: String,
        campaign_id: String,
        campaign_name: String,
        max_supply: u64,
        ctx: &mut TxContext,
    ) {
        assert_admin(contract, ctx);

        let img_url = url::new_unsafe_from_bytes(*bytes(&img_url));

        let id = object::new(ctx);
        event::emit(CreateNFTConfigEvent {
            id: uid_to_inner(&id),
            name,
            description,
            img_url,
            attributes: Attributes {
                reward_index,
                campaign_id,
                campaign_name,
            },
        });

        let nft_config = NFTConfig {
            id,
            name,
            description,
            img_url,
            max_supply,
            attributes: Attributes {
                reward_index,
                campaign_id,
                campaign_name,
            },
            creators: vector::empty(),
        };

        transfer::share_object(nft_config);
    }
}
