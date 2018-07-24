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
ALTER table employees 
    add COLUMN worksin_Depid char(3) not NULL
    CONSTRAINT vaildId
    references Departments(id) deferrable initially deferred;

begin;

--set constraints all deferred;

insert into employees values ('111-111-111','YANG','YANG',40.0,'100');
insert into departments values ('100','Administration','111-111-111'); 

--set constraints all immediate;

commit;
