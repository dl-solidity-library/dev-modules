// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {VerifierHelper} from "../../../../libs/zkp/VerifierHelper.sol";

contract VerifierHelperMock {
    using VerifierHelper for address;

    function verifyProofStruct(
        address verifier_,
        uint256[] memory pubSignals_,
        VerifierHelper.ProofPoints memory proofPoints_
    ) external view returns (bool) {
        return verifier_.verifyProof(pubSignals_, proofPoints_);
    }

    function verifyProof(
        address verifier_,
        uint256[] memory pubSignals_,
        uint256[2] memory a_,
        uint256[2][2] memory b_,
        uint256[2] memory c_
    ) external view returns (bool) {
        return verifier_.verifyProof(pubSignals_, a_, b_, c_);
    }

    function verifyProofStructSafe(
        address verifier_,
        uint256[] memory pubSignals_,
        VerifierHelper.ProofPoints memory proofPoints_,
        uint256 pubSignalsCount_
    ) external view returns (bool) {
        return verifier_.verifyProofSafe(pubSignals_, proofPoints_, pubSignalsCount_);
    }

    function verifyProofSafe(
        address verifier_,
        uint256[] memory pubSignals_,
        uint256[2] memory a_,
        uint256[2][2] memory b_,
        uint256[2] memory c_,
        uint256 pubSignalsCount_
    ) external view returns (bool) {
        return verifier_.verifyProofSafe(pubSignals_, a_, b_, c_, pubSignalsCount_);
    }
}
