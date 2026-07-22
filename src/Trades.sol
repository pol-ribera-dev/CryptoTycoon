// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "./ImyToken.sol";
import "./ImyNFT.sol";

/// @title Trades
/// @author Pol Ribera Moreno
/// @notice Marketplace for trading game NFTs.
/// @dev All interactions are performed through the Main contract. Buyers pay
/// the listed price plus an additional penalty based on the NFT production to avoid players
/// claim two times the same NFT reward that day.
contract Trades {
    ////////////////////////////////////////
    //           DATA STRUCTURES          //
    ////////////////////////////////////////

    /// @notice The others contracts and interficies.
    IMyToken public immutable token;
    IMyNFT public immutable nft;
    address immutable master;

    /// @notice constant value that define the game
    uint256 public immutable relationPriceProduction;

    /// @notice Information about an active NFT listing.
    struct Listing {


        /// @notice Address selling the NFT.
        address seller;

        /// @notice Sale price in ERC20 tokens.
        uint256 price;
    }

    /// @notice Active listing for each NFT.
    mapping(uint256 => Listing) public listing;

    ////////////////////////////////////////
    //              MODIFIERS             //
    ////////////////////////////////////////

    /// @notice Restricts access to the Main contract.
    modifier onlyMaster() {
        require(msg.sender == master, "08");
        _;
    }

    ////////////////////////////////////////
    //               EVENTS               //
    ////////////////////////////////////////

    /// @notice Emitted when an NFT is listed for sale.
    /// @param seller NFT owner.
    /// @param tokenId NFT identifier.
    /// @param price Listing price.
    event NFTListed(address indexed seller, uint256 indexed tokenId, uint256 price);

    /// @notice Emitted when a listing is cancelled.
    /// @param seller NFT owner.
    /// @param tokenId NFT identifier.
    event NFTCancelled(address indexed seller, uint256 indexed tokenId);

    /// @notice Emitted when an NFT is purchased.
    /// @param buyer Address purchasing the NFT.
    /// @param seller Previous NFT owner.
    /// @param tokenId NFT identifier.
    /// @param price Sale price paid to the seller.
    event NFTSold(address indexed buyer, address indexed seller, uint256 tokenId, uint256 price);

    ////////////////////////////////////////
    //             CONSTRUCTOR            //
    ////////////////////////////////////////

    /// @notice Deploys the marketplace contract.
    /// @param _token ERC20 reward token.
    /// @param _nft ERC721 game NFT.
    /// @param _relationPriceProduction Ratio used to calculate the purchase penalty.
    constructor(IMyToken _token, IMyNFT _nft, uint256 _relationPriceProduction) {
        token = _token;
        nft = _nft;
        relationPriceProduction = _relationPriceProduction;
        master = msg.sender;
    }

    ////////////////////////////////////////
    //         EXTERNAL FUNCTIONS         //
    ////////////////////////////////////////

    /// @notice Lists an NFT for sale.
    /// @dev The NFT owner sets the desired sale price.
    /// @param _user NFT owner.
    /// @param _tokenId NFT identifier.
    /// @param _price Sale price in ERC20 tokens.
    function listNFT(address _user, uint256 _tokenId, uint256 _price) external onlyMaster {
        require(_price > 0, "14");
        address owner_ = nft.ownerOf(_tokenId);
        require(owner_ == _user, "03");

        Listing memory listing_ = Listing({seller: _user, price: _price});

        listing[_tokenId] = listing_;

        emit NFTListed(_user, _tokenId, _price);
    }

    /// @notice Cancels an active listing.
    /// @param _user Seller address.
    /// @param _tokenId NFT identifier.
    function cancelList(address _user, uint256 _tokenId) external onlyMaster {
        Listing memory listing_ = listing[_tokenId];
        require(listing_.seller == _user, "05");

        delete listing[_tokenId];
        emit NFTCancelled(_user, _tokenId);
    }

    /// @notice Purchases a listed NFT.
    /// @dev The buyer pays the listed price plus an additional burn penalty
    /// based on the NFT production. Needs the approve of the seller().
    /// @param _user Buyer address.
    /// @param _tokenId NFT identifier.
    function buyNFT(address _user, uint256 _tokenId) external onlyMaster {
        Listing memory listing_ = listing[_tokenId];
        require(listing_.price > 0, "04");

        uint256 extraPrice_ = nft.getPrice(_tokenId) / relationPriceProduction;

        token.burn(_user, listing_.price + extraPrice_);
        token.mint(listing_.seller, listing_.price);

        delete listing[_tokenId];

        nft.safeTransferFrom(listing_.seller, _user, _tokenId);

        emit NFTSold(_user, listing_.seller, _tokenId, listing_.price);
    }
}

