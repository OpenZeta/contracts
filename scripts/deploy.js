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

async function main() {
  const artifact = await read_artifact(argv.artifact);
  const result = await deploy(artifact, argv.args);

  console.log(`
  --------------------------------------------------------------------------------------------
                Deployed contract to: ${result.contract_address}
                Gas used:             ${result.gas_used}
  --------------------------------------------------------------------------------------------
  `);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
