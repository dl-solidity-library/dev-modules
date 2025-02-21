import { ethers } from "hardhat";
import { expect } from "chai";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";
import { getSelectors, FacetAction } from "@/test/helpers/diamond-helper";
import { wei } from "@/scripts/utils/utils";

import { OwnableDiamondMock, DummyFacetMock, DummyInitMock, Diamond } from "@ethers-v6";

describe("Diamond", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let SECOND: SignerWithAddress;

  let diamond: OwnableDiamondMock;

  before("setup", async () => {
    [OWNER, SECOND] = await ethers.getSigners();

    const OwnableDiamond = await ethers.getContractFactory("OwnableDiamondMock");
    diamond = await OwnableDiamond.deploy();

    await diamond.__OwnableDiamondMock_init();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should initialize only once", async () => {
      await expect(diamond.__OwnableDiamondMock_init())
        .to.be.revertedWithCustomError(diamond, "AlreadyInitialized")
        .withArgs();
    });

    it("should initialize only by top level contract", async () => {
      await expect(diamond.__OwnableDiamondDirect_init())
        .to.be.revertedWithCustomError(diamond, "NotInitializing")
        .withArgs();
    });
  });

  describe("ownable diamond functions", () => {
    it("should set owner correctly", async () => {
      expect(await diamond.owner()).to.equal(OWNER.address);
    });

    it("should transfer ownership", async () => {
      await diamond.transferOwnership(SECOND.address);

      expect(await diamond.owner()).to.equal(SECOND.address);
    });

    it("should renounce ownership", async () => {
      await diamond.renounceOwnership();

      expect(await diamond.owner()).to.equal(ethers.ZeroAddress);
    });

    it("should not transfer ownership from non-owner", async () => {
      await expect(diamond.connect(SECOND).transferOwnership(SECOND.address))
        .to.be.revertedWithCustomError(diamond, "CallerNotOwner")
        .withArgs(SECOND.address, OWNER.address);
    });

    it("should not renounce ownership from non-owner", async () => {
      await expect(diamond.connect(SECOND).renounceOwnership())
        .to.be.revertedWithCustomError(diamond, "CallerNotOwner")
        .withArgs(SECOND.address, OWNER.address);
    });

    it("should not transfer ownership to zero address", async () => {
      await expect(diamond.transferOwnership(ethers.ZeroAddress))
        .to.be.revertedWithCustomError(diamond, "InvalidOwner")
        .withArgs();
    });
  });

  describe("facets", () => {
    let dummyFacet: DummyFacetMock;
    let facets: Diamond.FacetStruct[] = [];
    let selectors: string[];

    beforeEach("setup", async () => {
      const DummyFacetMock = await ethers.getContractFactory("DummyFacetMock");
      dummyFacet = await DummyFacetMock.deploy();

      selectors = getSelectors(dummyFacet.interface);
    });

    describe("getters", () => {
      it("should return empty data", async () => {
        expect(await diamond.facets()).to.deep.equal([]);
        expect(await diamond.facetFunctionSelectors(await dummyFacet.getAddress())).to.deep.equal([]);
        expect(await diamond.facetAddresses()).to.deep.equal([]);
        expect(await diamond.facetAddress("0x11223344")).to.equal(ethers.ZeroAddress);
      });
    });

    describe("init", () => {
      let dummyInit: DummyInitMock;

      beforeEach("setup", async () => {
        dummyInit = await ethers.getContractFactory("DummyInitMock").then((f) => f.deploy());

        facets = [
          {
            facetAddress: await dummyFacet.getAddress(),
            action: FacetAction.Add,
            functionSelectors: selectors,
          },
        ];
      });

      it("should init correctly", async () => {
        const init = dummyInit.init.fragment.selector;
        const addr = await dummyInit.getAddress();

        const tx = await diamond.diamondCutLong(facets, dummyInit.getAddress(), init);

        await expect(tx).to.emit(diamond, "DiamondCut").withArgs(facets.map(Object.values), addr, init);

        const dimondInitMock = <DummyInitMock>dummyInit.attach(await diamond.getAddress());
        await expect(tx).to.emit(dimondInitMock, "Initialized");

        dummyFacet = <DummyFacetMock>dummyFacet.attach(await diamond.getAddress());
        expect(await dummyFacet.getDummyString()).to.be.equal("dummy facet initialized");
      });

      it("should revert if init function reverted", async () => {
        const initWithError = dummyInit.initWithError.fragment.selector;
        await expect(diamond.diamondCutLong(facets, await dummyInit.getAddress(), initWithError))
          .to.be.revertedWithCustomError(diamond, "InitializationReverted")
          .withArgs(await dummyInit.getAddress(), initWithError);
      });

      it("should revert if init function reverted with message", async () => {
        const initWithErrorMsg = dummyInit.initWithErrorMsg.fragment.selector;
        await expect(diamond.diamondCutLong(facets, await dummyInit.getAddress(), initWithErrorMsg))
          .to.be.revertedWithCustomError(dummyInit, "InitError")
          .withArgs();
      });
    });

    describe("add", () => {
      beforeEach("setup", async () => {
        facets = [
          {
            facetAddress: await dummyFacet.getAddress(),
            action: FacetAction.Add,
            functionSelectors: selectors,
          },
        ];
      });

      it("should add facet correctly", async () => {
        const tx = diamond.diamondCutShort(facets);

        await expect(tx).to.emit(diamond, "DiamondCut").withArgs(facets.map(Object.values), ethers.ZeroAddress, "0x");

        expect(await diamond.facets()).to.deep.equal([[await dummyFacet.getAddress(), selectors]]);
        expect(await diamond.facetFunctionSelectors(await dummyFacet.getAddress())).to.deep.equal(selectors);
        expect(await diamond.facetAddresses()).to.deep.equal([await dummyFacet.getAddress()]);
        expect(await diamond.facetAddress(selectors[0])).to.equal(await dummyFacet.getAddress());
        expect(await diamond.facetAddress("0x11223344")).to.equal(ethers.ZeroAddress);
      });

      it("should not add facet with zero address", async () => {
        facets[0].facetAddress = ethers.ZeroAddress;
        await expect(diamond.diamondCutShort(facets))
          .to.be.revertedWithCustomError(diamond, "FacetIsZeroAddress")
          .withArgs();
      });

      it("should not add facet when no selectors provided", async () => {
        facets[0].functionSelectors = [];
        await expect(diamond.diamondCutShort(facets))
          .to.be.revertedWithCustomError(diamond, "NoSelectorsProvided")
          .withArgs();
      });

      it("only owner should add facets", async () => {
        await expect(diamond.connect(SECOND).diamondCutShort(facets))
          .to.be.revertedWithCustomError(diamond, "CallerNotOwner")
          .withArgs(SECOND.address, OWNER.address);

        await expect(diamond.connect(SECOND).diamondCutLong(facets, ethers.ZeroAddress, ethers.ZeroHash))
          .to.be.revertedWithCustomError(diamond, "CallerNotOwner")
          .withArgs(SECOND.address, OWNER.address);
      });

      it("should not add duplicate selectors", async () => {
        await diamond.diamondCutShort(facets);
        await expect(diamond.diamondCutShort(facets))
          .to.be.revertedWithCustomError(diamond, "SelectorAlreadyAdded")
          .withArgs(facets[0].facetAddress, selectors[0]);
      });
    });

    describe("remove", () => {
      beforeEach("setup", async () => {
        selectors = getSelectors(dummyFacet.interface);
        facets = [
          {
            facetAddress: await dummyFacet.getAddress(),
            action: FacetAction.Remove,
            functionSelectors: selectors,
          },
        ];
      });

      it("should remove selectors", async () => {
        facets[0].action = FacetAction.Add;
        await diamond.diamondCutShort(facets);

        facets[0].action = FacetAction.Remove;
        facets[0].functionSelectors = selectors.slice(1);
        const tx = diamond.diamondCutShort(facets);

        await expect(tx).to.emit(diamond, "DiamondCut").withArgs(facets.map(Object.values), ethers.ZeroAddress, "0x");

        expect(await diamond.facets()).to.deep.equal([[await dummyFacet.getAddress(), [selectors[0]]]]);
        expect(await diamond.facetAddresses()).to.deep.equal([await dummyFacet.getAddress()]);
        expect(await diamond.facetFunctionSelectors(await dummyFacet.getAddress())).to.deep.equal([selectors[0]]);
        expect(await diamond.facetAddress(selectors[0])).to.equal(await dummyFacet.getAddress());
        expect(await diamond.facetAddress(selectors[1])).to.equal(ethers.ZeroAddress);
      });

      it("should fully remove facets", async () => {
        facets[0].action = FacetAction.Add;
        await diamond.diamondCutShort(facets);

        facets[0].action = FacetAction.Remove;
        const tx = diamond.diamondCutShort(facets);

        await expect(tx).to.emit(diamond, "DiamondCut").withArgs(facets.map(Object.values), ethers.ZeroAddress, "0x");

        expect(await diamond.facets()).to.deep.equal([]);
        expect(await diamond.facetAddresses()).to.deep.equal([]);
        expect(await diamond.facetFunctionSelectors(await dummyFacet.getAddress())).to.deep.equal([]);
        expect(await diamond.facetAddress(selectors[0])).to.equal(ethers.ZeroAddress);
      });

      it("should not remove facet when facet is zero address", async () => {
        facets[0].facetAddress = ethers.ZeroAddress;
        await expect(diamond.diamondCutShort(facets))
          .to.be.revertedWithCustomError(diamond, "FacetIsZeroAddress")
          .withArgs();
      });

      it("should not remove facet when no selectors provided", async () => {
        facets[0].functionSelectors = [];
        await expect(diamond.diamondCutShort(facets))
          .to.be.revertedWithCustomError(diamond, "NoSelectorsProvided")
          .withArgs();
      });

      it("should not remove selectors from another facet", async () => {
        facets[0].action = FacetAction.Add;
        await diamond.diamondCutShort(facets);

        facets[0].action = FacetAction.Remove;
        facets[0].facetAddress = await diamond.getAddress();

        await expect(diamond.diamondCutShort(facets))
          .to.be.revertedWithCustomError(diamond, "SelectorFromAnotherFacet")
          .withArgs(facets[0].functionSelectors[0]);
      });

      it("only owner should remove facets", async () => {
        await expect(diamond.connect(SECOND).diamondCutShort(facets))
          .to.be.revertedWithCustomError(diamond, "CallerNotOwner")
          .withArgs(SECOND.address, OWNER.address);

        await expect(diamond.connect(SECOND).diamondCutLong(facets, ethers.ZeroAddress, ethers.ZeroHash))
          .to.be.revertedWithCustomError(diamond, "CallerNotOwner")
          .withArgs(SECOND.address, OWNER.address);
      });
    });

    describe("replace", () => {
      beforeEach("setup", async () => {
        selectors = getSelectors(dummyFacet.interface);
        facets = [
          {
            facetAddress: await dummyFacet.getAddress(),
            action: FacetAction.Replace,
            functionSelectors: selectors,
          },
        ];
      });

      it("should replace facets and and part of its selectors", async () => {
        const dummyFacet2 = await ethers.getContractFactory("DummyFacetMock").then((f) => f.deploy());

        facets[0].action = FacetAction.Add;
        await diamond.diamondCutShort(facets);

        facets[0].action = FacetAction.Replace;
        facets[0].facetAddress = await dummyFacet2.getAddress();
        facets[0].functionSelectors = selectors.slice(1);

        const tx = diamond.diamondCutShort(facets);

        await expect(tx).to.emit(diamond, "DiamondCut").withArgs(facets.map(Object.values), ethers.ZeroAddress, "0x");

        expect(await diamond.facets()).to.deep.equal([
          [await dummyFacet.getAddress(), [selectors[0]]],
          [await dummyFacet2.getAddress(), selectors.slice(1)],
        ]);
        expect(await diamond.facetFunctionSelectors(await dummyFacet.getAddress())).to.deep.equal([selectors[0]]);
        expect(await diamond.facetFunctionSelectors(await dummyFacet2.getAddress())).to.deep.equal(selectors.slice(1));
        expect(await diamond.facetAddress(selectors[0])).to.equal(await dummyFacet.getAddress());
        expect(await diamond.facetAddress(selectors[1])).to.equal(await dummyFacet2.getAddress());
      });

      it("should replace facets and all its selectors", async () => {
        const dummyFacet2 = await ethers.getContractFactory("DummyFacetMock").then((f) => f.deploy());

        facets[0].action = FacetAction.Add;
        await diamond.diamondCutShort(facets);

        facets[0].action = FacetAction.Replace;
        facets[0].facetAddress = await dummyFacet2.getAddress();

        const tx = diamond.diamondCutShort(facets);

        await expect(tx).to.emit(diamond, "DiamondCut").withArgs(facets.map(Object.values), ethers.ZeroAddress, "0x");

        expect(await diamond.facets()).to.deep.equal([[await dummyFacet2.getAddress(), selectors]]);
        expect(await diamond.facetFunctionSelectors(await dummyFacet.getAddress())).to.deep.equal([]);
        expect(await diamond.facetFunctionSelectors(await dummyFacet2.getAddress())).to.deep.equal(selectors);
        expect(await diamond.facetAddress(selectors[0])).to.equal(await dummyFacet2.getAddress());
      });

      it("should not replace facet when facet is zero address", async () => {
        facets[0].facetAddress = ethers.ZeroAddress;
        await expect(diamond.diamondCutShort(facets))
          .to.be.revertedWithCustomError(diamond, "FacetIsZeroAddress")
          .withArgs();
      });

      it("should not replace facet when no selectors provided", async () => {
        facets[0].functionSelectors = [];
        await expect(diamond.diamondCutShort(facets))
          .to.be.revertedWithCustomError(diamond, "NoSelectorsProvided")
          .withArgs();
      });

      it("should not replace facet with the same facet", async () => {
        facets[0].action = FacetAction.Add;
        await diamond.diamondCutShort(facets);

        facets[0].action = FacetAction.Replace;
        await expect(diamond.diamondCutShort(facets))
          .to.be.revertedWithCustomError(diamond, "SelectorIsAlreadyInThisFaucet")
          .withArgs(facets[0].functionSelectors[0], facets[0].facetAddress);
      });

      it("should not replace facet if selector is not registered", async () => {
        facets[0].action = FacetAction.Add;
        await diamond.diamondCutShort(facets);

        facets[0].action = FacetAction.Replace;
        // set random selector
        facets[0].functionSelectors = ["0x00000000"];
        await expect(diamond.diamondCutShort(facets))
          .to.be.revertedWithCustomError(diamond, "NoFacetForSelector")
          .withArgs(facets[0].functionSelectors[0]);
      });

      it("only owner should replace facets", async () => {
        await expect(diamond.connect(SECOND).diamondCutShort(facets))
          .to.be.revertedWithCustomError(diamond, "CallerNotOwner")
          .withArgs(SECOND.address, OWNER.address);

        await expect(diamond.connect(SECOND).diamondCutLong(facets, ethers.ZeroAddress, ethers.ZeroHash))
          .to.be.revertedWithCustomError(diamond, "CallerNotOwner")
          .withArgs(SECOND.address, OWNER.address);
      });
    });

    describe("call", () => {
      beforeEach("setup", async () => {
        facets = [
          {
            facetAddress: await dummyFacet.getAddress(),
            action: FacetAction.Add,
            functionSelectors: selectors,
          },
        ];
      });

      it("should be able to call facets", async () => {
        await diamond.diamondCutShort(facets);

        const DummyFacetMock = await ethers.getContractFactory("DummyFacetMock");
        const facet = <DummyFacetMock>DummyFacetMock.attach(await diamond.getAddress());

        await facet.setDummyString("hello, diamond");

        expect(await facet.getDummyString()).to.equal("hello, diamond");
        expect(await dummyFacet.getDummyString()).to.equal("");
      });

      it("should receive ether via receive", async () => {
        facets[0].functionSelectors = ["0x00000000"];
        await diamond.diamondCutShort(facets);

        let tx = {
          to: await diamond.getAddress(),
          value: wei("1"),
        };

        await OWNER.sendTransaction(tx);
      });

      it("should not call facet if selector is not added", async () => {
        const DummyFacetMock = await ethers.getContractFactory("DummyFacetMock");
        const facet = <DummyFacetMock>DummyFacetMock.attach(await diamond.getAddress());

        await expect(facet.getDummyString())
          .to.be.revertedWithCustomError(diamond, "SelectorNotRegistered")
          .withArgs(getSelectors(facet.interface)[1]);
      });

      it("should not receive ether if receive is not added", async () => {
        let tx = {
          to: await diamond.getAddress(),
          value: wei("1"),
        };

        await expect(OWNER.sendTransaction(tx))
          .to.be.revertedWithCustomError(diamond, "SelectorNotRegistered")
          .withArgs("0x00000000");
      });
    });
  });
});
