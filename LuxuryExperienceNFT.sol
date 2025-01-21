// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LuxuryExperienceNFT is ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;

    struct Benefit {
        string name;        
        uint96 total;      
        uint96 used;       
        uint64 expiryDate; 
        bool isActive;     
    }

    mapping(uint256 => Benefit[]) public tokenBenefits;
    
    event BenefitAdded(uint256 indexed tokenId, string name, uint96 total);
    event BenefitUsed(uint256 indexed tokenId, uint256 benefitIndex);

    constructor() ERC721("LuxuryExperience", "LUXE") Ownable(msg.sender) {}

    function mintWithBenefits(
        address recipient,
        string memory uri,
        string[] memory benefitNames,
        uint96[] memory benefitTotals,
        uint64[] memory expiryDates
    ) public onlyOwner returns (uint256) {
        require(
            benefitNames.length == benefitTotals.length && 
            benefitTotals.length == expiryDates.length,
            "Arrays length mismatch"
        );

        uint256 newTokenId = _nextTokenId++;
        _safeMint(recipient, newTokenId);
        _setTokenURI(newTokenId, uri);

        for (uint256 i = 0; i < benefitNames.length; i++) {
            Benefit memory newBenefit = Benefit({
                name: benefitNames[i],
                total: benefitTotals[i],
                used: 0,
                expiryDate: expiryDates[i],
                isActive: true
            });
            tokenBenefits[newTokenId].push(newBenefit);
            emit BenefitAdded(newTokenId, benefitNames[i], benefitTotals[i]);
        }

        return newTokenId;
    }

    function useBenefit(uint256 tokenId, uint256 benefitIndex) public {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        require(benefitIndex < tokenBenefits[tokenId].length, "Invalid benefit index");

        Benefit storage benefit = tokenBenefits[tokenId][benefitIndex];
        require(benefit.isActive, "Benefit not active");
        require(benefit.used < benefit.total, "No uses remaining");
        require(block.timestamp < benefit.expiryDate, "Benefit expired");

        benefit.used += 1;
        emit BenefitUsed(tokenId, benefitIndex);

        if (benefit.used == benefit.total) {
            benefit.isActive = false;
        }
    }
}
