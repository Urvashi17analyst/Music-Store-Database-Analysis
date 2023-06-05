-- Who is the senior most employee based on job title?

select * from employee
order by levels desc
limit 1;

-- Which Countries have the most invoices?

select billing_country,count(*) Invoices from invoice
group by billing_country
order by Invoices desc;

-- What are top 3 values of total invoices?

select * from invoice
order by total desc
limit 3;

-- Which city has the best customers to promote music festival? we would like to throw a promotional Music festival 
-- in the city we made the most money. write the query that returns one citythat has the highest sum of invoices totals
-- return both the city name and sum of all invoice totals.


select billing_city,sum(total) total_invoices
from invoice
group by billing_city
order by total_invoices desc;

-- who is the best customer? The customer who has spent the most money will be declared the best customer. write a 
-- querythat returns the person who has spent the most money?

select cust.first_name, cust.customer_id, round(sum(invoi.total)) as invoices
from customer as cust
join invoice as invoi
on cust.customer_id = invoi.customer_id
group by cust.customer_id
order by invoices desc
limit 1;

-- Write a query to returnthe email, first name, last name & genre of all Rock music listener.
-- Return your list orders alphabatically in ascending order

select distinct cust.email,cust.first_name, cust.last_name
from customer as cust
join invoice
on cust.customer_id = invoice.customer_id
join invoice_line
on invoice.invoice_id = invoice_line.invoice_id
where track_id in(
select track_id
from track
join genre
on track.genre_id = genre.genre_id
where genre.name like 'Rock'
)
order by email; 

-- Let's invite the artist who have written the most rock music in our dataset.
-- write a query that returns the artist name and total track count of the top 10 Rock bands 

--Method 1

select artist.name, count(track.track_id)
from artist
join album on artist.artist_id = album.artist_id
join track on album.album_id = track.album_id
where track_id in(
select track_id
from track
join genre
on track.genre_id = genre.genre_id
where genre.name like 'Rock')
group by  artist.name
order by count(track.track_id) desc
limit 10;

--Method 2

select artist.name, count(track.track_id) as number_of_songs
from artist
join album on artist.artist_id = album.artist_id
join track on album.album_id = track.album_id
join genre on track.genre_id = genre.genre_id
where genre.name = 'Rock'
group by  artist.artist_id
order by number_of_songs  desc
limit 10;

-- Return all the track names that have a song length longer than the average song length.
-- Return the name  and milliseconds for each track.
--Order by the song lengthwith the longest songs listed first.

select name, milliseconds
from track
where milliseconds >
( 
	select avg(milliseconds) as avg_length 
	from track
)
order by milliseconds desc;

-- Find how much amount spent by each customer on artists? write  a query to return customer name, artist name 
-- and total amount spent.

with best_selling_artist as
(
	select artist.artist_id,artist.name as artist_name, sum(il.unit_price*il.quantity) as Total_sales
	from invoice_line as il
	join track on track.track_id = il.track_id
	join album on album.album_id = track.album_id
	join artist on artist.artist_id = album.album_id
	group by 1
	order by 3 desc
	limit 1
)
select cust.customer_id,cust.first_name,cust.last_name, bsa.artist_name, sum(invoice_line.unit_price*invoice_line.quantity) as amount_spent
from customer cust
join invoice on invoice.customer_id = cust.customer_id
join invoice_line on invoice_line.invoice_id = invoice.invoice_id
join track on track.track_id = invoice_line.track_id
join album on album.album_id = track.album_id
join best_selling_artist bsa on bsa.artist_id = album.artist_id
group by 1,2,3,4
order by 5 desc;

-- we want to find out the most popular music genre for each country. we determine the most popular genre as the highest 
-- amount of purchases. write a query that returns each country along with the top genre. For countries where the maximum number 
-- of purchases is shared return all genre.

with popular_genre as 
(
	select customer.country, count(invoice_line.quantity) as purchases, genre.genre_id,genre.name,
	row_number() over(partition by customer.country 
					  order by count(invoice_line.quantity) desc) as Row_no 
	from customer
	join invoice on customer.customer_id = invoice.customer_id
	join invoice_line on invoice_line.invoice_id = invoice.invoice_id
	join track on track.track_id = invoice_line.track_id
	join genre on genre.genre_id = track.genre_id
	group by 1,3,4
	order by 1 asc,2 desc
)
select * from popular_genre 
where Row_no <=1;


--2nd method

with recursive sales_per_country as(
	select count(*) as purchases_per_genre, genre.genre_id,genre.name,customer.country
	from customer
	join invoice on customer.customer_id = invoice.customer_id
	join invoice_line on invoice_line.invoice_id = invoice.invoice_id
	join track on track.track_id = invoice_line.track_id
	join genre on genre.genre_id = track.genre_id
	group by 4,2,3
	order by 4,1 desc
),
	max_genre_per_country as (select max(purchases_per_genre) as max_genre_number, country
							  from sales_per_country
							  group by 2
							  order by 2)
select sales_per_country.*
from sales_per_country
join max_genre_per_country on sales_per_country.country = max_genre_per_country.country
where sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;


--Write a query that determines the customer that has spent the most on music for each country. 
-- write a query that returns the country along with the top customer and how much they spent.
--The countries where the top amount spent is shared, provide all customers who spent this amount.

with recursive customer_with_country as(
	select customer.customer_id, first_name, last_name, billing_country, sum(total) as total_spending
	from customer
	join invoice on customer.customer_id = invoice.customer_id
	group by 1,2,3,4
	order by 1,5 desc),
	country_max_spending as (select max(total_spending) as max_spending,billing_country
	from customer_with_country
	group by billing_country)
select cc.first_name, cc.last_name, cc.billing_country, cc.total_spending, ms.max_spending
from country_max_spending as ms 
join customer_with_country as cc 
on cc.billing_country = ms.billing_country
where cc.total_spending = ms.max_spending
order by 3;


							