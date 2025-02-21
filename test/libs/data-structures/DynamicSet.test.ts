import { ethers } from "hardhat";
import { expect } from "chai";

import { Reverter } from "@/test/helpers/reverter";

import { DynamicSetMock } from "@ethers-v6";

describe("DynamicSet", () => {
  const reverter = new Reverter();

  let mock: DynamicSetMock;

  before("setup", async () => {
    const DynamicSetMockFactory = await ethers.getContractFactory("DynamicSetMock");
    mock = await DynamicSetMockFactory.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("StringSet", () => {
    describe("add()", () => {
      it("should add different strings twice", async () => {
        const expected1 = "test1";
        const expected2 = "test2";

        expect(await mock.addString.staticCall(expected1)).to.be.true;

        await mock.addString(expected1);
        await mock.addString(expected2);

        const set = await mock.getStringSet();

        expect(set.length).to.be.equal(2n);
        expect(set).to.be.deep.eq([expected1, expected2]);
      });

      it("should add empty string", async () => {
        const expected = "";

        await mock.addString(expected);

        const set = await mock.getStringSet();

        expect(set.length).to.be.equal(1n);
        expect(set).to.be.deep.equal([expected]);
      });

      it("should add same string twice", async () => {
        const expected = "test";

        await mock.addString(expected);

        expect(await mock.addString.staticCall(expected)).to.be.false;
        await mock.addString(expected);

        const set = await mock.getStringSet();

        expect(set.length).to.be.equal(1n);
        expect(set).to.be.deep.equal([expected]);
      });
    });

    describe("remove()", () => {
      it("should remove string", async () => {
        const expected = "test";

        await mock.addString(expected);

        expect(await mock.removeString.staticCall(expected)).to.be.true;

        await mock.removeString(expected);

        const set = await mock.getStringSet();

        expect(set.length).to.be.equal(0n);
      });

      it("should call remove at empty set", async () => {
        expect(await mock.removeString.staticCall("test")).to.be.false;
      });

      it("should remove non-existent string", async () => {
        const expected = "test";

        await mock.addString(expected);
        await mock.removeString(expected + "1");

        const set = await mock.getStringSet();

        expect(set.length).to.be.equal(1n);
        expect(set).to.be.deep.equal([expected]);
      });

      it("should remove from middle", async () => {
        const expected1 = "test1";
        const expected2 = "test2";
        const expected3 = "test3";

        await mock.addString(expected1);
        await mock.addString(expected2);
        await mock.addString(expected3);

        await mock.removeString(expected2);

        const set = await mock.getStringSet();

        expect(set.length).to.be.equal(2n);
        expect(set).to.be.deep.equal([expected1, expected3]);
      });
    });

    describe("contains()", () => {
      it("should return true", async () => {
        const expected = "test";

        await mock.addString(expected);

        expect(await mock.containsString(expected)).to.be.true;
      });

      it("should return false", async () => {
        const expected = "test";

        await mock.addString(expected);

        expect(await mock.containsString(expected + "1")).to.be.false;
      });
    });

    describe("length()", () => {
      it("should return correct length", async () => {
        const expected = "test";

        expect(await mock.lengthString()).to.be.equal(0n);

        await mock.addString(expected);

        expect(await mock.lengthString()).to.be.equal(1n);

        await mock.addString(expected);

        expect(await mock.lengthString()).to.be.equal(1n);
      });
    });

    describe("at()", () => {
      it("should correctly return 10 values", async () => {
        const expected = "test";

        for (let i = 0; i < 10; i++) {
          await mock.addString(expected + i);
        }

        for (let i = 0; i < 10; i++) {
          expect(await mock.atString(i)).to.be.equal(expected + i);
        }
      });
    });

    describe("values()", () => {
      it("should return all values", async () => {
        const expected = "test";

        for (let i = 0; i < 10; i++) {
          await mock.addString(expected + i);
        }

        const values = await mock.valuesString();

        for (let i = 0; i < 10; i++) {
          expect(expected + i).to.be.equal(values[i]);
        }
      });
    });
  });

  describe("BytesSet", () => {
    describe("add()", () => {
      it("should add different bytes twice", async () => {
        const expected1 = ethers.toUtf8Bytes("test1");
        const expected2 = ethers.toUtf8Bytes("test2");

        expect(await mock.addBytes.staticCall(expected1)).to.be.true;

        await mock.addBytes(expected1);
        await mock.addBytes(expected2);

        const set = await mock.getBytesSet();

        expect(set.length).to.be.equal(2n);
        expect(set).to.be.deep.eq([ethers.hexlify(expected1), ethers.hexlify(expected2)]);
      });

      it("should add empty bytes", async () => {
        const expected = ethers.toUtf8Bytes("");

        await mock.addBytes(expected);

        const set = await mock.getBytesSet();

        expect(set.length).to.be.equal(1n);
        expect(set).to.be.deep.equal([ethers.hexlify(expected)]);
      });

      it("should add same bytes twice", async () => {
        const expected = ethers.toUtf8Bytes("test");

        await mock.addBytes(expected);

        expect(await mock.addBytes.staticCall(expected)).to.be.false;
        await mock.addBytes(expected);

        const set = await mock.getBytesSet();

        expect(set.length).to.be.equal(1n);
        expect(set).to.be.deep.equal([ethers.hexlify(expected)]);
      });
    });

    describe("remove()", () => {
      it("should remove bytes", async () => {
        const expected = ethers.toUtf8Bytes("test");

        await mock.addBytes(expected);

        expect(await mock.removeBytes.staticCall(expected)).to.be.true;

        await mock.removeBytes(expected);

        const set = await mock.getBytesSet();

        expect(set.length).to.be.equal(0n);
      });

      it("should call remove at empty set", async () => {
        expect(await mock.removeBytes.staticCall(ethers.toUtf8Bytes("test"))).to.be.false;
      });

      it("should remove non-existent bytes", async () => {
        const expected = ethers.toUtf8Bytes("test");

        await mock.addBytes(expected);
        await mock.removeBytes(ethers.toUtf8Bytes("test1"));

        const set = await mock.getBytesSet();

        expect(set.length).to.be.equal(1n);
        expect(set).to.be.deep.equal([ethers.hexlify(expected)]);
      });

      it("should remove from middle", async () => {
        const expected1 = ethers.toUtf8Bytes("test1");
        const expected2 = ethers.toUtf8Bytes("test2");
        const expected3 = ethers.toUtf8Bytes("test3");

        await mock.addBytes(expected1);
        await mock.addBytes(expected2);
        await mock.addBytes(expected3);

        await mock.removeBytes(expected2);

        const set = await mock.getBytesSet();

        expect(set.length).to.be.equal(2n);
        expect(set).to.be.deep.equal([ethers.hexlify(expected1), ethers.hexlify(expected3)]);
      });
    });

    describe("contains()", () => {
      it("should return true", async () => {
        const expected = ethers.toUtf8Bytes("test");

        await mock.addBytes(expected);

        expect(await mock.containsBytes(expected)).to.be.true;
      });

      it("should return false", async () => {
        const expected = ethers.toUtf8Bytes("test");

        await mock.addBytes(expected);

        expect(await mock.containsBytes(ethers.toUtf8Bytes("test1"))).to.be.false;
      });
    });

    describe("length()", () => {
      it("should return correct length", async () => {
        const expected = ethers.toUtf8Bytes("test");

        expect(await mock.lengthBytes()).to.be.equal(0n);

        await mock.addBytes(expected);

        expect(await mock.lengthBytes()).to.be.equal(1n);

        await mock.addBytes(expected);

        expect(await mock.lengthBytes()).to.be.equal(1n);
      });
    });

    describe("at()", () => {
      it("should correctly return 10 values", async () => {
        for (let i = 0; i < 10; i++) {
          await mock.addBytes(ethers.toUtf8Bytes(`test${i}`));
        }

        for (let i = 0; i < 10; i++) {
          expect(await mock.atBytes(i)).to.be.equal(ethers.hexlify(ethers.toUtf8Bytes(`test${i}`)));
        }
      });
    });

    describe("values()", () => {
      it("should return all values", async () => {
        for (let i = 0; i < 10; i++) {
          await mock.addBytes(ethers.toUtf8Bytes(`test${i}`));
        }

        const values = await mock.valuesBytes();

        for (let i = 0; i < 10; i++) {
          expect(ethers.hexlify(ethers.toUtf8Bytes(`test${i}`))).to.be.equal(values[i]);
        }
      });
    });
  });
});
