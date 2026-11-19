#!/usr/bin/env bash
set -e

# Start local RabbitMQ in background and wait until AMQP port 5672 is ready
rabbitmq-server -detached
rabbitmqctl await_startup

# Start CitrineOS OCPP Server (runs Drizzle/Sequelize migrations per CITRINEOS_DB_STRATEGY)
exec pnpm --filter @citrineos/ocpp-server start
