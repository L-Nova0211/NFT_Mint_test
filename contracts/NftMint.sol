// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./libs/MerkleProof.sol";

import "hardhat/console.sol";

contract NftMint is ERC721Royalty, Ownable, ReentrancyGuard, Pausable {
    using Strings for uint256;

    string private _baseUri = "";
    string private _baseExtension = ".json";
    uint8 private _maxMintAmount = 3; // uint8 (0 ~ 255)
    uint16 private _preMintMaxBalance = 5;
    uint16 private _totalSupply = 65_535;
    uint16 private _currentTokenId = 0;
    uint16 private _newAssignedId = 0;
    uint40 private _preSaleTime = 1_647_302_400; // Date.UTC(2022, 2, 15, 0, 0, 0) / 1000 | 2022.3.15 UTC
    uint40 private _publicSaleTime = 1_648_684_800; // Date.UTC(2022, 2, 31, 0, 0, 0) / 1000 | 2022.3.31 UTC
    uint64 private _cost = 0.01 ether; // uint64 (0 ~ 18,446,744,073,709,551,615)
    bytes32 private _merkleRoot;
    mapping(address => uint16) private _preMintBalances;

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
    function publicMint(uint8 mintAmount_) external nonReentrant payable {
        require(block.timestamp >= _publicSaleTime, "NftMint: not ready to public mint");
        require(msg.value == _cost * mintAmount_, "NftMint: payment is not enough");
        mint(mintAmount_);
    }

    function preMint(uint8 mintAmount_, bytes32[] calldata proof_) external nonReentrant payable {
        require(block.timestamp >= _preSaleTime, "NftMint: not ready to pre mint");
        require(msg.value == _cost * mintAmount_, "NftMint: payment is not enough");
        require(MerkleProof.verify(proof_, _merkleRoot, MerkleProof._leaf(_msgSender())), "NftMint: address is not on whitelist");
        mint(mintAmount_);
        require(_preMintBalances[_msgSender()] <= _preMintMaxBalance, string(abi.encodePacked("NftMint: Cannot own more than ", _preMintMaxBalance, " NFTs")));
    }

    // Views
    function maxMintAmount() external view returns (uint8) {
        return _maxMintAmount;
    }

    function preMintMaxBalance() external view returns (uint16) {
        return _preMintMaxBalance;
    }

    function totalSupply() external view returns (uint16) {
        return _totalSupply;
    }

    function currentSupply() external view returns (uint16) {
        return _currentTokenId;
    }

    function newAssignedId() external view returns (uint16) {
        require(_newAssignedId != 0, "NftMint: not set the provenance id");
        return _newAssignedId;
    }

    function preSaleTime() external view returns (uint40) {
        return _preSaleTime;
    }

    function publicSaleTime() external view returns (uint40) {
        return _publicSaleTime;
    }

    function cost() external view returns (uint64) {
        return _cost;
    }

    function preMintBalances(address addr) external view returns (uint16) {
        return _preMintBalances[addr];
    }

    // @Overrides
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 assignedTokenId = tokenId + uint256(_newAssignedId);

        return bytes(_baseUri).length > 0 ? string(abi.encodePacked(_baseUri, assignedTokenId.toString(), _baseExtension)) : "";
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
    // Owners: PresaleTime
    function setPreSaleTime(uint40 preSaleTime_) external onlyOwner {
        _preSaleTime = preSaleTime_;
    }
    // Owners: PublicsaleTime
    function setPublicSaleTime(uint40 publicSaleTime_) external onlyOwner {
        _publicSaleTime = publicSaleTime_;
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
    // Owners: finalized id
    function setNewAssignedId() external onlyOwner {
        require(_newAssignedId == 0, "NftMint: provenance id is already set");
        _newAssignedId = uint16(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, _msgSender()))) % _totalSupply);
    }
    // Owners: max mint amount
    function setMaxMintAmount(uint8 maxMintAmount_) external onlyOwner {
        require(maxMintAmount_ > 0, "NftMint: cannot set as zero");
        _maxMintAmount = maxMintAmount_;
    }
    // Owners: pre mint max balance
    function setPreMintMaxBalance(uint8 preMintMaxBalance_) external onlyOwner {
        require(preMintMaxBalance_ > 0, "NftMint: cannot set as zero");
        _preMintMaxBalance = preMintMaxBalance_;
    }
    // Owners: merkle root
    function getMerkleRoot() external view onlyOwner returns (bytes32) {
        return _merkleRoot;
    }
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        _merkleRoot = merkleRoot_;
    }

    function balance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function withdraw() external onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
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