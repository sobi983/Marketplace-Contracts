// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";



contract ExSports is ERC1155PresetMinterPauser{

    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    constructor (string memory uri) ERC1155PresetMinterPauser(uri) public {
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    //supply tokens by Id
    mapping(uint256 => uint256) private _totalSupply;
    
    mapping(uint256=>string)private _uris;

    //hash of properties in MetadataUri of cards
    mapping(uint256 => bytes32) private _propertiesHash;

    //storing to indexing of balance tokens in address
    mapping(address => EnumerableSet.UintSet) _addressBalance;

  

    EnumerableSet.UintSet private _totalTokenIds;

    //getter function for 
    function uri(uint256 tokenid)override public view returns(string memory)
    {
        return (_uris[tokenid]);
       
    }
    //setting Unique Uri for each Token
    function updateUri(uint256 tokenid,string memory URI) onlyRole(ADMIN_ROLE) external {
        require(bytes(_uris[tokenid]).length==0,"Metadata: cannot set uri twice");
        _uris[tokenid]=URI;
    }


    function totalSupply(uint256 tokenId) public view returns(uint256) {
        return _totalSupply[tokenId];
        
    }
    
    

    function totalTokens() public view returns(uint256) {
        return _totalTokenIds.length();
    }

    function totalTokensIdByIndex(uint256 index) public view returns(uint256) {
        return _totalTokenIds.at(index);
    }



    function balanceOfTokens(address owner) public view returns(uint256) {
        return _addressBalance[owner].length();
    }
    
    function tokenOwnedByIndex(address owner, uint256 index) public view returns(uint256) {
        return _addressBalance[owner].at(index);
    }

    /**
    @dev Is limited by the gas limit of each block. only call when the total tokenId is not greater than 36.000.
     in this case call the functions balanceOfTokens to get the total index of the address, 
     and tokenOwnedByIndex to get the tokenId in 
     the address using the Index obtained from the previous function.
    */

    function allTokenIdInAddress(address owner) public view returns(uint256[] memory) {
        uint256 balanceTokens = balanceOfTokens(owner);
        uint256[] memory ids = new uint256[](balanceTokens);
        for (uint256 index = 0; index < balanceTokens; ++index) {
            uint256 tokenId = tokenOwnedByIndex(owner, index);
            ids[index] = tokenId;
        }
        return ids;
    }

    /**
    @dev Is limited by the gas limit of each block. only call when the total tokenId is not greater than 36.000.
     in this case call the functions balanceOfTokens to get the total index of the address, 
     and tokenOwnedByIndex to get the tokenId in 
     the address using the Index obtained from the previous function.
    */

    function allTokenIds() public view returns(uint256[] memory) {
        uint256 balanceTokens = totalTokens();
        uint256[] memory ids = new uint256[](balanceTokens);
        for (uint256 index = 0; index < balanceTokens; ++index) {
            uint256 tokenId = totalTokensIdByIndex(index);
            ids[index] = tokenId;
        }
        return ids;
    }

    function getHashProperties(uint256 tokenId) public view returns(bytes32) {
        return _propertiesHash[tokenId];        
    }


    /**
    @dev if amount is greater than 1, the mintage is a non-fungible token, you cannot mint more of this token in the future.
    but if it is greater than 1, you can mint more of this token in the future - this is a semi-fungible token. 
    The hash of the properties of each token must be provided.
    */
    function mint(address to, uint256 tokenId, uint256 amount,  bytes memory  data) public virtual override {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");
        require(_totalSupply[tokenId] == 0);
         
        _mint(to, tokenId, amount, '');

        _propertiesHash[tokenId] = keccak256(data);
        
        _totalSupply[tokenId] += amount;
       
        _addressBalance[to].add(tokenId);
        _totalTokenIds.add(tokenId);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(false, "ERC1155: MintBatch invalidate");
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual override {
        require(false, "ERC1155: burnBatch invalidate");
    }


    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual override {
        require(hasRole(ADMIN_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");

        require(balanceOf(msg.sender, id) >= 1,  "ERC1155: Token not owned");

        _burn(msg.sender, id, value);

        delete _propertiesHash[id];
        _totalSupply[id] -= value;

        _addressBalance[msg.sender].remove(id);
        _totalTokenIds.remove(id);
    }

    /** 
    @dev Make sure that the token ID corresponds to a Semi-fungible token otherwise the transaction will be reversed.
    */

    function transferTo(address to, uint256 tokenId) internal {
        if(balanceOf(to, tokenId) == 0 ){
            _addressBalance[to].add(tokenId); // add new token to index
        }
    }

    function transferFrom(address from, uint256 tokenId, uint256 amount) internal {
        if (balanceOf(from, tokenId).sub(amount) == 0){
            _addressBalance[from].remove(tokenId); // remove token to index
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override
        {   
            //if SafeTransferFrom update indexing sender/receiver of token
            if(from != address(0)){
                for (uint256 i = 0; i < ids.length; ++i) {
                    uint256 id = ids[i];
                    uint256 amount = amounts[i];
                    transferTo(to, id);
                    transferFrom(from, id, amount);
                }
            }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }


}