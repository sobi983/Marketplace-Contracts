const {time,loadFixture,} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");
var colors = require('colors');

describe(colors.red("EXS TOken Testing").bgGreen, function () {
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

  let owner, buyer1, ERC20

  it("Deployment of ERC20 Token", async ()=>{
    [owner,  buyer1 ] = await ethers.getSigners();
    console.log(colors.cyan("Owner Address"),owner.address.brightWhite)
    console.log(colors.cyan("Buyer 1 Address"),buyer1.address.brightWhite)
  

    const _ERC20 = await ethers.getContractFactory("ChildERC20")
    ERC20 = await _ERC20.deploy("ExCoin","EXS",18)
    ERC20.deployed()
  })

  it("Checking all the function of the ERC20 contract", async ()=>{
    expect(await  ERC20.getMaxSupply()).to.equal("100000000000000000000")

    try{
      await ERC20.connect(buyer1).deposit(buyer1.address,  ethers.utils.hexZeroPad(ethers.utils.hexlify(200), 32))
    }catch(err){
      if(err){
        console.log(colors.rainbow("     Error Generated on purpose"))
      }
    }






    await ERC20.deposit(owner.address, ethers.utils.hexZeroPad(ethers.utils.hexlify(100), 32))  //minted
    expect(await ERC20.totalSupply()).to.equal("100")
    expect(await ERC20.balanceOf(owner.address)).to.equal("100")
    expect(await ERC20.balanceOf(buyer1.address)).to.equal("0")

    try{
      await ERC20.transferFrom(owner.address, buyer1.address, 10)
    }catch(err){
      if(err){
        console.log(colors.rainbow("     Error Generated on purpose"))
      }
    }
    
    await ERC20.connect(owner).approve(buyer1.address,"10")
    await ERC20.connect(buyer1).transferFrom( owner.address, buyer1.address, "10")

    
    await ERC20.withdraw("90") //burn
    expect(await ERC20.totalSupply()).to.equal("10")

    await ERC20.increaseAllowance(buyer1.address,1)

    expect(await ERC20.allowance(owner.address, buyer1.address)).to.equal("1")
    await ERC20.decreaseAllowance(buyer1.address,1)
    expect(await ERC20.allowance(owner.address, buyer1.address)).to.equal("0")
    

    try{
      await ERC20.withdraw("1")
    }catch(err){
      if(err){
        console.log(colors.rainbow("     Error Generated on purpose"))
      }
    }
  })
});
