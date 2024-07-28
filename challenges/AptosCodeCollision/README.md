# Aptos Code Collision CTF Writeup by zeroc

I participated in the [Aptos Code Collision CTF](https://ctf.aptosfoundation.org/) and learned a lot as a beginner in aptos. Below are the detailed writeups for this game.

## Basic

Figuring out the whole challenge framework of this game may help you solve the challenges more easily.

There will be a server listening on a specific port and you can interact with it by establishing tcp connection. In general, your final goal is to make the `is_solved` function in the challenge contract return `true`, then the server will give you the flag.

The general interaction process is as follows:
* The server listens on a specific port and waits for the client to connect.
* once the client connects, the server will prepare a local environment to emulate the execution of the challenge contract.
* The client needs to send the bytecode of solution contract to the server. The server will publish all the contracts and may call the `initialize` function of the challenge contract to initialize the environment.
* The server waits for a series of instructions in the form of `address::module::function` from the client. The server will call the corresponding function of the corresponding module in the corresponding address. When the `solve` function of the solution contract is called, the server will return the result to the client.

## Welcome

It's a checkin challenge, you can learn some basic syntax and concepts of aptos move.

As you can see, you only need to call the `checkin` function of the challenge contract to solve this challenge.

![](./images/1.png)

## Flash Loan

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