import pandas as pd
import os

class CSVAdapter:
    """Adapter for CSV files from various sources"""
    
    # Column mappings for different systems
    COLUMN_MAPPINGS = {
        'shopify': {
            'Name': 'customer_name',
            'Email': 'customer_email',
            'Financial Status': 'payment_status',
            'Total': 'total_amount'
        },
        'woocommerce': {
            'Order ID': 'invoice_number',
            'Order Total': 'total_amount',
            'Customer Note': 'notes'
        },
        'generic': {
            'date': 'sale_date',
            'customer': 'customer_name',
            'amount': 'total_amount',
            'product': 'product_name'
        }
    }
    
    @staticmethod
    def read_and_transform(file_path, source_type='generic'):
        """
        Read CSV and transform to standard format
        
        Args:
            file_path: Path to CSV file
            source_type: Type of source system
            
        Returns:
            DataFrame in standardized format
        """
        try:
            # Read CSV with flexible encoding
            for encoding in ['utf-8', 'latin-1', 'iso-8859-1']:
                try:
                    df = pd.read_csv(file_path, encoding=encoding)
                    break
                except UnicodeDecodeError:
                    continue
            
            # Get column mapping for this source
            mapping = CSVAdapter.COLUMN_MAPPINGS.get(source_type, {})
            
            # Rename columns if mapping exists
            if mapping:
                df = df.rename(columns=mapping)
            
            # Ensure required columns (add defaults if missing)
            required_cols = ['sale_date', 'customer_name', 'total_amount', 'product_name']
            
            for col in required_cols:
                if col not in df.columns:
                    if col == 'sale_date':
                        df[col] = pd.Timestamp.now()
                    elif col == 'total_amount':
                        df[col] = 0
                    else:
                        df[col] = ''
            
            # Clean data
            df = CSVAdapter.clean_data(df)
            
            return df
            
        except Exception as e:
            raise Exception(f"Error processing CSV: {e}")
    
    @staticmethod
    def clean_data(df):
        """Clean and standardize data"""
        
        # Convert date columns
        date_columns = [col for col in df.columns if 'date' in col.lower()]
        for col in date_columns:
            df[col] = pd.to_datetime(df[col], errors='coerce')
        
        # Clean numeric columns
        numeric_columns = [col for col in df.columns if 'amount' in col.lower() or 'price' in col.lower()]
        for col in numeric_columns:
            df[col] = pd.to_numeric(df[col], errors='coerce')
            df[col] = df[col].fillna(0)
        
        # Clean string columns
        string_columns = [col for col in df.columns if 'name' in col.lower() or 'email' in col.lower()]
        for col in string_columns:
            df[col] = df[col].astype(str).str.strip()
        
        return df