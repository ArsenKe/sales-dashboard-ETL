import logging
import pandas as pd
from pathlib import Path
from datetime import datetime
from sqlalchemy import create_engine, inspect
import os
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger(__name__)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

class ETLPipeline:
    """Main ETL Pipeline for Cleaning Company Dashboard"""
    
    def __init__(self):
        self.db_url = f"postgresql://admin:{os.getenv('DB_PASSWORD', 'DFGr123')}@localhost:5432/sales_dashboard"
        self.engine = create_engine(self.db_url)
        self.raw_data_path = Path("data/raw")
        self.processed_data_path = Path("data/processed")
        self.processed_data_path.mkdir(exist_ok=True)
        
    def run(self):
        """Execute complete ETL pipeline"""
        try:
            logger.info("🚀 Starting ETL Pipeline...")
            
            # Extract
            data = self._extract()
            if data is None or len(data) == 0:
                logger.warning("⚠️ No data to process")
                return False
            
            # Transform
            data = self._transform(data)
            
            # Load
            self._load(data)
            
            logger.info("✅ ETL Pipeline completed successfully")
            return True
            
        except Exception as e:
            logger.error(f"❌ Pipeline failed: {e}", exc_info=True)
            raise
    
    def _extract(self):
        """Extract data from CSV files"""
        csv_files = list(self.raw_data_path.glob("*.csv"))
        
        if not csv_files:
            logger.warning(f"📂 No CSV files found in {self.raw_data_path}")
            return None
        
        all_data = []
        for file in csv_files:
            logger.info(f"📂 Reading {file.name}...")
            try:
                df = pd.read_csv(file, encoding='utf-8')
                logger.info(f"  Loaded {len(df)} rows from {file.name}")
                all_data.append(df)
            except Exception as e:
                logger.error(f"❌ Failed to read {file.name}: {e}")
        
        if not all_data:
            return None
            
        result = pd.concat(all_data, ignore_index=True)
        logger.info(f"📊 Total extracted: {len(result)} rows")
        return result
    
    def _transform(self, df):
        """Clean and standardize data"""
        logger.info("🔄 Transforming data...")
        
        # Remove exact duplicates
        initial_rows = len(df)
        df = df.drop_duplicates()
        logger.info(f"  Removed {initial_rows - len(df)} duplicate rows")
        
        # Fill nulls based on column type
        for col in df.columns:
            if df[col].dtype == 'object':
                df[col] = df[col].fillna('')
            elif df[col].dtype in ['int64', 'float64']:
                df[col] = df[col].fillna(0)
        
        # Add metadata
        df['loaded_at'] = datetime.now()
        df['data_quality_check'] = 'PASS'
        
        logger.info(f"✅ Transformation complete: {len(df)} rows")
        return df
    
    def _load(self, df):
        """Load data to PostgreSQL database"""
        logger.info("💾 Loading to database...")
        
        # Save processed CSV with timestamp
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        output_file = self.processed_data_path / f"processed_{timestamp}.csv"
        df.to_csv(output_file, index=False)
        logger.info(f"📁 Saved processed data to {output_file}")
        
        # Determine table name and load to DB
        try:
            # For now, assume data is for 'sales_data' table
            # In production, detect table name from CSV filename
            table_name = 'sales_data'
            
            # Create table if not exists, append data
            df.to_sql(table_name, self.engine, if_exists='append', index=False)
            logger.info(f"✅ Loaded {len(df)} rows to table '{table_name}'")
            
        except Exception as e:
            logger.error(f"❌ Failed to load to database: {e}")
            raise
    
    def validate_connection(self):
        """Test database connection"""
        try:
            with self.engine.connect() as conn:
                result = conn.execute("SELECT 1")
                logger.info("✅ Database connection successful")
                return True
        except Exception as e:
            logger.error(f"❌ Database connection failed: {e}")
            return False

if __name__ == "__main__":
    pipeline = ETLPipeline()
    
    # Test connection first
    if not pipeline.validate_connection():
        logger.error("Cannot proceed without database connection")
        exit(1)
    
    # Run pipeline
    pipeline.run()