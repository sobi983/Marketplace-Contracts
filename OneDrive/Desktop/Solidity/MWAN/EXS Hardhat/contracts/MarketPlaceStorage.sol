// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library MarketStorage  {

    struct cardOnSale {
        address _owner;
        bytes32 _currency;
        uint256 _cardId;
        uint256 _amountOnSale;
        uint256 _pricePerCard;
        uint256 _duration;
        uint256 _deadline;

    } 
    function set(
        cardOnSale storage self,
        address owner,
        bytes32 currency,
        uint256 cardId,
        uint256 amountOnSale,
        uint256 pricePerCard,
        uint256 duration,
        uint256 deadline
        ) internal {
        self._owner = owner;
        self._currency = currency;
        self._cardId = cardId;
        self._amountOnSale = amountOnSale;
        self._pricePerCard = pricePerCard;
        self._duration=duration;
        self._deadline=deadline;
        
    }
    
    function peelOnion(
        cardOnSale storage self
        ) internal returns(bool) 
        {
        if(self._amountOnSale > 0) {
            self._amountOnSale -= 1;            
        return true;
        }
        return false;
    }

    function amountOnion(
        cardOnSale storage self
    ) internal view returns(uint256)
    {
        return self._amountOnSale;
    }

    function priceOfCard(
        cardOnSale storage self
        ) internal view returns(uint256)
        {
        return self._pricePerCard;
    }
   

    function userAuctionDetails(
        cardOnSale storage self
    ) internal view returns(address,bytes32,uint256,uint256, uint256, uint256,uint256) 
    {
        return (self._owner,self._currency,self._cardId,self._amountOnSale, self._pricePerCard, self._duration,self._deadline);
    }

    function deadlineOfAuction(
      cardOnSale storage self
     ) internal view returns(uint256)
    {
        return self._deadline;
    }

    function isOnAuction(
        cardOnSale storage self
    )internal view returns(bool)
    {
        return self._amountOnSale >= 1;
    }
    function ownerAuction(
        cardOnSale storage self
    ) internal view returns(address){
        return self._owner;
    }

    function onionCardId(
        cardOnSale storage self
    ) internal view returns(uint256) {
        return self._cardId;
    }
    function currencyAuction(
        cardOnSale storage self
    ) internal view returns(bytes32) {
        return self._currency;
    }
}   