import { ethers } from "hardhat";
import { expect } from "chai";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";

import { MultiOwnablePoolContractsRegistryMock } from "@ethers-v6";

describe("MultiOwnablePoolContractsRegistry", () => {
  const reverter = new Reverter();

  let SECOND: SignerWithAddress;

  let poolContractsRegistry: MultiOwnablePoolContractsRegistryMock;

  before("setup", async () => {
    [, SECOND] = await ethers.getSigners();

    const MultiOwnablePoolContractsRegistryMock = await ethers.getContractFactory(
      "MultiOwnablePoolContractsRegistryMock",
    );
    poolContractsRegistry = await MultiOwnablePoolContractsRegistryMock.deploy();

    await poolContractsRegistry.__AMultiOwnablePoolContractsRegistry_init();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should not initialize twice", async () => {
      await expect(poolContractsRegistry.__AMultiOwnablePoolContractsRegistry_init())
        .to.be.revertedWithCustomError(poolContractsRegistry, "InvalidInitialization")
        .withArgs();
    });

    it("only owner should call these functions", async () => {
      await expect(poolContractsRegistry.connect(SECOND).setNewImplementations([], []))
        .to.be.revertedWithCustomError(poolContractsRegistry, "UnauthorizedAccount")
        .withArgs(SECOND.address);

      await expect(poolContractsRegistry.connect(SECOND).injectDependenciesToExistingPools("", 0, 0))
        .to.be.revertedWithCustomError(poolContractsRegistry, "UnauthorizedAccount")
        .withArgs(SECOND.address);

      await expect(poolContractsRegistry.connect(SECOND).injectDependenciesToExistingPoolsWithData("", "0x", 0, 0))
        .to.be.revertedWithCustomError(poolContractsRegistry, "UnauthorizedAccount")
        .withArgs(SECOND.address);
    });
  });

  describe("coverage", () => {
    it("should call these methods", async () => {
      await expect(poolContractsRegistry.setNewImplementations([""], [await SECOND.getAddress()])).to.be.reverted;

      await expect(poolContractsRegistry.injectDependenciesToExistingPools("", 0, 0)).to.be.reverted;

      await expect(poolContractsRegistry.injectDependenciesToExistingPoolsWithData("", "0x", 0, 0)).to.be.reverted;
    });
  });
});
