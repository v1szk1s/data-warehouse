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

-------------------VIEW FOR THAT ----------------------
-- create or replace view book_usage as
-- SELECT
--     dd.year_actual,
-- 	dd.quarter_actual,
-- 	dd.month_actual,
-- 	dd.week_of_year,
--     fr.request_id AS request_id
-- FROM
--     fact_request fr
-- JOIN
--     dim_date dd ON fr.loan_date = dd.date_actual
-- 
-- select year_actual, count(*) from book_usage
-- 	group by quarter_actual;
-- 
-- select year_actual, quarter_actual, count(*) from book_usage
-- group by year_actual, quarter_actual;
-- 
-- 
-- select year_actual, week_of_year, count(*) from book_usage
-- 	group by year_actual, week_of_year
-- 	order by
-- 	year_actual, week_of_year;


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

