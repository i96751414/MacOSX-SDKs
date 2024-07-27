FROM debian:buster

ARG XAR_REV="xar-1.6.1"
ARG PBZX_REV=master

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        libssl-dev \
        libbz2-dev \
        libxml2-dev \
        zlib1g-dev \
        liblzma-dev \
        autoconf \
        p7zip-full \
        curl \
        cpio \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

RUN curl -ksSL "https://github.com/mackyle/xar/archive/${XAR_REV}.tar.gz" | tar --strip=1 -xz \
    && cd xar \
    && sed -i 's|OpenSSL_add_all_ciphers|OPENSSL_init_crypto|' configure.ac \
    && ./autogen.sh \
    && ./configure \
    && make -j"$(nproc)" \
    && make install \
    && rm -rf "$(pwd)/"*

RUN curl -ksSL "https://github.com/NiklasRosenstein/pbzx/archive/${PBZX_REV}.tar.gz" | tar --strip=1 -xz \
    && cc -llzma -lxar -I /usr/local/include pbzx.c -o pbzx \
    && mv pbzx /usr/bin/ \
    && rm -rf "$(pwd)/"*

ENV PATH="/scripts:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}"

COPY scripts /scripts

VOLUME /sdk
WORKDIR /sdk
ENTRYPOINT ["gen_sdk_package_from_dmg.sh"]
