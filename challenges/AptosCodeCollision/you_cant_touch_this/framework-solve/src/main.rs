use std::net::TcpStream;
use std::io::{Read, Write};
use std::str::from_utf8;
use std::{error::Error, fs};

fn main() -> Result<(), Box<dyn Error>> {

    let host = "5.161.46.43".to_string(); // replace with remote ip
    let port = 31338;

    match TcpStream::connect(format!("{}:{}", host, port)) {
        Ok(mut stream) => {
            println!("  - Connected!");

            let mod_data : Vec<u8> = fs::read("./solve/build/solution/bytecode_modules/exploit.mv").unwrap();
            println!("  - Loaded solution!");

            stream.write_all(&mod_data)?;
            stream.flush()?;
            println!("  - Sent solution!");

            let mut return_data1 = [0 as u8; 200];
            match stream.read(&mut return_data1) {
                Ok(_) => {
                    println!("  - Connection Output: '{}'", from_utf8(&return_data1).unwrap()); // Get module address
                    let mut return_data2 = [0 as u8; 200];
                    match stream.read(&mut return_data2) {
                        Ok(_) => {
                            println!("  - Connection Output: '{}'", from_utf8(&return_data2).unwrap()); // Get module address
                            let mut flag = [0 as u8; 200]; 
                            match stream.read(&mut flag) {
                                Ok(_) => {
                                    println!("  - Connection Output: '{}'", from_utf8(&flag).unwrap()); // Get flag

                                },
                                Err(e) => {
                                    println!("  - Failed to receive data: {}", e);
                                }
                            }
                        },
                        Err(e) => {
                            println!("  - Failed to receive data: {}", e);
                        }
                    }
                },
                Err(e) => {
                    println!("  - Failed to connect: {}", e);
                }
            }
        },
        Err(e) => {
            println!("  - Failed to connect: {}", e);
        }
    }
    println!("  - Terminated.");

    Ok(())
}