#!/bin/bash

# Get the instance ID of the running instance
INSTANCE_ID=$(vastai show instances | grep running | awk '{print $1}')

if [ -z "$INSTANCE_ID" ]; then
    echo "No running instances found."
    exit 0
fi

echo "Destroying instance $INSTANCE_ID..."
vastai destroy instance $INSTANCE_ID

echo "Instance destroyed successfully." 