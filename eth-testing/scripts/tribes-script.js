//npx hardhat run scripts/tribes-script.js

const hre = require("hardhat");
async function main() {
    const [TENANT, USER] = await ethers.getSigners();

    /*********************** DEPLOYMENT ***********************/

    // This deploys the "TribesState" contract
    const Tribes = await hre.ethers.getContractFactory("Tribes");
    const tribesContract = await Tribes.deploy();
    await tribesContract.deployed();

    console.log("Tribes Contract deployed to:", tribesContract.address);

    /*********************** STUFF ***********************/

    // Yeah yeah
    const name = hre.ethers.utils.formatBytes32String("Merkle");
    const ipfsHash = hre.ethers.utils.formatBytes32String("https://ipfs.io/...");
    const description = hre.ethers.utils.formatBytes32String("a group that loves apples");

    // Creates a new tribe, passing in the Tenant address (the same as msg.sender above)
    await tribesContract.connect(TENANT).addNewTribe(
        name, ipfsHash, description
    );

    const getTribeData = await tribesContract.getTribeData(
        TENANT.address,
        1
    );
    // Gets the tribe data back and converts it from bytes -> string
    console.log(
        hre.ethers.utils.parseBytes32String(getTribeData[0]), "is",
        hre.ethers.utils.parseBytes32String(getTribeData[2]), "and you can view their image here:",
        hre.ethers.utils.parseBytes32String(getTribeData[1])
    );

    await tribesContract.connect(USER).joinTribe(
        TENANT.address,
        1
    );

    console.log("USER joined a tribe.");

    const getUserTribe = await tribesContract.getUserTribe(
        TENANT.address,
        USER.address
    );

    console.log("USER's Tribe:", getUserTribe._hex);

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });