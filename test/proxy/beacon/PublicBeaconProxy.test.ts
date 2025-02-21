import { ethers } from "hardhat";
import { expect } from "chai";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";

import { PublicBeaconProxy, ProxyBeacon, ERC20Mock } from "@ethers-v6";

describe("ProxyBeacon", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;

  let proxyBeacon: ProxyBeacon;
  let token: ERC20Mock;

  before("setup", async () => {
    [OWNER] = await ethers.getSigners();

    const ProxyBeacon = await ethers.getContractFactory("ProxyBeacon");
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

    proxyBeacon = await ProxyBeacon.deploy();
    token = await ERC20Mock.deploy("mock", "mock", 18);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("functions", () => {
    it("should get implementation", async () => {
      await proxyBeacon.upgradeTo(await token.getAddress());

      const PublicBeaconProxy = await ethers.getContractFactory("PublicBeaconProxy");
      const proxy: PublicBeaconProxy = await PublicBeaconProxy.deploy(proxyBeacon, "0x");

      expect(await proxyBeacon.implementation()).to.equal(await token.getAddress());
      expect(await proxy.implementation()).to.equal(await token.getAddress());
    });
  });
});
