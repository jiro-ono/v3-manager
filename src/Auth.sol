// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import "openzeppelin/access/Ownable2Step.sol";

abstract contract Auth is Ownable2Step {

    event SetTrusted(address indexed user, bool isTrusted);

    mapping(address => bool) public trusted;

    error OnlyTrusted();

    modifier onlyTrusted() {
        if (!trusted[msg.sender]) revert OnlyTrusted();
        _;
    }

    constructor(address trustedUser) {
        trusted[trustedUser] = true;
        emit SetTrusted(trustedUser, true);
    }

    function setTrusted(address user, bool isTrusted) external onlyOwner {
        trusted[user] = isTrusted;
        emit SetTrusted(user, isTrusted);
    }

}