from flask import Flask, jsonify, request, abort, render_template
import sqlite3

app = Flask(__name__)

# Connect to SQLite Database
def get_db_connection():
    conn = sqlite3.connect('tasks.db')
    conn.row_factory = sqlite3.Row
    return conn

# Initialize the database
def init_db():
    conn = get_db_connection()
    conn.execute('''
        CREATE TABLE IF NOT EXISTS tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            completed BOOLEAN NOT NULL DEFAULT 0
        )
    ''')
    conn.commit()
    conn.close()

@app.route('/')
def index():
    return render_template('index.html')

# API to Get All Tasks (Read)
@app.route('/api/tasks', methods=['GET'])
def get_tasks():
    conn = get_db_connection()
    tasks = conn.execute('SELECT * FROM tasks').fetchall()
    conn.close()
    return jsonify([dict(task) for task in tasks])

# API to Create a Task
@app.route('/api/tasks', methods=['POST'])
def create_task():
    data = request.get_json()
    if not data or 'title' not in data:
        abort(400, 'Task title is required')

    conn = get_db_connection()
    conn.execute('INSERT INTO tasks (title) VALUES (?)', (data['title'],))
    conn.commit()
    conn.close()
    return jsonify({'message': 'Task created successfully'}), 201

# API to Update a Task
@app.route('/api/tasks/<int:task_id>', methods=['PUT'])
def update_task(task_id):
    data = request.get_json()
    if not data or 'title' not in data:
        abort(400, 'Task title is required')

    conn = get_db_connection()
    conn.execute('UPDATE tasks SET title = ? WHERE id = ?', (data['title'], task_id))
    conn.commit()
    conn.close()
    return jsonify({'message': 'Task updated successfully'})

# API to Delete a Task
@app.route('/api/tasks/<int:task_id>', methods=['DELETE'])
def delete_task(task_id):
    conn = get_db_connection()
    conn.execute('DELETE FROM tasks WHERE id = ?', (task_id,))
    conn.commit()
    conn.close()
    return jsonify({'message': 'Task deleted successfully'})

if __name__ == '__main__':
    init_db()
    app.run(host="0.0.0.0", port=80)
