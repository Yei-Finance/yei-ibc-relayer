#!/bin/sh
set -e
set -x

# Write config directly
echo "$RELAYER_CONFIG" > /home/relayer/.relayer/config/config.yaml

echo "Config directory contents:"
ls -la /home/relayer/.relayer/config/

echo "Config file contents:"
cat /home/relayer/.relayer/config/config.yaml

# Initialize keys
echo "Restoring Noble key..."
rly keys restore noble yei "$NOBLE_MNEMONIC"

echo "Restoring Sei key..."
rly keys restore sei yei "$SEI_MNEMONIC"

# Explicitly set RPC addresses
rly chains set-rpc-addr noble "https://rpc.lavenderfive.com:443/noble"
rly chains set-backup-rpc-addrs noble "https://noble-rpc.polkachu.com:443,https://noble-rpc.owallet.io:443"

rly chains set-rpc-addr sei "https://rpc.sei-apis.com:443/?x-apikey=d0227c6f"
rly chains set-backup-rpc-addrs sei "https://rpc.lavenderfive.com:443/sei,https://sei-rpc.polkachu.com:443"

# Verify RPC connections
echo "Verifying RPC connections..."
rly chains list

# Query balances to ensure connectivity
echo "Checking chain balances..."
rly q balance noble
rly q balance sei

# Debugging
echo "Path details:"
rly paths show noble-sei

# Start the relayer
echo "Starting relayer..."
exec rly start noble-sei \
  --processor events \
  --block-history 100 \
  --enable-metrics-server \
  --metrics-listen-addr "0.0.0.0:5183"