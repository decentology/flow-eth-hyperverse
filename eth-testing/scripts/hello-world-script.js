//npx hardhat run scripts/hello-world-script.js

const hre = require("hardhat");
async function main() {
    const [TENANT, USER] = await ethers.getSigners();

    /*********************** DEPLOYMENT ***********************/

    // This deploys the "HelloWorld" contract
    const HelloWorld = await hre.ethers.getContractFactory("HelloWorld");
    const hwContract = await HelloWorld.deploy();
    await hwContract.deployed();

    console.log("HelloWorld Contract deployed to:", hwContract.address);

    /*********************** STUFF ***********************/

    // Yeah yeah
    const greeting = hre.ethers.utils.formatBytes32String("Hey there idiot!");

    // Creates a new tribe, passing in the Tenant address (the same as msg.sender above)
    await hwContract.connect(TENANT).changeGreeting(greeting);

    const greetMe = await hwContract.greet(TENANT.address);

    console.log(hre.ethers.utils.parseBytes32String(greetMe));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });