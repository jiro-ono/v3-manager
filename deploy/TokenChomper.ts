import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { SKL, WNATIVE_ADDRESS } from "sushi/currency";
import {
	isRouteProcessor6ChainId,
	ROUTE_PROCESSOR_6_ADDRESS,
} from "sushi/config";
import { EvmChainId } from "sushi/chain";

const getOperatorAddress = (_chainId: EvmChainId) =>
	process.env.OPERATOR_ADDRESS;
const getOwnerAddress = (chainId: EvmChainId) => getOperatorAddress(chainId);
const getRPAddress = (chainId: EvmChainId) =>
	isRouteProcessor6ChainId(chainId)
		? ROUTE_PROCESSOR_6_ADDRESS[chainId]
		: undefined;
const getTokenAddress = (chainId: EvmChainId) =>
	chainId === EvmChainId.SKALE_EUROPA ? SKL : WNATIVE_ADDRESS[chainId];

const func: DeployFunction = async function ({
	ethers,
	deployments,
	getChainId,
}: HardhatRuntimeEnvironment) {
	const { deploy } = deployments;
	const chainId = +(await getChainId()) as EvmChainId;
	const { deployer } = await ethers.getNamedSigners();

	const operator = getOperatorAddress(chainId);
	const rp = getRPAddress(chainId);
	const weth9 = getTokenAddress(chainId);
	const owner = getOwnerAddress(chainId);

	if (!deployer) throw new Error("Deployer not configured");
	if (!operator) throw new Error("Operator not found on this network");
	if (!rp) throw new Error("RP not found on this network");
	if (!weth9) throw new Error("WETH9 not found on this network");
	if (!owner) throw new Error("Owner not found on this network");

	console.log("Deployer address:", deployer.address);

	console.log("Deploying TokenChomper...");

	const { address } = await deploy("TokenChomper", {
		from: deployer.address,
		args: [operator, rp, weth9],
	});

	console.log("TokenChomper deployed to", address);

	{
		const TokenChomper = await ethers.getContractAt(
			"TokenChomper",
			address,
			deployer,
		);

		console.log("Transferring ownership to", owner);
		const tx = await TokenChomper.transferOwnership(owner);
		await tx.wait();
		console.log("Successfully transferred ownership");
	}
};

func.tags = ["TokenChomper"];

export default func;
