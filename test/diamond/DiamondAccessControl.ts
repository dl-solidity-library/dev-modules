import { ethers } from "hardhat";
import { expect } from "chai";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";
import { getSelectors, FacetAction } from "@/test/helpers/diamond-helper";

import { OwnableDiamondMock, Diamond, DiamondAccessControlMock } from "@ethers-v6";

describe("DiamondAccessControl", () => {
  const reverter = new Reverter();

  const ADMIN_ROLE = ethers.ZeroHash;
  const AGENT_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000001";

  let OWNER: SignerWithAddress;
  let SECOND: SignerWithAddress;
  let THIRD: SignerWithAddress;

  let access: DiamondAccessControlMock;
  let diamond: OwnableDiamondMock;

  before("setup", async () => {
    [OWNER, SECOND, THIRD] = await ethers.getSigners();

    const OwnableDiamond = await ethers.getContractFactory("OwnableDiamondMock");
    const DiamondAccessControlMock = await ethers.getContractFactory("DiamondAccessControlMock");

    diamond = await OwnableDiamond.deploy();
    access = await DiamondAccessControlMock.deploy();

    await diamond.__OwnableDiamondMock_init();

    const facets: Diamond.FacetStruct[] = [
      {
        facetAddress: await access.getAddress(),
        action: FacetAction.Add,
        functionSelectors: getSelectors(access.interface),
      },
    ];

    await diamond.diamondCutShort(facets);

    access = <DiamondAccessControlMock>DiamondAccessControlMock.attach(await diamond.getAddress());

    await access.__DiamondAccessControlMock_init();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should initialize only once", async () => {
      await expect(access.__DiamondAccessControlMock_init())
        .to.be.revertedWithCustomError(diamond, "AlreadyInitialized")
        .withArgs();
    });

    it("should initialize only by top level contract", async () => {
      await expect(access.__DiamondAccessControlDirect_init())
        .to.be.revertedWithCustomError(diamond, "NotInitializing")
        .withArgs();
    });
  });

  describe("DiamondAccessControl functions", () => {
    describe("grantRole", async () => {
      it("should not grant role if not admin", async () => {
        await expect(access.connect(SECOND).grantRole(AGENT_ROLE, SECOND))
          .to.be.revertedWithCustomError(access, "RoleNotGranted")
          .withArgs(await access.getRoleAdmin(AGENT_ROLE), SECOND);
      });

      it("should not grant role if it's granted", async () => {
        await access.grantRole(AGENT_ROLE, SECOND);

        await expect(access.grantRole(AGENT_ROLE, SECOND))
          .to.be.revertedWithCustomError(access, "RoleAlreadyGranted")
          .withArgs(AGENT_ROLE, SECOND);
      });

      it("should grant role if all conditions are met", async () => {
        await access.grantRole(AGENT_ROLE, SECOND);

        expect(await access.hasRole(AGENT_ROLE, SECOND)).to.be.true;
      });
    });

    describe("revokeRole", async () => {
      beforeEach(async () => {
        await access.grantRole(AGENT_ROLE, SECOND);
      });

      it("should not revoke role if not admin", async () => {
        await expect(access.connect(SECOND).revokeRole(AGENT_ROLE, SECOND))
          .to.be.revertedWithCustomError(access, "RoleNotGranted")
          .withArgs(await access.getRoleAdmin(AGENT_ROLE), SECOND);
      });

      it("should not revoke role if it's not granted", async () => {
        await access.revokeRole(AGENT_ROLE, SECOND);

        await expect(access.revokeRole(AGENT_ROLE, SECOND))
          .to.be.revertedWithCustomError(access, "RoleNotGranted")
          .withArgs(AGENT_ROLE, SECOND);
      });

      it("should revoke role if all conditions are met", async () => {
        await access.revokeRole(AGENT_ROLE, SECOND);

        expect(await access.hasRole(AGENT_ROLE, SECOND)).to.be.false;
      });
    });

    describe("renounceRole", async () => {
      beforeEach(async () => {
        await access.grantRole(AGENT_ROLE, SECOND);
      });

      it("should not renounce role if not self", async () => {
        await expect(access.renounceRole(AGENT_ROLE, SECOND))
          .to.be.revertedWithCustomError(access, "UnauthorizedAccount")
          .withArgs(OWNER);
      });

      it("should renounce role if all conditions are met", async () => {
        await access.connect(SECOND).renounceRole(AGENT_ROLE, SECOND);

        expect(await access.hasRole(AGENT_ROLE, SECOND)).to.be.false;
      });
    });

    describe("setAdminRole", async () => {
      beforeEach(async () => {
        await access.grantRole(AGENT_ROLE, SECOND);
        await access.setRoleAdmin(AGENT_ROLE, AGENT_ROLE);
      });

      it("should not grant role if not admin", async () => {
        await expect(access.grantRole(AGENT_ROLE, THIRD))
          .to.be.revertedWithCustomError(access, "RoleNotGranted")
          .withArgs(await access.getRoleAdmin(AGENT_ROLE), OWNER);

        it("should grant role if all conditions are met", async () => {
          await access.connect(SECOND).grantRole(AGENT_ROLE, THIRD);

          expect(await access.hasRole(AGENT_ROLE, THIRD)).to.be.true;
        });
      });
    });

    describe("getters", () => {
      it("should return base data", async () => {
        expect(await access.DEFAULT_ADMIN_ROLE()).to.equal(ADMIN_ROLE);
        expect(await access.AGENT_ROLE()).to.equal(AGENT_ROLE);
        expect(await access.hasRole(ADMIN_ROLE, OWNER)).to.be.true;
        expect(await access.hasRole(ADMIN_ROLE, SECOND)).to.be.false;
        expect(await access.getRoleAdmin(AGENT_ROLE)).to.equal(ADMIN_ROLE);
      });
    });
  });
});
