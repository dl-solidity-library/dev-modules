// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {ADiamondStorage} from "./ADiamondStorage.sol";

/**
 * @notice The Diamond standard module
 *
 * This is a custom, yet fully compatible, implementation of a [Diamond Proxy standard](https://eips.ethereum.org/EIPS/eip-2535).
 *
 * This contract acts as a highest level contract of that standard. Contrary to the EIP-2535, storage
 * is defined in a separate contract that the facets have to inherit from, not use an internal library.
 *
 * As a convention, view and pure function are defined in the storage contract while function that modify state, in
 * the facet itself.
 *
 * If you wish to add a receive() function, attach a "0x00000000" selector to a facet that has such a function.
 */
contract Diamond is ADiamondStorage {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    enum FacetAction {
        Add,
        Replace,
        Remove
    }

    struct Facet {
        address facetAddress;
        FacetAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(Facet[] facets, address initFacet, bytes initData);

    error FacetIsZeroAddress();
    error InitializationReverted(address initFacet, bytes initData);
    error NoSelectorsProvided();
    error NoFacetForSelector(bytes4 selector);

    error SelectorAlreadyAdded(address faucet, bytes4 selector);
    error SelectorFromAnotherFacet(bytes4 selector);
    error SelectorIsAlreadyInThisFaucet(bytes4 selector, address facet);
    error SelectorNotRegistered(bytes4 selector);

    /**
     * @notice The payable fallback function that delegatecall's the facet with associated selector
     */
    // solhint-disable-next-line
    fallback() external payable virtual {
        address facet_ = facetAddress(msg.sig);

        if (facet_ == address(0)) revert SelectorNotRegistered(msg.sig);

        _beforeFallback(facet_, msg.sig);

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result_ := delegatecall(gas(), facet_, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result_
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @notice Add/replace/remove any number of functions and optionally execute a function with delegatecall
     * @param facets_ Contains the facet addresses and function selectors
     * @param initFacet_ The address of the contract or facet to execute initData_
     * @param initData_ A function call, including function selector and arguments initData_ is executed with delegatecall on initFacet_
     */
    function _diamondCut(
        Facet[] memory facets_,
        address initFacet_,
        bytes memory initData_
    ) internal virtual {
        for (uint256 i; i < facets_.length; i++) {
            bytes4[] memory _functionSelectors = facets_[i].functionSelectors;
            address _facetAddress = facets_[i].facetAddress;

            FacetAction _action = facets_[i].action;

            if (_action == FacetAction.Add) {
                _addFacet(_facetAddress, _functionSelectors);
            } else if (_action == FacetAction.Remove) {
                _removeFacet(_facetAddress, _functionSelectors);
            } else {
                _updateFacet(_facetAddress, _functionSelectors);
            }
        }

        emit DiamondCut(facets_, initFacet_, initData_);

        _initializeDiamondCut(initFacet_, initData_);
    }

    /**
     * @notice The internal function to add facets to a diamond (aka diamondCut())
     * @param facet_ the implementation address
     * @param selectors_ the function selectors the implementation has
     */
    function _addFacet(address facet_, bytes4[] memory selectors_) internal virtual {
        _checkIfFacetIsValid(facet_, selectors_);

        DStorage storage _ds = _getDiamondStorage();

        for (uint256 i = 0; i < selectors_.length; i++) {
            if (_ds.selectorToFacet[selectors_[i]] != address(0))
                revert SelectorAlreadyAdded(_ds.selectorToFacet[selectors_[i]], selectors_[i]);

            _ds.selectorToFacet[selectors_[i]] = facet_;
            _ds.facetToSelectors[facet_].add(bytes32(selectors_[i]));
        }

        _ds.facets.add(facet_);
    }

    /**
     * @notice The internal function to remove facets from the diamond
     * @param facet_ the implementation to be removed. The facet itself will be removed only if there are no selectors left
     * @param selectors_ the selectors of that implementation to be removed
     */
    function _removeFacet(address facet_, bytes4[] memory selectors_) internal virtual {
        _checkIfFacetIsValid(facet_, selectors_);

        DStorage storage _ds = _getDiamondStorage();

        for (uint256 i = 0; i < selectors_.length; i++) {
            if (_ds.selectorToFacet[selectors_[i]] != facet_)
                revert SelectorFromAnotherFacet(selectors_[i]);

            _ds.selectorToFacet[selectors_[i]] = address(0);
            _ds.facetToSelectors[facet_].remove(bytes32(selectors_[i]));
        }

        if (_ds.facetToSelectors[facet_].length() == 0) {
            _ds.facets.remove(facet_);
        }
    }

    /**
     * @notice The internal function to update the facet selectors of the diamond
     * @param facet_ the facet to update
     * @param selectors_ the selectors of the facet
     */
    function _updateFacet(address facet_, bytes4[] memory selectors_) internal virtual {
        _checkIfFacetIsValid(facet_, selectors_);

        DStorage storage _ds = _getDiamondStorage();

        for (uint256 i; i < selectors_.length; i++) {
            bytes4 selector_ = selectors_[i];
            address oldFacet_ = facetAddress(selector_);

            if (oldFacet_ == facet_) revert SelectorIsAlreadyInThisFaucet(selector_, facet_);
            if (oldFacet_ == address(0)) revert NoFacetForSelector(selector_);

            // replace old facet address
            _ds.selectorToFacet[selector_] = facet_;
            _ds.facetToSelectors[facet_].add(bytes32(selector_));

            // remove old facet address
            _ds.facetToSelectors[oldFacet_].remove(bytes32(selector_));

            if (_ds.facetToSelectors[oldFacet_].length() == 0) {
                _ds.facets.remove(oldFacet_);
            }
        }

        _ds.facets.add(facet_);
    }

    /**
     * @notice The internal function to initialize the diamond cut.
     * @param initFacet_ the address of the contract or facet to execute initData_
     * @param initData_ a function call, including function selector and arguments, to be executed with delegatecall on initFacet_
     */
    function _initializeDiamondCut(address initFacet_, bytes memory initData_) internal virtual {
        if (initFacet_ == address(0)) {
            return;
        }

        // solhint-disable-next-line
        (bool success_, bytes memory err_) = initFacet_.delegatecall(initData_);

        if (!success_) {
            if (err_.length == 0) revert InitializationReverted(initFacet_, initData_);

            // bubble up error
            // @solidity memory-safe-assembly
            assembly {
                revert(add(32, err_), mload(err_))
            }
        }
    }

    function _checkIfFacetIsValid(
        address facet_,
        bytes4[] memory selectors_
    ) internal pure virtual {
        if (facet_ == address(0)) revert FacetIsZeroAddress();
        if (selectors_.length == 0) revert NoSelectorsProvided();
    }

    function _beforeFallback(address facet_, bytes4 selector_) internal virtual {}
}
