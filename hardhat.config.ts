import "dotenv/config";

import "@nomicfoundation/hardhat-ethers";
import "hardhat-deploy";
import "hardhat-deploy-ethers";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";
import "@matterlabs/hardhat-zksync-deploy";
import "@matterlabs/hardhat-zksync-solc";

import type { HardhatUserConfig } from "hardhat/config";
import {
	mainnet,
	apeChain,
	arbitrum,
	arbitrumNova,
	avalanche,
	base,
	blast,
	boba,
	bsc,
	bitTorrent,
	celo,
	coreDao,
	cronos,
	fantom,
	filecoin,
	fuse,
	gnosis,
	haqqMainnet,
	harmonyOne,
	kava,
	linea,
	manta,
	mantle,
	metis,
	mode,
	moonbeam,
	moonriver,
	optimism,
	polygon,
	polygonZkEvm,
	rootstock,
	scroll,
	sepolia,
	skaleEuropa,
	sonic,
	taiko,
	telos,
	thunderCore,
	zetachain,
	zkLinkNova,
	zksync,
	type Chain,
} from "viem/chains";
import { EvmChainId } from "sushi/chain";

const setBlockExplorerApiUrl = (chain: Chain, apiUrl: string) => {
	return {
		...chain,
		blockExplorers: {
			...chain.blockExplorers,
			default: {
				...chain.blockExplorers?.default,
				apiUrl,
			},
		},
	};
};

const accounts = process.env.PRIVATE_KEY
	? [process.env.PRIVATE_KEY]
	: {
			mnemonic:
				process.env.MNEMONIC ||
				"test test test test test test test test test test test junk",
			accountsBalance: "990000000000000000000",
		};

const bobaBNB = {
	id: 56288,
	rpcUrls: {
		default: { http: ["https://bnb.boba.network"] },
	},
	blockExplorers: {
		default: {
			apiUrl: "https://api.routescan.io/v2/network/mainnet/evm/56288/etherscan",
			url: "https://bobascan.com",
		},
	},
};

const hemi = {
	id: 43111,
	rpcUrls: {
		default: { http: ["https://rpc.hemi.network/rpc"] },
	},
	blockExplorers: {
		default: {
			apiUrl: "https://explorer.hemi.xyz/api",
			url: "https://explorer.hemi.xyz",
		},
	},
};

const chains = {
	ape: apeChain,
	arbitrum,
	"arbitrum-nova": arbitrumNova,
	avalanche,
	base,
	blast,
	boba: setBlockExplorerApiUrl(
		boba,
		"https://api.routescan.io/v2/network/mainnet/evm/288/etherscan",
	),
	"boba-bnb": bobaBNB,
	bsc,
	bttc: bitTorrent,
	celo,
	core: coreDao,
	cronos,
	ethereum: mainnet,
	fantom,
	filecoin,
	fuse,
	gnosis,
	haqq: haqqMainnet,
	harmony: harmonyOne,
	hemi,
	kava,
	linea,
	manta,
	mantle,
	metis,
	mode,
	moonbeam,
	moonriver,
	optimism,
	polygon,
	"polygon-zkevm": polygonZkEvm,
	rootstock,
	scroll,
	sepolia,
	"skale-europa": skaleEuropa,
	sonic,
	taiko,
	telos,
	thundercore: thunderCore,
	zetachain,
	"zklink-nova": zkLinkNova,
	zksync,
};

const zksyncChains: number[] = [EvmChainId.ZKSYNC_ERA, EvmChainId.ZKLINK];

const networks = Object.fromEntries(
	Object.entries(chains).map(([key, value]) => [
		key,
		{
			url: value.rpcUrls.default.http[0],
			chainId: value.id,
			accounts,
			zksync: zksyncChains.includes(value.id),
		},
	]),
);

const etherscan = {
	customChains: Object.entries(chains).reduce((accum, [key, value]) => {
		if (
			value.blockExplorers.default.url &&
			// biome-ignore lint/suspicious/noExplicitAny: <explanation>
			(value.blockExplorers.default as any).apiUrl
		) {
			accum.push({
				network: key,
				chainId: value.id,
				urls: {
					// biome-ignore lint/suspicious/noExplicitAny: fk types
					apiURL: (value.blockExplorers.default as any).apiUrl,
					browserURL: value.blockExplorers.default.url,
				},
			});
		}
		return accum;
	}, [] as {
		network: string,
		chainId: number,
		urls: {
			apiURL: string,
			browserURL: string
		}
	}[]),
	apiKey: Object.fromEntries(
		Object.entries(chains).map(([key, value]) => [
			key,
			process.env[`EXPLORER_${value.id}_KEY`] || "xxx",
		]),
	),
};

const config: HardhatUserConfig = {
	defaultNetwork: "ethereum",
	networks,
	etherscan,
	solidity: {
		version: "0.8.20",
		settings: {
			optimizer: {
				enabled: true,
				runs: 1000000,
			},
		},
	},
	namedAccounts: {
		// e.g. ledger://0x18dd4e0Eb8699eA4fee238dE41ecF115e32272F8
		deployer: process.env.LEDGER || { default: 0 },
		funder: { default: 1 },
		alice: {
			default: 1,
		},
		bob: {
			default: 2,
		},
		carol: {
			default: 3,
		},
		dev: {
			default: 4,
		},
		feeTo: {
			default: 5,
		},
	},
};

export default config;
