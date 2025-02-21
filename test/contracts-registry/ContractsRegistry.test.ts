import { ethers } from "hardhat";
import { expect } from "chai";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";

import { ContractsRegistryMock, DependantMock, DependantUpgradeMock, ERC20Mock } from "@ethers-v6";

describe("ContractsRegistry", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let SECOND: SignerWithAddress;

  let contractsRegistry: ContractsRegistryMock;

  before("setup", async () => {
    [OWNER, SECOND] = await ethers.getSigners();

    const ContractsRegistry = await ethers.getContractFactory("ContractsRegistryMock");
    contractsRegistry = await ContractsRegistry.deploy();

    await contractsRegistry.__OwnableContractsRegistry_init();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should not initialize twice", async () => {
      await expect(contractsRegistry.mockInit())
        .to.be.revertedWithCustomError(contractsRegistry, "NotInitializing")
        .withArgs();

      await expect(contractsRegistry.__OwnableContractsRegistry_init())
        .to.be.revertedWithCustomError(contractsRegistry, "InvalidInitialization")
        .withArgs();
    });

    it("should get proxy upgrader", async () => {
      await contractsRegistry.getProxyUpgrader();
    });

    it("only owner should call these functions", async () => {
      await expect(contractsRegistry.connect(SECOND).injectDependencies(""))
        .to.be.revertedWithCustomError(contractsRegistry, "OwnableUnauthorizedAccount")
        .withArgs(SECOND);

      await expect(contractsRegistry.connect(SECOND).injectDependenciesWithData("", "0x"))
        .to.be.revertedWithCustomError(contractsRegistry, "OwnableUnauthorizedAccount")
        .withArgs(SECOND);

      await expect(contractsRegistry.connect(SECOND).upgradeContract("", ethers.ZeroAddress))
        .to.be.revertedWithCustomError(contractsRegistry, "OwnableUnauthorizedAccount")
        .withArgs(SECOND);

      await expect(contractsRegistry.connect(SECOND).upgradeContractAndCall("", ethers.ZeroAddress, "0x"))
        .to.be.revertedWithCustomError(contractsRegistry, "OwnableUnauthorizedAccount")
        .withArgs(SECOND);

      await expect(contractsRegistry.connect(SECOND).addContract("", ethers.ZeroAddress))
        .to.be.revertedWithCustomError(contractsRegistry, "OwnableUnauthorizedAccount")
        .withArgs(SECOND);

      await expect(contractsRegistry.connect(SECOND).addProxyContract("", ethers.ZeroAddress))
        .to.be.revertedWithCustomError(contractsRegistry, "OwnableUnauthorizedAccount")
        .withArgs(SECOND);

      await expect(contractsRegistry.connect(SECOND).addProxyContractAndCall("", ethers.ZeroAddress, "0x"))
        .to.be.revertedWithCustomError(contractsRegistry, "OwnableUnauthorizedAccount")
        .withArgs(SECOND);

      await expect(contractsRegistry.connect(SECOND).justAddProxyContract("", ethers.ZeroAddress))
        .to.be.revertedWithCustomError(contractsRegistry, "OwnableUnauthorizedAccount")
        .withArgs(SECOND);

      await expect(contractsRegistry.connect(SECOND).removeContract(""))
        .to.be.revertedWithCustomError(contractsRegistry, "OwnableUnauthorizedAccount")
        .withArgs(SECOND);
    });
  });

  describe("contract management", async () => {
    it("should fail adding ethers.ZeroAddress address", async () => {
      await expect(contractsRegistry.addContract(await contractsRegistry.DEPENDANT_NAME(), ethers.ZeroAddress))
        .to.be.revertedWithCustomError(contractsRegistry, "ZeroAddressProvided")
        .withArgs(await contractsRegistry.DEPENDANT_NAME());

      await expect(contractsRegistry.addProxyContract(await contractsRegistry.DEPENDANT_NAME(), ethers.ZeroAddress))
        .to.be.revertedWithCustomError(contractsRegistry, "ZeroAddressProvided")
        .withArgs(await contractsRegistry.DEPENDANT_NAME());

      await expect(contractsRegistry.justAddProxyContract(await contractsRegistry.DEPENDANT_NAME(), ethers.ZeroAddress))
        .to.be.revertedWithCustomError(contractsRegistry, "ZeroAddressProvided")
        .withArgs(await contractsRegistry.DEPENDANT_NAME());
    });

    it("should add and remove the contract", async () => {
      const DependantMock = await ethers.getContractFactory("DependantMock");
      const dependant = await DependantMock.deploy();

      await expect(contractsRegistry.removeContract(await contractsRegistry.DEPENDANT_NAME()))
        .to.be.revertedWithCustomError(contractsRegistry, "NoMappingExists")
        .withArgs(await contractsRegistry.DEPENDANT_NAME());

      await contractsRegistry.addContract(await contractsRegistry.DEPENDANT_NAME(), await dependant.getAddress());

      expect(await contractsRegistry.getDependantContract()).to.equal(await dependant.getAddress());
      expect(await contractsRegistry.hasContract(await contractsRegistry.DEPENDANT_NAME())).to.be.true;

      await contractsRegistry.removeContract(await contractsRegistry.DEPENDANT_NAME());

      await expect(contractsRegistry.getDependantContract())
        .to.be.revertedWithCustomError(contractsRegistry, "NoMappingExists")
        .withArgs(await contractsRegistry.DEPENDANT_NAME());

      expect(await contractsRegistry.hasContract(await contractsRegistry.DEPENDANT_NAME())).to.be.false;
    });

    it("should add and remove the proxy contract", async () => {
      const DependantMock = await ethers.getContractFactory("DependantMock");
      const _dependant = await DependantMock.deploy();

      await expect(contractsRegistry.getImplementation(await contractsRegistry.DEPENDANT_NAME()))
        .to.be.revertedWithCustomError(contractsRegistry, "NoMappingExists")
        .withArgs(await contractsRegistry.DEPENDANT_NAME());

      await contractsRegistry.addProxyContract(await contractsRegistry.DEPENDANT_NAME(), await _dependant.getAddress());

      expect(await contractsRegistry.hasContract(await contractsRegistry.DEPENDANT_NAME())).to.be.true;

      await contractsRegistry.removeContract(await contractsRegistry.DEPENDANT_NAME());

      expect(await contractsRegistry.hasContract(await contractsRegistry.DEPENDANT_NAME())).to.be.false;
    });

    it("should add and remove proxy without dependant", async () => {
      const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
      const _token = await ERC20Mock.deploy("Mock", "Mock", 18);

      await contractsRegistry.addProxyContractAndCall(
        await contractsRegistry.TOKEN_NAME(),
        await _token.getAddress(),
        "0x",
      );
      await contractsRegistry.removeContract(await contractsRegistry.TOKEN_NAME());
    });

    it("should just add and remove the proxy contract", async () => {
      const DependantMock = await ethers.getContractFactory("DependantMock");
      const _dependant = await DependantMock.deploy();

      await contractsRegistry.addProxyContract(await contractsRegistry.DEPENDANT_NAME(), await _dependant.getAddress());

      const crdProxyAddr = await contractsRegistry.getDependantContract();

      await contractsRegistry.removeContract(await contractsRegistry.DEPENDANT_NAME());
      await contractsRegistry.justAddProxyContract(await contractsRegistry.DEPENDANT_NAME(), crdProxyAddr);

      expect(await contractsRegistry.hasContract(await contractsRegistry.DEPENDANT_NAME())).to.be.true;

      await contractsRegistry.removeContract(await contractsRegistry.DEPENDANT_NAME());

      expect(await contractsRegistry.hasContract(await contractsRegistry.DEPENDANT_NAME())).to.be.false;
    });
  });

  describe("contract upgrades", () => {
    let _dependant: DependantMock;
    let _dependantUpgrade: DependantUpgradeMock;

    let dependant: DependantUpgradeMock;

    beforeEach("setup", async () => {
      const DependantMock = await ethers.getContractFactory("DependantMock");
      const DependantUpgradeMock = await ethers.getContractFactory("DependantUpgradeMock");

      _dependant = await DependantMock.deploy();
      _dependantUpgrade = await DependantUpgradeMock.deploy();

      await contractsRegistry.addProxyContract(await contractsRegistry.DEPENDANT_NAME(), await _dependant.getAddress());

      dependant = <DependantUpgradeMock>DependantUpgradeMock.attach(await contractsRegistry.getDependantContract());
    });

    it("should not upgrade non-proxy contract", async () => {
      const DependantMock = await ethers.getContractFactory("DependantMock");
      const dependant = await DependantMock.deploy();

      await contractsRegistry.addContract(await contractsRegistry.DEPENDANT_NAME(), await dependant.getAddress());

      await expect(contractsRegistry.getImplementation(await contractsRegistry.DEPENDANT_NAME()))
        .to.be.revertedWithCustomError(contractsRegistry, "NotAProxy")
        .withArgs(await contractsRegistry.DEPENDANT_NAME(), await dependant.getAddress());

      await expect(
        contractsRegistry.upgradeContract(
          await contractsRegistry.DEPENDANT_NAME(),
          await _dependantUpgrade.getAddress(),
        ),
      )
        .to.be.revertedWithCustomError(contractsRegistry, "NotAProxy")
        .withArgs(await contractsRegistry.DEPENDANT_NAME(), await dependant.getAddress());
    });

    it("should upgrade the contract", async () => {
      await expect(dependant.addedFunction()).to.be.reverted;

      expect(await contractsRegistry.getImplementation(await contractsRegistry.DEPENDANT_NAME())).to.equal(
        await _dependant.getAddress(),
      );

      await contractsRegistry.upgradeContract(
        await contractsRegistry.DEPENDANT_NAME(),
        await _dependantUpgrade.getAddress(),
      );

      expect(await contractsRegistry.getImplementation(await contractsRegistry.DEPENDANT_NAME())).to.equal(
        await _dependantUpgrade.getAddress(),
      );

      expect(await dependant.addedFunction()).to.equal(42n);
    });

    it("should not upgrade non existing contract", async () => {
      await expect(contractsRegistry.upgradeContract("RANDOM CONTRACT", await _dependantUpgrade.getAddress()))
        .to.be.revertedWithCustomError(contractsRegistry, "NoMappingExists")
        .withArgs("RANDOM CONTRACT");
    });

    it("should upgrade and call the contract", async () => {
      await expect(dependant.addedFunction()).to.be.reverted;

      let data = _dependantUpgrade.interface.encodeFunctionData("doUpgrade", [42]);

      await contractsRegistry.upgradeContractAndCall(
        await contractsRegistry.DEPENDANT_NAME(),
        await _dependantUpgrade.getAddress(),
        data,
      );

      expect(await dependant.dummyValue()).to.equal(42n);
    });
  });

  describe("dependency injection", () => {
    let dependant: DependantUpgradeMock;
    let token: ERC20Mock;

    beforeEach("setup", async () => {
      const DependantUpgradeMock = await ethers.getContractFactory("DependantUpgradeMock");
      const DependantMock = await ethers.getContractFactory("DependantMock");
      const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

      const _dependant = await DependantMock.deploy();
      token = await ERC20Mock.deploy("Mock", "Mock", 18);

      await contractsRegistry.addProxyContract(await contractsRegistry.DEPENDANT_NAME(), await _dependant.getAddress());

      await contractsRegistry.addContract(await contractsRegistry.TOKEN_NAME(), await token.getAddress());

      dependant = <DependantUpgradeMock>DependantUpgradeMock.attach(await contractsRegistry.getDependantContract());
    });

    it("should inject dependencies", async () => {
      expect(await dependant.token()).to.equal(ethers.ZeroAddress);

      await contractsRegistry.injectDependencies(await contractsRegistry.DEPENDANT_NAME());

      expect(await dependant.token()).to.equal(await token.getAddress());
    });

    it("should inject dependencies with data", async () => {
      expect(await dependant.token()).to.equal(ethers.ZeroAddress);

      await contractsRegistry.injectDependenciesWithData(await contractsRegistry.DEPENDANT_NAME(), "0x112233");

      expect(await dependant.token()).to.equal(await token.getAddress());
    });

    it("should not inject dependencies", async () => {
      await expect(contractsRegistry.injectDependencies("RANDOM CONTRACT"))
        .to.be.revertedWithCustomError(contractsRegistry, "NoMappingExists")
        .withArgs("RANDOM CONTRACT");
    });

    it("should not allow random users to inject dependencies", async () => {
      await contractsRegistry.injectDependencies(await contractsRegistry.DEPENDANT_NAME());

      expect(await dependant.getInjector()).to.equal(await contractsRegistry.getAddress());

      await expect(dependant.setDependencies(await contractsRegistry.getAddress(), "0x"))
        .to.be.revertedWithCustomError(dependant, "NotAnInjector")
        .withArgs(await contractsRegistry.getAddress(), OWNER.address);
    });

    it("should not allow random users to set new injector", async () => {
      await contractsRegistry.injectDependencies(await contractsRegistry.DEPENDANT_NAME());

      await expect(dependant.setInjector(OWNER))
        .to.be.revertedWithCustomError(dependant, "NotAnInjector")
        .withArgs(await dependant.getInjector(), OWNER.address);
    });
  });
});
