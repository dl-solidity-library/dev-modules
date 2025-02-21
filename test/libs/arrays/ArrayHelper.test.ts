import { ethers } from "hardhat";
import { expect } from "chai";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";

import { ArrayHelperMock } from "@ethers-v6";

describe("ArrayHelper", () => {
  const reverter = new Reverter();

  let FIRST: SignerWithAddress;
  let SECOND: SignerWithAddress;
  let THIRD: SignerWithAddress;

  let mock: ArrayHelperMock;

  before("setup", async () => {
    [FIRST, SECOND, THIRD] = await ethers.getSigners();

    const ArrayHelperMock = await ethers.getContractFactory("ArrayHelperMock");
    mock = await ArrayHelperMock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("prefix sum array", () => {
    function getArraySum(arr: number[]) {
      return arr.reduce((prev, cur) => prev + cur, 0);
    }

    function countPrefixes(arr: number[]) {
      return arr.map((_, idx) => getArraySum(arr.slice(0, idx + 1)));
    }

    const array = [0, 100, 50, 4, 34, 520, 4];

    describe("bounds", () => {
      const arbitraryArray = [10, 20, 30, 30, 30, 40, 50];
      const singletonArray = [100];
      const identicalElemsArray = [100, 100, 100, 100, 100];

      describe("lowerBound", () => {
        it("should find the correct indices in the arbitrary array", async () => {
          await mock.setArray(arbitraryArray);

          expect(await mock.lowerBound(1)).to.equal(0n);
          expect(await mock.lowerBound(10)).to.equal(0n);
          expect(await mock.lowerBound(15)).to.equal(1n);
          expect(await mock.lowerBound(20)).to.equal(1n);
          expect(await mock.lowerBound(25)).to.equal(2n);
          expect(await mock.lowerBound(30)).to.equal(2n);
          expect(await mock.lowerBound(35)).to.equal(5n);
          expect(await mock.lowerBound(40)).to.equal(5n);
          expect(await mock.lowerBound(45)).to.equal(6n);
          expect(await mock.lowerBound(50)).to.equal(6n);
          expect(await mock.lowerBound(100)).to.equal(7n);
        });

        it("should find the correct indices in the singleton array", async () => {
          await mock.setArray(singletonArray);

          expect(await mock.lowerBound(1)).to.equal(0n);
          expect(await mock.lowerBound(100)).to.equal(0n);
          expect(await mock.lowerBound(150)).to.equal(1n);
        });

        it("should find the correct indices in the identical elements array", async () => {
          await mock.setArray(identicalElemsArray);

          expect(await mock.lowerBound(1)).to.equal(0n);
          expect(await mock.lowerBound(100)).to.equal(0n);
          expect(await mock.lowerBound(150)).to.equal(5n);
        });

        it("should find the correct indices in the empty array", async () => {
          expect(await mock.lowerBound(100)).to.equal(0n);
        });
      });

      describe("upperBound", () => {
        it("should find the correct indices in the arbitrary array", async () => {
          await mock.setArray(arbitraryArray);

          expect(await mock.upperBound(1)).to.equal(0n);
          expect(await mock.upperBound(10)).to.equal(1n);
          expect(await mock.upperBound(15)).to.equal(1n);
          expect(await mock.upperBound(20)).to.equal(2n);
          expect(await mock.upperBound(25)).to.equal(2n);
          expect(await mock.upperBound(30)).to.equal(5n);
          expect(await mock.upperBound(35)).to.equal(5n);
          expect(await mock.upperBound(40)).to.equal(6n);
          expect(await mock.upperBound(45)).to.equal(6n);
          expect(await mock.upperBound(50)).to.equal(7n);
          expect(await mock.upperBound(100)).to.equal(7n);
        });

        it("should find the correct indices in the singleton array", async () => {
          await mock.setArray(singletonArray);

          expect(await mock.upperBound(1)).to.equal(0n);
          expect(await mock.upperBound(100)).to.equal(1n);
          expect(await mock.upperBound(150)).to.equal(1n);
        });

        it("should find the correct indices in the identical elements array", async () => {
          await mock.setArray(identicalElemsArray);

          expect(await mock.upperBound(1)).to.equal(0n);
          expect(await mock.upperBound(100)).to.equal(5n);
          expect(await mock.upperBound(150)).to.equal(5n);
        });

        it("should find the correct indices in the empty array", async () => {
          expect(await mock.upperBound(100)).to.equal(0n);
        });
      });
    });

    describe("getRangeSum", () => {
      it("should get the range sum properly if all conditions are met", async () => {
        await mock.setArray((await mock.countPrefixes(array)).map((e) => Number(e)));

        for (let l = 0; l < array.length; l++) {
          for (let r = l; r < array.length; r++) {
            expect(await mock.getRangeSum(l, r)).to.equal(BigInt(getArraySum(array.slice(l, r + 1))));
          }
        }
      });

      it("should revert if the first index is greater than the last one", async () => {
        await mock.setArray((await mock.countPrefixes(array)).map((e) => Number(e)));

        await expect(mock.getRangeSum(array.length - 1, 0))
          .to.be.revertedWithCustomError(mock, "InvalidRange")
          .withArgs(array.length - 1, 0);
        await expect(mock.getRangeSum(1, 0)).to.be.revertedWithCustomError(mock, "InvalidRange").withArgs(1, 0);
        await expect(mock.getRangeSum(2, 1)).to.be.revertedWithCustomError(mock, "InvalidRange").withArgs(2, 1);
      });

      it("should revert if one of the indexes is out of range", async () => {
        await expect(mock.getRangeSum(0, 0)).to.be.reverted;

        await mock.setArray((await mock.countPrefixes(array)).map((e) => Number(e)));

        await expect(mock.getRangeSum(0, array.length)).to.be.reverted;
      });
    });

    describe("countPrefixes", () => {
      it("should compute prefix array properly", async () => {
        expect(await mock.countPrefixes([])).to.deep.equal([]);
        expect(await mock.countPrefixes(array)).to.deep.equal(countPrefixes(array).map((e) => BigInt(e)));
      });
    });
  });

  describe("contains", () => {
    const arbitraryArray = [10, 20, 30, 30, 35, 40, 50];
    const smallArray = [100];

    it("should find the element in the arbitrary array", async () => {
      await mock.setArray(arbitraryArray);

      for (const element of arbitraryArray) {
        expect(await mock.contains(element)).to.equal(true);
      }

      expect(await mock.contains(1)).to.equal(false);
      expect(await mock.contains(100)).to.equal(false);
    });

    it("should find the element if the array contains only one element", async () => {
      await mock.setArray(smallArray);

      expect(await mock.contains(smallArray[0])).to.equal(true);
      expect(await mock.contains(1)).to.equal(false);
      expect(await mock.contains(200)).to.equal(false);
    });
  });

  describe("reverse", async () => {
    it("should reverse uint array", async () => {
      const arr = await mock.reverseUint([1, 2, 3]);

      expect(arr.length).to.equal(3);
      expect(arr[0]).to.equal(3n);
      expect(arr[1]).to.equal(2n);
      expect(arr[2]).to.equal(1n);
    });

    it("should reverse address array", async () => {
      const arr = await mock.reverseAddress([FIRST.address, SECOND.address, THIRD.address]);

      expect(arr.length).to.equal(3);
      expect(arr[0]).to.equal(THIRD.address);
      expect(arr[1]).to.equal(SECOND.address);
      expect(arr[2]).to.equal(FIRST.address);
    });

    it("should reverse bool array", async () => {
      const arr = await mock.reverseBool([true, true, false]);

      expect(arr.length).to.equal(3);
      expect(arr[0]).to.equal(false);
      expect(arr[1]).to.equal(true);
      expect(arr[2]).to.equal(true);
    });

    it("should reverse string array", async () => {
      const arr = await mock.reverseString(["1", "2", "3"]);

      expect(arr.length).to.equal(3);
      expect(arr[0]).to.equal("3");
      expect(arr[1]).to.equal("2");
      expect(arr[2]).to.equal("1");
    });

    it("should reverse bytes32 array", async () => {
      const bytes32Arrays = [
        ethers.ZeroHash.replaceAll("0000", "1234"),
        ethers.ZeroHash.replaceAll("0000", "4321"),
        ethers.ZeroHash.replaceAll("0000", "abcd"),
      ];

      const arr = await mock.reverseBytes32(bytes32Arrays);

      expect(arr.length).to.equal(3);
      expect(arr[0]).to.equal(bytes32Arrays[2]);
      expect(arr[1]).to.equal(bytes32Arrays[1]);
      expect(arr[2]).to.equal(bytes32Arrays[0]);
    });

    it("should reverse empty array", async () => {
      let arrUint = await mock.reverseUint([]);
      expect(arrUint.length).to.equal(0);

      let arrAddress = await mock.reverseAddress([]);
      expect(arrAddress.length).to.equal(0);

      let arrString = await mock.reverseString([]);
      expect(arrString.length).to.equal(0);

      let arrBytes32 = await mock.reverseBytes32([]);
      expect(arrBytes32.length).to.equal(0);
    });
  });

  describe("insert", () => {
    it("should insert uint array", async () => {
      const base = [1, 2, 3, 0, 0, 0];
      const index = 3;
      const what = [4, 5, 6];

      const res = await mock.insertUint(base, index, what);

      expect(res[0]).to.equal(6n);
      expect(res[1]).to.deep.equal([1n, 2n, 3n, 4n, 5n, 6n]);
    });

    it("should insert address array", async () => {
      const base = [FIRST.address, SECOND.address];
      const index = 1;
      const what = [THIRD.address];

      const res = await mock.insertAddress(base, index, what);

      expect(res[0]).to.equal(2n);
      expect(res[1]).to.deep.equal([FIRST.address, THIRD.address]);
    });

    it("should insert bool array", async () => {
      const base = [true, false];
      const index = 1;
      const what = [true];

      const res = await mock.insertBool(base, index, what);

      expect(res[0]).to.equal(2n);
      expect(res[1]).to.deep.equal([true, true]);
    });

    it("should insert string array", async () => {
      const base = ["1", "2"];
      const index = 1;
      const what = ["3"];

      const res = await mock.insertString(base, index, what);

      expect(res[0]).to.equal(2n);
      expect(res[1]).to.deep.equal(["1", "3"]);
    });

    it("should insert bytes32 array", async () => {
      const bytes32Arrays = [
        ethers.ZeroHash.replaceAll("0000", "1111"),
        ethers.ZeroHash.replaceAll("0000", "2222"),
        ethers.ZeroHash.replaceAll("0000", "3333"),
      ];

      const base = [bytes32Arrays[0], bytes32Arrays[1]];
      const index = 1;
      const what = [bytes32Arrays[2]];

      const res = await mock.insertBytes32(base, index, what);

      expect(res[0]).to.equal(2n);
      expect(res[1]).to.deep.equal([bytes32Arrays[0], bytes32Arrays[2]]);
    });

    it("should revert in case of out of bound insertion", async () => {
      await expect(mock.insertUint([1], 1, [2])).to.be.reverted;
      await expect(mock.insertAddress([], 0, [FIRST.address])).to.be.reverted;
      await expect(mock.insertString(["1", "2"], 2, ["1"])).to.be.reverted;
    });
  });

  describe("crop", () => {
    it("should crop uint256 array properly", async () => {
      let arr = await mock.cropUint([1, 2, 3, 0], 3);

      expect(arr.length).to.equal(3);
    });

    it("should crop address array properly", async () => {
      let arr = await mock.cropAddress([FIRST.address, SECOND.address, THIRD.address], 2);

      expect(arr).to.deep.equal([FIRST.address, SECOND.address]);
    });

    it("should crop bool array properly", async () => {
      let arr = await mock.cropBool([true, false, true], 2);

      expect(arr).to.deep.equal([true, false]);
    });

    it("should crop string array properly", async () => {
      let arr = await mock.cropString(["a", "b", "c"], 2);

      expect(arr).to.deep.equal(["a", "b"]);
    });

    it("should crop bytes32 array properly", async () => {
      let arr = await mock.cropBytes([ethers.ZeroHash, ethers.ZeroHash], 1);

      expect(arr).to.deep.equal([ethers.ZeroHash]);
    });

    it("should not crop uint256 array if new length more than initial length", async () => {
      let arr = await mock.cropUint([1, 2, 3, 0], 5);

      expect(arr.length).to.equal(4);
    });

    it("should not crop address array if new length more than initial length", async () => {
      let arr = await mock.cropAddress([FIRST.address, SECOND.address, THIRD.address], 5);

      expect(arr.length).to.equal(3);
    });

    it("should not crop bool if new length more than initial length", async () => {
      let arr = await mock.cropBool([true, false], 2);

      expect(arr.length).to.equal(2);
    });

    it("should not crop string array if new length more than initial length", async () => {
      let arr = await mock.cropString(["a", "b", "c"], 6);

      expect(arr.length).to.equal(3);
    });

    it("should not crop bytes32 array if new length more than initial length", async () => {
      let arr = await mock.cropBytes([ethers.ZeroHash, ethers.ZeroHash], 2);

      expect(arr.length).to.equal(2);
    });
  });
});
