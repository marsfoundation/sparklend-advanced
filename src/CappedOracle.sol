// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IPriceSource {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);
}

contract CappedOracle {

    IPriceSource public immutable source;
    int256       public immutable maxPrice;

    constructor(address _source, int256 _maxPrice) {
        // 8 decimals required as AaveOracle assumes this
        require(IPriceSource(_source).decimals() == 8, "CappedOracle/invalid-decimals");
        require(_maxPrice > 0,                         "CappedOracle/invalid-max-price");
        
        source   = IPriceSource(_source);
        maxPrice = _maxPrice;
    }

    function latestAnswer() external view returns (int256) {
        int256 price = source.latestAnswer();

        return price < maxPrice ? price : maxPrice;
    }

    function decimals() external pure returns (uint8) {
        return 8;
    }

}
