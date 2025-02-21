// SPDX-License-Identifier: MIT
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/proxy/transparent/TransparentUpgradeableProxy.sol

pragma solidity ^0.8.21;

import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IAdminableProxy} from "../../interfaces/proxy/IAdminableProxy.sol";

/**
 * @notice This contract implements a proxy that is upgradeable by an admin.
 *
 * The implementation of this contract is based on OpenZeppelin's TransparentUpgradeableProxy.
 * The main change is in the constructor. While the original contract deploys an instance of ProxyAdmin
 * for every proxy, this implementation simply sets the specified address as the admin.
 * Additionally, an implementation function has been added.
 *
 * For more information about proxy logic, please refer to the OpenZeppelin documentation.
 */
contract AdminableProxy is ERC1967Proxy {
    // solhint-disable-previous-line immutable-vars-naming
    address private immutable _ADMIN;

    error ProxyDeniedAdminAccess();

    constructor(
        address logic_,
        address admin_,
        bytes memory data_
    ) payable ERC1967Proxy(logic_, data_) {
        _ADMIN = admin_;
        ERC1967Utils.changeAdmin(admin_);
    }

    function _fallback() internal virtual override {
        if (msg.sender == _ADMIN) {
            bytes4 selector_ = msg.sig;

            if (selector_ == IAdminableProxy.upgradeToAndCall.selector) {
                _dispatchUpgradeToAndCall();
            } else if (selector_ == IAdminableProxy.implementation.selector) {
                bytes memory returndata_ = _dispatchImplementation();

                assembly {
                    return(add(returndata_, 0x20), mload(returndata_))
                }
            } else {
                revert ProxyDeniedAdminAccess();
            }
        } else {
            super._fallback();
        }
    }

    function _dispatchUpgradeToAndCall() private {
        (address newImplementation_, bytes memory data_) = abi.decode(
            msg.data[4:],
            (address, bytes)
        );
        ERC1967Utils.upgradeToAndCall(newImplementation_, data_);
    }

    function _dispatchImplementation() private view returns (bytes memory) {
        return abi.encode(_implementation());
    }
}
