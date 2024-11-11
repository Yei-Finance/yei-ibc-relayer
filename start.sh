#!/bin/sh

set -e  # Exit on any error
set -x  # Print commands as they're executed

# Create necessary directories
mkdir -p /home/relayer/.relayer/config

# Decode config from env var
echo "Decoding config..."
echo $RELAYER_CONFIG | base64 -d > /home/relayer/.relayer/config/config.yaml

# Verify config was written
ls -la /home/relayer/.relayer/config/
cat /home/relayer/.relayer/config/config.yaml

# Initialize relayer config
echo "Initializing relayer config..."
rly config init

# Initialize keys
echo "Restoring Noble key..."
echo "$NOBLE_MNEMONIC" | rly keys restore noble default -

echo "Restoring Sei key..."
echo "$SEI_MNEMONIC" | rly keys restore sei default -

# Start the relayer
echo "Starting relayer..."
exec rly start noble-sei \
  --processor events \
  --block-history 100 \
  --enable-metrics-server \
  --metrics-listen-addr "0.0.0.0:5183"