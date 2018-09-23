# Multistage docker build, requires docker 17.05

# builder stage
FROM ubuntu:16.04 as builder

# BUILD_DATE and VCS_REF are immaterial, since this is a 2-stage build, but our build
# hook won't work unless we specify the args
ARG BUILD_DATE
ARG VCS_REF

RUN apt-get update && \
    apt-get --no-install-recommends --yes install \
        ca-certificates \
        cmake \
        g++ \
        libboost1.58-all-dev \
        libssl-dev \
        libzmq3-dev \
        libreadline-dev \
        libsodium-dev \
        make \
        pkg-config \
        graphviz \
        doxygen \
        git

RUN git clone https://github.com/kosonproject/koson.git /src
WORKDIR /src
#COPY . .

ARG NPROC
RUN rm -rf build && \
    if [ -z "$NPROC" ];then make -j$(nproc) release-static;else make -j$NPROC release-static;fi

# runtime stage
FROM ubuntu:16.04

# Now we DO need these, for the auto-labeling of the image
ARG BUILD_DATE
ARG VCS_REF

# Good docker practice, plus we get microbadger badges
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/funkypenguin/koson.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.schema-version="2.2-r1"

RUN apt-get update && \
    apt-get --no-install-recommends --yes install ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt

COPY --from=builder /src/build/release/bin/* /usr/local/bin/

# Contains the blockchain
VOLUME /root/.koson

# Generate your wallet via accessing the container and run:
# cd /wallet
# koson-wallet-cli
VOLUME /wallet

EXPOSE 15301
EXPOSE 15302

ENTRYPOINT ["kosond", "--p2p-bind-ip=0.0.0.0", "--p2p-bind-port=15301", "--rpc-bind-ip=0.0.0.0", "--rpc-bind-port=15302", "--non-interactive"]
