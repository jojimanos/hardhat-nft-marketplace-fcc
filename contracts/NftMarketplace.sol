// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error NftMarketplace__PriceMustBeAboveZero();
error NftMarketplace__NotApprovedForMarketplace();
error NftMarketplace__AlreadyListed(address nftAddress, uint256 nftId);
error NftMarketplace__NotOwner();
error NftMarketplace__NotListed(address nftAddress, uint256 nftId);
error NftMarketplace__PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error NftMarketplace__NoProceeds();
error NftMarketplace__TranserFailed();

contract NftMarketplace is ReentrancyGuard {

struct Listing {
    uint256 price;
    address seller;
}

event ItemListed(
    address indexed seller,
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price
);

event ItemBought(
    address indexed buyer,
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price
    );

event ItemCanceled(
    address indexed seller,
    address indexed nftAddress,
    uint256 indexed tokeId
);

    // NFT contract address -> NFT TokenId -> Listing
    mapping (address => mapping (uint256 => Listing)) private s_listings;

    // Seller address -> Amount earned
    mapping (address => uint256) private s_proceeds;
    
    //////////////////////////
    ////////Modifiers/////////
    //////////////////////////
    modifier notListed(address nftAddress, uint256 tokenId, address owner) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if(listing.price > 0) {
            revert NftMarketplace__AlreadyListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price <=0) {
            revert NftMarketplace__NotListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isOwner(address nftAddress, uint256 tokenId, address spender) 
    {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (spender != owner) {
            revert NftMarketplace__NotOwner();
        }
        _;
    }

    //////////////////////////
    //////Main Function///////
    //////////////////////////

    /*
     * @notice Method for listing your NFT to the marketplace
     * @param nftAddress of the Nft
     * @param tokenId: The token ID of the NFT
     * @param price: sale price of the listed NFT
     * @dev Technicaly we could have the contract be the escrow for the NFTs
     * but this way people can still hold their NFTs when listed.
     */ 

    function listItem(address nftAddress, uint256 tokenId, uint256 price) 
    external 
    notListed(nftAddress, tokenId, msg.sender)
    isOwner(nftAddress, tokenId, msg.sender)
     {
        if (price <= 0) {
            revert NftMarketplace__PriceMustBeAboveZero();
        }
        // 1. Send the NFT to the contract. Transfer -> Contract "hold" the NFT.
        // 2. Owners can still hold their NFT, and give the marketplace aproval
        // to sell the NFT for them.

        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId) != address(this)) {
            revert NftMarketplace__NotApprovedForMarketplace();
        }
        s_listings[nftAddress][tokenId] = Listing(price, msg.sender);
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }

    function buyItem(address nftAddress, uint256 tokenId) 
    external 
    payable 
    nonReentrant
    
    isListed(nftAddress, tokenId)
    {
        Listing memory listedItem = s_listings[nftAddress][tokenId];
        if(msg.value < listedItem.price) {
            revert NftMarketplace__PriceNotMet(nftAddress, tokenId, listedItem.price);
        }
        s_proceeds[listedItem.seller] = s_proceeds[listedItem.seller] + msg.value;
        delete (s_listings[nftAddress][tokenId]);
        IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
        // check to make sure the NFT was transfered

        emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
    }

    function cancelListing(address nftAddress, uint256 tokenId) 
    external
    isOwner(nftAddress, tokenId, msg.sender)
    isListed(nftAddress, tokenId)
    {
        delete (s_listings[nftAddress][tokenId]);
        emit ItemCanceled(msg.sender, nftAddress, tokenId);
    } 

    function updateListing(
        address nftAddress,
        uint256 tokenId,
    uint256 newPrice
    ) external isListed(nftAddress, tokenId) isOwner(nftAddress, tokenId, msg.sender) {
        s_listings[nftAddress][tokenId].price = newPrice;
        emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
    }

    function withdrawProceeds() external {
        uint256 proceeds = s_proceeds[msg.sender];
        if (proceeds >= 0) {
            revert NftMarketplace__NoProceeds();
        }
        s_proceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        if (!success){
            revert NftMarketplace__TranserFailed();
        }
    }

    //////////////////////////
    //////Getter Functions////
    //////////////////////////

    function getItem(address nftAddress, uint256 tokeId) external view returns (Listing memory) {
        return s_listings[nftAddress][tokeId];
    }

    function getProceeds(address seller) external view returns(uint256) {
        return s_proceeds[seller];
    }
}

// 1. `listItem`: List NFTs on the marketplace.
// 2. `buyItem`: Buy the NFT.
// 3. `cancelItem`: Cancel a listing.
// 4. `updateListing`: Update price.
// 5. `withdrawProceeds`: Withdraw payment for my bought NFTs.
