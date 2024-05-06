// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { Ownable } from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import { IPriceSource } from "./interfaces/IPriceSource.sol";

/**
 * @title  UpgradableOracle
 * @notice An oracle which allows changing the source.
 * @dev    Can be used as a Morpho Blue price feed.
 */
contract UpgradableOracle is Ownable, IPriceSource {

    event SourceChanged(address indexed oldSource, address indexed newSource);

    IPriceSource public source;

    constructor(address _owner, address _source) Ownable(_owner) {
        source = IPriceSource(_source);
        emit SourceChanged(address(0), _source);
    }

    function setSource(address _source) external onlyOwner {
        emit SourceChanged(address(source), _source);
        source = IPriceSource(_source);
    }

    function latestAnswer() external view override returns (int256) {
        return source.latestAnswer();
    }

    function decimals() external view override returns (uint8) {
        return source.decimals();
    }

    function latestRoundData() external view override returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return source.latestRoundData();
    }

}
