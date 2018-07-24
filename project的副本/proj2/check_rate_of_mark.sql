create or replace view semester_n 
AS
select id as semester_id, (substr(cast(year as varchar),3,2)||''||term)::char(4) as time from semesters 
;



create or replace view chengji1 
as
select c.id,s.name,s.code,se.time,ce.student,ce.mark from subjects s , courses c , course_enrolments ce , semester_n se 
where c.subject=s.id and c.semester=se.semester_id and ce.course=c.id;

create or replace view HD
as
select id, count(mark)::integer as HD from chengji1 where mark is not null and mark >=85 group by id
;
create or replace view D
as
select id, count(mark)::integer as D from chengji1 where mark is not null and mark <85 and mark>=75 group by id
;
create or replace view C
as
select id, count(mark)::integer as C from chengji1 where mark is not null and mark <75 and mark>=65 group by id
;
create or replace view pass
as
select id, count(mark)::integer as pass from chengji1 where mark is not null and mark <65 and mark>=50 group by id
;
create or replace view Fail
as
select id, count(mark)::integer as Fail from chengji1 where mark<50 group by id
;
create or replace view total
as
select id, count(mark)::integer as total from chengji1 group by id
;

create or replace view chengji2
as
select distinct ch.id,ch.code::text,ch.name,cast(ch.time as text),
round(hd.HD::numeric/t.total::numeric,2) as hd,
round(d.D::numeric/t.total::numeric,2) as d,
round(c.C::numeric/t.total::numeric,2) as C,
round(p.pass::numeric/t.total::numeric,2) as Pass,
round(f.Fail::numeric/t.total::numeric,2) as Fail 
from HD hd,D d, C c, pass p, Fail f, total t, chengji1 ch 
where hd.id=d.id and d.id=c.id and c.id=p.id and p.id=f.id and t.id=f.id and t.id=ch.id
;
drop type if exists chengji cascade;
create type chengji as (code text,name text,time text,HD numeric,D numeric,C numeric,Pass numeric,Fail numeric);

create or replace function check_mark(text ,text)
returns setof chengji 
as $$
select code,name,time,HD,D,C,PASS,FAIL from chengji2 where code=$1 and time=$2;
$$ LANGUAGE sql
;