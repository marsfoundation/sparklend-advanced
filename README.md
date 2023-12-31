# SparkLend Advanced Contracts

This repository contains advanced features to improve SparkLend beyond the core contracts. This repository is mostly focused on improving security and automating governance processes.

## Available Contracts

### Oracles

Please note all these oracles are designed for consumption by `AaveOracle` which assumes 8 decimal places.

[FixedPriceOracle](https://github.com/marsfoundation/sparklend-advanced/blob/master/src/FixedPriceOracle.sol): A hardcoded oracle price that never changes. Used for: DAI market

[CappedOracle](https://github.com/marsfoundation/sparklend-advanced/blob/master/src/CappedOracle.sol): Returns `min(market price, hardcoded max price)`. Used for: USDC/USDT markets

### Custom Interest Rate Strategies

[VariableBorrowInterestRateStrategy](https://github.com/marsfoundation/sparklend-advanced/blob/master/src/VariableBorrowInterestRateStrategy.sol): Modified version of `DefaultReserveInterestRateStrategy` that removes the stable borrow logic.

[RateTargetBaseInterestRateStrategy](https://github.com/marsfoundation/sparklend-advanced/blob/master/src/RateTargetBaseInterestRateStrategy.sol): Overridden version of `VariableBorrowInterestRateStrategy` that sets the base variable borrow rate to match an external rate source with a fixed spread. Used for: DAI market

[RateTargetKinkInterestRateStrategy](https://github.com/marsfoundation/sparklend-advanced/blob/master/src/RateTargetKinkInterestRateStrategy.sol): Overridden version of `VariableBorrowInterestRateStrategy` that sets the variable slope 1 rate to match an external rate source with a fixed spread. Used for: ETH/USDC/USDT markets

### Rate Sources

[PotRateSource](https://github.com/marsfoundation/sparklend-advanced/blob/master/src/PotRateSource.sol): Adapter to convert DSR into APR which can be consumed by one of the rate target interest rate strategies. Used for: DAI/USDC/USDT markets

## Usage

```bash
forge build
```

## Test

```bash
forge test
```

***
*The IP in this repository was assigned to Mars SPC Limited in respect of the MarsOne SP*
