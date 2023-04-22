const { expect } = require("chai");
const { ethers } = require("hardhat");
const {
  BN,           // Big Number support
  constants,    // Common constants, like the zero address and largest integers
  expectEvent,  // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');
require("@nomiclabs/hardhat-truffle5");
const helpers = require("@nomicfoundation/hardhat-network-helpers");

describe("Gaming Tournament Contest", function () {
  var GamingInstance;
  let participants = 4;
    it("Contract deployment", async function () {
      const GamingContest = await ethers.getContractFactory("GamingContest");
      GamingInstance = await GamingContest.deploy();
      await GamingInstance.deployed();
      console.log(`Contract Address : `,GamingInstance.address);
    });

    it(`addTournament Function`,async()=>{
      const [owner,user1,user2] = await ethers.getSigners();
      let add = await GamingInstance.connect(owner).addTournament(participants)
    })

    it(`JoinTournament Function`,async()=>{
      let tournamentID = 1
      let entryfee = "1000000000000000000"
      const [owner,user1,user2,user3,user4] = await ethers.getSigners();
      await GamingInstance.connect(user1).joinTournament(tournamentID,{value : entryfee})
      await GamingInstance.connect(user2).joinTournament(tournamentID,{value : entryfee})
      await GamingInstance.connect(user3).joinTournament(tournamentID,{value : entryfee})
      await GamingInstance.connect(user4).joinTournament(tournamentID,{value : entryfee})

    })



    it(`addScore Function`,async()=>{
      let tournamentID = 1
      const [owner,user1,user2,user3,user4] = await ethers.getSigners();
      await GamingInstance.connect(owner).addScore(tournamentID,user1.address,100)
      await GamingInstance.connect(owner).addScore(tournamentID,user2.address,200)
      await GamingInstance.connect(owner).addScore(tournamentID,user4.address,500)
      await GamingInstance.connect(owner).addScore(tournamentID,user3.address,30)
    })

    it(`GetLeaderBoard`,async()=>{
      let tournamentID = 1
      await helpers.time.increase(3600);
      const [owner] = await ethers.getSigners();
      await GamingInstance.connect(owner).getLeaderboard(tournamentID)
    })

    it(`Announce the winner`,async()=>{
      const [owner,user1,user2,user3,user4] = await ethers.getSigners();
      const balancebeforeUser1 = await user1.getBalance(); 
      console.log(`balancebeforeUser1`,balancebeforeUser1/1e18);

      const balancebeforeUser2 = await user2.getBalance(); 
      console.log(`balancebeforeUser2`,balancebeforeUser2/1e18);

      const balancebeforeUser3 = await user3.getBalance(); 
      console.log(`balancebeforeUser3`,balancebeforeUser3/1e18);

      const balancebeforeUser4 = await user4.getBalance(); 
      console.log(`balancebeforeUser4`,balancebeforeUser4/1e18);

      let tournamentID = 1
      let winner = await GamingInstance.connect(owner).announceWinner(tournamentID);
      
      const balanceafterUser1 = await user1.getBalance(); 
      console.log(`balanceafterUser1`,balanceafterUser1/1e18);

      const balanceafterUser2 = await user2.getBalance(); 
      console.log(`balanceafterUser2`,balanceafterUser2/1e18);

      const balanceafterUser3 = await user3.getBalance(); 
      console.log(`balanceafterUser3`,balanceafterUser3/1e18);

      const balanceafterUser4 = await user4.getBalance(); 
      console.log(`balanceafterUser4`,balanceafterUser4/1e18);


      // => 4e18 * 60/100(user 4 winning calculation )
      // 2400000000000000000
      // => 4e18 * 40/100(user 2 winning calculation )
      // 1600000000000000000
      // => 4e18 * 10/100(user 1 winning calculation )
      // 400000000000000000
  })

});