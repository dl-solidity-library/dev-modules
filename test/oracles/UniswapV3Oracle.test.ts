import { ethers } from "hardhat";
import { expect } from "chai";

import { time } from "@nomicfoundation/hardhat-network-helpers";
import { BigNumberish } from "ethers";
import { BigNumber } from "bignumber.js";

import { wei } from "@/scripts/utils/utils";
import { Reverter } from "@/test/helpers/reverter";

import { UniswapV3Oracle, UniswapV3FactoryMock, UniswapV3PoolMock } from "@ethers-v6";

describe("UniswapV3Oracle", () => {
  const reverter = new Reverter();

  const A_TOKEN = "0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa";
  const B_TOKEN = "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB";
  const C_TOKEN = "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC";
  const A_B_PATH = [A_TOKEN, B_TOKEN];

  const PERIOD = 1;
  const enum FeeAmount {
    LOW = 500,
    MEDIUM = 3000,
  }

  let oracle: UniswapV3Oracle;
  let uniswapV3Factory: UniswapV3FactoryMock;

  before("setup", async () => {
    const UniswapV3FactoryMock = await ethers.getContractFactory("UniswapV3FactoryMock");
    const Oracle = await ethers.getContractFactory("UniswapV3Oracle");

    uniswapV3Factory = await UniswapV3FactoryMock.deploy();
    oracle = await Oracle.deploy(await uniswapV3Factory.getAddress());

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  async function createPools(token0: string, token1: string): Promise<UniswapV3PoolMock> {
    await uniswapV3Factory.createPool(token0, token1, FeeAmount.MEDIUM);

    const poolAddress = await uniswapV3Factory.getPool(token0, token1, FeeAmount.MEDIUM);

    return <UniswapV3PoolMock>await ethers.getContractAt("UniswapV3PoolMock", poolAddress);
  }

  function encodePriceSqrt(reserve1: BigNumberish, reserve0: BigNumberish): BigNumberish {
    return new BigNumber(reserve1.toString())
      .div(reserve0.toString())
      .sqrt()
      .times((2n ** 96n).toString())
      .toFixed(0);
  }

  function getPriceByTick(tick: number, amount: BigNumberish): BigNumberish {
    BigNumber.config({ POW_PRECISION: 100 });

    return new BigNumber("1.0001").pow(tick).times(amount.toString()).toFixed(0, 1);
  }

  describe("init", () => {
    it("should set oracle correctly", async () => {
      expect(await oracle.uniswapV3Factory()).to.equal(await uniswapV3Factory.getAddress());
    });
  });

  describe("getPrice", () => {
    it("should correctly get price if there are same tokens in the path", async () => {
      const ans = await oracle.getPriceOfTokenInToken([A_TOKEN, A_TOKEN], [FeeAmount.MEDIUM], 51, PERIOD);

      expect(ans[0]).to.equal(51);
    });

    it("should correctly get price if it is older than observation", async () => {
      const poolAB = await createPools(A_TOKEN, B_TOKEN);

      const firstTime = (await time.latest()) + 2;
      await time.increaseTo(firstTime);

      await poolAB.initialize(encodePriceSqrt(wei(1, 6), wei(1)));

      await time.increaseTo(firstTime + 3);

      const ans = await oracle.getPriceOfTokenInToken(A_B_PATH, [FeeAmount.MEDIUM], wei(5), 5);

      expect(ans[0]).to.equal(getPriceByTick(Number((await poolAB.slot0()).tick), wei(5)));
      expect(ans[1]).to.equal((await time.latest()) - firstTime - 1);
    });

    it("should correctly increase cardinality and overwrite observations", async () => {
      const poolAB = await createPools(A_TOKEN, B_TOKEN);

      await poolAB.initialize(encodePriceSqrt(wei(1, 6), wei(1, 12)));
      await poolAB.increaseObservationCardinalityNext(2);

      await time.increaseTo((await time.latest()) + 1);

      const tickAB = -111;
      await poolAB.addObservation(tickAB);

      const firstTime = await time.latest();
      await time.increaseTo(firstTime + 3);

      await poolAB.addObservation(250);

      const ans = await oracle.getPriceOfTokenInToken(A_B_PATH, [FeeAmount.MEDIUM], wei(1, 6), 3);

      expect(ans[0]).to.equal(getPriceByTick(tickAB, wei(1, 6)));
      expect(ans[1]).to.equal(3);
    });

    it("should correctly get price for complex path", async () => {
      const poolAB = await createPools(A_TOKEN, B_TOKEN);
      const poolBC = await createPools(B_TOKEN, C_TOKEN);

      const reserveAB0 = wei(1);
      const reserveAB1 = wei(2, 6);
      const reserveBC0 = wei(1, 6);
      const reserveBC1 = 100n;

      await poolAB.initialize(encodePriceSqrt(reserveAB1, reserveAB0));
      await poolBC.initialize(encodePriceSqrt(reserveBC1, reserveBC0));

      await time.increaseTo((await time.latest()) + 2);

      let ans = await oracle.getPriceOfTokenInToken(
        [A_TOKEN, B_TOKEN, C_TOKEN],
        [FeeAmount.MEDIUM, FeeAmount.MEDIUM],
        wei(2),
        PERIOD,
      );

      const priceABC = (((wei(2) * reserveAB1) / reserveAB0) * reserveBC1) / reserveBC0;

      expect(ans[0]).to.be.closeTo(priceABC, 1);
      expect(ans[1]).to.equal(PERIOD);

      ans = await oracle.getPriceOfTokenInToken(
        [A_TOKEN, B_TOKEN, A_TOKEN],
        [FeeAmount.MEDIUM, FeeAmount.MEDIUM],
        wei(2),
        PERIOD,
      );

      expect(ans[0]).to.be.closeTo(wei(2), wei(2, 12));
      expect(ans[1]).to.equal(PERIOD);
    });

    it("should correctly get average price", async () => {
      const poolAB = await createPools(A_TOKEN, B_TOKEN);

      const firstTime = (await time.latest()) + 2;

      await time.increaseTo(firstTime);
      await poolAB.initialize(encodePriceSqrt(1, 1)); // first observation taken at firstTime
      await poolAB.increaseObservationCardinalityNext(4);

      await time.increaseTo(firstTime + 3);
      const tickSecond = -127;
      await poolAB.addObservation(tickSecond); // second observation taken at firstTime + 3

      await time.increaseTo(firstTime + 5);
      const tickThird = -871;
      await poolAB.addObservation(tickThird); // third observation at firstTime + 5

      await time.increaseTo(firstTime + 8);
      await poolAB.addObservation(-1241); // forth observation at firstTime + 8

      const ans = await oracle.getPriceOfTokenInToken(
        A_B_PATH,
        [FeeAmount.MEDIUM],
        wei(1, 6),
        (await time.latest()) - 1,
      );

      const avgTick = Math.floor((0 * 3 + tickSecond * 2 + tickThird * 3) / 8);

      expect(ans[0]).to.equal(getPriceByTick(avgTick, wei(1, 6)));
      expect(ans[1]).to.equal((await time.latest()) - firstTime - 1); // time of first observation
    });

    it("should correctly return period if it differs and get price from ticks", async () => {
      const poolAB = await createPools(A_TOKEN, B_TOKEN);
      const poolBC = await createPools(B_TOKEN, C_TOKEN);

      await poolAB.initialize(encodePriceSqrt(wei(1, 6), wei(1, 18)));
      await poolAB.increaseObservationCardinalityNext(2);

      const firstTime = await time.latest();
      const tickAB = -22222;
      await poolAB.addObservation(tickAB);

      await time.increaseTo(firstTime + 2);
      await poolBC.initialize(encodePriceSqrt(wei(1, 8), wei(1, 3)));
      await poolBC.increaseObservationCardinalityNext(3);

      const tick0 = Number((await poolBC.slot0()).tick);

      await time.increaseTo(firstTime + 6);
      await poolBC.addObservation(25000);

      await time.increaseTo(firstTime + 8);
      await poolBC.addObservation(24000);

      let ans = await oracle.getPriceOfTokenInToken(
        [A_TOKEN, B_TOKEN, C_TOKEN],
        [FeeAmount.MEDIUM, FeeAmount.MEDIUM],
        wei(3),
        (await time.latest()) - firstTime - 1,
      );

      const tickBC = Math.floor((tick0 * 4 + 25000 * 2) / 6);

      // priceAB = 1.0001 ** tickAB, priceBC = 1.0001 ** tickBC,
      // so priceAC = priceAB * priceBC = 1.0001 ** (tickAB + tickBC)
      expect(ans[0]).to.be.closeTo(getPriceByTick(tickAB + tickBC, wei(3)), wei(5, 3));
      expect(ans[1]).to.equal((await time.latest()) - firstTime - 3); // time of a first observation in second pool

      await time.increaseTo((await time.latest()) + 2);
      ans = await oracle.getPriceOfTokenInToken(
        [A_TOKEN, B_TOKEN, C_TOKEN],
        [FeeAmount.MEDIUM, FeeAmount.MEDIUM],
        wei(3),
        PERIOD,
      );

      const compositeTick = Number((await poolAB.slot0()).tick + (await poolBC.slot0()).tick);

      expect(ans[0]).equal(getPriceByTick(compositeTick, wei(3)));
    });

    it("should work correct if some observations aren't initialized", async () => {
      const poolAB = await createPools(A_TOKEN, B_TOKEN);

      const firstTime = (await time.latest()) + 2;
      await time.increaseTo(firstTime);
      await poolAB.initialize(encodePriceSqrt(wei(1, 6), wei(1, 3)));

      await poolAB.increaseObservationCardinalityNext(4);
      await poolAB.addObservation(-111);

      const ans = await oracle.getPriceOfTokenInToken(A_B_PATH, [FeeAmount.MEDIUM], 10, 3);
      expect(ans[1]).to.equal((await time.latest()) - firstTime - 1);
    });

    it("should return 0 if amount is 0", async () => {
      const ans = await oracle.getPriceOfTokenInToken([A_TOKEN, A_TOKEN], [FeeAmount.MEDIUM], 0, PERIOD);

      expect(ans).to.deep.equal([0n, 0n]);
    });

    it("should not get price if there is invalid path", async () => {
      await expect(oracle.getPriceOfTokenInToken([A_TOKEN], [FeeAmount.MEDIUM], 10, PERIOD)).to.be.revertedWith(
        "UniswapV3Oracle: invalid path",
      );
    });

    it("should not get price if there wrong amount of fees or tokens", async () => {
      await expect(
        oracle.getPriceOfTokenInToken([A_TOKEN, A_TOKEN, A_TOKEN], [FeeAmount.MEDIUM], 10, PERIOD),
      ).to.be.revertedWith("UniswapV3Oracle: path/fee lengths do not match");
    });

    it("should not get price if there is no such pool", async () => {
      await expect(oracle.getPriceOfTokenInToken(A_B_PATH, [FeeAmount.MEDIUM], 10, PERIOD)).to.be.revertedWith(
        "UniswapV3Oracle: such pool doesn't exist",
      );

      await createPools(A_TOKEN, B_TOKEN);
      await expect(oracle.getPriceOfTokenInToken(A_B_PATH, [FeeAmount.LOW], 10, PERIOD)).to.be.revertedWith(
        "UniswapV3Oracle: such pool doesn't exist",
      );
    });

    it("should not get price if period larger than current timestamp", async () => {
      await expect(
        oracle.getPriceOfTokenInToken([A_TOKEN, A_TOKEN], [FeeAmount.MEDIUM], 10, (await time.latest()) + 10),
      ).to.be.revertedWith("UniswapV3Oracle: period larger than current timestamp");
    });

    it("should return if oldest observation is on current block", async () => {
      const poolAB = await createPools(A_TOKEN, B_TOKEN);

      await poolAB.initialize(encodePriceSqrt(1, 1));

      await expect(oracle.getPriceOfTokenInToken(A_B_PATH, [FeeAmount.MEDIUM], 10, PERIOD)).to.be.revertedWith(
        "UniswapV3Oracle: the oldest observation is on the current block",
      );
    });

    it("should not get price if period is zero", async () => {
      await expect(oracle.getPriceOfTokenInToken([A_TOKEN, A_TOKEN], [FeeAmount.MEDIUM], 10, 0)).to.be.revertedWith(
        "UniswapV3Oracle: period can't be 0",
      );
    });
  });
});
