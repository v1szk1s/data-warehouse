import { query } from '$lib/db';


function convert_line(rows, title){
    return { labels: rows.map(i => i.first ),
        datasets: [
            {
                label:title,
                fill: true,
                lineTension: 0.3,
                backgroundColor: "rgba(25, 24,30, .3)",
                borderColor: "rgb(5, 13, 15)",
                borderCapStyle: "butt",
                borderDash: [],
                borderDashOffset: 0.0,
                borderJoinStyle: "miter",
                pointBorderColor: "rgb(205, 130,1 58)",
                pointBackgroundColor: "rgb(255, 255, 255)",
                pointBorderWidth: 10,
                pointHoverRadius: 5,
                pointHoverBackgroundColor: "rgb(0, 0, 0)",
                pointHoverBorderColor: "rgba(220, 220, 220,1)",
                pointHoverBorderWidth: 2,
                pointRadius: 1,
                pointHitRadius: 10,
                data: rows.map(i => i.second ),
            }
        ],
    }
}

function convert_bar(rows, title){
    return { labels: rows.map(i => i.first ),
            datasets: [
                {
                    label:title,
                    backgroundColor:  "rgba(14, 16, 11, 0.7)",
                    borderColor:  "rgba(1, 1, 1, 1)",
                    data: rows.map(i => i.second ),
                }
            ],
    }
}

export async function load() {
    let book_usage_y;
    let book_usage_q;
    let course_request;
    let avg_request_time;
    let books_never_requested;
    let readers_by_district;
    let most_requests_per_student;


    try {
        book_usage_y = await query( "SELECT dd.year_actual first, COUNT(fr.request_id) AS second FROM fact_request fr JOIN dim_date dd ON fr.loan_date = dd.date_actual GROUP BY dd.year_actual ORDER BY year_actual;", [],"","array");
        book_usage_q = await query( "SELECT dd.year_actual || 'q' || dd.quarter_actual as first, COUNT(fr.request_id) AS second FROM fact_request fr JOIN dim_date dd ON fr.loan_date = dd.date_actual GROUP BY dd.year_actual, dd.quarter_actual ORDER BY dd.year_actual, dd.quarter_actual; ", [],"","array");

        course_request = await query( "SELECT ds.course first, COUNT(fr.request_id) AS second FROM fact_request fr JOIN dim_student ds ON fr.student_id = ds.student_id GROUP BY ds.course ORDER BY second DESC LIMIT 10; ", [],"","array");
        avg_request_time = await query( "WITH next_loan AS ( SELECT request_id, student_id, book_id, loan_date, LEAD(loan_date) OVER (PARTITION BY book_id ORDER BY loan_date) AS next_loan_date FROM fact_request) SELECT AVG(next_loan_date - loan_date) AS average_requisition_time FROM next_loan WHERE next_loan_date IS NOT NULL;", [],"","array");

        books_never_requested = await query("select dim_book.title as first, dim_book.price as second from dim_book where book_id not in (select book_id from fact_request) order by second offset 0 fetch next 50 rows only; ", []);

        readers_by_district = await query("select dim_population.city as first, count(request_id) as second from fact_request inner join dim_population on dim_population.population_id = fact_request.population_id group by dim_population.population_id order by second desc; ", []);

        most_requests_per_student = await query("select * from most_requests_per_student;", []);
        console.log(most_requests_per_student.fields.map(i => i.name))

    } catch (error) {
        console.log(error)
    }

    return {
        book_usages: [
            convert_line(book_usage_y.rows, "Book usage over time (yearly)"),
            convert_line(book_usage_q.rows, "Book usage over time (quarterly)"),
        ],
        course_request: convert_bar(course_request.rows, "Book request by course"),
        avg_request_time: avg_request_time.rows[0].average_requisition_time,
        books_never_requested: books_never_requested.rows,
        readers_by_district: convert_bar(readers_by_district.rows, "Readers by District"),
    }
        
}
