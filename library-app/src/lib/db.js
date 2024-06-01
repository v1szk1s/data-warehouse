import 'dotenv/config'
import pg from 'pg'
const { Client } = pg

let client

try {
    
client = new Client({
  user: process.env?.PG_USER || process.env.POSTGRE_USER,
  password: process.env?.PG_PASSWORD || process.env.POSTGRE_PASSWORD,
  host: process.env?.PG_HOST || process.env.POSTGRE_HOST,
  port: process.env?.PG_PORT || process.env.POSTGRE_PORT, 
  database: process.env?.PG_DATABASE || process.env.POSTGRE_DATABASE, 
});

await client.connect();

} catch (error) {
    
}

export const query = (text, params) => client.query(text, params);

