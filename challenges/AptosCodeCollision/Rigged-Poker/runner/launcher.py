import json
import os
import random
import string
import time
import hashlib
from dataclasses import dataclass
from typing import Callable, Dict, List, Optional
from uuid import UUID
import os

import requests

HTTP_PORT = os.getenv("HTTP_PORT", "9000")

PUBLIC_IP = os.getenv("PUBLIC_IP", "127.0.0.1")

CHALLENGE_ID = os.getenv("CHALLENGE_ID", "challenge")
FLAG = os.getenv("FLAG", "AptosCTF{PLACEHOLDER}")

@dataclass
class Ticket:
    challenge_id: string
    team_id: string

def get_shared_secret():
    return os.getenv("SHARED_SECRET", "t0ps3cret")

def check_ticket(ticket: str) -> Ticket:
    if len(ticket) > 100 or len(ticket) < 8:
        print('invalid ticket length')
        return None
    if not all(c in 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789' for c in ticket):
        print('ticket must be alphanumeric')
        return None
    m = hashlib.sha256()
    m.update(ticket.encode('ascii'))
    digest1 = m.digest()
    m = hashlib.sha256()
    m.update(digest1 + ticket.encode('ascii'))
    if not m.hexdigest().startswith('000000'):
        print('PoW: sha256(sha256(ticket) + ticket) must start with 000000')
        print('(digest was ' + m.hexdigest() + ')')
        return None
    print('This ticket is your TEAM SECRET. Do NOT SHARE IT!')
    return Ticket(challenge_id=CHALLENGE_ID, team_id=ticket)

@dataclass
class Action:
    name: str
    handler: Callable[[], int]


def new_launch_instance_action(
    do_deploy,
):
    def action() -> int:
        ticket = check_ticket(input("ticket please: (it should be a SECURE SECRET) "))
        if not ticket:
            print("invalid ticket!")
            return 1

        if ticket.challenge_id != CHALLENGE_ID:
            print("invalid ticket!")
            return 1

        data = requests.post(
            f"http://server:{HTTP_PORT}/new",
            headers={
                "Authorization": f"Bearer {get_shared_secret()}",
                "Content-Type": "application/json",
            },
            data=json.dumps(
                {
                    "team_id": ticket.team_id,
                }
            ),
        ).json()

        if data["ok"] == False:
            print(data["message"])
            return 1

        uuid = data["uuid"]

        deployed_data = do_deploy(uuid)

        with open(f"/tmp/{ticket.team_id}", "w") as f:
            f.write(
                json.dumps(
                    {
                        "uuid": uuid,
                        "deployed_data":deployed_data
                    }
                )
            )

        print()
        print(f"your private aptos validator has been deployed")
        print(f"it will automatically terminate in 15 minutes")
        print(f"here's some useful information")
        print(f"uuid:           {uuid}")
        print(f"RPC Endpoint:   http://{PUBLIC_IP}:{HTTP_PORT}/{uuid}/node/v1")
        print(f"Gas Faucet:   http://{PUBLIC_IP}:{HTTP_PORT}/{uuid}/gas/")
        print(f"Deployed: {deployed_data['module']}")
        return 0

    return Action(name="launch new instance", handler=action)


def new_kill_instance_action():
    def action() -> int:
        ticket = check_ticket(input("ticket please: (choose a SECURE SECRET) "))
        if not ticket:
            print("invalid ticket!")
            return 1

        if ticket.challenge_id != CHALLENGE_ID:
            print("invalid ticket!")
            return 1

        data = requests.post(
            f"http://server:{HTTP_PORT}/kill",
            headers={
                "Authorization": f"Bearer {get_shared_secret()}",
                "Content-Type": "application/json",
            },
            data=json.dumps(
                {
                    "team_id": ticket.team_id,
                }
            ),
        ).json()

        print(data["message"])
        return 1

    return Action(name="kill instance", handler=action)


def new_get_flag_action(
    checker
):
    def action() -> int:
        ticket = check_ticket(input("ticket please: (choose a SECURE SECRET) "))
        if not ticket:
            print("invalid ticket!")
            return 1

        if ticket.challenge_id != CHALLENGE_ID:
            print("invalid ticket!")
            return 1

        try:
            with open(f"/tmp/{ticket.team_id}", "r") as f:
                data = json.loads(f.read())
        except:
            print("bad ticket")
            return 1

        if not checker(data):
            print("are you sure you solved it?")
            return 1

        print(FLAG)
        print('')
        print('for your safety, you should delete your instance now that you are done')
        return 0

    return Action(name="get flag", handler=action)


def run_launcher(actions: List[Action]):
    for i, action in enumerate(actions):
        print(f"{i+1} - {action.name}")

    action = int(input("action? ")) - 1
    if action < 0 or action >= len(actions):
        print("can you not")
        exit(1)

    exit(actions[action].handler())
