FROM debian:13-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc \
        g++ \
        python3 \
        python3-pip \
        ripgrep \
        make \
        libc6-dev \
        git \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY sdk /opt/sdk

ENV PATH="/opt/sdk/bin:${PATH}"

WORKDIR /workspace

CMD echo 'Usage: docker run --rm -v ${PWD}:/workspace aglab2/n64chain:latest make -j$(nproc)\n'
