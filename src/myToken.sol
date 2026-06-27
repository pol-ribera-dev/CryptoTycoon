// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract myToken is ERC20 {

    address public upgrade; 
    address public trades; 
    address public master; 

    modifier onlyMaster() {
        require(master == msg.sender, "08");
        _;
    }

    modifier onlyOthers() {
        require(upgrade == msg.sender || trades == msg.sender , "08");
        _;
    }

    modifier onlyAllowed(){
        require(upgrade == msg.sender || master == msg.sender || trades == msg.sender, "08");
        _;
    }

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        master = msg.sender;
    }

    function mint(address _user, uint256 _amount) external onlyAllowed {
        _mint(_user, _amount);
    }

    function burn(address _user, uint256 _amount) external onlyOthers {
        _burn(_user, _amount);
    }

    function setMarket (address _upgrade) external onlyMaster {
        upgrade = _upgrade;
    }

    function setTrades (address _trades) external onlyMaster {
        trades = _trades;
    }

   // (C) no bloquejo el transfere
   // (C) ni bloquejo el upgrade
}
