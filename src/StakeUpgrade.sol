// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "./ImyToken.sol";
import "./ImyNFT.sol";

/// @title StakeUpgrade
/// @author Pol Ribera Moreno
/// @notice Handles the NFT upgrade mechanism.
/// @dev Users burn tokens to start an upgrade, may cancel it with a refund fee,
/// and can claim the level up NFT once the required time has elapsed.

contract StakeUpgrade {
    ////////////////////////////////////////
    //           DATA STRUCTURES          //
    ////////////////////////////////////////

    /// @notice The others contracts and interficies.
    IMyNFT public immutable nft;
    IMyToken public immutable token;
    address immutable master;

    /// @notice constant values that define the game
    uint256 public immutable feeRefund; // 10 (%)
    uint256 public immutable upgradePeriodPerLvl; // 1 days
    uint256 public immutable maxLvlBase; // 10
    uint256 public immutable maxLvlMulti; // 20

    /// @notice Timestamp when each NFT started its current upgrade.
    mapping(uint256 => uint256) public elapseTimeNFT;

    ////////////////////////////////////////
    //              MODIFIERS             //
    ////////////////////////////////////////

    /// @notice Restricts access to the Main contract.
    modifier onlyMaster() {
        require(msg.sender == master, "08");
        _;
    }

    /// @notice Ensures an NFT has not reached its maximum level.
    /// @param _tokenId NFT identifier.
    modifier canBeUpgraded(uint256 _tokenId) {
        (uint8 _lvl, bool _multi,) = nft.IdToData(_tokenId);
        uint256 maxLvl_;
        if (_multi) {
            maxLvl_ = maxLvlMulti;
        } else {
            maxLvl_ = maxLvlBase;
        }
        require(_lvl < maxLvl_, "06");
        _;
    }

    ////////////////////////////////////////
    //               EVENTS               //
    ////////////////////////////////////////

    /// @notice Emitted when an upgrade starts.
    /// @param _user NFT owner.
    /// @param _tokenId NFT identifier.
    /// @param _amount Cost of the upgrade.
    event Deposit(address indexed _user, uint256 _tokenId, uint256 _amount);

    /// @notice Emitted when an upgrade is cancelled.
    /// @param _user NFT owner.
    /// @param _tokenId NFT identifier.
    /// @param _amount Amount of refunded tokens.
    event Cancel(address indexed _user, uint256 _tokenId, uint256 _amount);

    /// @notice Emitted when an upgrade is successfully completed.
    /// @param _user NFT owner.
    /// @param _tokenId NFT identifier.
    /// @param _lvl New NFT level.
    event Upgrade(address indexed _user, uint256 _tokenId, uint256 _lvl);

    ////////////////////////////////////////
    //             CONSTRUCTOR            //
    ////////////////////////////////////////

    /// @notice Deploys the upgrade contract.
    /// @param _token ERC20 reward token.
    /// @param _nft ERC721 game NFT.
    /// @param _feeRefund Refund fee applied when cancelling an upgrade.
    /// @param _upgradePeriodPerLvl Upgrade duration per NFT level.
    /// @param _maxLvlBase Maximum level for production NFTs.
    /// @param _maxLvlMulti Maximum level for multiplier NFTs.
    constructor(
        IMyToken _token,
        IMyNFT _nft,
        uint256 _feeRefund,
        uint256 _upgradePeriodPerLvl,
        uint256 _maxLvlBase,
        uint256 _maxLvlMulti
    ) {
        master = msg.sender;
        token = _token;
        nft = _nft;
        feeRefund = _feeRefund;
        upgradePeriodPerLvl = _upgradePeriodPerLvl;
        maxLvlBase = _maxLvlBase;
        maxLvlMulti = _maxLvlMulti;
    }

    ////////////////////////////////////////
    //         EXTERNAL FUNCTIONS         //
    ////////////////////////////////////////

    /// @notice Starts the upgrade process for an NFT.
    /// @dev Burns the required amount of ERC20 tokens of the user and marks the NFT as upgrading.
    /// @param _user NFT owner.
    /// @param _tokenId NFT identifier.
    function depositToUpgrade(address _user, uint256 _tokenId) external onlyMaster canBeUpgraded(_tokenId) {
        uint256 price_ = nft.getPrice(_tokenId);
        uint256 balance_ = token.balanceOf(_user);
        (,, bool _upgrading) = nft.IdToData(_tokenId);

        require(balance_ >= price_, "07");
        require(nft.ownerOf(_tokenId) == _user, "03");
        require(!_upgrading, "11");

        elapseTimeNFT[_tokenId] = block.timestamp;

        token.burn(_user, price_);
        nft.setUpgrading(_tokenId, true);

        emit Deposit(_user, _tokenId, price_);
    }

    /// @notice Cancels an active upgrade.
    /// @dev Refunds the upgrade cost minus the configured cancellation fee and clears its upgrading status.
    /// @param _user NFT owner.
    /// @param _tokenId NFT identifier.
    function cancelUpgrade(address _user, uint256 _tokenId) external onlyMaster {
        (,, bool _upgrading) = nft.IdToData(_tokenId);
        require(nft.ownerOf(_tokenId) == _user, "03");
        require(_upgrading, "12");

        elapseTimeNFT[_tokenId] = 0;

        uint256 refund_ = nft.getPrice(_tokenId);

        nft.setUpgrading(_tokenId, false);

        refund_ = (refund_ * (100 - feeRefund)) / 100;
        token.mint(_user, refund_);

        emit Cancel(_user, _tokenId, refund_);
    }

    /// @notice Completes an upgrade once the waiting period has passed.
    /// @dev Increases the NFT level and clears its upgrading status.
    /// @param _user NFT owner.
    /// @param _tokenId NFT identifier.
    function claim(address _user, uint256 _tokenId) external onlyMaster {
        (uint8 _lvl,, bool _upgrading) = nft.IdToData(_tokenId);
        require(nft.ownerOf(_tokenId) == _user, "03");
        require(_upgrading, "12");

        uint256 elapsePeriod_ = block.timestamp - elapseTimeNFT[_tokenId];

        uint256 time_ = upgradePeriodPerLvl * _lvl;
        require(elapsePeriod_ >= time_, "13");

        elapseTimeNFT[_tokenId] = 0;

        nft.setUpgrading(_tokenId, false);
        nft.lvlUp(_tokenId);

        emit Upgrade(_user, _tokenId, _lvl + 1);
    }
}

