// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface IMyToken {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);
}
