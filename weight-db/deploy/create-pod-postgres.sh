#!/bin/bash
podman pod create --network marcos-net --hostname postgres-host --memory 8G -p5432:5432 -p 8000:80 postgres-pod
