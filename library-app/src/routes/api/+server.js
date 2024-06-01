import { json } from '@sveltejs/kit';
import { query } from '$lib/db';


const page_size = 10;

function convert_table(query_res, title){
    return {
        label: title, 
        titles: query_res.fields.map(i => i.name),
        rows: query_res.rows,
    }

}

export async function POST({ request }) {
    const { table, page } = await request.json();

    console.log(table, page)

    try {
        let query_string, title;

        switch(table){
            case "most_request_student":
                title = "Most Requested per Student";
                query_string = "select * from most_request_student offset $1 limit $2;";
                break;
            case "most_request_course":
                title = "Most Requested per Course";
                query_string = "select * from most_request_course offset $1 limit $2;";
                break;
            case "most_request_gender":
                title = "Most Requested per Gender";
                query_string = "select * from most_request_gender offset $1 limit $2;";
                break;
            case "most_request_population":
                title = "Most Requested per population";
                query_string = "select * from most_request_population offset $1 limit $2;";
                break;
            case "never_requested":
                title = "Books Not Requested";
                query_string = "select * from never_requested offset $1 limit $2;";
                break;
            case "not_returned":
                title = "Books Not Returned";
                query_string = "select * from not_returned offset $1 limit $2;";
                break;
            case "an_new_old":
                title = "Relationship between older and newer books";
                query_string = "select * from an_new_old offset $1 limit $2;";
                break;
            default: query_string = "";
        }

        if(query_string == "") return json({});
        //console.log(await query(query_string,[page*page_size, page_size]))

        //const query_res = await query("select * from dim_student limit 2;", []);
        return json(
            convert_table((await query(query_string,[page*page_size, page_size])), title)
        );

    } catch (error) {
        console.log(error)
    }
    return json({});
}

