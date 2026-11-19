#!/usr/bin/env bash
set -e

# Prevent Erlang from over-allocating memory/CPU for massive containerd nofile limits
ulimit -n 65536 || true

# Pin node name and interface to localhost to avoid pod-hostname DNS delays
export RABBITMQ_NODENAME=rabbit@localhost
export RABBITMQ_NODE_IP_ADDRESS=127.0.0.1
export RABBITMQ_LOGS=-

# Start RabbitMQ in the background with logs streaming to container stdout
rabbitmq-server &
RABBIT_PID=$!

# Wait up to 60 seconds for the broker to finish first-boot Mnesia initialization
if ! rabbitmqctl -n rabbit@localhost await_startup --timeout 60; then
  echo "RabbitMQ failed to start within 60s (PID $RABBIT_PID still alive? $(kill -0 $RABBIT_PID 2>/dev/null && echo yes || echo no))"
  cat /var/log/rabbitmq/* 2>/dev/null || true
  exit 1
fi

echo "RabbitMQ is ready on localhost:5672"

# Start CitrineOS OCPP Server
exec pnpm --filter @citrineos/ocpp-server start