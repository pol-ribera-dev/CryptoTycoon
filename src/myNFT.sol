// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract myNFT is ERC721Enumerable{
    using Strings for uint256;

    mapping(uint => TokenData) public IdToData;
    address public upgrade; 
    address public master; 

    struct TokenData {
        uint8 lvl;
        bool multi;
        bool upgrading;
    }

    uint256 public id;

    string public baseUri;  // "bafybeia4v7eadp6r4nuf3ei5cucf62hwigari6kbvbqggkg5e2dfxwqhxe/"

    uint256 public immutable baseProductionPerLvl; // 1000
    uint256 public immutable boostPercentagePerLvl; // 5%  
    uint256 public immutable relationPriceProduction; // 10  
    uint256 public immutable amountBase; // 5
    uint256 public immutable amountMulti; // 1

    modifier onlyMaster() {
        require(master == msg.sender, "08");
        _;
    }

    modifier onlyUpgrade() {
        require(upgrade == msg.sender, "08");
        _;
    }

    constructor(string memory _name, string memory _symbol, string memory _baseUri, uint256 _baseProductionPerLvl, uint256 _boostPercentagePerLvl, uint256 _relationPriceProduction, uint256 _amountBase, uint256 _amountMulti) ERC721(_name, _symbol){
        master = msg.sender;
        baseUri = _baseUri;
        baseProductionPerLvl = _baseProductionPerLvl; 
        boostPercentagePerLvl = _boostPercentagePerLvl; 
        relationPriceProduction = _relationPriceProduction; 
        amountBase = _amountBase; 
        amountMulti = _amountMulti; 
    }

    function mintAll(address _user) external onlyMaster{
       for (uint i = 0; i < (amountBase + amountMulti); i++) {
            mint(i >= amountBase, _user);
        }
    }

    function lvlUp (uint256 _tokenId) external onlyUpgrade{ 
        IdToData[_tokenId].lvl++;
    }

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

    function setUpgrading(uint256 _tokenId, bool _value) external onlyUpgrade{  
        IdToData[_tokenId].upgrading = _value;
    }

    function setMarket (address _upgrade) external onlyMaster {
        upgrade = _upgrade;
    }

    function mint(bool _type, address _user) internal { 
        IdToData[id] = TokenData(1, _type, false);
        _safeMint(_user, id);
        id++;
    }
}