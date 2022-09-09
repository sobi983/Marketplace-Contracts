// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library OnionStorage  {

    struct cardOnSale {
        address _owner;
        bytes32 _currency;
        uint256 _cardId;
        uint256 _amountOnSale;
        uint256 _pricePerCard;
        uint256 _incrementer;
    }

    function set(
        cardOnSale storage self,
        address owner,
        bytes32 currency,
        uint256 cardId,
        uint256 amountOnSale,
        uint256 pricePerCard,
        uint256 incrementer
        ) internal {
        self._owner = owner;
        self._currency = currency;
        self._cardId = cardId;
        self._amountOnSale = amountOnSale;
        self._pricePerCard = pricePerCard;
        self._incrementer = incrementer;
    }

    function peelOnion(
        cardOnSale storage self
        ) internal returns(bool) 
        {
        if(self._amountOnSale > 0) {
            self._amountOnSale -= 1;            
            self._pricePerCard += self._incrementer;

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

    function onionDetails(
        cardOnSale storage self
    ) internal view returns(address, bytes32,uint256, uint256, uint256, uint256) 
    {
        return (self._owner, self._currency,self._cardId, self._amountOnSale, self._pricePerCard, self._incrementer);
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

    // function addressLoyalty(
    //     cardOnSale storage self
    // ) internal view returns(address){
    //     return self._athleteLoyalty;
    // }

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