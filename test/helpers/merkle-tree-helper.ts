import { ethers } from "hardhat";

import { MerkleTree } from "merkletreejs";

export function getRoot(tree: MerkleTree): string {
  const root = tree.getRoot();

  if (root.length == 0) {
    return ethers.ZeroHash;
  }

  return "0x" + root.toString("hex");
}

export function getProof(tree: MerkleTree, leaf: any, hashFn: any = ethers.keccak256): string[] {
  return tree.getProof(hashFn(leaf)).map((e) => "0x" + e.data.toString("hex"));
}

export function buildTree(leaves: any, hashFn: any = ethers.keccak256): MerkleTree {
  return new MerkleTree(leaves, hashFn, { hashLeaves: true, sortPairs: true });
}

export function buildSparseMerkleTree(leaves: any, height: number, hashFn: any = ethers.keccak256): MerkleTree {
  const elementsToAdd = 2 ** height - leaves.length;
  const zeroHash = hashFn(ethers.ZeroHash);
  const zeroElements = Array(elementsToAdd).fill(zeroHash);

  return new MerkleTree([...leaves, ...zeroElements], hashFn, {
    hashLeaves: false,
    sortPairs: false,
  });
}

export function addElementToTree(tree: MerkleTree, element: any, hashFn: any = ethers.keccak256) {
  return new MerkleTree([...tree.getLeaves(), element], hashFn, {
    hashLeaves: true,
    sortPairs: true,
  });
}
