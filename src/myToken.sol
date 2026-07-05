// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @title myToken
/// @author Pol Ribera Moreno
/// @notice ERC20 token used as the in-game currency.
/// @dev Tokens are minted as player rewards and consumed by game mechanics
/// such as NFT upgrades and marketplace purchases.
contract myToken is ERC20 {

    ////////////////////////////////////////
    //           DATA STRUCTURES          //
    ////////////////////////////////////////

    /// @notice The address of the others contracts.
    address public upgrade; 
    address public trades; 
    address public master; 

    ////////////////////////////////////////
    //              MODIFIERS             //
    ////////////////////////////////////////    

    /// @notice Restricts access to the Main contract.
    modifier onlyMaster() {
        require(master == msg.sender, "08");
        _;
    }

    /// @notice Restricts access to the Upgrade and Marketplace contracts.
    modifier onlyOthers() {
        require(upgrade == msg.sender || trades == msg.sender , "08");
        _;
    }

    /// @notice Restricts access to authorized contracts.
    modifier onlyAllowed(){
        require(upgrade == msg.sender || master == msg.sender || trades == msg.sender, "08");
        _;
    }

    ////////////////////////////////////////
    //             CONSTRUCTOR            //
    ////////////////////////////////////////
    
    /// @notice Deploys the ERC20 reward token.
    /// @param _name ERC20 token name.
    /// @param _symbol ERC20 token symbol.
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        master = msg.sender;
    }

    ////////////////////////////////////////
    //         EXTERNAL FUNCTIONS         //
    ////////////////////////////////////////    

    /// @notice Mints tokens to a user.
    /// @dev Can only be called by authorized game contracts.
    /// @param _user Recipient address.
    /// @param _amount Amount of tokens to mint.
    function mint(address _user, uint256 _amount) external onlyAllowed {
        _mint(_user, _amount);
    }

    /// @notice Burns tokens from a user.
    /// @param _user Address whose tokens will be burned.
    /// @param _amount Amount of tokens to burn.
    function burn(address _user, uint256 _amount) external onlyOthers {
        _burn(_user, _amount);
    }

    /// @notice Sets the authorized Upgrade contract.
    /// @param _upgrade Upgrade contract address.
    function setUpgrade (address _upgrade) external onlyMaster {
        upgrade = _upgrade;
    }

    /// @notice Sets the authorized Marketplace contract.
    /// @param _trades Marketplace contract address.
    function setTrades (address _trades) external onlyMaster {
        trades = _trades;
    }
}
