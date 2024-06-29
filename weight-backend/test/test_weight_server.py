import argparse
from datetime import datetime
import pytest
from sqlalchemy import DateTime, Float, create_engine, Table, Column, Integer, String, MetaData

from unittest.mock import patch, MagicMock
from weight_service.weight_server import app, connect_to_db, execute_query_by_user_id, get_engine, parse_args


@pytest.fixture(scope="module")
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

@pytest.fixture(scope="module")
def db_connection():
    test_db_uri = "sqlite:///:memory=/"
    conn =  connect_to_db(test_db_uri)
    yield conn
    conn.close()

def test_connect_to_db_success(db_connection):
    assert db_connection is not None
    assert 'connection'.lower() in str(type(db_connection)).lower(), "Expected connection object"
    db_connection.close()


def test_connect_to_db_exception():
    invalid_uri = "invalid_connection_string"
    try:
        conn = connect_to_db(invalid_uri)
        assert False, "Expected exception for invalid URI"
    except Exception as e:
        pass

@pytest.fixture(scope="session")
def in_memory_db_cursor():
    engine = get_engine("sqlite:///:memory")
    conn = engine.raw_connection()
    cursor = conn.cursor()
    create_table_stmt = """
CREATE TABLE IF NOT EXISTS health_data (
id INTEGER PRIMARY KEY AUTOINCREMENT,
user_id TEXT NOT NULL,
date_time DATETIME NOT NULL,
weight REAL NOT NULL,
height REAL NOT NULL,
bp_systolic INTEGER NOT NULL,
bp_diastolic INTEGER NOT NULL
);
"""
    cursor.execute(create_table_stmt)

    insert_data = """
    INSERT INTO health_data (user_id, date_time, weight, height, bp_systolic, bp_diastolic)
    VALUES ('test_user', '2023-05-29T12:34:56', 70.5, 175.3, 120, 80)
    """

    cursor.execute(insert_data)    
    yield cursor
    cursor.close()

def test_execute_query_by_user_id(in_memory_db_cursor):
    cursor = in_memory_db_cursor
    query = "SELECT id, user_id, date_time, weight, tall, bp_systolic, bp_diastolic FROM health_data where user_id = ?"
    results = execute_query_by_user_id(cursor, query, 'test_user')
    assert results == [
        {
            'id': 1,
            'user_id': 'test_user',
            'date_time': '2023-05-29T12:34:56',
            'weight': 70.5,
            'height': 175.3,
            'bp_systolic': 120,
            'bp_diastolic': 80
        }
    ]       

@patch('weight_service.weight_server.connect_to_db')
@patch('weight_service.weight_server.execute_query_by_user_id')
def test_get_entries(mock_execute_query_by_user_id, mock_connect_to_db, client):
    mock_conn = MagicMock()
    mock_connect_to_db.return_value = mock_conn

    mock_cursor = MagicMock()
    mock_conn.cursor.return_value = mock_cursor

    mock_execute_query_by_user_id.return_value = [
        {
            'id': 1,
            'user_id': 'test_user',
            'date_time': '2023-05-29T12:34:56',
            'weight': 70.5,
            'height': 175.3,
            'bp_systolic': 120,
            'bp_diastolic': 80
        }
    ]

    response = client.get('/get_entries', query_string={'user_id': 'test_user'})
    assert response.status_code == 200
    assert response.json == {
        'entries': [
            {
                'id': 1,
                'user_id': 'test_user',
                'date_time': '2023-05-29T12:34:56',
                'weight': 70.5,
                'height': 175.3,
                'bp_systolic': 120,
                'bp_diastolic': 80
            }
        ]
    }

    mock_connect_to_db.assert_called_once()
    mock_conn.cursor.assert_called_once()
    mock_cursor.close.assert_called_once()  
    mock_conn.close.assert_called_once()

def test_get_entries_missing_user_id(client):
    response = client.get('/get_entries')
    assert response.status_code == 400
    assert response.json == {'error': 'User ID is required'}

@patch('weight_service.weight_server.connect_to_db')
def test_get_entries_db_connection_failure(mock_connect_to_db, client):
    mock_connect_to_db.return_value = None

    response = client.get('/get_entries', query_string={'user_id': 'test_user'})
    assert response.status_code == 500
    assert response.json == {'error': 'Failed to connect to database'}

def test_parse_args_defaults():
    args = parse_args(argparse.ArgumentParser())

    assert args.db_host == 'postgres-pod'
    assert args.db_name == 'health'
    assert args.db_user == 'rossini'
    assert args.port == 5000
    assert args.host == '0.0.0.0'
    assert args.debug is False


def test_parse_args_with_args():
    args = parse_args(['-H', 'localhost', '-N', 'mydb', '-U', 'myuser', '-P', '8080', '-L', '127.0.0.1', '-D'])

    assert args.db_host == 'localhost'
    assert args.db_name == 'mydb'
    assert args.db_user == 'myuser'
    assert args.port == 8080
    assert args.host == '127.0.0.1'
    assert args.debug is True