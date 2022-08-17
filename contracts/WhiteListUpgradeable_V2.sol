// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./WhiteListUpgradeable.sol";

contract WhiteListUpgradeable_V2 is WhiteListUpgradeable {
    function version() pure public override virtual returns(string memory){
        return 'V2';
    }

}