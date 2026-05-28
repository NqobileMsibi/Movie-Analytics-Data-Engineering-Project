CREATE TABLE "EDW".fact_movie_analytics (
customerid INTEGER,
id_dim_devices INTEGER,
id_dim_location INTEGER,
id_dim_os INTEGER,
amount_spent DECIMAL(18, 5),
review_score INTEGER,
review_count INTEGER,
insert_date DATE);

CREATE TABLE "EDW".dim_date (
id_dim_date INTEGER PRIMARY KEY,
log_date DATE,
day VARCHAR,
month VARCHAR,
year VARCHAR,
season VARCHAR
);

CREATE TABLE "EDW".dim_devices (
id_dim_devices INTEGER PRIMARY KEY,
device VARCHAR
);

CREATE TABLE "EDW".dim_location (
id_dim_location INTEGER PRIMARY KEY,
location VARCHAR
);

CREATE TABLE "EDW".dim_os (
id_dim_devices INTEGER PRIMARY KEY,
os VARCHAR
);



