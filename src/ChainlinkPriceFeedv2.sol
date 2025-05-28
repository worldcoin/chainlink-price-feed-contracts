// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28;

import { IVerifierProxy } from "./interfaces/IVerifierProxy.sol";

/**
 * @title PriceFeedStorage
 * @dev Contract for storing and updating price feed data for a single asset pair
 */
contract ChainlinkPriceFeed {
    error InvalidParameter(string parameterName);
    error FeedIdMismatch();
    error PriceDataInvalid();
    error PriceFeedNotAvailable();
    error PriceFeedExpired();
    error OldPriceFeedUpdate(uint256 previousTimestamp, uint256 updateTimestamp);
    error InvalidPriceFeedVersion(uint16 version);
    error NotImplemented();

    struct PriceFeedData {
        int192 price;
        uint32 timestamp;
        uint32 expiresAt;
    }

    // Address of the pair token (always the first token in the pair)
    address public immutable PAIR_TOKEN_ADDRESS;

    // Address of the WETH token (always the second token in the pair)
    address public immutable WETH_TOKEN_ADDRESS;

    // Address of the VerifierProxy contract
    IVerifierProxy public immutable VERIFIER_PROXY;

    // The unique identifier for this price feed
    bytes32 public immutable FEED_ID;

    // Expected version of the report
    uint16 public immutable EXPECTED_VERSION = 2;

    // Human-readable name of the pair (e.g., "WLD/USD")
    string public PAIR_NAME;

    // Number of decimals for the price feed
    uint8 public immutable DECIMALS;

    // Price feed data for the single pair
    PriceFeedData public priceFeed;

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

    /**
     * @dev Constructor to set the WETH address, Pair Token address, VerifierProxy address, feed ID and pair name
     * @param _pairAddress The address of the pair token token
     * @param _wethAddress The address of the WETH token
     * @param _verifierProxyAddress The address of the VerifierProxy contract
     * @param _feedId The unique identifier for this price feed
     * @param _pairName Human-readable name of the pair (e.g., "ETH/USD")
     * @param _decimals Number of decimals for the price feed
     */
    constructor(
        address _pairAddress,
        address _wethAddress,
        address payable _verifierProxyAddress,
        bytes32 _feedId,
        string memory _pairName,
        uint8 _decimals
    ) {
        if (_wethAddress == address(0)) revert InvalidParameter("WETH_Address");
        if (_pairAddress == address(0)) revert InvalidParameter("Pair_Token_Address");
        if (_verifierProxyAddress == address(0)) revert InvalidParameter("Verifier_Proxy");
        if (_feedId == bytes32(0)) revert InvalidParameter("Feed_Id");
        if (bytes(_pairName).length == 0) revert InvalidParameter("Pair_Name");
        if (_decimals == 0) revert InvalidParameter("Decimals");

        WETH_TOKEN_ADDRESS = _wethAddress;
        PAIR_TOKEN_ADDRESS = _pairAddress;
        VERIFIER_PROXY = IVerifierProxy(_verifierProxyAddress);
        FEED_ID = _feedId;
        PAIR_NAME = _pairName;
        DECIMALS = _decimals;
    }

    function updatePriceData(
        bytes memory verifySignedReportRequest,
        bytes memory parameterPayload
    )
        public
        returns (bytes memory)
    {
        // Decode the reportData from verifySignedReportRequest
        (, bytes memory reportData) = abi.decode(verifySignedReportRequest, (bytes32[3], bytes));

        // Extract report version from reportData
        uint16 reportVersion = (uint16(uint8(reportData[0])) << 8) | uint16(uint8(reportData[1]));

        if (reportVersion != EXPECTED_VERSION) revert InvalidPriceFeedVersion(reportVersion);

        // @dev - Value should be the nativeFee required to verify the reportData on-chain
        // We're passing 0 here just for testing purpose, make sure to adapt to your case.
        bytes memory returnDataCall = VERIFIER_PROXY.verify{ value: 0 }(verifySignedReportRequest, parameterPayload);

        // Decode the return data into the specified structure
        (
            bytes32 receivedFeedId,
            uint32 validFromTimestamp,
            uint32 observationsTimestamp,
            ,
            ,
            uint32 expiresAt,
            int192 price
        ) = abi.decode(returnDataCall, (bytes32, uint32, uint32, uint192, uint192, uint32, int192));

        // Don't allow updating to an old price
        if (observationsTimestamp < priceFeed.timestamp) {
            revert OldPriceFeedUpdate(priceFeed.timestamp, observationsTimestamp);
        }

        // Verify that the feed ID matches the contract's feed ID
        if (receivedFeedId != FEED_ID) revert FeedIdMismatch();

        // Validate the expiration times
        if (block.timestamp < validFromTimestamp || block.timestamp > expiresAt) revert PriceDataInvalid();

        // Store the price feed data
        priceFeed = PriceFeedData({ price: price, timestamp: observationsTimestamp, expiresAt: expiresAt });

        emit AnswerUpdated(price, block.timestamp, block.timestamp);

        return returnDataCall;
    }

    /**
     * @dev Get the latest price feed data
     * @return roundId The round ID
     * @return answer The latest price
     * @return startedAt The timestamp when the round started
     * @return updatedAt The timestamp of the latest update
     * @return answeredInRound The round ID in which the answer was computed
     */
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        if (priceFeed.timestamp == 0) revert PriceFeedNotAvailable();
        if (block.timestamp > priceFeed.expiresAt) revert PriceFeedExpired();

        roundId = priceFeed.timestamp;
        answer = priceFeed.price;
        startedAt = priceFeed.timestamp;
        updatedAt = priceFeed.timestamp;
        answeredInRound = priceFeed.timestamp;

        return (roundId, answer, startedAt, updatedAt, answeredInRound);
    }

    /**
     * @dev Returns the description of the price feed
     * @return The human-readable name of the pair (e.g., "WLD/USD")
     */
    function description() external view returns (string memory) {
        return PAIR_NAME;
    }

    /**
     * @dev Returns the version of the price feed
     * @return The version number
     */
    function version() external pure returns (uint256) {
        return 1;
    }

    /**
     * @dev Returns the number of decimals for the price feed
     * @return The number of decimals
     */
    function decimals() external view returns (uint8) {
        return DECIMALS;
    }

    /**
     * @dev Get historical price feed data for a specific round
     * @param _roundId The round ID to get data for
     * @return roundId The round ID
     * @return answer The price
     * @return startedAt The timestamp when the round started
     * @return updatedAt The timestamp of the update
     * @return answeredInRound The round ID in which the answer was computed
     */
    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        revert NotImplemented();
    }
}
