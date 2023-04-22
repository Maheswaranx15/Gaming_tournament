// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const fs = require("fs");

async function main() {

  const Contest = await hre.ethers.getContractFactory("GamingContest");
  const contest = await Contest.deploy();
  await contest.deployed();

  console.log(
    `Tournament Gaming contract deployment address`, contest.address
  );


  const GamingContestdata = {
    address: contest.address,
    abi: JSON.parse(contest.interface.format('json'))
  }

  fs.writeFileSync('./GameTournament.json', JSON.stringify(GamingContestdata))

  //Verify the smart contract using hardhat 
  await hre.run("verify:verify", {
    address: contest.address,
  });

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
