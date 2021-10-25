//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MyAuction {
    
    struct AuctionItem{
        uint256 id;
        uint256 tokenId;
        uint256 startPrice;
        address tokenAddress;
        address payable owner;
        uint expirationTime;
        bool ended;
    }
    
    AuctionItem[] public auctions;
    
    mapping(uint256 => mapping(address => uint256)) bids;
    
    modifier notOwner(address tokenAddress, uint256 tokenId){
        IERC721 tokenContract = IERC721(tokenAddress);
        require(tokenContract.ownerOf(tokenId) != msg.sender, "Owner can not bid");
        _;
    }
    
    modifier HasTransferApproval(address tokenAddress, uint256 tokenId){
        IERC721 tokenContract = IERC721(tokenAddress);
        require(tokenContract.getApproved(tokenId) == address(this));
        _;
    }
    
     modifier OnlyItemOwner(address tokenAddress, uint256 tokenId){
        IERC721 tokenContract = IERC721(tokenAddress);
        require(tokenContract.ownerOf(tokenId) == msg.sender);
        _;
    }
    
    modifier ItemExists(uint256 id){
        require(id < auctions.length && auctions[id].id == id, "Could not find Item");
        _;
    }
    
    mapping(uint => address) public highestBidder;
    mapping(uint => uint) public highestBid;
    // address public highestBidder;
    // uint public highestBid;
    
    event AuctionCreated(uint256 id, uint256 tokenId, address tokenAddress, uint256 price, uint endTime);
    event HighestBidIncreased(uint id, address bidder, uint amount);
    event AuctionEnded(uint id, address winner, uint amount);
    
    function placeBid(uint id, uint price) public payable ItemExists(id) notOwner(auctions[id].tokenAddress, auctions[id].tokenId) {
        
         require(block.timestamp <= auctions[id].expirationTime,  "Auction already ended.");
         require(price> highestBid[id], "There already is a higher bid.");
         
        //  uint currentBid = bids[id][msg.sender].add(msg.value);
         
        //  if (highestBid[id] != 0) {
        //     bids[id][msg.sender] += price;
        // }
        
         uint currentBid = bids[id][msg.sender] += price;
        // uint currentBid = bids[id][msg.sender].add(price);
        require(currentBid > highestBid[id], "bid should be higher");
        // set the currentBid links with msg.sender
        bids[id][msg.sender] = currentBid;
        // update the highest price
        highestBid[id] = currentBid;
        highestBidder[id] = msg.sender;
        
        highestBid[id] = price;
        emit HighestBidIncreased(id, msg.sender, price);
    
    }
     
    
    function AuctionAdded(uint256 tokenId, address tokenAddress, uint price, uint time) OnlyItemOwner(tokenAddress, tokenId) HasTransferApproval(tokenAddress, tokenId) external returns (uint256){
        // require(bids[tokenAddress][tokenId] == 0);
    
        uint256 newItemId = auctions.length;
        auctions.push(AuctionItem(newItemId, tokenId, price, tokenAddress, payable (msg.sender), block.timestamp + time, false));
        // bids[newItemId][msg.sender] = 0;    
        
        assert(auctions[newItemId].id == newItemId);
        emit AuctionCreated(newItemId, tokenId, tokenAddress, price, time);
        return newItemId;
        
    }
    
    function withdraw(uint id, address payable recipient) public returns (bool) {
        uint amount = bids[id][recipient];
        if (amount > 0) {
            
            bids[id][recipient] = 0;

            if (!recipient.send(amount)) {
                // No need to call throw here, just reset the amount owing
                bids[id][msg.sender] = amount;
                return false;
            }
        }
        return true;
    }
    
    function auctionEnd(uint id) ItemExists(id) HasTransferApproval(auctions[id].tokenAddress, auctions[id].tokenId) public {
        // 1. Conditions
        require(block.timestamp >=  auctions[id].expirationTime, "Auction not yet ended.");
        require(!auctions[id].ended, "auctionEnd has already been called.");

        // 2. Effects
        auctions[id].ended = true;

        // 3. Interaction
        IERC721(auctions[id].tokenAddress).safeTransferFrom(auctions[id].owner, highestBidder[id], auctions[id].tokenId);
        auctions[id].owner.transfer(highestBid[id]);
        
        emit AuctionEnded(id, highestBidder[id], highestBid[id]);
    }
}