import json
import csv

input_file = 'fetch_data/brands.json'
brands_output = 'clean_json/brands_clean.csv'
categories_output = 'clean_json/brandcategories_clean.csv'
cpg_output = 'clean_json/cpg_clean.csv'

# Use dictionaries to help deduplicate categories and cpg records
categories = {}  # key: categorycode, value: category
cpgs = {}        # key: cpgid, value: ref

# Prepare the CSV for the brands table
with open(input_file, 'r') as infile, \
     open(brands_output, 'w', newline='') as b_out:
    
    brands_writer = csv.writer(b_out)
    # Define header for brands table
    brands_header = [
        "_id", 
        "barcode", 
        "brandcode", 
        "categorycode", 
        "topbrand", 
        "brandname", 
        "cpgid"
    ]
    brands_writer.writerow(brands_header)
    
    # Process each line (each JSON record) in brands.json
    for line in infile:
        data = json.loads(line)
        
        # Extract the fields for tb_brands
        brand_id = data["_id"]["$oid"]
        barcode = data.get("barcode")
        # Use "brandCode" if available; sometimes it might be missing
        brandcode = data.get("brandCode", "")
        categorycode = data.get("categoryCode", "")
        # For some records, "topBrand" might be missing (default to False)
        topbrand = data.get("topBrand", False)
        brandname = data.get("name")
        
        # Extract CPG info from the nested object if available
        cpg_data = data.get("cpg", {})
        cpgid = ""
        cpgref = ""
        if "$id" in cpg_data and isinstance(cpg_data["$id"], dict):
            cpgid = cpg_data["$id"].get("$oid", "")
        if "$ref" in cpg_data:
            cpgref = cpg_data["$ref"]
        
        # Write the brand row
        brands_writer.writerow([
            brand_id,
            barcode,
            brandcode,
            categorycode,
            topbrand,
            brandname,
            cpgid
        ])
        
        # Add to categories dictionary if we have category data
        # Here we assume the category is in the key "category"
        if categorycode:
            categories[categorycode] = data.get("category", "")
        
        # Add to cpg dictionary if we have a CPG id
        if cpgid:
            cpgs[cpgid] = cpgref

# Write the categories CSV (for tb_brandcategories)
with open(categories_output, 'w', newline='') as cat_out:
    cat_writer = csv.writer(cat_out)
    cat_header = ["categorycode", "category"]
    cat_writer.writerow(cat_header)
    
    for cat_code, cat_name in categories.items():
        cat_writer.writerow([cat_code, cat_name])

# Write the CPG CSV (for tb_cpg)
with open(cpg_output, 'w', newline='') as cpg_out:
    cpg_writer = csv.writer(cpg_out)
    cpg_header = ["_id", "ref"]
    cpg_writer.writerow(cpg_header)
    
    for cpg_id, cpg_ref in cpgs.items():
        cpg_writer.writerow([cpg_id, cpg_ref])

print("Conversion complete. CSVs saved to:")
print("Brands:", brands_output)
print("Categories:", categories_output)
print("CPG:", cpg_output)
