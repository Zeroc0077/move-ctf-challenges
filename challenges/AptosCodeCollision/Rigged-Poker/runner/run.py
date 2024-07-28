import json
from pathlib import Path
import os
import subprocess

import launcher
import requests
import time

def deploy(uuid: str) -> str:
    time.sleep(20)
    #init
    subprocess.run(f"cd rigged_poker; echo ''| aptos init --profile {uuid} --network custom --rest-url 'http://server:9000/{uuid}/node/v1' --assume-yes", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    #fund
    module_address = json.loads(subprocess.run(f"cd rigged_poker; aptos account lookup-address --profile {uuid}", shell=True, capture_output=True).stdout.decode())['Error'].split('Address(')[1].split(")")[0].strip()
    requests.post(f"http://server:9000/{uuid}/gas/fund", json={"address":f"{module_address}","amount":100000000})
    requests.post(f"http://server:9000/{uuid}/gas/fund", json={"address":f"{module_address}","amount":100000000})
    time.sleep(1)
    
    #deploy contract
    published_data = subprocess.run(f"cd rigged_poker; aptos move publish --named-addresses rigged_poker={uuid} --profile {uuid} --assume-yes", shell=True, capture_output=True)

    data = json.loads("\n".join([X for X in published_data.stdout.decode().split("\n")[1:]]))

    module_address = data['Result']['sender']
    
    # final initialize

    requests.post(f"http://server:9000/{uuid}/gas/fund", json={"address":f"{module_address}","amount":100000000})
    time.sleep(1)

    subprocess.run(f"cd rigged_poker; aptos move run --function-id '{uuid}::main::initialize' --profile {uuid} --assume-yes", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    return {"module": module_address}

def checkoooor(data) -> bool:
    uuid = data['uuid']
    deployed_data = data['deployed_data']
    resources = requests.get(f"http://server:9000/{uuid}/node/v1/accounts/{deployed_data['module']}/resources").json()
    win_resource = [X for X in resources if X['type'].endswith("main::Win")][0]

    # Empty out the EUR vault as win condition
    return win_resource['data']['solved']

launcher.run_launcher([
    launcher.new_launch_instance_action(deploy),
    launcher.new_kill_instance_action(),
    launcher.new_get_flag_action(checkoooor)
])
