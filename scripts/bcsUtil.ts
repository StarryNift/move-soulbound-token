import { BCS, getSuiMoveConfig } from "@mysten/bcs";
const bcs = new BCS(getSuiMoveConfig());
bcs.registerEnumType("Option<T>", {
	none: null,
	some: "T",
});

const serString2U8Vector = function (content: string) {
	return bcs
		.ser(["vector", BCS.U8], bcs.ser(BCS.STRING, content).toBytes())
		.toBytes();
};
const serAddress2U8Vector = function (content: string) {
	return bcs
		.ser(["vector", BCS.U8], bcs.ser(BCS.ADDRESS, content).toBytes())
		.toBytes();
};
const serBoolean2U8Vector = function (content: boolean) {
	return bcs
		.ser(["vector", BCS.U8], bcs.ser(BCS.BOOL, content).toBytes())
		.toBytes();
};
const serU82U8Vector = function (content: number) {
	return bcs
		.ser(["vector", BCS.U8], bcs.ser(BCS.U8, content).toBytes())
		.toBytes();
};

const serU642U8Vector = function (content: number) {
	return bcs
		.ser(["vector", BCS.U8], bcs.ser(BCS.U64, content).toBytes())
		.toBytes();
};

export {
	bcs,
	serString2U8Vector,
	serAddress2U8Vector,
	serBoolean2U8Vector,
	serU82U8Vector,
	serU642U8Vector
}
