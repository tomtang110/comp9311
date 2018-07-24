

create or replace view AllRatings(taster,beer,brewer,rating)
as
	select t.given as taster, b.name,bre.name,r.score as rating
	from taster t, brewer bre, beer b, ratings r 
	where t.id = r.taster and bre.id = b.brewer and r.beer = b.id
	order by taster, rating DESC
;


-- John's favourite beer

create or replace view JohnsFavouriteBeer(brewer,beer)
as
select brewer, beer from allratings 
where rating = 5 and taster like 'John' 
-- 	... replace this by your SQL query ...
;


-- -- X's favourite beer

create type BeerInfo as (brewer text, beer text);

create or replace function FavouriteBeer(text) returns setof BeerInfo
as $$
select brewer, beer from allratings 
where rating = (select max(rating) from AllRatings
where taster = $1) and taster = $1 
-- 	... replace this by your SQL query ...
$$ language sql
;


-- -- Beer style

create or replace function BeerStyle (brewer text, beer text) returns text
as $$
select bs.name from brewer bre, beer b, beerstyle bs 
where bre.id = b.brewer and b.style = bs.id 
and lower(bre.name) = lower($1) and lower(b.name) = lower($2)
-- 	... replace this by your SQL query ...
$$ language sql
;

-- create or replace function BeerStyle1(brewer text, beer text) returns text
-- as $$
-- begin
-- 	... replace this by your PLpgSQL code ...
-- end;
-- $$ language plpgsql
-- ;


-- -- Taster address

create or replace function TasterAddress(taster text) returns text
as $$
	select case 
		when loc.country is null then loc.STATE
		when loc.state is null then loc.country
		ELSE loc.state||', '||loc.country
		END
	from   Taster t, Location loc
	where  t.given = $1 and t.livesIn = loc.id

$$ language sql
;




create or replace FUNCTION 
beers_k(_beer text,_rating float,_taster text) returns text 
as $$
BEGIN
	return E'\n' ||
			'Beer:' ||' '|| _beer||E'\n'||
			'Rating' ||' '|| to_char(_rating,'9.9')||E'\n'||
			'Tasters' ||' '|| substring(_taster,3,length(_taster))||E'\n';
end;
$$ language plpgsql
;
-- -- BeerSummary function

create or replace function BeerSummary() returns text
as $$
declare
r record;
curbeer text := '';
out text := '';
tasters text := '';
count INTEGER;
sum INTEGER;
-- 	... replace this by your definitions ...
begin
for r in select * from allratings order by beer, taster 
loop
	if (r.beer != curbeer) THEN
		if (curbeer != '') then 
			OUT :=out || beers_k(curbeer,sum/count,tasters);
		end if ;
		curbeer := r.beer;
		sum := 0; count := 0 ;  tasters :='';
	end if ;
	sum := sum + r.rating;
	count := count + 1;
	tasters := tasters||', '||r.taster; 	
end loop;
OUT :=out || beers_k(curbeer,sum/count,tasters);
return OUT;
-- 	... replace this by your code ...
end;
$$ language plpgsql;




-- -- Concat aggregate
create or replace FUNCTION append_next(_state text, _next text)
returns text AS $$
BEGIN
return _state ||','|| _next;
end;
$$ LANGUAGE plpgsql;

CREATE or replace function finaltext(_final text) returns text as $$
BEGIN
RETURN substring(_final,2,length(_final));
end;
$$ LANGUAGE plpgsql;

create aggregate concat (text)
(
	stype     = text,
	initcond  =  '',
	sfunc     = append_next,
	finalfunc = finaltext
);


-- -- BeerSummary view

create or replace view BeerSummary(beer,rating,tasters)
as
select beer, to_char(avg(rating),'9.9'),concat(taster) as tasters from allratings 
group by beer
;


-- -- TastersByCountry view

-- create or replace view TastersByCountry(country,tasters)
-- as
-- 	... replace by SQL your query using concat() and Taster ...
-- ;
