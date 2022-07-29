import { expect } from "chai";
import { ethers } from "hardhat";
import { NftMint } from "../typechain/NftMint";
import { NftMint__factory } from "../typechain/factories/NftMint__factory";

const tokenName = "TName";
const tokenSymbol = "TN";
const baseUri = "http://localhost/nfts/";

// describe("Greeter", function () {
//   it("Should return the new greeting once it's changed", async function () {
//     const Greeter = await ethers.getContractFactory("Greeter");
//     const greeter = await Greeter.deploy("Hello, world!");
//     await greeter.deployed();

//     expect(await greeter.greet()).to.equal("Hello, world!");

//     const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

//     // wait until the transaction is mined
//     await setGreetingTx.wait();

//     expect(await greeter.greet()).to.equal("Hola, mundo!");
//   });
// });

describe("NftMint", async function () {
  let NftMint: NftMint__factory;
  let nftMint: NftMint;
  //@ts-ignore
  let owner, user1, user2;
  this.beforeAll(async function () {
    [owner, user1, user2] = await ethers.getSigners();
    console.log(owner.address)
    console.log(user1.address)
    console.log(user2.address)
  });
  beforeEach(async function () {
    NftMint = (await ethers.getContractFactory("NftMint")) as NftMint__factory;
    nftMint = await NftMint.deploy(tokenName, tokenSymbol, baseUri);
    await nftMint.deployed();
  });
  it("After Deployment, confirm the initical values of contract", async function () {
    expect(await nftMint.totalSupply()).to.equal(65535);
    expect(await nftMint.currentSupply()).to.equal(0);
  });
  it("After Minting, confirm the status of contract", async function () {
    const mintTx1 = await nftMint.publicMint(1, {
      //@ts-ignore
      from: owner.address
    });
    await mintTx1.wait();

    expect(await nftMint.currentSupply()).to.equal(1);
    const mintTx2 = await nftMint.publicMint(1, {
      //@ts-ignore
      from: owner.address
    });
    await mintTx2.wait();

    expect(await nftMint.currentSupply()).to.equal(2);

    expect(await nftMint.tokenURI(1)).to.equal(`${baseUri}1.json`);
    expect(await nftMint.tokenURI(2)).to.equal(`${baseUri}2.json`);
    // expect(await nftMint.tokenURI(3)).to.equal(`${baseUri}3.json`);
  })
});
