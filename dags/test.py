from airflow.decorators import dag, task
from datetime import datetime

@dag(
    dag_id="gitsync_test_dag",
    schedule=None,  # Manual trigger only
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=["test", "gitsync"],
)
def gitsync_test_dag():

    @task()
    def check_sync():
        print("GitSync successful! The DAG is running from the repository.")
        return "Sync Verified"

    check_sync()

# Instantiate the DAG
gitsync_test_dag()
