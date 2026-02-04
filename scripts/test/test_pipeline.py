import pytest
import pandas as pd
from pathlib import Path
from scripts.etl.main_pipeline import ETLPipeline
from scripts.adapters.csv_adapter import CSVAdapter

class TestETLPipeline:
    
    @pytest.fixture
    def pipeline(self):
        return ETLPipeline()
    
    @pytest.fixture
    def sample_df(self):
        return pd.DataFrame({
            'name': ['Test1', 'Test1', 'Test2'],
            'amount': [10.0, 10.0, None],
            'date': ['2024-01-01', '2024-01-02', '2024-01-03']
        })
    
    def test_transform_removes_duplicates(self, pipeline, sample_df):
        result = pipeline._transform(sample_df.copy())
        # Original: 3 rows, 1 duplicate → 2 rows
        assert len(result) == 2
    
    def test_transform_fills_nulls(self, pipeline, sample_df):
        result = pipeline._transform(sample_df.copy())
        assert result['amount'].isna().sum() == 0
    
    def test_validate_connection(self, pipeline):
        # This will fail if DB not running
        assert pipeline.validate_connection() == True

class TestCSVAdapter:
    
    def test_shopify_adapter(self):
        adapter = CSVAdapter(source_type='shopify')
        assert 'customer_name' in adapter.column_mapping
    
    def test_woocommerce_adapter(self):
        adapter = CSVAdapter(source_type='woocommerce')
        assert 'customer_email' in adapter.column_mapping
    
    def test_generic_adapter(self):
        adapter = CSVAdapter(source_type='generic')
        assert adapter.source_type == 'generic'

