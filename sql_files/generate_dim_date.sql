-- DROP TABLE IF EXISTS dim_date;
-- CREATE TABLE dim_date
-- (
--   date_id                  INT NOT NULL,
--   date_actual              DATE NOT NULL,
--   day_name                 VARCHAR(9) NOT NULL,
--   day_of_week              INT NOT NULL,
--   day_of_month             INT NOT NULL,
--   day_of_year              INT NOT NULL,
--   week_of_month            INT NOT NULL,
--   week_of_year             INT NOT NULL,
--   month_actual             INT NOT NULL,
--   month_name               VARCHAR(9) NOT NULL,
--   year_actual              INT NOT NULL,
--   is_weekend               BOOLEAN NOT NULL,
--   PRIMARY KEY (date_id)
-- );

-- ALTER TABLE public.dim_date ADD CONSTRAINT d_date_date_dim_id_pk PRIMARY KEY (date_id);

-- CREATE INDEX d_date_date_actual_idx
-- ON dim_date(date_actual);

INSERT INTO dim_date
SELECT TO_CHAR(datum, 'yyyymmdd')::INT AS date_id,
       datum AS date_actual,
       TO_CHAR(datum, 'TMDay') AS day_name,
       EXTRACT(ISODOW FROM datum) AS day_of_week,
       EXTRACT(DAY FROM datum) AS day_of_month,
       EXTRACT(DOY FROM datum) AS day_of_year,
       TO_CHAR(datum, 'W')::INT AS week_of_month,
       EXTRACT(WEEK FROM datum) AS week_of_year,
       EXTRACT(MONTH FROM datum) AS month_actual,
       TO_CHAR(datum, 'TMMonth') AS month_name,
       EXTRACT(YEAR FROM datum) AS year_actual,
       CASE
           WHEN EXTRACT(ISODOW FROM datum) IN (6, 7) THEN TRUE
           ELSE FALSE
           END AS is_weekend
FROM (SELECT '2019-01-01'::DATE + SEQUENCE.DAY AS datum
      FROM GENERATE_SERIES(0, 2190) AS SEQUENCE (DAY)
      GROUP BY SEQUENCE.DAY) DQ
ORDER BY 1;
