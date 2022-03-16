// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../NFT/TNT721.sol";

contract ZMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _items;
    Counters.Counter private _soldItems;

    address payable _marketOwner;

    uint256 _minSalePrice = 1 wei; // minimum price for a sale to happen
    uint8 _marketFee; // market fee percentage %

    // interface to marketplace item
    struct MarketplaceItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketplaceItem) private marketItemById;

    // declare a event for when a item is created on marketplace
    event Sell(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        uint256 price,
        bool sold
    );

    // declare a event for when a item is sold on marketplace
    event Buy(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address owner,
        uint256 price,
        bool sold
    );

    constructor(uint8 marketFee_) {
        _marketOwner = payable(msg.sender);
        _marketFee = marketFee_;
    }

    // returns the minimum sale price of the contract
    function minSalePrice() public view returns (uint256) {
        return _minSalePrice;
    }

    // returns the market fee percentage
    function marketFee() public view returns (uint256) {
        return _marketFee;
    }

    // places an item for sale on the marketplace
    function sell(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        require(price > _minSalePrice, "Price must be at least 1 tfuel");

        _items.increment();
        uint256 itemId = _items.current();

        marketItemById[itemId] = MarketplaceItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            price,
            false
        );

        ITNT721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit Sell(itemId, nftContract, tokenId, msg.sender, price, false);
    }

    // creates the sale of a marketplace item
    // transfers ownership of the item, as well as funds between parties
    function buy(address nftContract, uint256 itemId)
        public
        payable
        nonReentrant
    {
        uint256 price = marketItemById[itemId].price;
        uint256 tokenId = marketItemById[itemId].tokenId;

        require(
            msg.value == price,
            "Please submit the asking price in order to complete the purchase"
        );

        uint256 fee = (price * _marketFee) / 100;

        marketItemById[itemId].seller.transfer(msg.value - fee);
        payable(_marketOwner).transfer(fee);

        ITNT721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        marketItemById[itemId].seller = payable(msg.sender);
        marketItemById[itemId].sold = true;

        _soldItems.increment();

        emit Buy(itemId, nftContract, tokenId, msg.sender, price, true);
    }

    // returns item by id
    function itemById(uint256 itemId)
        public
        view
        returns (MarketplaceItem memory)
    {
        return marketItemById[itemId];
    }
}
