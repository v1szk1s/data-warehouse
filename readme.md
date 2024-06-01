# Connect to container
psql -h localhost -U hulu -p 30000 library_dwh

## sources
Script for creating dim_date table: https://duffn.medium.com/creating-a-date-dimension-table-in-postgresql-af3f8e2941ac
