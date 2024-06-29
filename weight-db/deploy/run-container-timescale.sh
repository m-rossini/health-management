#!/bin/bash
podman run --name timescale-db --pod postgres-pod -d -v /home/rossini/data/timescale_db:/var/lib/postgresql/data:z -e POSTGRES_PASSWORD=password timescale/timescaledb:latest-pg16
