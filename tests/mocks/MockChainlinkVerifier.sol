// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockChainlinkVerifier {
    bytes private returnValue;

    // Default constructor
    constructor() {
        // Set default return value
        returnValue =
            hex"000365f820b0633946b78232bb91a97cf48100c426518e732465c3a050edb9f100000000000000000000000000000000000000000000000000000000680ae4c500000000000000000000000000000000000000000000000000000000680ae4c50000000000000000000000000000000000000000000000000000a43edb1645b5000000000000000000000000000000000000000000000000004bdde13435e2ac00000000000000000000000000000000000000000000000000000000683271c50000000000000000000000000000000000000000000000000cc0e107f5301bb80000000000000000000000000000000000000000000000000cbf418cae5754480000000000000000000000000000000000000000000000000cc248d8b7b68800";
    }

    // Function to set a new return value
    function setReturnValue(bytes memory _newReturnValue) external {
        returnValue = _newReturnValue;
    }

    // Main verify function that will return the configured value
    function verify(bytes memory, bytes memory) external payable returns (bytes memory) {
        return returnValue;
    }
}
