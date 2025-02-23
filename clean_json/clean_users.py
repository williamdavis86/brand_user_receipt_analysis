import json
import csv
from datetime import datetime

def convert_date(mongo_date_obj):
    """Expects a dict like {"$date": 1609687531000}"""
    try:
        timestamp_ms = mongo_date_obj["$date"]
        return datetime.utcfromtimestamp(timestamp_ms / 1000).strftime('%Y-%m-%d')
    except (TypeError, KeyError):
        return None

input_file = 'fetch_data/users.json'          # Your source JSON file
output_file = 'clean_json/users_clean.csv'     # Output CSV file

# Define CSV header matching your table columns
header = [
    "_id", 
    "active", 
    "createddate",   # Will store the converted "createdDate"
    "lastlogin",     # Will store the converted "lastLogin"
    "role", 
    "signupsource", 
    "state"
]

with open(input_file, 'r') as infile, open(output_file, 'w', newline='') as outfile:
    writer = csv.writer(outfile)
    writer.writerow(header)
    
    for line in infile:
        data = json.loads(line)

        user_id = data["_id"]["$oid"]
        active = data.get("active")
        # Convert the MongoDB date to YYYY-MM-DD
        created_date = convert_date(data.get("createdDate"))
        last_login = convert_date(data.get("lastLogin"))
        role = data.get("role")
        # Match the JSON key "signUpSource" but store it as "signupsource" in CSV
        signup_source = data.get("signUpSource")
        state = data.get("state")

        row = [
            user_id,
            active,
            created_date,
            last_login,
            role,
            signup_source,
            state
        ]
        writer.writerow(row)

print("Conversion complete. CSV saved to", output_file)
