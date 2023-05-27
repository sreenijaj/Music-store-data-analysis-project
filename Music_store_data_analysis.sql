/* Q1: Who is the senior most employee based on job title? */
select title,last_name,first_name
from employee 
order by levels desc limit 1;

/* Q2: Which countries have the most Invoices? */
select count(*) as c,billing_country
from invoice
group by billing_country
order by c desc;

/* Q3: What are top 3 values of total invoice? */
select total from invoice
order by total desc
limit 3;

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival 
in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

select sum(total) as invoice_total,billing_city
from invoice
group by billing_city
order by invoice_total desc
limit 1;

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/

select customer.customer_id,customer.first_name,customer.last_name,sum(total) as total_spending
from customer
join invoice on customer.customer_id=invoice.customer_id
group by customer.customer_id
order by total_spending desc
limit 1;

/* Question Set 2 - Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

select distinct email as EMAIL,first_name as FIRSTNAME,last_name as LASTNAME,genre.name as Name
from customer
join invoice on invoice.customer_id=customer.customer_id
join invoice_line on invoice_line.invoice_id=invoice.invoice_id
join track on track.track_id=invoice_line.track_id
join genre on genre.genre_id=track.genre_id
where genre.name like 'Rock'
order by email;

/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

select artist.artist_id,artist.name,Count(artist.artist_id)as number_of_songs
from track
join album on album.album_id=track.album_id
join artist on artist.artist_id=album.artist_id
join genre on genre.genre_id=track.genre_id
where genre.name like 'Rock'
group by artist.artist_id
order by number_of_songs desc
limit 10

/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

select name, milliseconds from track
where milliseconds >(
	select avg(milliseconds) as avg_track_length
	from track )
order by milliseconds desc;

/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: ind the artist who has made the most money according to the InvoiceLines first. Find out who paid the most for this artist by using this artist. You must use the Invoice, InvoiceLine, Track, Customer, Album, and Artist tables for this query. This one is challenging because the Total spent in the Invoice table might not be on a single product; therefore, you must use the InvoiceLine table to determine the quantity of each product purchased, multiply that number by the price for each artist, and then use the result as your answer. */

WITH selling_artist AS (
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name, 
	SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */

/* Method : Using CTE(common table expression) */

with popular_genre as
(
	select count(invoice_line.quantity) as purchases,customer.country,genre.name,genre.genre_id,
	Row_Number()over(partition by customer.country order by count(invoice_line.quantity)Desc)as RowNo
	from invoice_line
	join invoice on invoice.invoice_id=invoice_line.invoice_id
	join customer on customer.customer_id=invoice.customer_id
	join track on track.track_id=invoice_line.track_id
	join genre on genre.genre_id=track.genre_id
	group by 2,3,4
    order by 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1

/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */

/* Method : using CTE */

with topCustomer_from_country as(
	select customer.customer_id,first_name,last_name,billing_country,sum(total)as total_spending,
	Row_Number() over(partition by billing_country order by sum(total)desc) as RowNo
	from invoice
	join customer on customer.customer_id=invoice.customer_id
	group by 1,2,3,4
	order by 4 asc,5 desc
)
	
select * from topCustomer_from_country where RowNo <=1
	