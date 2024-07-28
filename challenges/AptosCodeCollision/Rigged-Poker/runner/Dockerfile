FROM python:3.11-slim

RUN apt update -y
RUN apt install -y git socat gcc wget unzip

RUN pip install requests

RUN wget https://github.com/aptos-labs/aptos-core/releases/download/aptos-cli-v3.5.1/aptos-cli-3.5.1-Ubuntu-22.04-x86_64.zip
RUN unzip aptos-cli-3.5.1-Ubuntu-22.04-x86_64.zip
RUN cp aptos /bin/aptos 
RUN rm aptos-cli-3.5.1-Ubuntu-22.04-x86_64.zip aptos

RUN mkdir /app
WORKDIR /app


ADD ./rigged_poker /app/rigged_poker

RUN cd ./rigged_poker; aptos move build --named-addresses rigged_poker=0x0; cd ../

COPY ./run.py ./
COPY ./launcher.py ./


CMD socat TCP-LISTEN:7070,fork EXEC:'python /app/run.py',pty,stderr,setsid,sigint,sane
