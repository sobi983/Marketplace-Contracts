// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./onionStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./allowances.sol";
import "./Royalties.sol";


contract SingleSell is  AccessControlEnumerable, Allowances {
    using Counters for Counters.Counter;
    Counters.Counter private _onionTracker;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AUCTIONER_ROLE = keccak256("AUCTIONER_ROLE");
    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER_ROLE");
    // bytes32 public constant OPERATIONAL_ROLE = keccak256("OPERATIONAL_ROLE");

    using SafeMath for uint256;
    using OnionStorage for OnionStorage.cardOnSale;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;
    
    IERC1155 private ERC1155;
    IERC20 private ERC20;
    Royalties private RoyaltiesAddress;

    // uint64 public transactionFee=375;

    struct structCardOnSale {
        address _owner;
        uint256 _cardId;
        uint256 _amountOnSale;
        uint256 _pricePerCard;
        uint256 _incrementer;
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

    constructor(address ERC1155Address, address treasurer, address _RoyaltiesAddress,bytes32 MAIN_TOKEN_) Allowances(MAIN_TOKEN_) {
        _setupRole(DEFAULT_ADMIN_ROLE,_msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(AUCTIONER_ROLE, _msgSender());
        _setupRole(TREASURER_ROLE, treasurer);
        // _setupRole(OPERATIONAL_ROLE,operational);
        ERC1155 = IERC1155(ERC1155Address);
        RoyaltiesAddress=Royalties(_RoyaltiesAddress);
    }
    
    function addCurrency(bytes32 currency, address currencyAddress) external onlyRole(ADMIN_ROLE) {
        _addCurrency(currency, currencyAddress);
    }

    function removeCurrency(bytes32 currency) external onlyRole(ADMIN_ROLE) {
        _removeCurrency(currency);
    }
    mapping(uint256 => OnionStorage.cardOnSale) private _onionAuction;



    using EnumerableSet for EnumerableSet.UintSet;

    EnumerableSet.UintSet private _onionIndexes;

    // function updateTransactionFee(uint64 _fee)public onlyRole(ADMIN_ROLE)
    // {
    //     require(_fee <= 10000, "OnionAuction: TransactionFee must be less than 10000");
    //     transactionFee=_fee;
    // }

    function _createOnionAuction(
        address owner,
        uint256 cardId,
        bytes32 currency,
        uint256 amountOfSale,
        uint256 pricePerCard,
        uint256 incrementer
        ) private {
        _onionTracker.increment();
        uint256 onionId = _onionTracker.current();
        _onionAuction[onionId].set(
            owner,
            currency,
            cardId,
            amountOfSale,
            pricePerCard,
            incrementer
        );
        _onionIndexes.add(onionId);
    }
    /** 
    @dev please make sure to call approve erc1155 before calling this marketPlace function, 
    */
    function createOnionAuction(
        uint256[] memory cardIds,
        address owner,
        bytes32 currency,
        uint256[] memory amountOfSales,
        uint256[] memory pricePerCards,
        uint256[] memory incrementers
    ) external onlyRole(AUCTIONER_ROLE)
    {
        require( 
        cardIds.length == amountOfSales.length && 
        amountOfSales.length == pricePerCards.length &&
        pricePerCards.length == incrementers.length,
        "Onion:  length mismatch"
        );
        ERC1155.safeBatchTransferFrom( msg.sender, address(this), cardIds, amountOfSales, '');

        for (uint256 index = 0; index < cardIds.length; ++index) {
            _createOnionAuction(
                owner,
                cardIds[index],
                currency,
                amountOfSales[index],
                pricePerCards[index],
                incrementers[index]
            );
        }
        emit NewOnion(cardIds, amountOfSales);
    }
    function _removeOnionAuction(
        uint256  onionId
        ) private
         {
        address owner = _onionAuction[onionId].ownerAuction();
        require(owner == msg.sender, "Onion: you are not the owner of the auction.");

        uint256 amountOfSale = _onionAuction[onionId].amountOnion();
        uint256 cardId = _onionAuction[onionId].onionCardId();
        
        delete _onionAuction[onionId]; //remove from storage
        _onionIndexes.remove(onionId);  // remove from auctions indexes

        ERC1155.safeTransferFrom(address(this), owner, cardId, amountOfSale, '');
    }

    function cancelOnionAuction(
        uint256[] memory onionIds
    ) external onlyRole(AUCTIONER_ROLE)
    {
        for (uint256 index = 0; index < onionIds.length; ++index) {
            _removeOnionAuction(onionIds[index]);
        }
        emit CancelOnion(onionIds);
    }

    function onionAuctionDetails(uint256 onionId) public view returns(address, bytes32,uint256, uint256, uint256, uint256) {
        return _onionAuction[onionId].onionDetails();
    }

    function _loyalty(uint256 price, uint64 loyaltyFee) internal pure returns(uint256) {
        uint256 fee = price.mul(loyaltyFee).div(10000);
        return fee;
    }
   
    /** 
    @dev please make sure to call approve erc20 before calling this Onion Auction function, 
    */
    function buyCard(
        uint256 onionId,
        address to
    ) external  
    {
        address TREASURER = getRoleMember(TREASURER_ROLE, 0);
        address OPERATIONAL = RoyaltiesAddress.OperationalAddress();

        uint256 cardId = _onionAuction[onionId].onionCardId();
       
        require(_onionAuction[onionId].isOnAuction(), "Onion:The current card is not for sale  ");
        
        
        uint256 priceOfAuction = _onionAuction[onionId].priceOfCard();

        bytes32 currency = _onionAuction[onionId].currencyAuction();
        require(_allowedCurrency(currency), "Auction: You cannot buy this auction with this currency");
        address contractCurrency = addressCurrency(currency);

        uint256 operationalFee = _loyalty(priceOfAuction,RoyaltiesAddress.TransactionFee());
        IERC20(contractCurrency).transferFrom(msg.sender, OPERATIONAL, operationalFee); // Transfer loyalty to athlete
        uint256 remaining_price=priceOfAuction.sub(operationalFee);

        uint256 athleteRoyaltyFee = _loyalty(remaining_price,RoyaltiesAddress.getAthletefee(RoyaltiesAddress.getCategories(cardId)));
        uint256 fedrationRoyaltyFee = _loyalty(remaining_price,RoyaltiesAddress.getFedrationfee(RoyaltiesAddress.getCategories(cardId)));
        
        IERC20(contractCurrency).transferFrom(msg.sender, RoyaltiesAddress.getAthleteAddress(cardId), athleteRoyaltyFee); // Transfer loyalty to athlete
        IERC20(contractCurrency).transferFrom(msg.sender, RoyaltiesAddress.getFedrationAddress(cardId), fedrationRoyaltyFee); // Transfer loyalty to athlete
       
        remaining_price=remaining_price.sub(athleteRoyaltyFee);
        remaining_price=remaining_price.sub(fedrationRoyaltyFee);

        IERC20(contractCurrency).transferFrom(msg.sender, TREASURER,remaining_price); //transfer (prices auction- loyalty) to auctioner
        
        require(_onionAuction[onionId].peelOnion(), "Onion: dont have cards to sell"); //update price per card on OA !IMPORTANT 

        if(_onionAuction[onionId].amountOnion() == 1){
            delete _onionAuction[onionId]; //after peel onion remove the auction because the auctions avalaible are 0
            _onionIndexes.remove(onionId);  //remove card from indexes
        }

        ERC1155.safeTransferFrom(address(this), to, cardId, 1, '');// transfer card to buyer

        emit CardBuyed(onionId, cardId, priceOfAuction);

    }

    function getAllOnionsId() public view returns(uint256[] memory) {
        
        uint256 indexMax = onionAuctionIndex();
        uint256[] memory onionIds = new uint256[](indexMax);
        for (uint256 index = 0; index < indexMax; ++index) {
            uint256 onionId= getOnionByIndex(index);
            onionIds[index] = onionId;
        }

        return onionIds;
    }

    function batchDetailsOnions(uint256[] memory onionIds) public view returns(OnionStorage.cardOnSale[] memory) {
        OnionStorage.cardOnSale[] memory detailsOnion = new OnionStorage.cardOnSale[](onionIds.length);
        for (uint256 index = 0; index < onionIds.length; ++index) {
            detailsOnion[index] = _onionAuction[onionIds[index]];
        }
        return detailsOnion;
    }


    function onionAuctionIndex() public view returns(uint256){
        return _onionIndexes.length();
    }

    function getOnionByIndex(uint256 index) public view returns(uint256) {
        return _onionIndexes.at(index);
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