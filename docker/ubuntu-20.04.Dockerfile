ARG CUDA_VERSION=11.4.3
ARG OS_VERSION=20.04
FROM nvidia/cuda:${CUDA_VERSION}-cudnn8-devel-ubuntu${OS_VERSION}

# FROM nvidia/cuda:11.4.3-devel-ubuntu20.04
#LABEL maintainer="NVIDIA CORPORATION"

ENV TRT_VERSION 8.5.2.2
SHELL ["/bin/bash", "-c"]

# Setup user account
ARG uid=1000
ARG gid=1000
RUN groupadd -r -f -g ${gid} trtuser && useradd -o -r -l -u ${uid} -g ${gid} -ms /bin/bash trtuser && \
    usermod -aG sudo trtuser && \
    echo 'trtuser:nvidia' | chpasswd && \
    mkdir -p /workspace && chown trtuser /workspace

# Required to build Ubuntu 20.04 without user prompts with DLFW container
ENV DEBIAN_FRONTEND=noninteractive

# Update CUDA signing key and install required libraries
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/3bf863cc.pub && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    libcurl4-openssl-dev \
    wget \
    git \
    pkg-config \
    sudo \
    ssh \
    libssl-dev \
    pbzip2 \
    vim \
    pv \
    bzip2 \
    unzip \
    build-essential \
    libprotobuf-dev \
    protobuf-compiler \
    libprotoc-dev \
    libopencv-dev \
    mosquitto \
    mosquitto-clients \
    python3 \
    python3-pip \
    python3-dev \
    python3-wheel && \
    cd /usr/local/bin && \
    ln -s /usr/bin/python3 python && \
    ln -s /usr/bin/pip3 pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install PyPI packages
RUN pip3 install --no-cache-dir --upgrade pip setuptools>=41.0.0 && \
    pip3 install --no-cache-dir --upgrade numpy

# Install Cmake
RUN cd /tmp && \
    wget https://github.com/Kitware/CMake/releases/download/v3.14.4/cmake-3.14.4-Linux-x86_64.sh && \
    chmod +x cmake-3.14.4-Linux-x86_64.sh && \
    ./cmake-3.14.4-Linux-x86_64.sh --prefix=/usr/local --exclude-subdir --skip-license && \
    rm ./cmake-3.14.4-Linux-x86_64.sh

# Download NGC client
RUN cd /usr/local/bin && \
    wget https://ngc.nvidia.com/downloads/ngccli_cat_linux.zip && \
    unzip ngccli_cat_linux.zip && \
    chmod u+x ngc-cli/ngc && \
    rm ngccli_cat_linux.zip ngc-cli.md5 && \
    echo "no-apikey\nascii\n" | ngc-cli/ngc config set

# Set environment and working directory
ENV TRT_LIBPATH /usr/lib/x86_64-linux-gnu
ENV TRT_OSSPATH /workspace/TensorRT
ENV PATH="${PATH}:/usr/local/bin/ngc-cli"
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${TRT_OSSPATH}/build/out:${TRT_LIBPATH}"
WORKDIR /workspace

USER trtuser
RUN ["/bin/bash"]
