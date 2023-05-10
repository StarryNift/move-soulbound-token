import {
	Ed25519Keypair,
	JsonRpcProvider,
	devnetConnection,
	RawSigner,
	TransactionBlock,
	testnetConnection, DEFAULT_ED25519_DERIVATION_PATH,
} from "@mysten/sui.js";
import { bcs } from './bcsUtil'
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
		const { digest, transaction, effects, events, errors } = executedTx;
		console.log(digest, transaction, effects, events);
	} catch (err) {
		console.log(err);
		return null;
	}
}

async function main() {
	await test_mint_for_users()
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(`error: ${error.stack}`);
    process.exit(1);
  });
