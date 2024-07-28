from random import choice
import hashlib

CHARSET = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

def rand_str(n):
    return "".join([choice(CHARSET) for i in range(n)])

def find_ticket(n):
    while True:
        ticket = rand_str(n)

        m = hashlib.sha256()
        m.update(ticket.encode('ascii'))
        digest1 = m.digest()
        m = hashlib.sha256()
        m.update(digest1 + ticket.encode('ascii'))
        if m.hexdigest().startswith('000000'):
            return ticket

if __name__ == "__main__":
    print(f"Use ticket: {find_ticket(16)}")