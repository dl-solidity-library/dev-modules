import { ethers } from "hardhat";
import { expect } from "chai";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { MerkleTree } from "merkletreejs";

import { Reverter } from "@/test/helpers/reverter";
import { getRoot, getProof, buildTree } from "../helpers/merkle-tree-helper";

import { MerkleWhitelistedMock } from "@ethers-v6";

describe("MerkleWhitelisted", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;

  let merkle: MerkleWhitelistedMock;
  let leaves: any;
  let tree: MerkleTree;
  let users: SignerWithAddress[];

  async function buildMerkleTree() {
    tree = buildTree(leaves);

    await merkle.setMerkleRoot(getRoot(tree));
  }

  async function addToWhitelist(leaf: any) {
    leaves.push(leaf);

    await buildMerkleTree();
  }

  function buildAmountLeaf(user: any, amount: number) {
    return ethers.solidityPacked(["uint256", "address"], [amount, user]);
  }

  before(async () => {
    [OWNER, ...users] = await ethers.getSigners();

    const MerkleWhitelistedMock = await ethers.getContractFactory("MerkleWhitelistedMock");
    merkle = await MerkleWhitelistedMock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("getMerkleRoot, _setMerkleRoot", () => {
    beforeEach(async () => {
      leaves = [];

      await buildMerkleTree();
    });

    it("should be zero if root is not set yet", async () => {
      expect(await merkle.getMerkleRoot()).to.equal(ethers.ZeroHash);
    });

    it("should change merkle tree root properly", async () => {
      await addToWhitelist(users[0].address);

      const root1 = getRoot(tree);

      expect(await merkle.getMerkleRoot()).to.equal(root1);

      await addToWhitelist(users[1].address);

      const root2 = getRoot(tree);

      expect(await merkle.getMerkleRoot()).to.equal(root2);
      expect(root1).to.not.equal(root2);
    });
  });

  describe("onlyWhitelisted", () => {
    const amounts = [100, 500, 200, 1, 3000];

    beforeEach(async () => {
      leaves = amounts.map((e, index) => buildAmountLeaf(users[index].address, e));

      await buildMerkleTree();
    });

    it("should revert if the user is incorrect", async () => {
      const data = ethers.solidityPacked(["uint256", "address"], [amounts[0], users[1].address]);

      await expect(merkle.connect(users[1]).onlyWhitelistedMethod(amounts[0], getProof(tree, leaves[0])))
        .to.be.revertedWithCustomError(merkle, "LeafNotWhitelisted")
        .withArgs(data);
    });

    it("should revert if the amount is incorrect", async () => {
      const data = ethers.solidityPacked(["uint256", "address"], [amounts[1], users[0].address]);

      await expect(merkle.connect(users[0]).onlyWhitelistedMethod(amounts[1], getProof(tree, leaves[0])))
        .to.be.revertedWithCustomError(merkle, "LeafNotWhitelisted")
        .withArgs(data);
    });

    it("should revert if the proof is incorrect", async () => {
      const data = ethers.solidityPacked(["uint256", "address"], [amounts[0], users[0].address]);

      await expect(merkle.connect(users[0]).onlyWhitelistedMethod(amounts[0], getProof(tree, leaves[1])))
        .to.be.revertedWithCustomError(merkle, "LeafNotWhitelisted")
        .withArgs(data);
    });

    it("should not revert if all conditions are met", async () => {
      for (let i = 0; i < 5; i++) {
        expect(await merkle.connect(users[i]).onlyWhitelistedMethod(amounts[i], getProof(tree, leaves[i]))).to.emit(
          merkle,
          "WhitelistedData",
        );
      }
    });
  });

  describe("onlyWhitelistedUser", () => {
    beforeEach(async () => {
      leaves = users.map((e) => e.address);

      await buildMerkleTree();
    });

    it("should revert if the user is incorrect", async () => {
      await expect(merkle.onlyWhitelistedUserMethod(getProof(tree, leaves[0])))
        .to.be.revertedWithCustomError(merkle, "UserNotWhitelisted")
        .withArgs(OWNER.address);
    });

    it("should revert if the proof is incorrect", async () => {
      await expect(merkle.connect(users[0]).onlyWhitelistedUserMethod(getProof(tree, leaves[1])))
        .to.be.revertedWithCustomError(merkle, "UserNotWhitelisted")
        .withArgs(users[0].address);
    });

    it("should not revert if all conditions are met", async () => {
      for (let i = 0; i < 5; i++) {
        expect(await merkle.connect(users[i]).onlyWhitelistedUserMethod(getProof(tree, leaves[i]))).to.emit(
          merkle,
          "WhitelistedUser",
        );
      }
    });
  });
});
