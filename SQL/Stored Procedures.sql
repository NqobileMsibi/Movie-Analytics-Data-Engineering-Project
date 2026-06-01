CREATE OR REPLACE PROCEDURE "EDW".sp_fact_movie_analytics()
LANGUAGE plpgsql
AS $proc$
DECLARE
    v_rows INTEGER;
BEGIN
INSERT INTO "EDW".fact_movie_analytics (
        customerid, 
        id_dim_devices, 
        id_dim_location, 
        id_dim_os,
        amount_spent, 
        review_score, 
        review_count, 
        insert_date
    )
SELECT 
        r.customer_id AS customerid,
        dd.id_dim_devices,
        dl.id_dim_location,
        dos.id_dim_os,
        COALESCE(p.amount_spent, 0) AS amount_spent,
        r.review_score,
        r.review_count,
        CURRENT_DATE AS insert_date
FROM (
        SELECT 
            customer_id,
            device,
            location,
            os,
            SUM(positive_review) AS review_score,
            COUNT(*) AS review_count
        FROM "Stage".review_session
        GROUP BY customer_id, device, location, os
    ) r
LEFT OUTER JOIN (
        SELECT 
            customer_id,
            SUM(quantity * unit_price) AS amount_spent
        FROM "Stage".user_purchase
        GROUP BY customer_id
    ) p ON p.customer_id = r.customer_id
LEFT OUTER JOIN "EDW".dim_devices dd  
    ON dd.device = r.device
LEFT OUTER JOIN "EDW".dim_location dl  
    ON dl.location = r.location
LEFT OUTER JOIN "EDW".dim_os dos 
    ON dos.os = r.os
WHERE NOT EXISTS (
		SELECT 1
		FROM "EDW".fact_movie_analytics fma
		WHERE fma.customerid = p.customer_id
		AND   fma.id_dim_devices = dd.id_dim_devices
		AND   fma.id_dim_location = dl.id_dim_location
		AND   fma.id_dim_os = dos.id_dim_os
		)
END;
$proc$;

-- Dimension Log Date
CREATE OR REPLACE PROCEDURE "EDW".sp_log_date(
	)
LANGUAGE 'sql'
AS $BODY$
INSERT INTO "EDW".dim_date(
	id_dim_date, 
	log_date, 
	day,
	month, 
	year)
SELECT DISTINCT
	CAST(CONCAT(RIGHT(log_date,4),SUBSTRING(log_date,4,2),LEFT(log_date,2)) AS INT) AS id_dim_date,
	CAST(log_date as date) AS log_date,
	LEFT(log_date,2) as day,
	SUBSTRING(log_date,4,2) as month,
	RIGHT(log_date,4) AS year
FROM "Stage".log_review
WHERE CAST(log_date as date) NOT IN (
			SELECT CAST(log_date as date)
			FROM "EDW".dim_date
)
$BODY$;

-- Dimension Operating System
CREATE OR REPLACE PROCEDURE "EDW".sp_dim_os(
	)
LANGUAGE 'sql'
AS $BODY$
INSERT INTO "EDW".dim_os(
	os)
SELECT DISTINCT os
FROM "Stage".log_review
WHERE os NOT IN (
			SELECT os
			FROM "EDW".dim_os
)
$BODY$;

-- Dimension Location
CREATE OR REPLACE PROCEDURE "EDW".sp_dim_location(
	)
LANGUAGE 'sql'
AS $BODY$
INSERT INTO "EDW".dim_location(
	location)
SELECT DISTINCT location
FROM "Stage".log_review
WHERE location NOT IN (
			SELECT location
			FROM "EDW".dim_location
)
ORDER BY Location
$BODY$;

-- Dimension Device
CREATE OR REPLACE PROCEDURE "EDW".sp_dim_device(
	)
LANGUAGE 'sql'
AS $BODY$
INSERT INTO "EDW".dim_devices(
	device)
SELECT DISTINCT device
FROM "Stage".log_review
WHERE device NOT IN (
			SELECT device
			FROM "EDW".dim_devices
)
$BODY$;

-- Joined movie_review and log_review
CREATE OR REPLACE PROCEDURE "Stage".sp_review_session(
	)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    INSERT INTO "Stage".review_session (
        id_review, 
		customer_id, 
		positive_review,
        log_date, 
		device, 
		os, 
		location, 
		ip, 
		phone_number
    )
    SELECT 
        mr.id_review,
        mr.cid AS customer_id,
        CASE WHEN mr.positive_review = 'true' THEN 1 ELSE 0 END,
        CAST(lr.log_date AS timestamp), 
		lr.device, 
		lr.os, 
		lr.location, 
		lr.ip, 
		lr.phone_number
    FROM "Stage".movie_review mr
    INNER JOIN "Stage".log_review lr ON lr.id_review = mr.id_review
    WHERE NOT EXISTS (
        SELECT 1 FROM "Stage".review_session rs
        WHERE rs.id_review = mr.id_review
    );
END;
$BODY$;
