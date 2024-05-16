// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

interface IPriceSource {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);
}
