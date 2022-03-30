// SPDX-License-Identifier: MIT
// Implements a TNT721 token marketplace using TFUEL as a currency

pragma solidity ^0.8.12;

import "../NFT/interfaces/ITNT721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ZMarket is ReentrancyGuard, Ownable, Pausable {
    bytes4 private constant _INTERFACE_ID_ZMARKET = 0xc28144be;
    bytes4 private constant _INTERFACE_ID_TNT165 = 0x01ffc9a7;

    // minimum price for a sale
    uint256 public minPrice;

    // market fee percentage
    uint8 public marketFee;

    // interface of the marketplace item
    struct Item {
        address payable seller;
        address tokenContract;
        uint256 tokenId;
        uint256 price;
        bytes32 status; // Open, Sold, Cancelled
    }

    // mapping of item id to item
    mapping(uint256 => Item) private itemsById;

    // mapping of seller to item
    mapping(address => uint256[]) private itemsBySeller;

    // items counter
    uint256 public itemsCounter;

    // event if item is modified
    event MarketChange(
        uint256 id,
        address seller,
        address buyer,
        address tokenContract,
        uint256 tokenId,
        uint256 price,
        bytes32 status
    );

    constructor() {
        itemsCounter = 0;
        minPrice = 10 ether;
        marketFee = 4;
    }

    /**
     * @dev Implementation of the TNT165 interface
     */
    function supportsInterface(bytes4 interfaceID)
        external
        pure
        returns (bool)
    {
        return
            interfaceID == _INTERFACE_ID_TNT165 ||
            interfaceID == _INTERFACE_ID_ZMARKET;
    }

    /**
     * @dev Returns the details for a marketplace item.
     */
    function getItem(uint256 _id) external view returns (Item memory) {
        return itemsById[_id];
    }

    /**
     * (optional)
     * @dev Returns all items of an address
     */
    function getItemsOfAddress(address _addr)
        external
        view
        returns (uint256[] memory)
    {
        return itemsBySeller[_addr];
    }

    /**
     * @dev Put a TNT721 token for sale.
     */
    function sell(
        address tokenContract,
        uint256 tokenId,
        uint256 price
    ) external nonReentrant whenNotPaused {
        require(price >= minPrice, "Price must be at least 10 tfuel");

        // put item in escrow
        ITNT721(tokenContract).transferFrom(msg.sender, address(this), tokenId);

        // add item to marketplace
        itemsById[itemsCounter] = Item({
            seller: payable(msg.sender),
            tokenContract: tokenContract,
            tokenId: tokenId,
            price: price,
            status: "Open"
        });

        // add item to seller
        itemsBySeller[msg.sender].push(itemsCounter);

        itemsCounter += 1;

        // emit event
        emit MarketChange(
            itemsCounter - 1,
            msg.sender,
            address(0),
            tokenContract,
            tokenId,
            price,
            "Open"
        );
    }

    /**
     * @dev Buys a TNT721 token from the marketplace items.
     */
    function buy(uint256 _id) external payable nonReentrant whenNotPaused {
        Item memory item = itemsById[_id];

        // item must be open for sale
        require(item.status == "Open", "Item is not for sale.");

        // buyer must send item price
        require(msg.value >= item.price, "You should pay the asked price");

        // calculate fee
        uint256 fee = (item.price / 100) * marketFee;

        // pay seller
        bool sent = _pay(item.seller, (item.price - fee));

        // payment must be successful
        require(sent, "Failed to send tfuel to the seller");

        // transfer token to new owner
        ITNT721(item.tokenContract).transferFrom(
            address(this),
            msg.sender,
            item.tokenId
        );

        // update item status
        itemsById[_id].status = "Sold";

        // emit event
        emit MarketChange(
            _id,
            item.seller,
            msg.sender,
            item.tokenContract,
            item.tokenId,
            item.price,
            "Sold"
        );
    }

    /**
     * @dev Cancels a marketplace item and return it to seller
     */
    function cancel(uint256 _id) external nonReentrant whenNotPaused {
        Item memory item = itemsById[_id];

        require(
            msg.sender == item.seller,
            "Item can only be cancelled by seller"
        );

        require(item.status == "Open", "Item is already sold or cancelled");

        ITNT721(item.tokenContract).transferFrom(
            address(this),
            item.seller,
            item.tokenId
        );

        itemsById[_id].status = "Cancelled";

        emit MarketChange(
            _id,
            item.seller,
            address(0),
            item.tokenContract,
            item.tokenId,
            item.price,
            "Cancelled"
        );
    }

    /**
     * (optional)
     * @dev Update a marketplace item price.
     */
    function update(uint256 _id, uint256 _price)
        external
        nonReentrant
        whenNotPaused
    {
        Item memory item = itemsById[_id];

        require(
            msg.sender == item.seller,
            "Item can only be changed by seller"
        );

        require(item.status == "Open", "Item is already sold or cancelled");

        itemsById[_id].price = _price;

        emit MarketChange(
            _id,
            item.seller,
            address(0),
            item.tokenContract,
            item.tokenId,
            _price,
            "Open"
        );
    }

    function _payout(address payable to, uint256 amount)
        external
        onlyOwner
        whenNotPaused
    {
        bool sent = _pay(to, amount);
        require(sent, "Failed to send tfuel to the address");
    }

    /**
     * @dev Pays the receiver the selected amount of TFUEL.
     */
    function _pay(address payable to, uint256 amount) internal returns (bool) {
        (bool sent, ) = to.call{value: amount}("");
        return sent;
    }
}
