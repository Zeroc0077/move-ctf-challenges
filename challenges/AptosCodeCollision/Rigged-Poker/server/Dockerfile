FROM tiangolo/uvicorn-gunicorn-fastapi:python3.11

RUN apt update -y
RUN apt install -y apt-transport-https ca-certificates curl wget gnupg lsb-release

RUN wget https://github.com/aptos-labs/aptos-core/releases/download/aptos-cli-v3.5.1/aptos-cli-3.5.1-Ubuntu-22.04-x86_64.zip
RUN unzip aptos-cli-3.5.1-Ubuntu-22.04-x86_64.zip
RUN cp aptos /bin/aptos 
RUN rm aptos-cli-3.5.1-Ubuntu-22.04-x86_64.zip aptos

RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
RUN echo "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN apt update -y
RUN apt install -y docker-ce docker-ce-cli containerd.io

COPY ./requirements.txt /app/
COPY ./main.py /app/
COPY ./prestart.sh /app/


RUN pip install --no-cache-dir --upgrade -r /app/requirements.txt
