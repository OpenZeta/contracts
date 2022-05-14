// SPDX-License-Identifier: MIT
//
// Zeta implementation of TNT-721 NFT
//

pragma solidity ^0.8.12;

import "./TNT721.sol";

contract ZNFT is TNT721 {
    address private _creator;
    string private _collectionURI;
    bytes4 private constant _INTERFACE_ID_ZNFT = 0xa199d5f5;

    constructor(
        string memory name,
        string memory symbol,
        string memory collectionURI_
    ) TNT721(name, symbol) {
        _creator = msg.sender;
        _collectionURI = collectionURI_;

        _registerInterface(_INTERFACE_ID_ZNFT);
    }

    modifier onlyCreator() {
        require(
            msg.sender == _creator,
            "Only creator of the contract can call this function."
        );
        _;
    }

    // return contract creator
    function creator() public view returns (address) {
        return _creator;
    }

    // return contract collection URI
    function collectionURI() public view returns (string memory) {
        return _collectionURI;
    }

    // mint one token to one address
    function mint(address to, string memory uri) public onlyCreator {
        uint256 index = totalSupply();
        _safeMint(to, index);
        _setTokenURI(index, uri);
    }

    // update contract collection URI
    function updateCollectionURI(string memory collectionURI_)
        public
        onlyCreator
    {
        _collectionURI = collectionURI_;
    }
}
