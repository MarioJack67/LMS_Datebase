--Switch and check if lms exists, drop if it does, helps avoid usage/repeat errors
use master;
go

if exists (select name from sys.databases where name = 'lms')
begin
    alter database lms 
    set single_user 
    with rollback immediate;
   
    drop database lms;
end
go

create database lms;
go

use lms;
go


--Create tables and constraints
create table Department(
	deptID int not null primary key,
	code varchar(5) not null,
	name varchar(30) not null,
	location varchar(30),
	budget money not null
	check (budget > 0 and budget <= 100000)
);

create table Program(
	programID int not null primary key,
	major varchar(20) not null,
	degree varchar(4) not null,
	yearsToComp int,
	deptID int not null,
	--don't allow deletion until programs are given a new department or deleted themselves
	constraint fk_programdeptID foreign key (deptID) references Department(deptID) on delete no action
	on update cascade,
	check(yearsToComp > 0 and yearsToComp < 8)
);

create table [User](
	userID int not null primary key,
	fname varchar(50) not null,
	lname varchar(50),
	email varchar(50) unique,
	phone varchar(20),
	accessLvl int not null,
	check (email like '_%@_%._%'),
	check (accessLvl in (1, 2, 3))
);

create table Instructor(
	userID int not null primary key,
	title varchar(5),
	officeRoom varchar(20) not null,
	deptID int not null default 1,
	--on delete, set the instructor to the general staff department automatically
	constraint fk_instructdeptID foreign key (deptID) references Department(deptID) on delete set default
	on update cascade,
	constraint fk_instructuserID foreign key (userID) references [User](userID) on delete cascade
	on update cascade
);

create table Student(
	userID int not null primary key,
	gpa decimal(3, 2),
	classLvl varchar(20) not null,
	programID int not null default 1,
	--On delete, set the student in the general studies program automatically
	constraint fk_studentprogramID foreign key (programID) references Program(programID) on delete set default
	on update cascade,
	constraint fk_studentuserID foreign key (userID) references [User](userID) on delete cascade
	on update cascade,
	check (gpa between 0.0 and 4.0),
	check (classLvl in ('Freshman', 'Sophomore', 'Junior', 'Senior'))
);

create table Course(
	courseID int not null primary key,
	cname varchar(30) default 'New Experimental Course',
	[subject] varchar(5) not null,
	cnumber int not null,
	[description] varchar(200),
	credits int not null
	check (credits in (2, 3, 4))
);

create table Section(
	sectionID int not null primary key,
	[format] varchar(10) not null,
	[location] varchar(20),
	meetingTime time,
	semester varchar(15) not null,
	semesterEnd datetime not null,
	courseID int not null,
	instructorID int,
	constraint fk_sectioncourseID foreign key (courseID) references Course(courseID) on delete cascade
	on update cascade,
	constraint fk_sectioninstructorID foreign key (instructorID) references Instructor(userID) on delete set null
	on update cascade,
	check ([format] in ('In-Person', 'Hybrid', 'Online'))
);

create table Enrollment(
	enrollmentID int not null primary key,
	enrollDate datetime not null,
	finalGrade varchar(2) not null default 'IP',
	studentID int not null,
	sectionID int not null,
	constraint fk_enrollstudentID foreign key (studentID) references Student(userID) on delete cascade
	on update cascade,
	constraint fk_enrollsectionID foreign key (sectionID) references Section(sectionID),
	check (finalGrade in ('A', 'B', 'C', 'D', 'F', 'IP'))
);

create table Grade(
	gradeID int not null primary key,
	totalEarned int not null,
	totalAssignment int not null,
	gradeDate datetime,
	enrollmentID int not null unique,
	--If the enrollment is deleted, don't hang onto the grade anymore
	constraint fk_gradeenrollmentID foreign key (enrollmentID) references Enrollment(enrollmentID) on delete cascade
	on update cascade
);

create table Assignment(
	assignID int not null primary key,
	totalPoints int not null,
	aname varchar(30) default 'New Assignment',
	dueDate datetime not null,
	[type] varchar(15) not null,
	sectionID int not null,
	constraint fk_assignsectionID foreign key (sectionID) references Section(sectionID) on delete cascade
	on update cascade
);

create table Submission(
	subID int not null primary key,
	earnedPoints int not null,
	subDate datetime not null,
	enrollmentID int not null,
	assignID int not null,
	constraint fk_submitenrollmentID foreign key (enrollmentID) references Enrollment(enrollmentID) on delete cascade
	on update cascade,
	constraint fk_submitassignID foreign key (assignID) references Assignment(assignID)
);

create table Feedback(
	feedID int not null primary key,
	feedDate datetime,
	comments varchar(100),
	publish bit not null,
	subID int not null,
	constraint fk_feedsubID foreign key (subID) references Submission(subID) on delete cascade
	on update cascade
);
go

--Insert some departments
insert into Department values (1, 'GEN', 'General Staff', null, 20000)
insert into Department values (2, 'CS', 'School of Computing', 'Building 1', 50000)
insert into Department values (3, 'MATH', 'School of Math', 'Building 2', 40000)
insert into Department values (4, 'ENGL', 'School of English', 'Building 3', 35000)

--Insert some programs
insert into Program values (201, 'Computer Science', 'AS', 2, 2)
insert into Program values (202, 'Computer Science', 'BS', 4, 2)
insert into Program values (203, 'Computer Science', 'MS', 2, 2)
insert into Program values (301, 'Mathematics', 'AS', 2, 3)
insert into Program values (302, 'Mathematics', 'BS', 4, 3)
insert into Program values (401, 'English', 'BS', 4, 4)

--Insert 3 instructors, 10 students, and 1 admin into users
--Access Level 3 = Admin, 2 = Instructor, 1 = Student
insert into [User] values (1001, 'John', 'Smith', 'jsmith@school.edu', '801-999-1234', 3)
insert into [User] values (1002, 'Bryce', 'Scott', 'bscott@school.edu', '801-567-9384', 2)
insert into [User] values (1003, 'Amira', 'Jones', 'ajones@school.edu' , null, 2)
insert into [User] values (1004, 'Hunter', 'Omega', 'homega@school.edu', '385-292-9393', 2)
insert into [User] values (1005, 'Brielle', 'Jenkins', 'bjenkins@school.edu', '801-393-9825', 1)
insert into [User] values (1006, 'Kyle', 'Hamilton', 'khamilton@school.edu', '414-016-1642', 1)
insert into [User] values (1007, 'Ellie', 'Alton', 'ealton@school.edu', '414-812-7134', 1)
insert into [User] values (1008, 'Jack', 'Huff', 'jhuff@school.edu', '285-121-8392', 1)
insert into [User] values (1009, 'Enrique', 'Lopez', 'elopez@school.edu', null, 1)
insert into [User] values (1010, 'Omar', 'Salvator', 'osalvator@school.edu', '801-293-5832', 1)
insert into [User] values (1011, 'Heather', 'Withers', 'hwithers@school.edu', '285-715-4092', 1)
insert into [User] values (1012, 'Jim', 'Dean', 'jdean@school.edu', '717-264-0808', 1)
insert into [User] values (1013, 'Harper', 'Franco', 'hfranco@school.edu', '385-193-0156', 1)
insert into [User] values (1014, 'Michael', 'Campbell', 'mcampbell@school.edu', '801-628-3948', 1)

--Insert 3 instructors into instructor table
insert into Instructor values (1002, 'Dr.', 'B1-203', 2)
insert into Instructor values (1003, 'Dr.', 'B2-105', 3)
insert into Instructor values (1004, 'Prof.', 'B3-102', 4)

--Insert 10 students into student table
--2 seniors, 2 juniors, 3 sophmores, 3 freshman
insert into Student values (1005, 3.5, 'Senior', 202)
insert into Student values (1006, 3.0, 'Senior', 302)
insert into Student values (1007, 3.0, 'Junior', 401)
insert into Student values (1008, 2.5, 'Junior', 302)
insert into Student values (1009, 4.0, 'Sophomore', 201)
insert into Student values (1010, 2.0, 'Sophomore', 301)
insert into Student values (1011, 3.0, 'Sophomore', 401)
insert into Student values (1012, null, 'Freshman', 201)
insert into Student values (1013, null, 'Freshman', 301)
insert into Student values (1014, null, 'Freshman', 401)

--Insert two courses for each subject
insert into Course values (2001, 'Operating Systems', 'CS', 3100, 'An overview of operating systems', 4)
insert into Course values (2002, 'DSA', 'CS', 2420, 'Intro to data structures and algorithms', 4)
insert into Course values (3001, 'Number Theory', 'MATH', 4100, 'Advanced topics in number theory', 3)
insert into Course values (3002, 'Calculus 1', 'MATH', 1210, 'Limits, derivatives, and optimization', 4)
insert into Course values (4001, 'Adv Fiction Writing', 'ENGL', 3560, 'Literature and Writing in Fiction', 3)
insert into Course values (4002, 'Intro to Writing', 'ENGL', 1010, 'Basics of Essay Writing', 3)

--Insert between 1-2 sections per course
insert into Section values (9001, 'In-Person', 'B1-301', '08:30:00', 'Fall20', '2020-12-05 00:00:00', 2001, 1002)
insert into Section values (9002, 'In-Person', 'B1-302', '10:00:00', 'Spr20', '2020-04-28 00:00:00', 2002, 1002)
insert into Section values (9003, 'Online', null, null, 'Spr20', '2020-04-28 00:00:00', 2002, 1003)
insert into Section values (9004, 'Online', null, null, 'Fall20', '2020-12-05 00:00:00', 3001, 1003)
insert into Section values (9005, 'Hybrid', 'B2-108', '11:00:00', 'Fall19', '2019-12-05 00:00:00', 3002, 1003)
insert into Section values (9006, 'Online', null, null, 'Fall19', '2019-12-05 00:00:00', 3002, 1002)
insert into Section values (9007, 'In-Person', 'B3-307', '12:00:00', 'Spr20', '2020-04-28 00:00:00', 4001, 1004)
insert into Section values (9008, 'In-Person', 'B3-308', '10:30:00', 'Fall20', '2020-12-05 00:00:00', 4002, 1004)
insert into Section values (9009, 'Online', null, null, 'Fall20', '2020-12-05 00:00:00', 4002, 1004)

--Insert enrollments for some students, leave others blank to mimic students taking semester breaks
--If a student has a final grade for a section, while another student still has IP in the 
--same section, we will assume it's a flex format where some students can finish quicker
insert into Enrollment values (10001, '2019-06-23 20:30:00', 'A', 1005, 9002)
insert into Enrollment values (10002, '2019-08-13 14:00:00', 'B', 1005, 9006)
insert into Enrollment values (10003, '2020-01-03 08:00:00', 'IP', 1005, 9001)
insert into Enrollment values (10004, '2019-06-23 20:30:00', 'B', 1006, 9005)
insert into Enrollment values (10005, '2019-08-13 14:00:00', 'B', 1006, 9007)
insert into Enrollment values (10006, '2020-01-03 08:00:00', 'IP', 1006, 9004)
insert into Enrollment values (10007, '2019-06-23 20:30:00', 'A', 1007, 9009)
insert into Enrollment values (10008, '2019-08-13 14:00:00', 'B', 1007, 9006)
insert into Enrollment values (10009, '2019-06-23 20:30:00', 'C', 1008, 9005)
insert into Enrollment values (10010, '2019-08-13 14:00:00', 'B', 1008, 9003)
insert into Enrollment values (10011, '2019-06-23 20:30:00', 'A', 1009, 9002)
insert into Enrollment values (10012, '2019-08-13 14:00:00', 'IP', 1009, 9003)
insert into Enrollment values (10013, '2019-06-23 20:30:00', 'C', 1010, 9008)
insert into Enrollment values (10014, '2019-08-13 14:00:00', 'IP', 1010, 9006)
insert into Enrollment values (10015, '2019-06-23 20:30:00', 'B', 1011, 9009)
insert into Enrollment values (10016, '2019-08-13 14:00:00', 'IP', 1011, 9002)
insert into Enrollment values (10017, '2019-06-23 20:30:00', 'IP', 1012, 9003)
insert into Enrollment values (10018, '2019-08-13 14:00:00', 'IP', 1012, 9005)
insert into Enrollment values (10019, '2019-06-23 20:30:00', 'IP', 1013, 9006)
insert into Enrollment values (10020, '2019-08-13 14:00:00', 'IP', 1013, 9009)
insert into Enrollment values (10021, '2019-06-23 20:30:00', 'IP', 1014, 9008)
insert into Enrollment values (10022, '2019-08-13 14:00:00', 'IP', 1014, 9002)

--Insert two assignments for each section, random points, quizzes and exams for better 
--calculation will be added later during functions and triggers
insert into Assignment values (101, 200, 'Assignment 1', '2020-10-08 00:00:00', 'Assignment', 9001);
insert into Assignment values (102, 200, 'Assignment 2', '2020-12-03 00:00:00', 'Assignment', 9001);
insert into Assignment values (103, 150, 'Assignment 1', '2020-03-25 00:00:00', 'Assignment', 9002);
insert into Assignment values (104, 100, 'Assignment 2', '2020-03-16 00:00:00', 'Assignment', 9002);
insert into Assignment values (105, 10, 'Assignment 1', '2020-02-23 00:00:00', 'Assignment', 9003);
insert into Assignment values (106, 20, 'Assignment 2', '2020-02-28 00:00:00', 'Assignment', 9003);
insert into Assignment values (107, 150, 'Assignment 1', '2020-10-09 00:00:00', 'Assignment', 9004);
insert into Assignment values (108, 100, 'Assignment 2', '2020-10-16 00:00:00', 'Assignment', 9004);
insert into Assignment values (109, 10, 'Assignment 1', '2019-09-16 00:00:00', 'Assignment', 9005);
insert into Assignment values (110, 10, 'Assignment 2', '2019-11-29 00:00:00', 'Assignment', 9005);
insert into Assignment values (111, 20, 'Assignment 1', '2019-10-28 00:00:00', 'Assignment', 9006);
insert into Assignment values (112, 20, 'Assignment 2', '2019-09-19 00:00:00', 'Assignment', 9006);
insert into Assignment values (113, 20, 'Assignment 1', '2020-04-12 00:00:00', 'Assignment', 9007);
insert into Assignment values (114, 10, 'Assignment 2', '2020-02-28 00:00:00', 'Assignment', 9007);
insert into Assignment values (115, 100, 'Assignment 1', '2020-10-14 00:00:00', 'Assignment', 9008);
insert into Assignment values (116, 20, 'Assignment 2', '2020-12-01 00:00:00', 'Assignment', 9008);
insert into Assignment values (117, 20, 'Assignment 1', '2020-09-13 00:00:00', 'Assignment', 9009);
insert into Assignment values (118, 20, 'Assignment 2', '2020-09-30 00:00:00', 'Assignment', 9009);

--For students who have completed enrollments, add some generic submissions for assignments
--Enrollments with IP won't have any submissions for now
--The earned points divided the total assignment points across two assignments should match enrollment grade
insert into Submission values (5001, 141, '2020-03-24 18:00:00', 10001, 103);
insert into Submission values (5002, 94, '2020-03-15 18:00:00', 10001, 104);
insert into Submission values (5003, 18, '2019-10-27 18:00:00', 10002, 111);
insert into Submission values (5004, 17, '2019-09-18 18:00:00', 10002, 112);
insert into Submission values (5005, 8, '2019-09-15 18:00:00', 10004, 109);
insert into Submission values (5006, 9, '2019-10-10 18:00:00', 10004, 110);
insert into Submission values (5007, 17, '2020-04-11 18:00:00', 10005, 113);
insert into Submission values (5008, 9, '2020-02-27 18:00:00', 10005, 114);
insert into Submission values (5009, 19, '2020-09-12 18:00:00', 10007, 117);
insert into Submission values (5010, 19, '2020-09-29 18:00:00', 10007, 118);
insert into Submission values (5011, 18, '2019-10-27 18:00:00', 10008, 111);
insert into Submission values (5012, 17, '2019-09-18 18:00:00', 10008, 112);
insert into Submission values (5013, 8, '2019-09-15 18:00:00', 10009, 109);
insert into Submission values (5014, 7, '2019-10-10 18:00:00', 10009, 110);
insert into Submission values (5015, 9, '2020-02-22 18:00:00', 10010, 105);
insert into Submission values (5016, 17, '2020-02-27 18:00:00', 10010, 106);
insert into Submission values (5017, 142, '2020-03-24 18:00:00', 10011, 103);
insert into Submission values (5018, 95, '2020-03-15 18:00:00', 10011, 104);
insert into Submission values (5019, 78, '2020-10-13 18:00:00', 10013, 115);
insert into Submission values (5020, 16, '2020-10-22 18:00:00', 10013, 116);
insert into Submission values (5021, 17, '2020-09-12 18:00:00', 10015, 117);
insert into Submission values (5022, 17, '2020-09-29 18:00:00', 10015, 118);
insert into Submission values (5023, 10, '2020-03-21 17:00:00', 10019, 111);
insert into Submission values (5024, 10, '2020-02-28 11:00:00' , 10019, 112);
insert into Submission values (5025, 10, '2020-02-28 11:00:00' , 10020, 117);
insert into Submission values (5026, 10, '2020-02-28 11:00:00' , 10020, 118);
insert into Submission values (5027, 0, '2020-03-03 15:00:00' , 10021, 115);
insert into Submission values (5028, 0, '2020-03-03 15:00:00' , 10021, 116);

--For all enrollments that already have a final grade, add grade records to match
--submission and assignment data
insert into Grade (gradeID, totalEarned, totalAssignment, gradeDate, enrollmentID) values (6001, 235, 250, '2020-03-26 10:00:00', 10001);
insert into Grade (gradeID, totalEarned, totalAssignment, gradeDate, enrollmentID) values (6002, 35, 40, '2019-10-29 10:00:00', 10002);
insert into Grade (gradeID, totalEarned, totalAssignment, gradeDate, enrollmentID) values (6003, 17, 20, '2019-10-12 10:00:00', 10004);
insert into Grade (gradeID, totalEarned, totalAssignment, gradeDate, enrollmentID) values (6004, 26, 30, '2020-04-13 10:00:00', 10005);
insert into Grade (gradeID, totalEarned, totalAssignment, gradeDate, enrollmentID) values (6005, 38, 40, '2020-10-01 10:00:00', 10007);
insert into Grade (gradeID, totalEarned, totalAssignment, gradeDate, enrollmentID) values (6006, 35, 40, '2019-10-29 10:00:00', 10008);
insert into Grade (gradeID, totalEarned, totalAssignment, gradeDate, enrollmentID) values (6007, 15, 20, '2019-10-12 10:00:00', 10009);
insert into Grade (gradeID, totalEarned, totalAssignment, gradeDate, enrollmentID) values (6008, 26, 30, '2020-03-01 10:00:00', 10010);
insert into Grade (gradeID, totalEarned, totalAssignment, gradeDate, enrollmentID) values (6009, 237, 250, '2020-03-26 10:00:00', 10011);
insert into Grade (gradeID, totalEarned, totalAssignment, gradeDate, enrollmentID) values (6010, 94, 120, '2020-10-24 10:00:00', 10013);
insert into Grade (gradeID, totalEarned, totalAssignment, gradeDate, enrollmentID) values (6011, 34, 40, '2020-10-01 10:00:00', 10015);
insert into Grade (gradeID, totalEarned, totalAssignment, gradeDate, enrollmentID) values (6012, 20, 40, '2020-10-21 12:00:00' , 10019);
insert into Grade (gradeID, totalEarned, totalAssignment, gradeDate, enrollmentID) values (6013, 20, 40, '2020-11-03 13:00:00', 10020);

--Add a couple of Feedback records for functionality
insert into Feedback values (7001, '2020-10-10 16:00:00', 'Very good', 1, 5001)
insert into Feedback values (7002, '2020-11-12 13:00:00', 'Needs some work', 1, 5020)

go

/*Write select queries to verify that the most critical tables are filled
select * from [User]
select * from Student
select * from Instructor
select * from Department
select * from Program
select * from Course
select * from Section
select * from Enrollment
select * from Grade
select * from Submission
select * from Assignment
select * from Feedback
go*/

--Create multitable view using joins
create view lms_details
as 
select 
	concat(u.fname, ' ', u.lname) as full_name,
	case
		when s.userID is not null then 'Student'
		when i.userID is not null then 'Instructor'
		else 'Administrator'
	end as user_role,
	c.cname,
	sec.[format],
	sec.[location],
	sec.meetingTime,
	sec.semester,
	e.enrollDate,
	e.finalGrade
--Joins Student, Instructor, Enrollment, Section, Course, and additionally User
from [User] u
left join Student s on u.userID = s.userID
left join Instructor i on u.userID = i.userID
left join Enrollment e on s.userID = e.studentID
left join Section sec on (e.sectionID = sec.sectionID or i.userID = sec.instructorID)
left join Course c on sec.courseID = c.courseID
go

--Run a query against the view
select * from lms_details

/* Query #1: userID 1005, all classes ever enrolled*/
select fname, lname, cname, [format], finalGrade
from [User] u
join Student s on u.userID = s.userID
join Enrollment e on s.userID = e.studentID
join Section sec on e.sectionID = sec.sectionID
join Course c on sec.courseID = c.courseID
where u.userID = 1005

/* Query #2: userID 1006, all classes that are IP*/
select fname, lname, cname, [format], finalGrade
from [User] u
join Student s on u.userID = s.userID
join Enrollment e on s.userID = e.studentID
join Section sec on e.sectionID = sec.sectionID
join Course c on sec.courseID = c.courseID
where u.userID = 1006 and finalGrade = 'IP'

/* Query #3: userId 1007, find all assignments, earned/total points for a class*/ 
select aname, subDate, dueDate, earnedPoints, totalPoints,
	case
		when (cast(earnedPoints as float) / totalPoints) * 100 >= 90 then 'A'
		when (cast(earnedPoints as float) / totalPoints) * 100 >= 80 then 'B'
		when (cast(earnedPoints as float) / totalPoints) * 100 >= 70 then 'C'
		when (cast(earnedPoints as float) / totalPoints) * 100 >= 60 then 'D'
		else 'F'
	end as grade
from Enrollment e
join Submission s on e.enrollmentID = s.enrollmentID
join Assignment a on s.assignID = a.assignID
where studentID = 1007 and e.sectionID = 9009
order by dueDate ASC

/* Query #4: Select all students in a single course and combine different sections */
select cname, [format], enrollDate, concat(fname, ' ', lname) as student_name
from Course c
join Section s on s.courseID = c.courseID
join Enrollment e on e.sectionID = s.sectionID
join Student stu on e.studentID = stu.userID
join [User] u on stu.userID = u.userID
where c.courseID = 3002
order by [format] ASC 

/* Query #5: List all students taking one or more courses under a specific instructor */
select concat(ui.fname, ' ', ui.lname) as instructor_name, cname, [format], concat(us.fname, ' ', us.lname) as student_name
from Course c
join Section s on s.courseID = c.courseID
join Instructor i on s.instructorID = i.userID
join [User] ui on ui.userID = i.userID
join Enrollment e on e.sectionID = s.sectionID
join Student stu on e.studentID = stu.userID
join [User] us on us.userID = stu.userID
where ui.userID = 1002
order by cname, [format] ASC

/* Query #6: Find average score for each assignment in a single class section */
select aname, avg(earnedPoints) as average_score
from Submission s
join Assignment a on s.assignID = a.assignID
where sectionID = 9009
group by aname 

/* Query #7: Find all assignments due in next 7 days for a single student 
   (Since this is historical data, I will do the the next 7 days after enrollment)*/
select cname, aname, enrollDate, dueDate
from Enrollment e
join Section s on e.sectionID = s.sectionID
join Course c on s.courseID = c.courseID
join Assignment a on a.sectionID = s.sectionID
where dueDate between dateadd(day, -7, semesterEnd) and semesterEnd
and studentID = 1010

/* Query #8: Find top five students with highest average grade across all enrollments 
   (Freshman won't be displayed because they have no grades yet) */
select top 5 max(concat(fname, ' ', lname)) as student_name, avg(totalEarned) as average_class_grade
from Grade g
join Enrollment e on g.enrollmentID = e.enrollmentID
join Student s on e.studentID = s.userID
join [User] u on s.userID = u.userID
group by e.studentID
order by average_class_grade DESC

/* Query #9: Find total number of students enrolled in each course/section*/ 
select max(cname) as course_name, max([format]) as section_format, count(studentID) as total_students
from Section s
join Enrollment e on e.sectionID = s.sectionID
join Course c on s.courseID = c.courseID
group by e.sectionID
order by total_students DESC

/* Query #10: Find all students failing a class with a grade percent less than 70*/
select concat(fname, ' ', lname) as student_name, cname, (cast(totalEarned as float) / totalAssignment) * 100 as grade_percent
from Grade g
join Enrollment e on g.enrollmentID = e.enrollmentID
join Student s on e.studentID = s.userID
join [User] u on s.userID = u.userID
join Section sec on e.sectionID = sec.sectionID
join Course c on sec.courseID = c.courseID
where (cast(totalEarned as float) / totalAssignment) * 100 < 70
go

/* Procedure #1: Find all assignments due in 7 days from the end of semester
   (Since we are using historical data, it's easier to find all projects due towards the end)*/
create procedure instructor_end_todolist
	@InstructorID int
as
begin
	select aname, cname, sec.sectionID, [format], dueDate
	from Section sec
	join Assignment a on sec.sectionID = a.sectionID
	join Course c on sec.courseID = c.courseID
	where sec.instructorID = @InstructorID
	and dueDate >= dateadd(day, -7, semesterEnd)
	and dueDate <= semesterEnd
end
go

/* Write a test for procedure #1 to find all assignments due in final week of a semester
	for instructor 1002*/
exec instructor_end_todolist @InstructorID = 1002
go

/* Procedure #2: Find all classes marked as IP for a single student*/
create procedure student_course_schedule
	@StudentID int
as
begin
	select concat(us.fname, ' ', us.lname) as student_name, cname, s.sectionID, 
		concat(ui.fname, ' ', ui.lname) as instructor_name, finalGrade
	from [User] us
	join Enrollment e on us.userID = e.studentID
	join Section s on e.sectionID = s.sectionID
	join Course c on s.courseID = c.courseID
	join [User] ui on s.instructorID = ui.userID
	where us.userID = @StudentID and finalGrade = 'IP'
end
go

/* Write a test for procedure #2 to find all current courses for student 1013*/
exec student_course_schedule @StudentID = 1013
go

/* Procedure #3: Return all students in a single class section */
create procedure course_roster
	@SectionID int
as
begin
	select concat(fname, ' ', lname) as student_name, studentID, enrollDate
	from Section sec
	join Enrollment e on e.sectionID = sec.sectionID
	join [User] u on u.userID = e.studentID
	where sec.sectionID = @SectionID
end
go

/* Write a test for procedure #3 to find all students in section 9002 */
exec course_roster @SectionID = 9002
go

/* Function #1: Return number of students with 2 or more missing assignments in a section */
create function missing_assignments_count(@SectionID int)
returns int
as
begin
	declare @StudentMissingCount int
	set @StudentMissingCount =
	(
		select count(*)
		from
		(
			select e.studentID, count(a.assignID) as number_of_missing
			from Enrollment e
			join Submission s on e.enrollmentID = s.enrollmentID
			join Assignment a on s.assignID = a.assignID
			where s.earnedPoints = 0 and e.sectionID = @SectionID
			group by e.studentID
			having count(a.assignID) >= 2
		) as missing_list
	)
	return @StudentMissingCount
end
go

/* Write a test for function #1 with a sectionID of 9008 */
select dbo.missing_assignments_count(9008) as number_of_student_with_2ormore_missing
go 

/* Function #2: Return average final score/earnedPoints for a section */
create function avg_section_score(@SectionID int)
returns decimal(10,2)
as
begin
	declare @AvgFinalScore decimal(10,2)
	set @AvgFinalScore =
	(
		select avg(g.totalEarned)
		from Enrollment e
		join Grade g on e.enrollmentID = g.enrollmentID
		where e.sectionID = @SectionID
	)
	return @AvgFinalScore
end
go

/* Write a test for function #2 using a sectionID of 9002 */
select dbo.avg_section_score(9002) as avg_section_score
go 

/* Query an existing student to find their current final score */
select concat(fname, ' ', lname) as student_name, e.enrollmentID, g.totalEarned
from Enrollment e
join [User] u on e.studentID = u.userID
join Grade g on e.enrollmentID = g.enrollmentID
where e.enrollmentID = 10001
go

/* Create trigger to recalculate final grades */
create trigger trigger_update_final_score
on Submission
after insert, update
as
begin
	set nocount on

	--Note: Only assignments count towards grade right now, so we only sum earned points
	update Grade 
	set totalEarned = sub.newTotal
	from Grade g
	join
	(
		select enrollmentID from inserted
		union
		select enrollmentID from deleted
	) nd on g.enrollmentID = nd.enrollmentID
	join
	(
		select s.enrollmentID, sum(earnedPoints) as newTotal
		from Submission s
		group by s.enrollmentID
	) sub on g.enrollmentID = sub.enrollmentID
end
go

/* Write updates and a query to test the new trigger */
update Submission
set earnedPoints = 100
where subID = 5001

select concat(fname, ' ', lname) as student_name, e.enrollmentID, g.totalEarned
from Enrollment e
join [User] u on e.studentID = u.userID
join Grade g on e.enrollmentID = g.enrollmentID
where e.enrollmentID = 10001
go

/* Index #1: Student enrollment lookup */
create nonclustered index IX_Student_Enrollment_Lookup
on Enrollment(studentID)

/* Explanation: We created this index so that we could speed up the retrieval of enrollment,
	submission, and section information when filtering by studentID. This is helpful when we
	want to find all enrollments/classes that a particular student would be in. Here is a sample
	query: */
select concat(fname, ' ', lname) as student_name, e.studentID, enrollDate, e.sectionID
from Enrollment e
join [User] u on e.studentID = u.userID
where studentID = 1005

/* Index #2: Assignment due date lookup */
create nonclustered index IX_Assignment_DueDate_Lookup
on Assignment(dueDate)

/* Explanation: This index was created to speed up the retrieval of assignment information
based on its due date. This was greatly benefit queries where we want to find assignments that are
due within the last 7 days of the semester as shown in our first procedure. Here is an example
query: */
select aname, cname, sec.sectionID, [format], dueDate
from Assignment a
join Section sec on a.sectionID = sec.sectionID
join Course c on sec.courseID = c.courseID
where dueDate >= dateadd(day, -7, semesterEnd)
and dueDate <= semesterEnd