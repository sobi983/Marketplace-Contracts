
async function main() {
  const [deployer] = await ethers.getSigners(); 

  console.log("Deploying contracts with the account:", deployer.address); 

 
  const AURAStaking = await hre.ethers.getContractFactory("ChildERC20"); 
  const staking = await AURAStaking.deploy("EXS", "EXS", "18"); 
  await staking.deployed(); 


  console.log("Staking deployed to:", staking.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 