// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IPriceSource } from "./interfaces/IPriceSource.sol";

/**
 * @title  UpgradableOracle
 * @notice An oracle which allows changing the source.
 */
contract UpgradableOracle {

    IPriceSource public source;

    constructor() {
    }

    function latestAnswer() external view returns (int256) {
        return source.latestAnswer();
    }

    function decimals() external view returns (uint8) {
        return source.decimals();
    }

}
