// SPDX-License-Identifier: MIT


pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ublib.sol";

    struct AuthorRating
    {
        uint256 upVotes;
        uint256 downVotes;
    }


contract ETC is
ERC1155,
Ownable,
Pausable,
ERC1155Supply,
ERC2981,
ReentrancyGuard,
UBLib
{
    modifier onlyManager()
    {
        require(this.balanceOf(msg.sender, MANAGER_TOKEN_ID) > 0, "Only manager may use this feature");
        _;
    }

    modifier onlyStaff()
    {
        require(this.balanceOf(msg.sender, MANAGER_TOKEN_ID) > 0 || this.balanceOf(msg.sender, AUTHOR_TOKEN_ID) > 0, "Only staff member may do this");
        _;
    }

    constructor() ERC1155("")
    {
        _creator = msg.sender;
        _mint(_creator, MANAGER_TOKEN_ID, 1, "");
    }

    address private _ubContract;
    uint256 private _royalties = 1000;

    //Subscription[] private _subscriptions;
    mapping(address => Subscription) subscribers;
    mapping(address => uint256) private authorStatus;
    mapping(address => string) private authorAlias; // May be used for storing the name of an author.
    mapping(address => AuthorRating) private authorRating;
    mapping(address => mapping(address => uint256)) private subscriberVotes; //subscriber->author->value

    string private managerAlias;

    uint256 private managerBalance;
    uint256 private creatorBalance;

    uint256 public subscriptionPrice = 4000000000000000000; // Price per 10 days

    string public name = "Editor Token Contract v1";
    string public symbol = "ETCv1";

    function getCreatorBalance() external view onlyCreator returns(uint256)
    {
        return creatorBalance;
    }

    function getManagerBalance() external view onlyManager returns(uint256)
    {
        return managerBalance;
    }

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override
    {
        super._afterTokenTransfer(operator, from, to, ids, amounts, data);
        for(uint256 i = 0; i < ids.length; i++)
        {
            if(ids[i] == SUBSCRIBER_TOKEN_ID)
            {
                subscribers[to] = subscribers[from];
                delete subscribers[from];
            }
        }
    }

    function setUBContract(address newContractAddress) external onlyOwner
    {
        _ubContract = newContractAddress;
    }

    function UBContract()external view returns (address)
    {
        return _ubContract;
    }

    function setManagerAlias(string memory newAlias) external onlyManager
    {
        managerAlias = newAlias;
    }

    function getManagerAlias() external view returns (string memory)
    {
        return managerAlias;
    }

    function setAuthorAlias(string memory newAlias) external onlyStaff
    {
        authorAlias[msg.sender] = newAlias;
    }

    function getAuthorAlias(address authorAddress) external view returns (string memory)
    {
        return authorAlias[authorAddress];
    }

    function setSubscriptionPrice(uint256 newPrice) external onlyManager
    {
        subscriptionPrice = newPrice;
    }

    event NewSubscription(address indexed subscriber, uint256 indexed periodCount, uint256 subscriptionEnd);

    function subscribe(uint256 periodCount) external payable nonReentrant
    {
        require(msg.value >= periodCount * subscriptionPrice, "Insufficient payment for subscription.");
        _mint(msg.sender, SUBSCRIBER_TOKEN_ID, 1, "");
        Subscription memory newSubscription = Subscription(msg.sender, block.timestamp, block.timestamp + 864000 * periodCount);
        subscribers[msg.sender] = newSubscription;
        emit NewSubscription(msg.sender, periodCount, newSubscription.end);
        managerBalance += (msg.value / 100) * MANAGER_PERCENTAGE;
        creatorBalance += msg.value - managerBalance;
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

    event AuthorAdded(address indexed authorAddress, address indexed manager);

    function addAuthor(address authorAddress) external onlyManager
    {
        if (balanceOf(authorAddress, AUTHOR_TOKEN_ID) < 1)
            _mint(authorAddress, AUTHOR_TOKEN_ID, 1, "");
        authorStatus[authorAddress] = 1;
        emit AuthorAdded(authorAddress, msg.sender);
    }

    event AuthorRemoved(address indexed author);

    function removeAuthor(address authorAddress) external onlyManager
    {
        authorStatus[authorAddress] = 0;
        emit AuthorRemoved(authorAddress);
    }

    function verifyAuthor(address author) public view returns (uint256)
    {
        uint256 ab = balanceOf(author, AUTHOR_TOKEN_ID);
        if (ab < 1 || authorStatus[author] == 0)
            return 0;
        return 1;
    }

    function verifySubscription(address subscriber) public view returns (uint256)
    {
        uint256 sb = balanceOf(subscriber, SUBSCRIBER_TOKEN_ID);
        if (sb < 1)
            return 0;
        Subscription memory s = subscribers[subscriber];
        if (s.end <= block.timestamp)
            return 0;
        return 1;
    }

    function setURI(string memory newUri) external onlyCreator
    {
        _setURI(newUri);
    }

    function uri(uint256 tokenId) public view override returns (string memory)
    {
        string memory extendedTokenId = Strings.toHexString(tokenId, 32);
        if (tokenId == 0)
            return super.uri(0);
        return string.concat(super.uri(0), trim0x(extendedTokenId), ".json");
    }

    function contractURI() public view returns(string memory)
    {
        return string.concat(super.uri(0), "UB_ETC.json");
    }

    function trim0x(string memory str) private pure returns (string memory)
    {
        bytes memory b = bytes(str);
        bytes memory r = new bytes(b.length - 2);

        for (uint256 i = 0; i < b.length - 2; i++)
        {
            r[i] = b[i + 2];
        }

        return string(r);
    }

    function setRoyaltiesRecipient(address newRecipient) external onlyCreator
    {
        _creator = newRecipient;
    }

    function setRoyaltyPercent(uint256 newPercent) external onlyCreator
    {
        _royalties = newPercent * 100;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view override returns (address recipient, uint256 amount)
    {
        return (_creator, (_salePrice * _royalties) / 10000);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    whenNotPaused
    override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
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

    function upVoteAuthor(address author) external
    {
        if (1 == verifySubscription(msg.sender))
        {
            if (subscriberVotes[msg.sender][author] != 1)
            {
                if (1 == verifyAuthor(author))
                {
                    if (subscriberVotes[msg.sender][author] == 2)
                        authorRating[author].downVotes--;
                    authorRating[author].upVotes++;
                    subscriberVotes[msg.sender][author] = 1;
                }
                else
                {
                    revert("Address does not belong to an author");
                }
            }
        }
        else
        {
            revert("Only subscribers may vote");
        }
    }

    function downVoteAuthor(address author) external
    {
        if (1 == verifySubscription(msg.sender))
        {
            if (subscriberVotes[msg.sender][author] != 2)
            {
                if (1 == verifyAuthor(author))
                {
                    if (subscriberVotes[msg.sender][author] == 1)
                        authorRating[author].upVotes--;
                    authorRating[author].downVotes++;
                    subscriberVotes[msg.sender][author] = 2;
                }
                else
                {
                    revert("Address does not belong to an author");
                }
            }
        }
        else
        {
            revert("Only subscribers may vote");
        }
    }

    function getAuthorRating(address author) external view returns (AuthorRating memory)
    {
        return authorRating[author];
    }

}