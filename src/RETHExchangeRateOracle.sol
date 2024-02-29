// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IPriceSource } from "./interfaces/IPriceSource.sol";

interface IRocketPoolStakedEth {
    function getExchangeRate() external view returns (uint256);
}

/**
 *  @title RETHExchangeRateOracle
 *  @dev   Provides rETH / USD by multiplying the rETH exchange rate by ETH / USD.
 *         This provides a "non-market" price. Any depeg event will be ignored.
 */
contract RETHExchangeRateOracle {

    /// @notice RocketPool staked eth token contract.
    IRocketPoolStakedEth public immutable reth;

    /// @notice The price source for ETH / USD.
    IPriceSource public immutable ethSource;

    constructor(address _reth, address _ethSource) {
        // 8 decimals required as AaveOracle assumes this
        require(IPriceSource(_ethSource).decimals() == 8, "RETHExchangeRateOracle/invalid-decimals");
        
        reth      = IRocketPoolStakedEth(_reth);
        ethSource = IPriceSource(_ethSource);
    }

    function latestAnswer() external view returns (int256) {
        int256 ethUsd       = ethSource.latestAnswer();
        int256 exchangeRate = int256(reth.getExchangeRate());

        if (ethUsd <= 0 || exchangeRate <= 0) {
            return 0;
        }

        return exchangeRate * ethUsd / 1e18;
    }

    function decimals() external pure returns (uint8) {
        return 8;
    }

}
