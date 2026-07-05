// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title myNFT
/// @author Pol Ribera Moreno
/// @notice ERC721 collection representing the player's assets.
/// @dev There are two NFT types:
/// - Base NFTs generate token production.
/// - Multiplier NFTs increase the production of all Base NFTs.
contract myNFT is ERC721Enumerable{
    using Strings for uint256;

    ////////////////////////////////////////
    //           DATA STRUCTURES          //
    ////////////////////////////////////////

    /// @notice Stores the data associated with each NFT.
    mapping(uint => TokenData) public IdToData;

    /// @notice The address of the others contracts.
    address public upgrade;
    address public trades;  
    address public master; 

    /// @notice Data stored for every NFT.
    struct TokenData {
        /// @notice Current NFT level.
        uint8 lvl;

        /// @notice NFT type. True = Multiplier, False = Base.
        bool multi;

        /// @notice Indicates whether the NFT is currently upgrading.
        bool upgrading;
    }

    /// @notice Next NFT identifier to mint.
    uint256 public id;

    /// @notice Base IPFS URI used to build NFT metadata.
    string public baseUri;  // "bafybeia4v7eadp6r4nuf3ei5cucf62hwigari6kbvbqggkg5e2dfxwqhxe/"

    /// @notice constant values that define the game
    uint256 public immutable baseProductionPerLvl; // 1000
    uint256 public immutable boostPercentagePerLvl; // 5%  
    uint256 public immutable relationPriceProduction; // 10  
    uint256 public immutable amountBase; // 5
    uint256 public immutable amountMulti; // 1

    ////////////////////////////////////////
    //              MODIFIERS             //
    ////////////////////////////////////////    

    /// @notice Restricts access to the Main contract.
    modifier onlyMaster() {
        require(master == msg.sender, "08");
        _;
    }

    /// @notice Restricts access to the Upgrade contract.
    modifier onlyUpgrade() {
        require(upgrade == msg.sender, "08");
        _;
    }

    /// @notice Restricts access to the Marketplace contract.
    modifier onlyTrades() {
        require(trades == msg.sender, "08");
        _;
    }

    ////////////////////////////////////////
    //             CONSTRUCTOR            //
    ////////////////////////////////////////    

    /// @notice Deploys the NFT contract.
    /// @param _name ERC721 collection name.
    /// @param _symbol ERC721 collection symbol.
    /// @param _baseUri Base IPFS URI for metadata and images.
    /// @param _baseProductionPerLvl Production generated per Base NFT level.
    /// @param _boostPercentagePerLvl Boost percentage per Multiplier NFT level.
    /// @param _relationPriceProduction Ratio used to calculate upgrade prices.
    /// @param _amountBase Initial number of Base NFTs per player.
    /// @param _amountMulti Initial number of Multiplier NFTs per player.
    constructor(string memory _name, string memory _symbol, string memory _baseUri, uint256 _baseProductionPerLvl, uint256 _boostPercentagePerLvl, uint256 _relationPriceProduction, uint256 _amountBase, uint256 _amountMulti) ERC721(_name, _symbol){
        master = msg.sender;
        baseUri = _baseUri;
        baseProductionPerLvl = _baseProductionPerLvl; 
        boostPercentagePerLvl = _boostPercentagePerLvl; 
        relationPriceProduction = _relationPriceProduction; 
        amountBase = _amountBase; 
        amountMulti = _amountMulti; 
    }

    ////////////////////////////////////////
    //         EXTERNAL FUNCTIONS         //
    ////////////////////////////////////////

    /// @dev override of transferFrom to don't allow users use a diferent marketplace
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyTrades{
        super.transferFrom(from, to, tokenId);
    }

    /// @dev override of safeTransferFrom to don't allow users use a diferent marketplace
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721, IERC721) onlyTrades{
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /// @notice Mints the initial NFT collection for a new player.
    /// @dev Mints both Base and Multiplier NFTs.
    /// @param _user Recipient address.
    function mintAll(address _user) external onlyMaster{
       for (uint i = 0; i < (amountBase + amountMulti); i++) {
            mint(i >= amountBase, _user);
        }
    }

    /// @notice Increases an NFT level by one.
    /// @param _tokenId NFT identifier.
    function lvlUp (uint256 _tokenId) external onlyUpgrade{ 
        IdToData[_tokenId].lvl++;
    }

    /// @notice Returns the on-chain metadata for an NFT.
    /// @dev Metadata is generated dynamically and encoded as Base64 JSON.
    /// @param _tokenId NFT identifier.
    /// @return Base64-encoded ERC721 metadata URI.
    function tokenURI(uint256 _tokenId) public view override virtual returns (string memory) {
        _requireOwned(_tokenId);
        TokenData memory data_ = IdToData[_tokenId];
        bool type_ = data_.multi;
        uint8 lvl_ = data_.lvl;

        require(lvl_ > 0, "09"); 

        string memory name_;
        string memory image_;
        uint production_;
        uint price_;
        string memory text_;

        if (type_) {
            name_ = "Creatine (Multi)";
            image_ = string.concat(baseUri, "11.png");
            production_ = 100 + boostPercentagePerLvl * lvl_; 
            price_ = boostPercentagePerLvl * baseProductionPerLvl * 2**(lvl_ - 1);
            text_ = "Boost (%)";
        } else { 
            name_ = "Plates (Base)";
            image_ = string.concat(baseUri, uint256(lvl_).toString(), ".png");
            production_ = baseProductionPerLvl * lvl_;
            price_ = baseProductionPerLvl * relationPriceProduction * lvl_;
            text_ = "Production";
        }

        string memory json_ = string(abi.encodePacked(
            '{"name": "', name_, '",',
            '"description": "NFT of tycoon gym",',
            '"image": "ipfs://', image_, '",',
            '"attributes": [{"trait_type": "Level", "value": ', uint256(lvl_).toString(), '},',
            '{"trait_type":"', text_ ,'", "value": ', production_.toString(),'},',
            '{"trait_type": "Upgrade_price", "value": ', price_.toString(), '}]}'
        ));

        string memory encoded_ = Base64.encode(bytes(json_));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            encoded_
        ));
    }
   
    /// @notice Returns the token cost required to upgrade an NFT.
    /// @param _tokenId NFT identifier.
    /// @return price_ Upgrade cost.
    function getPrice(uint256 _tokenId) external view returns (uint price_){ 
        _requireOwned(_tokenId);
        TokenData memory data_ = IdToData[_tokenId];
        bool type_ = data_.multi;
        uint8 lvl_ = data_.lvl;
        if (type_) {
            price_ = boostPercentagePerLvl * baseProductionPerLvl * 2**(lvl_ - 1);
        } else { 
            price_ = baseProductionPerLvl * relationPriceProduction * lvl_;
        }
    } 

    // @notice Updates the upgrading status of an NFT.
    /// @param _tokenId NFT identifier.
    /// @param _value New upgrading status.
    function setUpgrading(uint256 _tokenId, bool _value) external onlyUpgrade{  
        IdToData[_tokenId].upgrading = _value;
    }

    /// @notice Sets the authorized Marketplace contract.
    /// @param _trades Marketplace contract address.
    function setTrades (address _trades) external onlyMaster {
        trades = _trades;
    }

    /// @notice Sets the authorized Upgrade contract.
    /// @param _upgrade Upgrade contract address.
    function setUpgrade (address _upgrade) external onlyMaster {
        upgrade = _upgrade;
    }


    ////////////////////////////////////////
    //         INTERNAL FUNCTIONS         //
    ////////////////////////////////////////


    /// @notice Mints a new NFT.
    /// @dev Newly minted NFTs always start at level 1 and are not upgrading.
    /// @param _type NFT type. True = Multiplier, False = Base.
    /// @param _user Recipient address.
    function mint(bool _type, address _user) internal { 
        IdToData[id] = TokenData(1, _type, false);
        _safeMint(_user, id);
        id++;
    }
}