-- CREATING A NEW SCHEMA AND LOADING THE DATASET FOR THE PROJECT USING TABLE DATA IMPORT WIZARD

Create Schema Crash_Report;
Use Crash_Report;


-- Alter Table crash_data
-- rename column
-- `Crash ID` to Crash_ID;

-- drop table crash_data;

select * from crash_data;

-- CLEANING THE DATA: FILLING IN MISSING DATA, CHANGING STATES' NAME TO UPPERCASE, RENAMING COLUMNS

-- Change the State column to uppercase
Update crash_data SET State = upper(State);

-- Renaming columns for easy querying
Alter Table crash_data
rename column
`Bus Involvement` to Bus_Involvement;

-- I should have done this instead
Alter Table crash_data
rename column `Heavy Rigid Truck Involvement` to HR_Truck_Involvement,
rename column `Articulated Truck Involvement` to Articulated_Truck_Involvement,
rename column `Speed Limit` to Speed_Limit,
rename column `Road User` to Road_User,
rename column `National Remoteness Areas` to National_Remoteness_Areas;

-- I'd like to update the rows that contain empty string or null values
select * 
from crash_data
where Bus_Involvement = '';

-- Filling in empty rows in Bus_Involvement
-- Assuming it's a'NO' where Crash_Type is 'Single'
Start Transaction;
Update crash_data
set Bus_Involvement = 'No'
where Bus_Involvement = '' and Crash_Type = 'Single';
Rollback;
Commit;

select * from crash_data;

-- Ok, let's get ready for visualization
-- Cleaning more data
Update crash_data
set HR_Truck_Involvement = 'No'
where HR_Truck_Involvement = '' and Crash_Type = 'Single';

update crash_data
set Articulated_Truck_Involvement = 'No'
where Articulated_Truck_Involvement = '' and Crash_Type = 'Single';

select * from crash_data;


-- EXPLORATORY DATA ANALYSIS

-- Identify the State with the highest crash incident
with State_count(State, total) AS
	(
	select distinct State, count(State) as total
	from crash_data
	group by State
	)
    
    select State, total, total/52843 * 100 as percentage
    from State_count
    order by percentage desc;


-- Identify the highest crash incident by year
select distinct Year, count(Year) total
from crash_data
group by Year
order by total desc;



-- See if it's looking good
select * from crash_data;


-- Create a Procedure to count the total crash incident per state
Drop Procedure total_crash;
Delimiter &&
Create Procedure total_crash(in selected_state varchar(50))
Begin
select selected_state, count(selected_state) from crash_data
where State = selected_state
group by selected_state;
End &&
Delimiter ;

call total_crash('VIC');
call total_crash('SA');


-- This Stored Procedure is not working
Drop Procedure fill_in_data
Delimiter &&
Create Procedure fill_in_data(in select_column varchar(50))
Begin
	Update crash_data
	Set select_column = 'Unknown'
	Where select_column = '' and Crash_Type = "Single";
End &&
Delimiter ;

call fill_in_data(Bus_Involvement);


-- Identify the most areas in Australia where crash accidents happen
select National_Remoteness_Areas, count(National_Remoteness_Areas)as total_Count
from crash_data
group by National_Remoteness_Areas
order by total_Count desc;

-- Identify what gender has the most crash incidents
select Gender, count(Gender)
from crash_data
group by Gender;


-- Identify empty rows in Nationa_Remoteness_Areas column
select  State, count(State) as count
from crash_data
where National_Remoteness_Areas = ''
group by State
order by count desc;

-- Which Age group had more record of crash accident
Alter Table crash_data
rename column
`Age Group` to Age_Group;

with Age_Group_Total(Age_Group, total) As
	(
	select Age_Group, count(Age_Group) as total
	from crash_data
	group by Age_Group
	order by total desc
    )
    
    select Age_Group, total, total/52843 * 100 as percentage
    from Age_Group_Total;
    


-- Identify which day of the week has the highest crash incident
select Dayweek, count(Dayweek) as total
from crash_data
group by Dayweek
order by total desc;


select * from crash_data;

-- Which Road User is more prone to crash
 select Road_User, count(Road_User) as total
 from crash_data
 group by Road_User
 order by total desc;

-- Find out what is the most speed limit when an accident occurs
select Speed_Limit, count(Speed_Limit) total
from crash_data
group by Speed_Limit
order by total desc;


Delimiter //
Create Procedure Get_The_Most(in selected_column varchar(50))
Begin
(
	select selected_column, count(selected_column) total
	from crash_data
	group by selected_column
	order by total desc
)
End 
Delimiter ;


-- Find out the average speed limit of road users involved in crash
-- This doesn't make sense, a pedestrian walking 65k/hr?

select Road_User,avg(Speed_Limit) as Ave_Speed
from crash_data
group by Road_User
order by Ave_Speed desc;

-- Do most accidents happen at night or day?
alter table crash_data
rename column
`Time of day` to Time_of_day;

select Time_of_day, count(Time_of_day) total
from crash_data
group by Time_of_day
order by total desc;

-- Well, it seems like most accidents happens during the day, but most people usually drive during the day, so?



-- State where the most bus accidents happen
select State, count(Bus_Involvement) total
from crash_data
where Bus_Involvement = "Yes"
group by State
order by total desc;


-- I noticed that there negative values for speed limit
select distinct speed_limit from crash_data;
select avg(speed_limit) from crash_data;



-- CREATING TABLES USING VIEWS AND CTES

-- I need to create a table where I can see the state's number of crash in some years
-- My first attempt is to make views and combine them together
-- This would end me up with lots of views

Drop View y;
Create View y
As
select State, count(Year) as `1989`
from crash_data
where Year = '1989'
group by State
;

select * from `1989`;

Drop View y1;
Create View y1
As
select State, count(Year) as `1990`
from crash_data
where Year = '1990'
group by State
;

Drop View y2;
Create View y2
As
select State, count(Year) as `1991`
from crash_data
where Year = '1991'
group by State
;

Drop View y3;
Create View y3
As
select State, count(Year) as `1992`
from crash_data
where Year = '1992'
group by State
;

-- Joining all the tables
select y.State, y.`1989`, y1.`1990`, y2.`1991`, y3.`1992` from y1
Join y on y1.State = y.State
Join y2 on y2.State = y1.State
Join y3 on y3.State = y2.State;
 
 
 -- Trying a different approach
 -- I was trying to see whether I can use CTE instead, and then when I got all my result, I saved the table as a view
 
Create View State_by_year AS
( 
with T1 as
(
select State, count(Year) as `1989`
from crash_data
where Year = '1989'
group by State
),
T2 as (
select State, count(Year) as `1990`
from crash_data
where Year = '1990'
group by State),

T3 as (
select State, count(Year) as `1991`
from crash_data
where Year = '1991'
group by State),

T4 as (
select State, count(Year) as `1992`
from crash_data
where Year = '1992'
group by State)

select T1.State, T1.`1989`, T2.`1990`, T3.`1991`, T4.`1992` from T1
Join T2 on T1.State = T2.State
Join T3 on T2.State = T3.State
Join T4 on T3.State = T4.State)
;

-- I successfully created a view where I can see the states' car crash number by year

-- I am in attempt now to make a cte recursion