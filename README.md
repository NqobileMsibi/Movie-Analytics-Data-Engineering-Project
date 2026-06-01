# End-to-End Movie Analytics Data Pipeline

The solution ingests transactional and external review data, transforms it into analytics-ready datasets, and loads a dimensional warehouse to support reporting and business insights.

---

## Project Summary

This project simulates a real-world use case for a user behavior analytics company that needs to combine customer purchase data, movie review text, and review session metadata into a single reporting-ready data model.

The final output is a warehouse centered around a fact table called **`fact_movie_analytics`**, supported by dimension tables for:

- date
- device
- location
- operating system
- date

This enables downstream analytics such as:

- review activity by state
- review activity by device type
- positive review scoring
- customer spending analysis
- device usage by region

---

## Architecture Overview

### Infrastructure Used

- **AWS EC2**
  - hosted the project environment
  - ran **Docker containers**
  - hosted **Airflow**
  - hosted **Spark jobs**
- **Docker**
  - containerized orchestration and processing services
- **Apache Airflow**
  - orchestrated the end-to-end ETL workflow
- **Apache Spark / PySpark**
  - transformed raw review and log data
- **Amazon RDS PostgreSQL**
  - stored:
    - Airflow metadata database
    - source transactional data
    - analytics warehouse tables
- **SQL**
  - used for schema design, dimensional modeling, and analytics queries

---

## Business Problem

A user behavior analytics company needs a data pipeline to populate an OLAP-ready table called **`fact_movie_analytics`**.

The source data comes from three systems:

1. **`user_purchase`**
   - stored in PostgreSQL
   - contains transactional customer purchase data

2. **`movie_review.csv`**
   - contains customer reviews
   - includes customer id, review id, and review message

3. **`log_reviews.csv`**
   - contains review session metadata
   - includes review id and XML-based session details like:
     - log date
     - device
     - OS
     - region/location
     - IP
     - phone number

The challenge was to setting up airflow to use spark to run the transforms and split the xml data into it's individual columns.

---

## End-to-End Pipeline Flow

1. **Provision and configure environment**
   - Launch AWS EC2 instance
   - Install Docker and run project services
   - Configure Airflow and Spark execution environment
   - Connect Airflow to Amazon RDS PostgreSQL

2. **Load source data**
   - Load `user_purchase.csv` into PostgreSQL
   - Place external files into the raw ingestion layer

3. **Transform reviews with Spark**
   - tokenize review text
   - remove stop words
   - classify reviews containing the word `"good"` as positive
   - convert boolean result into integer score:
     - `1` for positive
     - `0` otherwise
   - write transformed review data to staging table

4. **Transform logs with Spark**
   - parse XML stored in the log column
   - extract structured metadata fields
   - remove raw XML column
   - write structured log data to staging table

5. **Build dimension tables**
   - `dim_date`
   - `dim_devices`
   - `dim_location`
   - `dim_os`

6. **Build fact table**
   - `fact_movie_analytics`
   - aggregate amount spent, review score, and review count by customer and dimension keys

7. **Serve analytics**
   - create analytics queries and dashboard-ready datasets

---

## Tech Stack

- **Cloud**: AWS
- **Compute**: EC2
- **Containerization**: Docker
- **Orchestration**: Apache Airflow
- **Processing**: Apache Spark / PySpark
- **Database / Warehouse**: Amazon RDS PostgreSQL
- **Analytics / BI**: PowerBI
- **Querying**: SQL
- **Programming**: Python

---

## Data Sources

### 1. `user_purchase`
Transactional purchase data stored in PostgreSQL.

**Columns**
- `invoice_number`
- `stock_code`
- `detail`
- `quantity`
- `invoice_date`
- `unit_price`
- `customer_id`
- `country`

### 2. `movie_review.csv`
Customer movie review data.

**Columns**
- `cid`
- `review_id`
- `review_str`

### 3. `log_reviews.csv`
Review session metadata.

**Contains**
- `id_review`
- XML log payload with:
  - `log_date`
  - `device`
  - `os`
  - `location`
  - `ip`
  - `phone_number`

---

## Transformation Logic

### Review Transformation
Using PySpark, I transformed `movie_review.csv` by:

- tokenizing the review text
- optionally removing stop words
- identifying whether a review contains the word **"good"**
- creating a `positive_review` flag
- converting the flag into an integer metric for downstream aggregation
- appending pipeline execution timestamp as `insert_date`

**Output**
- `user_id`
- `review_id`
- `positive_review`
- `insert_date`

---

### Log Transformation
Using PySpark, I transformed `log_reviews.csv` by:

- mapping the schema for XML content in the log field
- parsing the XML content into structured columns
- extracting:
  - `review_id`
  - `log_date`
  - `device`
  - `os`
  - `location`
  - `ip`
  - `phone_number`
- dropping the original raw log/XML column

**Output**
- `review_id`
- `log_date`
- `device`
- `os`
- `location`
- `ip`
- `phone_number`

---

## Data Warehouse Model

### Fact Table

#### `fact_movie_analytics`

| Column | Description |
|--------|-------------|
| customerid | Customer identifier |
| id_dim_date | Date dimension key |
| id_dim_devices | Device dimension key |
| id_dim_location | Location dimension key |
| id_dim_os | OS dimension key |
| amount_spent | Total customer spend |
| review_score | Sum of positive reviews |
| review_count | Total reviews |
| insert_date | Pipeline load date |

---

### Dimension Tables

#### `dim_date`
- `id_dim_date`
- `log_date`
- `day`
- `month`
- `year`
- `season`

#### `dim_devices`
- `id_dim_devices`
- `device`

#### `dim_location`
- `id_dim_location`
- `location`

#### `dim_os`
- `id_dim_os`
- `os`
  
---

## Fact Table Business Logic

The fact table was built using the following business rules:

- `customerid` => from `user_purchase.customer_id`
- `amount_spent` => `SUM(quantity * unit_price)`
- `review_score` => `SUM(positive_review)`
- `review_count` => `COUNT(review_id)`
- `insert_date` => Airflow pipeline runtime timestamp

---

## Example Analytics Questions Answered

This project supports queries such as:

- How many reviews were submitted in California, New York, and Texas?
- How many reviews were submitted using Apple devices?
- Which states had the highest and lowest review volume in 2021?
- Which customers spent the most and how does that compare to review activity?

└── notebooks/
    └── exploratory_checks.ipynb
