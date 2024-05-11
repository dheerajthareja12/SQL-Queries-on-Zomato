create database Zomato;
use Zomato;

#Table_No_1 - goldusers_signup
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup (userid, gold_signup_date) 
VALUES 
(1, STR_TO_DATE('09-22-2017', '%m-%d-%Y')),
(3, STR_TO_DATE('04-21-2017', '%m-%d-%Y'));


#Table_No_2 - users
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users (userid, signup_date) 
VALUES 
(1, STR_TO_DATE('09-02-2014', '%m-%d-%Y')),
(2, STR_TO_DATE('01-15-2015', '%m-%d-%Y')),
(3, STR_TO_DATE('04-11-2014', '%m-%d-%Y')); 
#this database doesn't recognize To_date 


#Table_no_3 - Sales
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales (userid, created_date, product_id) 
VALUES 
(1, STR_TO_DATE('04-19-2017', '%m-%d-%Y'), 2),
(3, STR_TO_DATE('12-18-2019', '%m-%d-%Y'), 1),
(2, STR_TO_DATE('07-20-2020', '%m-%d-%Y'), 3),
(1, STR_TO_DATE('10-23-2019', '%m-%d-%Y'), 2),
(1, STR_TO_DATE('03-19-2018', '%m-%d-%Y'), 3),
(3, STR_TO_DATE('12-20-2016', '%m-%d-%Y'), 2),
(1, STR_TO_DATE('11-09-2016', '%m-%d-%Y'), 1),
(1, STR_TO_DATE('05-20-2016', '%m-%d-%Y'), 3),
(2, STR_TO_DATE('09-24-2017', '%m-%d-%Y'), 1),
(1, STR_TO_DATE('03-11-2017', '%m-%d-%Y'), 2),
(1, STR_TO_DATE('03-11-2016', '%m-%d-%Y'), 1),
(3, STR_TO_DATE('11-10-2016', '%m-%d-%Y'), 1),
(3, STR_TO_DATE('12-07-2017', '%m-%d-%Y'), 2),
(3, STR_TO_DATE('12-15-2016', '%m-%d-%Y'), 2),
(2, STR_TO_DATE('11-08-2017', '%m-%d-%Y'), 2),
(2, STR_TO_DATE('09-10-2018', '%m-%d-%Y'), 3);


#Table_No_4 - product
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users; 

#Q.1 : What is the total amount each customer spent on Zomato?

select userid, sum(price) as total_price
from (select a.userid, a.product_id, b.price 
from sales as a 
inner join 
product as b 
on a.product_id = b.product_id) as joined_data
group by userid;

#or
select a.userid, sum(b.price) as total_price
from sales as a 
inner join 
product as b 
on a.product_id = b.product_id
group by a.userid;

#Q.2 : How many days has each customer visited Zomato? 

select userid, count(distinct created_date) as total_visits
from sales
group  by userid;

#Q.3 What was the first product purchased by each customer? 

select *
from (select *, rank() over (partition by userid order by created_date) as rank_date from sales) as Z
where rank_date = 1;

#Q.4: What is the most purcahsed item on the menu and how many times was it purchased by all customers?

select userid, count(product_id) as Countt
from sales 
where product_id =
(select product_id
from sales
group by product_id
order by count(product_id) DESC
limit 1)
group by userid;

#Q.5: Which Item is the most popular for each customer? 

select * 
from
(select *, rank() over (partition by userid order by x desc ) as rnk
from (select userid, product_id, count(product_id) as x
from sales
group by product_id, userid) as g) as j
where rnk = '1';

#Q.6: Which item was first purchased by customer after become the member?

select userid, product_id 
from
(select*, rank() over (partition by userid order by created_date) as rnk 
from 
(select a.userid, a.created_date, a.product_id, b.gold_signup_date 
from sales as a
inner join 
goldusers_signup as b
on a.userid=b.userid
and created_date >= gold_signup_date) as c) as d 
where rnk = 1;  

#Q.7: Which item was purcased just before the customer became member?

select userid, product_id, created_date, gold_signup_date 
from
(select *, rank() over (partition by userid order by created_date desc) as rnk
from
(select a.userid, a.created_date, a.product_id, b.gold_signup_date 
from sales as a
inner join 
goldusers_signup as b
on a.userid=b.userid
and created_date <= gold_signup_date) as c) as d
where rnk =1;

#Q.8: what is the total order and amount spent for each member before they become a member? 

select userid, count(product_id) num_of_order, sum(price) as total_amount
from
(select d.userid, d.product_id, c.price
from
(select a.userid, a.product_id, a.created_date, b.gold_signup_date 
from sales as a
inner join 
goldusers_signup as b
on a.userid = b.userid 
and created_date <= gold_signup_date) as d
inner join
product as c 
on d.product_id = c.product_id) as e
group by userid; 

#Q.9: If buying ech product offers rewards on products: p1: 5rs =1, p2: 10rs = 5, p3: 5rs =1. 
#Total pints collected by each customer and for which product, most points have been given till now.

select userid, sum(reward_points) as total_reward_points
from
(select *, (case
when product_name in ('p1', 'p3') then Total_spend/5
when product_name = 'p2' then Total_spend/2
end) as reward_points
from 
(select userid, product_name, sum(price) as Total_spend
from
(select a.userid, b.product_name, b.price
from sales as a
inner join 
product as b
on a.product_id=b.product_id) as c
group by userid, product_name) as d) as e
group by userid;

select product_name, sum(reward_points) as total_reward_points_product
from
(select *, (case
when product_name in ('p1', 'p3') then Total_spend/5
when product_name = 'p2' then Total_spend/2
end) as reward_points
from 
(select userid, product_name, sum(price) as Total_spend
from
(select a.userid, b.product_name, b.price
from sales as a
inner join 
product as b
on a.product_id=b.product_id) as c
group by userid, product_name) as d) as e
group by product_name
order by total_reward_points_product desc
limit 1;

#q.10: In the first one year after joining the God Membership, the customer get 5 reward points for every 10 rs. spent. What are the total earning of reward points and who earned more?

select c.userid, c.product_id, d.price, (d.price/2) as rewards
from
(select a.userid, a.created_date, a.product_id, b.gold_signup_date
from sales as a 
inner join
goldusers_signup as b
on a.userid = b.userid 
and a.created_date >= b.gold_signup_date
and a.created_date <= date_add(b.gold_signup_date, INTERVAL 1 YEAR)) as c
inner join
product as d
on c.product_id = d.product_id;

#Q.11: rank all transactions of the customers?

select a.*, b.price, rank() over (partition by userid order by price Desc) as rnk
from sales as a
inner join
product as b
on a.product_id = b.product_id;

#Q.12: Rank all the transaction whenever they are under goldmembership. Non-gold member transactions should be put as na

select c.*, d.price, case 
when c.gold_signup_date is null then 'na'
else rank() over (partition by userid order by d.price desc)
end as rnk
from
(select a.*, b.gold_signup_date
from sales as a
left join 
goldusers_signup as b
on a.userid = b.userid) as c
left join
product as d
on c.product_id = d.product_id
order by rnk;