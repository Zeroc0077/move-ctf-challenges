# Rigged Poker

## How to run locally

Install docker and docker-compose. Then you can just do `docker-compose up` and it should run out of the box.

You can connect to 7070 locally to emulate the full remote environment

## How it works

You can use `gen_ticket.py` to generate a ticket for you. Then connect to remote on 7070 using netcat, enter 1 to deploy a private RPC that you can use however you want to reach the win condition

The win condition is part of the `run.py` in runner. In short, you have to win poker 32 times in a row