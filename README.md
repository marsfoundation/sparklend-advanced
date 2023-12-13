# SparkLend Advanced Contracts

This repository contains advanced features to improve SparkLend beyond the core contracts. This repository is mostly focused on improving security and automating governance processes.

## Available Contracts

### Oracles

[FixedPriceOracle](https://github.com/marsfoundation/sparklend-advanced/blob/master/src/FixedPriceOracle.sol): A hardcoded oracle price that never changes. Uses: DAI market

[CappedOracle](https://github.com/marsfoundation/sparklend-advanced/blob/master/src/CappedOracle.sol): Returns `min(market price, hardcoded max price)`. Uses: USDC/USDT markets

### Custom Interest Rate Strategies

[VariableBorrowInterestRateStrategy](https://github.com/marsfoundation/sparklend-advanced/blob/master/src/VariableBorrowInterestRateStrategy.sol): Modified version of `DefaultReserveInterestRateStrategy` that removes the stable borrow logic.

[RateTargetBaseInterestRateStrategy](https://github.com/marsfoundation/sparklend-advanced/blob/master/src/RateTargetBaseInterestRateStrategy.sol): Overriden version of `VariableBorrowInterestRateStrategy` that sets the base variable borrow rate to match an external rate source with a fixed spread. Uses: DAI market

[RateTargetKinkInterestRateStrategy](https://github.com/marsfoundation/sparklend-advanced/blob/master/src/RateTargetKinkInterestRateStrategy.sol): Overriden version of `VariableBorrowInterestRateStrategy` that sets the variable slope 1 rate to match an external rate source with a fixed spread. Uses: ETH/USDC/USDT markets

### Rate Sources

[PotRateSource](https://github.com/marsfoundation/sparklend-advanced/blob/master/src/PotRateSource.sol): Adapter to convert DSR into APR which can be consumed by one of the rate target interest rate strategies. Uses: DAI/USDC/USDT markets

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