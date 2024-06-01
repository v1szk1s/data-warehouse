import { query } from '$lib/db';


function convert_line(q, title){
    return { labels: q.rows.map(i => i[Object.keys(q.rows[0])[0]] ),
        datasets: [
            {
                label:title,
                fill: true,
                lineTension: 0.3,
                backgroundColor: "rgba(25, 24,30, .3)",
                borderColor: "rgb(5, 13, 15)",
                data: q.rows.map(i => i[Object.keys(q.rows[0])[1]] ),
            }
        ],
    }
}
function convert(q, title){
    return { labels: q.rows.map(i => i[Object.keys(q.rows[0])[0]] ),
        datasets: [
            {
                label:title,
                //fill: true,
                //lineTension: 0.3,
                backgroundColor: "rgba(25, 24,30, .3)",
                borderColor: "rgb(5, 13, 15)",
                //borderCapStyle: "butt",
                //borderDash: [],
                //borderDashOffset: 0.0,
                //borderJoinStyle: "miter",
                //pointBorderColor: "rgb(205, 130,1 58)",
                //pointBackgroundColor: "rgb(255, 255, 255)",
                //pointBorderWidth: 10,
                //pointHoverRadius: 5,
                //pointHoverBackgroundColor: "rgb(0, 0, 0)",
                //pointHoverBorderColor: "rgba(220, 220, 220,1)",
                //pointHoverBorderWidth: 2,
                //pointRadius: 1,
                //pointHitRadius: 10,
                data: q.rows.map(i => i[Object.keys(q.rows[0])[1]] ),
            }
        ],
    }
}

export async function load() {

    try {
        let book_usage_y = await query( "select * from usage_year;");
        let book_usage_q = await query( "SELECT year_actual || 'q' || quarter_actual as quarter, total_loans FROM usage_quarter");

        let course_request = await query( "SELECT * from request_course");
        let avg_request_time = await query( "select * from avg_time");

        let readers_by_district = await query("select * from most_reader_city");

        let annual_cost = await query("select * from an_annual_cost");

        let busy_day = await query("select * from busy_day");

        let busy_month = await query("select * from busy_month");
        console.log(busy_month.rows)


        return {
            book_usages: [
                convert_line(book_usage_y, "Book usage over time (yearly)"),
                convert_line(book_usage_q, "Book usage over time (quarterly)"),
            ],
            course_request: convert(course_request, "Book request by course"),
            avg_request_time: avg_request_time.rows[0].average_requisition_time,
            readers_by_district: convert(readers_by_district, "Readers by District"),
            annual_cost: convert(annual_cost, "Annual cost"),
            busy_day: convert(busy_day, "Busiest days"),
            busy_month: convert(busy_month, "Busiest months"),
        }
    } catch (error) {
        console.log(error)
    }

        
}
