// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IPriceSource } from "./interfaces/IPriceSource.sol";

interface IWrappedEtherfiRestakedEth {
    function getRate() external view returns (uint256);
}

/**
 *  @title WEETHExchangeRateOracle
 *  @dev   Provides weETH / USD by multiplying the weETH exchange rate by ETH / USD.
 *         This provides a "non-market" price. Any depeg event will be ignored.
 */
contract WEETHExchangeRateOracle {

    /// @notice Etherfi restaked wrapped eth token contract.
    IWrappedEtherfiRestakedEth public immutable weeth;

    /// @notice The price source for ETH / USD.
    IPriceSource public immutable ethSource;

    constructor(address _weeth, address _ethSource) {
        // 8 decimals required as AaveOracle assumes this
        require(IPriceSource(_ethSource).decimals() == 8, "WEETHExchangeRateOracle/invalid-decimals");
        
        weeth     = IWrappedEtherfiRestakedEth(_weeth);
        ethSource = IPriceSource(_ethSource);
    }

    function latestAnswer() external view returns (int256) {
        int256 ethUsd       = ethSource.latestAnswer();
        int256 exchangeRate = int256(weeth.getRate());

        if (ethUsd <= 0 || exchangeRate <= 0) {
            return 0;
        }

        return exchangeRate * ethUsd / 1e18;
    }

    function decimals() external pure returns (uint8) {
        return 8;
    }

}
