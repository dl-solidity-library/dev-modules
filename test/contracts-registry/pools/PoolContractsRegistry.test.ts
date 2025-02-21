import { ethers } from "hardhat";
import { expect } from "chai";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";

import { PoolContractsRegistryMock, ContractsRegistryPoolMock, PoolMock, PoolUpgradeMock, ERC20Mock } from "@ethers-v6";

describe("PoolContractsRegistry", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let SECOND: SignerWithAddress;

  let poolContractsRegistry: PoolContractsRegistryMock;
  let contractsRegistry: ContractsRegistryPoolMock;
  let token: ERC20Mock;

  let POOL_1: SignerWithAddress;
  let POOL_2: SignerWithAddress;

  let NAME_1: string;
  let NAME_2: string;

  before("setup", async () => {
    [OWNER, SECOND, , POOL_1, POOL_2] = await ethers.getSigners();

    const ContractsRegistryPool = await ethers.getContractFactory("ContractsRegistryPoolMock");
    const PoolContractsRegistry = await ethers.getContractFactory("PoolContractsRegistryMock");
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

    contractsRegistry = await ContractsRegistryPool.deploy();
    const _poolContractsRegistry = await PoolContractsRegistry.deploy();
    token = await ERC20Mock.deploy("Mock", "Mock", 18);

    await contractsRegistry.__OwnableContractsRegistry_init();

    await contractsRegistry.addProxyContract(
      await contractsRegistry.POOL_CONTRACTS_REGISTRY_NAME(),
      await _poolContractsRegistry.getAddress(),
    );
    await contractsRegistry.addContract(await contractsRegistry.TOKEN_NAME(), await token.getAddress());
    await contractsRegistry.addContract(await contractsRegistry.POOL_FACTORY_NAME(), OWNER);

    poolContractsRegistry = <PoolContractsRegistryMock>(
      PoolContractsRegistry.attach(await contractsRegistry.getPoolContractsRegistryContract())
    );

    await poolContractsRegistry.__AOwnablePoolContractsRegistry_init();

    await contractsRegistry.injectDependencies(await contractsRegistry.POOL_CONTRACTS_REGISTRY_NAME());

    NAME_1 = await poolContractsRegistry.POOL_1_NAME();
    NAME_2 = await poolContractsRegistry.POOL_2_NAME();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should not initialize twice", async () => {
      await expect(poolContractsRegistry.__AOwnablePoolContractsRegistry_init())
        .to.be.revertedWithCustomError(poolContractsRegistry, "InvalidInitialization")
        .withArgs();

      await expect(poolContractsRegistry.mockInit())
        .to.be.revertedWithCustomError(poolContractsRegistry, "NotInitializing")
        .withArgs();
    });

    it("should not set dependencies from non dependant", async () => {
      const injector = await poolContractsRegistry.getInjector();

      await expect(poolContractsRegistry.setDependencies(OWNER.address, "0x"))
        .to.be.revertedWithCustomError(poolContractsRegistry, "NotAnInjector")
        .withArgs(injector, OWNER.address);
    });

    it("only owner should call these functions", async () => {
      await expect(poolContractsRegistry.connect(SECOND).setNewImplementations([], []))
        .to.be.revertedWithCustomError(contractsRegistry, "OwnableUnauthorizedAccount")
        .withArgs(SECOND);

      await expect(poolContractsRegistry.connect(SECOND).injectDependenciesToExistingPools("", 0, 0))
        .to.be.revertedWithCustomError(contractsRegistry, "OwnableUnauthorizedAccount")
        .withArgs(SECOND);

      await expect(poolContractsRegistry.connect(SECOND).injectDependenciesToExistingPoolsWithData("", "0x", 0, 0))
        .to.be.revertedWithCustomError(contractsRegistry, "OwnableUnauthorizedAccount")
        .withArgs(SECOND);
    });
  });

  describe("setNewImplementations()", () => {
    it("should successfully add and get implementation", async () => {
      await poolContractsRegistry.setNewImplementations([NAME_1], [await token.getAddress()]);

      expect(await poolContractsRegistry.getImplementation(NAME_1)).to.equal(await token.getAddress());
      expect(await poolContractsRegistry.getProxyBeacon(NAME_1)).not.to.equal(ethers.ZeroAddress);
    });

    it("should not get not existing implementation", async () => {
      await expect(poolContractsRegistry.getImplementation(NAME_1))
        .to.be.revertedWithCustomError(poolContractsRegistry, "NoMappingExists")
        .withArgs(NAME_1);

      await expect(poolContractsRegistry.getProxyBeacon(NAME_1))
        .to.be.revertedWithCustomError(poolContractsRegistry, "ProxyDoesNotExist")
        .withArgs(NAME_1);
    });
  });

  describe("addProxyPool()", () => {
    it("should add pool", async () => {
      await poolContractsRegistry.addProxyPool(NAME_1, POOL_1.address);
      await poolContractsRegistry.addProxyPool(NAME_1, POOL_2.address);

      expect(await poolContractsRegistry.isPool(NAME_1, POOL_1.address)).to.be.true;
      expect(await poolContractsRegistry.countPools(NAME_1)).to.equal(2n);
      expect(await poolContractsRegistry.countPools(NAME_2)).to.equal(0n);
    });

    it("should list added pools", async () => {
      await poolContractsRegistry.addProxyPool(NAME_1, POOL_1.address);
      await poolContractsRegistry.addProxyPool(NAME_1, POOL_2.address);

      expect(await poolContractsRegistry.listPools(NAME_1, 0, 2)).to.deep.equal([POOL_1.address, POOL_2.address]);
      expect(await poolContractsRegistry.listPools(NAME_1, 0, 10)).to.deep.equal([POOL_1.address, POOL_2.address]);
      expect(await poolContractsRegistry.listPools(NAME_1, 1, 1)).to.deep.equal([POOL_2.address]);
      expect(await poolContractsRegistry.listPools(NAME_1, 2, 0)).to.deep.equal([]);
      expect(await poolContractsRegistry.listPools(NAME_2, 0, 2)).to.deep.equal([]);
    });

    it("only owner should be able to add pools", async () => {
      await expect(poolContractsRegistry.connect(POOL_1).addProxyPool(NAME_1, POOL_1.address))
        .to.be.revertedWithCustomError(poolContractsRegistry, "CallerNotAFactory")
        .withArgs(POOL_1, OWNER.address);
    });
  });

  describe("injectDependenciesToExistingPools()", () => {
    let pool: PoolMock;

    beforeEach("setup", async () => {
      const Pool = await ethers.getContractFactory("PoolMock");
      pool = await Pool.deploy();
    });

    it("should inject dependencies", async () => {
      await poolContractsRegistry.addProxyPool(NAME_1, await pool.getAddress());

      expect(await pool.token()).to.equal(ethers.ZeroAddress);

      await poolContractsRegistry.injectDependenciesToExistingPools(NAME_1, 0, 1);

      expect(await pool.token()).to.equal(await token.getAddress());
    });

    it("should inject dependencies with data", async () => {
      await poolContractsRegistry.addProxyPool(NAME_1, await pool.getAddress());

      expect(await pool.token()).to.equal(ethers.ZeroAddress);

      await poolContractsRegistry.injectDependenciesToExistingPoolsWithData(NAME_1, "0x", 0, 1);

      expect(await pool.token()).to.equal(await token.getAddress());
    });

    it("should not inject dependencies to 0 pools", async () => {
      await expect(poolContractsRegistry.injectDependenciesToExistingPools(NAME_1, 0, 1))
        .to.be.revertedWithCustomError(poolContractsRegistry, "NoPoolsToInject")
        .withArgs(NAME_1);
    });
  });

  describe("upgrade pools", () => {
    let pool: PoolMock;
    let poolUpgrade: PoolUpgradeMock;

    beforeEach("setup", async () => {
      const Pool = await ethers.getContractFactory("PoolMock");
      const PoolUpgrade = await ethers.getContractFactory("PoolUpgradeMock");

      pool = await Pool.deploy();
      poolUpgrade = await PoolUpgrade.deploy();
    });

    it("should upgrade pools", async () => {
      await poolContractsRegistry.setNewImplementations([NAME_1], [await pool.getAddress()]);

      const beacon = await poolContractsRegistry.getProxyBeacon(NAME_1);

      expect(await poolContractsRegistry.getImplementation(NAME_1)).to.equal(await pool.getAddress());

      await poolContractsRegistry.setNewImplementations([NAME_1], [await poolUpgrade.getAddress()]);

      expect(await poolContractsRegistry.getProxyBeacon(NAME_1)).to.equal(beacon);
      expect(await poolContractsRegistry.getImplementation(NAME_1)).to.equal(await poolUpgrade.getAddress());

      await poolContractsRegistry.setNewImplementations([NAME_1], [await poolUpgrade.getAddress()]);

      expect(await poolContractsRegistry.getProxyBeacon(NAME_1)).to.equal(beacon);
      expect(await poolContractsRegistry.getImplementation(NAME_1)).to.equal(await poolUpgrade.getAddress());
    });
  });
});
