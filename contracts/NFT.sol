//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";

contract NFTMatic is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address contractAddress;

    constructor(address marketplaceAddress) ERC721("Mechademy Tokens", "MECHADEMY"){
        contractAddress = marketplaceAddress;
    }
    
    struct Item{
        uint256 id;
        address creater;
        string uri;
    }
    
    mapping (uint256 => Item) public Items;
    
    function mintNFT(address recipient, string memory uri)
        public
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
       Items[newItemId] = Item(newItemId, recipient, uri);
       setApprovalForAll(contractAddress, true);

        return newItemId;
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERSC721METADATA : URI query for nonexistent token ");
    
        return Items[tokenId].uri;
    }   
}