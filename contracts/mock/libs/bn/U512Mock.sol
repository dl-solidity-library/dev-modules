// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {call512, uint512, U512} from "../../../libs/bn/U512.sol";

contract U512Mock {
    using U512 for *;

    function copy(
        uint256 u256_
    )
        external
        pure
        returns (
            uint512 pointerOriginal_,
            uint512 pointerCopy_,
            bytes memory valueOriginal_,
            bytes memory valueCopy_
        )
    {
        pointerOriginal_ = U512.fromUint256(u256_);
        valueOriginal_ = U512.toBytes(pointerOriginal_);

        pointerCopy_ = U512.copy(pointerOriginal_);
        valueCopy_ = U512.toBytes(pointerCopy_);
    }

    function assign(
        uint256 u256_
    )
        external
        pure
        returns (
            uint512 pointerOriginal_,
            uint512 pointerAssign_,
            bytes memory valueOriginal_,
            bytes memory valueAssign_
        )
    {
        pointerOriginal_ = U512.fromUint256(u256_);
        valueOriginal_ = U512.toBytes(pointerOriginal_);

        pointerAssign_ = U512.fromUint256(0);

        U512.assign(pointerOriginal_, pointerAssign_);
        valueAssign_ = U512.toBytes(pointerAssign_);
    }

    function isNull(uint512 pointer_) external pure returns (bool isNull_) {
        return U512.isNull(pointer_);
    }

    function eq(bytes memory aBytes_, bytes memory bBytes_) external view returns (bool eq_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        return U512.eq(a_, b_);
    }

    function eqU256(bytes memory aBytes_, uint256 u256_) external view returns (bool eq_) {
        uint512 a_ = U512.fromBytes(aBytes_);

        return U512.eqU256(a_, u256_);
    }

    function cmp(bytes memory aBytes_, bytes memory bBytes_) external view returns (int256) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        return U512.cmp(a_, b_);
    }

    function mod(
        bytes memory aBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        // uint256 gasBefore_ = gasleft();
        uint512 result_ = U512.mod(call_, a_, m_);

        // console.log("mod gas: ", gasBefore_ - gasleft());

        return result_.toBytes();
    }

    function modAlloc(
        bytes memory aBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        return U512.mod(a_, m_).toBytes();
    }

    function modAssign(
        bytes memory aBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        U512.modAssign(call_, a_, m_);

        return a_.toBytes();
    }

    function modAssignTo(
        bytes memory aBytes_,
        bytes memory mBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.modAssignTo(call_, a_, m_, to_);

        return to_.toBytes();
    }

    function modinv(
        bytes memory aBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        // uint256 gasBefore_ = gasleft();
        uint512 result_ = U512.modinv(call_, a_, m_);

        // console.log("modinv gas: ", gasBefore_ - gasleft());

        return result_.toBytes();
    }

    function modinvAlloc(
        bytes memory aBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        return U512.modinv(a_, m_).toBytes();
    }

    function modinvAssign(
        bytes memory aBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        U512.modinvAssign(call_, a_, m_);

        return a_.toBytes();
    }

    function modinvAssignTo(
        bytes memory aBytes_,
        bytes memory mBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.modinvAssignTo(call_, a_, m_, to_);

        return to_.toBytes();
    }

    function add(
        bytes memory aBytes_,
        bytes memory bBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        // uint256 gasBefore_ = gasleft();
        uint512 result_ = U512.add(a_, b_);

        // console.log("add gas: ", gasBefore_ - gasleft());

        return result_.toBytes();
    }

    function addAssign(
        bytes memory aBytes_,
        bytes memory bBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        U512.addAssign(a_, b_);

        return a_.toBytes();
    }

    function addAssignTo(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.addAssignTo(a_, b_, to_);

        return to_.toBytes();
    }

    function sub(
        bytes memory aBytes_,
        bytes memory bBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        // uint256 gasBefore_ = gasleft();
        uint512 result_ = U512.sub(a_, b_);

        // console.log("sub gas: ", gasBefore_ - gasleft());

        return result_.toBytes();
    }

    function subAssign(
        bytes memory aBytes_,
        bytes memory bBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        U512.subAssign(a_, b_);

        return a_.toBytes();
    }

    function subAssignTo(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.subAssignTo(a_, b_, to_);

        return to_.toBytes();
    }

    function mul(
        bytes memory aBytes_,
        bytes memory bBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        // uint256 gasBefore_ = gasleft();
        uint512 result_ = U512.mul(a_, b_);

        // console.log("mul gas: ", gasBefore_ - gasleft());

        return result_.toBytes();
    }

    function mulAssign(
        bytes memory aBytes_,
        bytes memory bBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        U512.mulAssign(a_, b_);

        return a_.toBytes();
    }

    function mulAssignTo(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.mulAssignTo(a_, b_, to_);

        return to_.toBytes();
    }

    function modadd(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        // uint256 gasBefore_ = gasleft();
        uint512 result_ = U512.modadd(call_, a_, b_, m_);

        // console.log("modadd gas: ", gasBefore_ - gasleft());

        return result_.toBytes();
    }

    function modaddAlloc(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        return U512.modadd(a_, b_, m_).toBytes();
    }

    function modaddAssign(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        U512.modaddAssign(call_, a_, b_, m_);

        return a_.toBytes();
    }

    function modaddAssignTo(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.modaddAssignTo(call_, a_, b_, m_, to_);

        return to_.toBytes();
    }

    function redadd(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        // uint256 gasBefore_ = gasleft();
        uint512 result_ = U512.redadd(call_, a_, b_, m_);

        // console.log("redadd gas: ", gasBefore_ - gasleft());

        return result_.toBytes();
    }

    function redaddAlloc(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        return U512.redadd(a_, b_, m_).toBytes();
    }

    function redaddAssign(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        U512.redaddAssign(call_, a_, b_, m_);

        return a_.toBytes();
    }

    function redaddAssignTo(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.redaddAssignTo(call_, a_, b_, m_, to_);

        return to_.toBytes();
    }

    function modsub(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        // uint256 gasBefore_ = gasleft();
        uint512 result_ = U512.modsub(call_, a_, b_, m_);

        // console.log("modsub gas: ", gasBefore_ - gasleft());

        return result_.toBytes();
    }

    function modsubAlloc(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        return U512.modsub(a_, b_, m_).toBytes();
    }

    function modsubAssign(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        U512.modsubAssign(call_, a_, b_, m_);

        return a_.toBytes();
    }

    function modsubAssignTo(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.modsubAssignTo(call_, a_, b_, m_, to_);

        return to_.toBytes();
    }

    function redsub(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        // uint256 gasBefore_ = gasleft();
        uint512 result_ = U512.redsub(call_, a_, b_, m_);

        // console.log("redsub gas: ", gasBefore_ - gasleft());

        return result_.toBytes();
    }

    function redsubAlloc(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        return U512.redsub(a_, b_, m_).toBytes();
    }

    function redsubAssign(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        U512.redsubAssign(call_, a_, b_, m_);

        return a_.toBytes();
    }

    function redsubAssignTo(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.redsubAssignTo(call_, a_, b_, m_, to_);

        return to_.toBytes();
    }

    function modmul(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        // uint256 gasBefore_ = gasleft();
        uint512 result_ = U512.modmul(call_, a_, b_, m_);

        // console.log("modmul gas: ", gasBefore_ - gasleft());

        return result_.toBytes();
    }

    function modmulAlloc(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        return U512.modmul(a_, b_, m_).toBytes();
    }

    function modmulAssign(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        U512.modmulAssign(call_, a_, b_, m_);

        return a_.toBytes();
    }

    function modmulAssignTo(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.modmulAssignTo(call_, a_, b_, m_, to_);

        return to_.toBytes();
    }

    function modexp(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        // uint256 gasBefore_ = gasleft();
        uint512 result_ = U512.modexp(call_, a_, b_, m_);

        // console.log("modexp gas: ", gasBefore_ - gasleft());

        return result_.toBytes();
    }

    function modexpAlloc(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        return U512.modexp(a_, b_, m_).toBytes();
    }

    function modexpAssign(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        U512.modexpAssign(call_, a_, b_, m_);

        return a_.toBytes();
    }

    function modexpAssignTo(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.modexpAssignTo(call_, a_, b_, m_, to_);

        return to_.toBytes();
    }

    function modexpU256(
        bytes memory aBytes_,
        uint256 b_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        // uint256 gasBefore_ = gasleft();
        uint512 result_ = U512.modexpU256(call_, a_, b_, m_);

        // console.log("modexpU256 gas: ", gasBefore_ - gasleft());

        return result_.toBytes();
    }

    function modexpU256Alloc(
        bytes memory aBytes_,
        uint256 b_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        return U512.modexpU256(a_, b_, m_).toBytes();
    }

    function modexpU256Assign(
        bytes memory aBytes_,
        uint256 b_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        U512.modexpU256Assign(call_, a_, b_, m_);

        return a_.toBytes();
    }

    function modexpU256AssignTo(
        bytes memory aBytes_,
        uint256 b_,
        bytes memory mBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.modexpU256AssignTo(call_, a_, b_, m_, to_);

        return to_.toBytes();
    }

    function moddiv(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        // uint256 gasBefore_ = gasleft();
        uint512 result_ = U512.moddiv(call_, a_, b_, m_);

        // console.log("moddiv gas: ", gasBefore_ - gasleft());

        return result_.toBytes();
    }

    function moddivAlloc(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        return U512.moddiv(a_, b_, m_).toBytes();
    }

    function moddivAssign(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        U512.moddivAssign(call_, a_, b_, m_);

        return a_.toBytes();
    }

    function moddivAssignTo(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        call512 call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.moddivAssignTo(call_, a_, b_, m_, to_);

        return to_.toBytes();
    }

    function and(
        bytes memory aBytes_,
        bytes memory bBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        return U512.and(a_, b_).toBytes();
    }

    function andAssign(
        bytes memory aBytes_,
        bytes memory bBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        // uint256 gasBefore_ = gasleft();
        U512.andAssign(a_, b_);

        // console.log("and gas: ", gasBefore_ - gasleft());

        return a_.toBytes();
    }

    function andAssignTo(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.andAssignTo(a_, b_, to_);

        return to_.toBytes();
    }

    function or(
        bytes memory aBytes_,
        bytes memory bBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        return U512.or(a_, b_).toBytes();
    }

    function orAssign(
        bytes memory aBytes_,
        bytes memory bBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        // uint256 gasBefore_ = gasleft();
        U512.orAssign(a_, b_);

        // console.log("or gas: ", gasBefore_ - gasleft());

        return a_.toBytes();
    }

    function orAssignTo(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.orAssignTo(a_, b_, to_);

        return to_.toBytes();
    }

    function xor(
        bytes memory aBytes_,
        bytes memory bBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        // uint256 gasBefore_ = gasleft();
        uint512 result_ = U512.xor(a_, b_);

        // console.log("xor gas: ", gasBefore_ - gasleft());

        return result_.toBytes();
    }

    function xorAssign(
        bytes memory aBytes_,
        bytes memory bBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        U512.xorAssign(a_, b_);

        return a_.toBytes();
    }

    function xorAssignTo(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.xorAssignTo(a_, b_, to_);

        return to_.toBytes();
    }

    function not(bytes memory aBytes_) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);

        // uint256 gasBefore_ = gasleft();
        uint512 result_ = U512.not(a_);

        // console.log("not gas: ", gasBefore_ - gasleft());

        return result_.toBytes();
    }

    function notAssign(bytes memory aBytes_) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);

        U512.notAssign(a_);

        return a_.toBytes();
    }

    function notAssignTo(
        bytes memory aBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.notAssignTo(a_, to_);

        return to_.toBytes();
    }

    function shl(bytes memory aBytes_, uint8 b_) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);

        // uint256 gasBefore_ = gasleft();
        uint512 result_ = U512.shl(a_, b_);

        // console.log("shl gas: ", gasBefore_ - gasleft());

        return result_.toBytes();
    }

    function shlAssign(
        bytes memory aBytes_,
        uint8 b_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);

        U512.shlAssign(a_, b_);

        return a_.toBytes();
    }

    function shlAssignTo(
        bytes memory aBytes_,
        uint8 b_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.shlAssignTo(a_, b_, to_);

        return to_.toBytes();
    }

    function shr(bytes memory aBytes_, uint8 b_) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);

        // uint256 gasBefore_ = gasleft();
        uint512 result_ = U512.shr(a_, b_);

        // console.log("shr gas: ", gasBefore_ - gasleft());

        return result_.toBytes();
    }

    function shrAssign(
        bytes memory aBytes_,
        uint8 b_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);

        U512.shrAssign(a_, b_);

        return a_.toBytes();
    }

    function shrAssignTo(
        bytes memory aBytes_,
        uint8 b_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.shrAssignTo(a_, b_, to_);

        return to_.toBytes();
    }
}
