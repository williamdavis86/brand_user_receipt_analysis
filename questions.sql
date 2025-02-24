-- create schemas 
CREATE SCHEMA brands AUTHORIZATION postgres;

CREATE SCHEMA receipts AUTHORIZATION postgres;

CREATE SCHEMA users AUTHORIZATION postgres;

-- create tables 
drop table if exists receipts.tb_receipts;
create table receipts.tb_receipts(
_id text, 
bonuspointsearned int ,
bonuspointsearnedreason text,
createdate date, 
datescanned date, 
finisheddate date, 
modifydate date, 
pointsawardeddate date, 
pointsearned numeric,
purchasedate date, 
purchaseditemcount int,
rewardsreceiptitemlist jsonb,
rewardsreceiptstatus text,
totalspent numeric,
userid text
);

drop table if exists users.tb_users;
create table users.tb_users(
_id text, 
active boolean, 
createddate date, 
lastlogin date, 
role text,
signupsource text, 
state text
);

drop table if exists brands.tb_brands;
create table brands.tb_brands(
_id text, 
barcode text,
brandcode text,
categorycode text,
topbrand boolean,
brandname text,
cpgid text
);

create table brands.tb_brandcategories(
categorycode text, 
category text 
);

drop table if exists brands.tb_cpg;
create table brands.tb_cpg(
_id text, 
ref text
);

-- fill tables with data 
-- REPLACE [PATH] with the your path housing the files from the python scripts

COPY receipts.tb_receipts(
    _id, 
    bonuspointsearned, 
    bonuspointsearnedreason, 
    createdate, 
    datescanned, 
    finisheddate, 
    modifydate, 
    pointsawardeddate, 
    pointsearned,
    purchasedate, 
    purchaseditemcount, 
    rewardsreceiptitemlist, 
    rewardsreceiptstatus, 
    totalspent, 
    userid
)
FROM '[PATH]'--'C:\Users\wdavi\Documents\receipts_clean.csv'
csv header;

-- select * from receipts.tb_Receipts

COPY users.tb_users
FROM '[PATH]' -- 'C:\Users\wdavi\Documents\users_clean.csv'
csv header;

-- select * from users.tb_users

copy brands.tb_brands 
from '[PATH]'--'C:\Users\wdavi\Documents\brands_clean.csv' 
csv header; 

-- select * from brands.tb_brands 

copy brands.tb_brandcategories 
from '[PATH]'-- 'C:\Users\wdavi\Documents\brandcategories_clean.csv' 
csv header;

-- select * from brands.tb_brandcategories

copy brands.tb_cpg 
from '[PATH]'-- 'C:\Users\wdavi\Documents\cpg_clean.csv' 
csv header; 


-- answering questions with queries 

-- decided to add a table dedicated to receipt items for easier analysis/reading of data 
drop table if exists receipts.tb_receipt_items;
create table receipts.tb_receipt_items as 
SELECT
  r._id AS receipt_id,
  item ->> 'barcode' AS barcode,
  (item ->> 'itemPrice')::numeric AS item_price,
  (item ->> 'finalPrice')::numeric AS final_price,
  item ->> 'description' AS description,
  item ->> 'partnerItemId' AS partner_item_id,
  (item ->> 'needsFetchReview')::boolean AS needs_fetch_review,
  (item ->> 'userFlaggedPrice')::numeric AS user_flagged_price,
  (item ->> 'quantityPurchased')::int AS quantity_purchased,
  item ->> 'userFlaggedBarcode' AS user_flagged_barcode,
  (item ->> 'userFlaggedNewItem')::boolean AS user_flagged_new_item,
  (item ->> 'userFlaggedQuantity')::int AS user_flagged_quantity,
  (item ->> 'preventTargetGapPoints')::boolean AS prevent_target_gap_points,
  (item ->> 'rewardsProductPartnerId')AS rewardsProductPartnerId, 
  (item ->> 'brandCode')AS brandcode
FROM receipts.tb_receipts AS r,
LATERAL jsonb_array_elements(
    CASE 
      WHEN jsonb_typeof(r.rewardsreceiptitemlist) = 'array'
        THEN r.rewardsreceiptitemlist
      ELSE jsonb_build_array(r.rewardsreceiptitemlist)
    END
) AS item

-- select * from receipts.tb_receipt_items

-- Which brand has the most spend among users who were created within the past 6 months?
with receipts as (
SELECT 
  _id, 
  datescanned,
  userid,
  totalspent
  FROM receipts.tb_receipts
ORDER BY datescanned DESC
),receipts_with_brandcode as (
select tri.brandcode, r.totalspent, r.userid 
from receipts r
inner join 
receipts.tb_receipt_items tri on r._id = tri.receipt_id
inner join 
brands.tb_brands tb on tb.brandcode = tri.brandcode -- receipts which have the brandcode in the receipt information (there are many missing)
),distinct_users_last_6_months as (
select distinct * from users.tb_users
WHERE createddate >= (
  SELECT max(createddate) - interval '6 months'
  FROM users.tb_users
)
)
select 
r.brandcode, sum(totalspent) ts 
from receipts_with_brandcode r 
inner join 
distinct_users_last_6_months u on r.userid  = u._id
group by r.brandcode 
order by ts desc 
limit 1 

-- Which brand has the most transactions among users who were created within the past 6 months?
with receipts as (
SELECT 
  _id, 
  datescanned,
  userid,
  totalspent
  FROM receipts.tb_receipts
ORDER BY datescanned DESC
),receipts_with_brandcode as (
select r._id, tri.brandcode, r.totalspent, r.userid 
from receipts r
inner join 
receipts.tb_receipt_items tri on r._id = tri.receipt_id
inner join 
brands.tb_brands tb on tb.brandcode = tri.brandcode -- receipts which have the brandcode in the receipt information (there are many missing)
),distinct_users_last_6_months as (
select distinct * from users.tb_users
WHERE createddate >= (
  SELECT max(createddate) - interval '6 months'
  FROM users.tb_users
)
)
select 
r.brandcode, count(distinct r._id) total_transactions -- defining a transaction as a single receipt (i.e. multiple branded products on a single receipt = 1 transaction for that brand)
from receipts_with_brandcode r 
inner join 
distinct_users_last_6_months u on r.userid  = u._id
group by r.brandcode 
order by total_transactions desc 
limit 1 

-- When considering total number of items purchased from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?

with receipts_and_items as (
select r._id, r.rewardsreceiptstatus
from receipts.tb_Receipts r
inner join 
receipts.tb_receipt_items tri on r._id = tri.receipt_id
where coalesce(tri.description, 'ITEM NOT FOUND') <> 'ITEM NOT FOUND' -- only considering items that we have the names of 
and (rewardsreceiptstatus = 'FINISHED' or rewardsreceiptstatus = 'REJECTED')
)
select 
rewardsreceiptstatus, count(_id) 
from receipts_and_items
group by rewardsreceiptstatus




