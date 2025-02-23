import json
import csv
from datetime import datetime

def convert_date(mongo_date_obj):
    try:
        # Convert from milliseconds to seconds, then format as YYYY-MM-DD
        return datetime.utcfromtimestamp(mongo_date_obj["$date"] / 1000).strftime('%Y-%m-%d')
    except (TypeError, KeyError):
        return None

input_file = 'fetch_data/receipts.json'          # original file
output_file = 'clean_json/receipts_clean.csv'     # Output CSV file

# Define CSV header with column names 
header = [
    "_id", 
    "bonuspointsearned", 
    "bonuspointsearnedreason", 
    "createdate", 
    "datescanned", 
    "finisheddate", 
    "modifydate", 
    "pointsawardeddate", 
    "pointsearned",
    "purchasedate", 
    "purchaseditemcount", 
    "rewardsreceiptitemlist", 
    "rewardsreceiptstatus", 
    "totalspent", 
    "userid"
]

with open(input_file, 'r') as infile, open(output_file, 'w', newline='') as outfile:
    writer = csv.writer(outfile)
    writer.writerow(header)
    
    for line in infile:
        data = json.loads(line)
        row = [
            data["_id"]["$oid"],
            data.get("bonusPointsEarned"),
            data.get("bonusPointsEarnedReason"),
            convert_date(data.get("createDate")) if data.get("createDate") else None,
            convert_date(data.get("dateScanned")) if data.get("dateScanned") else None,
            convert_date(data.get("finishedDate")) if data.get("finishedDate") else None,
            convert_date(data.get("modifyDate")) if data.get("modifyDate") else None,
            convert_date(data.get("pointsAwardedDate")) if data.get("pointsAwardedDate") else None,
            data.get("pointsEarned"),
            convert_date(data.get("purchaseDate")) if data.get("purchaseDate") else None,
            data.get("purchasedItemCount"),
            json.dumps(data.get("rewardsReceiptItemList")),  # json column 
            data.get("rewardsReceiptStatus"),
            data.get("totalSpent"),
            data.get("userId")
        ]
        writer.writerow(row)

print("Conversion complete. CSV saved to", output_file)
