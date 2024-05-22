// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTWithRoyalties is ERC721URIStorage, Ownable(msg.sender) {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct RoyaltyInfo {
        address creator;
        uint256 royaltyPercentage; // e.g., 5% is represented as 500
    }

    mapping(uint256 => RoyaltyInfo) private _royalties;

    event NFTMinted(
        uint256 tokenId,
        address creator,
        uint256 royaltyPercentage
    );
    event NFTSold(
        uint256 tokenId,
        address seller,
        address buyer,
        uint256 salePrice
    );
    event NFTRoyaltiesPaid(
        uint256 tokenId,
        address creator,
        uint256 royaltyAmount
    );

    constructor() ERC721("NFTWithRoyalties", "NWR") {}

    function mintNFT(
        uint256 royaltyPercentage
    ) public payable returns (uint256) {
        require(royaltyPercentage <= 10000, "Royalty percentage too high");
        require(msg.value == 0.002 ether);
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        //_setTokenURI(newItemId, tokenURI);

        _royalties[newItemId] = RoyaltyInfo({
            creator: msg.sender,
            royaltyPercentage: royaltyPercentage
        });

        emit NFTMinted(newItemId, msg.sender, royaltyPercentage);
        return newItemId;
    }

    function buyNFT(uint256 tokenId) external payable {
        address seller = ownerOf(tokenId);
        require(seller != msg.sender, "Cannot buy your own NFT");
        require(msg.value >= 0.002 ether, "Atleast send 0.002 ether");

        // Transfer the NFT to the buyer
        _transfer(seller, msg.sender, tokenId);

        RoyaltyInfo memory royalty = _royalties[tokenId];
        uint256 royaltyAmount = (msg.value * royalty.royaltyPercentage) / 10000;

        // Send sale proceeds to the seller minus royalty
        uint256 sellerAmount = msg.value - royaltyAmount;
        payable(seller).transfer(sellerAmount);

        // Send royalty to the creator
        payable(royalty.creator).transfer(royaltyAmount);

        emit NFTSold(tokenId, seller, msg.sender, msg.value);
        emit NFTRoyaltiesPaid(tokenId, royalty.creator, royaltyAmount);
    }

    // function resellNFT(uint256 tokenId, uint256 salePrice) external payable {
    //     require(ownerOf(tokenId) == msg.sender, "Only the owner can resell the NFT");
    //     require(msg.value >= salePrice, "Insufficient funds to buy NFT");

    //     address buyer = msg.sender;
    //     address seller = ownerOf(tokenId);
    //     require(seller != buyer, "Cannot resell to yourself");

    //     // Calculate royalty
    //     RoyaltyInfo memory royalty = _royalties[tokenId];
    //     uint256 royaltyAmount = (salePrice * royalty.royaltyPercentage) / 10000;

    //     // Transfer NFT to buyer
    //     _transfer(seller, buyer, tokenId);

    //     // Send sale proceeds to the seller minus royalty
    //     uint256 sellerAmount = salePrice - royaltyAmount;
    //     payable(seller).transfer(sellerAmount);

    //     // Send royalty to the creator
    //     payable(royalty.creator).transfer(royaltyAmount);

    //     emit NFTSold(tokenId, seller, buyer, salePrice);
    //     emit NFTRoyaltiesPaid(tokenId, royalty.creator, royaltyAmount);
    // }
}
