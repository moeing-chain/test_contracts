const chirp = artifacts.require("Chirp");
const registryLogic = artifacts.require("RegistryLogic");
const spaceLogic = artifacts.require("SpaceLogic");
const space = artifacts.require("Space");

module.exports = async function(deployer, network, accounts) {
    await deployer.deploy(spaceLogic);
    console.log("spaceLogic", spaceLogic.address);
    await deployer.deploy(registryLogic);
    console.log("registryLogic", registryLogic.address);
    await deployer.deploy(chirp, registryLogic.address, spaceLogic.address, accounts[0]);
    console.log("chirp", chirp.address);
};