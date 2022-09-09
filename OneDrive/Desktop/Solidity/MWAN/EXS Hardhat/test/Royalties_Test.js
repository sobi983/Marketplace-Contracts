const {time,loadFixture,} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");
var colors = require('colors');
const { TASK_COMPILE_SOLIDITY_GET_SOURCE_NAMES } = require("hardhat/builtin-tasks/task-names");

describe(colors.red("Royalties Testing ").bgGreen, function () {
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

  let owner, user, operationalWallet, athelete, fed, Royalties

  it("Deployment of Royalties Contract", async ()=>{
    [owner, user, operationalWallet, athelete, fed] = await ethers.getSigners();
    console.log(colors.cyan("Owner Address"), owner.address.brightWhite)
    console.log(colors.cyan("User Address"), user.address.brightWhite)
    console.log(colors.cyan("Operational Wallet Address"), operationalWallet.address.brightWhite)
    console.log(colors.cyan("Athelete Wallet Address"), athelete.address.brightWhite)
    console.log(colors.cyan("Fed Address"), fed.address.brightWhite)
  
    const R = await ethers.getContractFactory("Royalties")
    Royalties = await R.deploy(operationalWallet.address)
    Royalties.deployed()
  })

  it("Testing of adding new batch category batch", async()=>{
    await Royalties._addNewCategoryBatch([1], [8000], [1000])
    await Royalties._addRoyaltiesAddress("1", athelete.address, fed.address, "1")
    expect(await Royalties.category(1)).to.equal(true)
  })

  it("Updating transaction fees", async()=>{
    await Royalties.updateTransactionFee(200)
    expect(await Royalties.TransactionFee()).to.equal("200")
    
    try{
        await Royalties.connect(operationalWallet).updateTransactionFee(100)
    }catch(err){
        if(err){console.log(colors.rainbow("     Error Generated on purpose"))}
    }
  })

  it("Testing the royalties and fees adding through the different wallet address other than owner", async()=>{
    try{
    await Royalties.connect(user)._addNewCategoryBatch([2], [9000], [1000])
    }catch(err){
    if(err){console.log(colors.rainbow("     Error Generated on purpose"))}

    await Royalties._updateCategory(1, 9000, 1000)
    // console.log(await Royalties.getRoyaltiesfee("1"))
    
    // await Royalties.connect(user.address)._updateCategory(1, 9000, 1000) //will generate error
}
  })
});
