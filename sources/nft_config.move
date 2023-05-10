module move_soulbound_token::nft_config {
    use std::string::{String, bytes};

    use move_soulbound_token::admin::{Contract, assert_admin};
    use sui::event;
    use sui::object::{Self, UID, ID, uid_to_inner};
    use sui::transfer;
    use sui::tx_context::TxContext;
    use sui::url::{Self, Url};

    // =================== Struct =================

    /// NFT attributes
    struct Attributes has copy, store, drop {
        campaign_id: String,
        campaign_name: String,
    }

    /// NFT config
    struct NFTConfig has key, store {
        id: UID,
        name: String,
        description: String,
        img_url: Url,
        attributes: Attributes,
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

    public fun get_nft_campaign_id(nft_config: &NFTConfig): String {
        nft_config.attributes.campaign_id
    }

    public fun get_nft_campaign_name(nft_config: &NFTConfig): String {
        nft_config.attributes.campaign_name
    }

    /// Create NFT config
    public entry fun create_nft_config(
        contract: &Contract,
        name: String,
        description: String,
        img_url: String,
        campaign_id: String,
        campaign_name: String,
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
                campaign_id,
                campaign_name,
            },
        });

        let nft_config = NFTConfig {
            id,
            name,
            description,
            img_url,
            attributes: Attributes {
                campaign_id,
                campaign_name,
            },
        };

        transfer::share_object(nft_config);
    }
}
