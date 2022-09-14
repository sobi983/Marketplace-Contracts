const {time,loadFixture,} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");
var colors = require('colors');

describe(colors.red("Onion Auction testing").bgGreen, function () {
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

  let owner, buyer1, buyer2, buyer3, buyer4, PrimaryMP, treasureWallet, Royalties, AtheleteAddress, FedAddress, operationalWallet, ERC1155, ERC20BytesAddress, user1, user2, user3, user4, user5;

  it("Deployment of Primary Market Place Contract", async ()=>{

    [owner,  buyer1, buyer2, buyer3, buyer4, treasureWallet, operationalWallet, AtheleteAddress, AtheleteAddress1, FedAddress, FedAddress1, user1, user2, user3, user4, user5 ] = await ethers.getSigners();
    console.log(colors.cyan("Owner Address"),owner.address.brightWhite)
    console.log(colors.cyan("Buyer1 Address"),buyer1.address.brightWhite)
    console.log(colors.cyan("Treasure Wallet Address"),treasureWallet.address.brightWhite)
    console.log(colors.cyan("Operational Wallet Address"),operationalWallet.address.brightWhite)
    console.log(colors.cyan("Athelete Address"),AtheleteAddress.address.brightWhite)
    console.log(colors.cyan("Federation Address"),FedAddress.address.brightWhite)
  
    const E = await ethers.getContractFactory("ExSports")
    const R = await ethers.getContractFactory("Royalties")
    const _ERC20 = await ethers.getContractFactory("ExCoin")
    const P = await ethers.getContractFactory("SingleSell")
    const S = await ethers.getContractFactory("MarketPlace")
    
    ERC1155 = await E.deploy("")
    Royalties = await R.deploy(operationalWallet.address)
    ERC20 = await _ERC20.deploy("ExCoin","EXS",18)
    ERC20BytesAddress = await Royalties.calculateAddressHash(ERC20.address)
    SecondaryMP = await S.deploy(ERC1155.address, Royalties.address, ERC20BytesAddress.hash)
    PrimaryMP = await P.deploy(ERC1155.address, treasureWallet.address, Royalties.address, ERC20BytesAddress.hash )
 
    ERC20.deployed();
    ERC1155.deployed();
    Royalties.deployed();
    PrimaryMP.deployed();
    SecondaryMP.deployed();
  })

  //Deposite 500 and transfer it into user1-4 accounts for buying purposes
  it("Calling Deposit in the ERC20 contract", async function(){
    await ERC20.deposit(owner.address, "0x00000000000000000000000000000000000000000000001b1ae4d6e2ef500000")
    expect(await ERC20.balanceOf(owner.address)).to.equal("500000000000000000000")
  })

  it("Splitting the EXS tokens into different accounts", async()=>{
    await ERC20.transfer(user1.address,"100000000000000000000")
    expect(await ERC20.balanceOf(user1.address)).to.equal("100000000000000000000")

    await ERC20.transfer(user2.address,"100000000000000000000")
    expect(await ERC20.balanceOf(user2.address)).to.equal("100000000000000000000")
    
    await ERC20.transfer(user3.address,"100000000000000000000")
    expect(await ERC20.balanceOf(user3.address)).to.equal("100000000000000000000")
    
    await ERC20.transfer(user4.address,"100000000000000000000")
    expect(await ERC20.balanceOf(user4.address)).to.equal("100000000000000000000")
  })

  it("Approving 25 tokens to the MP contract for buying purposes", async()=>{
    await ERC20.connect(user1).approve(PrimaryMP.address, "100000000000000000000")
    expect(await ERC20.allowance(user1.address, PrimaryMP.address)).to.equal("100000000000000000000")

    await ERC20.connect(user2).approve(PrimaryMP.address, "25000000000000000000")
    expect(await ERC20.allowance(user2.address, PrimaryMP.address)).to.equal("25000000000000000000")

    await ERC20.connect(user3).approve(PrimaryMP.address, "25000000000000000000")
    expect(await ERC20.allowance(user3.address, PrimaryMP.address)).to.equal("25000000000000000000")

    await ERC20.connect(user4).approve(PrimaryMP.address, "25000000000000000000")
    expect(await ERC20.allowance(user4.address, PrimaryMP.address)).to.equal("25000000000000000000")

    //   console.log(await ERC20.balanceOf(owner.address))
    expect(await ERC20.totalSupply()).to.equal("500000000000000000000")
  })

  it("Minting tokens form the ERC1155 from the buyer's addresses", async()=>{
    await ERC1155.grantRole(await ERC1155.MINTER_ROLE(), buyer1.address)
    await ERC1155.grantRole(await ERC1155.MINTER_ROLE(), buyer2.address)
    await ERC1155.grantRole(await ERC1155.MINTER_ROLE(), buyer3.address)
    await ERC1155.grantRole(await ERC1155.MINTER_ROLE(), buyer4.address)
    expect(await ERC1155.hasRole(await ERC1155.MINTER_ROLE(),buyer1.address)).to.equal(true)

    await ERC1155.connect(buyer1).mint(buyer1.address, 1, 5, "0x")
    await ERC1155.connect(buyer2).mint(buyer2.address, 2, 5, "0x")
    await ERC1155.connect(buyer3).mint(buyer3.address, 3, 5, "0x")
    await ERC1155.connect(buyer4).mint(buyer4.address, 4, 5, "0x")
    expect(await ERC1155.balanceOf(buyer1.address, 1)).to.equal(5)
    expect(await ERC1155.totalSupply(1)).to.equal(5)
  })

  it("Approving All the ERC1155 to the Marketplace contract", async()=>{
    await ERC1155.connect(buyer1).setApprovalForAll(PrimaryMP.address, true)
    await ERC1155.connect(buyer2).setApprovalForAll(PrimaryMP.address, true)
    await ERC1155.connect(buyer3).setApprovalForAll(PrimaryMP.address, true)
    await ERC1155.connect(buyer4).setApprovalForAll(PrimaryMP.address, true)
    expect(await ERC1155.connect(buyer1).isApprovedForAll(buyer1.address, PrimaryMP.address)).to.equal(true)
  })

  it("Adding new Category to the Royalties contract", async()=>{
    await Royalties._addNewCategoryBatch([1], [8000], [1000])
    expect(await Royalties.getAthletefee(1)).to.equal(8000)
    expect(await Royalties.getFedrationfee(1)).to.equal(1000)
    
    await Royalties._addNewCategoryBatch([2], [5000], [4000])
    expect(await Royalties.getAthletefee(2)).to.equal(5000)
    expect(await Royalties.getFedrationfee(2)).to.equal(4000)

  })

  it("Adding addresses", async()=>{
    await Royalties._addRoyaltiesAddress(1, AtheleteAddress.address, FedAddress.address, 1)
    expect(await Royalties.getAthleteAddress(1)).to.equal(AtheleteAddress.address)
    expect(await Royalties.getFedrationAddress(1)).to.equal(FedAddress.address)
    expect(await Royalties.id(1)).to.equal(true)
    
    await Royalties._addRoyaltiesAddress(2, AtheleteAddress1.address, FedAddress1.address, 2)
    expect(await Royalties.getAthleteAddress(2)).to.equal(AtheleteAddress1.address)
    expect(await Royalties.getFedrationAddress(2)).to.equal(FedAddress1.address)
    expect(await Royalties.id(2)).to.equal(true)
  })

  it("Adding currency to the Primary Marketplace Contract and checking the remvoving functionality of the currency", async()=>{
    await PrimaryMP.addCurrency(ERC20BytesAddress.hash, ERC20.address)
    expect(await PrimaryMP.addressCurrency(ERC20BytesAddress.hash)).to.equal(ERC20.address)
    // console.log(await PrimaryMP.allCurrenciesAllowed())

    //removing currency
    // await PrimaryMP.removeCurrency(ERC20BytesAddress.hash)
    // console.log(await PrimaryMP.allCurrenciesAllowed())
  })

  it("Checking the Roles and Create a Auction", async()=>{
    await PrimaryMP.grantRole(await PrimaryMP.AUCTIONER_ROLE(), buyer1.address)
    await PrimaryMP.grantRole(await PrimaryMP.AUCTIONER_ROLE(), buyer2.address)
    await PrimaryMP.grantRole(await PrimaryMP.AUCTIONER_ROLE(), buyer3.address)
    await PrimaryMP.grantRole(await PrimaryMP.AUCTIONER_ROLE(), buyer4.address)

    try{
        await PrimaryMP.renounceRole(await PrimaryMP.ADMIN_ROLE(), buyer1.address)
    }catch(err){
        if(err){
        console.log(colors.rainbow("     Error Generated on purpose"))
        }
      }

       
      await PrimaryMP.grantRole(await PrimaryMP.DEFAULT_ADMIN_ROLE(), buyer2.address)
    //   expect(await PrimaryMP.hasRole(await PrimaryMP.ADMIN_ROLE(),buyer2.address)).to.equal(true)
      await PrimaryMP.connect(buyer2).grantRole(await PrimaryMP.AUCTIONER_ROLE(), buyer3.address)

    //The owner can revoke the roles of the other but they cannot revoke their own roles
    //   await PrimaryMP.connect(buyer2).revokeRole(await PrimaryMP.TREASURER_ROLE(), treasureWallet.address)
    //   await PrimaryMP.connect(treasureWallet).revokeRole(await PrimaryMP.TREASURER_ROLE(), treasureWallet.address)
    //   await PrimaryMP.connect(treasureWallet).renounceRole(await PrimaryMP.TREASURER_ROLE(), treasureWallet.address)
    //   await PrimaryMP.revokeRole(await PrimaryMP.AUCTIONER_ROLE(), buyer1.address) 
    //   await PrimaryMP.connect(buyer1).renounceRole(await PrimaryMP.AUCTIONER_ROLE(), buyer1.address) 
    

  })

  // it("Creating and removing the auction",async()=>{
  //     await PrimaryMP.connect(buyer1).createOnionAuction([1], buyer1.address, ERC20BytesAddress.hash, [5], [5], [10])    
  //     expect(await ERC1155.balanceOf(PrimaryMP.address, 1)).to.equal(5)
  //     await PrimaryMP.connect(buyer1).cancelOnionAuction([1])
  //     //   console.log(await PrimaryMP.onionAuctionDetails(1))
  // })
    
  it("Creating multiple auction using different accounts", async()=>{
    await PrimaryMP.connect(buyer1).createOnionAuction([1], buyer1.address, ERC20BytesAddress.hash, [5], ["10000000000000000000"], [10]) 
    expect(await ERC1155.balanceOf(PrimaryMP.address, 1)).to.equal(5)   
    await PrimaryMP.connect(buyer2).createOnionAuction([2], buyer2.address, ERC20BytesAddress.hash, [5], ["10000000000000000000"], [10])    
    await PrimaryMP.connect(buyer3).createOnionAuction([3], buyer3.address, ERC20BytesAddress.hash, [5], [5], [10])    
    await PrimaryMP.connect(buyer4).createOnionAuction([4], buyer4.address, ERC20BytesAddress.hash, [5], [5], [10])    
    // console.log(await PrimaryMP.getAllOnionsId())
  })

  it("Buy the nfts through the users account from the auctions", async()=>{   
   
    // for (let i = 0; i < 4; i++) {
    //     await PrimaryMP.connect(user1).buyCard(2, user1.address)
    // }
    await PrimaryMP.connect(user1).buyCard(1, user1.address)
    expect(await ERC1155.balanceOf(user1.address, 1)).to.equal(1)

    await PrimaryMP.connect(user1).buyCard(2, user1.address)
    expect(await ERC1155.balanceOf(user1.address, 2)).to.equal(1)


    // expect(await ERC20.balanceOf(user1.address)).to.equal(20)
    
    //   await PrimaryMP.connect(user2).buyCard(2, user2.address)
    // console.log(await PrimaryMP.getAllOnionsId())
  })

  it("Checking the distributions of the %ages between the stakeholders", async()=>{
    // expect(await ERC20.balanceOf(treasureWallet.address)).to.equal("1925000000000000000")
    // expect(await ERC20.balanceOf(FedAddress.address)).to.equal("1925000000000000000")
    // expect(await ERC20.balanceOf(AtheleteAddress.address)).to.equal("15400000000000000000")
    // expect(await ERC20.balanceOf(operationalWallet.address)).to.equal("750000000000000000")
    console.log(await ERC20.balanceOf(treasureWallet.address))
    console.log(await ERC20.balanceOf(FedAddress.address))
    console.log(await ERC20.balanceOf(AtheleteAddress.address))
    console.log(await ERC20.balanceOf(operationalWallet.address))

    console.log("...........................")

    console.log(await ERC20.balanceOf(FedAddress1.address))
    console.log(await ERC20.balanceOf(AtheleteAddress1.address))


  })

  it("Adding currency in Secondary MP", async()=>{
    await SecondaryMP.addCurrency(ERC20BytesAddress.hash, ERC20.address)
    expect(await SecondaryMP.addressCurrency(ERC20BytesAddress.hash)).to.equal(ERC20.address)
  })

  it("Creating auction on Secondary Marketplace", async()=>{
    await ERC1155.connect(user1).setApprovalForAll(SecondaryMP.address, true)
    await SecondaryMP.connect(user1).createUserAuction([1], user1.address, ERC20BytesAddress.hash, [1], [100], [2])
    // console.log(await SecondaryMP.validAuctionDetails("1"))
  })

  it("Skipping time like Hit and buying the id from the other user", async()=>{
    await ethers.provider.send("evm_increaseTime", [9006111])
    await SecondaryMP.connect(user1)._updateUserAuction(1,200,1)


    console.log(await ERC20.balanceOf(user1.address))

    await ERC20.connect(user2).approve(SecondaryMP.address, 200)
    await SecondaryMP.connect(user2).buyCard(1, user2.address)
    console.log(await ERC20.balanceOf(user2.address))
    expect(await ERC1155.balanceOf(user2.address, 1)).to.equal(1)
    console.log(await ERC20.balanceOf(user1.address))
  })
          
 
});
                                                  
    