// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28;

import "forge-std/src/Script.sol";
import "../src/ChainlinkPriceFeedv3.sol";

contract DeployProduction is Script {
    function run() external {
        address verifierProxyAddress = 0x6733e9106094b0C794e8E0297c96611fF60460Bf;
        address usdcAddress = 0x79A02482A880bCE3F13e09Da970dC34db4CD24d1;
        address pairAddress;
        bytes32 feedId;
        string memory pairName;

        // Deploy WLD/USD
        pairAddress = 0x2cFc85d8E48F8EAB294be644d9E25C3030863003;
        feedId = 0x000365f820b0633946b78232bb91a97cf48100c426518e732465c3a050edb9f1;
        pairName = "WLD/USD";
        deployPriceFeed(pairAddress, usdcAddress, payable(verifierProxyAddress), feedId, pairName, 18);

        // Deploy ETH/USD
        pairAddress = 0x4200000000000000000000000000000000000006;
        feedId = 0x000362205e10b3a147d02792eccee483dca6c7b44ecce7012cb8c6e0b68b3ae9;
        pairName = "ETH/USD";
        deployPriceFeed(pairAddress, usdcAddress, payable(verifierProxyAddress), feedId, pairName, 18);

        // Deploy BTC/USD
        pairAddress = 0x03C7054BCB39f7b2e5B2c7AcB37583e32D70Cfa3;
        feedId = 0x00039d9e45394f473ab1f050a1b963e6b05351e52d71e507509ada0c95ed75b8;
        pairName = "BTC/USD";
        deployPriceFeed(pairAddress, usdcAddress, payable(verifierProxyAddress), feedId, pairName, 18);

        // Deploy USDC/USD
        pairAddress = usdcAddress;
        feedId = 0x00038f83323b6b08116d1614cf33a9bd71ab5e0abf0c9f1b783a74a43e7bd992;
        pairName = "USDC/USD";
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
