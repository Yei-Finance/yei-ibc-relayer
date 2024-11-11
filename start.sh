#!/bin/sh
set -e
set -x

# Write config directly
echo "$RELAYER_CONFIG" > /home/relayer/.relayer/config/config.yaml

echo "Config directory contents:"
ls -la /home/relayer/.relayer/config/

echo "Config file contents:"
cat /home/relayer/.relayer/config/config.yaml

# Initialize relayer config
# echo "Initializing relayer config..."
# rly config init

# Initialize keys
echo "Restoring Noble key..."
echo $NOBLE_MNEMONIC | rly keys restore noble default -

echo "Restoring Sei key..."
echo $SEI_MNEMONIC | rly keys restore sei default -

# Start the relayer
echo "Starting relayer..."
exec rly start noble-sei \
  --processor events \
  --block-history 100 \
  --enable-metrics-server \
  --metrics-listen-addr "0.0.0.0:5183"