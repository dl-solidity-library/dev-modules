import { ethers } from "hardhat";
import { expect } from "chai";

import { Reverter } from "@/test/helpers/reverter";
import { wei } from "@/scripts/utils/utils";

import { DecimalsConverterMock } from "@ethers-v6";

describe("DecimalsConverter", () => {
  const reverter = new Reverter();

  let mock: DecimalsConverterMock;

  before("setup", async () => {
    const DecimalsConverterMock = await ethers.getContractFactory("DecimalsConverterMock");
    mock = await DecimalsConverterMock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("decimals", () => {
    it("should return correct decimals", async () => {
      const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

      const token1 = await ERC20Mock.deploy("MK1", "MK1", 18);
      const token2 = await ERC20Mock.deploy("MK2", "MK2", 3);

      expect(await mock.decimals(await token1.getAddress())).to.equal(18n);
      expect(await mock.decimals(await token2.getAddress())).to.equal(3n);
    });
  });

  describe("convert", () => {
    it("should convert", async () => {
      expect(await mock.convert(wei("1"), 18, 6)).to.equal(wei("1", 6));
      expect(await mock.convert(wei("1", 6), 6, 18)).to.equal(wei("1"));
      expect(await mock.convert(wei("1", 6), 18, 18)).to.equal(wei("1", 6));
    });

    it("should convert tokens", async () => {
      const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

      const token1 = await ERC20Mock.deploy("MK1", "MK1", 18);
      const token2 = await ERC20Mock.deploy("MK2", "MK2", 3);

      expect(await mock.convertTokens(wei("1"), await token1.getAddress(), await token2.getAddress())).to.equal(
        wei("1", 3),
      );
      expect(await mock.convertTokens(wei("1", 3), await token2.getAddress(), await token1.getAddress())).to.equal(
        wei("1"),
      );
    });
  });

  describe("to18", () => {
    it("should convert to 18", async () => {
      expect(await mock.to18(wei("1", 6), 6)).to.equal(wei("1"));
      expect(await mock.to18(wei("1", 8), 8)).to.equal(wei("1"));
      expect(await mock.to18(wei("1", 6), 8)).to.equal(wei("1", 16));
      expect(await mock.to18(wei("1", 30), 30)).to.equal(wei("1"));
    });

    it("should convert from token decimals to 18", async () => {
      const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

      const token1 = await ERC20Mock.deploy("MK1", "MK1", 6);
      expect(await mock.tokenTo18(wei("1", 6), await token1.getAddress())).to.equal(wei("1"));

      const token2 = await ERC20Mock.deploy("MK2", "MK2", 6);
      expect(await mock.tokenTo18(wei("1", 8), await token2.getAddress())).to.equal(wei("1", 20));

      const token3 = await ERC20Mock.deploy("MK3", "MK3", 18);
      expect(await mock.tokenTo18(wei("1", 6), await token3.getAddress())).to.equal(wei("1", 6));

      const token4 = await ERC20Mock.deploy("MK4", "MK4", 30);
      expect(await mock.tokenTo18(wei("1", 30), await token4.getAddress())).to.equal(wei("1"));
    });
  });

  describe("to18Safe", () => {
    it("should correctly convert to 18", async () => {
      expect(await mock.to18Safe(wei("1", 6), 6)).to.equal(wei("1"));
      expect(await mock.to18Safe(wei("1", 8), 8)).to.equal(wei("1"));
    });

    it("should correctly convert from token decimals to 18", async () => {
      const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

      const token1 = await ERC20Mock.deploy("MK1", "MK1", 6);
      expect(await mock.tokenTo18Safe(wei("1", 6), await token1.getAddress())).to.equal(wei("1"));

      const token2 = await ERC20Mock.deploy("MK2", "MK2", 8);
      expect(await mock.tokenTo18Safe(wei("1", 8), await token2.getAddress())).to.equal(wei("1"));
    });

    it("should get exception if the result of conversion is zero", async () => {
      await expect(mock.to18Safe(wei("1", 11), 30))
        .to.be.revertedWithCustomError(mock, "ConversionFailed")
        .withArgs();
    });
  });

  describe("from18", () => {
    it("should convert from 18", async () => {
      expect(await mock.from18(wei("1"), 6)).to.equal(wei("1", 6));
      expect(await mock.from18(wei("1"), 8)).to.equal(wei("1", 8));
      expect(await mock.from18(wei("1", 16), 8)).to.equal(wei("1", 6));
      expect(await mock.from18(wei("1", 5), 8)).to.equal(0n);
      expect(await mock.from18(wei("1"), 30)).to.equal(wei("1", 30));
    });

    it("should convert from 18 to token to token decimals", async () => {
      const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

      const token1 = await ERC20Mock.deploy("MK1", "MK1", 6);
      expect(await mock.tokenFrom18(wei("1"), await token1.getAddress())).to.equal(wei("1", 6));

      const token2 = await ERC20Mock.deploy("MK2", "MK2", 15);
      expect(await mock.tokenFrom18(wei("1", 12), await token2.getAddress())).to.equal(wei("1", 9));

      const token3 = await ERC20Mock.deploy("MK3", "MK3", 18);
      expect(await mock.tokenFrom18(wei("1", 6), await token3.getAddress())).to.equal(wei("1", 6));

      const token4 = await ERC20Mock.deploy("MK4", "MK4", 25);
      expect(await mock.tokenFrom18(wei("1", 20), await token4.getAddress())).to.equal(wei("1", 27));
    });
  });

  describe("from18Safe", () => {
    it("should correctly convert from 18", async () => {
      expect(await mock.from18Safe(wei("1"), 6)).to.equal(wei("1", 6));
      expect(await mock.from18Safe(wei("1"), 8)).to.equal(wei("1", 8));
    });

    it("should correctly convert from 18 to token decimals", async () => {
      const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

      const token1 = await ERC20Mock.deploy("MK1", "MK1", 6);
      expect(await mock.tokenFrom18Safe(wei("1"), await token1.getAddress())).to.equal(wei("1", 6));

      const token2 = await ERC20Mock.deploy("MK2", "MK2", 15);
      expect(await mock.tokenFrom18Safe(wei("1", 12), await token2.getAddress())).to.equal(wei("1", 9));
    });

    it("should get exception if the result of conversion is zero", async () => {
      await expect(mock.from18Safe(wei("1", 6), 6))
        .to.be.revertedWithCustomError(mock, "ConversionFailed")
        .withArgs();
    });
  });

  describe("round18", () => {
    it("should round 18", async () => {
      expect(await mock.round18(wei("1"), 18)).to.equal(wei("1"));
      expect(await mock.round18(wei("1"), 6)).to.equal(wei("1"));
      expect(await mock.round18(wei("1"), 30)).to.equal(wei("1"));
      expect(await mock.round18(wei("1", 7), 7)).to.equal(0n);

      const badNum1 = wei("1") + 123n;
      const badNum2 = wei("1") + wei("1", 7) + 123n;

      expect(await mock.round18(badNum1, 4)).to.equal(wei("1"));
      expect(await mock.round18(badNum2, 12)).to.equal(wei("1") + wei("1", 7));
    });

    it("should round 18 tokens", async () => {
      const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

      const token1 = await ERC20Mock.deploy("MK1", "MK1", 6);

      expect(await mock.tokenRound18(wei("1"), await token1.getAddress())).to.equal(wei("1"));
      expect(await mock.tokenRound18(wei("1", 6), await token1.getAddress())).to.equal(0n);
    });
  });

  describe("round18Safe", () => {
    it("should round 18 tokens safe", async () => {
      const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

      const token1 = await ERC20Mock.deploy("MK1", "MK1", 6);

      expect(await mock.tokenRound18Safe(wei("1"), await token1.getAddress())).to.equal(wei("1"));
    });

    it("should get exception if the result of conversion is zero", async () => {
      await expect(mock.round18Safe(wei("1", 6), 6))
        .to.be.revertedWithCustomError(mock, "ConversionFailed")
        .withArgs();
    });
  });
});
