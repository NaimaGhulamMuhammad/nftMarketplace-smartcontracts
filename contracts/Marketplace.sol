//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Marketplace is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    // address payable owner;
    // uint256 listingPrice = 0.05 ether;

    constructor() {
        // owner = payable(msg.sender);
    }
    mapping(uint256 => uint256) public itemIds;
    
    struct MarketItem{
        uint256 id;
        address tokenAddress;
        uint256 tokenId;
        address payable seller;
        uint256 royalty;
        uint256 price;
        bool sold;
    }
    
    MarketItem[] public items;

    mapping(address => mapping(uint => bool)) activeItems;

    event marketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        uint256 royalty,
        uint256 price,
        bool sold
    );
    
    event marketItemSold(uint256 id,uint256 tokenId, address buyer, address owner,address seller, uint256 price, uint256 royalty);

    modifier OnlyItemOwner(address tokenAddress, uint256 tokenId){
        IERC721 tokenContract = IERC721(tokenAddress);
        require(tokenContract.ownerOf(tokenId) == msg.sender);
        _;
    }

    modifier HasTransferApproval(address tokenAddress, uint256 tokenId){
        IERC721 tokenContract = IERC721(tokenAddress);
        require(tokenContract.getApproved(tokenId) == address(this));
        _;
    }

    modifier ItemExists(uint256 id){
        require(id < items.length && items[id].id == id, "Could not find Item");
        _;
    }

    modifier IsForSale(uint256 id){
        require(items[id].sold == false, "Item is already sold");
        _;
    }
    
    mapping(uint256 => address) public itemOwner;
    
    function addMarketItem(uint256 tokenId, address tokenAddress, uint256 price, uint256 royalty) OnlyItemOwner(tokenAddress, tokenId) HasTransferApproval(tokenAddress, tokenId)  external returns (uint256){
        require(activeItems[tokenAddress][tokenId] == false, "Item is already up for sale");
       
        // IERC721 tokenContract = IERC721(tokenAddress);
        // address owner = tokenContract.ownerOf(tokenId);
        
        uint256 newItemId = items.length;
        
        
        items.push(MarketItem(newItemId, tokenAddress, tokenId, payable(msg.sender), royalty, price, false));
        activeItems[tokenAddress][tokenId] = true;

        assert(items[newItemId].id == newItemId);
        emit marketItemCreated(newItemId, tokenAddress, tokenId ,msg.sender, royalty,  price, false);
        return newItemId;
    }
    
   
    
    function sellMarketItem(uint256 id) payable external nonReentrant ItemExists(id) IsForSale(id) HasTransferApproval(items[id].tokenAddress, items[id].tokenId){
        require(msg.value >= items[id].price, "Not enough Funds sent");
        require(msg.sender != items[id].seller, "seller should not be the buyer");
        
        
        uint royalty = (items[id].royalty * items[id].price)/100;
        uint price = items[id].price - royalty;
        
        // itemOwner[id] = items[id].seller;
        IERC721 tokenContract = IERC721(items[id].tokenAddress);
        address owner = tokenContract.ownerOf(items[id].tokenId);
        
        items[id].sold = true;
        activeItems[items[id].tokenAddress][items[id].tokenId] = false;
        IERC721(items[id].tokenAddress).safeTransferFrom(items[id].seller, msg.sender, items[id].tokenId);
        items[id].seller.transfer(price);
        
        // items[id].seller = payable(msg.sender);
        payable(owner).transfer(royalty);
        itemOwner[id] = owner;
        emit marketItemSold(id, items[id].tokenId, msg.sender, owner, items[id].seller , price, royalty);
    }

}