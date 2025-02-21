import { ethers } from "hardhat";

export const ETHER_ADDR = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";

export const SECONDS_IN_DAY = 86400;
export const SECONDS_IN_MONTH = SECONDS_IN_DAY * 30;

export const DECIMAL = 10n ** 18n;
export const PRECISION = 10n ** 25n;
export const PERCENTAGE_100 = PRECISION * 100n;

export const MAX_UINT256 = ethers.MaxUint256;
