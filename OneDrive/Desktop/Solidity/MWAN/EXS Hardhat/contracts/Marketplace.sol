// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./MarketPlaceStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./allowances2.sol";
import "./Royalties.sol";

contract MarketPlace is  AccessControlEnumerable, Allowances {
    using Counters for Counters.Counter;
    Counters.Counter private _onionTracker;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    using SafeMath for uint256;
    using SafeMath for uint64;
    using MarketStorage  for MarketStorage.cardOnSale;
    
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;
    
    IERC1155 private ERC1155;
    IERC20 private ERC20;
    Royalties private RoyaltiesAddress;

    uint64 private _athleteFeeRoyalty=500;

    uint64 private _maxUserAutionDays=60;

    struct structCardOnSale {
        address _owner;
        uint256 _cardId;
        uint256 _amountOnSale;
        uint256 _pricePerCard;
        uint256 _duration;
    }

   event NewOnion(
       uint256[] cardIds,
       uint256[] amounts
    );


    event CancelOnion(
        uint256[] onionIds
    );

    event CardBuyed(
        uint256 indexed onionId,
        uint256 indexed cardId,
        uint256 priceOfAuction
    );
    event loyalty(
        uint256[] onionId,
        address[] athletePerNFT
       
    );
    event FeeAthleteUpdated(
        uint64 _newFee
    );
    event TimeUserAuctionUpdated(
        uint64 _dayss
    );

    constructor(address ERC1155Address,address _RoyaltiesAddress,bytes32 MAIN_TOKEN_) Allowances(MAIN_TOKEN_) {
        _setupRole(DEFAULT_ADMIN_ROLE,_msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
        ERC1155 = IERC1155(ERC1155Address);
        RoyaltiesAddress=Royalties(_RoyaltiesAddress);
    }
    
    function addCurrency(bytes32 currency, address currencyAddress) external onlyRole(ADMIN_ROLE) {
        _addCurrency(currency, currencyAddress);
    }

    function removeCurrency(bytes32 currency) external onlyRole(ADMIN_ROLE) {
        _removeCurrency(currency);
    }
    mapping(uint256 => MarketStorage.cardOnSale) private _marketPlace;

    using EnumerableSet for EnumerableSet.UintSet;

    EnumerableSet.UintSet private _marketIndexes;

   //Timer & Passer functions
    function updateUserAuctionDaysLimits(uint64 _days) external onlyRole(ADMIN_ROLE) {
        _maxUserAutionDays = _days;
        emit TimeUserAuctionUpdated(_days);
    }
    function UserAuctionDaysLimitsDetails()public view returns(uint64){
        return _maxUserAutionDays;
    }

    function _createUserAuction(
        address owner,
        uint256 cardId,
        bytes32 currency,
        uint256 amountOfSale,
        uint256 pricePerCard,
        uint256 duration
        ) private {
        _onionTracker.increment();
        uint256 onionId = _onionTracker.current();
        uint256 deadline = block.timestamp + (duration * 1 days); // you can set any of them " hours , minutes , weeks , months , days "
        _marketPlace[onionId].set(
            owner,
            currency,
            cardId,
            amountOfSale,
            pricePerCard,
            duration,
            deadline
        );
        _marketIndexes.add(onionId);
    }
    
    /** 
    @dev please make sure to call approve erc1155 before calling this marketPlace function, 
    */
    function createUserAuction(
        uint256[] memory cardIds,
        address owner,
        bytes32 currency,
        uint256[] memory amountOfSales,
        uint256[] memory pricePerCards,
        uint256[] memory duration
    ) external 
    {
        require( 
        cardIds.length == amountOfSales.length && 
        amountOfSales.length == pricePerCards.length &&
        pricePerCards.length == duration.length,
        "UserAuction:  length mismatch"
        );
        
        ERC1155.safeBatchTransferFrom( msg.sender, address(this), cardIds, amountOfSales, '');
       

        for (uint256 index = 0; index < cardIds.length; ++index) {
            require(duration[index]<=_maxUserAutionDays,"UserAuction: Duration limit exceed form maxLimit");
            _createUserAuction(
                owner,
                cardIds[index],
                currency,
                amountOfSales[index],
                pricePerCards[index],
                duration[index]
            );
        }
        emit NewOnion(cardIds, amountOfSales);
    }
    //////////////////////SETTERS\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    /**
    @dev only the contract administrator can update the fee charged for each auction
    the fee must be a number less than 10000.
        10% = 1000
        10.2% = 1020
        45.46% = 4546
    @param fee must be a uint64
    */
    function updateAthleteFeeLoyalty(uint64 fee) external onlyRole(ADMIN_ROLE) {
        require(fee <= 10000, "Auction: fee must be less than 10000");
        _athleteFeeRoyalty = fee;
        emit FeeAthleteUpdated(fee);
    }
    function _removeUserAuction(
        uint256  onionId
        ) private
         {
        
        address owner = _marketPlace[onionId].ownerAuction();
        require(owner == msg.sender, "Onion: you are not the owner of the auction.");

        uint256 amountOfSale = _marketPlace[onionId].amountOnion();
        uint256 cardId = _marketPlace[onionId].onionCardId();
        
        delete _marketPlace[onionId]; //remove from storage
        _marketIndexes.remove(onionId);  // remove from auctions indexes

        ERC1155.safeTransferFrom(address(this), owner, cardId, amountOfSale, '');
    }

    function removeUserAuction(
        uint256[] memory onionIds
    ) external 
    {
        for (uint256 index = 0; index < onionIds.length; ++index) {
            _removeUserAuction(onionIds[index]);
        }
        emit CancelOnion(onionIds);
    }


    function userAuctionDetails(uint256 onionId) public view returns(address owner, bytes32 currency,uint256 NFTid, uint256 quantity, uint256 price, uint256 duration,uint256 deadline) {
        if(block.timestamp<=_marketPlace[onionId].deadlineOfAuction())
        {
        return _marketPlace[onionId].userAuctionDetails();
        }

    }

    function expireUserAuctionDetails(uint256 onionId) public view returns(address owner, bytes32 currency,uint256 NFTid, uint256 quantity, uint256 price, uint256 duration,uint256 deadline) {
        if(block.timestamp>=_marketPlace[onionId].deadlineOfAuction())
        {
        return _marketPlace[onionId].userAuctionDetails();
        }


    }

    function _loyalty(uint256 price, uint64 loyaltyFee) internal pure returns(uint256) {
        uint256 fee = price.mul(loyaltyFee).div(10000);
        return fee;
    }
    function athleteFeeLoyalty()public view returns(uint64){
        return _athleteFeeRoyalty;
    }

    
    /** 
    @dev please make sure to call approve erc20 before calling this Onion Auction function, 
    */
    function buyCard(
        uint256 onionId,
        address to
    ) external 
    {
        uint256 cardId = _marketPlace[onionId].onionCardId();
        
        address OPERATIONAL = RoyaltiesAddress.OperationalAddress();
        address ATHLETE =RoyaltiesAddress.getAthleteAddress(cardId);
        address SELLER =_marketPlace[onionId].ownerAuction();
        
        require(_marketPlace[onionId].isOnAuction(), "Onion:The current card is not for sale  ");
        require(block.timestamp<=_marketPlace[onionId].deadlineOfAuction(), "Onion:The current card is expired");

        uint256 priceOfAuction = _marketPlace[onionId].priceOfCard();
        
        bytes32 currency = _marketPlace[onionId].currencyAuction();
        require(_allowedCurrency(currency), "Auction: You cannot buy this auction with this currency");
        address contractCurrency = addressCurrency(currency);
        
        uint256 operationalFee = _loyalty(priceOfAuction,RoyaltiesAddress.TransactionFee());
        uint256 athleteLoyaltyFee = _loyalty(priceOfAuction, _athleteFeeRoyalty);
        
        IERC20(contractCurrency).transferFrom(msg.sender, OPERATIONAL, operationalFee); // Transfer loyalty to athlete
        IERC20(contractCurrency).transferFrom(msg.sender,ATHLETE, athleteLoyaltyFee); // Transfer loyalty to EXOwner

        uint256 remaining_price=priceOfAuction.sub(operationalFee);
        remaining_price=remaining_price.sub(athleteLoyaltyFee);

        IERC20(contractCurrency).transferFrom(msg.sender, SELLER, remaining_price); //transfer (prices auction- loyalty) to auctioner
        
        

        require(_marketPlace[onionId].peelOnion(), "UserAuction: dont have cards to sell"); //update amout of card card on OA !IMPORTANT 

        if(_marketPlace[onionId].amountOnion() == 0){
            delete _marketPlace[onionId]; //after peel onion remove the auction because the acutions avalaible are 0
            _marketIndexes.remove(onionId);  //remove card from indexes
        }

        ERC1155.safeTransferFrom(address(this), to, cardId, 1, '');// transfer card to buyer

        emit CardBuyed(onionId, cardId, priceOfAuction);

    }

    function getAllUsersAuctionId() public view returns(uint256[] memory) {
        
        uint256 indexMax = userAuctionIndex();
        uint256[] memory userAuctionIds = new uint256[](indexMax);
        for (uint256 index = 0; index < indexMax; ++index) {
            uint256 onionId= getUserAuctionByIndex(index);
            userAuctionIds[index] = onionId;
        }

        return userAuctionIds;
    }

    function batchDetailsUserAuction(uint256[] memory onionIds) public view returns(MarketStorage .cardOnSale[] memory) {
        MarketStorage .cardOnSale[] memory detailsUserAuction = new MarketStorage .cardOnSale[](onionIds.length);
        
        for (uint256 index = 0; index < onionIds.length; ++index) {
            if(block.timestamp<=_marketPlace[onionIds[index]].deadlineOfAuction())
            {
            detailsUserAuction[index] = _marketPlace[onionIds[index]];
            }
        }
        return detailsUserAuction;
    }


    function batchDetailsOfExpireUserAuction(uint256[] memory onionIds) public view returns(MarketStorage .cardOnSale[] memory) {
        MarketStorage .cardOnSale[] memory detailsUserAuction = new MarketStorage .cardOnSale[](onionIds.length);
        
        for (uint256 index = 0; index < onionIds.length; ++index) {
            if(block.timestamp>=_marketPlace[onionIds[index]].deadlineOfAuction())
            {
            detailsUserAuction[index] = _marketPlace[onionIds[index]];
            }
        }
        return detailsUserAuction;
     }



    function userAuctionIndex() public view returns(uint256){
        return _marketIndexes.length();
    }

    function getUserAuctionByIndex(uint256 index) public view returns(uint256) {
        return _marketIndexes.at(index);
    }
    function onERC1155Received(address operator, address from, uint256 id, uint256 value,bytes calldata data) external returns(bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */

    function onERC1155BatchReceived(address operator,address from,uint256[] calldata ids,uint256[] calldata values, bytes calldata data) external returns(bytes4) {
    
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}