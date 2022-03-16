globalThis.fetch = require("node-fetch");
const argv = require("minimist")(process.argv.slice(2));
const fs = require("fs");

const thetajs = require("@thetalabs/theta-js");
const wallet = require("./utils/signer.js").wallet;

async function read_artifact(path) {
  const data = fs.readFileSync(path, "utf8");
  return JSON.parse(data);
}

async function deploy(artifact, args) {
  const contractToDeploy = new thetajs.ContractFactory(
    artifact.abi,
    artifact.bytecode,
    wallet
  );
  let result;
  if (argv.S) {
    result = await contractToDeploy.simulateDeploy(...eval(args));
  } else {
    result = await contractToDeploy.deploy(...eval(args));
  }
  return result;
}

async function mint(add, artifact) {
  const contract = new thetajs.Contract(add, artifact.abi, wallet);

  const result = await contract.mint(
    "0x2Ee6480c6FD8b71F0a6877baE97991e8d6062F4d",
    "https://picsum.photos/seed/test/250"
  );
  return result;
}

async function main() {
  const artifact = await read_artifact(argv.artifact);
  const result = await deploy(artifact, argv.args);

  console.log(`
  --------------------------------------------------------------------------------------------
                Deployed contract to: ${result.contract_address}
                Gas used:             ${result.gas_used}
  --------------------------------------------------------------------------------------------
  `);

  const minted = await mint(result.contract_address, artifact);
  console.log(minted);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
