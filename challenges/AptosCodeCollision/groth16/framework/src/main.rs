use std::env;
use std::error::Error;
use std::fmt;
use std::io::{Read, Write};
use std::mem::drop;
use std::net::{TcpListener, TcpStream};
use std::str::FromStr;

use tokio;

use aptos_crypto::ed25519::Ed25519PrivateKey;
use aptos_transactional_test_harness::AptosTestAdapter;
use move_binary_format::file_format::CompiledModule;
use move_compiler::shared::NumericalAddress;
use move_core_types::{
    account_address::AccountAddress,
    ident_str,
    identifier::Identifier,
    language_storage::{ModuleId, TypeTag},
    value::MoveValue,
};

async fn handle_client(mut stream: TcpStream) -> Result<(), Box<dyn Error>> {
    let modules = vec!["flag", "groth16", "router"];

    // Initialize Named Addresses
    let named_addresses = vec![
        (
            "challenger",
            "0xf75daa73fc071f93593335eb9033da804777eb94491650dd3f095ce6f778acb6",
        ),
        (
            "solver",
            "0x9c3b634ac05d0af393e0f93b9b19b61e7cac1c519f566276aa0c6fd15dac12aa",
        ),
        ("challenge", "0x1337"),
        ("solution", "0x1338"),
    ]
    .into_iter()
    .map(|(name, addr)| (name.to_string(), NumericalAddress::parse_str(addr).unwrap()))
    .collect::<Vec<_>>();

    // Create Accounts
    let challenger_key = create_ed25519_key(&[
        0x56, 0xa2, 0x61, 0x40, 0xeb, 0x23, 0x37, 0x50, 0xcd, 0x14, 0xfb, 0x16, 0x8c, 0x3e, 0xb4,
        0xbd, 0x07, 0x82, 0xb0, 0x99, 0xcd, 0xe6, 0x26, 0xec, 0x8a, 0xff, 0x7f, 0x3c, 0xce, 0xb6,
        0x36, 0x4f,
    ])?;
    let solver_key = create_ed25519_key(&[
        0x95, 0x2a, 0xaf, 0x3a, 0x98, 0xa2, 0x79, 0x03, 0xdd, 0x07, 0x8d, 0x76, 0xfc, 0x9e, 0x41,
        0x17, 0x40, 0xd2, 0xae, 0x9d, 0xd9, 0xec, 0xb8, 0x7b, 0x96, 0xc7, 0xcd, 0x6b, 0x79, 0x1f,
        0xfc, 0x69,
    ])?;
    let account_priv_keys = vec![("challenger", challenger_key), ("solver", solver_key)]
        .into_iter()
        .map(|(name, key)| (Identifier::new(name.to_string()).unwrap(), key))
        .collect::<Vec<_>>();

    // Initialize CTF Framework (Adapter)
    let mut adapter = apt_ctf_framework::initialize(named_addresses, account_priv_keys);

    // Publish Challenge Module

    let chall_addr = publish_modules(&mut adapter, modules, "challenger", "challenge")?;
    // Read Solution Module
    let solution_data = read_solution_module(&mut stream)?;

    // Send Challenge Address
    send_message(
        &mut stream,
        format!("[SERVER] Challenge modules published at: {}", chall_addr),
    )?;

    // Publish Solution Module
    let sol_addr = publish_solution_module(&mut adapter, solution_data, "solver", "solve")?;

    // Send Solution Address
    send_message(
        &mut stream,
        format!("[SERVER] Solution published at {}", sol_addr),
    )?;

    // Call initialize Function
    let ret_val = call_function(
        &mut adapter,
        chall_addr,
        "router",
        "initialize",
        "challenger",
    )?;

    // Call solve Function
    loop {
        send_message(
            &mut stream,
            "[SERVER] function to invoke: ".to_owned(),
        )?;
        stream.flush();
        let function_to_invoke = read_function_to_invoke(&mut stream)?;
        if let Some((address, module, function)) = parse_function_to_invoke(&function_to_invoke) {
            let ret_val = call_function(&mut adapter, address, module, function, "solver")?;

            if module == "exploit" && function == "solve" {
                break;
            }
        }
    }

    // Check Solution
    let sol_ret = call_function(&mut adapter, chall_addr, "router", "is_solved", "challenger");
    validate_solution(sol_ret, &mut stream)?;

    Ok(())
}

fn create_ed25519_key(bytes: &[u8]) -> Result<Ed25519PrivateKey, Box<dyn Error>> {
    Ed25519PrivateKey::from_bytes_unchecked(bytes).map_err(|e| e.into())
}

fn publish_modules(
    adapter: &mut AptosTestAdapter,
    module_names: Vec<&str>,
    publisher: &str,
    challenge: &str,
) -> Result<AccountAddress, Box<dyn Error>> {
    let mut addr = AccountAddress::random();
    for module_name in module_names {
        let mod_path = format!(
            "./challenge/build/challenge/bytecode_modules/{}.mv",
            module_name
        );
        let mod_bytes = std::fs::read(mod_path)?;
        let module = CompiledModule::deserialize(&mod_bytes)?;
        addr = apt_ctf_framework::publish_compiled_module(
            adapter,
            module,
            publisher.to_string(),
            challenge.to_string(),
        );
        println!("[SERVER] Module published at: {:?}", addr);
    }
    Ok(addr)
}

fn read_solution_module(stream: &mut TcpStream) -> Result<Vec<u8>, Box<dyn Error>> {
    let mut solution_data = [0u8; 2000];
    stream.read(&mut solution_data)?;
    Ok(solution_data.to_vec())
}

fn send_message(stream: &mut TcpStream, message: String) -> Result<(), Box<dyn Error>> {
    stream.write(message.as_bytes())?;
    Ok(())
}

fn publish_solution_module(
    adapter: &mut AptosTestAdapter,
    solution_data: Vec<u8>,
    publisher: &str,
    challenge: &str,
) -> Result<AccountAddress, Box<dyn Error>> {
    let module = CompiledModule::deserialize(&solution_data)?;
    let addr = apt_ctf_framework::publish_compiled_module(
        adapter,
        module,
        publisher.to_string(),
        challenge.to_string(),
    );
    println!("[SERVER] Module published at: {:?}", addr);
    Ok(addr)
}

fn call_function(
    adapter: &mut AptosTestAdapter,
    addr: AccountAddress,
    module: &str,
    function: &str,
    sender: &str,
) -> Result<(), Box<dyn Error>> {
    let args = Vec::new();
    let type_args = Vec::new();
    apt_ctf_framework::call_function(
        adapter,
        addr,
        module,
        function,
        sender.to_string(),
        args,
        type_args,
    )
}

fn read_function_to_invoke(stream: &mut TcpStream) -> Result<String, Box<dyn Error>> {
    let mut buffer = vec![0u8; 200];
    stream.read(&mut buffer)?;
    let buffer = buffer
        .iter()
        .take_while(|&&x| x != 0)
        .cloned()
        .collect::<Vec<u8>>();
    let string = String::from_utf8(buffer)?;

    Ok(string)
}

fn parse_function_to_invoke(function_to_invoke: &str) -> Option<(AccountAddress, &str, &str)> {
    let parts: Vec<&str> = function_to_invoke.split("::").collect();
    if parts.len() == 3 {
        if let Ok(addr) = AccountAddress::from_str(parts[0]) {
            Some((addr, parts[1], parts[2]))
        } else {
            None
        }
    } else {
        None
    }
}

fn validate_solution(
    sol_ret: Result<(), Box<dyn Error>>,
    stream: &mut TcpStream,
) -> Result<(), Box<dyn Error>> {
    match sol_ret {
        Ok(()) => {
            println!("[SERVER] Correct Solution!");
            if let Ok(flag) = env::var("FLAG") {
                let message = format!("[SERVER] Congrats, flag: {}", flag);
                stream.write(message.as_bytes())?;
            } else {
                stream.write("[SERVER] Flag not found, please contact admin".as_bytes())?;
            }
        }
        Err(_) => {
            println!("[SERVER] Invalid Solution!");
            stream.write("[SERVER] Invalid Solution!".as_bytes())?;
        }
    }
    Ok(())
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    // Create Socket - Port 31337
    let listener = TcpListener::bind("0.0.0.0:31337")?;
    println!("[SERVER] Starting server at port 31337!");

    let local = tokio::task::LocalSet::new();

    // Wait For Incoming Solution
    for stream in listener.incoming() {
        match stream {
            Ok(stream) => {
                println!("[SERVER] New connection: {}", stream.peer_addr()?);
                let result = local
                    .run_until(async move {
                        tokio::task::spawn_local(async {
                            handle_client(stream).await.unwrap();
                        })
                        .await
                        .unwrap();
                    })
                    .await;
                println!("[SERVER] Result: {:?}", result);
            }
            Err(e) => {
                println!("[SERVER] Error: {}", e);
            }
        }
    }

    // Close Socket Server
    drop(listener);
    Ok(())
}
