import pandas as pd
import logging
from pathlib import Path
from typing import Dict, List, Optional

logger = logging.getLogger(__name__)

class CSVAdapter:
    """Adapter for CSV files from various sources (Shopify, WooCommerce, Custom)"""
    
    # Column mapping templates for different sources
    COLUMN_MAPPINGS = {
        'shopify': {
            'customer_name': 'Name',
            'customer_email': 'Email',
            'order_date': 'Date',
            'order_total': 'Total',
            'product_name': 'Lineitem name'
        },
        'woocommerce': {
            'customer_name': 'Billing First Name',
            'customer_email': 'Billing Email',
            'order_date': 'Date',
            'order_total': 'Order Total',
            'product_name': 'Product'
        },
        'generic': {
            'customer_name': 'customer_name',
            'customer_email': 'email',
            'order_date': 'date',
            'order_total': 'total',
            'product_name': 'service'
        }
    }
    
    def __init__(self, source_type: str = 'generic'):
        """
        Initialize CSV adapter
        
        Args:
            source_type: 'shopify', 'woocommerce', or 'generic'
        """
        self.source_type = source_type.lower()
        self.column_mapping = self.COLUMN_MAPPINGS.get(self.source_type, self.COLUMN_MAPPINGS['generic'])
        logger.info(f"📋 CSVAdapter initialized for source: {self.source_type}")
    
    def read_and_transform(self, file_path: Path, source_type: Optional[str] = None) -> pd.DataFrame:
        """
        Read CSV and transform to standard format
        
        Args:
            file_path: Path to CSV file
            source_type: Override adapter source type
            
        Returns:
            Transformed DataFrame
        """
        if source_type:
            self.source_type = source_type.lower()
            self.column_mapping = self.COLUMN_MAPPINGS.get(self.source_type, self.COLUMN_MAPPINGS['generic'])
        
        try:
            logger.info(f"📂 Reading {file_path.name} as {self.source_type}...")
            df = pd.read_csv(file_path, encoding='utf-8')
            
            # Transform columns
            df = self._map_columns(df)
            
            # Clean data
            df = self._clean_data(df)
            
            logger.info(f"✅ Successfully transformed {len(df)} rows")
            return df
            
        except Exception as e:
            logger.error(f"❌ Failed to process {file_path.name}: {e}")
            raise
    
    def _map_columns(self, df: pd.DataFrame) -> pd.DataFrame:
        """Map source columns to standard columns"""
        logger.info(f"🔄 Mapping columns from {self.source_type}...")
        
        rename_dict = {}
        for standard_col, source_col in self.column_mapping.items():
            if source_col in df.columns:
                rename_dict[source_col] = standard_col
            else:
                logger.warning(f"⚠️ Expected column '{source_col}' not found")
        
        df = df.rename(columns=rename_dict)
        
        # Keep only mapped columns
        keep_cols = [col for col in self.column_mapping.values() if col in df.columns] + \
                   [col for col in df.columns if col not in self.column_mapping.keys()]
        df = df[keep_cols]
        
        return df
    
    def _clean_data(self, df: pd.DataFrame) -> pd.DataFrame:
        """Clean and standardize data"""
        # Remove rows with missing critical fields
        critical_cols = ['customer_name', 'customer_email', 'order_date']
        df = df.dropna(subset=[col for col in critical_cols if col in df.columns])
        
        # Standardize dates
        if 'order_date' in df.columns:
            df['order_date'] = pd.to_datetime(df['order_date'], errors='coerce')
        
        # Standardize numeric fields
        if 'order_total' in df.columns:
            df['order_total'] = pd.to_numeric(df['order_total'], errors='coerce').fillna(0)
        
        # Trim whitespace
        for col in df.select_dtypes(include=['object']).columns:
            df[col] = df[col].str.strip()
        
        return df
    
    def validate_schema(self, df: pd.DataFrame, required_columns: List[str]) -> bool:
        """Validate DataFrame has required columns"""
        missing = set(required_columns) - set(df.columns)
        if missing:
            logger.error(f"❌ Missing required columns: {missing}")
            return False
        logger.info(f"✅ Schema validation passed")
        return True

# Usage Example
if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    
    adapter = CSVAdapter(source_type='shopify')
    df = adapter.read_and_transform(Path('data/raw/shopify_export.csv'))
    print(df.head())