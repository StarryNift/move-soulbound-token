import {
    DEFAULT_ED25519_DERIVATION_PATH,
    Ed25519Keypair,
    JsonRpcProvider,
    RawSigner,
    testnetConnection,
    TransactionBlock,
} from "@mysten/sui.js";
import {bcs} from './bcsUtil'
import {BCS} from "@mysten/bcs";

require("dotenv").config();

const MNEMONICS: string = process.env.MNEMONICS || "";
const provider = new JsonRpcProvider(testnetConnection);
const keypair_ed25519 = Ed25519Keypair.deriveKeypair(
    MNEMONICS,
    DEFAULT_ED25519_DERIVATION_PATH
);
const signer = new RawSigner(keypair_ed25519, provider);
const publicKey = keypair_ed25519.getPublicKey();
const defaultGasBudget = 0.01 * 10 ** 9

const packageId = process.env.PACKAGE_ID || "";
const contractId = process.env.CONTRACT_ID || "";

async function set_contract_owner(new_owner: string) {
    try {
        const tx = new TransactionBlock();
        const txn = await tx.moveCall({
            target: `${packageId}::admin::set_contract_owner`,
            arguments: [tx.object(contractId), tx.pure(new_owner, 'address')],
        });

        const executedTx = await signer.signAndExecuteTransactionBlock({
            transactionBlock: tx,
            options: {
                showInput: true,
                showEffects: true,
                showEvents: true,
                showObjectChanges: true,
            },
        });
        const {digest, transaction, effects, events, errors} = executedTx;
        console.log(digest, transaction, effects, events);
    } catch (err) {
        console.log(err);
        return null;
    }
}

async function create_nft_config() {
    try {
        const tx = new TransactionBlock();
        tx.setGasBudget(defaultGasBudget);
        tx.moveCall({
            target: `${packageId}::nft_config::create_nft_config`,
            arguments: [
                // contract ID
                tx.object(contractId),
                // nft_name
                tx.pure("AI ANIMO Mystery Box", "string"),
                // nft_description
                tx.pure("The boxes come with varying rarity levels. By harnessing the unmatched scalability of the Sui Network for efficient transaction processing and storage. We have bundled three different assets - AI ANIMO characters, Starryverse 3D virtual spaces, and Sui token packages - into each box", "string"),
                // nft_image
                tx.pure(
                    "https://d1uoymq29mtp9f.cloudfront.net/web/img/sui-mysterybox.png",
                    "string"
                ),
                // reward_index: string number
                tx.pure("1", "string"),
                // campaign_id
                tx.pure("campaign_id string test", "string"),
                // campaign_name
                tx.pure("campaign_name string test", "string"),
                // max supply
                tx.pure(2, 'u64')
            ],
        });

        const executedTx = await signer.signAndExecuteTransactionBlock({
            transactionBlock: tx,
            options: {
                showInput: true,
                showEffects: true,
                showEvents: true,
                showObjectChanges: true,
            },
        });

        const {digest, transaction, effects, events, errors} = executedTx;
        console.log("nft config", digest, transaction);
        if (effects && effects.created && effects.created[0]) {
            return effects.created[0].reference?.objectId;
        }
        return null;
    } catch (err) {
        console.log(err);
        return null;
    }
}

async function toggle_contract_freeze() {
    try {
        const tx = new TransactionBlock();
        tx.setGasBudget(defaultGasBudget);
        tx.moveCall({
            target: `${packageId}::admin::toggle_contract_freeze`,
            arguments: [
                // contract ID
                tx.object(contractId),
            ],
        });

        const executedTx = await signer.signAndExecuteTransactionBlock({
            transactionBlock: tx,
            options: {
                showInput: true,
                showEffects: true,
                showEvents: true,
                showObjectChanges: true,
            },
        });

        const {effects} = executedTx;
        const status = effects?.status
        if (status?.status === 'failure') {
            console.log('toggle_contract_freeze failed', status.error)
        } else {
            console.log('toggle_contract_freeze success')
        }
    } catch (err) {
        console.log(err);
        return null;
    }
}

async function set_contract_signer_public_key() {
    try {
        const tx = new TransactionBlock();
        tx.setGasBudget(defaultGasBudget);
        tx.moveCall({
            target: `${packageId}::admin::set_contract_signer_public_key`,
            arguments: [
                // contract ID
                tx.object(contractId),
                tx.pure(bcs.ser(['vector', BCS.U8], publicKey.toBytes()).toBytes())
            ],
        });

        const executedTx = await signer.signAndExecuteTransactionBlock({
            transactionBlock: tx,
            options: {
                showInput: true,
                showEffects: true,
                showEvents: true,
                showObjectChanges: true,
            },
        });

        const {effects} = executedTx;
        const status = effects?.status
        if (status?.status === 'failure') {
            console.log('set_contract_signer_public_key failed', status.error)
        } else {
            console.log('set_contract_signer_public_key success')
        }
    } catch (err) {
        console.log(err);
        return null;
    }
}

async function main() {
    const new_owner = await signer.getAddress();
    // set public key
    // await set_contract_signer_public_key();

    await create_nft_config();

    // await set_contract_owner('0xcf6eeef20f6a7567f8229efc28b699965d91f68393dc8cb0a0edc9c4c46882e4');
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(`error: ${error.stack}`);
        process.exit(1);
    });


