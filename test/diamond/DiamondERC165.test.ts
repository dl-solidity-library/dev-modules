import { ethers } from "hardhat";
import { expect } from "chai";

import { Reverter } from "@/test/helpers/reverter";
import { getSelectors, FacetAction } from "@/test/helpers/diamond-helper";

import { OwnableDiamondMock, DiamondERC165, Diamond } from "@ethers-v6";

describe("DiamondERC165", () => {
  const reverter = new Reverter();

  let erc165: DiamondERC165;
  let diamond: OwnableDiamondMock;

  before("setup", async () => {
    await reverter.snapshot();
  });

  beforeEach("setup", async () => {
    const OwnableDiamond = await ethers.getContractFactory("OwnableDiamondMock");
    const DiamondERC165 = await ethers.getContractFactory("DiamondERC165");

    diamond = await OwnableDiamond.deploy();
    erc165 = await DiamondERC165.deploy();

    const facets: Diamond.FacetStruct[] = [
      {
        facetAddress: await erc165.getAddress(),
        action: FacetAction.Add,
        functionSelectors: getSelectors(erc165.interface),
      },
    ];

    await diamond.__OwnableDiamondMock_init();
    await diamond.diamondCutShort(facets);

    erc165 = <DiamondERC165>DiamondERC165.attach(await diamond.getAddress());
  });

  afterEach(reverter.revert);

  describe("ERC165", () => {
    it("should support IERC165", async () => {
      expect(await erc165.supportsInterface(erc165.supportsInterface.fragment.selector)).to.be.true;
    });

    it("should support DiamondLoupe interface - 0x48e2b093", async () => {
      expect(
        await erc165.supportsInterface(
          ethers.toBeHex(
            Number(diamond.facets.fragment.selector) ^
              Number(diamond.facetFunctionSelectors.fragment.selector) ^
              Number(diamond.facetAddresses.fragment.selector) ^
              Number(diamond.facetAddress.fragment.selector),
          ),
        ),
      ).to.be.true;
    });

    it("should support DiamondCut interface - 0x1f931c1c", async () => {
      expect(
        await erc165.supportsInterface(
          diamond["diamondCut((address,uint8,bytes4[])[],address,bytes)"].fragment.selector,
        ),
      ).to.be.true;
    });

    it("should not support any random interface until it explicitly defined in diamond", async () => {
      // ERC20 interface
      expect(await erc165.supportsInterface("0x36372b07")).to.be.false;
    });
  });
});
