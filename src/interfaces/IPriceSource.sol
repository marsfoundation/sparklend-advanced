// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

/// @notice Subset of Chainlink Aggregator interface
interface IPriceSource {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}
