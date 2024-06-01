#!/usr/bin/env python3.11

import pandas as pd


def get_max_len(lista):
    return max(list(map(lambda x: (len(x)), lista)))


csv_path = "../data_csv/"
dest_path = "../data_transformed/"


book_file = "book.csv"
student_file = "student.csv"
request_file = "request.csv"
resident_file = "population.csv"

book_usecols = ["book_id", "title", "price", "purchase_date", "availability"]
book = pd.read_csv(csv_path + book_file, index_col="book_id", usecols=book_usecols)
print(f'max book.title length: { get_max_len(book["title"].values) }')

student_usecols = ["student_id", "name", "course", "address", "gender", "date_of_birth"]
student = pd.read_csv(csv_path + student_file, index_col="student_id", usecols=student_usecols)
print(f'max student.course length: { get_max_len(student["course"].values) }')
print(f'max student.address length: { get_max_len(student["address"].values) }\n')
print(f'max student.name length: { get_max_len(student["name"].values) }\n')

request = pd.read_csv(csv_path + request_file, index_col="request_id")

population = pd.read_csv(csv_path + resident_file, index_col="population_id")
print(f'max population.city length: { get_max_len(population["city"].values) }')
print(f'max population.region_type length: { get_max_len(population["region_type"].values) }')




def save():
    population.to_csv(dest_path + resident_file)
    book.to_csv(dest_path + book_file)
    request.to_csv(dest_path + request_file)
    student.to_csv(dest_path + student_file)


# save()
