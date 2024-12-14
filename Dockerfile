# Base
FROM rust:1.81 AS base
ARG MASSA_VERSION
WORKDIR /src
RUN apt-get -y update && apt-get install -y --no-install-recommends git && git clone https://github.com/massalabs/massa -b ${MASSA_VERSION}
# Install build dependencies
RUN apt-get install -y --no-install-recommends  \
  build-essential \
  cmake \
  curl \
  git \
  libclang-dev \
  libssl-dev \
  pkg-config

# Massa node
FROM base AS node-builder
WORKDIR /src/massa/
RUN cargo build --release --manifest-path massa-node/Cargo.toml

# Massa client
FROM base AS client-builder
WORKDIR /src/massa/
RUN cargo build --release --manifest-path massa-client/Cargo.toml

# Final
FROM gcr.io/distroless/cc-debian12 AS production
WORKDIR /app
USER nonroot
COPY --from=node-builder /src/massa/target/release/massa-node .
COPY --from=client-builder /src/massa/target/release/massa-client .
ENTRYPOINT ["/app/massa-node"]
