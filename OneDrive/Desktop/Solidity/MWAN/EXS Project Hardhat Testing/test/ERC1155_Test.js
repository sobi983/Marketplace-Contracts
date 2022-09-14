const {time,loadFixture,} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");
var colors = require('colors');
const { TASK_COMPILE_SOLIDITY_GET_SOURCE_NAMES } = require("hardhat/builtin-tasks/task-names");

describe(colors.red("ERC1155 Contract Testing").bgGreen, function () {
  colors.setTheme({
    silly: 'rainbow',
    input: 'grey',
    verbose: 'cyan',
    prompt: 'grey',
    info: 'green',
    data: 'grey',
    help: 'cyan',
    warn: 'yellow',
    debug: 'blue',
    error: 'red'
  });

  let owner, admin, minter1, minter2, ERC1155

  it("Deployment of ERC1155 Token", async ()=>{
    [owner,admin, minter1, minter2] = await ethers.getSigners();
    console.log(colors.cyan("Owner Address"), owner.address.brightWhite)
    console.log(colors.cyan("Admin1 Address"), admin.address.brightWhite)
    console.log(colors.cyan("Minter1 Address"), minter1.address.brightWhite)
    console.log(colors.cyan("Minter2 Address"), minter2.address.brightWhite)



    const _ERC155 = await ethers.getContractFactory("ExSports")
    ERC1155 = await _ERC155.deploy("")
    ERC1155.deployed()
  })

  it("Grant Admin access to address", async ()=>{
    
    await ERC1155.grantRole(await ERC1155.ADMIN_ROLE(),admin.address)
    expect(await ERC1155.hasRole(await ERC1155.ADMIN_ROLE(),admin.address)).to.equal(true)

    try{
        await ERC1155.connect(minter1).grantRole((await ERC1155.ADMIN_ROLE(),admin.address))
    }catch(err){
        if(err){
            console.log(colors.rainbow("     Error Generated on purpose"))
        }
    }
    
    await ERC1155.grantRole(await ERC1155.MINTER_ROLE(), minter1.address)
    expect(await ERC1155.getRoleMemberCount(ERC1155.ADMIN_ROLE())).to.equal("2") //owner, admin1, 
    expect(await ERC1155.getRoleMemberCount(ERC1155.MINTER_ROLE())).to.equal("2")  //minter1  owner

  })

  it("Revoke roles",async ()=>{
    try{
        await ERC1155.connect(minter1).revokeRole(await ERC1155.ADMIN_ROLE(),owner.address)
    }catch(err){
        if(err){
            console.log(colors.rainbow("     Error Generated on purpose"))
        }
    }

    try{
        await ERC1155.connect(admin).revokeRole(await ERC1155.ADMIN_ROLE(),minter1.address)
    }catch(err){
        if(err){
            console.log(colors.rainbow("     Error Generated on purpose"))
        }
    }

    try{
        await ERC1155.connect(admin).revokeRole(await ERC1155.MINTER_ROLE(),minter1.address)
    }catch(err){
        if(err){
            console.log(colors.rainbow("     Error Generated on purpose"))
        }
    }

    await ERC1155.revokeRole(await ERC1155.ADMIN_ROLE(),admin.address)

    try{
        await ERC1155.revokeRole(await ERC1155.MINTER_ROLE(),minter1.address)
    }catch(err){
        if(err){
            console.log(colors.rainbow("     Error Generated on purpose"))
        }
    }

  })

  it('Renounce roles', async()=>{
    await ERC1155.connect(minter1).renounceRole(await ERC1155.MINTER_ROLE(), minter1.address)

    expect(await ERC1155.getRoleMemberCount(ERC1155.ADMIN_ROLE())).to.equal("1") 
    expect(await ERC1155.getRoleMemberCount(ERC1155.MINTER_ROLE())).to.equal("1") 

    expect(await ERC1155.getRoleMember(await ERC1155.ADMIN_ROLE(),0)).to.equal(owner.address)
  })

  it("Assigning Admin role to other person donesn't gives him the access to mint the tokens until and unless he/she have the minter role", async()=>{
    await ERC1155.mint(owner.address, "1", "11", "0x")
    expect(await ERC1155.balanceOf(owner.address,"1")).to.equal("11")
    // console.log(await ERC1155.balanceOf(owner.address,"1"))
    
    await ERC1155.grantRole(await ERC1155.ADMIN_ROLE(), admin.address)
    
    try{
        await ERC1155.connect(admin).mint(owner.address, "2", "2", "0x")
    }catch(err){
        if(err)
        console.log(colors.rainbow("     Error Generated on purpose"))
    }
    
    await ERC1155.grantRole(await ERC1155.MINTER_ROLE(), admin.address)
    await ERC1155.connect(admin).mint(owner.address, "2", "2", "0x")
    

    expect(await ERC1155.balanceOfTokens(owner.address)).to.equal(2)
    expect(await ERC1155.totalTokens()).to.equal("2")
})

it("Minting the other tokens from the minter and the owner and testing the sums of the tokens", async()=>{
    await ERC1155.grantRole(await ERC1155.MINTER_ROLE(), minter1.address)
    await ERC1155.connect(minter1).mint(minter1.address,"3","3", "0x")
    expect(await ERC1155.balanceOf(minter1.address, 3)).to.equal("3")
    //owner have minted tokenID 1,2 and minter1 have minted tokenID 3
})

it("Testing the burning mechanism", async()=>{
  // the burn function is not executable 
})

it("Testing the transfer function", async()=>{
    await ERC1155.connect(minter1).safeTransferFrom(minter1.address, owner.address, "3", "3", "0x")
    // console.log(await ERC1155.allTokenIdInAddress(owner.address))
})

it("Testing the approval function for the safeTransfer", async()=>{
    await ERC1155.setApprovalForAll(minter1.address, true)
    await ERC1155.connect(minter1).safeTransferFrom(owner.address, minter1.address, "1", "11", "0x")
    // console.log(await ERC1155.allTokenIdInAddress(owner.address))
})
});
