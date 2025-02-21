import { expect } from "chai";
import { ethers } from "hardhat";
import { BytesLike } from "ethers";

import { CartesianMerkleTreeMock } from "@ethers-v6";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";
import { getPoseidon, poseidonHash } from "@/test/helpers/poseidon-hash";

import { CartesianMerkleTree } from "@ethers-v6/contracts/mock/libs/data-structures/CartesianMerkleTreeMock";

describe("CartesianMerkleTree", () => {
  const reverter = new Reverter();

  let USER1: SignerWithAddress;

  let treaple: CartesianMerkleTreeMock;

  function createRandomArray(length: number, bytesCount: number = 32): string[] {
    const resultArr: string[] = [];

    for (let i = 0; i < length; i++) {
      resultArr.push(ethers.hexlify(ethers.randomBytes(bytesCount)));
    }

    return resultArr;
  }

  function parseNumberToBitsArray(num: bigint, expectedLength: bigint): number[] {
    const binary = num.toString(2);
    const resultArr: number[] = [];

    if (expectedLength < BigInt(binary.length)) {
      throw Error("Wrong expected length");
    }

    for (let i = 0; i < expectedLength - BigInt(binary.length); i++) {
      resultArr.push(0);
    }

    for (let i = 0; i < binary.length; i++) {
      resultArr.push(Number(binary[i]));
    }

    return resultArr;
  }

  async function verifyCMTProof(
    proof: CartesianMerkleTree.ProofStruct,
    expectedRoot: string,
    keyToVerify: string,
    expectedExistence: boolean = true,
    isPoseidonHash: boolean = false,
  ) {
    expect(proof.existence).to.be.eq(expectedExistence);

    keyToVerify = `0x${keyToVerify.slice(2).padStart(64, "0")}`;

    keyToVerify = proof.existence ? keyToVerify.toString() : proof.nonExistenceKey.toString();

    let currentSiblingsIndex: number = Number(proof.siblingsLength);
    let finalHash: string = "";
    let directionBits = Array(currentSiblingsIndex / 2).fill(0);

    while (true) {
      let valuesToHash: string[] = [];
      let currentSiblings: BytesLike[] = proof.siblings.slice(currentSiblingsIndex - 2, currentSiblingsIndex);

      if (currentSiblingsIndex === Number(proof.siblingsLength)) {
        if (BigInt(ethers.hexlify(currentSiblings[0])) > BigInt(ethers.hexlify(currentSiblings[1]))) {
          currentSiblings = [currentSiblings[1], currentSiblings[0]];

          directionBits[currentSiblingsIndex / 2 - 1] = 1;
        }

        valuesToHash = [keyToVerify, ethers.hexlify(currentSiblings[0]), ethers.hexlify(currentSiblings[1])];
      } else {
        let sortedChildren: string[] = [finalHash, ethers.hexlify(currentSiblings[1])];

        if (BigInt(sortedChildren[0]) > BigInt(sortedChildren[1])) {
          sortedChildren = [sortedChildren[1], sortedChildren[0]];

          directionBits[currentSiblingsIndex / 2 - 1] = 1;
        }

        valuesToHash = [currentSiblings[0].toString(), sortedChildren[0], sortedChildren[1]];
      }

      let nodeHash: string = "";

      if (isPoseidonHash) {
        nodeHash = await treaple.hash3(valuesToHash[0], valuesToHash[1], valuesToHash[2]);
      } else {
        nodeHash = ethers.solidityPackedKeccak256(["bytes32", "bytes32", "bytes32"], valuesToHash);
      }

      finalHash = nodeHash;
      currentSiblingsIndex -= 2;

      if (currentSiblingsIndex <= 0) {
        break;
      }
    }

    const expectedDirBitsArray = parseNumberToBitsArray(proof.directionBits, proof.siblingsLength / 2n);

    expect(expectedDirBitsArray).to.be.deep.eq(directionBits);
    expect(expectedRoot).to.be.eq(finalHash);
  }

  function shuffle(array: any): any {
    let currentIndex = array.length;

    while (currentIndex != 0) {
      let randomIndex = Math.floor(Math.random() * currentIndex);
      currentIndex--;

      [array[currentIndex], array[randomIndex]] = [array[randomIndex], array[currentIndex]];
    }
  }

  before("setup", async () => {
    [USER1] = await ethers.getSigners();

    const CartesianMerkleTreeMock = await ethers.getContractFactory("CartesianMerkleTreeMock", {
      libraries: {
        PoseidonUnit3L: await (await getPoseidon(3)).getAddress(),
      },
    });

    treaple = await CartesianMerkleTreeMock.deploy();

    await reverter.snapshot();
  });

  afterEach("cleanup", async () => {
    await reverter.revert();
  });

  describe("Uint CMT", () => {
    beforeEach("setup", async () => {
      await treaple.initializeUintTreaple(40);
      await treaple.setUintPoseidonHasher();
    });

    it("should not initialize twice", async () => {
      await expect(treaple.initializeUintTreaple(20))
        .to.be.revertedWithCustomError(treaple, "TreapleAlreadyInitialized")
        .withArgs();
    });

    it("should revert if trying to set incorrect desired proof size", async () => {
      await expect(treaple.setDesiredProofSizeUintTreaple(0))
        .to.be.revertedWithCustomError(treaple, "ZeroDesiredProofSize")
        .withArgs();
    });

    it("should correctly set new desired proof size", async () => {
      await treaple.setDesiredProofSizeUintTreaple(20);

      expect(await treaple.getUintDesiredProofSize()).to.equal(20);
    });

    it("should revert if trying to call add/remove functions on non-initialized treaple", async () => {
      const CartesianMerkleTreeMock = await ethers.getContractFactory("CartesianMerkleTreeMock", {
        libraries: {
          PoseidonUnit3L: await (await getPoseidon(3)).getAddress(),
        },
      });
      const newTreap = await CartesianMerkleTreeMock.deploy();

      await expect(newTreap.addUint(13n)).to.be.revertedWithCustomError(treaple, "TreapleNotInitialized").withArgs();
      await expect(newTreap.removeUint(13n)).to.be.revertedWithCustomError(treaple, "TreapleNotInitialized").withArgs();
    });

    it("should add and full remove elements from the CMT correctly", async () => {
      const keysCount: number = 20;
      const keys: string[] = createRandomArray(keysCount);

      for (let i = 0; i < keysCount; i++) {
        await treaple.addUint(keys[i]);
      }

      shuffle(keys);

      for (let i = 0; i < keysCount; i++) {
        await treaple.removeUint(keys[i]);
      }

      expect(await treaple.getUintRoot()).to.equal(ethers.ZeroHash);

      expect(await treaple.getUintNodesCount()).to.equal(0);

      expect(await treaple.isUintCustomHasherSet()).to.be.true;
      expect(treaple.setUintPoseidonHasher()).to.not.be.rejected;
    });

    it("should maintain deterministic property", async () => {
      const keysCount: number = 100;
      const keys: string[] = createRandomArray(keysCount);

      const CartesianMerkleTreeMock = await ethers.getContractFactory("CartesianMerkleTreeMock", {
        libraries: {
          PoseidonUnit3L: await (await getPoseidon(3)).getAddress(),
        },
      });

      let treapleRoot: string = "";

      for (let i = 0; i < 5; i++) {
        const tmpTreaple = await CartesianMerkleTreeMock.deploy();
        await tmpTreaple.initializeUintTreaple(40);

        for (let i = 0; i < keysCount; i++) {
          await tmpTreaple.addUint(keys[i]);
        }

        if (i == 0) {
          treapleRoot = await tmpTreaple.getUintRoot();
        }

        expect(treapleRoot).to.be.eq(await tmpTreaple.getUintRoot());

        shuffle(keys);
      }
    });

    it("should maintain idempotence", async () => {
      const keysCount: number = 30;
      const keys: string[] = createRandomArray(keysCount);

      for (let i = 0; i < keysCount; i++) {
        await treaple.addUint(keys[i]);
      }

      const treapleRoot: string = await treaple.getUintRoot();
      const usedIndexes: number[] = [];

      for (let i = 0; i < 10; i++) {
        let randIndex: number = -1;

        while (true) {
          const newRandIndex =
            Math.floor(Math.random() * (Number(await treaple.getUintNodesCount()) + usedIndexes.length - 1)) + 1;

          if (!usedIndexes.includes(newRandIndex)) {
            randIndex = newRandIndex;
            usedIndexes.push(newRandIndex);

            break;
          }
        }

        let currentNode = await treaple.getUintNode(randIndex);

        await treaple.removeUint(currentNode.key);

        expect(await treaple.getUintRoot()).to.be.not.eq(treapleRoot);

        await treaple.addUint(currentNode.key);

        expect(await treaple.getUintRoot()).to.be.eq(treapleRoot);
      }
    });

    it("should not remove non-existent leaves", async () => {
      const keys = [7n, 1n, 5n];

      for (let key of keys) {
        const hexKey = ethers.toBeHex(key, 32);

        await treaple.addUint(hexKey);
      }

      await expect(treaple.removeUint(ethers.toBeHex(8, 32)))
        .to.be.revertedWithCustomError(treaple, "NodeDoesNotExist")
        .withArgs();
    });

    it("should generate empty proof on empty tree", async () => {
      const desiredProofSize = 20;
      const proof = await treaple.getUintProof(ethers.toBeHex(1n, 32), desiredProofSize);

      expect(proof.siblingsLength).to.be.eq(0);
      expect(proof.siblings).to.be.deep.eq(new Array(desiredProofSize).fill(0));
      expect(proof.directionBits).to.be.eq(0);
      expect(proof.existence).to.be.false;
    });

    it("should generate correct proof for the existing nodes", async () => {
      const keysCount: number = 50;
      const keys: string[] = createRandomArray(keysCount);

      for (let i = 0; i < keys.length; i++) {
        await treaple.addUint(keys[i]);
      }

      const treapleRoot: string = await treaple.getUintRoot();

      for (let i = 0; i < keysCount; i++) {
        const randIndex = Math.floor(Math.random() * (Number(await treaple.getUintNodesCount()) - 1)) + 1;
        const proof = await treaple.getUintProof(keys[randIndex], 40);

        await verifyCMTProof(proof, treapleRoot, keys[randIndex], true, true);
      }
    });

    it("should generate correct proof for the non-existing nodes", async () => {
      const keysCount: number = 50;
      const keys: string[] = createRandomArray(keysCount);

      for (let i = 0; i < keys.length; i++) {
        await treaple.addUint(keys[i]);
      }

      const desiredProofSize = 50;

      await treaple.setDesiredProofSizeUintTreaple(desiredProofSize);

      const treapleRoot: string = await treaple.getUintRoot();

      for (let i = 0; i < keysCount; i++) {
        const randKey = ethers.hexlify(ethers.randomBytes(32));
        const proof = await treaple.getUintProof(randKey, 0);

        expect(proof.siblings.length).to.be.eq(desiredProofSize);

        await verifyCMTProof(proof, treapleRoot, randKey, false, true);
      }
    });

    it("should revert if trying to add/remove zero key", async () => {
      const customError = "ZeroKeyProvided";

      await expect(treaple.addUint(ethers.ZeroHash)).to.be.revertedWithCustomError(treaple, customError).withArgs();
      await expect(treaple.removeUint(ethers.ZeroHash)).to.be.revertedWithCustomError(treaple, customError).withArgs();
    });

    it("should revert if trying to set hasher with non-empty treaple", async () => {
      const key = poseidonHash(ethers.toBeHex(2341n));

      await treaple.addUint(key);

      await expect(treaple.setUintPoseidonHasher())
        .to.be.revertedWithCustomError(treaple, "TreapleNotEmpty")
        .withArgs();
    });

    it("should revert if trying to add a node with the same key", async () => {
      const key = poseidonHash(ethers.toBeHex(2341n));

      await treaple.addUint(key);

      await expect(treaple.addUint(key)).to.be.revertedWithCustomError(treaple, "KeyAlreadyExists").withArgs();
    });

    it("should get empty Node by non-existing key", async () => {
      expect((await treaple.getUintNodeByKey(1n)).key).to.be.equal(ethers.ZeroHash);

      await treaple.addUint(ethers.toBeHex(7n, 32));

      expect((await treaple.getUintNodeByKey(5n)).key).to.be.equal(ethers.ZeroHash);
    });

    it("should get exception if desired size is too low", async () => {
      const keysCount: number = 50;
      const keys: string[] = createRandomArray(keysCount);

      for (let i = 0; i < keys.length; i++) {
        await treaple.addUint(keys[i]);
      }

      await expect(treaple.getUintProof(keys[0], 1))
        .to.be.revertedWithCustomError(treaple, "ProofSizeTooLow")
        .withArgs(1, 1);
    });
  });

  describe("Bytes32 CMT", () => {
    beforeEach("setup", async () => {
      await treaple.initializeBytes32Treaple(15);
      await treaple.setBytes32PoseidonHasher();
    });

    it("should not initialize twice", async () => {
      await expect(treaple.initializeBytes32Treaple(20))
        .to.be.revertedWithCustomError(treaple, "TreapleAlreadyInitialized")
        .withArgs();
    });

    it("should correctly set new desired proof size", async () => {
      await treaple.setDesiredProofSizeBytes32Treaple(20);

      expect(await treaple.getBytes32DesiredProofSize()).to.equal(20);
    });

    it("should build a Cartesian Merkle Tree correctly with multiple elements", async () => {
      for (let i = 1n; i < 20n; i++) {
        const key = poseidonHash(ethers.toBeHex(ethers.hexlify(ethers.randomBytes(28)), 32));

        await treaple.addBytes32(key);

        expect((await treaple.getBytes32NodeByKey(key)).key).to.be.eq(BigInt(key));

        const proof = await treaple.getBytes32Proof(key, 35);
        await verifyCMTProof(proof, await treaple.getBytes32Root(), key, true, true);
      }

      expect(await treaple.isBytes32CustomHasherSet()).to.be.true;
    });

    it("should maintain deterministic property", async () => {
      const keysCount: number = 100;
      const keys: string[] = createRandomArray(keysCount);

      const CartesianMerkleTreeMock = await ethers.getContractFactory("CartesianMerkleTreeMock", {
        libraries: {
          PoseidonUnit3L: await (await getPoseidon(3)).getAddress(),
        },
      });

      let treapleRoot: string = "";

      for (let i = 0; i < 5; i++) {
        const tmpTreaple = await CartesianMerkleTreeMock.deploy();
        await tmpTreaple.initializeBytes32Treaple(40);

        for (let i = 0; i < keysCount; i++) {
          await tmpTreaple.addBytes32(keys[i]);
        }

        if (i == 0) {
          treapleRoot = await tmpTreaple.getBytes32Root();
        }

        expect(treapleRoot).to.be.eq(await tmpTreaple.getBytes32Root());

        shuffle(keys);
      }
    });

    it("should maintain idempotence", async () => {
      const keysCount: number = 30;
      const keys: string[] = createRandomArray(keysCount);

      for (let i = 0; i < keysCount; i++) {
        await treaple.addBytes32(keys[i]);
      }

      const treapleRoot: string = await treaple.getBytes32Root();
      const usedIndexes: number[] = [];

      for (let i = 0; i < 10; i++) {
        let randIndex: number = -1;

        while (true) {
          const newRandIndex =
            Math.floor(Math.random() * (Number(await treaple.getBytes32NodesCount()) + usedIndexes.length - 1)) + 1;

          if (!usedIndexes.includes(newRandIndex)) {
            randIndex = newRandIndex;
            usedIndexes.push(newRandIndex);

            break;
          }
        }

        let currentNode = await treaple.getBytes32Node(randIndex);

        await treaple.removeBytes32(currentNode.key);

        expect(await treaple.getBytes32Root()).to.be.not.eq(treapleRoot);

        await treaple.addBytes32(currentNode.key);

        expect(await treaple.getBytes32Root()).to.be.eq(treapleRoot);
      }
    });

    it("should generate correct proof for the existing nodes", async () => {
      const keysCount: number = 50;
      const keys: string[] = createRandomArray(keysCount);

      for (let i = 0; i < keys.length; i++) {
        await treaple.addBytes32(keys[i]);
      }

      const treapleRoot: string = await treaple.getBytes32Root();

      for (let i = 0; i < keysCount; i++) {
        const randIndex = Math.floor(Math.random() * (Number(await treaple.getBytes32NodesCount()) - 1)) + 1;
        const proof = await treaple.getBytes32Proof(keys[randIndex], 40);

        await verifyCMTProof(proof, treapleRoot, keys[randIndex], true, true);
      }
    });
  });

  describe("Address CMT", () => {
    beforeEach("setup", async () => {
      await treaple.initializeAddressTreaple(15);
      await treaple.setAddressPoseidonHasher();
    });

    it("should not initialize twice", async () => {
      await expect(treaple.initializeAddressTreaple(20))
        .to.be.revertedWithCustomError(treaple, "TreapleAlreadyInitialized")
        .withArgs();
    });

    it("should correctly set new desired proof size", async () => {
      await treaple.setDesiredProofSizeAddressTreaple(20);

      expect(await treaple.getAddressDesiredProofSize()).to.equal(20);
    });

    it("should build a Cartesian Merkle Tree correctly with multiple elements", async () => {
      for (let i = 1n; i < 20n; i++) {
        const key = ethers.toBeHex(BigInt(await USER1.getAddress()) + i);

        await treaple.addAddress(key);

        expect((await treaple.getAddressNodeByKey(key)).key).to.be.eq(BigInt(key));

        const proof = await treaple.getAddressProof(key, 35);
        await verifyCMTProof(proof, await treaple.getAddressRoot(), key, true, true);
      }

      expect(await treaple.isAddressCustomHasherSet()).to.be.true;
    });

    it("should maintain deterministic property", async () => {
      const keysCount: number = 100;
      const keys: string[] = createRandomArray(keysCount, 20);

      const CartesianMerkleTreeMock = await ethers.getContractFactory("CartesianMerkleTreeMock", {
        libraries: {
          PoseidonUnit3L: await (await getPoseidon(3)).getAddress(),
        },
      });

      let treapleRoot: string = "";

      for (let i = 0; i < 5; i++) {
        const tmpTreaple = await CartesianMerkleTreeMock.deploy();
        await tmpTreaple.initializeAddressTreaple(40);

        for (let i = 0; i < keysCount; i++) {
          await tmpTreaple.addAddress(keys[i]);
        }

        if (i == 0) {
          treapleRoot = await tmpTreaple.getAddressRoot();
        }

        expect(treapleRoot).to.be.eq(await tmpTreaple.getAddressRoot());

        shuffle(keys);
      }
    });

    it("should maintain idempotence", async () => {
      const keysCount: number = 30;
      const keys: string[] = createRandomArray(keysCount, 20);

      for (let i = 0; i < keysCount; i++) {
        await treaple.addAddress(keys[i]);
      }

      const treapleRoot: string = await treaple.getAddressRoot();
      const usedIndexes: number[] = [];

      for (let i = 0; i < 10; i++) {
        let randIndex: number = -1;

        while (true) {
          const newRandIndex =
            Math.floor(Math.random() * (Number(await treaple.getAddressNodesCount()) + usedIndexes.length - 1)) + 1;

          if (!usedIndexes.includes(newRandIndex)) {
            randIndex = newRandIndex;
            usedIndexes.push(newRandIndex);

            break;
          }
        }
        let currentNode = await treaple.getAddressNode(randIndex);
        const currentNodeKey = `0x${currentNode.key.slice(26)}`;

        await treaple.removeAddress(currentNodeKey);

        expect(await treaple.getAddressRoot()).to.be.not.eq(treapleRoot);

        await treaple.addAddress(currentNodeKey);

        expect(await treaple.getAddressRoot()).to.be.eq(treapleRoot);
      }
    });

    it("should generate correct proof for the existing nodes", async () => {
      const keysCount: number = 50;
      const keys: string[] = createRandomArray(keysCount, 20);

      for (let i = 0; i < keys.length; i++) {
        await treaple.addAddress(keys[i]);
      }

      const treapleRoot: string = await treaple.getAddressRoot();

      for (let i = 0; i < keysCount; i++) {
        const randIndex = Math.floor(Math.random() * (Number(await treaple.getAddressNodesCount()) - 1)) + 1;
        const proof = await treaple.getAddressProof(keys[randIndex], 40);

        await verifyCMTProof(proof, treapleRoot, keys[randIndex], true, true);
      }
    });
  });
});
