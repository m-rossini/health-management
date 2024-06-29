#!/usr/bin/zsh

# Pod name and network (replace if needed)
POD_NAME="postgres-pod"
POD_NETWORK="marcos-net"

# Get the current user's home directory
USER_HOME_DIR="$HOME"

# Define the TimescaleDB directory path
TIMESCALE_DB_DIR="$USER_HOME_DIR/data/timescale_db"

# Check if network exists
if ! podman network inspect "$POD_NETWORK" &> /dev/null; then
  echo "Error: Network '$POD_NETWORK' does not exist."
  exit 1
fi

# Create the TimescaleDB directory if it doesn't exist
if [ ! -d "$TIMESCALE_DB_DIR" ]; then
  echo "Creating directory '$TIMESCALE_DB_DIR'..."
  mkdir -p "$TIMESCALE_DB_DIR"
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to create directory '$TIMESCALE_DB_DIR'."
    exit 1
  fi
fi

# Pod create command (replace with your actual command if different)
POD_CREATE_COMMAND="podman pod create --name $POD_NAME --network $POD_NETWORK --hostname postgres-host --memory 8G -p 5432:5432 -p 8000:80"

# Debug: Print the pod create command
echo "Pod create command: $POD_CREATE_COMMAND"

# Check if pod exists
if ! podman pod inspect "$POD_NAME" &> /dev/null; then
  echo "Pod '$POD_NAME' does not exist. Creating..."
  # Run pod create command
  eval $POD_CREATE_COMMAND
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to create pod '$POD_NAME'."
    exit 1
  fi
fi

# Container 1: TimescaleDB
CONTAINER_NAME_1="timescale-db"
RUN_COMMAND_1="podman run --name $CONTAINER_NAME_1 --pod $POD_NAME -d -v $TIMESCALE_DB_DIR:/var/lib/postgresql/data:z -e POSTGRES_PASSWORD=password timescale/timescaledb:latest-pg16"

# Debug: Print the container run command for TimescaleDB
echo "Run command for TimescaleDB: $RUN_COMMAND_1"

echo "Starting container '$CONTAINER_NAME_1'..."
eval $RUN_COMMAND_1
if [[ $? -ne 0 ]]; then
  echo "Error: Failed to start container '$CONTAINER_NAME_1'."
  exit 1
fi

# Container 2: pgAdmin
CONTAINER_NAME_2="pgadmin"
RUN_COMMAND_2="podman run --rm --name $CONTAINER_NAME_2 --pod $POD_NAME -v vol-pgadmin:/var/lib/pgadmin:z -e 'PGADMIN_DEFAULT_EMAIL=mrpt68@gmail.com' -e 'PGADMIN_DEFAULT_PASSWORD=pass123' -d dpage/pgadmin4"

# Debug: Print the container run command for pgAdmin
echo "Run command for pgAdmin: $RUN_COMMAND_2"

echo "Starting container '$CONTAINER_NAME_2'..."
eval $RUN_COMMAND_2
if [[ $? -ne 0 ]]; then
  echo "Error: Failed to start container '$CONTAINER_NAME_2'."
  exit 1
fi

echo "All containers in pod '$POD_NAME' started successfully."

