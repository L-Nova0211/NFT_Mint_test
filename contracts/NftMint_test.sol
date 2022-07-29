// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./libs/MerkleProof.sol";

import "hardhat/console.sol";

contract NftMint_test is ERC721Royalty, Ownable, ReentrancyGuard, Pausable {
    using Strings for uint256;

    string private _baseUri = "";
    string private _baseExtension = ".json";
    uint16 private _totalSupply = 65_535;
    uint16 private _currentTokenId = 0;
    uint64 private _cost = 0.01 ether; // uint64 (0 ~ 18,446,744,073,709,551,615)

    address public user3_1 = 0xD117842c3340e40E15ac8024F5159c968622e770;
    address public user3_2 = 0x07dA358466E890F05ff458C3b03c2571505D9f5D;
    address public user3_3 = 0x7BCB4f7FF8F5981bF670152cEF74d18CdB66923D;

    address public user4_1 = 0xD117842c3340e40E15ac8024F5159c968622e770;
    address public user4_2 = 0x07dA358466E890F05ff458C3b03c2571505D9f5D;
    address public user4_3 = 0x7BCB4f7FF8F5981bF670152cEF74d18CdB66923D;
    address public user4_4 = 0xB81144688A4705A2255FC7F02915c2c816548A2D;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseUri_
    ) ERC721(name_, symbol_) {
        require(bytes(baseUri_).length > 0, "NftMint: cannot empty string");
        _baseUri = baseUri_;
    }

    function mint(uint8 mintAmount_) internal {
        for (uint8 i = 1; i <= mintAmount_; i ++) {
            _safeMint(_msgSender(), _currentTokenId + i);
        }
        _currentTokenId += mintAmount_;
        require(_currentTokenId <= _totalSupply, "NftMint: Total NFTs are sold out");
    }

    // Public
    function publicMint3(uint8 mintAmount_) external nonReentrant payable {
        require(msg.value == _cost * mintAmount_, "NftMint: payment is not enough");
        mint(mintAmount_);
        payable(user3_1).transfer(msg.value * 15 / 100);
        payable(user3_2).transfer(msg.value * 20 / 100);
        payable(user3_3).transfer(msg.value * 65 / 100);
    }
    function publicMint4(uint8 mintAmount_) external nonReentrant payable {
        require(msg.value == _cost * mintAmount_, "NftMint: payment is not enough");
        mint(mintAmount_);
        payable(user4_1).transfer(msg.value * 15 / 100);
        payable(user4_2).transfer(msg.value * 20 / 100);
        payable(user4_3).transfer(msg.value * 55 / 100);
        payable(user4_4).transfer(msg.value * 10 / 100);
    }

    // Views

    function totalSupply() external view returns (uint16) {
        return _totalSupply;
    }

    function currentSupply() external view returns (uint16) {
        return _currentTokenId;
    }

    function cost() external view returns (uint64) {
        return _cost;
    }

    // @Overrides
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_baseUri).length > 0 ? string(abi.encodePacked(_baseUri, tokenId.toString(), _baseExtension)) : "";
    }

    // Owners: BaseUri
    function getBaseUri() external onlyOwner view returns (string memory) {
        return _baseUri;
    }
    function setBaseUri(string memory baseUri_) external onlyOwner {
        require(bytes(baseUri_).length > 0, "NftMint: cannot empty string");
        _baseUri = baseUri_;
    }
    // Owners: BaseExtension
    function getBaseExtension() external onlyOwner view returns (string memory) {
        return _baseExtension;
    }
    function setBaseExtension(string memory baseExtension_) external onlyOwner {
        require(bytes(baseExtension_).length > 0, "NftMint: cannot empty string");
        _baseExtension = baseExtension_;
    }
    // Owners: TotalSupply
    function setTotalSupply(uint16 totalSupply_) external onlyOwner {
        require(totalSupply_ > 0, "NftMint: cannot set as zero");
        _totalSupply = totalSupply_;
    }
    // Owners: Cost
    function setCost(uint64 cost_) external onlyOwner {
        _cost = cost_;
    }
    // Owners: pause & unpause
    function pause() external onlyOwner {
        _pause();
    }
    function unpause() external onlyOwner {
        _unpause();
    }
    // Override internal functions
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}