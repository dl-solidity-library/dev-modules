import { ethers } from "hardhat";
import { expect } from "chai";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";

import {
  PoolFactoryMock,
  PublicBeaconProxy,
  PoolContractsRegistryMock,
  ContractsRegistryPoolMock,
  PoolMock,
  PoolUpgradeMock,
  ERC20Mock,
} from "@ethers-v6";

describe("PoolFactory", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;

  let poolFactory: PoolFactoryMock;
  let poolContractsRegistry: PoolContractsRegistryMock;
  let contractsRegistry: ContractsRegistryPoolMock;
  let token: ERC20Mock;

  let NAME_1: string;
  let NAME_2: string;

  before("setup", async () => {
    [OWNER] = await ethers.getSigners();

    const ContractsRegistryPool = await ethers.getContractFactory("ContractsRegistryPoolMock");
    const PoolFactory = await ethers.getContractFactory("PoolFactoryMock");
    const PoolContractsRegistry = await ethers.getContractFactory("PoolContractsRegistryMock");
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

    contractsRegistry = await ContractsRegistryPool.deploy();
    const _poolFactory = await PoolFactory.deploy();
    const _poolContractsRegistry = await PoolContractsRegistry.deploy();
    token = await ERC20Mock.deploy("Mock", "Mock", 18);

    await contractsRegistry.__OwnableContractsRegistry_init();

    await contractsRegistry.addProxyContract(
      await contractsRegistry.POOL_CONTRACTS_REGISTRY_NAME(),
      await _poolContractsRegistry.getAddress(),
    );
    await contractsRegistry.addProxyContract(
      await contractsRegistry.POOL_FACTORY_NAME(),
      await _poolFactory.getAddress(),
    );
    await contractsRegistry.addContract(await contractsRegistry.TOKEN_NAME(), await token.getAddress());

    poolContractsRegistry = <PoolContractsRegistryMock>(
      PoolContractsRegistry.attach(await contractsRegistry.getPoolContractsRegistryContract())
    );
    poolFactory = <PoolFactoryMock>PoolFactory.attach(await contractsRegistry.getPoolFactoryContract());

    await poolContractsRegistry.__AOwnablePoolContractsRegistry_init();

    await contractsRegistry.injectDependencies(await contractsRegistry.POOL_CONTRACTS_REGISTRY_NAME());
    await contractsRegistry.injectDependencies(await contractsRegistry.POOL_FACTORY_NAME());

    NAME_1 = await poolContractsRegistry.POOL_1_NAME();
    NAME_2 = await poolContractsRegistry.POOL_2_NAME();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should not set dependencies from non dependant", async () => {
      await expect(poolFactory.setDependencies(OWNER, "0x"))
        .to.be.revertedWithCustomError(poolFactory, "NotAnInjector")
        .withArgs(await poolContractsRegistry.getInjector(), OWNER.address);
    });
  });

  describe("after setting the implementation", () => {
    let poolImpl: PoolMock;

    beforeEach("setup", async () => {
      const PoolMock = await ethers.getContractFactory("PoolMock");
      poolImpl = await PoolMock.deploy();

      await poolContractsRegistry.setNewImplementations([NAME_1], [await poolImpl.getAddress()]);
    });

    describe("deploy()", () => {
      it("should deploy pool", async () => {
        await poolFactory.deployPool();

        expect(await poolContractsRegistry.countPools(NAME_1)).to.equal(1n);
        expect(await poolContractsRegistry.countPools(NAME_2)).to.equal(0n);

        const PoolMock = await ethers.getContractFactory("PoolMock");
        const PublicBeaconProxy = await ethers.getContractFactory("PublicBeaconProxy");

        const pool = <PoolMock>PoolMock.attach((await poolContractsRegistry.listPools(NAME_1, 0, 1))[0]);
        const beaconProxy = <PublicBeaconProxy>PublicBeaconProxy.attach(await pool.getAddress());

        expect(await beaconProxy.implementation()).to.equal(await poolImpl.getAddress());
        expect(await pool.token()).not.to.equal(ethers.ZeroAddress);
      });

      it("should not register pools", async () => {
        await contractsRegistry.addContract(await contractsRegistry.POOL_FACTORY_NAME(), OWNER);
        await contractsRegistry.injectDependencies(await contractsRegistry.POOL_CONTRACTS_REGISTRY_NAME());

        await expect(poolFactory.deployPool())
          .to.be.revertedWithCustomError(poolContractsRegistry, "CallerNotAFactory")
          .withArgs(await poolFactory.getAddress(), OWNER.address);
      });

      it("should deploy several pools", async () => {
        await poolFactory.deployPool();
        await poolFactory.deployPool();
        await poolFactory.deployPool();

        expect(await poolContractsRegistry.countPools(NAME_1)).to.equal(3n);
      });

      it("should set access correctly", async () => {
        await poolFactory.deployPool();

        const PoolMock = await ethers.getContractFactory("PoolMock");
        const pool = <PoolMock>PoolMock.attach((await poolContractsRegistry.listPools(NAME_1, 0, 1))[0]);

        await expect(poolContractsRegistry.addProxyPool(NAME_1, await poolFactory.getAddress()))
          .to.be.revertedWithCustomError(poolContractsRegistry, "CallerNotAFactory")
          .withArgs(OWNER.address, await poolFactory.getAddress());

        await expect(pool.setDependencies(await contractsRegistry.getAddress(), "0x"))
          .to.be.revertedWithCustomError(poolFactory, "NotAnInjector")
          .withArgs(await pool.getInjector(), OWNER.address);
      });

      it("should upgrade pools", async () => {
        await poolFactory.deployPool();

        const PoolUpgradeMock = await ethers.getContractFactory("PoolUpgradeMock");
        const pool1 = <PoolUpgradeMock>PoolUpgradeMock.attach((await poolContractsRegistry.listPools(NAME_1, 0, 1))[0]);

        await expect(pool1.addedFunction()).to.be.reverted;

        const poolUpgrade = await PoolUpgradeMock.deploy();
        await poolContractsRegistry.setNewImplementations([NAME_1], [await poolUpgrade.getAddress()]);

        expect(await pool1.addedFunction()).to.equal(42n);

        await poolFactory.deployPool();

        const pool2 = <PoolUpgradeMock>PoolUpgradeMock.attach((await poolContractsRegistry.listPools(NAME_1, 1, 1))[0]);
        expect(await pool2.addedFunction()).to.equal(42n);
      });
    });

    describe("deploy2() predictPoolAddress()", () => {
      const SALT1 = "pool_salt1";
      const SALT2 = "pool_salt2";

      it("should deploy to the predicted address", async () => {
        const predictedAddress1 = await poolFactory.predictPoolAddress(SALT1);
        const predictedAddress2 = await poolFactory.predictPoolAddress(SALT2);

        await poolFactory.deploy2Pool(SALT1);
        await poolFactory.deploy2Pool(SALT2);

        expect(await poolContractsRegistry.countPools(NAME_1)).to.equal(2n);
        expect(await poolContractsRegistry.countPools(NAME_2)).to.equal(0n);

        const pools = await poolContractsRegistry.listPools(NAME_1, 0, 2);

        expect(pools).to.deep.equal([predictedAddress1, predictedAddress2]);

        const PoolMock = await ethers.getContractFactory("PoolMock");
        const PublicBeaconProxy = await ethers.getContractFactory("PublicBeaconProxy");

        const poolProxies = await Promise.all(pools.map(async (pool: string) => <PoolMock>PoolMock.attach(pool)));
        const beaconProxies = await Promise.all(
          pools.map(async (pool: string) => <PublicBeaconProxy>PublicBeaconProxy.attach(pool)),
        );

        const tokens = await Promise.all(poolProxies.map(async (poolProxy: PoolMock) => await poolProxy.token()));
        const implementations = await Promise.all(
          beaconProxies.map(async (beaconProxy: PublicBeaconProxy) => await beaconProxy.implementation()),
        );

        expect(tokens).to.deep.equal([await token.getAddress(), await token.getAddress()]);
        expect(implementations).to.deep.equal([await poolImpl.getAddress(), await poolImpl.getAddress()]);
      });

      it("should revert when deploying the pool with the same salt", async () => {
        await poolFactory.deploy2Pool(SALT1);

        await expect(poolFactory.deploy2Pool(SALT1)).to.be.reverted;
      });
    });
  });
});
