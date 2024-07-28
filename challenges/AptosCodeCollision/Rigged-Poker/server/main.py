import os
import random
import socket
import subprocess
import signal
import sys
import json
import time
from dataclasses import dataclass
from threading import Lock, Thread
from typing import Any, Dict, Tuple
from uuid import uuid4
import os
import requests
import uvicorn
from fastapi import FastAPI,  HTTPException, Request, Response
import tempfile
from pathlib import Path

app = FastAPI()

# 9000
HTTP_PORT = os.getenv("HTTP_PORT", "80")

def get_shared_secret():
    return os.getenv("SHARED_SECRET", "t0ps3cret")

def has_instance_by_uuid(uuid: str) -> bool:
    return os.path.exists(f"/tmp/instances-by-uuid/{uuid}")


def has_instance_by_team(team: str) -> bool:
    return os.path.exists(f"/tmp/instances-by-team/{team}")


def get_instance_by_uuid(uuid: str) -> Dict:
    with open(f"/tmp/instances-by-uuid/{uuid}", 'r') as f:
        return json.loads(f.read())


def get_instance_by_team(team: str) -> Dict:
    with open(f"/tmp/instances-by-team/{team}", 'r') as f:
        return json.loads(f.read())


def delete_instance_info(node_info: Dict):
    os.remove(f'/tmp/instances-by-uuid/{node_info["uuid"]}')
    os.remove(f'/tmp/instances-by-team/{node_info["team"]}')


def create_instance_info(node_info: Dict):
    with open(f'/tmp/instances-by-uuid/{node_info["uuid"]}', "w+") as f:
        f.write(json.dumps(node_info))

    with open(f'/tmp/instances-by-team/{node_info["team"]}', "w+") as f:
        f.write(json.dumps(node_info))


def really_kill_node(node_info: Dict):
    print(f"killing node {node_info['team']} {node_info['uuid']}")

    delete_instance_info(node_info)
    subprocess.run(f"docker stop {node_info['uuid']}",shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)



def kill_node(node_info: Dict):
    time.sleep(15 * 60)

    if not has_instance_by_uuid(node_info["uuid"]):
        return

    really_kill_node(node_info)


def launch_node(team_id: str) -> Dict:
    port = random.randrange(30000, 60000)
    uuid = str(uuid4())

    subprocess.run(f"docker run --rm -d --network challenge_shared-bridge --name {uuid} aptoslabs/tools:aptos-node-v1.17.0-rc aptos node run-local-testnet", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    node_info = {
        "port": port,
        "uuid": uuid,
        "team": team_id,
    }

    reaper = Thread(target=kill_node, args=(node_info,))
    reaper.start()
    return node_info


def is_request_authenticated(request):
    token = request.headers.get("Authorization")

    return token == f"Bearer {get_shared_secret()}"


@app.get("/")
async def index():
    return {"server":"run"}


@app.post("/new")
async def create(request: Request):
    if not is_request_authenticated(request):
        return {
            "ok": False,
            "error": "nice try",
        }

    body = await request.json()

    team_id = body["team_id"]

    if has_instance_by_team(team_id):
        print(f"refusing to run a new chain for team {team_id}")
        return {
            "ok": False,
            "error": "already_running",
            "message": "An instance is already running!",
        }

    print(f"launching node for team {team_id}")
    
    node_info = launch_node(team_id)
    if node_info is None:
        print(f"failed to launch node for team {team_id}")
        return {
            "ok": False,
            "error": "error_starting_chain",
            "message": "An error occurred while starting the chain",
        }
    create_instance_info(node_info)

    print(f"launched node for team {team_id} (uuid={node_info['uuid']})")

    return {
        "ok": True,
        "uuid": node_info['uuid'],
    }


@app.post("/kill")
async def kill(request: Request):
    if not is_request_authenticated(request):
        return {
            "ok": False,
            "error": "nice try",
        }

    body = await request.json()

    team_id = body["team_id"]

    if not has_instance_by_team(team_id):
        print(f"no instance to kill for team {team_id}")
        return {
            "ok": False,
            "error": "not_running",
            "message": "No instance is running!",
        }

    really_kill_node(get_instance_by_team(team_id))

    return {
        "ok": True,
        "message": "Instance killed",
    }

HEADERS_PRESERVE = ["Authorization", "Content-Type", "Accept"]

def preserve_headers(headers):
    new_headers = {}
    for header in HEADERS_PRESERVE:
        if header in headers:
            new_headers[header] = headers[header]
    return new_headers

@app.post("/{uuid}/gas/{full_path:path}")
async def proxy2(uuid: str, full_path: str, request: Request):
    # not JSONRPC anymore
    if not has_instance_by_uuid(uuid):
        return None

    body = await request.body()
    headers = preserve_headers(request.headers)
    
    node_info = get_instance_by_uuid(uuid)
    resp = requests.post(f"http://{uuid}:8081/{full_path}", headers=headers, data=body)
    # Ensure to convert the headers from CaseInsensitiveDict (requests library) to a standard dict
    headers = {k: v for k, v in resp.headers.items()}
    return Response(content=resp.content, status_code=resp.status_code, headers=headers)


@app.post("/{uuid}/node/{full_path:path}")
async def proxy(uuid: str, full_path: str, request: Request):
    # not JSONRPC anymore
    if not has_instance_by_uuid(uuid):
        return None

    body = await request.body()
    headers = preserve_headers(request.headers)
    
    node_info = get_instance_by_uuid(uuid)
    resp = requests.post(f"http://{uuid}:8080/{full_path}", headers=headers, data=body)
    # Ensure to convert the headers from CaseInsensitiveDict (requests library) to a standard dict
    headers = {k: v for k, v in resp.headers.items()}
    return Response(content=resp.content, status_code=resp.status_code, headers=headers)

@app.get("/{uuid}/node/{full_path:path}")
async def proxy3(uuid: str, full_path: str, request: Request):
    # not JSONRPC anymore
    if not has_instance_by_uuid(uuid):
        return None

    print(request.query_params)

    body = await request.body()
    headers = preserve_headers(request.headers)
    
    node_info = get_instance_by_uuid(uuid)
    resp = requests.get(f"http://{uuid}:8080/{full_path}", headers=headers, data=body, params=request.query_params)
    # Ensure to convert the headers from CaseInsensitiveDict (requests library) to a standard dict
    headers = {k: v for k, v in resp.headers.items()}
    return Response(content=resp.content, status_code=resp.status_code, headers=headers)



if __name__ == "__main__":
    uvicorn.run("main:app", port=9000)
