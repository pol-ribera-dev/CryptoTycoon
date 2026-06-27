// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "./ImyToken.sol";
import "./ImyNFT.sol";

contract StakeUpgrade {

    IMyNFT public immutable nft;
    IMyToken public immutable token;
    address immutable master;
    
    uint256 public immutable feeRefund; // 10 (%)
    uint256 public immutable upgradePeriodPerLvl; // 1 days
    uint256 public immutable maxLvlBase; // 10
    uint256 public immutable maxLvlMulti; // 20

    mapping(uint256 => uint256) public elapseTimeNFT;

    modifier onlyMaster() {
        require(msg.sender == master, "08");
        _;
    }

    modifier canBeUpgraded (uint256 _tokenId){
        (uint8 _lvl, bool _multi,) = nft.IdToData(_tokenId);
        uint256 maxLvl_;
        if (_multi){
            maxLvl_ = maxLvlMulti;
        }
        else{
            maxLvl_ = maxLvlBase;
        }
        require( _lvl < maxLvl_, "06");
        _;
    }

    // Events
    
    event Deposit(address indexed _user, uint256 _tokenId, uint256 _amount);
    event Cancel(address indexed _user, uint256 _tokenId, uint256 _amount);
    event Upgrade(address indexed _user, uint256 _tokenId, uint256 _lvl);

    constructor(IMyToken _token, IMyNFT _nft, uint256 _feeRefund, uint256 _upgradePeriodPerLvl, uint256 _maxLvlBase, uint256 _maxLvlMulti) {
        master = msg.sender;
        token = _token;
        nft = _nft;
        feeRefund = _feeRefund;
        upgradePeriodPerLvl = _upgradePeriodPerLvl;
        maxLvlBase = _maxLvlBase;
        maxLvlMulti = _maxLvlMulti;
    }

    
    function depositToUpgrade(address _user, uint256 _tokenId) external onlyMaster canBeUpgraded(_tokenId){  
        uint256 price_ = nft.getPrice(_tokenId);
        uint256 balance_ = token.balanceOf(_user);
        ( , , bool _upgrading) = nft.IdToData(_tokenId);
        
        require(balance_ >= price_, "07");
        require(nft.ownerOf(_tokenId) == _user, "03");
        require(!_upgrading, "11");

        elapseTimeNFT[_tokenId] = block.timestamp;
        
        token.burn(_user, price_);
        nft.setUpgrading(_tokenId, true);
        
        emit Deposit(_user, _tokenId, price_);
    }

    function cancelUpgrade(address _user, uint256 _tokenId) external onlyMaster{ 

        ( , , bool _upgrading) = nft.IdToData(_tokenId);
        require(nft.ownerOf(_tokenId) == _user, "03");
        require(_upgrading, "12");

        elapseTimeNFT[_tokenId] = 0; 
        
        uint refund_ = nft.getPrice(_tokenId);

        nft.setUpgrading(_tokenId, false); 

        refund_ = (refund_ * (100 - feeRefund)) / 100;
        token.mint(_user, refund_);
            
        emit Cancel(_user, _tokenId, refund_);

    }

    // 3. Claim Rewards
    function claim(address _user, uint256 _tokenId) external onlyMaster{
        
        (uint8 _lvl , , bool _upgrading) = nft.IdToData(_tokenId);
        require(nft.ownerOf(_tokenId) == _user, "03");
        require(_upgrading, "12");

        uint256 elapsePeriod_ = block.timestamp - elapseTimeNFT[_tokenId];
        
        uint time_ = upgradePeriodPerLvl * _lvl;
        require(elapsePeriod_ >= time_, "13");
        
        elapseTimeNFT[_tokenId] = 0;

        nft.setUpgrading(_tokenId, false);
        nft.lvlUp(_tokenId);

        emit Upgrade(_user, _tokenId, _lvl + 1);
    }
}


