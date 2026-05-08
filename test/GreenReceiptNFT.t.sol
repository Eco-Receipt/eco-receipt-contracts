// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {GreenReceiptNFT} from "../src/GreenReceiptNFT.sol";

contract GreenReceiptNFTTest is Test {
    GreenReceiptNFT private nft;

    address private owner = address(0xA11CE);
    address private auditor = address(0xA0D170);
    address private user = address(0xB0B);
    address private stranger = address(0xBAD);

    bytes32 private reportHash = keccak256("green receipt report json");
    bytes32 private evidenceRoot = keccak256("evidence merkle root");
    string private metadataURI = "ipfs://bafy-green-receipt-metadata";

    function setUp() public {
        vm.prank(owner);
        nft = new GreenReceiptNFT();
    }

    function testOwnerCanMintReceipt() public {
        vm.warp(1_717_171_717);

        vm.prank(owner);
        uint256 tokenId = nft.mintReceipt(
            user, "Nike Pegasus Trail 5 DV3865-602", "Nike", 82, "B", reportHash, evidenceRoot, metadataURI
        );

        assertEq(tokenId, 1);
        assertEq(nft.ownerOf(tokenId), user);
        assertEq(nft.tokenURI(tokenId), metadataURI);
        assertTrue(nft.exists(tokenId));

        GreenReceiptNFT.GreenReceipt memory receipt = nft.getReceipt(tokenId);
        assertEq(receipt.tokenId, tokenId);
        assertEq(receipt.productName, "Nike Pegasus Trail 5 DV3865-602");
        assertEq(receipt.brand, "Nike");
        assertEq(receipt.score, 82);
        assertEq(receipt.grade, "B");
        assertEq(receipt.reportHash, reportHash);
        assertEq(receipt.evidenceMerkleRoot, evidenceRoot);
        assertEq(receipt.metadataURI, metadataURI);
        assertEq(receipt.timestamp, 1_717_171_717);
        assertEq(receipt.creator, user);
        assertEq(receipt.auditor, owner);
    }

    function testAuditorCanMintAfterOwnerAddsAuditor() public {
        vm.prank(owner);
        nft.addAuditor(auditor);

        assertTrue(nft.isAuditor(auditor));

        vm.prank(auditor);
        uint256 tokenId =
            nft.mintReceipt(user, "Patagonia Jacket", "Patagonia", 91, "A", reportHash, evidenceRoot, metadataURI);

        assertEq(tokenId, 1);
        assertEq(nft.ownerOf(tokenId), user);

        GreenReceiptNFT.GreenReceipt memory receipt = nft.getReceipt(tokenId);
        assertEq(receipt.auditor, auditor);
    }

    function testRemovedAuditorCannotMint() public {
        vm.startPrank(owner);
        nft.addAuditor(auditor);
        nft.removeAuditor(auditor);
        vm.stopPrank();

        assertFalse(nft.isAuditor(auditor));

        vm.prank(auditor);
        vm.expectRevert(abi.encodeWithSelector(GreenReceiptNFT.UnauthorizedMinter.selector, auditor));
        nft.mintReceipt(user, "Patagonia Jacket", "Patagonia", 91, "A", reportHash, evidenceRoot, metadataURI);
    }

    function testUnauthorizedAccountCannotMint() public {
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(GreenReceiptNFT.UnauthorizedMinter.selector, stranger));
        nft.mintReceipt(user, "Unknown Product", "Unknown", 50, "C", reportHash, evidenceRoot, metadataURI);
    }

    function testMintRevertsWhenScoreAbove100() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(GreenReceiptNFT.InvalidScore.selector, 101));
        nft.mintReceipt(user, "Product", "Brand", 101, "F", reportHash, evidenceRoot, metadataURI);
    }

    function testMintRevertsWhenReportHashIsEmpty() public {
        vm.prank(owner);
        vm.expectRevert(GreenReceiptNFT.EmptyReportHash.selector);
        nft.mintReceipt(user, "Product", "Brand", 80, "B", bytes32(0), evidenceRoot, metadataURI);
    }

    function testMintRevertsWhenEvidenceRootIsEmpty() public {
        vm.prank(owner);
        vm.expectRevert(GreenReceiptNFT.EmptyEvidenceMerkleRoot.selector);
        nft.mintReceipt(user, "Product", "Brand", 80, "B", reportHash, bytes32(0), metadataURI);
    }

    function testMintRevertsWhenMetadataURIIsEmpty() public {
        vm.prank(owner);
        vm.expectRevert(GreenReceiptNFT.EmptyMetadataURI.selector);
        nft.mintReceipt(user, "Product", "Brand", 80, "B", reportHash, evidenceRoot, "");
    }

    function testMintRevertsWhenRecipientIsZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(GreenReceiptNFT.InvalidRecipient.selector);
        nft.mintReceipt(address(0), "Product", "Brand", 80, "B", reportHash, evidenceRoot, metadataURI);
    }

    function testGetReceiptRevertsForNonexistentToken() public {
        vm.expectRevert(abi.encodeWithSelector(GreenReceiptNFT.NonexistentToken.selector, 999));
        nft.getReceipt(999);
    }

    function testTokenIdsAutoIncrement() public {
        vm.startPrank(owner);
        uint256 firstTokenId =
            nft.mintReceipt(user, "Product One", "Brand", 80, "B", reportHash, evidenceRoot, metadataURI);
        uint256 secondTokenId =
            nft.mintReceipt(user, "Product Two", "Brand", 81, "B", reportHash, evidenceRoot, metadataURI);
        vm.stopPrank();

        assertEq(firstTokenId, 1);
        assertEq(secondTokenId, 2);
    }
}
