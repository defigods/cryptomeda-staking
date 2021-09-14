const { expect } = require('chai');
const {
  BN,
  expectEvent,
  time,
  expectRevert,
} = require('@openzeppelin/test-helpers');

const MockToken = artifacts.require('MockToken');
const CMStaking = artifacts.require('CMStaking');
const Utils = artifacts.require('Utils');

let token,
  staking,
  utils,
  startTime,
  amount = 1000;
const lockupDuration = 86400 * 4;

contract(CMStaking, ([_, alice, bob, carol, dan, erin]) => {
  describe('stake', async () => {
    before(async () => {
      token = await MockToken.new('Cryptomeda', 'CMS', 1e4);
      staking = await CMStaking.new(token.address);
      utils = await Utils.new(staking.address);
      await staking.setHelper(utils.address);

      await token.approve(utils.address, 1e5);
      await token.approve(staking.address, 1e5, { from: alice });
      await token.approve(staking.address, 1e5, { from: bob });
      await token.approve(staking.address, 1e5, { from: carol });
      await token.approve(staking.address, 1e5, { from: dan });
      await token.approve(staking.address, 1e5, { from: erin });

      await token.mint(alice, 1000);
      await token.mint(bob, 500);
      await token.mint(carol, 500);
      await token.mint(dan, 500);
      await token.mint(erin, 500);
    });

    it('start', async () => {
      startTime = (await time.latest()).toNumber() + 100;
      await utils.startSeason(500, startTime, startTime + 86400 * 10);
      expect((await utils.reward()).toNumber()).to.eq(500);

      await time.increaseTo(startTime);
      await staking.stake(amount, lockupDuration, { from: alice });

      amount = 500;
      await time.increase(86400);
      await staking.stake(amount, lockupDuration, { from: bob });

      await time.increase(86400 * 2);
      await staking.stake(amount, lockupDuration, { from: carol });

      await time.increase(86400 * 3);
      await staking.stake(amount, lockupDuration, { from: dan });

      await time.increase(86400 * 4 - 10);
      await staking.stake(amount, lockupDuration, { from: erin });

      console.log('>>>>>>> share <<<<<<<');
      const names = ['alice', 'bob', 'carol', 'dan', 'erin'];
      const totalShare = (await staking.totalShare()).toNumber();
      const balance = (await token.balanceOf(staking.address)).toNumber();
      for (let i = 0; i < 5; i++) {
        const share = (await staking.stakes(i)).share.toNumber();
        console.log(
          names[i],
          '\t',
          share,
          '\t',
          Math.floor((balance * share) / totalShare),
        );
      }
      console.log('----------------------');
      console.log('total\t', totalShare, '\t', balance);
    });

    it('check withdrawable amounts', async () => {
      let share = (await staking.stakes(0)).share.toNumber();
      const totalShare = (await staking.totalShare()).toNumber();
      const balance = (await token.balanceOf(staking.address)).toNumber();
      expect(
        (await staking.withdraw.call(0, share, { from: alice })).toNumber(),
      ).to.eq(Math.floor((share * balance) / totalShare));

      share = (await staking.stakes(1)).share.toNumber();
      expect(
        (await staking.withdraw.call(1, share, { from: bob })).toNumber(),
      ).to.eq(Math.floor((share * balance) / totalShare));

      share = (await staking.stakes(2)).share.toNumber();
      expect(
        (await staking.withdraw.call(2, share, { from: carol })).toNumber(),
      ).to.eq(Math.floor((share * balance) / totalShare));

      share = (await staking.stakes(3)).share.toNumber();
      expectRevert(
        staking.withdraw.call(3, share, { from: dan }),
        'Lockup duration not passed yet',
      );
    });
  });
});
