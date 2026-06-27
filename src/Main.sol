// SPDX-License-Idenfitier: MIT

pragma solidity 0.8.24;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

import "./myToken.sol";
import "./myNFT.sol";
import "./StakeUpgrade.sol";
import "./Trades.sol";

import "./ImyToken.sol";
import "./ImyNFT.sol";
import "./IStakeUpgrade.sol";
import "./ITrades.sol";

contract MainGym is ReentrancyGuard { // (C) Tot Reentrancy pk no s'han d'executar mai dos funcions del Main a la mateixa transacció 
    
    uint constant DURATION =  1 days;

    myToken public immutable token;
    myNFT public immutable nft;
    StakeUpgrade public immutable upgrade;
    Trades public immutable marketplace;

    IMyToken public immutable Itoken;
    IMyNFT public immutable Inft;
    IStakeUpgrade public immutable Iupgrade;
    ITrades public immutable Imarketplace;

    mapping (address => bool) public playing;
    mapping (address => uint) public timeLastReward;

    uint256 public immutable boostPercentagePerLvl; // 5 (%)
    uint256 public immutable baseProductionPerLvl; // 1000


    modifier notPlaying() {
        require(!playing[msg.sender], "01");
        _;
    }

    modifier yesPlaying() {
        require(playing[msg.sender], "15");
        _;
    }

    modifier oncePerDay(uint _last) {
        require(block.timestamp > _last + DURATION, "02");
        _;
    }

    // EVENTOS
    event StartPlaying(address _newPlayer);
    event Reward(address indexed _newPlayer, uint _amount);

    // (C) no hi ha limitació en valors d'inputs, s'enten que la persona que utilitza entent
    constructor(string memory _tokenName, string memory _tokenSymbol, string memory _NFTName, string memory _NFTSymbol, string memory _baseUri, uint _feeRefund, uint256 _upgradePeriodPerLvl, uint256 _boostPercentagePerLvl, uint256 _baseProductionPerLvl, uint256 _relationPriceProduction, uint256 _maxLvlBase, uint256 _maxLvlMulti, uint256 _amountBase, uint256 _amountMulti) {
        
        boostPercentagePerLvl = _boostPercentagePerLvl;
        baseProductionPerLvl = _baseProductionPerLvl;   

        token = new myToken(_tokenName, _tokenSymbol); 
        nft = new myNFT(_NFTName, _NFTSymbol, _baseUri, _baseProductionPerLvl, _boostPercentagePerLvl, _relationPriceProduction, _amountBase, _amountMulti);
        
        Itoken = IMyToken(address(token));
        Inft = IMyNFT(address(nft));
        
        upgrade = new StakeUpgrade(Itoken, Inft, _feeRefund, _upgradePeriodPerLvl, _maxLvlBase, _maxLvlMulti);
        marketplace = new Trades(Itoken, Inft, _relationPriceProduction);

        token.setMarket(address(upgrade)); // (C) no he utilitzat proxi pk vull que la gent es fiï
        nft.setMarket(address(upgrade));  

        token.setTrades(address(marketplace));
        
        Iupgrade = IStakeUpgrade(address(upgrade));
        Imarketplace = ITrades(address(marketplace));
    }

    // Main
    function start() external notPlaying { //(C) CEI pattern
        playing[msg.sender] = true;
        Inft.mintAll(msg.sender);
        emit StartPlaying(msg.sender);
    }

    function getRewards() external oncePerDay(timeLastReward[msg.sender]) yesPlaying nonReentrant{
        timeLastReward[msg.sender] = block.timestamp;
        uint balance_ = Inft.balanceOf(msg.sender);
        uint base_ = 0;
        uint multiply_ = 100; // (C) 2 decimals
        
        for (uint256 i = 0; i < balance_; i++) {
            uint256 tokenId_ = Inft.tokenOfOwnerByIndex(msg.sender, i);
            (uint8 _lvl, bool _multi, bool _upgrading) = Inft.IdToData(tokenId_);
            if (!_upgrading){
                if (_multi){
                    multiply_ *= (100 + boostPercentagePerLvl * _lvl);
                    multiply_ /= 100;
                } else{
                    base_ += baseProductionPerLvl * _lvl;
                }
            }
        }
        uint reward_ = (base_ * multiply_) / 100;
        Itoken.mint(msg.sender, reward_);

        emit Reward(msg.sender, reward_);
    }


    // marketPlace
    function listNFT( uint256 _tokenId, uint256 _price) external yesPlaying nonReentrant{
        Imarketplace.listNFT(msg.sender, _tokenId, _price); 
    }

    function cancelList(uint256 _tokenId) external yesPlaying nonReentrant{
        Imarketplace.cancelList(msg.sender, _tokenId);
    }

    function buyNFT(uint256 _tokenId) external yesPlaying nonReentrant{
        Imarketplace.buyNFT(msg.sender, _tokenId);
    }

    // Upgrades

    function depositToUpgrade(uint256 _tokenId) external yesPlaying nonReentrant{ 
        upgrade.depositToUpgrade(msg.sender, _tokenId);
    }

    function cancelUpgrade(uint256 _tokenId) external yesPlaying nonReentrant{
        upgrade.cancelUpgrade(msg.sender, _tokenId);
    }

    function claim(uint256 _tokenId) external yesPlaying nonReentrant{
        upgrade.claim(msg.sender, _tokenId);
    }

}