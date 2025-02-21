import { ethers } from "hardhat";
import { expect } from "chai";

import { Reverter } from "@/test/helpers/reverter";
import { ETHER_ADDR } from "@/scripts/utils/constants";

import { TypeCasterMock } from "@ethers-v6";

describe("TypeCaster", () => {
  const reverter = new Reverter();
  const coder = ethers.AbiCoder.defaultAbiCoder();

  let mock: TypeCasterMock;

  before("setup", async () => {
    const TypeCasterMock = await ethers.getContractFactory("TypeCasterMock");
    mock = await TypeCasterMock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("array cast", () => {
    const addressArrays = [[], [ethers.ZeroAddress, ETHER_ADDR]];
    const bytes32Arrays = [[], addressArrays[1].flatMap((e) => coder.encode(["address"], [e]))];
    const uint256Arrays = [[], <bigint[]>(<unknown>bytes32Arrays[1].flatMap((e) => coder.decode(["uint256"], e)))];

    describe("asUint256Array", () => {
      it("should convert bytes32 array to uint256 array properly", async () => {
        for (const [idx, bytes32Array] of bytes32Arrays.entries()) {
          expect(await mock.asUint256ArrayFromBytes32Array(bytes32Array)).to.deep.equal(uint256Arrays[idx]);
        }
      });

      it("should convert address array to uint256 array properly", async () => {
        for (const [idx, addressArray] of addressArrays.entries()) {
          expect(await mock.asUint256ArrayFromAddressArray(addressArray)).to.deep.equal(uint256Arrays[idx]);
        }
      });
    });

    describe("asAddressArray", () => {
      it("should convert bytes32 array to address array properly", async () => {
        for (const [idx, bytes32Array] of bytes32Arrays.entries()) {
          expect(await mock.asAddressArrayFromBytes32Array(bytes32Array)).to.deep.equal(addressArrays[idx]);
        }
      });

      it("should convert uint256 array to address array properly", async () => {
        for (const [idx, uint256Array] of uint256Arrays.entries()) {
          expect(await mock.asAddressArrayFromUint256Array(uint256Array)).to.deep.equal(addressArrays[idx]);
        }
      });
    });

    describe("asBytes32Array", () => {
      it("should convert uint256 array to bytes32 array properly", async () => {
        for (const [idx, uint256Array] of uint256Arrays.entries()) {
          expect(await mock.asBytes32ArrayFromUint256Array(uint256Array)).to.deep.equal(bytes32Arrays[idx]);
        }
      });

      it("should convert address array to bytes32 array properly", async () => {
        for (const [idx, addressArray] of addressArrays.entries()) {
          expect(await mock.asBytes32ArrayFromAddressArray(addressArray)).to.deep.equal(bytes32Arrays[idx]);
        }
      });
    });
  });

  describe("singleton array", () => {
    const MOCKED_BYTES32 = ethers.ZeroHash.replaceAll("0000", "1234");

    it("should build singleton arrays properly", async () => {
      expect(await mock.asSingletonArrayFromUint256(123)).to.deep.equal([123n]);

      expect(await mock.asSingletonArrayFromAddress(ETHER_ADDR)).to.deep.equal([ETHER_ADDR]);
      expect(await mock.asSingletonArrayFromBool(false)).to.deep.equal([false]);
      expect(await mock.asSingletonArrayFromString("1")).to.deep.equal(["1"]);
      expect(await mock.asSingletonArrayFromBytes32(MOCKED_BYTES32)).to.deep.equal([MOCKED_BYTES32]);
    });
  });

  describe("static2dynamic", () => {
    it("should convert static uint array to dynamic", async () => {
      expect(await mock.testUint()).to.be.true;
    });

    it("should convert static address array to dynamic", async () => {
      expect(await mock.testAddress()).to.be.true;
    });

    it("should convert static bool array to dynamic", async () => {
      expect(await mock.testBool()).to.be.true;
    });

    it("should convert static string array to dynamic", async () => {
      expect(await mock.testString()).to.be.true;
    });

    it("should convert static bytes32 array to dynamic", async () => {
      expect(await mock.testBytes32()).to.be.true;
    });
  });
});
