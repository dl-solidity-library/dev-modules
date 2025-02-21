// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @notice The Diamond standard module
 *
 * This is the storage contract for the diamond proxy
 */
abstract contract ADiamondStorage {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice The struct slot where the storage is
     */
    bytes32 public constant DIAMOND_STORAGE_SLOT = keccak256("diamond.standard.diamond.storage");

    /**
     * @notice The storage of the Diamond proxy
     */
    struct DStorage {
        mapping(bytes4 => address) selectorToFacet;
        mapping(address => EnumerableSet.Bytes32Set) facetToSelectors;
        EnumerableSet.AddressSet facets;
    }

    struct FacetInfo {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /**
     * @notice The internal function to get the diamond proxy storage
     * @return _ds the struct from the DIAMOND_STORAGE_SLOT
     */
    function _getDiamondStorage() internal pure returns (DStorage storage _ds) {
        bytes32 slot_ = DIAMOND_STORAGE_SLOT;

        assembly {
            _ds.slot := slot_
        }
    }

    /**
     * @notice The function to get all the facets and their selectors
     * @return facets_ the array of FacetInfo
     */
    function facets() public view returns (FacetInfo[] memory facets_) {
        EnumerableSet.AddressSet storage _facets = _getDiamondStorage().facets;

        facets_ = new FacetInfo[](_facets.length());

        for (uint256 i = 0; i < facets_.length; i++) {
            address facet_ = _facets.at(i);

            facets_[i].facetAddress = facet_;
            facets_[i].functionSelectors = facetFunctionSelectors(facet_);
        }
    }

    /**
     * @notice The function to get all the selectors assigned to the facet
     * @param facet_ the facet to get assigned selectors of
     * @return selectors_ the array of assigned selectors
     */
    function facetFunctionSelectors(
        address facet_
    ) public view returns (bytes4[] memory selectors_) {
        EnumerableSet.Bytes32Set storage _f2s = _getDiamondStorage().facetToSelectors[facet_];

        selectors_ = new bytes4[](_f2s.length());

        for (uint256 i = 0; i < selectors_.length; i++) {
            selectors_[i] = bytes4(_f2s.at(i));
        }
    }

    /**
     * @notice The function to get all the facets of this diamond
     * @return facets_ the array of facets' addresses
     */
    function facetAddresses() public view returns (address[] memory facets_) {
        return _getDiamondStorage().facets.values();
    }

    /**
     * @notice The function to get associated facet by the selector
     * @param selector_ the selector
     * @return facet_ the associated facet address
     */
    function facetAddress(bytes4 selector_) public view returns (address facet_) {
        return _getDiamondStorage().selectorToFacet[selector_];
    }
}
