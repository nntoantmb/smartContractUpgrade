// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MarketUpgradeable.sol";

contract MarketUpgradeable_V2 is MarketUpgradeable {
    function version() pure public override virtual returns(string memory){
        return 'V2';
    }

}