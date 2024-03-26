// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IRateSource } from "./interfaces/IRateSource.sol";

/**
 * @title  CappedFallbackRateSource
 * @notice Wraps another rate source, caps the rate and protects against reverts with a fallback value.
 */
contract CappedFallbackRateSource is IRateSource {

    IRateSource public immutable source;
    uint256     public immutable lowerBound;
    uint256     public immutable upperBound;
    uint256     public immutable defaultRate;

    constructor(
        address _source,
        uint256 _lowerBound,
        uint256 _upperBound,
        uint256 _defaultRate
    ) {
        require(_lowerBound <= _upperBound,                                 "CappedFallbackRateSource/invalid-bounds");
        require(_defaultRate >= _lowerBound && _defaultRate <= _upperBound, "CappedFallbackRateSource/invalid-default-rate");

        source      = IRateSource(_source);
        lowerBound  = _lowerBound;
        upperBound  = _upperBound;
        defaultRate = _defaultRate;
    }

    function getAPR() external override view returns (uint256) {
        uint256 sourceRate = defaultRate;

        try source.getAPR() returns (uint256 rate) {
            sourceRate = rate;
        } catch {
            // Ignore the error and use the default rate
        }

        if (sourceRate < lowerBound) {
            return lowerBound;
        } else if (sourceRate > upperBound) {
            return upperBound;
        } else {
            return sourceRate;
        }
    }

    function decimals() external view override returns (uint8) {
        return source.decimals();
    }

}
