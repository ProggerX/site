FROM ubuntu:latest

COPY . .

RUN apt update -y

RUN apt install libboost-dev g++ -y

RUN g++ ./src/* -I include -oout

CMD ["./out"]
