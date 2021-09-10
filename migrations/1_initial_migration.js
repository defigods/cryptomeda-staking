const CMStaking = artifacts.require('CMStaking');

module.exports = function (deployer) {
  deployer.deploy(CMStaking);
};
