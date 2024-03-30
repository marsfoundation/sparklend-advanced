// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IPriceSource } from "./interfaces/IPriceSource.sol";

interface ILidoStakedEth {
    function getPooledEthByShares(uint256 shares) external view returns (uint256);
}

/**
 *  @title WSTETHExchangeRateOracle
 *  @dev   Provides wstETH / USD by multiplying the wstETH exchange rate by ETH / USD.
 *         This provides a "non-market" price. Any depeg event will be ignored.
 */
contract WSTETHExchangeRateOracle {

    /// @notice Lido staked eth token contract.
    ILidoStakedEth public immutable steth;

    /// @notice The price source for ETH / USD.
    IPriceSource public immutable ethSource;

    constructor(address _steth, address _ethSource) {
        // 8 decimals required as AaveOracle assumes this
        require(IPriceSource(_ethSource).decimals() == 8, "WSTETHExchangeRateOracle/invalid-decimals");
        
        steth     = ILidoStakedEth(_steth);
        ethSource = IPriceSource(_ethSource);
    }

    function latestAnswer() external view returns (int256) {
        int256 ethUsd       = ethSource.latestAnswer();
        int256 exchangeRate = int256(steth.getPooledEthByShares(1e18));

        if (ethUsd <= 0 || exchangeRate <= 0) {
            return 0;
        }

        return exchangeRate * ethUsd / 1e18;
    }

    function decimals() external pure returns (uint8) {
        return 8;
    }

}
