const { ethers, getNamedAccounts } = require("hardhat")

// let usdcAddress = "0x9dE18Ae6087a568410751c8caD8cf4fc2E399290"//abitrum
let usdcAddress = "0x07865c6E87B9F70255377e024ace6630C1Eaa37F" //goerli

// let minABI = [
//     // balanceOf
//     {
//         constant: true,
//         inputs: [{ name: "_owner", type: "address" }],
//         name: "balanceOf",
//         outputs: [{ name: "balance", type: "uint256" }],
//         type: "function",
//     },
//     {
//         constant: false,
//         inputs: [
//             { name: "usr", type: "address" },
//             { name: "wad", type: "uint256" },
//         ],
//         name: "approve",
//         outputs: [{ name: "", type: "bool" }],
//         payable: false,
//         stateMutability: "nonpayable",
//         type: "function",
//     },
// ]
// const usdcToken = new ethers.Contract( usdcAddress,minABI)

// usdcToken.approve(lpstake.address, amount)

async function main() {
    const { deployer } = await getNamedAccounts()
    const lpstake = await ethers.getContract("lpstake", deployer)
    console.log(`Got contract lpstake at ${lpstake.address}`)
    console.log("lpstake contract...")
    const transactionResponse = await lpstake.depositTokens(1000000)
    console.log("transactionResponse:", transactionResponse)
    await transactionResponse.wait()
    console.log("lpstake!")
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
