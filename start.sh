#!/bin/sh

# Decode config from env var
echo $RELAYER_CONFIG | base64 -d > /home/relayer/.relayer/config/config.yaml

# Initialize keys
echo $NOBLE_MNEMONIC | rly keys restore noble default -
echo $SEI_MNEMONIC | rly keys restore sei default -

# Start the relayer
exec rly start noble-sei \
  --processor events \
  --block-history 100 \
  --enable-metrics-server \
  --metrics-listen-addr "0.0.0.0:5183"