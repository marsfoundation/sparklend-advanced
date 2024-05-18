// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IRateSource } from "../../src/interfaces/IRateSource.sol";

contract RateSourceMock is IRateSource {

    uint256 public rate;
    uint8   public decimals;

    constructor(uint256 _rate, uint8 _decimals) {
        rate     = _rate;
        decimals = _decimals;
    }

    function setRate(uint256 _rate) external {
        rate = _rate;
    }

    function getAPR() external override view returns (uint256) {
        return rate;
    }

    function setDecimals(uint8 _decimals) external {
        decimals = _decimals;
    }

}
