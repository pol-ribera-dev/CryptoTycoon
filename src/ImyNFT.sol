// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface IMyNFT {
    struct TokenData {
        int8 lvl;
        bool multi;
        bool upgrading;
    }

    function mintAll(address user) external;

    function lvlUp(uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function balanceOf(address owner) external view returns (uint256);

    function getPrice(uint256 tokenId) external returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    function setUpgrading(uint256 tokenId, bool value) external;

    function IdToData(uint256 tokenId) external view returns (uint8 lvl, bool multi, bool upgrading);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}
