
-- Q1: how many page accesses on March 2

-- ... replace this line by auxiliary views (or delete it) ...

create or replace view Q1(nacc) as
select count(*) from accesses 
where accTime >= '2005-03-02 00:00:00' and accTime < '2005-03-03 00:00:00';
-- ... replace this line by your SQL query ...



-- Q2: how many times was the MessageBoard search facility used?



create or replace view Q2(nsearches) as
select  count(*) from accesses
where page ~ '^messageboard' and params ~ 'state=search'
;


-- Q3: on which Tuba lab machines were there incomplete sessions?

-- ... replace this line by auxiliary views (or delete it) ...

create or replace view Q3(hostname) as
-- ... replace this line by your SQL query ...
select distinct h.hostname from hosts h, sessions s
where h.hostname like 'tuba%.orchestra.cse.unsw.edu.au' and h.id=s.host
and not s.complete
;


-- Q4: min,avg,max bytes transferred in page accesses



create or replace view Q4(min,avg,max) as
select min(nbytes),avg(nbytes)::integer,max(nbytes) from accesses 

;


-- Q5: number of sessions from CSE hosts
create or replace view CSEhost as 
select * from Hosts where hostname ~ 'cse.unsw.edu.au';

create or replace view Q5(nhosts) as
select count(*) from Sessions s , CSEhost c where s.host = c.id;



-- -- Q6: number of sessions from non-CSE hosts

create or replace view noncsehost AS
select * from hosts 
where hostname not like '%cse.unsw.edu.au';

create or replace view Q6(nhosts) as
select count(*) from sessions s, noncsehost nc
where s.host=nc.id
;


-- -- Q7: session id and number of accesses for the longest session?

create or replace view lg AS
select session, count(*) as len from accesses 
GROUP by session;

create or replace view Q7(session,length) as 
select * from lg where len = (select max(len) from lg)
;


-- -- Q8: frequency of page accesses


create or replace view Q8(page,freq) as
select page, count(*) from accesses 
group by page 
order by count(*) DESC

;


-- -- Q9: frequency of module accesses
CREATE or replace view FA as 
select session, seq, substring(page from '^[^/]+') as module
from accesses;


create or replace view Q9(module,freq) as
select module, count(*) as frequency from FA 
GROUP by module
ORDER by frequency desc

;


-- -- Q10: "sessions" which have no page accesses



create or replace view Q10(session) as
select id from sessions s
where not exists (select session from accesses a where s.id=a.session) 

;


