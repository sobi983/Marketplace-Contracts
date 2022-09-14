// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Allowances {

    bytes32 private MAIN_TOKEN;

    constructor(bytes32 MAIN_TOKEN_) {
        MAIN_TOKEN = MAIN_TOKEN_;
    }

    using EnumerableSet for EnumerableSet.Bytes32Set;

    mapping(bytes32 => address) private _tokenAllowed;
    mapping(bytes32 => address) private _currencyAllowed;

    EnumerableSet.Bytes32Set private _totalTokens;
    EnumerableSet.Bytes32Set private _totalCurrencies;

    /**
    @dev Add a contract address, make sure that the contract address corresponds to a erc1155
    @param tokenName the token name is the key that stores the value of tokenAddress
    @param tokenAddress is the value stored by the key, make sure it is an erc1155 contract.
    */
    function _addToken(bytes32 tokenName, address tokenAddress) internal {
        require(tokenAddress != address(0), "Allowances: The Zero Address is not allowed");
        _tokenAllowed[tokenName] = tokenAddress;
        _totalTokens.add(tokenName);
    }

    function _removeToken(bytes32 tokenName) internal {
        require(_tokenAllowed[tokenName] != address(0));

        _totalTokens.remove(tokenName);
        delete _tokenAllowed[tokenName];
    }

    /**
    @dev  add an erc20 coin to be used as a means of payment, make sure the coin meets the erc20 standard.
    @param currency is the key to store the value
    @param currencyAddress the contract address stored by the key, must be an erc20
    */

    function _addCurrency(bytes32 currency, address currencyAddress) internal {
        require(currencyAddress != address(0), "Allowances: The Zero Address is not allowed");
        _currencyAllowed[currency] = currencyAddress;
        _totalCurrencies.add(currency);
    }

    function _removeCurrency(bytes32 currency) internal {
        require(_currencyAllowed[currency] != address(0));

        _totalCurrencies.remove(currency);
        delete _currencyAllowed[currency];
    }

    function addressToken(bytes32 tokenName) public view returns(address) {
        return _tokenAllowed[tokenName];
    }

    function addressCurrency(bytes32 currency) public view returns(address) {
        return _currencyAllowed[currency];
    }
    /**
    @dev use this function to get all erc1155 allowed to create auctions 
    */

    function allTokensAllowed() public view returns(bytes32[] memory) {
        uint256 indexMax = _totalTokens.length();
        bytes32[] memory tokens = new bytes32[](indexMax);

        for (uint256 index = 0; index < indexMax; ++index) {
            bytes32 nameToken = _totalTokens.at(index);
            tokens[index] = nameToken;
        }
        return tokens;
    }

    function _allowedCurrency(bytes32 currency) internal view returns(bool){
        return _currencyAllowed[currency] != address(0);
    }

    /**
     @dev use this function to get all erc20 allowed as payment method in the contract.
     */
    function allCurrenciesAllowed() public view returns(bytes32[] memory) {
        uint256 indexMax = _totalCurrencies.length();
        bytes32[] memory currencies = new bytes32[](indexMax);
        for (uint256 index = 0; index < indexMax; ++index) {
            bytes32 currency = _totalCurrencies.at(index);
            currencies[index] = currency;
        }
        return currencies;
    }

    function _mainToken() internal view returns(bytes32) {
        return MAIN_TOKEN;
    }
    
    modifier currencyAllowed(bytes32 currency)  {
        if (currency == MAIN_TOKEN){
        } else {
            require(_currencyAllowed[currency] != address(0), "Allowances: This currency its not allowed" );
        }
        _;
    }

    modifier tokenAllowed(bytes32 tokenName) {
        require(_tokenAllowed[tokenName] != address(0), "Allowances: This token its not allowed" );
        _;
    }
    
}