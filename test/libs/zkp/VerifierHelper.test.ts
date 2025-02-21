import { ethers } from "hardhat";
import { expect } from "chai";

import { Reverter } from "@/test/helpers/reverter";

import { VerifierHelperMock, Verifier2Mock, Verifier3Mock } from "@ethers-v6";

describe("VerifierHelper", () => {
  const reverter = new Reverter();

  let verifierHelper: VerifierHelperMock;
  let verifier2: Verifier2Mock;
  let verifier3: Verifier3Mock;

  const a = <[number, number]>[10, 20];
  const b = <[[number, number], [number, number]]>[
    [1, 2],
    [3, 4],
  ];
  const c = <[number, number]>[30, 40];

  const pubSignals2 = [2, 4];
  const pubSignals3 = [3, 6, 9];

  before("setup", async () => {
    const VerifierHelperMock = await ethers.getContractFactory("VerifierHelperMock");
    const Verifier2Mock = await ethers.getContractFactory("Verifier2Mock");
    const Verifier3Mock = await ethers.getContractFactory("Verifier3Mock");

    verifierHelper = await VerifierHelperMock.deploy();

    verifier2 = await Verifier2Mock.deploy(true, pubSignals2);
    verifier3 = await Verifier3Mock.deploy(true, pubSignals3);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("verifyProof", () => {
    it("should correctly call verifyProof function", async () => {
      const contractInterface = expect(
        await verifierHelper.verifyProofStruct(await verifier3.getAddress(), pubSignals3, { a, b, c }),
      ).to.be.true;

      expect(await verifierHelper.verifyProof(await verifier3.getAddress(), pubSignals3, a, b, c)).to.be.true;

      await verifier2.setVerifyResult(false);

      expect(await verifierHelper.verifyProofStruct(await verifier2.getAddress(), pubSignals2, { a, b, c })).to.be
        .false;
      expect(await verifierHelper.verifyProof(await verifier2.getAddress(), pubSignals2, a, b, c)).to.be.false;
    });

    it("should get exception if failed to call verifyProof function", async () => {
      const wrongPubSignals = [1, 1, 2, 3];

      await expect(verifierHelper.verifyProofStruct(await verifier2.getAddress(), wrongPubSignals, { a, b, c }))
        .to.be.revertedWithCustomError(verifierHelper, "FailedToCallVerifyProof")
        .withArgs();
      await expect(verifierHelper.verifyProof(await verifier3.getAddress(), wrongPubSignals, a, b, c))
        .to.be.revertedWithCustomError(verifierHelper, "FailedToCallVerifyProof")
        .withArgs();
    });
  });

  describe("verifyProofSafe", () => {
    it("should correctly call verifyProof function with additional checks", async () => {
      expect(await verifierHelper.verifyProofStructSafe(await verifier3.getAddress(), pubSignals3, { a, b, c }, 3)).to
        .be.true;
      expect(await verifierHelper.verifyProofSafe(await verifier3.getAddress(), pubSignals3, a, b, c, 3)).to.be.true;

      await verifier2.setVerifyResult(false);

      expect(await verifierHelper.verifyProofStructSafe(await verifier2.getAddress(), pubSignals2, { a, b, c }, 2)).to
        .be.false;
      expect(await verifierHelper.verifyProofSafe(await verifier2.getAddress(), pubSignals2, a, b, c, 2)).to.be.false;
    });

    it("should get an exception if it passes invalid public signals arr", async () => {
      await expect(verifierHelper.verifyProofStructSafe(await verifier2.getAddress(), pubSignals2, { a, b, c }, 4))
        .to.be.revertedWithCustomError(verifierHelper, "InvalidPublicSignalsCount")
        .withArgs(pubSignals2.length, 4);

      await expect(verifierHelper.verifyProofSafe(await verifier3.getAddress(), pubSignals3, a, b, c, 4))
        .to.be.revertedWithCustomError(verifierHelper, "InvalidPublicSignalsCount")
        .withArgs(pubSignals3.length, 4);
    });
  });
});
