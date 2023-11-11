// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IPriceSource {
    function latestAnswer() external view returns (int256);
}

contract CappedOracle {

    IPriceSource public immutable source;
    int256       public immutable maxPrice;

    constructor(address _source, int256 _maxPrice) {
        require(_maxPrice > 0, "CappedOracle/invalid-max-price");
        
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
