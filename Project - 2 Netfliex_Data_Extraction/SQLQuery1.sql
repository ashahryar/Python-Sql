select * from netflix_raw 
where show_id = 's5023';
 
 --handling foregin character--

-- remove duplicate : --
select show_id  , count(*)
from netflix_raw
group by show_id
having count (*)>1

select * from netflix_raw 
where concat(upper(title),type) in (
select concat(upper(title)  , type)
from netflix_raw
group by upper(title) , type
having count (*)>1
)
order by title

with cte as (
select * 
,ROW_NUMBER() over(partition by title , type order by show_id) as rn
from netflix_raw 
)
select show_id , type, title,cast (date_added as date) as date_added , release_year
,rating ,case when duration is null  then rating else duration end as  duration, description 
into netflix
from cte

select * from netflix


 --new table for listed_in director, country , cast :
         --director--
select show_id , trim(value) as director
into netflix_directors
from netflix_raw
cross apply string_split(director , ',')

select * from netflix_directors

--country--
select show_id , trim(value) as country
into netflix_country
from netflix_raw
cross apply string_split(country , ',')

--cast--
select show_id , trim(value) as cast
into netflix_cast
from netflix_raw
cross apply string_split(cast , ',')

-- listed_in --
select show_id , trim(value) as genre
into netflix_genre
from netflix_raw
cross apply string_split(listed_in , ',')
select * from netflix_genre

--populate mising values in country , duriation columns :
insert into netflix_country
select  show_id , m.country
from netflix_raw nr
inner join (
select director, country
from netflix_country nc
inner join netflix_directors nd on nc.show_id = nd.show_id
group by director, country
) m on	nr.director = m.director
where nr.country is null

select * from netflix_raw where director = 'Ahishor Solomon'

select director, country
from netflix_country nc
inner join netflix_directors nd on nc.show_id = nd.show_id
group by director, country

----------------

select * from netflix_raw where duration is null

-------------------------------------netflix data analysis---------------------------------------

/* 1. for each director count the no of movies and tv shows create by them in sepreate columns
for directors who have created tv shows and movies both  */

select nd.director 
, count(distinct case when n.type='Movie' then n.show_id end )as no_of_movies
, count(distinct case when n.type='Tv Show' then n.show_id end )as no_of_tvshow
from netflix n
inner join netflix_directors nd on n.show_id = nd.show_id
group by nd.director
having count(distinct n.type) >1

/*  2. Which country have highest number of comedy movies  */

select  top 1 nc.country , COUNT(distinct ng.show_id ) as no_of_movies
from netflix_genre ng
inner join netflix_country nc on ng.show_id=nc.show_id
inner join netflix n on ng.show_id=nc.show_id
where ng.genre='Comedies' and n.type='Movie'
group by  nc.country
order by no_of_movies desc

/* 3. For each year(as per date added to netflix), which director has maximum number of movies released   */
	with cte as (
	select nd.director, year(date_added) as date_year,  count( n.show_id )as no_of_movies
	from netflix n
	inner join netflix_directors nd on n.show_id = nd.show_id
	where type = 'Movie'
	group by nd.director, year(date_added)
	)
	, cte2 as (
	select * 
	, ROW_NUMBER() over (partition by date_year order by no_of_movies  desc, director ) as rn
	from cte 
	--order by date_year , no_of_movies desc
	)
	select *from cte2 where rn = 1 

/* 4. what is the average duration of movies in each year  */
select ng.genre , avg(cast(REPLACE(duration, 'min', ' ')As int))as avg_duration
from netflix n
inner join netflix_genre ng on n.show_id = ng.show_id
where type = 'Movie'
group by ng.genre

/* 5. find the list of dirextor who has created horror and comedy movies both. Display director name
along with number of comedy and horror movies directed by them*/
select nd.director
, count(distinct case when ng.genre='Comedies' then n.show_id end) as no_of_comedy 
, count(distinct case when ng.genre='Horror Movies' then n.show_id end) as no_of_horror
from netflix n
inner join netflix_genre ng on n.show_id=ng.show_id
inner join netflix_directors nd on n.show_id=nd.show_id
where type='Movie' and ng.genre in ('Comedies','Horror Movies')
group by nd.director
having COUNT(distinct ng.genre)=2;

select * from netflix_genre where show_id in 
(select show_id from netflix_directors where director='Steve Brill')
order by genre