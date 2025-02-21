import { ethers } from "hardhat";
import { expect } from "chai";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";

import { ProxyBeacon, ERC20Mock } from "@ethers-v6";

describe("ProxyBeacon", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let SECOND: SignerWithAddress;

  let proxyBeacon: ProxyBeacon;
  let token: ERC20Mock;

  before("setup", async () => {
    [OWNER, SECOND] = await ethers.getSigners();

    const ProxyBeacon = await ethers.getContractFactory("ProxyBeacon");
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

    proxyBeacon = await ProxyBeacon.deploy();
    token = await ERC20Mock.deploy("mock", "mock", 18);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("functions", () => {
    it("should upgrade", async () => {
      expect(await proxyBeacon.implementation()).to.equal(ethers.ZeroAddress);

      await proxyBeacon.upgradeTo(await token.getAddress());

      expect(await proxyBeacon.implementation()).to.equal(await token.getAddress());
    });

    it("should not upgrade to non-contract", async () => {
      await expect(proxyBeacon.upgradeTo(SECOND))
        .to.be.revertedWithCustomError(proxyBeacon, "NewImplementationNotAContract")
        .withArgs(SECOND);
    });

    it("only owner should upgrade", async () => {
      await expect(proxyBeacon.connect(SECOND).upgradeTo(await token.getAddress()))
        .to.be.revertedWithCustomError(proxyBeacon, "UnauthorizedAccount")
        .withArgs(SECOND);
    });
  });
});
