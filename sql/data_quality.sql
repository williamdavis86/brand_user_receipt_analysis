
-- check for null brand codes 
-- important for joining brands to receipts 
select *
from brands.tb_brands 
where trim(coalesce(brandcode,'')) = '';


-- many brand codes in tri that are not in tb 
-- why are we seeing brand codes in the receipt items that we do not have in the brand data?
select tri.brandcode, tb.brandcode, * from receipts.tb_receipt_items tri 
left join 
brands.tb_brands tb on tb.brandcode = tri.brandcode 
where tri.brandcode is not null and tb.brandcode is null;

-- many receipts missing brand code in receipt items 
-- if using brandcode for joining, we will lose these records when joining to brands 
select *
from receipts.tb_receipt_items 
where coalesce(brandcode, '') = ''


-- there are some user ids in the receipts table which do not appear in the users table 
select *
from receipts.tb_receipts r 
left join 
users.tb_users u on r.userid = u._id
where u._id is null


-- some user IDs have duplicate records in users table (note this in email) (data quality)
with duped_userids as (
select 
_id, count(*) 
from users.tb_users
group by _id 
having count(*) > 1 
) 
select * from users.tb_users u 
inner join 
duped_userids d using (_id)
order by _id


-- check for brands that have duped brandcodes -- include in email  (data quality)
select brandcode, count(*) from brands.tb_brands 
group by brandcode 
having count(*) > 1 

-- receipts reflecting 0 total spend 
-- this may or may not be a data issue
select * from receipts.tb_receipts 
where totalspent = 0 