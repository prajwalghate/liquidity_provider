const { expect } = require("chai")
const { ethers } = require("hardhat")

const DAI = "0x6B175474E89094C44Da98b954EedeAC495271d0F"
const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
const DAI_WHALE = "0x2FAF487A4414Fe77e2327F0bf4AE2a264a776AD2"
const USDC_WHALE = "0x2FAF487A4414Fe77e2327F0bf4AE2a264a776AD2"

describe("LiquidityExamples", () => {
    let liquidityExamples
    let accounts
    let dai
    let usdc

    before(async () => {
        accounts = await ethers.getSigners(1)

        const lpstakeExamples = await ethers.getContractFactory("lpstake")
        lpstake = await lpstakeExamples.deploy(
            "0xE592427A0AEce92De3Edee1F18E0157C05861564",
            "0xC36442b4a4522E871399CD717aBDD847Ab11FE88"
        )
        await lpstake.deployed()

        usdc = await ethers.getContractAt("IERC20", USDC)
        dai = await ethers.getContractAt("IERC20", DAI)

        // Unlock DAI and USDC whales
        await network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [USDC_WHALE],
        })

        const usdcWhale = await ethers.getSigner(USDC_WHALE)

        // Send DAI and USDC to accounts[0]
        const usdcAmount = 1000n * 10n ** 6n

        expect(await usdc.balanceOf(usdcWhale.address)).to.gte(usdcAmount)

        await usdc.connect(usdcWhale).transfer(accounts[0].address, usdcAmount)
    })

    it("mintNewPosition", async () => {
        const usdcAmount = 100n * 10n ** 6n
        await usdc.connect(accounts[0]).approve(lpstake.address, usdcAmount)
        let k = await lpstake.depositTokens(usdcAmount)
        console.log(
            "USDC balance after add liquidity",
            await usdc.balanceOf(accounts[0].address)
        )
    })

    it("collectAllFees", async () => {
        await lpstake.collectAllFees()

        console.log("--- collect fees ---")
        console.log(`dai ${await dai.balanceOf(lpstake.address)}`)
        console.log(`usdc ${await usdc.balanceOf(lpstake.address)}`)
    })
})
