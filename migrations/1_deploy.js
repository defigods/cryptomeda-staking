const CMStaking = artifacts.require('CMStaking');
const Utils = artifacts.require('Utils');

module.exports = async function (deployer) {
  const token = '';
  await deployer.deploy(CMStaking, token);
  const staking = await CMStaking.deployed();

  await deployer.deploy(Utils);
  const utils = await Utils.deployed();
  await utils.setVault(staking.address);
};
