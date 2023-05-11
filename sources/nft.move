module move_soulbound_token::nft {
    use std::ascii;
    use std::option;
    use std::string::{Self, String, to_ascii};
    use std::vector;

    use nft_protocol::attributes::{Self, Attributes};
    use nft_protocol::collection;
    use nft_protocol::display_info;
    use nft_protocol::mint_cap::{Self, MintCap};
    use nft_protocol::mint_event;
    use nft_protocol::tags;
    use ob_permissions::witness;
    use ob_utils::display as ob_display;

    use move_soulbound_token::admin::{Contract, assert_admin, assert_not_freeze, get_signer_public_key};
    use move_soulbound_token::ecdsa::assert_mint_signature_valid;
    use move_soulbound_token::nft_config::{NFTConfig, get_nft_img_url, get_nft_name, get_nft_description, get_nft_campaign_id, get_nft_campaign_name, get_nft_id, get_nft_reward_index, add_creator};
    use sui::display;
    use sui::event;
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::url::Url;

    const COLLECTION_NAME: vector<u8> = b"Trantor soulbound token";
    const COLLECTION_DESCRIPTION: vector<u8> = b"This collection contains all SBT issued by Trantor on Sui mainnet which are provided exclusively for the campaign participators on Trantor platform. Find out more details from Trantor Official Website: https://trantor.xyz";

    // =================== Struct =================

    /// One time witness is only instantiated in the init method
    struct NFT has drop {}

    /// Used for authorization of other protected actions.
    ///
    /// `Witness` must not be freely exposed to any contract.
    struct Witness has drop {}

    struct SBT has key {
        id: UID,
        name: String,
        description: String,
        img_url: Url,
        attributes: Attributes,
    }

    // =================== Event =================

    struct MintNFTEvent has copy, drop {
        creator: address,
        nft_config_id: ID,
    }

    fun init(otw: NFT, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);

        // 1. Init Collection & MintCap with unlimited supply
        let (collection, mint_cap) = collection::create_with_mint_cap<NFT, SBT>(
            &otw, option::none(), ctx
        );

        // 2. Init Publisher & Delegated Witness
        let publisher = sui::package::claim(otw, ctx);
        let dw = witness::from_witness(Witness {});

        // === NFT DISPLAY ===

        // 3. Init Display
        let tags = vector[tags::tokenised_asset()];

        let display = display::new<SBT>(&publisher, ctx);
        display::add(&mut display, string::utf8(b"name"), string::utf8(b"{name}"));
        display::add(&mut display, string::utf8(b"description"), string::utf8(b"{description}"));
        display::add(&mut display, string::utf8(b"image_url"), string::utf8(b"{img_url}"));
        display::add(&mut display, string::utf8(b"attributes"), string::utf8(b"{attributes}"));
        display::add(&mut display, string::utf8(b"tags"), ob_display::from_vec(tags));
        display::update_version(&mut display);
        transfer::public_transfer(display, tx_context::sender(ctx));

        // === COLLECTION DOMAINS ===

        // 4. Add name and description to Collection
        collection::add_domain(
            dw,
            &mut collection,
            display_info::new(
                string::utf8(COLLECTION_NAME),
                string::utf8(COLLECTION_DESCRIPTION),
            ),
        );

        transfer::public_share_object(mint_cap);
        transfer::public_transfer(publisher, sender);
        transfer::public_share_object(collection);
    }

    public entry fun mint_for_users(
        contract: &Contract,
        nft_config: &mut NFTConfig,
        mint_cap: &mut MintCap<SBT>,
        receivers: vector<address>,
        ctx: &mut TxContext
    ) {
        assert_admin(contract, ctx);

        // attribute keys
        let attributes_keys = vector::empty<ascii::String>();
        vector::push_back(&mut attributes_keys, ascii::string(b"reward_index"));
        vector::push_back(&mut attributes_keys, ascii::string(b"campaign_id"));
        vector::push_back(&mut attributes_keys, ascii::string(b"campaign_name"));

        // attribute values
        let attribute_values = vector::empty<ascii::String>();
        let reward_index = get_nft_reward_index(nft_config);
        let campaign_id = get_nft_campaign_id(nft_config);
        let campaign_name = get_nft_campaign_name(nft_config);
        vector::push_back(&mut attribute_values, to_ascii(reward_index));
        vector::push_back(&mut attribute_values, to_ascii(campaign_id));
        vector::push_back(&mut attribute_values, to_ascii(campaign_name));

        let i = 0;
        let len = vector::length(&receivers);

        while (i < len) {
            let sbt = SBT {
                id: object::new(ctx),
                name: get_nft_name(nft_config),
                description: get_nft_description(nft_config),
                img_url: get_nft_img_url(nft_config),
                attributes: attributes::from_vec(attributes_keys, attribute_values),
            };

            let receiver = *vector::borrow(&receivers, i);

            add_creator(nft_config, receiver);

            event::emit(MintNFTEvent {
                creator: receiver,
                nft_config_id: get_nft_id(nft_config),
            });

            mint_event::emit_mint(
                witness::from_witness(Witness {}),
                mint_cap::collection_id(mint_cap),
                &sbt
            );

            mint_cap::increment_supply(mint_cap, 1);

            transfer::transfer(sbt, receiver);

            i = i + 1;
        }
    }

    public entry fun claim(
        contract: &Contract,
        nft_config: &mut NFTConfig,
        mint_cap: &mut MintCap<SBT>,
        signature: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert_not_freeze(contract);

        let sender = tx_context::sender(ctx);

        assert_mint_signature_valid(
            sender,
            &get_nft_id(nft_config),
            signature,
            get_signer_public_key(contract)
        );

        // attribute keys
        let attributes_keys = vector::empty<ascii::String>();
        vector::push_back(&mut attributes_keys, ascii::string(b"reward_index"));
        vector::push_back(&mut attributes_keys, ascii::string(b"campaign_id"));
        vector::push_back(&mut attributes_keys, ascii::string(b"campaign_name"));

        // attribute values
        let attribute_values = vector::empty<ascii::String>();
        let reward_index = get_nft_reward_index(nft_config);
        let campaign_id = get_nft_campaign_id(nft_config);
        let campaign_name = get_nft_campaign_name(nft_config);
        vector::push_back(&mut attribute_values, to_ascii(reward_index));
        vector::push_back(&mut attribute_values, to_ascii(campaign_id));
        vector::push_back(&mut attribute_values, to_ascii(campaign_name));

        let sbt = SBT {
            id: object::new(ctx),
            name: get_nft_name(nft_config),
            description: get_nft_description(nft_config),
            img_url: get_nft_img_url(nft_config),
            attributes: attributes::from_vec(attributes_keys, attribute_values),
        };

        let receiver = tx_context::sender(ctx);

        add_creator(nft_config, receiver);

        event::emit(MintNFTEvent {
            creator: receiver,
            nft_config_id: get_nft_id(nft_config),
        });

        mint_event::emit_mint(
            witness::from_witness(Witness {}),
            mint_cap::collection_id(mint_cap),
            &sbt
        );

        mint_cap::increment_supply(mint_cap, 1);

        transfer::transfer(sbt, receiver);
    }
}
