#!/usr/bin/zsh

# Pod and container names
POD_NAME="postgres-pod"
CONTAINER_NAME="timescale-db"

# SQL files directory (current directory)
SQL_FILES_DIR=$(pwd)

# SQL files
CREATE_USER_SQL="$SQL_FILES_DIR/create_user.sql"
CREATE_DATABASES_SQL="$SQL_FILES_DIR/create_databases.sql"
USER_DB_SQL="$SQL_FILES_DIR/user_db.sql"
HEALTH_DB_SQL="$SQL_FILES_DIR/health_db.sql"

# PostgreSQL credentials
PGUSER="postgres"
PGPASSWORD="postgres"

# Check if pod exists
if ! podman pod inspect "$POD_NAME" &> /dev/null; then
  echo "Error: Pod '$POD_NAME' does not exist."
  exit 1
fi

# Check if container exists
if ! podman container inspect "$CONTAINER_NAME" &> /dev/null; then
  echo "Error: Container '$CONTAINER_NAME' does not exist."
  exit 1
fi

# Function to run SQL file inside container
run_sql_file() {
  local sql_file=$1
  local db_name=$2

  echo "Running $sql_file on database $db_name..."

  podman exec -i "$CONTAINER_NAME" psql -U "$PGUSER" -d "$db_name" -f - <<EOF
$(cat "$sql_file")
EOF

  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to run $sql_file on database $db_name."
    exit 1
  fi

  echo "$sql_file executed successfully on $db_name."
}

# Function to check if a database exists
database_exists() {
  local db_name=$1

  podman exec -i "$CONTAINER_NAME" psql -U "$PGUSER" -tAc "SELECT 1 FROM pg_database WHERE datname='$db_name';" | grep -q 1
}

# Function to create a database if it does not exist
create_database_if_not_exists() {
  local db_name=$1

  if database_exists "$db_name"; then
    echo "Database '$db_name' already exists. Skipping creation."
  else
    echo "Creating database '$db_name'..."
    podman exec -i "$CONTAINER_NAME" psql -U "$PGUSER" -c "CREATE DATABASE $db_name;"
    if [[ $? -ne 0 ]]; then
      echo "Error: Failed to create database '$db_name'."
      exit 1
    fi
    echo "Database '$db_name' created successfully."
  fi
}

# Function to check if a role exists
role_exists() {
  local role_name=$1

  podman exec -i "$CONTAINER_NAME" psql -U "$PGUSER" -tAc "SELECT 1 FROM pg_roles WHERE rolname='$role_name';" | grep -q 1
}

# Function to create a role if it does not exist
create_role_if_not_exists() {
  local role_name="rossini"
  local role_password="rossini"

  if role_exists "$role_name"; then
    echo "Role '$role_name' already exists. Skipping creation."
  else
    echo "Creating role '$role_name'..."
    podman exec -i "$CONTAINER_NAME" psql -U "$PGUSER" -c "create user rossini CREATEDB PASSWORD 'rossini';"
    if [[ $? -ne 0 ]]; then
      echo "Error: Failed to create role '$role_name'."
      exit 1
    fi
    echo "Role '$role_name' created successfully."
  fi
}

# Example usage
create_role_if_not_exists

# Run the create_databases.sql file on the default 'postgres' database
run_sql_file "$CREATE_DATABASES_SQL" "postgres"

# Ensure that the databases 'user_db' and 'health_db' were created
create_database_if_not_exists "user_db"
create_database_if_not_exists "health_db"

# Run SQL files on newly created databases
run_sql_file "$USER_DB_SQL" "user_db"
run_sql_file "$HEALTH_DB_SQL" "health_db"

echo "All SQL files executed successfully."
