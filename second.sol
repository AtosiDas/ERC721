// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyNFT is ERC721URIStorage, Ownable(msg.sender) {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct RoyaltyInfo {
        address creator;
        uint256 royaltyPercentage; // value will be 0 to 100
    }

    address[] public shareHolders;
    uint256[] share;

    mapping(address => uint256) shares;
    mapping(address => bool) status;
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

    constructor() ERC721("Unique Graffiti tokens", "UGT") {
        shareHolders.push(msg.sender);
        shares[msg.sender] = 100;
        status[msg.sender] = true;
    }

    uint256 public price = 0.02 ether;

    function mintNFT(
        string memory tokenURI,
        uint256 royaltyPercentage
    ) public payable returns (uint256) {
        require(royaltyPercentage <= 100, "Royalty percentage too high");
        require(msg.value == price);
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);

        _royalties[newItemId] = RoyaltyInfo({
            creator: msg.sender,
            royaltyPercentage: royaltyPercentage
        });

        emit NFTMinted(newItemId, msg.sender, royaltyPercentage);
        return newItemId;
    }

    function changePrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function burn(uint256 id) external {
        require(msg.sender == ownerOf(id), "not owner");
        _burn(id);
    }

    // function withdraw() public onlyOwner {
    //     payable (msg.sender).transfer(address(this).balance);
    // }

    function checkShare(uint256 _share) internal view {
        uint256 sum;
        for (uint256 i = 0; i < share.length; i++) {
            sum += share[i];
        }
        require(sum + _share <= 100, "share must be under 100");
    }

    function addShareHolders(address _addr, uint256 _share) public onlyOwner {
        checkShare(_share);
        require(status[_addr] == false, "Address is already a shareholder.");
        shareHolders.push(_addr);
        status[_addr] = true;
        share.push(_share);
        shares[_addr] = _share;
        shares[msg.sender] -= _share;
    }

    function sharedWithdrawl() public payable onlyOwner {
        uint256 balance = address(this).balance;
        for (uint256 i = 0; i < shareHolders.length; i++) {
            payable(shareHolders[i]).transfer(
                (shares[shareHolders[i]] * balance) / 100
            );
        }
    }

    function buyNFT(uint256 tokenId) external payable {
        address seller = ownerOf(tokenId);
        require(seller != msg.sender, "Cannot buy your own NFT");
        require(msg.value >= price, "Atleast send 0.02 ether");

        // Transfer the NFT to the buyer
        _transfer(seller, msg.sender, tokenId);

        RoyaltyInfo memory royalty = _royalties[tokenId];
        uint256 royaltyAmount = (msg.value * royalty.royaltyPercentage) / 100;

        // Send sale proceeds to the seller minus royalty
        uint256 sellerAmount = msg.value - royaltyAmount;
        payable(seller).transfer(sellerAmount);

        // Send royalty to the creator
        payable(royalty.creator).transfer(royaltyAmount);

        emit NFTSold(tokenId, seller, msg.sender, msg.value);
        emit NFTRoyaltiesPaid(tokenId, royalty.creator, royaltyAmount);
    }
}
