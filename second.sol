// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MyNFT is ERC721URIStorage, Ownable(msg.sender) {
    address[] public shareHolders;
    uint256[] share;
    mapping(address => uint256) shares;
    mapping(address => bool) status;
    constructor() ERC721("Unique Graffiti tokens", "UGT") {
        shareHolders.push(msg.sender);
        shares[msg.sender] = 100;
        status[msg.sender] = true;
    }
    uint256 public price = 0.02 ether;
    function mint(uint256 _id, string memory _uri) external payable{
        require(msg.value == price, "Insufficient balance!");
        _mint(msg.sender, _id);
        _setTokenURI(_id, _uri);
    }

    function changePrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function burn(uint256 id) external {
        require(msg.sender == ownerOf(id), "not owner");
        _burn(id);
    }

    function withdraw() public onlyOwner {
        payable (msg.sender).transfer(address(this).balance);
    }
    function checkShare(uint256 _share) internal view {
        uint256 sum;
        for(uint256 i = 0; i < share.length; i++){
            sum += share[i];
        }
        require(sum + _share <= 100,"share must be under 100");
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
    function sharedWithdrawl() public onlyOwner payable{
        uint256 balance = address(this).balance;
        for(uint256 i = 0; i < shareHolders.length; i++){
            payable(shareHolders[i]).transfer((shares[shareHolders[i]]*balance)/100);
        }
    }
}

