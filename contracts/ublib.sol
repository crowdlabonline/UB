// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

    struct Subscription
    {
        address subscriber;
        uint256 start;
        uint256 end;
    }

    struct Post
    {
        uint256 Type;
        string Title;
        string Summary;
        string Content;
        address Author;
        uint256 TimeStamp;
        string Aux;
    }


abstract contract UBLib
{
    address _creator;
    modifier onlyCreator()
    {
        require(msg.sender == _creator, "Only creator may use this feature");
        _;
    }


    uint256 constant MANAGER_TOKEN_ID = 1;
    uint256 constant AUTHOR_TOKEN_ID = 1 << 1;
    uint256 constant SUBSCRIBER_TOKEN_ID = 1 << 128;

    uint256 constant MANAGER_PERCENTAGE = 95;
}