const { ethers } = require("hardhat");

async function main() {
  const CrossLendDAO = await ethers.getContractFactory("CrossLendDAO");
  const crossLendDAO = await CrossLendDAO.deploy();

  await crossLendDAO.deployed();

  console.log("CrossLendDAO contract deployed to:", crossLendDAO.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
