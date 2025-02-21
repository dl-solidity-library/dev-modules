// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @notice The SBT module
 */
interface ISBT {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @notice The function to return the name of the contract
     * @return the name of the contract
     */
    function name() external view returns (string memory);

    /**
     * @notice The function to return the symbol of the contract
     * @return the symbol of the contract
     */
    function symbol() external view returns (string memory);

    /**
     * @notice The function to check the existence of the token
     * @param tokenId_ the token to check
     * @return true if `tokenId_` exists, false otherwise
     */
    function tokenExists(uint256 tokenId_) external view returns (bool);

    /**
     * @notice The function to get the balance of the user
     * @param owner_ the user to get the balance of
     * @return the user's balance
     */
    function balanceOf(address owner_) external view returns (uint256);

    /**
     * @notice The function to get a user's token by its ordinal id
     * @param owner_ the user to get the token of
     * @param index_ the id of the token in the user's array
     * @return the token the user owns
     */
    function tokenOf(address owner_, uint256 index_) external view returns (uint256);

    /**
     * @notice The function to get ALL the tokens of a user. Be careful, O(n) complexity
     * @param owner_ the user to get the tokens of
     * @return the array of tokens the user owns
     */
    function tokensOf(address owner_) external view returns (uint256[] memory);

    /**
     * @notice The function to get the owner of a token
     * @param tokenId_ the token to get the owner of
     * @return address of an owner or `address(0)` if token does not exist
     */
    function ownerOf(uint256 tokenId_) external view returns (address);

    /**
     * @notice The function to get the base URI of all the tokens
     * @return the base URI
     */
    function baseURI() external view returns (string memory);

    /**
     * @notice The function to get the token URI.
     *
     * - If individual token URI is set, it gets returned.
     * - Otherwise if base URI is set, the concatenation of base URI and token URI gets returned.
     * - Otherwise `""` gets returned
     *
     * @param tokenId_ the token to get the URI of
     * @return the URI of the token
     */
    function tokenURI(uint256 tokenId_) external view returns (string memory);
}
