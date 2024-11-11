FROM --platform=$BUILDPLATFORM golang:1.21-alpine3.17 AS build-env

RUN apk add --update --no-cache curl make git libc-dev bash gcc linux-headers eudev-dev

ARG TARGETARCH
ARG BUILDARCH

RUN if [ "${TARGETARCH}" = "arm64" ] && [ "${BUILDARCH}" != "arm64" ]; then \
    wget -c https://musl.cc/aarch64-linux-musl-cross.tgz -O - | tar -xzvv --strip-components 1 -C /usr; \
    elif [ "${TARGETARCH}" = "amd64" ] && [ "${BUILDARCH}" != "amd64" ]; then \
    wget -c https://musl.cc/x86_64-linux-musl-cross.tgz -O - | tar -xzvv --strip-components 1 -C /usr; \
    fi

ADD . .

RUN if [ "${TARGETARCH}" = "arm64" ] && [ "${BUILDARCH}" != "arm64" ]; then \
    export CC=aarch64-linux-musl-gcc CXX=aarch64-linux-musl-g++;\
    elif [ "${TARGETARCH}" = "amd64" ] && [ "${BUILDARCH}" != "amd64" ]; then \
    export CC=x86_64-linux-musl-gcc CXX=x86_64-linux-musl-g++; \
    fi; \
    GOOS=linux GOARCH=$TARGETARCH CGO_ENABLED=1 LDFLAGS='-linkmode external -extldflags "-static"' make install

RUN if [ -d "/go/bin/linux_${TARGETARCH}" ]; then mv /go/bin/linux_${TARGETARCH}/* /go/bin/; fi

# Use minimal busybox from infra-toolkit image for final scratch image
FROM ghcr.io/strangelove-ventures/infra-toolkit:v0.0.6 AS busybox-min
RUN addgroup --gid 1000 -S relayer && adduser --uid 100 -S relayer -G relayer

# Create directory structure in busybox-min
RUN mkdir -p /home/relayer/.relayer/config && \
    chown -R relayer:relayer /home/relayer/.relayer

# Use ln and rm from full featured busybox for assembling final image
FROM busybox:1.34.1-musl AS busybox-full

# Build final image from scratch
FROM scratch

LABEL org.opencontainers.image.source="https://github.com/cosmos/relayer"

WORKDIR /bin

# Install ln (for making hard links) and rm (for cleanup) from full busybox image
COPY --from=busybox-full /bin/ln /bin/rm ./

# Install minimal busybox image as shell binary
COPY --from=busybox-min /busybox/busybox /bin/sh

# Add hard links for read-only utils
RUN ln sh pwd && \
    ln sh ls && \
    ln sh cat && \
    ln sh less && \
    ln sh grep && \
    ln sh sleep && \
    ln sh env && \
    ln sh tar && \
    ln sh tee && \
    ln sh du && \
    ln sh mkdir && \
    ln sh echo && \
    ln sh base64 && \
    rm ln rm

# Install chain binaries
COPY --from=build-env /bin/rly /bin

# Install trusted CA certificates
COPY --from=busybox-min /etc/ssl/cert.pem /etc/ssl/cert.pem

# Install relayer user and setup directory structure
COPY --from=busybox-min /etc/passwd /etc/passwd
COPY --from=busybox-min --chown=100:1000 /home/relayer /home/relayer

# Copy startup script with proper permissions
COPY --chmod=755 --chown=100:1000 start.sh /home/relayer/start.sh

WORKDIR /home/relayer
USER relayer

ENTRYPOINT ["/home/relayer/start.sh"]
