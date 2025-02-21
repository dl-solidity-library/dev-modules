import { ethers } from "hardhat";
import { expect } from "chai";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";

import { Reverter } from "@/test/helpers/reverter";
import { wei } from "@/scripts/utils/utils";

import { ValueDistributorMock } from "@ethers-v6";

describe("ValueDistributor", () => {
  const reverter = new Reverter();

  let FIRST: SignerWithAddress;
  let SECOND: SignerWithAddress;
  let THIRD: SignerWithAddress;
  let FOURTH: SignerWithAddress;

  let valueDistributor: ValueDistributorMock;

  const addSharesToAllUsers = async (shares: Array<any>) => {
    await valueDistributor.addShares(FIRST, shares[0]);
    await valueDistributor.addShares(SECOND, shares[1]);
    await valueDistributor.addShares(THIRD, shares[2]);
    await valueDistributor.addShares(FOURTH, shares[3]);
  };

  const removeSharesFromAllUsers = async (shares: Array<any>) => {
    await valueDistributor.removeShares(FIRST, shares[0]);
    await valueDistributor.removeShares(SECOND, shares[1]);
    await valueDistributor.removeShares(THIRD, shares[2]);
    await valueDistributor.removeShares(FOURTH, shares[3]);
  };

  const checkAllShares = async (shares: Array<any>) => {
    expect(await valueDistributor.userShares(FIRST)).to.equal(shares[0]);
    expect(await valueDistributor.userShares(SECOND)).to.equal(shares[1]);
    expect(await valueDistributor.userShares(THIRD)).to.equal(shares[2]);
    expect(await valueDistributor.userShares(FOURTH)).to.equal(shares[3]);
  };

  const performSharesManipulations = async () => {
    await time.setNextBlockTimestamp((await time.latest()) + 2);

    await valueDistributor.addShares(FIRST, 100);

    await time.setNextBlockTimestamp((await time.latest()) + 2);

    await valueDistributor.addShares(SECOND, 200);

    await valueDistributor.addShares(THIRD, 100);

    await time.setNextBlockTimestamp((await time.latest()) + 3);

    await valueDistributor.removeShares(FIRST, 100);

    await valueDistributor.addShares(THIRD, 100);

    await valueDistributor.removeShares(SECOND, 200);

    await time.setNextBlockTimestamp((await time.latest()) + 2);

    await valueDistributor.removeShares(THIRD, 200);
  };

  before("setup", async () => {
    [FIRST, SECOND, THIRD, FOURTH] = await ethers.getSigners();

    const valueDistributorMock = await ethers.getContractFactory("ValueDistributorMock");
    valueDistributor = await valueDistributorMock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("addShares()", () => {
    it("should add shares correctly", async () => {
      await addSharesToAllUsers([1, 2, 3, 4]);
      await valueDistributor.addShares(FIRST, 5);

      await checkAllShares([6, 2, 3, 4]);
      expect(await valueDistributor.totalShares()).to.equal(15);
    });

    it("should not allow to add 0 shares", async () => {
      await expect(valueDistributor.addShares(SECOND, 0))
        .to.be.revertedWithCustomError(valueDistributor, "AmountIsZero")
        .withArgs();
    });

    it("should not allow zero address to add shares", async () => {
      await expect(valueDistributor.addShares(ethers.ZeroAddress, 2))
        .to.be.revertedWithCustomError(valueDistributor, "UserIsZeroAddress")
        .withArgs();
    });
  });

  describe("removeShares()", () => {
    it("should correctly remove shares partially", async () => {
      await addSharesToAllUsers([3, 2, 3, 4]);

      await removeSharesFromAllUsers([1, 1, 1, 2]);
      await valueDistributor.removeShares(THIRD, 1);

      await checkAllShares([2, 1, 1, 2]);
      expect(await valueDistributor.totalShares()).to.equal(6);
    });

    it("should handle removing all the shares correctly", async () => {
      await addSharesToAllUsers([2, 1, 1, 2]);

      await removeSharesFromAllUsers([2, 1, 1, 2]);

      await checkAllShares([0, 0, 0, 0]);

      expect(await valueDistributor.totalShares()).to.equal(0);

      const cumulativeSum = await valueDistributor.cumulativeSum();

      await valueDistributor.addShares(FIRST, 2);

      expect(await valueDistributor.cumulativeSum()).to.equal(cumulativeSum);
      expect(await valueDistributor.totalShares()).to.equal(2);
      expect(await valueDistributor.userShares(FIRST)).to.equal(2);
    });

    it("should not allow to remove 0 shares", async () => {
      await expect(valueDistributor.removeShares(SECOND, 0))
        .to.be.revertedWithCustomError(valueDistributor, "AmountIsZero")
        .withArgs();
    });

    it("should not allow zero address to remove shares", async () => {
      await expect(valueDistributor.removeShares(ethers.ZeroAddress, 2))
        .to.be.revertedWithCustomError(valueDistributor, "InsufficientSharesAmount")
        .withArgs(ethers.ZeroAddress, 0, 2);
    });

    it("should not allow to remove more shares than it was added", async () => {
      await expect(valueDistributor.removeShares(SECOND, 1))
        .to.be.revertedWithCustomError(valueDistributor, "InsufficientSharesAmount")
        .withArgs(SECOND, (await valueDistributor.userDistribution(SECOND)).shares, 1);
    });
  });

  describe("distributeValue()", () => {
    it("should calculate the value owed to a user correctly", async () => {
      await valueDistributor.addShares(FIRST, 100);

      await time.setNextBlockTimestamp((await time.latest()) + 30);

      await valueDistributor.removeShares(FIRST, 100);

      expect(await valueDistributor.getOwedValue(FIRST)).to.equal(wei(30));
      expect(await valueDistributor.userOwedValue(FIRST)).to.equal(wei(30));
    });

    it("should calculate the value owed to multiple users correctly", async () => {
      await performSharesManipulations();

      const firstExpectedReward = wei(3) + wei(1) / 12n;
      const secondExpectedReward = wei(3) + wei(1) / 3n;
      const thirdExpectedReward = wei(3) + wei(7) / 12n;

      expect(await valueDistributor.getOwedValue(FIRST)).to.equal(firstExpectedReward);
      expect(await valueDistributor.getOwedValue(SECOND)).to.equal(secondExpectedReward);
      expect(await valueDistributor.getOwedValue(THIRD)).to.equal(thirdExpectedReward);

      expect(await valueDistributor.userOwedValue(FIRST)).to.equal(firstExpectedReward);
      expect(await valueDistributor.userOwedValue(SECOND)).to.equal(secondExpectedReward);
      expect(await valueDistributor.userOwedValue(THIRD)).to.equal(thirdExpectedReward);
    });

    it("should calculate the value owed to multiple users correctly", async () => {
      await valueDistributor.addShares(FIRST, 200);

      await time.setNextBlockTimestamp((await time.latest()) + 3);

      await valueDistributor.addShares(SECOND, 100);

      await valueDistributor.addShares(THIRD, 300);

      await time.setNextBlockTimestamp((await time.latest()) + 3);

      await valueDistributor.addShares(FIRST, 200);

      await valueDistributor.removeShares(FIRST, 100);

      await time.setNextBlockTimestamp((await time.latest()) + 3);

      await valueDistributor.removeShares(SECOND, 100);

      await valueDistributor.addShares(THIRD, 100);

      await time.setNextBlockTimestamp((await time.latest()) + 2);

      await valueDistributor.removeShares(FIRST, 300);

      await valueDistributor.removeShares(THIRD, 400);

      const firstExpectedReward = wei(7) + wei(2) / 3n + wei(1) / 7n;
      const secondExpectedReward = wei(233) / 168n;
      const thirdExpectedReward = wei(5) + wei(3) / 8n + wei(3) / 7n;

      expect(await valueDistributor.getOwedValue(FIRST)).to.equal(firstExpectedReward);
      expect(await valueDistributor.getOwedValue(SECOND)).to.equal(secondExpectedReward);
      expect(await valueDistributor.getOwedValue(THIRD)).to.equal(thirdExpectedReward);

      expect(await valueDistributor.userOwedValue(FIRST)).to.equal(firstExpectedReward);
      expect(await valueDistributor.userOwedValue(SECOND)).to.equal(secondExpectedReward);
      expect(await valueDistributor.userOwedValue(THIRD)).to.equal(thirdExpectedReward);
    });

    it("should distribute all the owed values correctly", async () => {
      await performSharesManipulations();

      await valueDistributor.distributeValue(FIRST, await valueDistributor.getOwedValue(FIRST));
      await valueDistributor.distributeValue(SECOND, await valueDistributor.getOwedValue(SECOND));
      await valueDistributor.distributeValue(THIRD, await valueDistributor.getOwedValue(THIRD));

      expect(await valueDistributor.getOwedValue(FIRST)).to.equal(0);
      expect(await valueDistributor.getOwedValue(SECOND)).to.equal(0);
      expect(await valueDistributor.getOwedValue(THIRD)).to.equal(0);

      expect(await valueDistributor.userOwedValue(FIRST)).to.equal(0);
      expect(await valueDistributor.userOwedValue(SECOND)).to.equal(0);
      expect(await valueDistributor.userOwedValue(THIRD)).to.equal(0);
    });

    it("should distribute all the owed values optimally", async () => {
      await performSharesManipulations();

      const firstOwed = await valueDistributor.getOwedValue(FIRST);
      const secondOwed = await valueDistributor.getOwedValue(SECOND);
      const thirdOwed = await valueDistributor.getOwedValue(THIRD);

      expect(await valueDistributor.distributeAllValue.staticCall(FIRST)).to.eq(firstOwed);
      expect(await valueDistributor.distributeAllValue.staticCall(SECOND)).to.eq(secondOwed);
      expect(await valueDistributor.distributeAllValue.staticCall(THIRD)).to.eq(thirdOwed);

      await valueDistributor.distributeAllValue(FIRST);
      await valueDistributor.distributeAllValue(SECOND);
      await valueDistributor.distributeAllValue(THIRD);

      expect(await valueDistributor.getOwedValue(FIRST)).to.equal(0);
      expect(await valueDistributor.getOwedValue(SECOND)).to.equal(0);
      expect(await valueDistributor.getOwedValue(THIRD)).to.equal(0);

      expect(await valueDistributor.userOwedValue(FIRST)).to.equal(0);
      expect(await valueDistributor.userOwedValue(SECOND)).to.equal(0);
      expect(await valueDistributor.userOwedValue(THIRD)).to.equal(0);
    });

    it("should correctly distribute owed values partially", async () => {
      await performSharesManipulations();

      await valueDistributor.distributeValue(FIRST, (await valueDistributor.getOwedValue(FIRST)) - wei(1));
      await valueDistributor.distributeValue(SECOND, (await valueDistributor.getOwedValue(SECOND)) - wei(2));
      await valueDistributor.distributeValue(THIRD, (await valueDistributor.getOwedValue(THIRD)) - wei(3));

      expect(await valueDistributor.getOwedValue(FIRST)).to.equal(wei(1));
      expect(await valueDistributor.getOwedValue(SECOND)).to.equal(wei(2));
      expect(await valueDistributor.getOwedValue(THIRD)).to.equal(wei(3));

      expect(await valueDistributor.userOwedValue(FIRST)).to.equal(wei(1));
      expect(await valueDistributor.userOwedValue(SECOND)).to.equal(wei(2));
      expect(await valueDistributor.userOwedValue(THIRD)).to.equal(wei(3));
    });

    it("should allow to distribute values in several rounds correctly", async () => {
      await performSharesManipulations();

      await valueDistributor.distributeValue(FIRST, (await valueDistributor.getOwedValue(FIRST)) - wei(3));

      expect(await valueDistributor.getOwedValue(FIRST)).to.equal(wei(3));
      expect(await valueDistributor.userOwedValue(FIRST)).to.equal(wei(3));

      await valueDistributor.distributeValue(FIRST, (await valueDistributor.getOwedValue(FIRST)) - wei(2));

      expect(await valueDistributor.getOwedValue(FIRST)).to.equal(wei(2));
      expect(await valueDistributor.userOwedValue(FIRST)).to.equal(wei(2));

      await valueDistributor.distributeValue(FIRST, wei(2));

      expect(await valueDistributor.getOwedValue(FIRST)).to.equal(0);
      expect(await valueDistributor.userOwedValue(FIRST)).to.equal(wei(0));
    });

    it("should not allow to distribute 0 values", async () => {
      await expect(valueDistributor.distributeValue(FIRST, 0))
        .to.be.revertedWithCustomError(valueDistributor, "AmountIsZero")
        .withArgs();
    });

    it("should not allow zero address to distribute values", async () => {
      await expect(valueDistributor.distributeValue(ethers.ZeroAddress, 2))
        .to.be.revertedWithCustomError(valueDistributor, "InsufficientOwedValue")
        .withArgs(ethers.ZeroAddress, 0, 2);
    });

    it("should not allow to distribute more values than owed", async () => {
      await performSharesManipulations();

      await expect(valueDistributor.distributeValue(FIRST, wei(4)))
        .to.be.revertedWithCustomError(valueDistributor, "InsufficientOwedValue")
        .withArgs(FIRST, valueDistributor.getOwedValue(FIRST), wei(4));
    });
  });

  describe("same block transactions", () => {
    it("should work as expected if more than one transaction which updates the key values is sent within one block", async () => {
      await valueDistributor.addShares(FIRST, 100);

      await valueDistributor.multicall([
        valueDistributor.interface.encodeFunctionData("addShares", [await FIRST.getAddress(), 200]),
        valueDistributor.interface.encodeFunctionData("addShares", [await SECOND.getAddress(), 200]),
      ]);

      await time.setNextBlockTimestamp((await time.latest()) + 3);

      await valueDistributor.removeShares(SECOND, 100);

      await time.setNextBlockTimestamp((await time.latest()) + 4);

      await valueDistributor.addShares(THIRD, 100);

      await valueDistributor.multicall([
        valueDistributor.interface.encodeFunctionData("removeShares", [await FIRST.getAddress(), 300]),
        valueDistributor.interface.encodeFunctionData("removeShares", [await SECOND.getAddress(), 100]),
      ]);

      await time.setNextBlockTimestamp((await time.latest()) + 3);

      await valueDistributor.removeShares(THIRD, 100);

      const firstExpectedReward = wei(6) + wei(2) / 5n;
      const secondExpectedReward = wei(2) + wei(2) / 5n;
      const thirdExpectedReward = wei(3) + wei(1) / 5n;

      expect(await valueDistributor.getOwedValue(FIRST)).to.equal(firstExpectedReward);
      expect(await valueDistributor.getOwedValue(SECOND)).to.equal(secondExpectedReward);
      expect(await valueDistributor.getOwedValue(THIRD)).to.equal(thirdExpectedReward);

      expect(await valueDistributor.userOwedValue(FIRST)).to.equal(firstExpectedReward);
      expect(await valueDistributor.userOwedValue(SECOND)).to.equal(secondExpectedReward);
      expect(await valueDistributor.userOwedValue(THIRD)).to.equal(thirdExpectedReward);
    });
  });
});
