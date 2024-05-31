// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

interface IRateSource {
    function getAPR() external view returns (uint256);
    function decimals() external view returns (uint8);
}
