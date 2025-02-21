import { ethers } from "hardhat";
import { expect } from "chai";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";

import { AdminableProxyUpgrader, AdminableProxy, ERC20Mock } from "@ethers-v6";

describe("AdminableProxyUpgrader", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let SECOND: SignerWithAddress;

  let adminableProxyUpgrader: AdminableProxyUpgrader;
  let token: ERC20Mock;
  let proxy: AdminableProxy;

  before("setup", async () => {
    [OWNER, SECOND] = await ethers.getSigners();

    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    const AdminableProxyUpgrader = await ethers.getContractFactory("AdminableProxyUpgrader");
    const AdminableProxy = await ethers.getContractFactory("AdminableProxy");

    token = await ERC20Mock.deploy("mock", "mock", 18);

    adminableProxyUpgrader = await AdminableProxyUpgrader.deploy();
    proxy = await AdminableProxy.deploy(await token.getAddress(), await adminableProxyUpgrader.getAddress(), "0x");

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("upgrade", () => {
    it("only owner should upgrade", async () => {
      await expect(
        adminableProxyUpgrader.connect(SECOND).upgrade(await proxy.getAddress(), await proxy.getAddress(), "0x"),
      )
        .to.be.revertedWithCustomError(adminableProxyUpgrader, "UnauthorizedAccount")
        .withArgs(SECOND);
    });
  });

  describe("getImplementation", () => {
    it("should get implementation", async () => {
      expect(await adminableProxyUpgrader.getImplementation(await proxy.getAddress())).to.equal(
        await token.getAddress(),
      );
    });
  });
});
