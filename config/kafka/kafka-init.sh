#!/bin/bash

echo "Creating topic 'email'..."
kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --replication-factor 1 \
  --partitions 1 \
  --topic email

echo "Topic 'email' created."
