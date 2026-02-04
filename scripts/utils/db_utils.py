import logging
from sqlalchemy import create_engine, inspect
import os
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger(__name__)

def get_db_engine():
    """Get SQLAlchemy engine for database connection"""
    db_url = f"postgresql://admin:{os.getenv('DB_PASSWORD', 'DFGr123')}@localhost:5432/sales_dashboard"
    return create_engine(db_url)

def table_exists(engine, table_name):
    """Check if table exists in database"""
    inspector = inspect(engine)
    return table_name in inspector.get_table_names()

def get_table_count(engine, table_name):
    """Get row count from table"""
    with engine.connect() as conn:
        result = conn.execute(f"SELECT COUNT(*) FROM {table_name}")
        return result.scalar()

def backup_table(engine, table_name, backup_path):
    """Backup table to CSV"""
    import pandas as pd
    from datetime import datetime
    
    df = pd.read_sql(f"SELECT * FROM {table_name}", engine)
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    file_path = f"{backup_path}/backup_{table_name}_{timestamp}.csv"
    df.to_csv(file_path, index=False)
    logger.info(f"✅ Backed up {table_name} to {file_path}")
    return file_path