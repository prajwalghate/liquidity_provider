const { ethers, getNamedAccounts } = require("hardhat")

async function main() {
    const { deployer } = await getNamedAccounts()
    const lpstake = await ethers.getContract("lpstake", deployer)
    console.log(`Got contract lpstake at ${lpstake.address}`)
    console.log("lpstake contract...")
    const transactionResponse = await lpstake.stakingBalance(deployer)
    console.log("transactionResponse:", transactionResponse)
    // await transactionResponse.wait()
    // console.log("lpstake!")
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
