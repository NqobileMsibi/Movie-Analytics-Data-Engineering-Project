from pyspark.sql import DataFrame, SparkSession
from pyspark.sql import functions as F
from pyspark.ml.feature import Tokenizer, StopWordsRemover
from pyspark.sql.functions import *
from pyspark.sql.types import *
import xml.etree.ElementTree as ET
from pyspark.sql.types import ArrayType, IntegerType
import os

# Environment variables
MOVIE_REVIEW_FILE = os.getenv("MOVIE_REVIEW_FILE")
LOG_REVIEW_FILE = os.getenv("LOG_REVIEW_FILE")
POSTGRES_HOST = os.environ["POSTGRES_HOST"]
POSTGRES_PORT = os.environ.get("POSTGRES_PORT", "5432")
POSTGRES_DB = os.environ["POSTGRES_DB"]
POSTGRES_USER = os.environ["POSTGRES_USER"]
POSTGRES_PASSWORD = os.environ["POSTGRES_PASSWORD"]
MOVIE_TABLE = os.getenv("MOVIE_TABLE")
LOG_TABLE = os.getenv("LOG_TABLE")
POSTGRES_URL = f"jdbc:postgresql://{POSTGRES_HOST}:{POSTGRES_PORT}/{POSTGRES_DB}"


spark = SparkSession.builder \
       .appName("Moviedata") \
       .getOrCreate()

## Movie Data Cleaning
moviedf = (spark
    .read
    .option("header", "true")
    .option("inferSchema", "true")
    .csv(MOVIE_REVIEW_FILE))


# Getting a list of words
tokenizer = Tokenizer(inputCol="review_str", outputCol="review_token")
moviedf = tokenizer.transform(moviedf)


# Removing stop words
remover = StopWordsRemover(inputCol="review_token", outputCol="filtered")
moviedf = remover.transform(moviedf)


# Getting good words
moviedf = moviedf.withColumn("positive_review", array_contains(moviedf["filtered"], "good"))
moviedf = moviedf.withColumn("insert_date", current_timestamp())


# dropping columns
moviedf_clean = moviedf.drop("review_str","review_token","filtered")


#Loading to Postgres
moviedf_clean.write \
    .format("jdbc") \
    .option("url", POSTGRES_URL) \
    .option("dbtable", MOVIE_TABLE) \
    .option("user", POSTGRES_USER) \
    .option("password", POSTGRES_PASSWORD) \
    .option("driver", "org.postgresql.Driver") \
    .mode("append") \
    .save()


## Log Data Cleaning
logdf = (spark
    .read
    .option("header", "true")
    .csv(LOG_REVIEW_FILE))


log_reviewsrdd = logdf.rdd

schema = StructType([
    StructField("log_date", StringType(), True),
    StructField("device", StringType(), True),
    StructField("os", StringType(), True),
    StructField("location", StringType(), True),
    StructField("ip", StringType(), True),
    StructField("phone_number", StringType(), True)
])

def select_text(doc, xpath):
    nodes = [e.text for e in doc.findall(xpath) if isinstance(e, ET.Element)]
    return next(iter(nodes), None)

def parse_xml(log):
    row = ET.fromstring(log)
    return {
        'log_date':  select_text(row, 'log/logDate'),
        'device':  select_text(row, 'log/device'),
        'os': select_text(row, 'log/os'),
        'location': select_text(row, 'log/location'),
        'ip': select_text(row, 'log/ipAddress'),
        'phone_number':  select_text(row, 'log/phoneNumber')
  }

extract_log_udf = udf(parse_xml, schema)

clean_log_df = (logdf
 .withColumn("info", extract_log_udf(logdf["log"]))
 .select('id_review','info.log_date', 'info.device','info.os', 'info.location', 'info.ip','info.phone_number'))

clean_log_df = clean_log_df.withColumn('id_review', clean_log_df['id_review'].cast(IntegerType()))


#Loading to Postgres
clean_log_df.write \
    .format("jdbc") \
    .option("url", POSTGRES_URL) \
    .option("dbtable", LOG_TABLE) \
    .option("user", POSTGRES_USER) \
    .option("password", POSTGRES_PASSWORD) \
    .option("driver", "org.postgresql.Driver") \
    .mode("append") \
    .save()

spark.stop()
