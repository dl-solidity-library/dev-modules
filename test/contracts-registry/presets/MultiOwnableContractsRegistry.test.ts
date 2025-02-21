import { ethers } from "hardhat";
import { expect } from "chai";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";

import { MultiOwnableContractsRegistry } from "@ethers-v6";

describe("MultiOwnableContractsRegistry", () => {
  const reverter = new Reverter();

  let SECOND: SignerWithAddress;

  let contractsRegistry: MultiOwnableContractsRegistry;

  before("setup", async () => {
    [, SECOND] = await ethers.getSigners();

    const MultiOwnableContractsRegistry = await ethers.getContractFactory("MultiOwnableContractsRegistry");
    contractsRegistry = await MultiOwnableContractsRegistry.deploy();

    await contractsRegistry.__MultiOwnableContractsRegistry_init();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should not initialize twice", async () => {
      await expect(contractsRegistry.__MultiOwnableContractsRegistry_init())
        .to.be.revertedWithCustomError(contractsRegistry, "InvalidInitialization")
        .withArgs();
    });

    it("only owner should call these functions", async () => {
      await expect(contractsRegistry.connect(SECOND).injectDependencies(""))
        .to.be.revertedWithCustomError(contractsRegistry, "UnauthorizedAccount")
        .withArgs(SECOND.address);

      await expect(contractsRegistry.connect(SECOND).injectDependenciesWithData("", "0x"))
        .to.be.revertedWithCustomError(contractsRegistry, "UnauthorizedAccount")
        .withArgs(SECOND.address);

      await expect(contractsRegistry.connect(SECOND).upgradeContract("", ethers.ZeroAddress))
        .to.be.revertedWithCustomError(contractsRegistry, "UnauthorizedAccount")
        .withArgs(SECOND.address);

      await expect(contractsRegistry.connect(SECOND).upgradeContractAndCall("", ethers.ZeroAddress, "0x"))
        .to.be.revertedWithCustomError(contractsRegistry, "UnauthorizedAccount")
        .withArgs(SECOND.address);

      await expect(contractsRegistry.connect(SECOND).addContract("", ethers.ZeroAddress))
        .to.be.revertedWithCustomError(contractsRegistry, "UnauthorizedAccount")
        .withArgs(SECOND.address);

      await expect(contractsRegistry.connect(SECOND).addProxyContract("", ethers.ZeroAddress))
        .to.be.revertedWithCustomError(contractsRegistry, "UnauthorizedAccount")
        .withArgs(SECOND.address);

      await expect(contractsRegistry.connect(SECOND).addProxyContractAndCall("", ethers.ZeroAddress, "0x"))
        .to.be.revertedWithCustomError(contractsRegistry, "UnauthorizedAccount")
        .withArgs(SECOND.address);

      await expect(contractsRegistry.connect(SECOND).justAddProxyContract("", ethers.ZeroAddress))
        .to.be.revertedWithCustomError(contractsRegistry, "UnauthorizedAccount")
        .withArgs(SECOND.address);

      await expect(contractsRegistry.connect(SECOND).removeContract(""))
        .to.be.revertedWithCustomError(contractsRegistry, "UnauthorizedAccount")
        .withArgs(SECOND.address);
    });
  });

  describe("coverage", () => {
    it("should call these methods", async () => {
      await expect(contractsRegistry.injectDependencies("")).to.be.reverted;

      await expect(contractsRegistry.injectDependenciesWithData("", "0x")).to.be.reverted;

      await expect(contractsRegistry.upgradeContract("", ethers.ZeroAddress)).to.be.reverted;

      await expect(contractsRegistry.upgradeContractAndCall("", ethers.ZeroAddress, "0x")).to.be.reverted;

      await expect(contractsRegistry.addContract("", ethers.ZeroAddress)).to.be.reverted;

      await expect(contractsRegistry.addProxyContract("", ethers.ZeroAddress)).to.be.reverted;

      await expect(contractsRegistry.addProxyContractAndCall("", ethers.ZeroAddress, "0x")).to.be.reverted;

      await expect(contractsRegistry.justAddProxyContract("", ethers.ZeroAddress)).to.be.reverted;

      await expect(contractsRegistry.removeContract("")).to.be.reverted;
    });
  });
});
