#!/usr/bin/env bash
set -e

# Prevent Erlang from over-allocating file-descriptor tables on containerd
ulimit -n 65536 || true

# Persist settings in /etc/rabbitmq/rabbitmq-env.conf so Debian's `su rabbitmq` preserves them
mkdir -p /etc/rabbitmq
cat <<EOF > /etc/rabbitmq/rabbitmq-env.conf
NODENAME=rabbit@localhost
NODE_IP_ADDRESS=127.0.0.1
LOGS=-
EOF

# Disable non-essential plugins to speed up cold boot and lower RAM usage
echo "[]." > /etc/rabbitmq/enabled_plugins

# Start RabbitMQ in the background (logs now stream directly to Northflank stdout)
rabbitmq-server &
RABBIT_PID=$!

# Poll AMQP port 5672 for up to 90s without spawning extra Erlang CLI VMs
READY=0
for i in $(seq 1 30); do
  if ! kill -0 "$RABBIT_PID" 2>/dev/null; then
    echo "RabbitMQ process (PID $RABBIT_PID) exited unexpectedly."
    exit 1
  fi
  if (echo > /dev/tcp/127.0.0.1/5672) >/dev/null 2>&1; then
    echo "RabbitMQ is ready on 127.0.0.1:5672 (~$((i * 3))s)"
    READY=1
    break
  fi
  sleep 3
done

if [ "$READY" -ne 1 ]; then
  echo "Timed out after 90s waiting for RabbitMQ on 127.0.0.1:5672"
  exit 1
fi

# Start CitrineOS OCPP Server
exec pnpm --filter @citrineos/ocpp-server start