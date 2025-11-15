-- Creating Tables

DROP TABLE IF EXISTS employees_data;
DROP TABLE IF EXISTS trainings_data;
DROP TABLE IF EXISTS recruitments_data;
DROP TABLE IF EXISTS surveys_data;



CREATE TABLE employees_data(
	EmployeeID INT, 
	FirstName VARCHAR(25),
	LastName VARCHAR(25),
	StartDate DATE,
	ExitDate DATE,	
	Title VARCHAR(50),
	Supervisor VARCHAR(50),
	ADEmail	VARCHAR(100),
	BusinessUnit VARCHAR(25),	
	EmployeeStatus VARCHAR(30),
	EmployeeType VARCHAR(25),
	PayZone	VARCHAR(20),
	EmployeeClassificationType VARCHAR(30),
	TerminationType	VARCHAR(25),
	TerminationDescription VARCHAR(100),
	DepartmentType VARCHAR(30),
	Division VARCHAR(30),
	DOB	VARCHAR(20),
	States VARCHAR(10),	
	JobFunctionDescription VARCHAR(50),
	GenderCode VARCHAR(30),
	LocationCode INT,
	RaceDesc VARCHAR(25),
	MaritalDesc	VARCHAR(30),
	PerformanceScore VARCHAR(50),
	CurrentEmployeeRating INT

);

CREATE TABLE trainings_data(
	EmployeeID INT,
	TrainingDate DATE,	
	TrainingProgramName	VARCHAR(100),
	TrainingType VARCHAR(25),
	TrainingOutcome	VARCHAR(25),
	Locations VARCHAR(50),
	Trainer	VARCHAR(50),
	TrainingDurationDays INT,
	TrainingCost FLOAT,
	CONSTRAINT fk_employeeid FOREIGN KEY (EmployeeID) REFERENCES surveys_data(EmployeeID)

);

CREATE TABLE recruitments_data(
	ApplicantID	INT,
	ApplicationDate	DATE,
	FirstName VARCHAR(30),
	LastName VARCHAR(30),
	Gender VARCHAR(20),
	DateofBirth	VARCHAR(30),
	Email VARCHAR(100),
	Address	VARCHAR(100),
	City VARCHAR(50),
	State VARCHAR(20),
	ZipCode	INT,
	Country	VARCHAR(100),
	EducationLevel	VARCHAR(30),
	YearsofExperience INT,
	DesiredSalary FLOAT,
	JobTitle VARCHAR(100),
	Status VARCHAR(30),
	CONSTRAINT fk_application FOREIGN KEY (EmployeeID) REFERENCES employees_data(EmployeeID),
	CONSTRAINT fk_employeeid FOREIGN KEY (EmployeeID) REFERENCES trainings_data(EmployeeID)

);

CREATE TABLE surveys_data(
	EmployeeID INT,
	SurveyDate VARCHAR(30),
	EngagementScore	INT,
	SatisfactionScore INT,
	WorkLifeBalanceScore INT

);

SELECT * FROM employees_data;
SELECT * FROM recruitments_data;
SELECT * FROM surveys_data;
SELECT * FROM trainings_data;