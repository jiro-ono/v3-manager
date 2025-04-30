import type { HardhatRuntimeEnvironment } from "hardhat/types";
import type { DeployFunction } from "hardhat-deploy/types";
import { WNATIVE_ADDRESS } from "sushi/currency";
import {
	isRedSnwapperChainId,
	RED_SNWAPPER_ADDRESS,
} from "sushi/config";
import { EvmChainId } from "sushi/chain";
import { zeroAddress } from "viem";

const getOperatorAddress = (_chainId: EvmChainId) =>
	process.env.OPERATOR_ADDRESS;
const getOwnerAddress = (chainId: EvmChainId) => getOperatorAddress(chainId);
const getRedSnwapperAddress = (chainId: EvmChainId) =>
	isRedSnwapperChainId(chainId)
		? RED_SNWAPPER_ADDRESS[chainId]
		: undefined;
const getTokenAddress = (chainId: EvmChainId) =>
	chainId === EvmChainId.SKALE_EUROPA ? zeroAddress : WNATIVE_ADDRESS[chainId];

const instanceCount = 3;

const func: DeployFunction = async ({
	ethers,
	deployments,
	getChainId,
}: HardhatRuntimeEnvironment) => {
	const { deploy } = deployments;
	const chainId = +(await getChainId()) as EvmChainId;
	const { deployer } = await ethers.getNamedSigners();

	const operator = getOperatorAddress(chainId);
	const redSnwapper = getRedSnwapperAddress(chainId);
	const weth9 = getTokenAddress(chainId);
	const owner = getOwnerAddress(chainId);

	if (!deployer) throw new Error("Deployer not configured");
	if (!operator) throw new Error("Operator not found on this network");
	if (!redSnwapper) throw new Error("RedSnwapper not found on this network");
	if (!weth9) throw new Error("WETH9 not found on this network");
	if (!owner) throw new Error("Owner not found on this network");

	console.log("Deployer address:", deployer.address);

	const deployedContracts: { name: string; address: string }[] = [];

	for (let i = 0; i < instanceCount; i++) {
		const name = `TokenChwomper_${i}`;

		console.log('⏳ Deploying', name)
	  
		try {
			const { address, newlyDeployed } = await deploy(name, {
			contract: "TokenChwomper",
			from: deployer.address,
			args: [operator, redSnwapper, weth9],
			});

			console.log(`✅ ${name} ${newlyDeployed ? "deployed" : "already exists"} at`, address);
			deployedContracts.push({ name, address });

			if (newlyDeployed) await new Promise(resolve => setTimeout(resolve, 5000));
		} catch (error) {
			console.error(`❌ Deployment FAILED for ${name}`);
			console.error(error);
			console.error("⛔ Halting further deployments.");
			process.exit(1);
		}
	}

	for (const { name, address } of deployedContracts) {
		try {
		  const TokenChwomper = await ethers.getContractAt("TokenChwomper", address, deployer);

		  const currentOwner = await TokenChwomper.owner();

		  if (currentOwner.toLowerCase() === owner.toLowerCase()) {
			console.log(`✅ Skipping ${name}: already owned by ${owner}`);
			continue;
		  }

		  if (currentOwner.toLowerCase() !== deployer.address.toLowerCase()) {
			console.warn(`⚠️ Skipping ${name}: deployer is not current owner (owner is ${currentOwner})`);
			continue;
		  }

		  console.log(`⏳ Transferring ownership of ${name} at ${address} to ${owner}`);
		  const tx = await TokenChwomper.transferOwnership(owner);
		  await tx.wait();
		  console.log(`✅ Ownership transferred for ${name}`);
		} catch (error) {
		  console.error(`❌ Ownership transfer FAILED for ${name} at ${address}`);
		  console.error(error);
		  console.error("⛔ Halting further ownership transfers due to error.");
		  break;
		}
	}
};

func.tags = ["TokenChwomper"];

export default func;
