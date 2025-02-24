# brand_user_receipt_analysis
This is a project that utilizes Python and PostgreSQL to analyze sample customer, receipt, and brand data. 

# Requirements
To run the files in this repository, you will need access to both Python and PostgreSQL. The code was written in Python 3.11.11 and PostgreSQL 17.

# Files
Before running the code, you may want to familiarize yourself with the entity relationship diagram (ERD.png). This is how the tables will be set up after you run the Python and SQL. 

The raw data is housed in the fetch_data folder.

Before running the SQL, you will need to run the Python code to get the data into a format better suited for loading into Postgres. The python code (clean_receipts.py, clean_brands.py, clean_users.py) is housed in the clean_json folder. I have also inlcuded the resulting CSV files which would be the output of running the Python scripts. The three scripts could be run in any order to get the resulting CSV files. 

Then, you can run the SQL code housed in the sql folder. First, you would run questions.sql where you set up the schemas, tables, and run the queries to answer the specified question. You will need to replace '[PATH]' in the copy statements with the path your csv files are housed in. 

Once your tables are populated you can run the queries to answer the specified questions as well as the data quality check queries which are housed in data_quality.sql. 

An example email to leadership is under mock_email.pdf.
