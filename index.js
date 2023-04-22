// Import required dependencies
const express = require('express');
const Web3 = require('web3');
const tournamentContract = require('./GameTournament.json');

// Set up web3 provider and contract instance
const web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545'));
const contractInstance = new web3.eth.Contract(tournamentContract.abi, tournamentContract.address);

// Set up Express server
const app = express();
const port = 3000;

// POST route to create a new tournament
app.post('/tournament', async (req, res) => {
  try {
    const result = await contractInstance.methods.createTournament(req.body.name, req.body.date).send({ from: '0x123456789abcdef123456789abcdef123456789', gas: 500000 });
    res.send(result);
  } catch (error) {
    console.error(error);
    res.status(500).send(error);
  }
});

app.get('/tournaments', async (req, res) => {
    try {
      const events = await contractInstance.getPastEvents('TournamentCreated', { fromBlock: 0 });
      const tournaments = events.map(event => event.returnValues.tournamentId);
      res.json(tournaments);
    } catch (error) {
      console.error(error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  });

// GET route to retrieve leaderboard information
app.get('/leaderboard', async (req, res) => {
  try {
    const result = await contractInstance.methods.getLeaderboard().call();
    res.send(result);
  } catch (error) {
    console.error(error);
    res.status(500).send(error);
  }
});

// Start the server
app.listen(port, () => {
  console.log(`Server listening at http://localhost:${port}`);
});
