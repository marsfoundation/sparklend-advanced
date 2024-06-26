// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

contract PriceSourceMock {

    int256 public latestAnswer;
    uint8  public decimals;

    constructor(int256 _latestAnswer, uint8 _decimals) {
        latestAnswer = _latestAnswer;
        decimals     = _decimals;
    }

    function setLatestAnswer(int256 _latestAnswer) external {
        latestAnswer = _latestAnswer;
    }

    function setDecimals(uint8 _decimals) external {
        decimals = _decimals;
    }

    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (0, latestAnswer, 0, 0, 0);
    }

}
