// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.7;

contract NftMarketplace {


        //////////////////////////
        //////Main Function///////
        //////////////////////////

        function listItem(address ntfAddress, uint256 tokenId, uint256 price) 
        external {
            if (price <= 0) {
                revert NftMarketplace_PriceMustBeAboveZero();
            }
            // 1. Send the NFT to the contract. Transfer -> Contract "hold" the NFT.
            // 2. Owners can still hold their NFT, and give the marketplace aproval
            // to sell the NFT for them.
        }
}
    
    // 1. `listItem`: List NFTs on the marketplace.
    // 2. `buyItem`: Buy the NFT.
    // 3. `cancelItem`: Cancel a listing.
    // 4. `updateListing`: Update price.
    // 5. `withdrawProceeds`: Withdraw payment for my bought NFTs.