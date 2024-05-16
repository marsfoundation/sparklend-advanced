// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { Ownable } from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import { AggregatorV3Interface } from "./interfaces/AggregatorV3Interface.sol";

/**
 * @title  MorphoUpgradableOracle
 * @notice An oracle which allows changing the source.
 * @dev    Can be used as a Morpho Blue price feed. Interface is restricted to what Morpho Blue needs.
 *         https://github.com/morpho-org/morpho-blue-oracles/blob/07a9a6988b0e1b316ac2fa97ec62ad485fbd0041/src/morpho-chainlink/libraries/ChainlinkDataFeedLib.sol
 */
contract MorphoUpgradableOracle is Ownable {

    event SourceChanged(address indexed oldSource, address indexed newSource);

    AggregatorV3Interface public source;

    constructor(address _owner, address _source) Ownable(_owner) {
        source = AggregatorV3Interface(_source);
        emit SourceChanged(address(0), _source);
    }

    function setSource(address _source) external onlyOwner {
        emit SourceChanged(address(source), _source);
        source = AggregatorV3Interface(_source);
    }

    function decimals() external view returns (uint8) {
        return source.decimals();
    }

    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        (, answer,,,) = source.latestRoundData();
    }

}
