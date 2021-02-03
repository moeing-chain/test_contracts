const spaceLogic = artifacts.require("SpaceLogic");
const space = artifacts.require("Space");
const registryLogic = artifacts.require("RegistryLogic");
const chirp = artifacts.require("Chirp");
const { ethers } = require("ethers");


async function deployContracts() {
    spaceLogicC = await spaceLogic.new();
    console.log("spaceLogic", spaceLogicC.address);
    registryLogicC = await registryLogic.new();
    console.log("registryLogic", registryLogicC.address);
    chirpContract = await chirp.new(registryLogicC.address, spaceLogicC.address, spaceLogicC.address);
    chirpC = await registryLogic.at(chirpContract.address);
    console.log("chirp", chirpC.address);
}

contract('Chirp', async accounts => {
    console.log("hehe");
    before(deployContracts);

    it('Register new account', async () => {
        let accountName = ethers.utils.formatBytes32String('Bear');
        await chirpC.register(accountName, accounts[1], accounts[2]);
        let owner = await chirpC.getOwnerByAccountName.call(accountName);
        assert.equal(owner, accounts[0]);
        let spaceAddress = await chirpC.getSpaceByAccountName.call(accountName);
        console.log("space", spaceAddress);
        let spaceC = await spaceLogic.at(spaceAddress);
        let id = await spaceC.getNextThreadId.call();
        console.log("id", id.toNumber());
    });
});