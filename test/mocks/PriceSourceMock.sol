// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

contract PriceSourceMock {

    int256 public latestAnswer;

    constructor(int256 _latestAnswer) {
        latestAnswer = _latestAnswer;
    }

    function setLatestAnswer(int256 _latestAnswer) external {
        latestAnswer = _latestAnswer;
    }

}