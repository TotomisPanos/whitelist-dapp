// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Whitelist.sol";

contract CryptoDoves is ERC721Enumerable, Ownable {
    //  _price is the price of one Crypto Dove NFT
    uint256 constant public _price = 0.01 ether;

    // Max number of CryptoDoves that can ever exist
    uint256 constant public maxTokenIds = 9;

    // Whitelist contract instance
    Whitelist whitelist;

    // Number of tokens reserved for whitelisted members
    uint256 public reservedTokens;
    uint256 public reservedTokensClaimed = 0;

    /**
      * @dev ERC721 constructor takes in a `name` and a `symbol` to the token collection.
      * name in our case is `Crypto Doves` and symbol is `CD`.
      * Constructor for Crypto Doves takes in the baseURI to set _baseTokenURI for the collection.
      * It also initializes an instance of whitelist interface.
      */
    constructor (address whitelistContract) ERC721("Crypto Doves", "CD") Ownable(msg.sender) {
        whitelist = Whitelist(whitelistContract);
        reservedTokens = whitelist.maxWhitelistedAddresses();
    }

    function mint() public payable {
        // Make sure we always leave enough room for whitelist reservations
        require(totalSupply() + reservedTokens - reservedTokensClaimed < maxTokenIds, "EXCEEDED_MAX_SUPPLY");

        // If user is part of the whitelist, make sure there is still reserved tokens left
        if (whitelist.whitelistedAddresses(msg.sender) && msg.value < _price) {
            // Make sure user doesn't already own an NFT
            require(balanceOf(msg.sender) == 0, "ALREADY_OWNED");
            reservedTokensClaimed += 1;
        } else {
            // If user is not part of the whitelist, make sure they have sent enough ETH
            require(msg.value >= _price, "NOT_ENOUGH_ETHER");
        }
        uint256 tokenId = totalSupply();
        _safeMint(msg.sender, tokenId);
    }

    /**
    * @dev withdraw sends all the ether in the contract
    * to the owner of the contract
      */
    function withdraw() public onlyOwner  {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) =  _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}