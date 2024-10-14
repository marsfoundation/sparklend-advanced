// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IRateSource } from "./interfaces/IRateSource.sol";

interface ISUSDS {
    function ssr() external view returns (uint256);
}

contract SSRRateSource is IRateSource {

    ISUSDS public immutable susds;

    constructor(address _susds) {
        susds = ISUSDS(_susds);
    }

    function getAPR() external override view returns (uint256) {
        return (susds.ssr() - 1e27) * 365 days;
    }

    function decimals() external pure returns (uint8) {
        return 27;
    }

}
