-- COMP9311 18s1 Project 1
--
-- MyMyUNSW Solution Template


-- Q1: 
create or replace view tran_over_85 AS
select student, count(*) as st_count 
from (select student, course,mark from course_enrolments 
where mark >= 85) as st_85 
group by student;

create or replace view pe_20 AS
select student from tran_over_85 tr join students s 
on (tr.student=s.id)
where tr.st_count > 20 and s.stype='intl';

create or replace view Q1(unswid, name)
as
select p.unswid, p.name from people p, pe_20 p20
where p.id = p20.student
order by p.unswid Desc

--... SQL statements, possibly using other views/functions defined by you ...
;



-- -- Q2: 
create or replace view CSB AS
select id from buildings 
where name = 'Computer Science Building';

CREATE or replace view Rtype as 
select id from room_types 
where DESCRIPTION = 'Meeting Room';


create or replace view Q2(unswid, name)
as
select r.unswid, r.longname
from (rooms r join CSB c on (r.building=c.id)) 
join Rtype Rt on (r.Rtype=Rt.id) 
where r.capacity >= 20 
-- --... SQL statements, possibly using other views/functions defined by you ...
;



-- -- Q3: 
create or replace view student_course AS
select course from (course_enrolments ce join students s 
on (ce.student=s.id)) join people p on (p.id=s.id) 
where p.name = 'Stefan Bilek';

create or replace view staffid as 
select staff from course_staff c join student_course s
on (c.course=s.course);

create or replace view Q3(unswid, name)
as
select unswid,name from people p join staffid s 
on (p.id=s.staff)
-- --... SQL statements, possibly using other views/functions defined by you ...
;



-- -- Q4:
create or replace view student_inters1 AS
select student from (subjects sub join courses c 
on (sub.id=c.subject)) join Course_enrolments ce 
on (ce.course=c.id) where sub.code='COMP3331' ;

create or replace view student_inters2 AS
select student from (subjects sub join courses c 
on (sub.id=c.subject)) join Course_enrolments ce 
on (ce.course=c.id) where sub.code='COMP3231' ;

create or replace view student_inters3 AS
select * from student_inters1 s1
except
(select * from student_inters1 s1 
INTERSECT
select * from student_inters2 s2); 


create or replace view Q4(unswid, name)
as
select unswid, name from people p join student_inters3 s3
on (p.id=s3.student)
-- --... SQL statements, possibly using other views/functions defined by you ...
;



-- -- Q5: 


create or replace view stu_term1 AS
select partof from streams s join Stream_enrolments se
on (s.id=se.stream) where s.name='Chemistry';

create or replace view stu_term2 AS
select semester,student from stu_term1 s1 join Program_enrolments pe 
ON (s1.partof=pe.id);

create or replace view stu_term3 AS
select student from stu_term2 pe JOIN
(select * from semesters s where s.year=2011 and 
s.term = 'S1') as sb on (sb.id=pe.semester);

CREATE or replace view stu_term4 AS
select distinct student from stu_term3 s join students ss
on (s.student=ss.id) where ss.stype = 'local';

create or replace view Q5a(num)
as
select count(*) as num from stu_term4
-- --... SQL statements, possibly using other views/functions defined by you ...
;

-- -- Q5: 
create or replace view stu_degree AS
select program, student from Program_enrolments pe JOIN
(select * from semesters s where s.year=2011 and 
s.term = 'S1') as sb ON (sb.id=pe.semester);

create or replace view stu_degree0 as 
select p.id from OrgUnits o join programs p 
on (o.id=p.offeredby)
where o.name = 'Computer Science and Engineering, School of';

create or replace view stu_degree1 AS
select student from stu_degree pe JOIN
stu_degree0 s0 on (pe.program=s0.id);

CREATE or replace view stu_degree2 AS
select distinct student from stu_degree1 s join students ss
on (s.student=ss.id) where ss.stype = 'intl';

create or replace view Q5b(num)
as
select count(*) as num from stu_degree2
-- --... SQL statements, possibly using other views/functions defined by you ...
;


-- -- Q6:
create or replace function Q6(text) 
returns text as $$

SELECT
    code||' '||longname||' '||uoc FROM subjects 
    where code = $1;


-- --... SQL statements, possibly using other views/functions defined by you ...
$$ language sql;



-- -- Q7: 
create or replace view prog_percentage1 AS
select program, count(*) as total from Program_enrolments 
group by program;

create or replace view prog_percentage2 AS
select program , count(*) as intel from Program_enrolments pe 
inner join students s on s.id=pe.student 
where s.stype='intl' group by program;

create or replace view prog_percentage3 AS
select p2.program from prog_percentage1 p1 inner JOIN
prog_percentage2 p2 on (p1.program=p2.program) where
(p2.intel::numeric / p1.total::numeric) > 0.5;

create or replace view Q7(code, name)
as
select p.code, p.name from Programs p
inner join prog_percentage3 p3 on p.id=p3.program 
order by p.code DESC

-- --... SQL statements, possibly using other views/functions defined by you ...
;



-- -- Q8:
CREATE or replace view course_av1 AS
select course, count(*) as mark_num from 
Course_enrolments group by course;

CREATE or replace view course_av2 AS
select course, mark_num from course_av1 where (mark_num::integer)>15;

CREATE or replace view course_av3 AS
select c2.course, avg(ce.mark) as avg_mark from course_av2 c2 
inner join Course_enrolments ce on c2.course=ce.course
group by c2.course;

CREATE or replace view course_av4 AS
select * from course_av3 where
avg_mark=(select max(avg_mark) from course_av3);


create or replace view Q8(code, name, semester)
as
select s.code, s.name, se.name as semester from 
course_av4 c4 ,courses c, subjects s, semesters se where 
c4.course=c.id and c.subject = s.id 
and c.semester = se.id
-- --... SQL statements, possibly using other views/functions defined by you ...
;



-- -- Q9:
create or replace view head_sc1 AS
select * from affiliations a inner join 
(select * from staff_roles where name='Head of School') as sr 
on (a.role=sr.id) where a.isprimary is true and ending is null; 

create or replace view head_sc2 AS
select hs1.staff,hs1.orgunit,hs1.starting from head_sc1 hs1 
inner JOIN OrgUnits o on o.id=hs1.OrgUnit
inner join OrgUnit_types ot on o.utype=ot.id
where ot.name='School';

create or replace view head_sc3 AS
select p.name, o.longname,p.email,hs2.starting, hs2.staff from head_sc2 hs2
inner join staff sf on hs2.staff=sf.id
inner join people p on p.id = sf.id 
inner join OrgUnits o on o.id = hs2.orgunit 
order by p.name desc;


create or replace view head_sc4 AS
select kobe.staff, count(*) as num_subjects
from (select distinct staff, s.code from courses c 
inner join Course_staff cs on cs.course = c.id
inner join subjects s on s.id=c.subject) kobe
group by kobe.staff;

create or replace view Q9(name, school, email, starting, num_subjects)
as
select distinct h3.name,h3.longname,h3.email,h3.starting,h4.num_subjects from head_sc3 h3
inner join head_sc4 h4 on h3.staff = h4.staff where h4.num_subjects >0

-- --... SQL statements, possibly using other views/functions defined by you ...

;


-- -- Q10:
create or replace view HD_s0 AS
select s.code,c.id,c.subject,s.name,count(c.subject) over (partition by c.subject) as subject_number
,substr(cast(se.year as varchar),3,2) as years from subjects s 
inner join courses c on s.id = c.subject
inner join semesters se on se.id = c.semester
where s.code like 'COMP93%' and se.term ~ '[S]'
and se.year >= 2003 and se.year <= 2012;

create or replace view HD_s1 AS
select distinct a1.code,s0.id ,s0.subject,s0.name,s0.years from HD_s0 s0 
,(select s.code from subjects s 
inner join courses c on s.id = c.subject
inner join semesters se on se.id = c.semester
where s.code like 'COMP93%' group by s.code having count(c.id) = 24) as a1
where a1.code=s0.code;

create or replace view HD_s20 AS
select s1.code,s1.id,s1.subject,s1.name,s1.years,ce.mark 
from HD_s1 s1
inner join Course_enrolments ce on ce.course = s1.id
inner join courses c on c.id=s1.id 
inner join semesters s on c.semester=s.id
where  s.term ='S1' and ce.mark > 0;

create or replace view HD_s21 AS
select distinct code ,id,name,years, count(mark) as mark1 from HD_s20
group by code,name,years,id;

create or replace view HD_s22 AS
select s1.code,s1.id,s1.subject,s1.name,s1.years,ce.mark 
from HD_s1 s1
inner join Course_enrolments ce on ce.course = s1.id
inner join courses c on c.id=s1.id 
inner join semesters s on c.semester=s.id
where  s.term ='S1' and ce.mark >= 85;

create or replace view HD_s23 AS
select distinct code ,id,name,years, count(mark) as mark1 from HD_s22
group by code,name,years,id;

create or replace view HD_s24 AS
select s21.code,s21.id,s21.name,s21.years,s21.mark1,
case when s23.mark1 is null then 0 else s23.mark1 end as mark2 from hd_s21 s21 
left join hd_s23 s23 on s21.id=s23.id;

create or replace view HD_s25 AS
select code,id,name,years, 
cast(1.0*mark2/mark1 as numeric(4,2)) as hd_rate from hd_s24 ; 

create or replace view HD_s30 AS
select s1.code,s1.id,s1.subject,s1.name,s1.years,ce.mark 
from HD_s1 s1
inner join Course_enrolments ce on ce.course = s1.id
inner join courses c on c.id=s1.id 
inner join semesters s on c.semester=s.id
where  s.term ='S2' and ce.mark > 0;

create or replace view HD_s31 AS
select distinct code ,id,name,years, count(mark) as mark1 from HD_s30
group by code,name,years,id;

create or replace view HD_s32 AS
select s1.code,s1.id,s1.subject,s1.name,s1.years,ce.mark 
from HD_s1 s1
inner join Course_enrolments ce on ce.course = s1.id
inner join courses c on c.id=s1.id 
inner join semesters s on c.semester=s.id
where  s.term ='S2' and ce.mark >= 85;

create or replace view HD_s33 AS
select distinct code ,id,name,years, count(mark) as mark1 from HD_s32
group by code,name,years,id;

create or replace view HD_s34 AS
select s21.code,s21.id,s21.name,s21.years,s21.mark1,
case when s23.mark1 is null then 0 else s23.mark1 end as mark2 from hd_s31 s21 
left join hd_s33 s23 on s21.id=s23.id;

create or replace view HD_s35 AS
select code,id,name,years, 
cast(1.0*mark2/mark1 as numeric(4,2)) as hd2_rate from hd_s34 ; 

create or replace view HD_s36 AS
select s25.code, s25.name, s25.years, s25.hd_rate, s35.hd2_rate from hd_s25 s25 
full outer join hd_s35 s35 on s35.id=s25.id;

create or replace view HD_s37 AS
select s25.code, s25.name, s25.years, s25.hd_rate, s25.hd2_rate, 
lead(s25.hd2_rate,2) over() as gg from hd_s36 s25;

create or replace view Q10(code, name, year, s1_HD_rate, s2_HD_rate)
as
select code, name, years, hd_rate, gg from hd_s37 where code is not null order by code, years 

-- --... SQL statements, possibly using other views/functions defined by you ...
;

