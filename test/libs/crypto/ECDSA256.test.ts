import { ethers } from "hardhat";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";

import { ECDSA256Mock } from "@ethers-v6";

describe("ECDSA256", () => {
  const reverter = new Reverter();

  let ecdsa256: ECDSA256Mock;

  before(async () => {
    const ECDSA256Mock = await ethers.getContractFactory("ECDSA256Mock");

    ecdsa256 = await ECDSA256Mock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("SECP256r1", () => {
    const signature =
      "0x37a1459a56f4042601208db702c24b7a4fde91f4445e29a76a503d7282cdea2250f70e34c15cd4944da0326e9096e708434e0fb7de61341e129aca1d45380752";
    const pubKey =
      "0x9e8ead221eb5e27aa9e07db415c5ebfd21683bac0c64fed612c158ee859f7ab93d63a507c81c32151cb1494fab248dc62c22fa488e1950090c2221f7918d1fc1";
    const message = "0x1b2ca2c2da4b5051c99194d850326cd24971e6e8ceffea5c5c7097dbdff5299b";

    describe("verify", () => {
      it("should verify the signature", async () => {
        expect(await ecdsa256.verifySECP256r1(message, signature, pubKey)).to.be.true;
      });

      it("should not verify invalid signature", async () => {
        const message = "0x0123456789";

        expect(await ecdsa256.verifySECP256r1(message, signature, pubKey)).to.be.false;
      });

      it("should revert if signature or public key is invalid", async () => {
        const wrongSig = ethers.toBeHex(0, 0x40);

        expect(await ecdsa256.verifySECP256r1(message, wrongSig, pubKey)).to.be.false;

        const wrongPubKey = ethers.toBeHex(0, 0x40);

        expect(await ecdsa256.verifySECP256r1(message, signature, wrongPubKey)).to.be.false;
      });

      it("should revert if signature or public key has an invalid length", async () => {
        const wrongSig = "0x0101";

        await expect(ecdsa256.verifySECP256r1(message, wrongSig, pubKey)).to.be.revertedWithCustomError(
          ecdsa256,
          "LengthIsNot64",
        );

        const wrongPubKey = "0x0101";

        await expect(ecdsa256.verifySECP256r1(message, signature, wrongPubKey)).to.be.revertedWithCustomError(
          ecdsa256,
          "LengthIsNot64",
        );
      });
    });
  });

  describe("brainpoolP256r1", () => {
    const signature =
      "0x1a721d3ca6078e208eddb80a3d3290c7bfa9208bc03c78e0f9cec5698502cf550a7d38a45e938e6bc57fe019522057e7c21c58e132f99fce8abdaed2a100fad1";
    const pubKey =
      "0x5ef984318687d0479c53d4d646de58f4e83862c757911deef88d87db076642666c2fcee77129605fa64c9df4edc508978496865fb3300a2a6d8fc54c350da7b1";
    const message = "0x68656c6c6f20776f726c64";

    it("should verify the signature", async () => {
      expect(await ecdsa256.verifyBrainpoolP256r1(message, signature, pubKey)).to.be.true;
    });

    it("should not verify invalid signature", async () => {
      const message = "0x0123456789";

      expect(await ecdsa256.verifyBrainpoolP256r1(message, signature, pubKey)).to.be.false;
    });
  });
});
