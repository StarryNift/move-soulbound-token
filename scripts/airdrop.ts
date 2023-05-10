import {
	Ed25519Keypair,
	JsonRpcProvider,
	devnetConnection,
	RawSigner,
	TransactionBlock,
	testnetConnection, DEFAULT_ED25519_DERIVATION_PATH,
} from "@mysten/sui.js";
import { bcs } from './bcsUtil'
import {BCS} from "@mysten/bcs";
require("dotenv").config();
const nftMetadataList: any = require("../consts/Metadata.json");

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
const phaseId = process.env.PHASE_ID || "";
const boxConfigId = process.env.BOX_CONFIG_ID || "";
const boxInfoId = process.env.BOX_INFO_ID || "";

const avatarMintCap = process.env.AVATAR_MINT_CAP || "";
const spaceMintCap = process.env.SPACE_MINT_CAP || "";
const couponMintCap = process.env.COUPON_MINT_CAP || "";
const mysteryBoxMintCap = process.env.MYSTERY_BOX_MINT_CAP || "";

async function airdropGas() {
	try {
		for (let i = 0; i < 100; i++) {
			// transfer gas cost: 0.00199588
			const tx = new TransactionBlock();
			const receiverAddress = publicKey.toSuiAddress()
			const [coin] = tx.splitCoins(tx.gas, [tx.pure(1000)]);
			tx.transferObjects([coin], tx.pure(receiverAddress));
			const result = await signer.signAndExecuteTransactionBlock({
				transactionBlock: tx,
			});
			console.log({ result });
		}
	} catch (err) {
		console.log(err);
		return null;
	}
}

async function main() {
	await airdropGas()
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(`error: ${error.stack}`);
		process.exit(1);
	});
