import sqlite3
from datetime import datetime, timedelta

# The local database file that will be created on the Android device
DB_FILE = "vyshu_memory.db"

def init_db():
    """Builds the database tables if they do not exist on first boot."""
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    
    # 1. Chat History Table (With 14-Day Auto-Deletion)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS chat_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            role TEXT,
            message TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # 2. Task & Reminder Table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            scheduled_time DATETIME,
            is_completed BOOLEAN DEFAULT 0
        )
    ''')
    
    # 3. Fitness Consistency Table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS fitness_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            workout_type TEXT,
            duration_minutes INTEGER,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    conn.commit()
    conn.close()

# ---------------------------------------------------------
# CHAT MEMORY SYSTEM
# ---------------------------------------------------------
def log_chat(role, message):
    """Saves a new message and scrubs data older than 14 days."""
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    
    # Insert the new message
    cursor.execute("INSERT INTO chat_history (role, message) VALUES (?, ?)", (role, message))
    
    # The 14-Day Rolling Scrubber
    fourteen_days_ago = datetime.now() - timedelta(days=14)
    cursor.execute("DELETE FROM chat_history WHERE timestamp < ?", (fourteen_days_ago,))
    
    conn.commit()
    conn.close()

def get_recent_chat(limit=15):
    """Retrieves the most recent messages so she remembers the conversation context."""
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    
    # Pull the last N messages
    cursor.execute("SELECT role, message FROM chat_history ORDER BY timestamp DESC LIMIT ?", (limit,))
    rows = cursor.fetchall()
    conn.close()
    
    # Format them specifically for the Gemini API structure
    return [{"role": r[0], "parts": [{"text": r[1]}]} for r in reversed(rows)]

# ---------------------------------------------------------
# TASK & SCHEDULE SYSTEM
# ---------------------------------------------------------
def add_task(title, time_str):
    """Logs a new task or reminder."""
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("INSERT INTO tasks (title, scheduled_time) VALUES (?, ?)", (title, time_str))
    conn.commit()
    conn.close()
    return True

def get_pending_tasks():
    """Retrieves all tasks that have not been completed yet."""
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("SELECT id, title, scheduled_time FROM tasks WHERE is_completed = 0 ORDER BY scheduled_time ASC")
    tasks = cursor.fetchall()
    conn.close()
    return tasks

# ---------------------------------------------------------
# FITNESS SYSTEM
# ---------------------------------------------------------
def log_workout(workout_type, minutes):
    """Saves a workout session to calculate the ongoing streak."""
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("INSERT INTO fitness_logs (workout_type, duration_minutes) VALUES (?, ?)", (workout_type, minutes))
    conn.commit()
    conn.close()
    return True

# Run the initialization immediately when the file is imported
init_db()

