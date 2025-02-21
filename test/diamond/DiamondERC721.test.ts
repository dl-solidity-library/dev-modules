import { ethers } from "hardhat";
import { expect } from "chai";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";
import { getSelectors, FacetAction } from "@/test/helpers/diamond-helper";

import { OwnableDiamondMock, DiamondERC721Mock, Diamond, DiamondERC721NotReceiverMock } from "@ethers-v6";

describe("DiamondERC721 and InitializableStorage", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let SECOND: SignerWithAddress;
  let THIRD: SignerWithAddress;

  let erc721: DiamondERC721Mock;
  let diamond: OwnableDiamondMock;
  let notReceiverMock: DiamondERC721NotReceiverMock;

  before("setup", async () => {
    [OWNER, SECOND, THIRD] = await ethers.getSigners();

    const OwnableDiamond = await ethers.getContractFactory("OwnableDiamondMock");
    const DiamondERC721Mock = await ethers.getContractFactory("DiamondERC721Mock");
    const DiamondERC721NotReceiverMock = await ethers.getContractFactory("DiamondERC721NotReceiverMock");

    diamond = await OwnableDiamond.deploy();
    const diamond2 = await OwnableDiamond.deploy();
    erc721 = await DiamondERC721Mock.deploy();
    notReceiverMock = await DiamondERC721NotReceiverMock.deploy();

    const facets: Diamond.FacetStruct[] = [
      {
        facetAddress: await erc721.getAddress(),
        action: FacetAction.Add,
        functionSelectors: getSelectors(erc721.interface),
      },
    ];

    const facets2: Diamond.FacetStruct[] = [
      {
        facetAddress: await notReceiverMock.getAddress(),
        action: FacetAction.Add,
        functionSelectors: getSelectors(notReceiverMock.interface),
      },
    ];

    await diamond.__OwnableDiamondMock_init();
    await diamond.diamondCutShort(facets);

    await diamond2.__OwnableDiamondMock_init();
    await diamond2.diamondCutShort(facets2);

    erc721 = <DiamondERC721Mock>DiamondERC721Mock.attach(await diamond.getAddress());
    notReceiverMock = <DiamondERC721NotReceiverMock>DiamondERC721NotReceiverMock.attach(await diamond2.getAddress());

    await erc721.__DiamondERC721Mock_init("Mock Token", "MT");
    await notReceiverMock.__DiamondERC721Mock_init("Mock Token", "MT");

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should initialize only once", async () => {
      await expect(erc721.__DiamondERC721Mock_init("Mock Token", "MT"))
        .to.be.revertedWithCustomError(erc721, "AlreadyInitialized")
        .withArgs();
    });

    it("should initialize only by top level contract", async () => {
      await expect(erc721.__DiamondERC721Direct_init("Mock Token", "MT"))
        .to.be.revertedWithCustomError(erc721, "NotInitializing")
        .withArgs();
    });

    it("should disable implementation initialization", async () => {
      const DiamondERC721Mock = await ethers.getContractFactory("DiamondERC721Mock");
      const contract = await DiamondERC721Mock.deploy();

      let tx = contract.deploymentTransaction();

      expect(tx)
        .to.emit(contract, "Initialized")
        .withArgs(await erc721.DIAMOND_ERC721_STORAGE_SLOT());

      await expect(contract.disableInitializers()).to.be.revertedWithCustomError(erc721, "InvalidInitialization");
    });
  });

  describe("getters", () => {
    it("should return base data", async () => {
      expect(await erc721.name()).to.equal("Mock Token");
      expect(await erc721.symbol()).to.equal("MT");

      await erc721.mint(OWNER.address, 1);

      expect(await erc721.balanceOf(OWNER.address)).to.equal(1);
      expect(await erc721.totalSupply()).to.equal(1);

      expect(await erc721.tokenOfOwnerByIndex(OWNER.address, 0)).to.equal(1);
      expect(await erc721.tokenByIndex(0)).to.equal(1);
      expect(await erc721.ownerOf(1)).to.equal(OWNER.address);

      await expect(erc721.tokenOfOwnerByIndex(OWNER.address, 10))
        .to.be.revertedWithCustomError(erc721, "OwnerIndexOutOfBounds")
        .withArgs(OWNER.address, 10);

      await expect(erc721.tokenByIndex(10)).to.be.revertedWithCustomError(erc721, "IndexOutOfBounds").withArgs(10);

      expect(await erc721.tokenURI(1)).to.equal("");
      await erc721.setBaseURI("https://example.com/");
      expect(await erc721.tokenURI(1)).to.equal("https://example.com/1");

      await expect(erc721.tokenURI(10)).to.be.revertedWithCustomError(erc721, "NonexistentToken").withArgs(10);
    });

    it("should support all necessary interfaces", async () => {
      // IERC721
      expect(await erc721.supportsInterface("0x80ac58cd")).to.be.true;
      // IERC721Metadata
      expect(await erc721.supportsInterface("0x5b5e139f")).to.be.true;
      // IERC721Enumerable
      expect(await erc721.supportsInterface("0x780e9d63")).to.be.true;
      // IERC165
      expect(await erc721.supportsInterface("0x01ffc9a7")).to.be.true;
    });
  });

  describe("DiamondERC721 functions", () => {
    describe("mint", () => {
      it("should mint tokens", async () => {
        const tx = erc721.mint(OWNER.address, 1);

        await expect(tx).to.emit(erc721, "Transfer").withArgs(ethers.ZeroAddress, OWNER.address, 1);

        expect(await erc721.balanceOf(OWNER.address)).to.equal(1);
      });

      it("should not mint tokens to zero address", async () => {
        await expect(erc721.mint(ethers.ZeroAddress, 1)).to.be.revertedWithCustomError(erc721, "ReceiverIsZeroAddress");
      });

      it("should not mint tokens if it's alredy minted", async () => {
        await erc721.mint(OWNER.address, 1);
        await expect(erc721.mint(OWNER.address, 1))
          .to.be.revertedWithCustomError(erc721, "TokenAlreadyMinted")
          .withArgs(1);
      });

      it("should not mint tokens if token is minted after `_update` hook", async () => {
        await erc721.toggleReplaceOwner();

        await expect(erc721.mint(OWNER.address, 1))
          .to.be.revertedWithCustomError(erc721, "TokenAlreadyMinted")
          .withArgs(1);
      });

      it("should not mint token if the receiver is a contract and doesn't implement onERC721Received correctly", async () => {
        const contract1 = await (await ethers.getContractFactory("DiamondERC721Mock")).deploy();

        await expect(erc721.mint(await contract1.getAddress(), 1))
          .to.be.revertedWithCustomError(erc721, "NonERC721Receiver")
          .withArgs(await contract1.getAddress());

        await expect(notReceiverMock.mint(await contract1.getAddress(), 1))
          .to.be.revertedWithCustomError(notReceiverMock, "NonERC721Receiver")
          .withArgs(await contract1.getAddress());

        const contract2 = await (await ethers.getContractFactory("NonERC721Receiver")).deploy();

        await expect(erc721.mint(await contract2.getAddress(), 1)).to.be.revertedWithCustomError(
          contract2,
          "RevertingOnERC721Received",
        );
      });
    });

    describe("burn", () => {
      it("should burn tokens", async () => {
        await erc721.mint(OWNER.address, 1);

        expect(await erc721.balanceOf(OWNER.address)).to.equal(1);

        const tx = erc721.burn(1);

        await expect(tx).to.emit(erc721, "Transfer").withArgs(OWNER.address, ethers.ZeroAddress, 1);

        expect(await erc721.balanceOf(OWNER.address)).to.equal(0);
      });

      it("should not burn a not minted token", async () => {
        await expect(erc721.burn(1)).to.be.revertedWithCustomError(erc721, "NonexistentToken").withArgs(1);
      });
    });

    describe("update hook", () => {
      it("update hook should only accept one token", async () => {
        expect(await erc721.update(1)).not.to.be.reverted;
      });

      it("update hook should not accept more than one token", async () => {
        await expect(erc721.update(2)).to.be.revertedWithCustomError(erc721, "ConsecutiveTransfersNotSupported");
      });
    });

    describe("transfer/safeTransfer", () => {
      it("should transfer tokens", async () => {
        await erc721.mint(OWNER.address, 1);

        expect(await erc721.balanceOf(OWNER.address)).to.equal(1);
        expect(await erc721.balanceOf(SECOND.address)).to.equal(0);

        const tx = erc721.transferFrom(OWNER.address, SECOND, 1);

        await expect(tx).to.emit(erc721, "Transfer").withArgs(OWNER.address, SECOND.address, 1);

        expect(await erc721.balanceOf(OWNER.address)).to.equal(0);
        expect(await erc721.balanceOf(SECOND.address)).to.equal(1);
      });

      it("should safely transfer tokens", async () => {
        await erc721.mint(OWNER.address, 1);
        await erc721.mint(OWNER.address, 2);

        expect(await erc721.balanceOf(OWNER.address)).to.equal(2);
        expect(await erc721.balanceOf(SECOND.address)).to.equal(0);

        const tx = erc721.safeTransferFromMock(OWNER.address, SECOND, 1);

        await expect(tx).to.emit(erc721, "Transfer").withArgs(OWNER.address, SECOND.address, 1);

        expect(await erc721.balanceOf(OWNER.address)).to.equal(1);
        expect(await erc721.balanceOf(SECOND.address)).to.equal(1);
      });

      it("should safely transfer tokens to the contract if it implements onERC721Received correctly", async () => {
        await erc721.mint(OWNER.address, 1);

        expect(await erc721.balanceOf(OWNER.address)).to.equal(1);
        expect(await erc721.balanceOf(SECOND.address)).to.equal(0);

        const receiver = await (await ethers.getContractFactory("ERC721HolderMock")).deploy();
        const tx = erc721.safeTransferFromMock(OWNER.address, await receiver.getAddress(), 1);

        await expect(tx)
          .to.emit(erc721, "Transfer")
          .withArgs(OWNER.address, await receiver.getAddress(), 1);

        expect(await erc721.balanceOf(OWNER.address)).to.equal(0);
        expect(await erc721.balanceOf(await receiver.getAddress())).to.equal(1);
      });

      it("should not transfer tokens when caller is not an owner or not approved", async () => {
        await erc721.mint(OWNER.address, 1);

        await expect(erc721.connect(SECOND).transferFrom(OWNER.address, SECOND.address, 1))
          .to.be.revertedWithCustomError(erc721, "InvalidSpender")
          .withArgs(SECOND.address, 1);

        await expect(erc721.connect(SECOND).safeTransferFromMock(OWNER.address, SECOND.address, 1))
          .to.be.revertedWithCustomError(erc721, "InvalidSpender")
          .withArgs(SECOND.address, 1);
      });

      it("should not transfer tokens when call is not an owner", async () => {
        await erc721.mint(OWNER.address, 1);

        await expect(erc721.transferFromMock(SECOND.address, OWNER.address, 1))
          .to.be.revertedWithCustomError(erc721, "UnauthorizedAccount")
          .withArgs(SECOND.address);
      });

      it("should not transfer tokens to zero address", async () => {
        await erc721.mint(OWNER.address, 1);

        await expect(erc721.transferFromMock(OWNER.address, ethers.ZeroAddress, 1)).to.be.revertedWithCustomError(
          erc721,
          "ReceiverIsZeroAddress",
        );
      });

      it("should not transfer tokens if owner is changed after `_update` hook", async () => {
        await erc721.mint(OWNER.address, 1);

        await erc721.toggleReplaceOwner();

        await expect(erc721.transferFromMock(OWNER.address, SECOND.address, 1)).to.be.revertedWithCustomError(
          erc721,
          "UnauthorizedAccount",
        );
      });

      it("should not transfer token if the receiver is a contract and doesn't implement onERC721Received", async () => {
        await notReceiverMock.mockMint(OWNER.address, 1);

        const contract = await (await ethers.getContractFactory("DiamondERC721Mock")).deploy();

        await expect(notReceiverMock.safeTransferFromMock(OWNER.address, await contract.getAddress(), 1))
          .to.be.revertedWithCustomError(notReceiverMock, "NonERC721Receiver")
          .withArgs(await contract.getAddress());
      });

      it("should not transfer incorrect token", async () => {
        await expect(erc721.transferFromMock(OWNER.address, SECOND.address, 1))
          .to.be.revertedWithCustomError(erc721, "NonexistentToken")
          .withArgs(1);
      });
    });

    describe("approve/approveAll", () => {
      it("should approve tokens", async () => {
        await erc721.mint(OWNER.address, 1);

        const tx = erc721.approve(SECOND.address, 1);

        await expect(tx).to.emit(erc721, "Approval").withArgs(OWNER.address, SECOND.address, 1);

        expect(await erc721.getApproved(1)).to.equal(SECOND.address);
        expect(await erc721.connect(SECOND).transferFrom(OWNER.address, THIRD.address, 1)).not.to.be.reverted;

        await erc721.mint(OWNER.address, 2);
        await erc721.mint(OWNER.address, 3);
        await erc721.setApprovalForAll(SECOND.address, true);

        await erc721.connect(SECOND).approve(THIRD.address, 3);

        expect(await erc721.getApproved(3)).to.equal(THIRD.address);
        expect(await erc721.connect(THIRD).transferFrom(OWNER.address, SECOND.address, 3)).not.to.be.reverted;
      });

      it("should not approve incorrect token", async () => {
        await expect(erc721.approve(OWNER.address, 1))
          .to.be.revertedWithCustomError(erc721, "NonexistentToken")
          .withArgs(1);
      });

      it("should not approve token if caller is not an owner", async () => {
        await erc721.mint(OWNER.address, 1);
        await expect(erc721.connect(SECOND).approve(THIRD.address, 1))
          .to.be.revertedWithCustomError(erc721, "InvalidApprover")
          .withArgs(SECOND.address, OWNER.address);
      });

      it("should not approve token if spender and caller are the same", async () => {
        await erc721.mint(OWNER.address, 1);

        await expect(erc721.approve(OWNER.address, 1))
          .to.be.revertedWithCustomError(erc721, "ApprovalToCurrentOwner")
          .withArgs(OWNER.address, 1);
      });

      it("should approve all tokens", async () => {
        await erc721.mint(OWNER.address, 1);
        await erc721.mint(OWNER.address, 2);
        await erc721.mint(OWNER.address, 3);
        const tx = erc721.setApprovalForAll(SECOND.address, true);

        await expect(tx).to.emit(erc721, "ApprovalForAll").withArgs(OWNER.address, SECOND.address, true);

        expect(await erc721.isApprovedForAll(OWNER.address, SECOND.address)).to.be.true;

        expect(await erc721.connect(SECOND).transferFrom(OWNER.address, THIRD.address, 1)).not.to.be.reverted;
      });

      it("should not approve all tokens if owner the same as operator", async () => {
        await erc721.mint(OWNER.address, 1);
        await erc721.mint(OWNER.address, 2);
        await erc721.mint(OWNER.address, 3);

        await expect(erc721.setApprovalForAll(OWNER.address, true))
          .to.be.revertedWithCustomError(erc721, "ApproveToCaller")
          .withArgs(OWNER.address);
      });
    });
  });
});
