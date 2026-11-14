--Q1.Yalniz ugurlu sifarisler.

select 
o.order_id,
c.customer_unique_id,
o.order_purchase_timestamp,
o.order_status
from customers c
inner join orders o on c.customer_id=o.customer_id
where order_status='delivered'

--Q2.Her musterinin ilk alis etdiyi ay.

--yalniz catdirilan sifarislerle islemek ucun bu cteni yaradiriq.
with delivered_order as (
select 
o.order_id,
c.customer_unique_id,
o.order_purchase_timestamp,
o.order_status
from customers c
inner join orders o on c.customer_id=o.customer_id
where order_status='delivered'
)
--hemin cteden istifade ederek ilk alis vaxtini tapiriq.
select 
customer_unique_id,
date_trunc('month' , min(order_purchase_timestamp)) as "cohort_month"
from delivered_order
group by customer_unique_id
order by cohort_month ;

--Q3.Musteri hansi ayda sifaris verir.
with delivered_order as (
select 
o.order_id,
c.customer_unique_id,
o.order_purchase_timestamp,
o.order_status
from customers c
inner join orders o on c.customer_id=o.customer_id
where order_status='delivered'
)
--eyni qaydada cte sorgusu vasitesile sifarislerin hansi aylarda oldugunada baxiriq.
select 
customer_unique_id,
order_id,
date_trunc('month',order_purchase_timestamp) as "order_month"
from delivered_order

--Q4.Novbeti sifarislerle ilk sifaris arasindaki ay fergi.
with delivered_order as (
select 
c.customer_unique_id,
o.order_purchase_timestamp
from customers c 
inner join orders o on c.customer_id=o.customer_id
where order_status='delivered'
--birinci catdirilan sifarisleri secirik , sonra bu cte vasitesile ilk sifarisi ve novbeti sifarisleri aliriq.
),
cohort_monthh as (
select 
customer_unique_id,
date_trunc('month', min(order_purchase_timestamp)) as "cohort_month"
from delivered_order
group by customer_unique_id
),
order_monthh as (
select 
customer_unique_id,
date_trunc('month',order_purchase_timestamp) as "order_month"
from delivered_order
)
--yekunde bu cteleri join ederek onlarin arasindaki ay fergini tapirig.
select 
c.customer_unique_id,
c.cohort_month,
o.order_month,
(extract(year from o.order_month)-extract(year from c.cohort_month))*12 + 
(extract(month from o.order_month)-extract(month from c.cohort_month)) as "between_month"
from cohort_monthh c 
inner join order_monthh o on c.customer_unique_id=o.customer_unique_id

--Q5.Her cohort uzre unikal musterilerin sayinin tapilmasi.
with delivered_order as (
select 
c.customer_unique_id,
o.order_purchase_timestamp
from customers c 
inner join orders o on c.customer_id=o.customer_id
where order_status='delivered'
),
cohort_monthh as (
select 
customer_unique_id,
date_trunc('month', min(order_purchase_timestamp)) as "cohort_month"
from delivered_order
group by customer_unique_id
),
order_monthh as (
select 
customer_unique_id,
date_trunc('month',order_purchase_timestamp) as "order_month"
from delivered_order
)
--bu sorguda ilk ayda ve sonraki aylarin her birinde musterilerin sayinin nece deyismesine baxirig.
--between_month'un sifir qiymeti ilk ayi bildirir.
--artiq between_monthu 1 qiymetinin qarsisinda , novbeti ayda ilk aydan nece musteri tekrar gelib , ona baxa bilirik.
select 
c.cohort_month,
(extract(year from o.order_month)-extract(year from c.cohort_month))*12 + 
(extract(month from o.order_month)-extract(month from c.cohort_month)) as "between_month",
count(distinct c.customer_unique_id) as "count_customer"
from cohort_monthh c 
inner join order_monthh o on c.customer_unique_id=o.customer_unique_id 
group by cohort_month,order_month
order by cohort_month;

--Q6.Her cohort uzre ilk aydaki musteri sayi.
with delivered_order as (
select 
c.customer_unique_id,
o.order_purchase_timestamp
from customers c 
inner join orders o on c.customer_id=o.customer_id
where order_status='delivered'
),
cohort_monthh as (
select 
customer_unique_id,
date_trunc('month', min(order_purchase_timestamp)) as "cohort_month"
from delivered_order
group by customer_unique_id
),
order_monthh as (
select 
customer_unique_id,
date_trunc('month',order_purchase_timestamp) as "order_month"
from delivered_order
)
-- burda between_month'a 0 filtiri vermekle yalniz ilk ayin deyerini(unikal musteri sayisini) aliriq.
select 
c.cohort_month,
count(distinct c.customer_unique_id) as "cohort_size"
from cohort_monthh c 
inner join order_monthh o on c.customer_unique_id=o.customer_unique_id
where (extract(year from o.order_month)-extract(year from c.cohort_month))*12 + 
(extract(month from o.order_month)-extract(month from c.cohort_month))=0
group by cohort_month
order by cohort_month;

--Q7 Her cohort ayi uzre rating.
with delivered_order as (
select 
c.customer_unique_id,
o.order_purchase_timestamp
from customers c 
inner join orders o on c.customer_id=o.customer_id
where order_status='delivered'
),
cohort_monthh as (
select 
customer_unique_id,
date_trunc('month', min(order_purchase_timestamp)) as cohort_month
from delivered_order
group by customer_unique_id
),
order_monthh as (
select 
customer_unique_id,
date_trunc('month',order_purchase_timestamp) as order_month
from delivered_order
),
--rating faizi tapmaq ucun cohort_size ala bileceyimiz bir cte sorgusu yaradiriq.
cohort_sizee as (
select
cohort_month,
count(distinct customer_unique_id) as cohort_size
from cohort_monthh
group by cohort_month
), 
--daha sonra rating hesabladigimiz bir cte sorgusu yazirig
matrix as (
select 
c.cohort_month,
(extract(year from o.order_month)-extract(year from c.cohort_month))*12 + 
(extract(month from o.order_month)-extract(month from c.cohort_month)) as between_month,
count(distinct c.customer_unique_id) as count_customer,
s.cohort_size,
round((count(distinct c.customer_unique_id)*100.0/s.cohort_size),2) as rating
from cohort_monthh c 
inner join order_monthh o on c.customer_unique_id=o.customer_unique_id
inner join cohort_sizee s on c.cohort_month=s.cohort_month
group by c.cohort_month,o.order_month,s.cohort_size
order by c.cohort_month,between_month
)
--ve bu sorgudan istifade ederek her bir ayin ratingini qruplasdiririq,
select 
cohort_month,
max(case when between_month=0 then rating end) as month_0,
max(case when between_month=1 then rating end) as month_1,
max(case when between_month=2 then rating end) as month_2,
max(case when between_month=3 then rating end) as month_3,
max(case when between_month=4 then rating end) as month_4,
max(case when between_month=5 then rating end) as month_5
--case when vasitesile aylarin her birini yeni sutuna menimsedirik.
from matrix 
group by cohort_month
order by cohort_month
--Q8.Her between_month ucun ortalama rating.
with delivered_order as (
select 
c.customer_unique_id,
o.order_purchase_timestamp
from customers c 
inner join orders o on c.customer_id=o.customer_id
where order_status='delivered'
),
cohort_monthh as (
select 
customer_unique_id,
date_trunc('month', min(order_purchase_timestamp)) as cohort_month
from delivered_order
group by customer_unique_id
),
order_monthh as (
select 
customer_unique_id,
date_trunc('month',order_purchase_timestamp) as order_month
from delivered_order
),
cohort_sizee as (
select
c.cohort_month,
count(distinct c.customer_unique_id) as cohort_size
from cohort_monthh c 
inner join order_monthh o on c.customer_unique_id=o.customer_unique_id
where (extract(year from o.order_month)-extract(year from c.cohort_month))*12 + 
(extract(month from o.order_month)-extract(month from c.cohort_month))=0
group by c.cohort_month
),
for_rating as (
select 
c.cohort_month,
(extract(year from o.order_month)-extract(year from c.cohort_month))*12 + 
(extract(month from o.order_month)-extract(month from c.cohort_month)) as between_month,
count(distinct c.customer_unique_id) as count_customer,
s.cohort_size,
round((count(distinct c.customer_unique_id)*100.0/s.cohort_size),2) as rating
from cohort_monthh c 
inner join order_monthh o on c.customer_unique_id=o.customer_unique_id
inner join cohort_sizee s on c.cohort_month=s.cohort_month
group by c.cohort_month,o.order_month,s.cohort_size
order by c.cohort_month,between_month
)
select 
between_month,
round(avg(rating),2) as avg_rating
from for_rating 
group by between_month
order by between_month

--Q9.Ilk ay ucun en ugurlu ve en ugursuz cohortlar.
with delivered_order as (
select 
c.customer_unique_id,
o.order_purchase_timestamp
from customers c 
inner join orders o on c.customer_id=o.customer_id
where order_status='delivered'
),
cohort_monthh as (
select 
customer_unique_id,
date_trunc('month', min(order_purchase_timestamp)) as cohort_month
from delivered_order
group by customer_unique_id
),
order_monthh as (
select 
customer_unique_id,
date_trunc('month',order_purchase_timestamp) as order_month
from delivered_order
),
cohort_sizee as (
select
c.cohort_month,
count(distinct c.customer_unique_id) as cohort_size
from cohort_monthh c 
inner join order_monthh o on c.customer_unique_id=o.customer_unique_id
where (extract(year from o.order_month)-extract(year from c.cohort_month))*12 + 
(extract(month from o.order_month)-extract(month from c.cohort_month))=0
group by c.cohort_month
),
max_min_rating as (
select 
c.cohort_month,
(extract(year from o.order_month)-extract(year from c.cohort_month))*12 + 
(extract(month from o.order_month)-extract(month from c.cohort_month)) as between_month,
round((count(distinct c.customer_unique_id)*100.0/s.cohort_size),2) as rating
from cohort_monthh c 
inner join order_monthh o on c.customer_unique_id=o.customer_unique_id
inner join cohort_sizee s on c.cohort_month=s.cohort_month
group by c.cohort_month,o.order_month,s.cohort_size
order by c.cohort_month,between_month
)
select 
cohort_month,
rating,
--alt sorgunun neticesine esasen yalniz 1 rankina beraber olan max ve ya min aliriq.
case 
when max=1 then 'Max'
when min=1 then 'Min'
end as status 
--statusla yeni sutun yaradib qarsisina max ve ya min yaziriq.
from (
select 
cohort_month,
rating,
--rank funksiyasi ile desc-de en yuxaridaki hisse(1) maksimum , ascde ise minumum olur deye bize yalniz 1 deyeri lazimdir.
rank() over(order by rating desc) as "max",
rank() over(order by rating asc) as "min"
from max_min_rating
where between_month=1
--yalniz novbeti ilk ay ucun
) finally 
--alias
where max=1 or min=1;

--Q10.Her cohort ve between_month ucun total_revenue
with delivered_order as (
select 
c.customer_unique_id,
o.order_id,
o.order_purchase_timestamp
from customers c 
inner join orders o on c.customer_id=o.customer_id
where order_status='delivered'
),
cohort_monthh as (
select 
customer_unique_id,
date_trunc('month', min(order_purchase_timestamp)) as cohort_month
from delivered_order
group by customer_unique_id
),
order_monthh as (
select 
customer_unique_id,
order_id,
date_trunc('month',order_purchase_timestamp) as order_month
from delivered_order
),
--yeni cedvelden qiymetleri almaq ucun cte sorgusu yaziriq.
order_item as (
select
order_id,
sum(price) as total_revenue
from order_items
group by order_id
--order id ucun cemini qruplasdiririq.
)
select 
c.cohort_month,
(extract(year from o.order_month)-extract(year from c.cohort_month))*12 + 
(extract(month from o.order_month)-extract(month from c.cohort_month)) as between_month,
--bu defe cohort_month ve between_month ucun cemini qruplasdiririq.
sum(i.total_revenue) as Total_revenue
from cohort_monthh c 
inner join order_monthh o on c.customer_unique_id=o.customer_unique_id
inner join order_item i on o.order_id=i.order_id
group by c.cohort_month , between_month

--Bonus feature'lar
--Her between_month ucun matrix qurub musteri sayina baxmaq.
with delivered_order as (
select 
c.customer_unique_id,
o.order_purchase_timestamp
from customers c 
inner join orders o on c.customer_id=o.customer_id
where order_status='delivered'
),
cohort_monthh as (
select 
customer_unique_id,
date_trunc('month', min(order_purchase_timestamp)) as "cohort_month"
from delivered_order
group by customer_unique_id
),
order_monthh as (
select 
customer_unique_id,
date_trunc('month',order_purchase_timestamp) as "order_month"
from delivered_order
),
count_matrix as (
select 
c.cohort_month,
(extract(year from o.order_month)-extract(year from c.cohort_month))*12 + 
(extract(month from o.order_month)-extract(month from c.cohort_month)) as "between_month",
count(distinct c.customer_unique_id) as "count_customer"
from cohort_monthh c 
inner join order_monthh o on c.customer_unique_id=o.customer_unique_id 
group by cohort_month,order_month
order by cohort_month
)
select 
cohort_month,
sum(case when between_month=0 then count_customer end) as month_0,
sum(case when between_month=1 then count_customer end) as month_1,
sum(case when between_month=2 then count_customer end) as month_2
from count_matrix
group by cohort_month

--Her novbeti ay ucun yeni sutunda total_revenue'ya baxilmasi.
with delivered_order as (
select 
c.customer_unique_id,
o.order_id,
o.order_purchase_timestamp
from customers c 
inner join orders o on c.customer_id=o.customer_id
where order_status='delivered'
),
cohort_monthh as (
select 
customer_unique_id,
date_trunc('month', min(order_purchase_timestamp)) as cohort_month
from delivered_order
group by customer_unique_id
),
order_monthh as (
select 
customer_unique_id,
order_id,
date_trunc('month',order_purchase_timestamp) as order_month
from delivered_order
),
order_item as (
select
order_id,
sum(price) as total_revenue
from order_items
group by order_id
),
revenue_matrix as (
select 
c.cohort_month,
(extract(year from o.order_month)-extract(year from c.cohort_month))*12 + 
(extract(month from o.order_month)-extract(month from c.cohort_month)) as between_month,
sum(i.total_revenue) as Total_revenue
from cohort_monthh c 
inner join order_monthh o on c.customer_unique_id=o.customer_unique_id
inner join order_item i on o.order_id=i.order_id
group by c.cohort_month , between_month
)
select
cohort_month,
sum(case when between_month=0 then total_revenue end ) as month_0,
sum(case when between_month=1 then total_revenue end ) as month_1,
sum(case when between_month=2 then total_revenue end ) as month_2,
sum(case when between_month=3 then total_revenue end ) as month_3,
sum(case when between_month=4 then total_revenue end ) as month_4
from revenue_matrix
group by cohort_month

--customer state'e esasen ratingler.
with delivered_order as (
select 
c.customer_unique_id,
--customer state elave edirikki cte sorgusundan istifade edende sutunu tapa bilsin.
c.customer_state,
o.order_purchase_timestamp
from customers c 
inner join orders o on c.customer_id=o.customer_id
where order_status='delivered'
),
cohort_monthh as (
select 
customer_unique_id,
customer_state,
date_trunc('month', min(order_purchase_timestamp)) as cohort_month
from delivered_order
group by customer_unique_id,customer_state
),
order_monthh as (
select 
customer_unique_id,
customer_state,
date_trunc('month',order_purchase_timestamp) as order_month
from delivered_order
),
cohort_sizee as (
select
customer_state,
cohort_month,
count(distinct customer_unique_id) as cohort_size
from cohort_monthh 
group by customer_state,cohort_month
)
select 
c.customer_state,
c.cohort_month,
(extract(year from o.order_month)-extract(year from c.cohort_month))*12 + 
(extract(month from o.order_month)-extract(month from c.cohort_month)) as between_month,
round((count(distinct c.customer_unique_id)*100.0/s.cohort_size),2) as rating
from cohort_monthh c 
inner join order_monthh o on c.customer_unique_id=o.customer_unique_id
inner join cohort_sizee s on c.cohort_month=s.cohort_month and c.customer_state=s.customer_state
group by c.customer_state,c.cohort_month,o.order_month,s.cohort_size

--her aktiv ay uzre kumulativ cemin hesablanmasi.
with delivered_order as (
select 
c.customer_unique_id,
o.order_id,
o.order_purchase_timestamp
from customers c 
inner join orders o on c.customer_id=o.customer_id
where order_status='delivered'
),
cohort_monthh as (
select 
customer_unique_id,
date_trunc('month', min(order_purchase_timestamp)) as cohort_month
from delivered_order
group by customer_unique_id
),
order_monthh as (
select 
customer_unique_id,
order_id,
date_trunc('month',order_purchase_timestamp) as order_month
from delivered_order
),
order_item as (
select
order_id,
sum(price) as total_revenue
from order_items
group by order_id
), 
data as (
select 
c.cohort_month,
(extract(year from o.order_month)-extract(year from c.cohort_month))*12 + 
(extract(month from o.order_month)-extract(month from c.cohort_month)) as between_month,
sum(i.total_revenue) as Total_revenue
from cohort_monthh c 
inner join order_monthh o on c.customer_unique_id=o.customer_unique_id
inner join order_item i on o.order_id=i.order_id
group by c.cohort_month , between_month
)
select 
cohort_month,
between_month,
Total_revenue,
--kumulyativ cem ucun over istifade edirik.
--her cohort ayi ucun , order by vasitesile her yeni tarixde total_revenue uzerine elave olunur.
sum(Total_revenue) over(partition by cohort_month order by between_month) as cumulative_sum
from data
where between_month between 0 and 6
--ilk 6 period ucun
order by cohort_month,between_month