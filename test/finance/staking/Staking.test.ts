import { ethers } from "hardhat";
import { expect } from "chai";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";

import { Reverter } from "@/test/helpers/reverter";

import { StakingMock, ERC20Mock } from "@ethers-v6";
import { wei } from "@/scripts/utils/utils";

describe("Staking", () => {
  const reverter = new Reverter();

  let FIRST: SignerWithAddress;
  let SECOND: SignerWithAddress;
  let THIRD: SignerWithAddress;

  let sharesToken: ERC20Mock;
  let rewardsToken: ERC20Mock;

  let sharesDecimals: number;
  let rewardsDecimals: number;

  let stakingStartTime: bigint;
  let rate: bigint;

  let staking: StakingMock;

  const mintAndApproveTokens = async (user: SignerWithAddress, token: ERC20Mock, amount: bigint) => {
    await token.mint(user, amount);
    await token.connect(user).approve(staking, amount);
  };

  const performStakingManipulations = async () => {
    await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));
    await mintAndApproveTokens(SECOND, sharesToken, wei(200, sharesDecimals));
    await mintAndApproveTokens(THIRD, sharesToken, wei(200, sharesDecimals));

    await time.setNextBlockTimestamp((await time.latest()) + 2);

    await staking.connect(FIRST).stake(wei(100, sharesDecimals));

    await time.setNextBlockTimestamp((await time.latest()) + 2);

    await staking.connect(SECOND).stake(wei(200, sharesDecimals));

    await staking.connect(THIRD).stake(wei(100, sharesDecimals));

    await time.setNextBlockTimestamp((await time.latest()) + 3);

    await staking.connect(FIRST).unstake(wei(100, sharesDecimals));

    await staking.connect(THIRD).stake(wei(100, sharesDecimals));

    await staking.connect(SECOND).unstake(wei(200, sharesDecimals));

    await time.setNextBlockTimestamp((await time.latest()) + 2);

    await staking.connect(THIRD).unstake(wei(200, sharesDecimals));
  };

  const checkManipulationRewards = async () => {
    const firstExpectedReward = wei(3, rewardsDecimals) + wei(1, rewardsDecimals) / 12n;
    const secondExpectedReward = wei(3, rewardsDecimals) + wei(1, rewardsDecimals) / 3n;
    const thirdExpectedReward = wei(3, rewardsDecimals) + wei(7, rewardsDecimals) / 12n;

    expect(await staking.getOwedValue(FIRST)).to.equal(firstExpectedReward);
    expect(await staking.getOwedValue(SECOND)).to.equal(secondExpectedReward);
    expect(await staking.getOwedValue(THIRD)).to.equal(thirdExpectedReward);

    expect(await staking.userOwedValue(FIRST)).to.equal(firstExpectedReward);
    expect(await staking.userOwedValue(SECOND)).to.equal(secondExpectedReward);
    expect(await staking.userOwedValue(THIRD)).to.equal(thirdExpectedReward);
  };

  const performStakingManipulations2 = async () => {
    await mintAndApproveTokens(FIRST, sharesToken, wei(400, sharesDecimals));
    await mintAndApproveTokens(SECOND, sharesToken, wei(100, sharesDecimals));
    await mintAndApproveTokens(THIRD, sharesToken, wei(400, sharesDecimals));

    await staking.connect(FIRST).stake(wei(200, sharesDecimals));

    await time.setNextBlockTimestamp((await time.latest()) + 3);

    await staking.connect(SECOND).stake(wei(100, sharesDecimals));

    await staking.connect(THIRD).stake(wei(300, sharesDecimals));

    await time.setNextBlockTimestamp((await time.latest()) + 3);

    await staking.connect(FIRST).stake(wei(200, sharesDecimals));

    await staking.connect(FIRST).unstake(wei(100, sharesDecimals));

    await time.setNextBlockTimestamp((await time.latest()) + 3);

    await staking.connect(SECOND).unstake(wei(100, sharesDecimals));

    await staking.connect(THIRD).stake(wei(100, sharesDecimals));

    await time.setNextBlockTimestamp((await time.latest()) + 2);

    await staking.connect(FIRST).unstake(wei(300, sharesDecimals));

    await staking.connect(THIRD).unstake(wei(400, sharesDecimals));
  };

  const checkManipulationRewards2 = async () => {
    const firstExpectedReward = wei(7, rewardsDecimals) + wei(2, rewardsDecimals) / 3n + wei(1, rewardsDecimals) / 7n;
    const secondExpectedReward = wei(233, rewardsDecimals) / 168n;
    const thirdExpectedReward = wei(5, rewardsDecimals) + wei(3, rewardsDecimals) / 8n + wei(3, rewardsDecimals) / 7n;

    expect(await staking.getOwedValue(FIRST)).to.equal(firstExpectedReward);
    expect(await staking.getOwedValue(SECOND)).to.equal(secondExpectedReward);
    expect(await staking.getOwedValue(THIRD)).to.equal(thirdExpectedReward);

    expect(await staking.userOwedValue(FIRST)).to.equal(firstExpectedReward);
    expect(await staking.userOwedValue(SECOND)).to.equal(secondExpectedReward);
    expect(await staking.userOwedValue(THIRD)).to.equal(thirdExpectedReward);
  };

  before("setup", async () => {
    [FIRST, SECOND, THIRD] = await ethers.getSigners();

    const StakingMock = await ethers.getContractFactory("StakingMock");
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

    staking = await StakingMock.deploy();
    sharesToken = await ERC20Mock.deploy("SharesMock", "SMock", 18);
    rewardsToken = await ERC20Mock.deploy("RewardsMock", "RMock", 18);

    sharesDecimals = Number(await sharesToken.decimals());
    rewardsDecimals = Number(await rewardsToken.decimals());

    await rewardsToken.mint(await staking.getAddress(), wei(100, rewardsDecimals));

    stakingStartTime = 3n;
    rate = wei(1, rewardsDecimals);

    await staking.__StakingMock_init(sharesToken, rewardsToken, rate, stakingStartTime);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("AStaking initialization", () => {
    it("should not initialize twice", async () => {
      await expect(staking.mockInit(sharesToken, rewardsToken, rate, stakingStartTime))
        .to.be.revertedWithCustomError(staking, "NotInitializing")
        .withArgs();

      await expect(staking.__StakingMock_init(sharesToken, rewardsToken, rate, stakingStartTime))
        .to.be.revertedWithCustomError(staking, "InvalidInitialization")
        .withArgs();
    });

    it("should set the initial values correctly", async () => {
      expect(await staking.sharesToken()).to.equal(await sharesToken.getAddress());
      expect(await staking.rewardsToken()).to.equal(await rewardsToken.getAddress());
      expect(await staking.rate()).to.equal(rate);
      expect(await staking.stakingStartTime()).to.equal(stakingStartTime);
    });

    it("should not allow to set 0 as a Shares Token or Rewards Token", async () => {
      const StakingMock = await ethers.getContractFactory("StakingMock");
      let staking = await StakingMock.deploy();

      await expect(staking.__StakingMock_init(ethers.ZeroAddress, rewardsToken, rate, stakingStartTime))
        .to.be.revertedWithCustomError(staking, "SharesTokenIsZeroAddress")
        .withArgs();

      await expect(staking.__StakingMock_init(sharesToken, ethers.ZeroAddress, rate, stakingStartTime))
        .to.be.revertedWithCustomError(staking, "RewardsTokenIsZeroAddress")
        .withArgs();
    });
  });

  describe("timestamps", () => {
    it("should not allow to stake, unstake, withdraw tokens or claim rewards before the start of the staking", async () => {
      const stakingStartTime = 1638474321;
      await staking.setStakingStartTime(stakingStartTime);

      await expect(staking.stake(wei(100, sharesDecimals)))
        .to.be.revertedWithCustomError(staking, "StakingHasNotStarted")
        .withArgs((await time.latest()) + 1, stakingStartTime);
      await expect(staking.unstake(wei(100, sharesDecimals)))
        .to.be.revertedWithCustomError(staking, "StakingHasNotStarted")
        .withArgs((await time.latest()) + 1, stakingStartTime);
      await expect(staking.withdraw())
        .to.be.revertedWithCustomError(staking, "StakingHasNotStarted")
        .withArgs((await time.latest()) + 1, stakingStartTime);
      await expect(staking.claim(wei(100, sharesDecimals)))
        .to.be.revertedWithCustomError(staking, "StakingHasNotStarted")
        .withArgs((await time.latest()) + 1, stakingStartTime);
      await expect(staking.claimAll())
        .to.be.revertedWithCustomError(staking, "StakingHasNotStarted")
        .withArgs((await time.latest()) + 1, stakingStartTime);
    });

    it("should work as expected if the staking start time is set to the timestamp in the past", async () => {
      await time.setNextBlockTimestamp((await time.latest()) + 20);

      await staking.setStakingStartTime(2);

      expect(await staking.stakingStartTime()).to.equal(2);

      await performStakingManipulations();

      await checkManipulationRewards();
    });

    it("should update values correctly if more than one transaction which updates the key values is sent within one block", async () => {
      await mintAndApproveTokens(FIRST, sharesToken, wei(400, sharesDecimals));

      await staking.connect(FIRST).stake(wei(100, sharesDecimals));
      await staking.connect(FIRST).stake(wei(100, sharesDecimals));

      await staking.multicall([
        staking.interface.encodeFunctionData("stake", [wei(100, sharesDecimals)]),
        staking.interface.encodeFunctionData("stake", [wei(100, sharesDecimals)]),
      ]);

      expect(await staking.userShares(FIRST)).to.equal(wei(400, sharesDecimals));
      expect(await staking.cumulativeSum()).to.equal(wei(1.5, 23));
    });

    it("should work as expected if more than one transaction which updates the key values is sent within one block", async () => {
      const StakersFactory = await ethers.getContractFactory("StakersFactory");
      const stakersFactory = await StakersFactory.deploy();

      await stakersFactory.createStaker();
      await stakersFactory.createStaker();

      const staker1 = await stakersFactory.stakers(0);
      const staker2 = await stakersFactory.stakers(1);

      await sharesToken.mint(staker1, wei(500, sharesDecimals));
      await sharesToken.mint(staker2, wei(500, sharesDecimals));
      await mintAndApproveTokens(THIRD, sharesToken, wei(100, sharesDecimals));

      await stakersFactory.stake(staking, staker1, sharesToken, wei(100, sharesDecimals));

      await stakersFactory.multicall([
        stakersFactory.interface.encodeFunctionData("stake", [
          await staking.getAddress(),
          staker1,
          await sharesToken.getAddress(),
          wei(200, sharesDecimals),
        ]),
        stakersFactory.interface.encodeFunctionData("stake", [
          await staking.getAddress(),
          staker2,
          await sharesToken.getAddress(),
          wei(200, sharesDecimals),
        ]),
      ]);

      await time.setNextBlockTimestamp((await time.latest()) + 3);

      await stakersFactory.unstake(staking, staker2, wei(100, sharesDecimals));

      await time.setNextBlockTimestamp((await time.latest()) + 4);

      await staking.connect(THIRD).stake(wei(100, sharesDecimals));

      await stakersFactory.multicall([
        stakersFactory.interface.encodeFunctionData("unstake", [
          await staking.getAddress(),
          staker1,
          wei(300, sharesDecimals),
        ]),
        stakersFactory.interface.encodeFunctionData("unstake", [
          await staking.getAddress(),
          staker2,
          wei(100, sharesDecimals),
        ]),
      ]);

      await time.setNextBlockTimestamp((await time.latest()) + 3);

      await staking.connect(THIRD).unstake(wei(100, sharesDecimals));

      const firstExpectedReward = wei(6, rewardsDecimals) + wei(2, rewardsDecimals) / 5n;
      const secondExpectedReward = wei(2, rewardsDecimals) + wei(2, rewardsDecimals) / 5n;
      const thirdExpectedReward = wei(3, rewardsDecimals) + wei(1, rewardsDecimals) / 5n;

      expect(await staking.getOwedValue(staker1)).to.equal(firstExpectedReward);
      expect(await staking.getOwedValue(staker2)).to.equal(secondExpectedReward);
      expect(await staking.getOwedValue(THIRD)).to.equal(thirdExpectedReward);

      expect(await staking.userOwedValue(staker1)).to.equal(firstExpectedReward);
      expect(await staking.userOwedValue(staker2)).to.equal(secondExpectedReward);
      expect(await staking.userOwedValue(THIRD)).to.equal(thirdExpectedReward);
    });
  });

  describe("stake()", () => {
    it("should add shares after staking correctly", async () => {
      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));
      await mintAndApproveTokens(SECOND, sharesToken, wei(300, sharesDecimals));

      await staking.connect(FIRST).stake(wei(100, sharesDecimals));
      await staking.connect(SECOND).stake(wei(300, sharesDecimals));

      expect(await staking.totalShares()).to.equal(wei(400, sharesDecimals));
      expect(await staking.userShares(FIRST)).to.equal(wei(100, sharesDecimals));
      expect(await staking.userShares(SECOND)).to.equal(wei(300, sharesDecimals));
    });

    it("should transfer tokens correctly on stake", async () => {
      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));

      await staking.connect(FIRST).stake(wei(50, sharesDecimals));

      expect(await sharesToken.balanceOf(FIRST)).to.equal(wei(50, sharesDecimals));
      expect(await sharesToken.balanceOf(staking)).to.equal(wei(50, sharesDecimals));

      await staking.connect(FIRST).stake(wei(50, sharesDecimals));

      expect(await sharesToken.balanceOf(FIRST)).to.equal(0);
      expect(await sharesToken.balanceOf(staking)).to.equal(wei(100, sharesDecimals));
    });

    it("should not allow to stake 0 tokens", async () => {
      await expect(staking.connect(FIRST).stake(0)).to.be.revertedWithCustomError(staking, "AmountIsZero").withArgs();
    });
  });

  describe("unstake()", () => {
    it("should remove shares after unstaking correctly", async () => {
      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));
      await mintAndApproveTokens(SECOND, sharesToken, wei(300, sharesDecimals));

      await staking.connect(FIRST).stake(wei(100, sharesDecimals));
      await staking.connect(SECOND).stake(wei(300, sharesDecimals));

      await staking.connect(FIRST).unstake(wei(50, sharesDecimals));
      await staking.connect(SECOND).unstake(wei(200, sharesDecimals));

      expect(await staking.totalShares()).to.equal(wei(150, sharesDecimals));
      expect(await staking.userShares(FIRST)).to.equal(wei(50, sharesDecimals));
      expect(await staking.userShares(SECOND)).to.equal(wei(100, sharesDecimals));
    });

    it("should handle unstaking the whole amount staked correctly", async () => {
      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));
      await mintAndApproveTokens(SECOND, sharesToken, wei(200, sharesDecimals));

      await staking.connect(FIRST).stake(wei(100, sharesDecimals));
      await staking.connect(SECOND).stake(wei(200, sharesDecimals));

      await staking.connect(FIRST).unstake(wei(100, sharesDecimals));
      await staking.connect(SECOND).unstake(wei(200, sharesDecimals));

      const cumulativeSum = await staking.cumulativeSum();

      expect(await staking.totalShares()).to.equal(0);
      expect(await staking.userShares(FIRST)).to.equal(0);
      expect(await staking.userShares(SECOND)).to.equal(0);

      await sharesToken.connect(FIRST).approve(staking, wei(50, sharesDecimals));
      await sharesToken.connect(SECOND).approve(staking, wei(100, sharesDecimals));

      await staking.connect(FIRST).stake(wei(50, sharesDecimals));

      expect(await staking.cumulativeSum()).to.equal(cumulativeSum);

      await staking.connect(SECOND).stake(wei(100, sharesDecimals));

      expect(await staking.totalShares()).to.equal(wei(150, sharesDecimals));
      expect(await staking.userShares(FIRST)).to.equal(wei(50, sharesDecimals));
      expect(await staking.userShares(SECOND)).to.equal(wei(100, sharesDecimals));
    });

    it("should transfer tokens correctly on unstake", async () => {
      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));

      await staking.connect(FIRST).stake(wei(100, sharesDecimals));

      await staking.connect(FIRST).unstake(wei(50, sharesDecimals));

      expect(await sharesToken.balanceOf(FIRST)).to.equal(wei(50, sharesDecimals));
      expect(await sharesToken.balanceOf(staking)).to.equal(wei(50, sharesDecimals));

      await staking.connect(FIRST).unstake(wei(50, sharesDecimals));

      expect(await sharesToken.balanceOf(FIRST)).to.equal(wei(100, sharesDecimals));
      expect(await sharesToken.balanceOf(staking)).to.equal(0);
    });

    it("should not allow to unstake 0 tokens", async () => {
      await expect(staking.connect(FIRST).unstake(0)).to.be.revertedWithCustomError(staking, "AmountIsZero").withArgs();
    });

    it("should not allow to unstake more than it was staked", async () => {
      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));

      await staking.connect(FIRST).stake(wei(100, sharesDecimals));
      await expect(staking.connect(FIRST).unstake(wei(150, sharesDecimals)))
        .to.be.revertedWithCustomError(staking, "InsufficientSharesAmount")
        .withArgs(FIRST.address, wei(100, sharesDecimals), wei(150, sharesDecimals));
    });
  });

  describe("withdraw()", () => {
    it("should withdraw tokens correctly", async () => {
      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));

      await staking.connect(FIRST).stake(wei(100, sharesDecimals));

      await staking.connect(FIRST).withdraw();

      expect(await staking.totalShares()).to.equal(0);
      expect(await staking.userShares(FIRST)).to.equal(0);
    });

    it("should transfer tokens correctly on withdraw", async () => {
      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));

      await staking.connect(FIRST).stake(wei(100, sharesDecimals));

      await staking.connect(FIRST).withdraw();

      expect(await sharesToken.balanceOf(staking)).to.equal(0);
      expect(await sharesToken.balanceOf(FIRST)).to.equal(wei(100, sharesDecimals));
    });

    it("should claim all the rewards earned after the withdrawal", async () => {
      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));

      await staking.connect(FIRST).stake(wei(100, sharesDecimals));

      await time.setNextBlockTimestamp((await time.latest()) + 30);

      await staking.connect(FIRST).withdraw();

      expect(await staking.getOwedValue(FIRST)).to.equal(0);
      expect(await staking.userOwedValue(FIRST)).to.equal(0);
    });

    it("should work as expected if withdraw is called right after claiming all the rewards within one block", async () => {
      await mintAndApproveTokens(SECOND, sharesToken, wei(200, sharesDecimals));
      await mintAndApproveTokens(FIRST, sharesToken, wei(200, sharesDecimals));

      await staking.connect(FIRST).stake(wei(100, sharesDecimals));

      // triggering the next block
      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));

      await staking.multicall([
        staking.interface.encodeFunctionData("claim", [await staking.getOwedValue(FIRST)]),
        staking.interface.encodeFunctionData("withdraw"),
      ]);

      expect(await staking.getOwedValue(FIRST)).to.equal(0);
      expect(await staking.userOwedValue(FIRST)).to.equal(0);
      expect(await staking.userShares(FIRST)).to.equal(0);
    });

    it("should withdraw as expected if there are no rewards because of the 0 rate", async () => {
      await staking.setRate(0);

      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));

      await staking.connect(FIRST).stake(wei(100, sharesDecimals));

      await time.setNextBlockTimestamp((await time.latest()) + 30);

      await staking.withdraw();

      expect(await staking.getOwedValue(FIRST)).to.equal(0);
      expect(await staking.userOwedValue(FIRST)).to.equal(0);
      expect(await staking.userShares(FIRST)).to.equal(0);
    });

    it("should not allow to withdraw if there are no shares", async () => {
      await mintAndApproveTokens(FIRST, sharesToken, wei(200, sharesDecimals));

      await staking.connect(FIRST).stake(wei(200, sharesDecimals));

      await expect(
        staking.multicall([
          staking.interface.encodeFunctionData("unstake", [wei(200, sharesDecimals)]),
          staking.interface.encodeFunctionData("withdraw"),
        ]),
      )
        .to.be.revertedWithCustomError(staking, "AmountIsZero")
        .withArgs();
    });
  });

  describe("claim()", () => {
    it("should calculate the rewards earned for a user correctly", async () => {
      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));

      await staking.connect(FIRST).stake(wei(100, sharesDecimals));

      await time.setNextBlockTimestamp((await time.latest()) + 30);

      await staking.connect(FIRST).unstake(wei(100, sharesDecimals));

      expect(await staking.getOwedValue(FIRST)).to.equal(wei(30, rewardsDecimals));
      expect(await staking.userOwedValue(FIRST)).to.equal(wei(30, rewardsDecimals));
    });

    it("should calculate the reward earned for multiple users correctly", async () => {
      await performStakingManipulations();

      await checkManipulationRewards();
    });

    it("should calculate the reward earned for multiple users correctly", async () => {
      await performStakingManipulations2();

      await checkManipulationRewards2();
    });

    it("should claim all the rewards correctly", async () => {
      await performStakingManipulations();

      await staking.connect(FIRST).claim(await staking.getOwedValue(FIRST));
      await staking.connect(SECOND).claim(await staking.getOwedValue(SECOND));
      await staking.connect(THIRD).claim(await staking.getOwedValue(THIRD));

      expect(await staking.getOwedValue(FIRST)).to.equal(0);
      expect(await staking.getOwedValue(SECOND)).to.equal(0);
      expect(await staking.getOwedValue(THIRD)).to.equal(0);

      expect(await staking.userOwedValue(FIRST)).to.equal(0);
      expect(await staking.userOwedValue(SECOND)).to.equal(0);
      expect(await staking.userOwedValue(THIRD)).to.equal(0);
    });

    it("should correctly claim rewards partially", async () => {
      await performStakingManipulations();

      await staking.connect(FIRST).claim((await staking.getOwedValue(FIRST)) - wei(1, rewardsDecimals));
      await staking.connect(SECOND).claim((await staking.getOwedValue(SECOND)) - wei(2, rewardsDecimals));
      await staking.connect(THIRD).claim((await staking.getOwedValue(THIRD)) - wei(3, rewardsDecimals));

      expect(await staking.getOwedValue(FIRST)).to.equal(wei(1, rewardsDecimals));
      expect(await staking.getOwedValue(SECOND)).to.equal(wei(2, rewardsDecimals));
      expect(await staking.getOwedValue(THIRD)).to.equal(wei(3, rewardsDecimals));

      expect(await staking.userOwedValue(FIRST)).to.equal(wei(1, rewardsDecimals));
      expect(await staking.userOwedValue(SECOND)).to.equal(wei(2, rewardsDecimals));
      expect(await staking.userOwedValue(THIRD)).to.equal(wei(3, rewardsDecimals));
    });

    it("should allow to claim rewards in several rounds correctly", async () => {
      await performStakingManipulations2();

      await staking.connect(FIRST).claim((await staking.getOwedValue(FIRST)) - wei(3));

      expect(await staking.getOwedValue(FIRST)).to.equal(wei(3, rewardsDecimals));
      expect(await staking.userOwedValue(FIRST)).to.equal(wei(3, rewardsDecimals));

      await staking.connect(FIRST).claim((await staking.getOwedValue(FIRST)) - wei(2));

      expect(await staking.getOwedValue(FIRST)).to.equal(wei(2, rewardsDecimals));
      expect(await staking.userOwedValue(FIRST)).to.equal(wei(2, rewardsDecimals));

      await staking.connect(FIRST).claim(wei(2, rewardsDecimals));

      expect(await staking.getOwedValue(FIRST)).to.equal(0);
      expect(await staking.userOwedValue(FIRST)).to.equal(0);
    });

    it("should transfer tokens correctly on the claim", async () => {
      await performStakingManipulations();

      const initialRewardsBalance = await rewardsToken.balanceOf(staking);

      const firstOwed = await staking.getOwedValue(FIRST);
      const secondOwed = await staking.getOwedValue(SECOND);
      const thirdOwed = await staking.getOwedValue(THIRD);

      await staking.connect(FIRST).claim(firstOwed);
      await staking.connect(SECOND).claim(secondOwed);

      await staking.connect(THIRD).claim(thirdOwed);

      expect(await rewardsToken.balanceOf(staking)).to.equal(
        initialRewardsBalance - (firstOwed + secondOwed + thirdOwed),
      );
      expect(await rewardsToken.balanceOf(FIRST)).to.equal(firstOwed);
      expect(await rewardsToken.balanceOf(SECOND)).to.equal(secondOwed);
      expect(await rewardsToken.balanceOf(THIRD)).to.equal(thirdOwed);
    });

    it("should not allow to claim 0 rewards", async () => {
      await expect(staking.connect(FIRST).claim(0)).to.be.revertedWithCustomError(staking, "AmountIsZero").withArgs();
    });

    it("should not allow to claim more rewards than earned", async () => {
      await performStakingManipulations();

      await expect(staking.connect(FIRST).claim(wei(4, rewardsDecimals)))
        .to.be.revertedWithCustomError(staking, "InsufficientOwedValue")
        .withArgs(FIRST.address, staking.getOwedValue(FIRST.address), wei(4, rewardsDecimals));
    });
  });

  describe("claimAll()", () => {
    it("should claim all the rewards correctly", async () => {
      await performStakingManipulations();

      await staking.connect(FIRST).claimAll();
      await staking.connect(SECOND).claimAll();
      await staking.connect(THIRD).claimAll();

      expect(await staking.getOwedValue(FIRST)).to.equal(0);
      expect(await staking.getOwedValue(SECOND)).to.equal(0);
      expect(await staking.getOwedValue(THIRD)).to.equal(0);

      expect(await staking.userOwedValue(FIRST)).to.equal(0);
      expect(await staking.userOwedValue(SECOND)).to.equal(0);
      expect(await staking.userOwedValue(THIRD)).to.equal(0);
    });

    it("should transfer tokens correctly on the claim", async () => {
      await performStakingManipulations();

      const initialRewardsBalance = await rewardsToken.balanceOf(staking);

      const firstOwed = await staking.getOwedValue(FIRST);
      const secondOwed = await staking.getOwedValue(SECOND);
      const thirdOwed = await staking.getOwedValue(THIRD);

      expect(await staking.connect(FIRST).claimAll.staticCall()).to.eq(firstOwed);
      expect(await staking.connect(SECOND).claimAll.staticCall()).to.eq(secondOwed);
      expect(await staking.connect(THIRD).claimAll.staticCall()).to.eq(thirdOwed);

      await staking.connect(FIRST).claimAll();
      await staking.connect(SECOND).claimAll();

      await staking.connect(THIRD).claimAll();

      expect(await rewardsToken.balanceOf(staking)).to.equal(
        initialRewardsBalance - (firstOwed + secondOwed + thirdOwed),
      );
      expect(await rewardsToken.balanceOf(FIRST)).to.equal(firstOwed);
      expect(await rewardsToken.balanceOf(SECOND)).to.equal(secondOwed);
      expect(await rewardsToken.balanceOf(THIRD)).to.equal(thirdOwed);
    });

    it("should not allow to claim 0 rewards", async () => {
      await performStakingManipulations();

      await expect(
        staking.multicall([
          staking.interface.encodeFunctionData("claimAll"),
          staking.interface.encodeFunctionData("claimAll"),
        ]),
      )
        .to.be.revertedWithCustomError(staking, "AmountIsZero")
        .withArgs();
    });
  });

  describe("rate", () => {
    it("should accept 0 as a rate and calculate owed values according to this rate correctly", async () => {
      const StakingMock = await ethers.getContractFactory("StakingMock");
      staking = await StakingMock.deploy();

      await staking.__StakingMock_init(sharesToken, rewardsToken, 0, stakingStartTime);

      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));

      await staking.connect(FIRST).stake(wei(100, sharesDecimals));

      await time.setNextBlockTimestamp((await time.latest()) + 20);

      await staking.connect(FIRST).unstake(wei(100, sharesDecimals));

      expect(await staking.rate()).to.equal(0);

      expect(await staking.getOwedValue(FIRST)).to.equal(0);
      expect(await staking.userOwedValue(FIRST)).to.equal(0);
      expect(await staking.cumulativeSum()).to.equal(0);
    });

    it("should calculate owed value properly after the rate is changed to 0", async () => {
      const StakingMock = await ethers.getContractFactory("StakingMock");
      staking = await StakingMock.deploy();

      await staking.__StakingMock_init(sharesToken, rewardsToken, rate, stakingStartTime);

      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));
      await mintAndApproveTokens(SECOND, sharesToken, wei(300, sharesDecimals));

      await staking.connect(FIRST).stake(wei(50, sharesDecimals));
      await staking.connect(SECOND).stake(wei(150, sharesDecimals));

      await staking.connect(FIRST).unstake(wei(50, sharesDecimals));
      await staking.connect(SECOND).unstake(wei(100, sharesDecimals));

      await staking.setRate(0);

      expect(await staking.rate()).to.equal(0);

      await staking.connect(SECOND).unstake(wei(50, sharesDecimals));

      let firstOwedValue = await staking.getOwedValue(FIRST);
      let secondOwedValue = await staking.getOwedValue(SECOND);

      await performStakingManipulations();

      expect(await staking.userOwedValue(FIRST)).to.equal(firstOwedValue);
      expect(await staking.userOwedValue(SECOND)).to.equal(secondOwedValue);
    });

    it("should work as expected after updating the rate", async () => {
      const StakingMock = await ethers.getContractFactory("StakingMock");
      staking = await StakingMock.deploy();

      await staking.__StakingMock_init(sharesToken, rewardsToken, rate, stakingStartTime);

      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));
      await mintAndApproveTokens(SECOND, sharesToken, wei(300, sharesDecimals));

      await staking.connect(FIRST).stake(wei(50, sharesDecimals));
      await staking.connect(SECOND).stake(wei(150, sharesDecimals));

      await staking.connect(FIRST).unstake(wei(50, sharesDecimals));
      await staking.connect(SECOND).unstake(wei(100, sharesDecimals));

      const prevCumulativeSum = await staking.cumulativeSum();

      let firstOwedValue = await staking.getOwedValue(FIRST);
      let secondOwedValue = await staking.getOwedValue(SECOND);

      await staking.setRate(wei(2, rewardsDecimals));

      const expectedCumulativeSum = prevCumulativeSum + wei(rate, 25) / (await staking.totalShares());

      expect(await staking.rate()).to.equal(wei(2, rewardsDecimals));
      expect(await staking.cumulativeSum()).to.equal(expectedCumulativeSum);
      expect(await staking.updatedAt()).to.equal(await time.latest());

      expect(await staking.userOwedValue(FIRST)).to.equal(firstOwedValue);
      expect(await staking.userOwedValue(SECOND)).to.equal(secondOwedValue);
    });
  });

  describe("should handle staking manipulations with 6-decimal values", () => {
    it("should handle the whole staling process using 6-decimal values", async () => {
      const StakingMock = await ethers.getContractFactory("StakingMock");
      const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

      staking = await StakingMock.deploy();
      sharesToken = await ERC20Mock.deploy("SharesMock", "SMock", 6);
      rewardsToken = await ERC20Mock.deploy("RewardsMock", "RMock", 6);

      sharesDecimals = Number(await sharesToken.decimals());
      rewardsDecimals = Number(await rewardsToken.decimals());

      await rewardsToken.mint(await staking.getAddress(), wei(100, rewardsDecimals));

      await staking.__StakingMock_init(sharesToken, rewardsToken, wei(1, rewardsDecimals), 3n);

      await performStakingManipulations2();

      await checkManipulationRewards2();
    });
  });
});
