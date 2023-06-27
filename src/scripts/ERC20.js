const { ethers } = require("hardhat");

const deployERC20 = async () => {
  const ERC20 = await ethers.getContractFactory("ERC20");
  const erc20 = await ERC20.deploy("Test", "TST");
  await erc20.deployed();
  console.log("ERC20 deployed at address:", erc20.address);
};

deployERC20().catch((error) => {
  console.error(error);
});
