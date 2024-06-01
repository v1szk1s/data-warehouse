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


--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------- SOLUTIONS ------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
-------------------------------------------------------------------
--- gettin the average request time
create or replace view avg_time as
WITH next_loan AS (
    SELECT 
        request_id,
        student_id,
        book_id,
        loan_date,
        LEAD(loan_date) OVER (PARTITION BY book_id ORDER BY loan_date) AS next_loan_date
    FROM 
        fact_request
)
SELECT 
    AVG(next_loan_date - loan_date) AS average_requisition_time
FROM 
    next_loan
WHERE 
    next_loan_date IS NOT NULL;



-------------------------------------------------------------------
--- book usage over time yearly

create or replace view usage_year as
SELECT
    dd.year_actual as first,
    COUNT(fr.request_id) AS second
FROM
    fact_request fr
JOIN
    dim_date dd ON fr.loan_date = dd.date_actual
GROUP BY
    dd.year_actual
ORDER BY
    year_actual;




-------------------------------------------------------------------
--- book usage over time quarterly
create or replace view usage_quarter as
SELECT
    dd.year_actual,
    dd.quarter_actual,
    COUNT(fr.request_id) AS total_loans
FROM
    fact_request fr
JOIN
    dim_date dd ON fr.loan_date = dd.date_actual
GROUP BY
    dd.year_actual,
    dd.quarter_actual
ORDER BY
    dd.year_actual,
    dd.quarter_actual;

--- book usage over time montly
create or replace view usage_month as
SELECT
    dd.year_actual,
    dd.month_actual,
    COUNT(fr.request_id) AS total_loans
FROM
    fact_request fr
JOIN
    dim_date dd ON fr.loan_date = dd.date_actual
GROUP BY
    dd.year_actual,
    dd.month_actual
ORDER BY
    dd.year_actual,
    dd.month_actual;


-------------------------------------------------------------------
---books that have never been requested, and their associated costs.
create or replace view never_requested as
select dim_book.title as title, dim_book.price as price
	from dim_book
	where book_id not in (select book_id from fact_request)
	order by price desc
	offset 0
    fetch next 50 rows only;

-------------------------------------------------------------------
---Identify which city have the most readers
create or replace view most_reader_city as
select dim_population.city as first, count(request_id) as second from fact_request
inner join
dim_population on dim_population.population_id = fact_request.population_id
group by dim_population.population_id
order by second desc;



-------------------------------------------------------------------
--- the most requested books per:
-- student
create or replace view most_request_student as
WITH student_book_requests AS (
    SELECT
        fr.student_id,
        fr.book_id,
        COUNT(fr.request_id) AS request_count
    FROM
        fact_request fr
    GROUP BY
        fr.student_id,
        fr.book_id
),
ranked_books AS (
    SELECT
        sbr.student_id,
        sbr.book_id,
        sbr.request_count,
        ROW_NUMBER() OVER (PARTITION BY sbr.student_id ORDER BY sbr.request_count DESC) AS rank
    FROM
        student_book_requests sbr
)
SELECT
    ds.name,
    db.title,
    rb.request_count
FROM
    ranked_books rb
JOIN
    dim_student ds ON rb.student_id = ds.student_id
JOIN
    dim_book db ON rb.book_id = db.book_id
WHERE
    rb.rank = 1
ORDER BY
    rb.request_count desc;


-- per course
create or replace view most_request_course as
WITH course_book_requests AS (
    SELECT
        ds.course,
        fr.book_id,
        COUNT(fr.request_id) AS request_count
    FROM
        fact_request fr
    JOIN
        dim_student ds ON fr.student_id = ds.student_id
    GROUP BY
        ds.course,
        fr.book_id
),
ranked_books AS (
    SELECT
        cbr.course,
        cbr.book_id,
        cbr.request_count,
        ROW_NUMBER() OVER (PARTITION BY cbr.course ORDER BY cbr.request_count DESC) AS rank
    FROM
        course_book_requests cbr
)
SELECT
    rb.course,
    db.title
    -- rb.request_count
FROM
    ranked_books rb
JOIN
    dim_book db ON rb.book_id = db.book_id
WHERE
    rb.rank = 1
ORDER BY
    rb.course;

create view request_course as
SELECT ds.course, COUNT(fr.request_id) AS count FROM fact_request fr JOIN dim_student ds ON fr.student_id = ds.student_id GROUP BY ds.course ORDER BY count DESC LIMIT 10; 

-- by gender
create or replace view most_request_gender as
select dim_student.gender as gender, dim_book.title from fact_request
inner join
dim_student on dim_student.student_id = fact_request.student_id
inner join
dim_book on dim_book.book_id = fact_request.book_id
group by dim_student.gender, title
	order by count(request_id) desc;



-- by districts with higher populations
create or replace view most_request_population as
select dim_population.city as first, count(request_id) as second
	from fact_request
	join
	dim_population on dim_population.population_id = fact_request.population_id
	where dim_population.population > 250000
	group by dim_population.city
	order by second desc;


-------------------------------------------------------------------
--- Analyze annual acquisition costs 
create or replace view an_annual_cost as
SELECT
    EXTRACT(YEAR FROM purchase_date) AS purchase_year,
    SUM(price) AS total_acquisition_cost
FROM
    dim_book
GROUP BY
    purchase_year
ORDER BY
    purchase_year;


-------------------------------------------------------------------
--- Analyze the relationship between reading newer and older books
create or replace view an_new_old as
SELECT
    EXTRACT(YEAR FROM fr.loan_date) AS loan_year,
    CASE
        WHEN AGE(fr.loan_date, db.purchase_date) <= INTERVAL '1 year' THEN '0-1 year'
        WHEN AGE(fr.loan_date, db.purchase_date) <= INTERVAL '2 year' THEN '1-2 years'
        WHEN AGE(fr.loan_date, db.purchase_date) <= INTERVAL '5 year' THEN '2-5 years'
        ELSE '5+ years'
    END AS book_age_category,
    COUNT(fr.request_id) AS total_requests
FROM
    fact_request fr
JOIN
    dim_book db ON fr.book_id = db.book_id
GROUP BY
    loan_year,
    book_age_category
ORDER BY
    loan_year,
    book_age_category;


-------------------------------------------------------------------
--- books not returned, among other aspects
create or replace view not_returned as
with next_loan as ( SELECT 
        request_id,
        student_id,
        book_id,
        loan_date,
        LEAD(loan_date) OVER (PARTITION BY book_id ORDER BY loan_date) AS next_loan_date
    FROM 
        fact_request
) select dim_book.book_id, title from next_loan
	inner join
	dim_book on dim_book.book_id = next_loan.book_id
	where next_loan_date is null
	group by dim_book.book_id;


-------------------------------------------------------------------
--- Determine the busiest day of the week for requisitions on average
create or replace view busy_day as
SELECT
    dd.day_name,
    COUNT(fr.request_id) AS total_requests
FROM
    fact_request fr
JOIN
    dim_date dd ON fr.loan_date = dd.date_actual
GROUP BY
    dd.day_name
ORDER BY
    total_requests DESC;

-------------------------------------------------------------------
--- Determine the months with the highest usage.
create or replace view busy_month as
SELECT
    dd.month_name,
    COUNT(fr.request_id) AS total_requests
FROM
    fact_request fr
JOIN
    dim_date dd ON fr.loan_date = dd.date_actual
GROUP BY
    dd.month_name, 
    dd.month_actual
ORDER BY
    total_requests desc;
