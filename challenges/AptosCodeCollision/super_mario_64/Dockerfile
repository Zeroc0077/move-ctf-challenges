FROM --platform=linux/amd64 ubuntu:latest

RUN apt-get update && \
    apt-get install -y curl build-essential python3 git libssl-dev pkg-config clang

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    echo 'source /root/.cargo/env' >> /root/.bashrc

ENV PATH="/root/.cargo/bin:$PATH"
RUN curl -fsSL "https://aptos.dev/scripts/install_cli.py" -o install_cli.py && \
    python3 install_cli.py --bin-dir /bin

RUN mkdir -p /ctf 

COPY framework /ctf/framework

WORKDIR /ctf

RUN cd framework/challenge && aptos move compile
RUN cd framework && RUSTFLAGS="--cfg tokio_unstable" cargo b --release

WORKDIR /ctf/framework

ENTRYPOINT ["./target/release/framework"]
