const { HardhatUserConfig } = require("hardhat/config");

const config = {
  solidity: "0.8.9",
  defaultNetwork: "zen",
  networks: {
    zen: {
      url: 'https://gobi-testnet.horizenlabs.io/ethv1',
      accounts: { mnemonic: "please dinner coast donor round decline gun drift fun menu shallow year" },
      gasPrice: "auto"
    }
  }
};

module.exports = config;
