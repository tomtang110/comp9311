--Q1:

drop type if exists RoomRecord cascade;
create type RoomRecord as (valid_room_number integer, bigger_room_number integer);

create or replace view ce_student 
as 
select ce.course as ce_course_id, count(*) as num1 from course_enrolments ce 
group by ce.course
;

create or replace view cew_student 
as 
select cew.course as cew_course_id, count(*) as num2 from Course_enrolment_waitlist cew 
group by cew.course
;

create or replace view combi
as
select ce.ce_course_id as id, ce.num1, 
case when cew.num2 is NULL then 0 else cew.num2 end 
from ce_student ce 
left join cew_student cew on ce.ce_course_id = cew. cew_course_id
;

create or replace function qq1(course_id integer)
returns RoomRecord
as $$
select C1.num1::integer, C2.num2::integer from (select c.id, count(*) as num1 from combi c, rooms r 
where r.capacity is not null and r.capacity >= c.num1::integer and c.id = $1
group by c.id) as C1,
(select c.id, count(*) as num2 from combi c, rooms r 
where r.capacity is not null and r.capacity >= c.num1::integer+c.num2::integer and c.id = $1
group by c.id) as C2 
where C1.id = C2.id
$$ language sql
;

create or replace function Q1(course_id integer)
    returns RoomRecord
as $$
declare 
check_id integer;
results RoomRecord;
BEGIN
select id into check_id from combi where id = $1;
if (not found) THEN
    raise exception 'INVALID COURSEID';
end if;
select * into results from qq1($1);
return results;
end;
$$ language plpgsql
;




--Q2:

drop type if exists TeachingRecord cascade;
create type TeachingRecord as (cid integer, term char(4), code char(8), name text, uoc integer, average_mark integer, highest_mark integer, median_mark integer, totalEnrols integer);


create or replace view median
as 
select course, round(avg(mark),2) as median from (select * from (select course,mark,
row_number() over (partition by course order by mark) as row_num,
count(1) over (partition by course) as total from course_enrolments where mark is not null) as o1
where row_num in ((total+1)/2,(total+2)/2)) as o2 group by course
;


create or replace view student_nb 
as
select course, count(*)::integer as student_nb from course_enrolments
where mark is not NULL group by course
;
 
create or replace view a_h_m 
as 
select ce.course, round(avg(ce.mark))::integer as average_mark,
round(max(ce.mark))::integer as highest_mark,
round(md.median)::integer as median_mark
from course_enrolments ce , median md 
where mark is not null and md.course =  ce.course
group by ce.course, md.median
;

create or replace view others 
as
select c.id, (substr(cast(year as varchar),3,2)||''||lower(sm.term))::char(4) as term,
 s.code ,s.name, s.uoc
from courses c, semesters sm, subjects s 
where c.subject = s.id and c.semester=sm.id  
;

create or replace view q2_all 
as
select cs.staff,o.id as cid,o.term,o.code,o.name,o.UOC,ahm.average_mark,ahm.highest_mark,ahm.median_mark,sb.student_nb as totalEnrols
from student_nb sb, a_h_m ahm, others o , course_staff cs
where sb.course=ahm.course and o.id = sb.course and cs.course = o.id
and sb.student_nb>0
;



create or replace function Q2(staff_id integer)
	returns setof TeachingRecord
as $$
declare 
checkid INTEGER;
results TeachingRecord;
begin
select staff into checkid from q2_all where staff = $1;
if (not found) THEN
    raise exception 'INVALID STAFFID';
end if;
return query select cid::integer,term::char(4),code::char(8),name::text,uoc::integer,average_mark::integer,highest_mark::integer,median_mark::integer,totalEnrols::integer from q2_all
where staff = $1;

end;
-- --... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;




-- --Q3:



create or replace view c_ce_p
as
select c.id as course_id,p.unswid,p.name,c.subject,ce.mark,c.semester from course_enrolments ce, courses c, people p where ce.course = c.id and ce.student = p.id 
;
create or replace view c_ce_p2 
as
select ccep.course_id,ccep.unswid,ccep.name,s.code,s.name as subject_name, se.name as semester_name, s.offeredby,ccep.mark
from c_ce_p ccep, semesters se, subjects s 
where ccep.semester = se.id and ccep.subject = s.id  
;
create or replace view c_ce_p3
as
select ccep2.course_id,ccep2.unswid,ccep2.name,ccep2.code,ccep2.subject_name,ccep2.semester_name,o.name as OrgUnits_name,ccep2.mark,ccep2.offeredby 
from c_ce_p2 ccep2, orgunits o where  ccep2.offeredby = o.id
order by ccep2.unswid,ccep2.mark desc nulls last,ccep2.code 
;
create or replace view c_ce_p4
AS
select * , row_number() over (partition by unswid) as row_nb from c_ce_p3
;

drop type if exists og_id cascade;
create type og_id as (owner integer,member integer);
create or replace function q33(org_id integer) returns setof og_id
as $$   
        with recursive suborg as (
            select * from orgunit_groups where owner = $1 
            UNION all
            select og.* from orgunit_groups og inner join suborg s on s.member = og.owner
        )
        select *  from suborg order by owner;
 
$$ LANGUAGE sql
;
drop type if exists og_id1 cascade;
create type og_id1 as (member integer);
create or replace function qb33(org_id integer) returns setof og_id1
as $$
DECLARE
abc og_id;
begin
        select * into abc from orgunit_groups where owner=$1;
        if abc.owner is null THEN
            return query select id from orgunits where id=$1;
        ELSE
            return query select member from q33($1);
        end if;
end;
$$ LANGUAGE plpgsql
;


drop type if exists CourseRecord cascade;
create type CourseRecord as (unswid integer, student_name text, course_records text);
drop type if exists Coursescreen cascade;
create type Coursescreen as (unswid integer, student_name text, code character,subject_name text,semester_name text,OrgUnits_name text,mark integer);

create or replace function q333(org_id integer, num_courses integer, min_score integer) 
returns setof Coursescreen
as $$
    with c_ce_p5 as 
    (select cp4.* from c_ce_p4 cp4, (select * from qb33($1)) as b1 where cp4.offeredby = b1.member) 
    ,
    c_ce_p7
    as
    (select unswid,mark from c_ce_p5 where mark>=$3 and mark is not null) 
    ,
    c_ce_p6
    AS
    (select c5.* from c_ce_p7 c7,c_ce_p5 c5, (select unswid,count(code)::integer as row_nb from c_ce_p5 group by unswid) as b2 
    where b2.row_nb > $2 and b2.unswid = c5.unswid  and c7.unswid=c5.unswid
    order by c5.unswid,c5.mark desc nulls last,c5.code)
    ,
    c_ce_c8 
    as
    (select distinct c3.course_id, c3.unswid,c3.name,c3.code,c3.subject_name,c3.semester_name,c3.orgunits_name,c3.mark ,c3.offeredby from c_ce_p6 c3
        order by c3.unswid,c3.mark desc nulls last,c3.code desc)

    select c.unswid,c.name,c.code,c.subject_name,c.semester_name,c.orgunits_name,c.mark from c_ce_c8 c;
$$ language sql
; 
drop type if exists Coursescreen1 cascade;
create type Coursescreen1 as (unswid integer, student_name text, code character,subject_name text,semester_name text,OrgUnits_name text,mark text);

create or replace function qba333(org_id integer, num_courses integer, min_score integer) 
returns setof Coursescreen1
as $$
select unswid,student_name,code,subject_name,semester_name,Orgunits_name,case when mark is null then 'null' else mark::text END
from q333($1,$2,$3)
$$ LANGUAGE sql
;
create or replace function concatenation(org_id integer, num_courses integer, min_score integer)
returns setof CourseRecord
AS $$

select unswid,student_name,code||', '||subject_name||', '||semester_name||', '||OrgUnits_name||', '||
mark
from qba333($1,$2,$3)
$$ language sql
;


create or replace function Q3(org_id integer, num_courses integer, min_score integer)
  returns setof CourseRecord
as $$
DECLARE
r record;
checker INTEGER;
count1 INTEGER :=0;
unswnd integer := 0 ;
outcome text:='';
finaloutcome CourseRecord;
name1 text :='';


BEGIN
select unswid into checker from q333($1,$2,$3);

if (not found) THEN
    raise exception 'INVALID ORGID';
end if;

for r in select * from concatenation($1,$2,$3)
loop 
    
    if (unswnd != r.unswid) THEN
        if (outcome = '') then 
            unswnd := r.unswid ;
            name1 := r.student_name;
            outcome := r.course_records||E'\n';
            count1 := count1+1;
            
        ELSE
            select unswnd,name1,outcome into finaloutcome;
            return next finaloutcome;
            count1 := 0;
            unswnd := r.unswid; 
            name1 := r.student_name;
            outcome := r.course_records||E'\n';
            count1 := count1+1;
        end if; 
    ELSE
        continue when count1 >4;
        outcome := outcome||''||r.course_records||E'\n';
        count1 := count1+1;

    end if ;
    
end loop; 
select unswnd,name1,outcome into finaloutcome;
return next finaloutcome;
return;

end;

-- -- -- -- --... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;
