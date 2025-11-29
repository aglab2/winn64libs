FROM ubuntu:18.04

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        flex \
        bison \
        gawk \
        m4 \
        texinfo \
        libgmp-dev \
        libmpfr-dev \
        libmpc-dev \
        wget \
        ca-certificates \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

