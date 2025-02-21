import { ethers } from "hardhat";
import { expect } from "chai";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { encodeBytes32String, toBeHex } from "ethers";

import { Reverter } from "@/test/helpers/reverter";

import { AvlTreeMock } from "@ethers-v6";

describe("AvlTree", () => {
  const reverter = new Reverter();

  let USER1: SignerWithAddress;
  let USER2: SignerWithAddress;
  let USER3: SignerWithAddress;
  let USER4: SignerWithAddress;

  let avlTree: AvlTreeMock;

  before(async () => {
    [USER1, USER2, USER3, USER4] = await ethers.getSigners();
    const AvlTreeMock = await ethers.getContractFactory("AvlTreeMock");

    avlTree = await AvlTreeMock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  function uintToBytes32Array(uintArray: Array<number>) {
    let bytes32Array = [];

    for (let i = 0; i < uintArray.length; i++) {
      bytes32Array.push(encodeBytes32String(uintArray[i].toString()));
    }

    return bytes32Array;
  }

  describe("Uint Tree", () => {
    describe("insert", () => {
      it("should insert values to the uint tree correctly", async () => {
        await avlTree.insertUint(4, 1);
        await avlTree.insertUint(12, 2);
        await avlTree.insertUint(1, 3);

        expect(await avlTree.rootUint()).to.equal(4);
        expect(await avlTree.sizeUint()).to.equal(3);

        let traversal = await avlTree.traverseUint();
        expect(traversal[0]).to.deep.equal([1, 4, 12]);
        expect(traversal[1]).to.deep.equal([3, 1, 2]);

        await avlTree.insertUint(200, 4);
        await avlTree.insertUint(10, 5);
        await avlTree.insertUint(5, 6);

        expect(await avlTree.rootUint()).to.equal(10);
        expect(await avlTree.sizeUint()).to.equal(6);

        traversal = await avlTree.traverseUint();
        expect(traversal[0]).to.deep.equal([1, 4, 5, 10, 12, 200]);
        expect(traversal[1]).to.deep.equal([3, 1, 6, 5, 2, 4]);

        await avlTree.insertUint(15, 7);

        expect(await avlTree.rootUint()).to.equal(10);
        expect(await avlTree.sizeUint()).to.equal(7);

        traversal = await avlTree.traverseUint();
        expect(traversal[0]).to.deep.equal([1, 4, 5, 10, 12, 15, 200]);
        expect(traversal[1]).to.deep.equal([3, 1, 6, 5, 2, 7, 4]);

        await avlTree.insertUint(2, 8);
        await avlTree.insertUint(3, 9);

        expect(await avlTree.rootUint()).to.equal(10);
        expect(await avlTree.sizeUint()).to.equal(9);

        traversal = await avlTree.traverseUint();
        expect(traversal[0]).to.deep.equal([1, 2, 3, 4, 5, 10, 12, 15, 200]);
        expect(traversal[1]).to.deep.equal([3, 8, 9, 1, 6, 5, 2, 7, 4]);
      });

      it("should handle complex operations on the uint tree", async () => {
        await avlTree.insertUint(2, 10);
        await avlTree.insertUint(3, 1);
        await avlTree.insertUint(10, 18);

        await avlTree.removeUint(3);

        await avlTree.insertUint(4, 20);
        await avlTree.insertUint(5, 10);

        await avlTree.removeUint(2);
        await avlTree.removeUint(10);
        await avlTree.removeUint(4);

        await avlTree.insertUint(4, 7);
        await avlTree.insertUint(1, 20);
        await avlTree.insertUint(2, 10);
        await avlTree.insertUint(20, 20);
        await avlTree.insertUint(111, 10);

        await avlTree.removeUint(20);

        await avlTree.insertUint(16, 20);
        await avlTree.insertUint(17, 100);
        await avlTree.insertUint(18, 20);
        await avlTree.insertUint(19, 250);
        await avlTree.insertUint(20, 4);

        expect(await avlTree.rootUint()).to.equal(4);
        expect(await avlTree.sizeUint()).to.equal(10);

        const traversal = await avlTree.traverseUint();
        expect(traversal[0]).to.deep.equal([1, 2, 4, 5, 16, 17, 18, 19, 20, 111]);
        expect(traversal[1]).to.deep.equal([20, 10, 7, 10, 20, 100, 20, 250, 4, 10]);
      });

      it("should not allow to insert 0 as key to the uint tree", async () => {
        await expect(avlTree.insertUint(0, 100)).to.be.revertedWithCustomError(avlTree, "KeyIsZero").withArgs();
      });

      it("should not allow to insert node with duplicate key to the uint tree", async () => {
        const key = 2;
        await avlTree.insertUint(key, 10);

        await expect(avlTree.insertUint(key, 4))
          .to.be.revertedWithCustomError(avlTree, "NodeAlreadyExists")
          .withArgs(toBeHex(key, 32));
      });
    });

    describe("remove", () => {
      it("should remove a node in the uint tree correctly", async () => {
        await avlTree.insertUint(2, 4);
        await avlTree.insertUint(3, 8);
        await avlTree.insertUint(6, 10);
        await avlTree.insertUint(1, 2);
        await avlTree.insertUint(4, 10);
        await avlTree.insertUint(7, 10);
        await avlTree.insertUint(10, 10);

        expect(await avlTree.rootUint()).to.equal(3);
        expect(await avlTree.sizeUint()).to.equal(7);

        await avlTree.removeUint(3);

        expect(await avlTree.rootUint()).to.equal(4);
        expect(await avlTree.sizeUint()).to.equal(6);

        const traversal = await avlTree.traverseUint();
        expect(traversal[0]).to.deep.equal([1, 2, 4, 6, 7, 10]);
        expect(traversal[1]).to.deep.equal([2, 4, 10, 10, 10, 10]);
      });

      it("should handle removing root node in the uint tree correctly", async () => {
        await avlTree.setUintDescComparator();

        await avlTree.insertUint(4, 2);
        await avlTree.insertUint(6, 3);
        await avlTree.insertUint(2, 22);
        await avlTree.insertUint(1, 12);
        await avlTree.insertUint(8, 4);

        expect(await avlTree.rootUint()).to.be.equal(4);

        await avlTree.removeUint(4);

        expect(await avlTree.rootUint()).to.be.equal(2);
        expect(await avlTree.sizeUint()).to.be.equal(4);

        const traversal = await avlTree.traverseUint();
        expect(traversal[0]).to.deep.equal([8, 6, 2, 1]);
        expect(traversal[1]).to.deep.equal([4, 3, 22, 12]);
      });

      it("should remove multiple nodes in the uint tree correctly", async () => {
        await avlTree.insertUint(1, 2);
        await avlTree.insertUint(4, 20);
        await avlTree.insertUint(3, 4);
        await avlTree.insertUint(7, 1);
        await avlTree.insertUint(8, 10);
        await avlTree.insertUint(9, 1);
        await avlTree.insertUint(5, 12);
        await avlTree.insertUint(6, 11);

        await avlTree.removeUint(8);
        await avlTree.removeUint(3);
        await avlTree.removeUint(5);

        expect(await avlTree.rootUint()).to.equal(6);
        expect(await avlTree.sizeUint()).to.equal(5);

        const traversal = await avlTree.traverseUint();
        expect(traversal[0]).to.deep.equal([1, 4, 6, 7, 9]);
        expect(traversal[1]).to.deep.equal([2, 20, 11, 1, 1]);
      });

      it("should handle removing all the nodes in the uint tree correctly", async () => {
        await avlTree.insertUint(2, 1);
        await avlTree.insertUint(4, 10);
        await avlTree.insertUint(3, 2);
        await avlTree.removeUint(4);
        await avlTree.removeUint(2);
        await avlTree.insertUint(2, 2);
        await avlTree.insertUint(1, 2);
        await avlTree.removeUint(2);
        await avlTree.removeUint(1);
        await avlTree.removeUint(3);

        expect(await avlTree.rootUint()).to.be.equal(0);
        expect(await avlTree.sizeUint()).to.be.equal(0);

        const traversal = await avlTree.traverseUint();
        expect(traversal[0].length).to.be.equal(0);
        expect(traversal[1].length).to.be.equal(0);
      });

      it("should not allow to remove a node that doesn't exist in the uint tree", async () => {
        await avlTree.insertUint(1, 10);

        await expect(avlTree.removeUint(2))
          .to.be.revertedWithCustomError(avlTree, "NodeDoesNotExist")
          .withArgs(toBeHex(2, 32));
        await expect(avlTree.removeUint(0)).to.be.revertedWithCustomError(avlTree, "KeyIsZero").withArgs();
      });

      it("should not allow to remove a node twice in the uint tree", async () => {
        const key = 2;
        await avlTree.insertUint(1, 10);
        await avlTree.insertUint(key, 20);

        await avlTree.removeUint(key);

        await expect(avlTree.removeUint(key))
          .to.be.revertedWithCustomError(avlTree, "NodeDoesNotExist")
          .withArgs(toBeHex(key, 32));
      });

      it("should not allow to remove nodes in the empty uint tree", async () => {
        await expect(avlTree.removeUint(1))
          .to.be.revertedWithCustomError(avlTree, "NodeDoesNotExist")
          .withArgs(toBeHex(1, 32));
      });
    });

    describe("setComparator", () => {
      it("should set a comparator for the uint tree correctly", async () => {
        await avlTree.setUintDescComparator();

        await avlTree.insertUint(2, 3);
        await avlTree.insertUint(4, 10);
        await avlTree.insertUint(1, 4);
        await avlTree.insertUint(6, 4);
        await avlTree.insertUint(3, 200);
        await avlTree.insertUint(5, 1);

        expect(await avlTree.rootUint()).to.equal(4);
        expect(await avlTree.sizeUint()).to.equal(6);

        const traversal = await avlTree.traverseUint();
        expect(traversal[0]).to.deep.equal([6, 5, 4, 3, 2, 1]);
        expect(traversal[1]).to.deep.equal([4, 1, 10, 200, 3, 4]);
      });

      it("should not allow to set comparator for the uint tree if the tree is not empty", async () => {
        await avlTree.insertUint(1, 10);

        await expect(avlTree.setUintDescComparator()).to.be.revertedWithCustomError(avlTree, "TreeNotEmpty").withArgs();
      });
    });

    describe("getters", () => {
      it("should get value for the existing node in the uint tree correctly", async () => {
        await avlTree.insertUint(1, 4);
        await avlTree.insertUint(2, 0);
        await avlTree.insertUint(3, 1);

        expect(await avlTree.getUint(1)).to.be.equal(4);
        expect(await avlTree.tryGetUint(1)).to.deep.equal([true, 4]);

        expect(await avlTree.getUint(2)).to.deep.equal(0);
        expect(await avlTree.tryGetUint(2)).to.deep.equal([true, 0]);

        expect(await avlTree.getUint(3)).to.be.equal(1);
        expect(await avlTree.tryGetUint(3)).to.deep.equal([true, 1]);

        await expect(avlTree.getUint(4))
          .to.be.revertedWithCustomError(avlTree, "NodeDoesNotExist")
          .withArgs(toBeHex(4, 32));
        expect(await avlTree.tryGetUint(4)).to.deep.equal([false, 0]);

        await expect(avlTree.getUint(6))
          .to.be.revertedWithCustomError(avlTree, "NodeDoesNotExist")
          .withArgs(toBeHex(6, 32));
        expect(await avlTree.tryGetUint(6)).to.deep.equal([false, 0]);
      });

      it("should handle getting value for the non-existing node in the uint tree correctly", async () => {
        await expect(avlTree.getUint(1))
          .to.be.revertedWithCustomError(avlTree, "NodeDoesNotExist")
          .withArgs(toBeHex(1, 32));
        expect(await avlTree.tryGetUint(1)).to.deep.equal([false, 0]);

        await avlTree.insertUint(1, 30);

        await expect(avlTree.getUint(2))
          .to.be.revertedWithCustomError(avlTree, "NodeDoesNotExist")
          .withArgs(toBeHex(2, 32));
        expect(await avlTree.tryGetUint(2)).to.deep.equal([false, 0]);

        await expect(avlTree.getUint(0))
          .to.be.revertedWithCustomError(avlTree, "NodeDoesNotExist")
          .withArgs(toBeHex(0, 32));
        expect(await avlTree.tryGetUint(0)).to.deep.equal([false, 0]);
      });

      it("should get the treeSize correctly for the uint tree", async () => {
        expect(await avlTree.sizeUint()).to.be.equal(0);

        await avlTree.insertUint(1, 10);
        await avlTree.insertUint(2, 10);
        await avlTree.removeUint(1);
        await avlTree.insertUint(3, 4);
        await avlTree.insertUint(7, 90);

        expect(await avlTree.sizeUint()).to.be.equal(3);
      });

      it("should check if custom comparator is set for the uint tree correctly", async () => {
        expect(await avlTree.isCustomComparatorSetUint()).to.be.false;

        await avlTree.setUintDescComparator();

        expect(await avlTree.isCustomComparatorSetUint()).to.be.true;
      });

      it("should traverse the uint tree correctly", async () => {
        await avlTree.insertUint(2, 10);
        await avlTree.insertUint(4, 11);
        await avlTree.insertUint(1, 12);
        await avlTree.insertUint(6, 13);
        await avlTree.insertUint(7, 14);

        let fullTraversal = await avlTree.traverseUint();
        expect(fullTraversal[0]).to.deep.equal([1, 2, 4, 6, 7]);
        expect(fullTraversal[1]).to.deep.equal([12, 10, 11, 13, 14]);

        let backwardsTraversal = await avlTree.backwardsTraversalUint();
        expect(backwardsTraversal[0]).to.deep.equal([7, 6, 4, 2, 1]);
        expect(backwardsTraversal[1]).to.deep.equal([14, 13, 11, 10, 12]);

        expect(await avlTree.nextOnLast()).to.deep.equal([0, 0]);
        expect(await avlTree.prevOnFirst()).to.deep.equal([0, 0]);

        await expect(avlTree.brokenTraversalUint()).to.be.revertedWithCustomError(avlTree, "NoNodesLeft").withArgs();
      });

      it("should maintain idempotent traversal", async () => {
        await avlTree.insertUint(1, 12);
        await avlTree.insertUint(6, 22);
        await avlTree.insertUint(3, 10);

        await avlTree.removeUint(1);

        await avlTree.insertUint(2, 0);

        await avlTree.removeUint(3);

        await avlTree.insertUint(5, 5);
        await avlTree.insertUint(1, 15);
        await avlTree.insertUint(3, 1000);
        await avlTree.insertUint(4, 44);

        const traversal = await avlTree.backAndForthTraverseUint();
        expect(traversal[0]).to.deep.equal([1, 2, 3, 2, 3, 2, 1, 2, 3, 4, 5, 6]);
        expect(traversal[1]).to.deep.equal([15, 0, 1000, 0, 1000, 0, 15, 0, 1000, 44, 5, 22]);
      });
    });
  });

  describe("Bytes32 Tree", () => {
    it("should insert nodes to the bytes32 tree correctly", async () => {
      await avlTree.setBytes32DescComparator();

      await avlTree.insertBytes32(2, encodeBytes32String("20"));
      await avlTree.insertBytes32(4, encodeBytes32String("22"));
      await avlTree.insertBytes32(1, encodeBytes32String("12"));
      await avlTree.insertBytes32(6, encodeBytes32String("2"));
      await avlTree.insertBytes32(3, encodeBytes32String("112"));
      await avlTree.insertBytes32(5, encodeBytes32String("2"));

      expect(await avlTree.rootBytes32()).to.equal(4);
      expect(await avlTree.getBytes32(4)).to.be.equal(encodeBytes32String("22"));
      expect(await avlTree.tryGetBytes32(4)).to.deep.equal([true, encodeBytes32String("22")]);

      expect(await avlTree.sizeBytes32()).to.equal(6);

      let fullTraversal = await avlTree.traverseBytes32();
      expect(fullTraversal[0]).to.deep.equal([6, 5, 4, 3, 2, 1]);
      expect(fullTraversal[1]).to.deep.equal(uintToBytes32Array([2, 2, 22, 112, 20, 12]));

      let backwardsTraversal = await avlTree.backwardsTraversalBytes32();
      expect(backwardsTraversal[0]).to.deep.equal([1, 2, 3, 4, 5, 6]);
      expect(backwardsTraversal[1]).to.deep.equal(uintToBytes32Array([12, 20, 112, 22, 2, 2]));
    });

    it("should remove nodes in the bytes32 tree correctly", async () => {
      await avlTree.insertBytes32(2, encodeBytes32String("2"));
      await avlTree.insertBytes32(1, encodeBytes32String("1"));
      await avlTree.insertBytes32(5, encodeBytes32String("5"));
      await avlTree.insertBytes32(4, encodeBytes32String("6"));

      await avlTree.removeBytes32(2);

      expect(await avlTree.rootBytes32()).to.equal(4);

      expect(await avlTree.sizeBytes32()).to.equal(3);
      await expect(avlTree.getBytes32(2))
        .to.be.revertedWithCustomError(avlTree, "NodeDoesNotExist")
        .withArgs(toBeHex(2, 32));
      expect(await avlTree.tryGetBytes32(2)).to.deep.equal([false, 0]);

      let traversal = await avlTree.traverseBytes32();
      expect(traversal[0]).to.deep.equal([1, 4, 5]);
      expect(traversal[1]).to.deep.equal(uintToBytes32Array([1, 6, 5]));

      await avlTree.insertBytes32(3, encodeBytes32String("3"));
      await avlTree.insertBytes32(6, encodeBytes32String("4"));
      await avlTree.insertBytes32(2, encodeBytes32String("2"));

      await avlTree.removeBytes32(1);
      await avlTree.removeBytes32(3);

      expect(await avlTree.rootBytes32()).to.equal(4);
      expect(await avlTree.sizeBytes32()).to.equal(4);

      expect(await avlTree.getBytes32(2)).to.be.equal(encodeBytes32String("2"));
      expect(await avlTree.tryGetBytes32(2)).to.deep.equal([true, encodeBytes32String("2")]);

      await expect(avlTree.getBytes32(1))
        .to.be.revertedWithCustomError(avlTree, "NodeDoesNotExist")
        .withArgs(toBeHex(1, 32));
      expect(await avlTree.tryGetBytes32(1)).to.deep.equal([false, encodeBytes32String("")]);

      await expect(avlTree.getBytes32(3))
        .to.be.revertedWithCustomError(avlTree, "NodeDoesNotExist")
        .withArgs(toBeHex(3, 32));
      expect(await avlTree.tryGetBytes32(3)).to.deep.equal([false, encodeBytes32String("")]);

      traversal = await avlTree.traverseBytes32();
      expect(traversal[0]).to.deep.equal([2, 4, 5, 6]);
      expect(traversal[1]).to.deep.equal(uintToBytes32Array([2, 6, 5, 4]));

      await avlTree.removeBytes32(2);
      await avlTree.removeBytes32(5);
      await avlTree.removeBytes32(6);
      await avlTree.removeBytes32(4);

      expect(await avlTree.rootBytes32()).to.equal(0);
      expect(await avlTree.sizeBytes32()).to.equal(encodeBytes32String(""));
    });

    it("should handle getting value in the bytes32 tree correctly", async () => {
      await expect(avlTree.getBytes32(1))
        .to.be.revertedWithCustomError(avlTree, "NodeDoesNotExist")
        .withArgs(toBeHex(1, 32));
      expect(await avlTree.tryGetBytes32(1)).to.deep.equal([false, encodeBytes32String("")]);

      await avlTree.insertBytes32(1, encodeBytes32String(""));
      await avlTree.insertBytes32(2, encodeBytes32String("2"));

      expect(await avlTree.getBytes32(1)).to.be.equal(encodeBytes32String(""));
      expect(await avlTree.tryGetBytes32(1)).to.deep.equal([true, encodeBytes32String("")]);

      expect(await avlTree.getBytes32(2)).to.be.equal(encodeBytes32String("2"));
      expect(await avlTree.tryGetBytes32(2)).to.deep.equal([true, encodeBytes32String("2")]);

      await expect(avlTree.getBytes32(3))
        .to.be.revertedWithCustomError(avlTree, "NodeDoesNotExist")
        .withArgs(toBeHex(3, 32));
      expect(await avlTree.tryGetBytes32(3)).to.deep.equal([false, encodeBytes32String("")]);

      await expect(avlTree.getBytes32(0))
        .to.be.revertedWithCustomError(avlTree, "NodeDoesNotExist")
        .withArgs(toBeHex(0, 32));
      expect(await avlTree.tryGetBytes32(0)).to.deep.equal([false, encodeBytes32String("")]);
    });

    it("should check if custom comparator is set for the bytes32 tree correctly", async () => {
      expect(await avlTree.isCustomComparatorSetBytes32()).to.be.false;

      await avlTree.setBytes32DescComparator();

      expect(await avlTree.isCustomComparatorSetBytes32()).to.be.true;
    });
  });

  describe("Address Tree", () => {
    it("should insert nodes to the address tree correctly", async () => {
      await avlTree.insertAddress(6, USER1);
      await avlTree.insertAddress(4, USER2);
      await avlTree.insertAddress(5, USER1);
      await avlTree.insertAddress(3, USER4);
      await avlTree.insertAddress(2, USER3);

      expect(await avlTree.rootAddress()).to.equal(5);
      expect(await avlTree.getAddressValue(5)).to.be.equal(USER1);
      expect(await avlTree.tryGetAddress(5)).to.deep.equal([true, USER1.address]);

      expect(await avlTree.sizeAddress()).to.equal(5);

      let traversal = await avlTree.traverseAddress();
      expect(traversal[0]).to.deep.equal([2, 3, 4, 5, 6]);
      expect(traversal[1]).to.deep.equal([USER3.address, USER4.address, USER2.address, USER1.address, USER1.address]);

      await avlTree.insertAddress(1, USER3);

      expect(await avlTree.rootAddress()).to.equal(3);
      expect(await avlTree.getAddressValue(3)).to.be.equal(USER4);
      expect(await avlTree.tryGetAddress(3)).to.deep.equal([true, USER4.address]);

      expect(await avlTree.sizeAddress()).to.equal(6);

      traversal = await avlTree.traverseAddress();
      expect(traversal[0]).to.deep.equal([1, 2, 3, 4, 5, 6]);
      expect(traversal[1]).to.deep.equal([
        USER3.address,
        USER3.address,
        USER4.address,
        USER2.address,
        USER1.address,
        USER1.address,
      ]);

      const backwardsTraversal = await avlTree.backwardsTraversalAddress();
      expect(backwardsTraversal[0]).to.deep.equal([6, 5, 4, 3, 2, 1]);
      expect(backwardsTraversal[1]).to.deep.equal([
        USER1.address,
        USER1.address,
        USER2.address,
        USER4.address,
        USER3.address,
        USER3.address,
      ]);
    });

    it("should remove nodes in the address tree correctly", async () => {
      await avlTree.setAddressDescComparator();

      await avlTree.insertAddress(2, USER2);
      await avlTree.insertAddress(1, USER2);
      await avlTree.insertAddress(5, USER3);
      await avlTree.insertAddress(6, USER1);

      await avlTree.removeAddress(2);

      expect(await avlTree.rootAddress()).to.equal(5);
      expect(await avlTree.sizeAddress()).to.equal(3);

      await expect(avlTree.getAddressValue(2))
        .to.be.revertedWithCustomError(avlTree, "NodeDoesNotExist")
        .withArgs(toBeHex(2, 32));
      expect(await avlTree.tryGetAddress(2)).to.deep.equal([false, ethers.ZeroAddress]);

      let traversal = await avlTree.traverseAddress();
      expect(traversal[0]).to.deep.equal([6, 5, 1]);
      expect(traversal[1]).to.deep.equal([USER1.address, USER3.address, USER2.address]);

      await avlTree.insertAddress(3, USER2);
      await avlTree.insertAddress(4, USER4);
      await avlTree.insertAddress(2, USER3);

      await avlTree.removeAddress(2);
      await avlTree.insertAddress(2, USER2);

      await avlTree.removeAddress(3);
      await avlTree.removeAddress(5);

      expect(await avlTree.rootAddress()).to.equal(2);
      expect(await avlTree.sizeAddress()).to.equal(4);

      expect(await avlTree.getAddressValue(1)).to.be.equal(USER2);
      expect(await avlTree.tryGetAddress(1)).to.deep.equal([true, USER2.address]);

      await expect(avlTree.getAddressValue(3))
        .to.be.revertedWithCustomError(avlTree, "NodeDoesNotExist")
        .withArgs(toBeHex(3, 32));
      expect(await avlTree.tryGetAddress(3)).to.deep.equal([false, 0]);

      await expect(avlTree.getAddressValue(5))
        .to.be.revertedWithCustomError(avlTree, "NodeDoesNotExist")
        .withArgs(toBeHex(5, 32));
      expect(await avlTree.tryGetAddress(5)).to.deep.equal([false, ethers.ZeroAddress]);

      traversal = await avlTree.traverseAddress();
      expect(traversal[0]).to.deep.equal([6, 4, 2, 1]);
      expect(traversal[1]).to.deep.equal([USER1.address, USER4.address, USER2.address, USER2.address]);

      await avlTree.removeAddress(2);
      await avlTree.removeAddress(6);
      await avlTree.removeAddress(4);
      await avlTree.removeAddress(1);

      expect(await avlTree.rootAddress()).to.equal(0);
      expect(await avlTree.sizeAddress()).to.equal(0);

      traversal = await avlTree.traverseAddress();
      expect(traversal[0].length).to.be.equal(0);
      expect(traversal[1].length).to.be.equal(0);
    });

    it("should handle getting value in the address tree correctly", async () => {
      await expect(avlTree.getAddressValue(1))
        .to.be.revertedWithCustomError(avlTree, "NodeDoesNotExist")
        .withArgs(toBeHex(1, 32));
      expect(await avlTree.tryGetAddress(1)).to.deep.equal([false, ethers.ZeroAddress]);

      await avlTree.insertAddress(1, USER2);
      await avlTree.insertAddress(2, ethers.ZeroAddress);

      expect(await avlTree.getAddressValue(1)).to.be.equal(USER2);
      expect(await avlTree.tryGetAddress(1)).to.deep.equal([true, USER2.address]);

      expect(await avlTree.getAddressValue(2)).to.be.equal(ethers.ZeroAddress);
      expect(await avlTree.tryGetAddress(2)).to.deep.equal([true, ethers.ZeroAddress]);

      await expect(avlTree.getAddressValue(5))
        .to.be.revertedWithCustomError(avlTree, "NodeDoesNotExist")
        .withArgs(toBeHex(5, 32));
      expect(await avlTree.tryGetAddress(5)).to.deep.equal([false, ethers.ZeroAddress]);

      await expect(avlTree.getAddressValue(0))
        .to.be.revertedWithCustomError(avlTree, "NodeDoesNotExist")
        .withArgs(toBeHex(0, 32));
      expect(await avlTree.tryGetAddress(0)).to.deep.equal([false, ethers.ZeroAddress]);
    });

    it("should check if custom comparator is set for the address tree correctly", async () => {
      expect(await avlTree.isCustomComparatorSetAddress()).to.be.false;

      await avlTree.setAddressDescComparator();

      expect(await avlTree.isCustomComparatorSetAddress()).to.be.true;
    });
  });
});
