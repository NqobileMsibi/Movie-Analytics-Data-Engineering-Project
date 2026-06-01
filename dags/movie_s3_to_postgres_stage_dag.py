from datetime import datetime
from airflow import DAG
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator


with DAG(
    dag_id="load_s3_to_postgres_stage",
    start_date=datetime(2024, 1, 1),
    schedule_interval=None,
    catchup=False,
    tags=["spark", "s3", "postgres"],
) as dag: 


    load_files = SparkSubmitOperator(
        task_id="load_files",
        conn_id="spark_default",
        application="/opt/airflow/spark-apps/movie_transform.py",
        conf={
            "spark.jars.packages": (
            "org.postgresql:postgresql:42.7.3,"
            "org.apache.hadoop:hadoop-aws:3.3.4,"
            "com.amazonaws:aws-java-sdk-bundle:1.12.262"
        ),

        "spark.hadoop.fs.s3a.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem",
        "spark.hadoop.fs.s3a.aws.credentials.provider": (
            "com.amazonaws.auth.EnvironmentVariableCredentialsProvider"
        ),

        "spark.executorEnv.AWS_ACCESS_KEY_ID": "{{ conn.aws_default.login }}",
        "spark.executorEnv.AWS_SECRET_ACCESS_KEY": "{{ conn.aws_default.password }}",
        "spark.driverEnv.AWS_ACCESS_KEY_ID": "{{ conn.aws_default.login }}",
        "spark.driverEnv.AWS_SECRET_ACCESS_KEY": "{{ conn.aws_default.password }}",
        },
        packages=(
            "org.postgresql:postgresql:42.7.3,"
            "org.apache.hadoop:hadoop-aws:3.3.4,"
            "com.amazonaws:aws-java-sdk-bundle:1.12.262"
        ),
        env_vars={
            "AWS_ACCESS_KEY_ID": "{{ conn.aws_default.login }}",
            "AWS_SECRET_ACCESS_KEY": "{{ conn.aws_default.password }}",

            "MOVIE_REVIEW_FILE": "s3a://movie-files-430118855758-af-south-1-an/movie_review.csv",
            "LOG_REVIEW_FILE": "s3a://movie-files-430118855758-af-south-1-an/log_reviews.csv",

            "POSTGRES_HOST": "{{ conn.postgres_default.host }}",
            "POSTGRES_PORT": "{{ conn.postgres_default.port }}",
            "POSTGRES_DB": "{{ conn.postgres_default.schema }}",
            "POSTGRES_USER": "{{ conn.postgres_default.login }}",
            "POSTGRES_PASSWORD": "{{ conn.postgres_default.password }}",

            "MOVIE_TABLE": '"Stage"."movie_review"',
            "LOG_TABLE": '"Stage"."log_review"',
        },
        verbose=True,
    )
