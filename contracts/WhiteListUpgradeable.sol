// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract WhiteListUpgradeable is Initializable, UUPSUpgradeable, OwnableUpgradeable {

    mapping(address => bool) public isWhiteList;
    event setStatusUser(
        address user,
        bool status
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __UUPSUpgradeable_init();
        __Ownable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    // custom
    function version() pure public virtual returns(string memory){
        return 'V1';
    }

    
    /** 
        * set status user in white list data
        * @param user: address of user
        * @param status: status of user in white list
    */
    function setWhiteListUser(address user, bool status) external onlyOwner  {
        isWhiteList[user] = status;
        emit setStatusUser(user, status);
    }

    /** 
        * set status list off user in white list data
        * @param listUser: lisst address of user
        * @param status: status of user in white list
    */
    function setWhiteListUser(address[] calldata listUser, bool status) external onlyOwner  {
        for (uint i = 0; i < listUser.length; i++) {
            isWhiteList[listUser[i]] = status;
            emit setStatusUser(listUser[i], status);
        }
    }
}