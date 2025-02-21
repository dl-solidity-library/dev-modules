import { ethers } from "hardhat";
import { expect } from "chai";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";

import { RBACMock } from "@ethers-v6";

describe("RBAC", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let SECOND: SignerWithAddress;

  let rbac: RBACMock;

  before("setup", async () => {
    [OWNER, SECOND] = await ethers.getSigners();

    const RBACMock = await ethers.getContractFactory("RBACMock");
    rbac = await RBACMock.deploy();

    await rbac.__RBACMock_init();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should not initialize twice", async () => {
      await expect(rbac.mockInit()).to.be.revertedWithCustomError(rbac, "NotInitializing").withArgs();
    });
  });

  describe("role permissions", () => {
    it("should add allowed permissions to role", async () => {
      let allowedPerms = (await rbac.getRolePermissions("ROLE"))[0];

      expect(allowedPerms).to.deep.equal([]);

      await rbac.addPermissionsToRole(
        "ROLE",
        [{ resource: "resource", permissions: ["permission1", "permission2"] }],
        true,
      );

      allowedPerms = (await rbac.getRolePermissions("ROLE"))[0];

      expect(allowedPerms).to.deep.equal([["resource", ["permission1", "permission2"]]]);
    });

    it("should add disallowed permissions to role", async () => {
      let disallowedPerms = (await rbac.getRolePermissions("ROLE"))[1];

      expect(disallowedPerms).to.deep.equal([]);

      await rbac.addPermissionsToRole(
        "ROLE",
        [{ resource: "resource", permissions: ["permission1", "permission2"] }],
        false,
      );

      disallowedPerms = (await rbac.getRolePermissions("ROLE"))[1];

      expect(disallowedPerms).to.deep.equal([["resource", ["permission1", "permission2"]]]);
    });

    it("should remove allowed permissions from role", async () => {
      await rbac.addPermissionsToRole(
        "ROLE",
        [{ resource: "resource", permissions: ["permission1", "permission2"] }],
        true,
      );
      await rbac.removePermissionsFromRole("ROLE", [{ resource: "resource", permissions: ["permission1"] }], true);

      let allowedPerms = (await rbac.getRolePermissions("ROLE"))[0];

      expect(allowedPerms).to.deep.equal([["resource", ["permission2"]]]);
    });

    it("should remove disallowed permissions from role", async () => {
      await rbac.addPermissionsToRole(
        "ROLE",
        [{ resource: "resource", permissions: ["permission1", "permission2"] }],
        false,
      );
      await rbac.removePermissionsFromRole("ROLE", [{ resource: "resource", permissions: ["permission2"] }], false);

      let disallowedPerms = (await rbac.getRolePermissions("ROLE"))[1];

      expect(disallowedPerms).to.deep.equal([["resource", ["permission1"]]]);
    });

    it("should remove all permissions from role", async () => {
      await rbac.addPermissionsToRole(
        "ROLE",
        [{ resource: "resource", permissions: ["permission1", "permission2"] }],
        true,
      );
      await rbac.addPermissionsToRole(
        "ROLE",
        [{ resource: "resource", permissions: ["permission1", "permission2"] }],
        false,
      );

      await rbac.removePermissionsFromRole(
        "ROLE",
        [{ resource: "resource", permissions: ["permission1", "permission2"] }],
        true,
      );
      await rbac.removePermissionsFromRole(
        "ROLE",
        [{ resource: "resource", permissions: ["permission1", "permission2"] }],
        false,
      );

      let allowedPerms = (await rbac.getRolePermissions("ROLE"))[0];
      let disallowedPerms = (await rbac.getRolePermissions("ROLE"))[1];

      expect(allowedPerms).to.deep.equal([]);
      expect(disallowedPerms).to.deep.equal([]);
    });
  });

  describe("user roles", () => {
    describe("empty roles", () => {
      it("should not grant empty roles", async () => {
        await expect(rbac.grantRoles(SECOND.address, [])).to.be.revertedWithCustomError(rbac, "EmptyRoles");
      });

      it("should not revoke empty roles", async () => {
        await expect(rbac.revokeRoles(SECOND.address, [])).to.be.revertedWithCustomError(rbac, "EmptyRoles");
      });
    });

    describe("allowed permissions", () => {
      it("should grant roles and check permissions (1)", async () => {
        await rbac.addPermissionsToRole(
          "ROLE",
          [{ resource: "resource", permissions: ["permission1", "permission2"] }],
          true,
        );

        expect(await rbac.hasPermission(SECOND.address, "resource", "permission2")).to.be.false;

        await rbac.grantRoles(SECOND.address, ["ROLE"]);

        expect(await rbac.getUserRoles(SECOND.address)).to.deep.equal(["ROLE"]);
        expect(await rbac.hasPermission(SECOND.address, "resource", "permission2")).to.be.true;
      });

      it("should grant roles and check permissions (2)", async () => {
        await rbac.addPermissionsToRole("ROLE1", [{ resource: "resource1", permissions: ["permission1"] }], true);
        await rbac.addPermissionsToRole("ROLE2", [{ resource: "resource2", permissions: ["permission2"] }], true);

        expect(await rbac.hasPermission(SECOND.address, "resource1", "permission1")).to.be.false;
        expect(await rbac.hasPermission(SECOND.address, "resource2", "permission2")).to.be.false;

        await rbac.grantRoles(SECOND.address, ["ROLE1", "ROLE2"]);

        expect(await rbac.getUserRoles(SECOND.address)).to.deep.equal(["ROLE1", "ROLE2"]);
        expect(await rbac.hasPermission(SECOND.address, "resource1", "permission1")).to.be.true;
        expect(await rbac.hasPermission(SECOND.address, "resource2", "permission2")).to.be.true;
      });

      it("should grant roles and check permissions (3)", async () => {
        await rbac.addPermissionsToRole("ROLE", [], true);

        expect(await rbac.hasPermission(SECOND.address, "resource", "permission")).to.be.false;

        await rbac.grantRoles(SECOND.address, ["ROLE"]);

        expect(await rbac.getUserRoles(SECOND.address)).to.deep.equal(["ROLE"]);
        expect(await rbac.hasPermission(SECOND.address, "resource", "permission")).to.be.false;
      });

      it("should grant roles and check permissions (4)", async () => {
        await rbac.addPermissionsToRole("ROLE", [{ resource: "resource", permissions: [] }], true);

        expect(await rbac.hasPermission(SECOND.address, "resource", "permission")).to.be.false;

        await rbac.grantRoles(SECOND.address, ["ROLE"]);

        expect(await rbac.getUserRoles(SECOND.address)).to.deep.equal(["ROLE"]);
        expect(await rbac.hasPermission(SECOND.address, "resource", "permission")).to.be.false;
      });

      it("should add roles with proper permission", async () => {
        await rbac.addPermissionsToRole("RBAC_MASTER", [{ resource: "RBAC_RESOURCE", permissions: ["CREATE"] }], true);
        await rbac.grantRoles(SECOND.address, ["RBAC_MASTER"]);

        await rbac.connect(SECOND).grantRoles(OWNER.address, ["RBAC_MASTER"]);
      });

      it("should grant and revoke roles", async () => {
        await rbac.addPermissionsToRole("ROLE1", [{ resource: "resource", permissions: ["permission1"] }], true);
        await rbac.addPermissionsToRole("ROLE2", [{ resource: "resource", permissions: ["permission2"] }], true);

        expect(await rbac.hasPermission(SECOND.address, "resource", "permission1")).to.be.false;
        expect(await rbac.hasPermission(SECOND.address, "resource", "permission2")).to.be.false;

        await rbac.grantRoles(SECOND.address, ["ROLE1", "ROLE2"]);

        expect(await rbac.getUserRoles(SECOND.address)).to.deep.equal(["ROLE1", "ROLE2"]);
        expect(await rbac.hasPermission(SECOND.address, "resource", "permission1")).to.be.true;
        expect(await rbac.hasPermission(SECOND.address, "resource", "permission2")).to.be.true;

        await rbac.revokeRoles(SECOND.address, ["ROLE2"]);

        expect(await rbac.getUserRoles(SECOND.address)).to.deep.equal(["ROLE1"]);
        expect(await rbac.hasPermission(SECOND.address, "resource", "permission1")).to.be.true;
        expect(await rbac.hasPermission(SECOND.address, "resource", "permission2")).to.be.false;
      });

      it("should check that MASTER has all permissions", async () => {
        expect(await rbac.hasPermission(OWNER.address, "resource", "permission")).to.be.true;
        expect(await rbac.hasPermission(OWNER.address, "", "")).to.be.true;
      });

      it("should revoke master role", async () => {
        await rbac.revokeRoles(OWNER.address, ["MASTER"]);

        expect(await rbac.getUserRoles(OWNER.address)).to.deep.equal([]);
        expect(await rbac.hasPermission(OWNER.address, "resource", "permission")).to.be.false;
        expect(await rbac.hasPermission(OWNER.address, "", "")).to.be.false;
      });
    });

    describe("disallowed permissions", async () => {
      it("should grant roles with disallowed permissions (1)", async () => {
        await rbac.addPermissionsToRole(
          "ROLE",
          [{ resource: "resource", permissions: ["permission1", "permission2"] }],
          true,
        );
        await rbac.grantRoles(SECOND.address, ["ROLE"]);

        expect(await rbac.hasPermission(SECOND.address, "resource", "permission2")).to.be.true;
        expect(await rbac.hasPermission(SECOND.address, "resource", "permission1")).to.be.true;

        await rbac.addPermissionsToRole("ROLE", [{ resource: "resource", permissions: ["permission2"] }], false);

        expect(await rbac.getUserRoles(SECOND.address)).to.deep.equal(["ROLE"]);

        expect(await rbac.hasPermission(SECOND.address, "resource", "permission2")).to.be.false;
        expect(await rbac.hasPermission(SECOND.address, "resource", "permission1")).to.be.true;
      });

      it("should grant roles with disallowed permissions (2)", async () => {
        await rbac.addPermissionsToRole("ROLE1", [{ resource: "resource", permissions: ["permission"] }], true);
        await rbac.grantRoles(SECOND.address, ["ROLE1"]);

        expect(await rbac.hasPermission(SECOND.address, "resource", "permission")).to.be.true;

        await rbac.addPermissionsToRole("ROLE2", [{ resource: "resource", permissions: ["permission"] }], false);
        await rbac.grantRoles(SECOND.address, ["ROLE2"]);

        expect(await rbac.getUserRoles(SECOND.address)).to.deep.equal(["ROLE1", "ROLE2"]);
        expect(await rbac.hasPermission(SECOND.address, "resource", "permission")).to.be.false;
      });

      it("should disallow specific permission", async () => {
        expect(await rbac.hasPermission(OWNER.address, "resource", "permission")).to.be.true;

        await rbac.addPermissionsToRole("MASTER", [{ resource: "resource", permissions: ["permission"] }], false);

        expect(await rbac.hasPermission(OWNER.address, "resource", "permission")).to.be.false;
      });

      it("should disallow resource", async () => {
        expect(await rbac.hasPermission(OWNER.address, "resource", "permission")).to.be.true;

        await rbac.addPermissionsToRole("MASTER", [{ resource: "resource", permissions: ["*"] }], false);

        expect(await rbac.hasPermission(OWNER.address, "resource", "permission")).to.be.false;
        expect(await rbac.hasPermission(OWNER.address, "resource", "permission2")).to.be.false;
      });

      it("should disallow specific permission on all resources", async () => {
        expect(await rbac.hasPermission(OWNER.address, "resource", "permission")).to.be.true;

        await rbac.addPermissionsToRole("MASTER", [{ resource: "*", permissions: ["permission"] }], false);

        expect(await rbac.hasPermission(OWNER.address, "resource", "permission")).to.be.false;
        expect(await rbac.hasPermission(OWNER.address, "resource2", "permission")).to.be.false;
      });

      it("should disallow all permissions", async () => {
        expect(await rbac.hasPermission(OWNER.address, "resource", "permission")).to.be.true;

        await rbac.addPermissionsToRole("MASTER", [{ resource: "*", permissions: ["*"] }], false);

        expect(await rbac.hasPermission(OWNER.address, "resource", "permission")).to.be.false;
        expect(await rbac.hasPermission(OWNER.address, "resource2", "permission2")).to.be.false;
      });

      it("should revoke disallowing role", async () => {
        expect(await rbac.hasPermission(OWNER.address, "resource", "permission")).to.be.true;

        await rbac.addPermissionsToRole("ANTI_ROLE", [{ resource: "resource", permissions: ["permission"] }], false);
        await rbac.grantRoles(OWNER.address, ["ANTI_ROLE"]);

        expect(await rbac.hasPermission(OWNER.address, "resource", "permission")).to.be.false;

        await rbac.revokeRoles(OWNER.address, ["ANTI_ROLE"]);

        expect(await rbac.hasPermission(OWNER.address, "resource", "permission")).to.be.true;
      });
    });
  });

  describe("extreme roles", () => {
    it("should work correctly", async () => {
      await rbac.addPermissionsToRole("ROLE1", [{ resource: "*", permissions: ["permission"] }], true);
      await rbac.addPermissionsToRole("ROLE2", [{ resource: "resource", permissions: ["permission"] }], false);

      await rbac.grantRoles(SECOND.address, ["ROLE1", "ROLE2"]);

      expect(await rbac.hasPermission(SECOND.address, "resource", "permission")).to.be.false;
    });

    it("should work correctly (2)", async () => {
      await rbac.addPermissionsToRole("ROLE1", [{ resource: "*", permissions: ["*"] }], true);
      await rbac.addPermissionsToRole("ROLE2", [{ resource: "resource", permissions: ["*"] }], false);

      await rbac.grantRoles(SECOND.address, ["ROLE1", "ROLE2"]);

      expect(await rbac.hasPermission(SECOND.address, "resource", "permission")).to.be.false;
    });

    it("should work correctly (3)", async () => {
      await rbac.addPermissionsToRole("ROLE1", [{ resource: "resource", permissions: ["*"] }], true);
      await rbac.addPermissionsToRole("ROLE2", [{ resource: "*", permissions: ["*"] }], false);

      await rbac.grantRoles(SECOND.address, ["ROLE1", "ROLE2"]);

      expect(await rbac.hasPermission(SECOND.address, "resource", "permission")).to.be.false;
    });
  });

  describe("access", () => {
    it("should not call these functions without permission", async () => {
      await expect(rbac.connect(SECOND).grantRoles(OWNER.address, ["ROLE"]))
        .to.be.revertedWithCustomError(rbac, "NoPermissionForResource")
        .withArgs(SECOND.address, "CREATE", "RBAC_RESOURCE");

      await expect(rbac.connect(SECOND).revokeRoles(OWNER.address, ["MASTER"]))
        .to.be.revertedWithCustomError(rbac, "NoPermissionForResource")
        .withArgs(SECOND.address, "DELETE", "RBAC_RESOURCE");

      await expect(
        rbac
          .connect(SECOND)
          .addPermissionsToRole("ROLE", [{ resource: "resource", permissions: ["permission"] }], true),
      )
        .to.be.revertedWithCustomError(rbac, "NoPermissionForResource")
        .withArgs(SECOND.address, "CREATE", "RBAC_RESOURCE");

      await expect(
        rbac
          .connect(SECOND)
          .removePermissionsFromRole("ROLE", [{ resource: "resource", permissions: ["permission"] }], false),
      )
        .to.be.revertedWithCustomError(rbac, "NoPermissionForResource")
        .withArgs(SECOND.address, "DELETE", "RBAC_RESOURCE");
    });
  });
});
