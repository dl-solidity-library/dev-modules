// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {ReturnDataProxy} from "../../../libs/utils/ReturnDataProxy.sol";

struct Entry {
    bytes data;
    string name;
    uint256 value;
}

contract RawReturnMock {
    uint256 private _mirror;

    error Test();

    receive() external payable {}

    function setMirror(uint256 mirror_) external {
        _mirror = mirror_;
    }

    function getMirror() external view returns (uint256) {
        return _mirror;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function revertWithMessage() external pure {
        revert Test();
    }

    function getEntry() external pure returns (Entry memory) {
        return Entry({data: abi.encodePacked("0x12345678"), name: "test", value: 12345678});
    }

    function getEntryWithArgs(
        bytes memory args_,
        string memory name_,
        uint256 value_
    ) external pure returns (Entry memory) {
        return Entry({data: args_, name: name_, value: value_});
    }
}

contract ReturnDataProxyMock {
    using ReturnDataProxy for address;

    uint256 private _back;
    address private _target;

    constructor(address target_) {
        _target = target_;
    }

    function callWithValue() external payable {
        _target.yield(msg.value, hex"");
    }

    function callSetMirror(uint256 mirror_) external {
        _target.yield(abi.encodeWithSelector(RawReturnMock.setMirror.selector, mirror_));
    }

    function delegateCallSetMirror(uint256 mirror_) external {
        _target.delegateYield(abi.encodeWithSelector(RawReturnMock.setMirror.selector, mirror_));
    }

    function callRevertWithMessage() external {
        _target.yield(abi.encodeWithSelector(RawReturnMock.revertWithMessage.selector));
    }

    function delegateCallRevertWithMessage() external {
        _target.delegateYield(abi.encodeWithSelector(RawReturnMock.revertWithMessage.selector));
    }

    function staticCallGetEntry() external view returns (Entry memory) {
        _target.staticYield(abi.encodeWithSelector(RawReturnMock.getEntry.selector));
    }

    function staticCallRevertWithMessage() external view {
        _target.staticYield(abi.encodeWithSelector(RawReturnMock.revertWithMessage.selector));
    }

    function staticCallWithArgs(
        bytes memory args_,
        string memory name_,
        uint256 value_
    ) external view returns (Entry memory) {
        _target.staticYield(
            abi.encodeWithSelector(RawReturnMock.getEntryWithArgs.selector, args_, name_, value_)
        );
    }

    function getBack() external view returns (uint256) {
        return _back;
    }
}
