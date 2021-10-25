const myNft = artifacts.require("myNft");

module.exports = function (deployer) {
  deployer.deploy(myNft);
};
