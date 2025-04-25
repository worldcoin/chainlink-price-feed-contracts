// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28;

import "forge-std/src/Script.sol";
import "../src/ChainlinkPriceFeedUSD.sol";

contract DeployProduction is Script {
    function run() external {
        address verifierProxyAddress = 0xd61ceB4521453F147C58d22879B4ec539331F851;
        address usdcAddress = 0x79A02482A880bCE3F13e09Da970dC34db4CD24d1;
        address pairAddress;
        bytes32 feedId;
        string memory pairName;

        // Deploy BTC/USD
        pairAddress = 0x03C7054BCB39f7b2e5B2c7AcB37583e32D70Cfa3;
        feedId = 0x00037da06d56d083fe599397a4769a042d63aa73dc4ef57709d31e9971a5b439;
        pairName = "BTC/USD";
        deployPriceFeed(pairAddress, usdcAddress, payable(verifierProxyAddress), feedId, pairName, 18);
    }

    function deployPriceFeed(
        address pairAddress,
        address usdcAddress,
        address verifierProxyAddress,
        bytes32 feedId,
        string memory pairName,
        uint8 decimals
    )
        internal
    {
        vm.startBroadcast();
        new ChainlinkPriceFeed(pairAddress, usdcAddress, payable(verifierProxyAddress), feedId, pairName, decimals);
        vm.stopBroadcast();
    }
}
