require("dotenv").config();
const thetajs = require("@thetalabs/theta-js");

const privateKey = process.env.PRIVATE_KEY;
const network = process.env.NETWORK;

let provider = new thetajs.providers.HttpProvider(
  thetajs.networks.ChainIds.Testnet
);
if (network == "mainnet") {
  provider = new thetajs.providers.HttpProvider(
    thetajs.networks.ChainIds.Mainnet
  );
}
if (network == "privatenet") {
  provider = new thetajs.providers.HttpProvider(
    thetajs.networks.ChainIds.Privatenet
  );
}

const openWallet = new thetajs.Wallet(privateKey);

const wallet = openWallet.connect(provider);

module.exports = { wallet };
