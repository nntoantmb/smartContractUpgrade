// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./NFTUpgradeable.sol";

contract NFTUpgradeable_V2 is NFTUpgradeable {
    function version() pure public override virtual returns(string memory){
        return 'V2';
    }

}