import { ethers } from "hardhat";
import { expect } from "chai";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";

import { Reverter } from "@/test/helpers/reverter";

import { BlockGuardMock } from "@ethers-v6";

describe("BlockGuard", () => {
  const reverter = new Reverter();

  let FIRST: SignerWithAddress;
  let SECOND: SignerWithAddress;

  let mock: BlockGuardMock;

  before("setup", async () => {
    [FIRST, SECOND] = await ethers.getSigners();

    const BlockGuardMock = await ethers.getContractFactory("BlockGuardMock");
    mock = await BlockGuardMock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("lockBlock", () => {
    it("should return zero if the resource key hasn't been locked", async () => {
      expect(await mock.getLatestLockBlock(await mock.LOCK_LOCK_RESOURCE(), FIRST)).to.equal(0n);
    });

    it("should return the current block if the resource key has been locked", async () => {
      await mock.deposit();

      expect(await mock.getLatestLockBlock(await mock.DEPOSIT_WITHDRAW_RESOURCE(), FIRST)).to.equal(
        await time.latestBlock(),
      );

      expect(await mock.getLatestLockBlock(await mock.DEPOSIT_WITHDRAW_RESOURCE(), SECOND)).to.equal(0n);
    });
  });

  describe("checkBlock", () => {
    it("should allow to call in different blocks", async () => {
      await mock.deposit();

      await mock.withdraw();
    });

    it("should disallow to call in the same block", async () => {
      await expect(
        mock.multicall([mock.interface.encodeFunctionData("deposit"), mock.interface.encodeFunctionData("withdraw")]),
      )
        .to.be.revertedWithCustomError(mock, "BlockGuardLocked")
        .withArgs(await mock.DEPOSIT_WITHDRAW_RESOURCE(), FIRST);
    });
  });

  describe("checkLockBlock", () => {
    it("should allow to call in different blocks", async () => {
      await mock.lock();

      const blockNumber = await time.latestBlock();

      expect(await mock.getLatestLockBlock(await mock.LOCK_LOCK_RESOURCE(), FIRST)).to.equal(blockNumber);

      await mock.lock();

      expect(await mock.getLatestLockBlock(await mock.LOCK_LOCK_RESOURCE(), FIRST)).to.equal(blockNumber + 1);
    });

    it("should disallow to call in the same block", async () => {
      await expect(
        mock.multicall([mock.interface.encodeFunctionData("lock"), mock.interface.encodeFunctionData("lock")]),
      )
        .to.be.revertedWithCustomError(mock, "BlockGuardLocked")
        .withArgs(await mock.LOCK_LOCK_RESOURCE(), FIRST);
    });
  });
});
