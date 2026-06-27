// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

interface ITrades {

    function listNFT(address _user, uint256 _tokenId, uint256 _price) external;

    function buyNFT(address _user, uint256 _tokenId) external;

    function cancelList(address _user, uint256 _tokenId) external;

}