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
const nftConfigId = process.env.NFT_CONFIG_ID || "";
const mintCap = process.env.MINT_CAP || "";

async function get_sign_data() {
    const address = await signer.getAddress();
    console.log('getAddress: ', address);
    const data = [
        // user address
        bcs.ser(BCS.ADDRESS, address).toBytes(),
        // nft config id
        bcs.ser(BCS.ADDRESS, nftConfigId).toBytes(),
    ];
    return signer.signData(bcs.ser(['vector', BCS.U8], data).toBytes())
}

async function test_mint_for_users() {
    try {
        const tx = new TransactionBlock();
        // tx.setGasBudget(defaultGasBudget);
        await tx.moveCall({
            target: `${packageId}::nft::mint_for_users`,
            arguments: [
                tx.object(contractId),
                tx.object(nftConfigId),
                tx.object(mintCap),
                // user wallet address list
                tx.pure(["0xcf6eeef20f6a7567f8229efc28b699965d91f68393dc8cb0a0edc9c4c46882e4", "0x0e0f2992f8d036b9a89d43aa76b1f6cf33c6b94947fa28f6eb196d772accb92c"]),
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
        console.log(digest, transaction, effects, events);
    } catch (err) {
        console.log(err);
        return null;
    }
}

async function test_claim() {
    try {
        // const signature = '8341d4775e92d78866a54a71855c8b7233d19b764e8b57300e60bbcd58399b650b06e3b986dc95b2154e11aad0e3b91df4383a635b9eea6d7e56065cf564bc03';
        const signature = await get_sign_data();
        console.log('signature: ', signature);
        const sign = bcs.ser(['vector', BCS.U8],
            Buffer.from(signature, 'hex')).toBytes();
        console.log('sign: ', sign);
        const tx = new TransactionBlock();
        // tx.setGasBudget(defaultGasBudget);
        await tx.moveCall({
            target: `${packageId}::nft::claim`,
            arguments: [
                tx.object(contractId),
                tx.object(nftConfigId),
                tx.object(mintCap),
                // signature
                tx.pure(sign),
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
        console.log(digest, transaction, effects, events);
    } catch (err) {
        console.log(err);
        return null;
    }
}

async function main() {
    await test_claim()
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(`error: ${error.stack}`);
        process.exit(1);
    });
