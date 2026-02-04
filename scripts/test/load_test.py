from locust import HttpUser, task, between
import logging

logger = logging.getLogger(__name__)

class MetabaseLoadTest(HttpUser):
    """Load testing for Metabase dashboard"""
    
    wait_time = between(1, 3)  # Random wait 1-3 seconds
    
    @task(3)
    def view_dashboard(self):
        """Simulate user viewing dashboard"""
        self.client.get("/api/dashboard/1")
    
    @task(2)
    def run_query(self):
        """Simulate running a query"""
        self.client.post("/api/dataset", json={
            "database": 1,
            "type": "query",
            "query": {"source-table": 1}
        })
    
    @task(1)
    def get_cards(self):
        """Simulate fetching cards"""
        self.client.get("/api/card")

# Run with: locust -f scripts/test/load_test.py --host=http://localhost:3000