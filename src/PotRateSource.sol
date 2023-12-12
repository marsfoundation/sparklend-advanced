// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IRateSource } from "./interfaces/IRateSource.sol";

interface IPot {
    function dsr() external view returns (uint256);
}

contract PotRateSource is IRateSource {

    IPot public immutable pot;

    constructor(address _pot) {
        pot = IPot(_pot);
    }

    function getAPR() external override view returns (uint256) {
        return (pot.dsr() - 1e27) * 365 days;
    }

}
