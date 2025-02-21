import { ethers } from "hardhat";
import { expect } from "chai";

import { impersonateAccount, setBalance } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";

import { AdminableProxyUpgrader, AdminableProxy, ERC20Mock } from "@ethers-v6";

describe("AdminableProxy", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let PROXY_UPGRADER: SignerWithAddress;

  let proxy: AdminableProxy;
  let tokenProxy: ERC20Mock;

  before("setup", async () => {
    [OWNER] = await ethers.getSigners();

    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    const AdminableProxyUpgrader = await ethers.getContractFactory("AdminableProxyUpgrader");
    const AdminableProxy = await ethers.getContractFactory("AdminableProxy");

    const token: ERC20Mock = await ERC20Mock.deploy("mock", "mock", 18);

    const adminableProxyUpgrader: AdminableProxyUpgrader = await AdminableProxyUpgrader.deploy();
    proxy = await AdminableProxy.deploy(await token.getAddress(), await adminableProxyUpgrader.getAddress(), "0x");

    tokenProxy = <ERC20Mock>token.attach(await proxy.getAddress());

    await impersonateAccount(await adminableProxyUpgrader.getAddress());
    PROXY_UPGRADER = await ethers.provider.getSigner(await adminableProxyUpgrader.getAddress());
    await setBalance(await PROXY_UPGRADER.getAddress(), ethers.parseEther("1"));

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("delegated functions", () => {
    const AMOUNT = 10;

    it("proxy admin cannot call delegated functions", async () => {
      await expect(tokenProxy.connect(PROXY_UPGRADER).mint(OWNER.address, AMOUNT))
        .to.be.revertedWithCustomError(proxy, "ProxyDeniedAdminAccess")
        .withArgs();
    });

    it("everyone except proxy admin can call delegated functions", async () => {
      await tokenProxy.mint(OWNER.address, AMOUNT);

      expect(await tokenProxy.balanceOf(OWNER.address)).to.equal(AMOUNT);
    });
  });
});
