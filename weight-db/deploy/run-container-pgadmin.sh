#!/bin/bash
podman run --rm --name pgadmin --pod postgres-pod -v vol-pgadmin:/var/lib/pgadmin:z -e 'PGADMIN_DEFAULT_EMAIL=mrpt68@gmail.com' -e 'PGADMIN_DEFAULT_PASSWORD=pass123' -d dpage/pgadmin4
