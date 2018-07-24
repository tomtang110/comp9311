-- Schema for simple company database

create table Employees (
	tfn         char(11) 
	constraint Validtfn
	check (tfn ~ '[0-9]{3}-[0-9]{3}-[0-9]{3}'),
	givenName   varchar(30) not null,
	familyName  varchar(30),
	hoursPweek  float 
	constraint Validhourspweek
	check (hoursPweek<=168 AND hoursPweek>0),
	primary key (tfn)
);

create table Departments (
	id          char(3) 
	constraint vaildId
	check (id ~ '[[:digit:]]{3}'),
	name        varchar(100),
	manager     char(11)
	constraint Validmanager
	references Employees(tfn),
	UNIQUE(name,manager),
	primary key (id)
);

create table DeptMissions (
	department  char(3) 
	constraint vailddepartment
	references Departments(id),
	keyword     varchar(20),
	primary key (department,keyword)
);

create table WorksFor (
	employee    char(11) 
	constraint Vaildemployees
	references Employees(tfn),
	department  char(3)
	constraint vailddepartment
	references Departments(id),
	percentage  float 
	constraint vaildpercentage
	check (percentage>0),
	primary key (employee,department)
);

create or replace function check_insert_worksfor()
returns TRIGGER as $check_insert_wf$
DECLARE
percentage1 FLOAT;
percentage2 FLOAT;
BEGIN
select into percentage1 sum(percentage) from worksfor where 
employee = NEW.employee;
percentage2 = percentage1 + NEW.percentage;
IF percentage2 > 100 THEN
	raise exception 'work percentage cannot exceed 100 percent';
END IF;
return NEW;
END;
$check_insert_wf$ language plpgsql;

CREATE trigger check_insert_wfg before insert or update on Worksfor 
for each ROW EXECUTE PROCEDURE check_insert_worksfor();


