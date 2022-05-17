import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { CryptoPlaze, CryptoPlaze__factory } from "../typechain";

describe("CryptoPlaze", function () {
  let Token: CryptoPlaze__factory;
  let owner: SignerWithAddress;
  let token: CryptoPlaze;
  let addr1: SignerWithAddress;
  this.beforeEach(async () => {
    Token = await ethers.getContractFactory("CryptoPlaze");
    [owner, addr1] = await ethers.getSigners();
    token = await Token.deploy();
  });

  describe("Deployment", () => {
    it("Should set the right owner", async () => {
      expect(await token.owner()).to.equal(owner.address);
    });
  });
  describe("Minting", () => {
    it("Should fail if hex code is invalid", async () => {
      const tokenId = 2541;
      const failed_minting = token.connect(addr1).create("4333", 2541);
      expect(failed_minting).to.be.revertedWith("Hex must be 3 or 6 chr long!");
    });
    it("Should fail if token id exceeds the maximum", async () => {
      const tokenId = 1000001;
      const failed_minting = token.connect(addr1).create("333", tokenId);
      expect(failed_minting).to.be.revertedWith("TokenId must be 1 - 1 mil");
    });
    it("Should fail if token id is less than the minimum", async () => {
      const tokenId = 0;
      const failed_minting = token.connect(addr1).create("333", tokenId);
      expect(failed_minting).to.be.revertedWith("TokenId must be 1 - 1 mil");
    });
    it("Should fail if the balance is insufficient", async () => {
      const tokenId = 454;
      const failed_minting = token.connect(addr1).create("333", tokenId);
      expect(failed_minting).to.be.revertedWith("Insufficient payment");
    });
    it("Should successfully mint a token", async () => {
      const tokenId = 454;
      const overrides = {
        value: ethers.utils.parseEther("1.0"),
      };
      await token.connect(addr1).create("333", tokenId, overrides);
      // console.log(t);
      expect(await token.ownerOf(tokenId)).to.be.equal(addr1.address);
    });
    it("Should fail to mint two tokens with the same id", async () => {
      const tokenId = 454;
      const overrides = {
        value: ethers.utils.parseEther("1.0"),
      };

      const successful_mint = token
        .connect(addr1)
        .create("333", tokenId, overrides);
      const failed_mint = token
        .connect(addr1)
        .create("333", tokenId, overrides);
      // console.log(t);
      expect(failed_mint).to.be.revertedWith("That piece was already minted");
      expect(await token.ownerOf(tokenId)).to.be.equal(addr1.address);
    });
    it("Should successfully mint a token", async () => {
      const tokenId = 454;
      const overrides = {
        value: ethers.utils.parseEther("1.0"),
      };
      await token.connect(addr1).create("333", tokenId, overrides);
      // console.log(t);
      expect(await token.ownerOf(tokenId)).to.be.equal(addr1.address);
      console.log(ethers.utils.formatEther(await addr1.getBalance()));
    });
    it("Should successfully return unused funds", async () => {
      const tokenId = 454;
      const past_balance = ethers.utils.formatEther(await addr1.getBalance());
      const overrides = {
        value: ethers.utils.parseEther("2.0"),
      };
      await token.connect(addr1).create("333", tokenId, overrides);
      // console.log(t);
      expect(await token.ownerOf(tokenId)).to.be.equal(addr1.address);
      const new_balance = ethers.utils.formatEther(await addr1.getBalance());
      const balance_difference =
        parseFloat(past_balance) - parseFloat(new_balance);
      expect(balance_difference)
        .to.greaterThanOrEqual(1)
        .and.to.lessThanOrEqual(1.1);
      // console.log(ethers.utils.formatEther(await addr1.getBalance()));
    });
    it("Gets the token price", async () => {});
  });
});
