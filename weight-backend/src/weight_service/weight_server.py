
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS
from sqlalchemy import create_engine, text
from functools import cache
import argparse
import logging

logging.basicConfig(level=logging.DEBUG)

major_version = 0
minor_version = 1
modification_version = 0
semantic_version = f"{major_version}.{minor_version}.{modification_version}"

default_port=5003
db_uri = None
app = Flask(__name__)
CORS(app,origins=['*'], 
     supports_credentials=True,
     methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"], 
     allow_headers=["Content-Type", "Authorization"])

@cache
def get_engine(uri):
    return create_engine(uri)

def connect_to_db(uri):
    try:
        engine = get_engine(uri) 
        return engine.connect()
    except Exception as e:
        app.logger.error("Error connecting to database:", e)
        return None


@app.route('/get_entries', methods=['GET'])
def get_entries():
    app.logger.info(">>>:weight-server.Retrieving entries.Version: %s, Session: %s, Headers: %s",semantic_version, request.args, request.headers)
    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({'error': 'User ID is required'}), 400

    conn = connect_to_db(db_uri)
    if not conn:
        return jsonify({'error': 'Failed to connect to database'}), 500
    
    try:
        query = text("SELECT id, user_id, TO_CHAR(date_time, 'YYYY-MM-DD HH24:MI:SS'), weight, height, bp_systolic, bp_diastolic, heart_rate FROM health.health_data where user_id = :user_id")
        results = execute_query_by_user_id(conn, query, user_id)
        return jsonify({'entries': results}), 200
    except Exception as e:
        app.logger.error("Error retrieving entries: %s", str(e))
        return jsonify({'error': 'Failed to retrieve entries'}), 500
    finally:
        if conn:
            conn.close()  # Close connection

def row_to_dict(row):
  return {
      'id': row[0],
      'user_id': row[1],
      'date_time': row[2],
      'weight': row[3],
      'height': row[4],
      'bp_systolic': row[5],
      'bp_diastolic': row[6],
      'heart_rate': row[7]
  }

def execute_query_by_user_id(conn, query, user_id):
    rows = conn.execute(query, {'user_id': user_id}) #.bindparams(user_id)
    return [row_to_dict(row) for row in rows]

@app.route('/add_entry', methods=['POST'])
def add_entry():
    conn = connect_to_db(db_uri)
    if not conn:
        return jsonify({'error': 'Failed to connect to database'}), 500

    try:
        user_id = request.json.get('user_id')
        if not user_id:
            return jsonify({'error': 'User ID is required'}), 400

        weight = request.json.get('weight')
        if not weight:
            return jsonify({'error': 'Weight is required'}), 400

        height = request.json.get('height')
        if not height:
            return jsonify({'error': 'height is required'}), 400
        
        date_time = request.json.get('date_time')
        if not date_time:
            date_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

        bp_systolic = request.json.get('bp_systolic')
        bp_diastolic = request.json.get('bp_diastolic')
        heart_rate = request.json.get('heart_rate')
        insert_health_data(conn, user_id, weight, height, date_time, bp_systolic, bp_diastolic,heart_rate)
        conn.commit()

        return jsonify({'message': 'Entry added successfully!'}), 201
    except Exception as e:
        app.logger.error("Error adding entry: %s", str(e))
        conn.rollback()  # Rollback on error
        return jsonify({'error': 'Failed to add entry'}), 500
    finally:
        if conn:
            conn.close()  # Close connection

def insert_health_data(conn, user_id, weight, height, date_time, bp_systolic, bp_diastolic,heart_rate):
    query = text("INSERT INTO health.health_data (user_id, weight, height, date_time, bp_systolic, bp_diastolic, heart_rate) VALUES (:user_id, :weight, :height, :date_time, :bp_systolic, :bp_diastolic, :heart_rate)")
    health_data = {
        'user_id': user_id, #.bindparams(user_id,
        'weight': weight, #.bindparams(weight,
        'height': height, #.bindparams(height,
        'date_time': date_time,
        'bp_systolic': bp_systolic, #.bindparams(bp_systolic,
        'bp_diastolic': bp_diastolic, #.bindparams(bp_diastolic
        'heart_rate': heart_rate #.bindparams
    }
    conn.execute(query, health_data)

@app.route('/delete_entry/<int:user_id>/<int:entry_id>', methods=['DELETE'])
def delete_entry(user_id, entry_id):
    app.logger.info(">>>:weight-server.Deleting entry.User Id: %s, Entry Id: %s, Session: %s, Headers: %s", user_id, entry_id, request.args, request.headers)    
    try:
        with get_engine(db_uri).connect() as connection:
            query = text("DELETE FROM health.health_data WHERE user_id = :user_id and id = :entry_id")
            connection.execute(query, {'user_id': user_id, 'entry_id': entry_id})
            connection.commit()
        return jsonify({'message': 'Entry deleted successfully'}), 200
    except Exception as e:
        app.logger.error(f"Error deleting entry: {e}")
        return jsonify({'error': 'Failed to delete entry'}), 500
    
def parse_args(parser):
    parser.add_argument('-H', '--db-host',
                        default='postgres-pod', help='DB host')
    parser.add_argument('-N', '--db-name', default='health_db', help='DB name')
    parser.add_argument('-U', '--db-user', default='rossini', help='DB user')
    parser.add_argument('-P', '--port', type=int,
                        default=default_port, help='App listening port')
    parser.add_argument('-L', '--host', default='0.0.0.0',
                        help='App listening host')
    parser.add_argument(
        '-D', '--debug', action='store_true', help='Debug mode')
    return parser.parse_args()


def get_postgres_url_from_args(args):
    return get_postgres_url(args.db_user, args.db_host, args.db_name)


def get_postgres_url(db_user, db_host, db_name):
    return f'postgresql://{db_user}:rossini@{db_host}/{db_name}'


if __name__ == '__main__':
    arg = parse_args(argparse.ArgumentParser())
    print(">>>:weight-server. Args", arg)
    db_uri = get_postgres_url_from_args(arg)
    app.run(host='0.0.0.0', port=default_port, debug=arg.debug)
