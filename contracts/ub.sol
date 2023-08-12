// SPDX-License-Identifier: MIT


pragma solidity ^0.8.18;


import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ublib.sol";

abstract contract ETContract
{
    function balanceOf(address account, uint256 tokenID) public view virtual returns (uint256);

    function verifySubscription(address subscriber) external view virtual returns (uint256);

    function verifyAuthor(address author) external view virtual returns (uint256);
}

contract UB is
ReentrancyGuard,
Ownable,
UBLib
{
    constructor()
    {
        _creator = msg.sender;
    }

    uint256 private constant POST_TYPE_DELETED = 0;
    uint256 private constant POST_TYPE_PUBLIC = 1;
    uint256 private constant POST_TYPE_SUBSCRIPTION = 1 << 1;
    uint256 private constant POST_TYPE_URL = 1 << 2;

    //address private _manager;

    address private _editorTokenContract;

    Post[] private _posts;

    uint256 private managerBalance;
    uint256 private creatorBalance;
    string public version = "1.0.0";

    string private creatorUIPackageURL = "";
    string private customUIPackageURL = "";
    string private documentationURL = "";

    string public name = "UncensoredBulletin v1";
    string public symbol = "UBv1";

    function getCreatorBalance() external view onlyCreator returns(uint256)
    {
        return creatorBalance;
    }

    function getManagerBalance() external view onlyManager returns(uint256)
    {
        return managerBalance;
    }

    function setDocumentationURL(string memory newUrl) external onlyCreator
    {
        documentationURL = newUrl;
    }

    function getDocumentationURL() external view returns (string memory)
    {
        return documentationURL;
    }

    function setCreatorUIPackageURL(string memory newUrl) external onlyCreator
    {
        creatorUIPackageURL = newUrl;
    }

    function getCreatorUIPackageURL() external view returns(string memory)
    {
        return creatorUIPackageURL;
    }

    function setCustomUIPackageURL(string memory newUrl)external onlyManager
    {
        customUIPackageURL = newUrl;
    }

    function getCustomUIPackageURL() external view returns(string memory)
    {
        return customUIPackageURL;
    }

    receive() external payable
    {
        managerBalance += (msg.value / 100) * MANAGER_PERCENTAGE;
        creatorBalance += msg.value - managerBalance;
    }

    fallback() external payable
    {
        managerBalance += (msg.value / 100) * MANAGER_PERCENTAGE;
        creatorBalance += msg.value - managerBalance;
    }


    function setETC(address editorTokenContract) external onlyCreator
    {
        require(editorTokenContract != address(0), "0 is not a valid address");
        _editorTokenContract = editorTokenContract;
    }

    function getETC() external view returns (address)
    {
        return _editorTokenContract;
    }

    event PostAdded(address indexed postAuthor, string indexed postTitle, uint256 indexed postType, uint256 postTimeStamp);

    function addPost(uint256 _type, string memory _title, string memory _summary, string memory _content, string memory _auxData) external
    {
        ETContract etc = ETContract(_editorTokenContract);
        uint256 managerTokenBalance = etc.balanceOf(msg.sender, MANAGER_TOKEN_ID);
        uint256 authorStatus = etc.verifyAuthor(msg.sender);

        require((0 != managerTokenBalance) || (0 != authorStatus), "You are not allowed to post");

        uint256 ts = block.timestamp;

        bytes memory titleBytes = bytes(_title);
        bytes memory summaryBytes = bytes(_summary);
        bytes memory contentBytes = bytes(_content);
        bytes memory auxBytes = bytes(_auxData);

        require((titleBytes.length <= 128) && (summaryBytes.length <= 256) && (contentBytes.length <= 1024) && (auxBytes.length <= 1024), "Title, summary, content or aux too long");

        Post memory newPost = Post(_type, _title, _summary, _content, msg.sender, ts, _auxData);
        _posts.push(newPost);
        emit PostAdded(msg.sender, _title, _type, ts);
    }

    function removePost(uint256 postIndex) external onlyManager
    {
        delete _posts[postIndex];
    }

    function totalPosts() external view returns (uint256)
    {
        return _posts.length;
    }

    function postAt(uint256 postIndex) external view returns (Post memory)
    {
        Post memory p = _posts[postIndex];
        if ((p.Type & POST_TYPE_SUBSCRIPTION) == POST_TYPE_SUBSCRIPTION)
        {
            ETContract etc = ETContract(_editorTokenContract);
            uint256 bypass = etc.balanceOf(msg.sender, MANAGER_TOKEN_ID) + etc.balanceOf(msg.sender, AUTHOR_TOKEN_ID);
            uint256 subscriptionVerified = etc.verifySubscription(msg.sender);
            require((bypass > 0) || (subscriptionVerified > 0), "You need a valid subscription to view this post");
        }

        return _posts[postIndex];
    }

    function creatorReward() external onlyCreator nonReentrant
    {
        require(creatorBalance > 0, "Creator balance is 0");
        payable(_creator).transfer(creatorBalance);
        creatorBalance = 0;
    }

    function withdraw() external onlyManager nonReentrant
    {
        require(managerBalance > 0, "Manager balance is 0");
        payable(msg.sender).transfer(managerBalance);
    }

    modifier onlyManager()
    {
        ETContract etc = ETContract(_editorTokenContract);
        require(etc.balanceOf(msg.sender, MANAGER_TOKEN_ID) > 0, "Only manager may use this feature");
        _;
    }

    function setCreatorAddress(address newAddress)external onlyCreator
    {
        _creator = newAddress;
    }

    function getUserStatus() external view returns (string memory)
    {
        ETContract etc = ETContract(_editorTokenContract);
        if (0 < etc.balanceOf(msg.sender, MANAGER_TOKEN_ID))
            return "manager";
        else if (0 < etc.balanceOf(msg.sender, AUTHOR_TOKEN_ID))
            return "author";
        else if (0 < etc.balanceOf(msg.sender, SUBSCRIBER_TOKEN_ID))
            return "subscriber";
        else if (msg.sender == _creator)
            return "creator";
        return "viewer";
    }

}
