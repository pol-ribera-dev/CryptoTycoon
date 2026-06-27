// SPDX-License-Idenfitier: MIT

pragma solidity 0.8.24;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "./ImyToken.sol";
import "./ImyNFT.sol";

contract Trades{

    struct Listing {
        address seller;
        uint256 price;
    }

    mapping(uint256 => Listing) public listing;

    event NFTListed(address indexed seller, uint256 indexed tokenId, uint256 price);
    event NFTCancelled(address indexed seller, uint256 indexed tokenId);
    event NFTSold(address indexed buyer, address indexed seller, uint256 tokenId, uint256 price);
    
    IMyToken public immutable token;
    IMyNFT public immutable nft;
    address immutable master;
    uint256 public immutable relationPriceProduction;

    modifier onlyMaster() {
        require(msg.sender == master, "08");
        _;
    }

    constructor(IMyToken _token, IMyNFT _nft, uint _relationPriceProduction) {
        token = _token;
        nft = _nft;
        relationPriceProduction = _relationPriceProduction;
        master = msg.sender;
    }

    function listNFT(address _user, uint256 _tokenId, uint256 _price) external onlyMaster {
        require(_price > 0, "14");
        address owner_ = nft.ownerOf(_tokenId);
        require(owner_ == _user, "03");

        Listing memory listing_ = Listing({
            seller: _user,
            price: _price
        });

        listing[_tokenId] = listing_;

        emit NFTListed(_user, _tokenId, _price);
    }

    function buyNFT(address _user, uint256 _tokenId) external onlyMaster { 
        Listing memory listing_ = listing[_tokenId];
        require(listing_.price > 0, "04");

        uint extraPrice_ = nft.getPrice(_tokenId) / relationPriceProduction; // (C) penalty
        
        token.burn(_user, listing_.price + extraPrice_);
        token.mint(listing_.seller, listing_.price);

        delete listing[_tokenId];

        nft.safeTransferFrom(listing_.seller, _user, _tokenId);
        
        emit NFTSold(_user, listing_.seller, _tokenId, listing_.price);
    }

    function cancelList(address _user, uint256 _tokenId) external onlyMaster { 
        Listing memory listing_ = listing[_tokenId];
        require(listing_.seller == _user, "05");

        delete listing[_tokenId];
        emit NFTCancelled(_user, _tokenId);
    }
}

