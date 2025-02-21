import { ethers } from "hardhat";
import { expect } from "chai";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";

import { SBTMock } from "@ethers-v6";

const name = "testName";
const symbol = "TS";

describe("SBT", () => {
  const reverter = new Reverter();

  let FIRST: SignerWithAddress;

  let sbt: SBTMock;

  before("setup", async () => {
    [FIRST] = await ethers.getSigners();

    const SBTMock = await ethers.getContractFactory("SBTMock");
    sbt = await SBTMock.deploy();

    await sbt.__SBTMock_init(name, symbol);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should not initialize twice", async () => {
      await expect(sbt.__SBTMock_init(name, symbol))
        .to.be.revertedWithCustomError(sbt, "InvalidInitialization")
        .withArgs();
      await expect(sbt.mockInit(name, symbol)).to.be.revertedWithCustomError(sbt, "NotInitializing").withArgs();
    });
  });

  describe("init parameters", () => {
    it("should correctly init", async () => {
      expect(await sbt.name()).to.equal(name);
      expect(await sbt.symbol()).to.equal(symbol);
    });
  });

  describe("mint()", () => {
    it("should correctly mint", async () => {
      const tx = await sbt.mint(FIRST.address, 1337);

      expect(await sbt.tokenExists(1337)).to.be.true;

      expect(await sbt.balanceOf(FIRST.address)).to.equal(1n);
      expect(await sbt.ownerOf(1337)).to.equal(FIRST.address);

      expect(await sbt.tokenOf(FIRST.address, 0)).to.equal(1337n);
      expect(await sbt.tokensOf(FIRST.address)).to.deep.equal([1337n]);

      expect(await sbt.tokenURI(1337)).to.equal("");

      expect(tx).to.emit(sbt, "Transfer").withArgs(ethers.ZeroAddress, FIRST.address, 1337);
    });

    it("should not mint to null address", async () => {
      await expect(sbt.mint(ethers.ZeroAddress, 1))
        .to.be.revertedWithCustomError(sbt, "ReceiverIsZeroAddress")
        .withArgs();
    });

    it("should not mint token twice", async () => {
      await sbt.mint(FIRST.address, 1);

      await expect(sbt.mint(FIRST.address, 1)).to.be.revertedWithCustomError(sbt, "TokenAlreadyExists").withArgs(1);
    });
  });

  describe("burn()", () => {
    it("should correctly burn", async () => {
      const tx = await sbt.mint(FIRST.address, 1337);

      await sbt.burn(1337);

      expect(await sbt.tokenExists(0)).to.be.false;

      expect(await sbt.balanceOf(FIRST.address)).to.equal(0n);
      expect(await sbt.ownerOf(0)).to.equal(ethers.ZeroAddress);

      expect(await sbt.tokensOf(FIRST.address)).to.deep.equal([]);

      expect(tx).to.emit(sbt, "Transfer").withArgs(FIRST.address, ethers.ZeroAddress, 1337);
    });

    it("should not burn SBT that doesn't exist", async () => {
      await expect(sbt.burn(1337)).to.be.revertedWithCustomError(sbt, "TokenDoesNotExist").withArgs(1337);
    });
  });

  describe("setTokenURI()", () => {
    it("should correctly set token URI", async () => {
      await sbt.mint(FIRST.address, 1337);
      await sbt.setTokenURI(1337, "test");

      expect(await sbt.tokenURI(1337)).to.equal("test");
    });

    it("should not set uri for non-existent token", async () => {
      await expect(sbt.setTokenURI(1337, "")).to.be.revertedWithCustomError(sbt, "TokenDoesNotExist").withArgs(1337);
    });

    it("should reset token URI if token is burnder", async () => {
      await sbt.mint(FIRST.address, 1337);
      await sbt.setTokenURI(1337, "test");

      await sbt.burn(1337);

      expect(await sbt.tokenURI(1337)).to.equal("");
    });
  });

  describe("setBaseURI()", () => {
    it("should correctly set base URI", async () => {
      await sbt.setBaseURI("test");

      expect(await sbt.baseURI()).to.equal("test");
      expect(await sbt.tokenURI(1337)).to.equal("test1337");
    });

    it("should override base URI", async () => {
      await sbt.setBaseURI("test");

      await sbt.mint(FIRST.address, 1337);
      await sbt.setTokenURI(1337, "test");

      expect(await sbt.tokenURI(1337)).to.equal("test");
    });
  });

  describe("supportsInterface()", () => {
    it("should return correct values", async () => {
      const IERC721MetadaInterfaceID = "0x5b5e139f";
      const ISBTInterfaceID = "0xddd872b5";
      const IERC165InterfaceID = "0x01ffc9a7";

      expect(await sbt.supportsInterface(IERC721MetadaInterfaceID)).to.be.eq(true);
      expect(await sbt.supportsInterface(ISBTInterfaceID)).to.be.eq(true);
      expect(await sbt.supportsInterface(IERC165InterfaceID)).to.be.eq(true);

      const randomInterfaceID = "0xaaa1234d";

      expect(await sbt.supportsInterface(randomInterfaceID)).to.be.eq(false);
    });
  });
});
