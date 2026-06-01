SELECT 
    dl.location,
    COUNT(f.review_count) AS reviews
FROM "EDW".fact_movie_analytics f
INNER JOIN "EDW".dim_location dl ON dl.id_dim_location = f.id_dim_location
INNER JOIN "EDW".dim_devices  dd ON dd.id_dim_devices  = f.id_dim_devices
INNER JOIN "EDW".dim_os       dos ON dos.id_dim_os     = f.id_dim_os
WHERE dl.location IN (
	'California',
	'New York',
	'Texas'
)
GROUP BY dl.location;


SELECT 
    dl.location,
    dd.device,
    COUNT(f.review_count) AS Review
FROM "EDW".fact_movie_analytics f
INNER JOIN "EDW".dim_location dl ON dl.id_dim_location = f.id_dim_location
INNER JOIN "EDW".dim_devices  dd ON dd.id_dim_devices  = f.id_dim_devices
INNER JOIN "EDW".dim_os       dos ON dos.id_dim_os     = f.id_dim_os
WHERE os = 'Apple iOS' 
AND dl.location IN (
	'California',
	'New York',
	'Texas'
)
GROUP BY dl.location, dd.device
ORDER BY dl.location, Review DESC;


SELECT 
    dl.location,
	  dd.device,
    dos.os,
    to_char(SUM(f.amount_spent), 'R FM999,999,990.00') AS Total
FROM "EDW".fact_movie_analytics f
INNER JOIN "EDW".dim_location dl ON dl.id_dim_location = f.id_dim_location
INNER JOIN "EDW".dim_devices  dd ON dd.id_dim_devices  = f.id_dim_devices
INNER JOIN "EDW".dim_os       dos ON dos.id_dim_os     = f.id_dim_os
GROUP BY dl.location, dd.device, dos.os
ORDER BY Total;
