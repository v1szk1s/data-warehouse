import 'dotenv/config'
import pg from 'pg'
const { Client } = pg

const client = new Client({
  user: process.env.USER,
  password: process.env.PASSWORD,
  host: process.env.HOST,
  port: process.env.PORT, 
  database: process.env.DATABASE, 
});

client.connect();

export const query = (text, params) => client.query(text, params);

