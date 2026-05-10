// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title EcoReceiptNFT
/// @notice NFT certificate for an AI-generated environmental receipt.
/// @dev The full report and raw evidence stay off-chain. This contract stores only
///      concise public fields plus hashes that can be used to verify off-chain data.
contract EcoReceiptNFT is ERC721URIStorage, Ownable {
    struct EcoReceipt {
        uint256 tokenId;
        string productName;
        string brand;
        uint8 score;
        string grade;
        bytes32 reportHash;
        bytes32 evidenceMerkleRoot;
        string metadataURI;
        uint256 timestamp;
        address creator;
        address auditor;
    }

    event ReceiptMinted(
        uint256 indexed tokenId,
        address indexed creator,
        address indexed auditor,
        string productName,
        string brand,
        uint8 score,
        string grade,
        bytes32 reportHash,
        bytes32 evidenceMerkleRoot,
        string metadataURI
    );

    event AuditorAdded(address indexed auditor);
    event AuditorRemoved(address indexed auditor);

    error UnauthorizedMinter(address account);
    error InvalidRecipient();
    error InvalidScore(uint8 score);
    error EmptyReportHash();
    error EmptyEvidenceMerkleRoot();
    error EmptyMetadataURI();
    error NonexistentToken(uint256 tokenId);
    error ZeroAddressAuditor();

    uint256 private _nextTokenId = 1;

    mapping(address => bool) private _auditors;
    mapping(uint256 => EcoReceipt) private _receipts;

    modifier onlyAuthorizedMinter() {
        if (msg.sender != owner() && !_auditors[msg.sender]) {
            revert UnauthorizedMinter(msg.sender);
        }
        _;
    }

    constructor() ERC721("Eco Receipt NFT", "ERN") Ownable(msg.sender) {}

    /// @notice Mint one NFT that represents one environmental assessment report.
    /// @dev Stores hashes and summary fields only. Full report/evidence should live off-chain.
    function mintReceipt(
        address to,
        string memory productName,
        string memory brand,  // 品牌名称
        uint8 score,  // 评分
        string memory grade,  // 等级
        bytes32 reportHash,
        bytes32 evidenceMerkleRoot,  // 证据 Merkle Root
        string memory metadataURI  // metadata URI
    ) external onlyAuthorizedMinter returns (uint256) {
        if (to == address(0)) revert InvalidRecipient();
        if (score > 100) revert InvalidScore(score);
        if (reportHash == bytes32(0)) revert EmptyReportHash();
        if (evidenceMerkleRoot == bytes32(0)) revert EmptyEvidenceMerkleRoot();
        if (bytes(metadataURI).length == 0) revert EmptyMetadataURI();

        uint256 tokenId = _nextTokenId++;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, metadataURI);

        _receipts[tokenId] = EcoReceipt({
            tokenId: tokenId,
            productName: productName,
            brand: brand,
            score: score,
            grade: grade,
            reportHash: reportHash,
            evidenceMerkleRoot: evidenceMerkleRoot,
            metadataURI: metadataURI,
            timestamp: block.timestamp,
            creator: to,
            auditor: msg.sender
        });

        emit ReceiptMinted(
            tokenId, to, msg.sender, productName, brand, score, grade, reportHash, evidenceMerkleRoot, metadataURI
        );

        return tokenId;
    }

    /// @notice Return the on-chain summary and verification hashes for a receipt NFT.
    function getReceipt(uint256 tokenId) external view returns (EcoReceipt memory) {
        if (!exists(tokenId)) revert NonexistentToken(tokenId);
        return _receipts[tokenId];
    }

    /// @notice Grant minting permission to an auditor address.
    function addAuditor(address auditor) external onlyOwner {
        if (auditor == address(0)) revert ZeroAddressAuditor();
        _auditors[auditor] = true;
        emit AuditorAdded(auditor);
    }

    /// @notice Revoke minting permission from an auditor address.
    function removeAuditor(address auditor) external onlyOwner {
        if (auditor == address(0)) revert ZeroAddressAuditor();
        _auditors[auditor] = false;
        emit AuditorRemoved(auditor);
    }

    /// @notice Return whether an account is authorized as an auditor.
    function isAuditor(address account) public view returns (bool) {
        return _auditors[account];
    }

    /// @notice Return whether a token has been minted and not burned.
    function exists(uint256 tokenId) public view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
}
