const Web3 = require('web3');
const SwapERC20ABI = require('./contracts/SwapERC20ABI.json');
// import SwapERC20ABI from './SwapERC20ABI.json';

// Configure the Web3 provider
const providerUrl = 'https://goerli.infura.io/v3/7f170c3da3a249faa28f1eb9efdbf973';
const web3 = new Web3(providerUrl);

// Configure the contract address and instance
const contractAddress = 'CONTRACT_ADDRESS';
const contractInstance = new web3.eth.Contract(SwapERC20ABI, contractAddress);

// Example function to initiate a swap
async function initiateSwap(initiatorERC20, initiatorAmount, counterPartyERC20, counterPartyAmount, counterParty) {
  try {
    const accounts = await web3.eth.getAccounts();
    const sender = accounts[0];

    // Call the begin function in the smart contract
    const result = await contractInstance.methods
      .begin(initiatorERC20, initiatorAmount, counterPartyERC20, counterPartyAmount, counterParty)
      .send({ from: sender, gas: 3000000 });

    console.log('Swap initiated:', result);
  } catch (error) {
    console.error('Error initiating swap:', error);
  }
}


if (!isConnected) {
  return (
    <div className="App">
      <button onClick={tryConnect}>Connect</button>
    </div>
  );
}

// Example function to cancel a swap
async function cancelSwap(id) {
  try {
    const accounts = await web3.eth.getAccounts();
    const sender = accounts[0];

    // Call the cancel function in the smart contract
    const result = await contractInstance.methods.cancel(id).send({ from: sender, gas: 3000000 });

    console.log('Swap cancelled:', result);
  } catch (error) {
    console.error('Error cancelling swap:', error);
  }
}

// Example function to complete a swap
async function completeSwap(id) {
  try {
    const accounts = await web3.eth.getAccounts();
    const sender = accounts[0];

    // Call the complete function in the smart contract
    const result = await contractInstance.methods.complete(id).send({ from: sender, gas: 3000000 });

    console.log('Swap completed:', result);
  } catch (error) {
    console.error('Error completing swap:', error);
  }
}

// Example function to get swap instances for an address
async function getSwapInstances(address) {
  try {
    const instances = await contractInstance.methods.findInstances(address).call();
    console.log('Swap instances for address', address, ':', instances);
  } catch (error) {
    console.error('Error getting swap instances:', error);
  }
}

// Usage example
async function run() {
  try {
    // Initiate a swap
    await initiateSwap('INITIATOR_ERC20_ADDRESS', 10, 'COUNTERPARTY_ERC20_ADDRESS', 20, 'COUNTERPARTY_ADDRESS');

    // Cancel a swap (provide the swap ID)
    await cancelSwap(1);

    // Complete a swap (provide the swap ID)
    await completeSwap(1);

    // Get swap instances for an address (provide the address)
    await getSwapInstances('ADDRESS');
  } catch (error) {
    console.error('Error:', error);
  }
}

run();
