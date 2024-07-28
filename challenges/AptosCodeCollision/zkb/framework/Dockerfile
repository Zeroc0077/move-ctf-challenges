FROM rust:latest

RUN apt-get update && apt-get install -qy clang libudev-dev nodejs npm tmux vim neovim git netcat-traditional zsh nano wget cmake gcc libssl-dev libclang-dev curl libpq-dev screen
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

RUN rustup component add rustfmt
RUN rustup update stable

WORKDIR /home

RUN rustup update stable
RUN wget https://github.com/aptos-labs/aptos-core/releases/download/aptos-cli-v3.3.1/aptos-cli-3.3.1-Ubuntu-x86_64.zip
RUN unzip aptos-cli-3.3.1-Ubuntu-x86_64.zip
RUN chmod +x aptos 
RUN mv aptos /bin

WORKDIR /work/framework
ADD ./Cargo.toml .
ADD ./Cargo.lock .

RUN mkdir src
RUN echo "fn main() {}" > src/main.rs
RUN RUSTFLAGS="--cfg tokio_unstable" cargo build --release
RUN rm -rf src

ADD ./ /work/framework

WORKDIR /work/framework/challenge
RUN apt-get install libssl-dev openssl
RUN wget http://nz2.archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.22_amd64.deb
RUN dpkg -i libssl1.1_1.1.1f-1ubuntu2.22_amd64.deb
RUN aptos move compile

WORKDIR /work/framework

# refresh from dummy
RUN touch src/main.rs
RUN RUSTFLAGS="--cfg tokio_unstable" cargo build --locked --release

CMD RUSTFLAGS="--cfg tokio_unstable" cargo r --release