import { ethers } from "hardhat";
import { expect } from "chai";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";

import { Reverter } from "@/test/helpers/reverter";
import { precision } from "@/scripts/utils/utils";

import { CompoundRateKeeperMock } from "@ethers-v6";

const maxRate = 2n ** 128n - 1n;

describe("CompoundRateKeeper", () => {
  const reverter = new Reverter();

  let SECOND: SignerWithAddress;

  let keeper: CompoundRateKeeperMock;

  before("setup", async () => {
    [, SECOND] = await ethers.getSigners();

    const CompoundRateKeeperMock = await ethers.getContractFactory("CompoundRateKeeperMock");
    keeper = await CompoundRateKeeperMock.deploy();

    await keeper.__OwnableCompoundRateKeeper_init(precision(1), 31536000);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should not initialize twice", async () => {
      await expect(keeper.mockInit(precision(1), 31536000)).to.be.revertedWithCustomError(keeper, "NotInitializing");
      await expect(keeper.__OwnableCompoundRateKeeper_init(precision(1), 31536000))
        .to.be.revertedWithCustomError(keeper, "InvalidInitialization")
        .withArgs();
    });

    it("only owner should call these functions", async () => {
      await expect(keeper.connect(SECOND).setCapitalizationRate(precision(1)))
        .to.be.revertedWithCustomError(keeper, "OwnableUnauthorizedAccount")
        .withArgs(SECOND);

      await expect(keeper.connect(SECOND).setCapitalizationPeriod(31536000))
        .to.be.revertedWithCustomError(keeper, "OwnableUnauthorizedAccount")
        .withArgs(SECOND);
    });
  });

  describe("setCapitalizationRate()", () => {
    it("should correctly set new annual percent", async () => {
      let nextBlockTime = (await time.latest()) + 10;

      await time.setNextBlockTimestamp(nextBlockTime);
      await keeper.setCapitalizationRate(precision(1.1));

      expect(await keeper.getCompoundRate()).to.equal(precision(1));
      expect(await keeper.getCurrentRate()).to.equal(precision(1));
      expect(await keeper.getCapitalizationRate()).to.equal(precision(1.1));
      expect(await keeper.getLastUpdate()).to.equal(BigInt(nextBlockTime));

      nextBlockTime = (await time.latest()) + 31536000;

      await time.setNextBlockTimestamp(nextBlockTime);
      await keeper.setCapitalizationRate(precision(1.2));

      expect(await keeper.getCompoundRate()).to.equal(precision(1.1));
      expect(await keeper.getCapitalizationRate()).to.equal(precision(1.2));
      expect(await keeper.getLastUpdate()).to.equal(BigInt(nextBlockTime));
    });

    it("should revert if rate is less than zero", async () => {
      await expect(keeper.setCapitalizationRate(precision(0.99999)))
        .to.be.revertedWithCustomError(keeper, "RateIsLessThanOne")
        .withArgs(precision(0.99999));
    });

    it("should revert if compound rate reaches max limit", async () => {
      await time.setNextBlockTimestamp((await time.latest()) + 10);
      await keeper.setCapitalizationRate(precision(5));

      await time.setNextBlockTimestamp((await time.latest()) + 100 * 31536000);
      await keeper.emergencyUpdateCompoundRate();

      await expect(keeper.setCapitalizationRate(precision(1.1)))
        .to.be.revertedWithCustomError(keeper, "MaxRateIsReached")
        .withArgs();
    });
  });

  describe("setCapitalizationPeriod()", () => {
    it("should correctly set new capitalization period", async () => {
      expect(await keeper.getCapitalizationPeriod()).to.equal(31536000n);

      await keeper.setCapitalizationPeriod(10);
      expect(await keeper.getCapitalizationPeriod()).to.equal(10n);

      await keeper.setCapitalizationPeriod(157680000);
      expect(await keeper.getCapitalizationPeriod()).to.equal(157680000n);
    });

    it("should revert if capitalization period is zero", async () => {
      await expect(keeper.setCapitalizationPeriod(0))
        .to.be.revertedWithCustomError(keeper, "CapitalizationPeriodIsZero")
        .withArgs();
    });

    it("should revert if compound rate reaches max limit", async () => {
      await time.setNextBlockTimestamp((await time.latest()) + 10);
      await keeper.setCapitalizationRate(precision(5));

      await time.setNextBlockTimestamp((await time.latest()) + 100 * 31536000);
      await keeper.emergencyUpdateCompoundRate();

      await expect(keeper.setCapitalizationPeriod(1))
        .to.be.revertedWithCustomError(keeper, "MaxRateIsReached")
        .withArgs();
    });
  });

  describe("emergencyUpdateCompoundRate()", () => {
    it("should correctly update compound rate", async () => {
      await time.setNextBlockTimestamp((await time.latest()) + 10);
      await keeper.setCapitalizationRate(precision(5));

      await keeper.emergencyUpdateCompoundRate();

      expect(await keeper.getIsMaxRateReached()).to.be.false;

      await time.setNextBlockTimestamp((await time.latest()) + 100 * 31536000);
      await keeper.emergencyUpdateCompoundRate();

      expect(await keeper.getIsMaxRateReached()).to.be.true;
      expect(await keeper.getCompoundRate()).to.equal(precision(2n ** 128n - 1n));

      await keeper.emergencyUpdateCompoundRate();

      expect(await keeper.getIsMaxRateReached()).to.be.true;
      expect(await keeper.getCompoundRate()).to.equal(precision(2n ** 128n - 1n));
    });
  });

  describe("getFutureCompoundRate()", () => {
    async function checkByParams(rate: number) {
      await time.setNextBlockTimestamp((await time.latest()) + 10);
      await keeper.setCapitalizationRate(precision(rate));

      let calcRate: bigint;
      let expectedRate: bigint;

      for (let y = 3; y <= 3600; y += 9) {
        try {
          calcRate = await keeper.getFutureCompoundRate((await time.latest()) + y * 2628000);

          const capitalizationPeriodsNum = BigInt(y) / 12n;
          const capitalizationRate = BigInt(rate) ** capitalizationPeriodsNum;
          const leftRate = ((BigInt(y) % 12n) * (BigInt(rate) - 1n)) / 12n + 1n;

          expectedRate = precision(capitalizationRate * leftRate);

          if (expectedRate > maxRate) {
            expect(calcRate).to.equal(maxRate);
          } else {
            expect(calcRate - expectedRate).to.be.closeTo(0n, 100000000000000000000n);
          }
        } catch (e) {
          return;
        }
      }
    }

    it("check correct compound calculate for 50%, check max timestamp", async () => {
      await time.setNextBlockTimestamp((await time.latest()) + 10);
      await keeper.setCapitalizationRate(precision(1.5));

      expect(await keeper.getFutureCompoundRate((await time.latest()) + 2628000)).to.equal(
        precision("1.0416666666666666666666666"),
      );
      expect(await keeper.getFutureCompoundRate((await time.latest()) + 8 * 2628000)).to.equal(
        precision("1.3333333333333333333333333"),
      );
      expect(await keeper.getFutureCompoundRate((await time.latest()) + 31536000)).to.equal(precision("1.5"));
      expect(await keeper.getFutureCompoundRate((await time.latest()) + 2 * 31536000)).to.equal(precision("2.25"));
      expect(await keeper.getFutureCompoundRate((await time.latest()) + 2 * 31536000 + 31536000 / 4)).to.equal(
        precision("2.53125"),
      );
      expect(await keeper.getFutureCompoundRate((await time.latest()) + 2 * 31536000 + 31536000 / 2)).to.equal(
        precision("2.8125"),
      );
      expect(await keeper.getFutureCompoundRate((await time.latest()) + 2 * 31536000 + (31536000 / 4) * 3)).to.equal(
        precision("3.09375"),
      );
      expect(await keeper.getFutureCompoundRate((await time.latest()) + 5 * 31536000)).to.equal(precision("7.59375"));
      expect(await keeper.getFutureCompoundRate((await time.latest()) + 10 * 31536000)).to.equal(
        precision("57.6650390625"),
      );
      expect(await keeper.getFutureCompoundRate((await time.latest()) + 50 * 31536000)).to.equal(
        precision("637621500.2140495869034078069148136"),
      );
    });

    it("check compound rate when capitalization period changes", async () => {
      await time.setNextBlockTimestamp((await time.latest()) + 10);
      await keeper.setCapitalizationRateAndPeriod(precision(1.0000001), 1);

      expect(await keeper.getFutureCompoundRate((await time.latest()) + 31536000)).to.be.closeTo(
        precision(23.42),
        precision(0.01),
      );

      await time.setNextBlockTimestamp((await time.latest()) + 31536000);
      await keeper.setCapitalizationRateAndPeriod(precision(1.01), 86400);

      expect(await keeper.getFutureCompoundRate((await time.latest()) + 2 * 31536000)).to.be.closeTo(
        precision(33434.42),
        precision(0.01),
      );
    });

    it("check compound rate when capitalization rate changes", async () => {
      await time.setNextBlockTimestamp((await time.latest()) + 10);
      await keeper.setCapitalizationRate(precision(1.1));

      expect(await keeper.getFutureCompoundRate((await time.latest()) + 31536000)).to.equal(precision("1.1"));

      await time.setNextBlockTimestamp((await time.latest()) + 31536000);
      await keeper.setCapitalizationRate(precision(1.2));

      expect(await keeper.getFutureCompoundRate((await time.latest()) + 2 * 31536000)).to.equal(precision("1.584"));

      await time.setNextBlockTimestamp((await time.latest()) + 2 * 31536000);
      await keeper.setCapitalizationRate(precision(1.5));

      expect(await keeper.getFutureCompoundRate((await time.latest()) + 3 * 31536000)).to.equal(precision("5.346"));

      await time.setNextBlockTimestamp((await time.latest()) + 3 * 31536000);
      await keeper.setCapitalizationRate(precision(1.05));

      expect(await keeper.getFutureCompoundRate((await time.latest()) + 31536000)).to.equal(precision("5.6133"));
    });

    it("check max timestamp for 10%", async () => {
      await checkByParams(1.1);
    });

    it("check max timestamp for 25%", async () => {
      await checkByParams(1.25);
    });

    it("check max timestamp for 50%", async () => {
      await checkByParams(1.5);
    });

    it("check max timestamp for 100%", async () => {
      await checkByParams(2);
    });

    it("check max timestamp for 200%", async () => {
      await checkByParams(3);
    });

    it("check max timestamp for 500%", async () => {
      await checkByParams(6);
    });

    it("check max timestamp for 1000%", async () => {
      await checkByParams(11);
    });
  });
});
