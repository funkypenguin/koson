FROM debian:9 as builder

# install build dependencies
# checkout the latest tag
# build and install
RUN apt-get update && \
    apt-get install -y \
      build-essential \
      gdb \
      libreadline-dev \
      python-dev \
      gcc \
      g++\
      git \
      cmake \
      libssl-dev \
      libboost-all-dev \
      librocksdb-dev && \
    git clone https://github.com/kosonproject/koson.git /opt/koson && \
    cd /opt/koson && \
    mkdir build && \
    cd build && \
    export CXXFLAGS="-w -std=gnu++11" && \
    #cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo .. && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="-fassociative-math" -DCMAKE_CXX_FLAGS="-fassociative-math" -DSTATIC=true -DDO_TESTS=OFF .. && \
    make -j$(nproc)

FROM debian:9

# Daemon needs libreadline 
RUN apt-get update && \
    apt-get install -y \
      libreadline-dev \
     && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/bin && mkdir -p /tmp/checkpoints 

WORKDIR /usr/local/bin
COPY --from=builder /opt/koson/build/src/kosond .
COPY --from=builder /opt/koson/build/src/koson-wallet-rpc .
COPY --from=builder /opt/koson/build/src/koson-wallet-cli .
RUN mkdir -p /var/lib/koson
WORKDIR /var/lib/koson
ENTRYPOINT ["/usr/local/bin/Daemon"]
CMD ["--no-console","--data-dir","/var/lib/koson","--rpc-bind-ip","0.0.0.0","--rpc-bind-port","13002","--p2p-bind-port","13001"]
