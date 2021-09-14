const MockToken = artifacts.require('MockToken');
const CMStaking = artifacts.require('CMStaking');
const Utils = artifacts.require('Utils');

module.exports = async function (deployer) {
  await deployer.deploy(MockToken, 'Crypto Staking', 'CMS', 10000);
  const token = await MockToken.deployed();

  await deployer.deploy(CMStaking, token.address);
  const staking = await CMStaking.deployed();

  await deployer.deploy(Utils, staking.address);
  const utils = await Utils.deployed();
  await staking.setHelper(utils.address);
};
