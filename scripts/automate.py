import schedule
import time
import logging
from pathlib import Path
from datetime import datetime
from scripts.etl.main_pipeline import ETLPipeline

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/scheduler.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class ETLScheduler:
    """Scheduler for automated ETL runs"""
    
    def __init__(self):
        self.pipeline = ETLPipeline()
        Path('logs').mkdir(exist_ok=True)
        
    def scheduled_etl(self):
        """Run ETL at scheduled intervals"""
        try:
            logger.info("⏰ Running scheduled ETL...")
            self.pipeline.run()
            logger.info("✅ Scheduled ETL completed")
        except Exception as e:
            logger.error(f"❌ Scheduled ETL failed: {e}")
    
    def setup_schedule(self):
        """Configure job schedule"""
        # Run daily at 2 AM
        schedule.every().day.at("02:00").do(self.scheduled_etl)
        logger.info("📅 Schedule set: Daily at 02:00")
        
        # Run every Monday at 9 AM for full sync
        schedule.every().monday.at("09:00").do(self.scheduled_etl)
        logger.info("📅 Schedule set: Every Monday at 09:00")
        
        # Run every 6 hours
        schedule.every(6).hours.do(self.scheduled_etl)
        logger.info("📅 Schedule set: Every 6 hours")
    
    def start(self):
        """Start the scheduler"""
        self.setup_schedule()
        logger.info("🚀 Scheduler started. Press Ctrl+C to exit.")
        
        try:
            while True:
                schedule.run_pending()
                time.sleep(60)
        except KeyboardInterrupt:
            logger.info("⏹️ Scheduler stopped")

if __name__ == "__main__":
    scheduler = ETLScheduler()
    scheduler.start()