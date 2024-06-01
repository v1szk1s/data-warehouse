DROP TABLE IF EXISTS fact_request;

DROP TABLE IF EXISTS dim_student;
CREATE TABLE dim_student
(
  student_id INT NOT NULL,
  name VARCHAR(27) NOT NULL,
  course VARCHAR(87) NOT NULL,
  gender VARCHAR(1) NOT NULL,
  date_of_birth DATE NOT NULL,
  address VARCHAR(79) NOT NULL,
  PRIMARY KEY (student_id)
);

CREATE INDEX d_student_int_student_id_idx ON dim_student(student_id);

-------------------------------

DROP TABLE IF EXISTS dim_book;
CREATE TABLE dim_book
(
  book_id INT NOT NULL,
  title VARCHAR(59) NOT NULL,
  availability BOOLEAN NOT NULL,
  purchase_date DATE NOT NULL,
  price FLOAT NOT NULL,
  PRIMARY KEY (book_id)
);
CREATE INDEX d_book_id_idx ON dim_book(book_id);

-------------------------------

DROP TABLE IF EXISTS dim_population;
CREATE TABLE dim_population
(
  population_id INT NOT NULL,
  city VARCHAR(28) NOT NULL,
  region_type VARCHAR(9) NOT NULL,
  population INT NOT NULL,
  PRIMARY KEY (population_id)
);
CREATE INDEX d_population_id_idx ON dim_population(population_id);

-------------------------------

DROP TABLE if exists dim_date;
CREATE TABLE dim_date
(
  -- loan_date_id              INT NOT NULL,
  date_actual              DATE NOT NULL,
  epoch                    BIGINT NOT NULL,
  day_name                 VARCHAR(9) NOT NULL,
  day_of_week              INT NOT NULL,
  day_of_month             INT NOT NULL,
  day_of_quarter           INT NOT NULL,
  day_of_year              INT NOT NULL,
  week_of_month            INT NOT NULL,
  week_of_year             INT NOT NULL,
  week_of_year_iso         CHAR(10) NOT NULL,
  month_actual             INT NOT NULL,
  month_name               VARCHAR(9) NOT NULL,
  month_name_abbreviated   CHAR(3) NOT NULL,
  quarter_actual           INT NOT NULL,
  quarter_name             VARCHAR(9) NOT NULL,
  year_actual              INT NOT NULL,
  first_day_of_week        DATE NOT NULL,
  last_day_of_week         DATE NOT NULL,
  first_day_of_month       DATE NOT NULL,
  last_day_of_month        DATE NOT NULL,
  first_day_of_quarter     DATE NOT NULL,
  last_day_of_quarter      DATE NOT NULL,
  first_day_of_year        DATE NOT NULL,
  last_day_of_year         DATE NOT NULL,
  mmyyyy                   CHAR(6) NOT NULL,
  mmddyyyy                 CHAR(10) NOT NULL,
  weekend_indr             BOOLEAN NOT NULL,
  PRIMARY KEY (date_actual)
);
CREATE INDEX d_loan_date_date_actual_idx ON dim_date(date_actual);

-------------------------------


CREATE TABLE stage_request
(
      request_id INT NOT NULL,
      student_id INT NOT NULL,
      book_id INT NOT NULL,
      loan_date DATE NOT NULL,
      PRIMARY KEY (request_id)
);

-------------------------------

INSERT INTO dim_date
SELECT --TO_CHAR(datum, 'yyyymmdd')::INT AS date_id,
       datum AS date_actual,
       EXTRACT(EPOCH FROM datum) AS epoch,
       TO_CHAR(datum, 'TMDay') AS day_name,
       EXTRACT(ISODOW FROM datum) AS day_of_week,
       EXTRACT(DAY FROM datum) AS day_of_month,
       datum - DATE_TRUNC('quarter', datum)::DATE + 1 AS day_of_quarter,
       EXTRACT(DOY FROM datum) AS day_of_year,
       TO_CHAR(datum, 'W')::INT AS week_of_month,
       EXTRACT(WEEK FROM datum) AS week_of_year,
       EXTRACT(ISOYEAR FROM datum) || TO_CHAR(datum, '"-W"IW-') || EXTRACT(ISODOW FROM datum) AS week_of_year_iso,
       EXTRACT(MONTH FROM datum) AS month_actual,
       TO_CHAR(datum, 'TMMonth') AS month_name,
       TO_CHAR(datum, 'Mon') AS month_name_abbreviated,
       EXTRACT(QUARTER FROM datum) AS quarter_actual,
       CASE
           WHEN EXTRACT(QUARTER FROM datum) = 1 THEN 'First'
           WHEN EXTRACT(QUARTER FROM datum) = 2 THEN 'Second'
           WHEN EXTRACT(QUARTER FROM datum) = 3 THEN 'Third'
           WHEN EXTRACT(QUARTER FROM datum) = 4 THEN 'Fourth'
           END AS quarter_name,
       EXTRACT(YEAR FROM datum) AS year_actual,
       datum + (1 - EXTRACT(ISODOW FROM datum))::INT AS first_day_of_week,
       datum + (7 - EXTRACT(ISODOW FROM datum))::INT AS last_day_of_week,
       datum + (1 - EXTRACT(DAY FROM datum))::INT AS first_day_of_month,
       (DATE_TRUNC('MONTH', datum) + INTERVAL '1 MONTH - 1 day')::DATE AS last_day_of_month,
       DATE_TRUNC('quarter', datum)::DATE AS first_day_of_quarter,
       (DATE_TRUNC('quarter', datum) + INTERVAL '3 MONTH - 1 day')::DATE AS last_day_of_quarter,
       TO_DATE(EXTRACT(YEAR FROM datum) || '-01-01', 'YYYY-MM-DD') AS first_day_of_year,
       TO_DATE(EXTRACT(YEAR FROM datum) || '-12-31', 'YYYY-MM-DD') AS last_day_of_year,
       TO_CHAR(datum, 'mmyyyy') AS mmyyyy,
       TO_CHAR(datum, 'mmddyyyy') AS mmddyyyy,
       CASE
           WHEN EXTRACT(ISODOW FROM datum) IN (6, 7) THEN TRUE
           ELSE FALSE
           END AS weekend_indr
FROM (SELECT '2014-05-21'::DATE + SEQUENCE.DAY AS datum
      FROM GENERATE_SERIES(0, 3654) AS SEQUENCE (DAY)
      GROUP BY SEQUENCE.DAY) DQ
ORDER BY 1;

-------------------------------

-------------------------------

CREATE TABLE fact_request
(
      request_id INT NOT NULL,
      loan_date DATE NOT NULL,
      student_id INT NOT NULL,
      book_id INT NOT NULL,
      population_id INT,
      -- PRIMARY KEY (request_id),
      FOREIGN KEY (student_id) REFERENCES dim_student(student_id),
      FOREIGN KEY (book_id) REFERENCES dim_book(book_id),
      FOREIGN KEY (population_id) REFERENCES dim_population(population_id),
      FOREIGN KEY (loan_date) REFERENCES dim_date(date_actual)
);

-------------------------------

COPY dim_book
FROM '/data/book.csv'
DELIMITER ','
CSV HEADER;

COPY dim_student
FROM '/data/student.csv'
DELIMITER ','
CSV HEADER;

COPY dim_population
FROM '/data/population.csv'
DELIMITER ','
CSV HEADER;

COPY stage_request
FROM '/data/request.csv'
DELIMITER ','
CSV HEADER;



insert into fact_request 
select request_id, loan_date, sr.student_id, sr.book_id, dp.population_id
from dim_population dp, stage_request sr
	inner join 
	dim_student ds
	on ds.student_id = sr.student_id
	inner join
	dim_book dib
	on dib.book_id = sr.book_id
	inner join
	dim_date dd
	on dd.date_actual = sr.loan_date
	where ds.address like '%' || dp.city || '%'
	order by loan_date;

drop table if exists stage_request;
