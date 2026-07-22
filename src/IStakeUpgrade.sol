// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

interface IStakeUpgrade {
    function depositToUpgrade(address _user, uint256 _tokenId) external;

    function CancelUpgrade(address _user, uint256 _tokenId) external;

    function claim(address _user, uint256 _tokenId) external;
}
