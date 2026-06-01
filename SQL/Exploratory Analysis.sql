-- How many reviews were done in California, NY and Texas?

SELECT 
    dl.location,
    COUNT(f.review_count) AS reviews
FROM "EDW".fact_movie_analytics f
INNER JOIN "EDW".dim_location dl 
	ON dl.id_dim_location = f.id_dim_location
INNER JOIN "EDW".dim_devices dd 
	ON dd.id_dim_devices = f.id_dim_devices
INNER JOIN "EDW".dim_os dos 
	ON dos.id_dim_os = f.id_dim_os
WHERE dl.location IN (
	'California',
	'New York',
	'Texas'
)
GROUP BY dl.location;

--How many reviews were done in California, NY, and Texas with an Apple device? And how many for each device type?

SELECT 
    dl.location,
    dd.device,
    COUNT(f.review_count) AS Review
FROM "EDW".fact_movie_analytics f
INNER JOIN "EDW".dim_location dl 
	ON dl.id_dim_location = f.id_dim_location
INNER JOIN "EDW".dim_devices dd 
	ON dd.id_dim_devices = f.id_dim_devices
INNER JOIN "EDW".dim_os dos 
	ON dos.id_dim_os = f.id_dim_os
WHERE os = 'Apple iOS' 
AND dl.location IN (
	'California',
	'New York',
	'Texas'
)
GROUP BY dl.location, dd.device
ORDER BY dl.location, Review DESC;

--What are the states with more and fewer reviews in 2021?

SELECT 
    dl.location,
    COUNT(f.review_count) AS reviews
FROM "EDW".fact_movie_analytics f
INNER JOIN "EDW".dim_location dl ON dl.id_dim_location = f.id_dim_location
INNER JOIN "EDW".dim_devices  dd ON dd.id_dim_devices  = f.id_dim_devices
INNER JOIN "EDW".dim_os       dos ON dos.id_dim_os     = f.id_dim_os
GROUP BY dl.location
ORDER BY reviews DESC
LIMIT 10;


SELECT 
    dl.location,
    COUNT(f.review_count) AS reviews
FROM "EDW".fact_movie_analytics f
INNER JOIN "EDW".dim_location dl ON dl.id_dim_location = f.id_dim_location
INNER JOIN "EDW".dim_devices  dd ON dd.id_dim_devices  = f.id_dim_devices
INNER JOIN "EDW".dim_os       dos ON dos.id_dim_os     = f.id_dim_os
GROUP BY dl.location
ORDER BY reviews
LIMIT 10;
