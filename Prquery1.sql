/*

Project: Hospital Operations Intelligence System (HOIS)
Nikhil Shrivastava
Script 1
Objective: End-to-End Data Pipeline.

*/

USE HOIS; 
GO



/*
1. SCHEMA: OPERATIONAL DATA STORE (ODS)
*/


CREATE TABLE dbo.ODS_Hospitals (
    FacilityID VARCHAR(50) NOT NULL,
    FacilityName VARCHAR(200) NOT NULL,
    City VARCHAR(100) NULL,
    [State] VARCHAR(10) NOT NULL,
    ZipCode VARCHAR(20) NULL,
    County VARCHAR(100) NULL,
    HospitalType VARCHAR(100) NULL,
    OwnershipType VARCHAR(150) NULL,
    OverallRating INT NULL, 
    CONSTRAINT PK_ODS_Hospitals PRIMARY KEY (FacilityID)
);

CREATE TABLE dbo.ODS_Readmissions (
    ObservationID INT IDENTITY(1,1) NOT NULL,
    FacilityID VARCHAR(50) NOT NULL,
    MeasureID VARCHAR(50) NOT NULL,
    ComparedToNational VARCHAR(100) NULL,
    Score DECIMAL(8,2) NULL, 
    EndDate DATE NULL,
    CONSTRAINT PK_ODS_Readmissions PRIMARY KEY (ObservationID),
    CONSTRAINT FK_ODS_Readm_Hosp FOREIGN KEY (FacilityID) REFERENCES dbo.ODS_Hospitals(FacilityID)
);

CREATE TABLE dbo.ODS_ERWaitTimes (
    ObservationID INT IDENTITY(1,1) NOT NULL,
    FacilityID VARCHAR(50) NOT NULL,
    MeasureID VARCHAR(50) NOT NULL,
    WaitTimeMinutes INT NULL, 
    EndDate DATE NULL,
    CONSTRAINT PK_ODS_ERWaitTimes PRIMARY KEY (ObservationID),
    CONSTRAINT FK_ODS_ERWait_Hosp FOREIGN KEY (FacilityID) REFERENCES dbo.ODS_Hospitals(FacilityID)
);
GO


/*
2. SCHEMA: DATA WAREHOUSE (5 Dimensions and 1 Fact)
*/
PRINT 'Creating Data Warehouse Star Schema';

/*Dimension 1: Date */
CREATE TABLE dbo.Dim_Date (
    DateKey INT NOT NULL, FullDate DATE NOT NULL, [Year] INT NOT NULL,
    [Month] INT NOT NULL,
    Quarter INT NOT NULL,
    CONSTRAINT PK_Dim_Date PRIMARY KEY (DateKey)
);

/* Dimension 2: Hospital Demographic */
CREATE TABLE dbo.Dim_Hospital (
    HospitalKey INT IDENTITY(1,1) NOT NULL, FacilityID VARCHAR(50) NOT NULL, FacilityName VARCHAR(200) NOT NULL,
    OverallRating INT NULL,
    CONSTRAINT PK_Dim_Hospital PRIMARY KEY (HospitalKey)
);

/* Dimension 3: Geography / Location */
CREATE TABLE dbo.Dim_Location (
    LocationKey INT IDENTITY(1,1) NOT NULL,
    City VARCHAR(100) NULL,
    [State] VARCHAR(10) NOT NULL,
    ZipCode VARCHAR(20) NULL,
    County VARCHAR(100) NULL,
    CONSTRAINT PK_Dim_Location PRIMARY KEY (LocationKey)
);

/* Dimension 4: Hospital Ownership Attributes */
CREATE TABLE dbo.Dim_Ownership (
    OwnershipKey INT IDENTITY(1,1) NOT NULL,
    HospitalType VARCHAR(100) NULL,
    OwnershipType VARCHAR(150) NULL,
    CONSTRAINT PK_Dim_Ownership PRIMARY KEY (OwnershipKey)
);

/* Dimension 5: CMS Measure Catalog */
CREATE TABLE dbo.Dim_Measure (
    MeasureKey INT IDENTITY(1,1) NOT NULL,
    MeasureID VARCHAR(50) NOT NULL,
    MeasureName VARCHAR(200) NOT NULL,
    MetricCategory VARCHAR(50) NOT NULL,
    CONSTRAINT PK_Dim_Measure PRIMARY KEY (MeasureKey)
);

/* Central Fact Table */
CREATE TABLE dbo.Fact_HospitalQuality (
    FactKey INT IDENTITY(1,1) NOT NULL,
    DateKey INT NOT NULL,
    HospitalKey INT NOT NULL,
    LocationKey INT NOT NULL,
    OwnershipKey INT NOT NULL,
    MeasureKey INT NOT NULL,
    DecimalScore DECIMAL(8,2) NULL,      
    IntegerScore INT NULL,               
    ComparedToNational VARCHAR(100) NULL,
    CONSTRAINT PK_Fact_HospitalQuality PRIMARY KEY (FactKey),
    CONSTRAINT FK_Fact_Date FOREIGN KEY (DateKey) REFERENCES dbo.Dim_Date(DateKey),
    CONSTRAINT FK_Fact_Hospital FOREIGN KEY (HospitalKey) REFERENCES dbo.Dim_Hospital(HospitalKey),
    CONSTRAINT FK_Fact_Location FOREIGN KEY (LocationKey) REFERENCES dbo.Dim_Location(LocationKey),
    CONSTRAINT FK_Fact_Ownership FOREIGN KEY (OwnershipKey) REFERENCES dbo.Dim_Ownership(OwnershipKey),
    CONSTRAINT FK_Fact_Measure FOREIGN KEY (MeasureKey) REFERENCES dbo.Dim_Measure(MeasureKey)
);
GO



/*

3. STAGING & BULK INSERT

*/

CREATE TABLE dbo.stg_Hospital (
    FacilityID VARCHAR(100), FacilityName VARCHAR(300), [Address] VARCHAR(300), CityTown VARCHAR(100),
    [State] VARCHAR(50), ZIPCode VARCHAR(50), CountyParish VARCHAR(100), TelephoneNumber VARCHAR(50),
    HospitalType VARCHAR(150), HospitalOwnership VARCHAR(200), EmergencyServices VARCHAR(50),
    BirthingFriendly VARCHAR(50), OverallRating VARCHAR(50), OverallRatingFootnote VARCHAR(100),
    M1 VARCHAR(100), M2 VARCHAR(100), M3 VARCHAR(100), M4 VARCHAR(100), M5 VARCHAR(100), M6 VARCHAR(100),
    S1 VARCHAR(100), S2 VARCHAR(100), S3 VARCHAR(100), S4 VARCHAR(100), S5 VARCHAR(100), S6 VARCHAR(100),
    R1 VARCHAR(100), R2 VARCHAR(100), R3 VARCHAR(100), R4 VARCHAR(100), R5 VARCHAR(100), R6 VARCHAR(100),
    P1 VARCHAR(100), P2 VARCHAR(100), P3 VARCHAR(100), T1 VARCHAR(100), T2 VARCHAR(100), T3 VARCHAR(100)
);

CREATE TABLE dbo.stg_Readmission (
    FacilityID VARCHAR(100), FacilityName VARCHAR(300), [Address] VARCHAR(300), CityTown VARCHAR(100),
    [State] VARCHAR(50), ZIPCode VARCHAR(50), CountyParish VARCHAR(100), TelephoneNumber VARCHAR(50),
    MeasureID VARCHAR(100), MeasureName VARCHAR(400), ComparedToNational VARCHAR(150), Denominator VARCHAR(100),
    Score VARCHAR(100), LowerEstimate VARCHAR(100), HigherEstimate VARCHAR(100), NumberOfPatients VARCHAR(100),
    NumberReturned VARCHAR(100), Footnote VARCHAR(100), StartDate VARCHAR(50), EndDate VARCHAR(50)
);

CREATE TABLE dbo.stg_TimelyCare (
    FacilityID VARCHAR(100), FacilityName VARCHAR(300), [Address] VARCHAR(300), CityTown VARCHAR(100),
    [State] VARCHAR(50), ZIPCode VARCHAR(50), CountyParish VARCHAR(100), TelephoneNumber VARCHAR(50),
    Condition VARCHAR(150), MeasureID VARCHAR(150), MeasureName VARCHAR(400), Score VARCHAR(100),
    Sample VARCHAR(100), Footnote VARCHAR(100), StartDate VARCHAR(50), EndDate VARCHAR(50)
);


BULK INSERT dbo.stg_Hospital FROM 'C:\Data\Final Project\Hospital_Data\Hospital_General_Information.csv.csv' WITH (FORMAT = 'CSV', FIRSTROW = 2);
BULK INSERT dbo.stg_Readmission FROM 'C:\Data\Final Project\Hospital_Data\Unplanned_Hospital_Visits-Hospital.csv.csv' WITH (FORMAT = 'CSV', FIRSTROW = 2);
BULK INSERT dbo.stg_TimelyCare FROM 'C:\Data\Final Project\Hospital_Data\Timely_and_Effective_Care-Hospital.csv.csv' WITH (FORMAT = 'CSV', FIRSTROW = 2);
GO



/*
4. DATA CLEANSING
 */



INSERT INTO dbo.ODS_Hospitals (FacilityID, FacilityName, City, [State], ZipCode, County, HospitalType, OwnershipType, OverallRating)
SELECT 
    FacilityID, FacilityName, CityTown, [State], ZIPCode, CountyParish, HospitalType, HospitalOwnership,
    CASE WHEN OverallRating IN ('Not Available', '') THEN NULL ELSE TRY_CAST(OverallRating AS INT) END
FROM dbo.stg_Hospital;

INSERT INTO dbo.ODS_Readmissions (FacilityID, MeasureID, ComparedToNational, Score, EndDate)
SELECT 
    FacilityID, MeasureID, NULLIF(ComparedToNational, 'Not Available'), 
    TRY_CAST(NULLIF(Score, 'Not Available') AS DECIMAL(8,2)),
    TRY_CAST(NULLIF(EndDate, 'Not Available') AS DATE)
FROM dbo.stg_Readmission
WHERE MeasureID = 'Hybrid_HWR' AND FacilityID IN (SELECT FacilityID FROM dbo.ODS_Hospitals);

INSERT INTO dbo.ODS_ERWaitTimes (FacilityID, MeasureID, WaitTimeMinutes, EndDate)
SELECT 
    FacilityID, MeasureID, TRY_CAST(NULLIF(Score, 'Not Available') AS INT),
    TRY_CAST(NULLIF(EndDate, 'Not Available') AS DATE)
FROM dbo.stg_TimelyCare
WHERE MeasureID = 'OP_18b' AND FacilityID IN (SELECT FacilityID FROM dbo.ODS_Hospitals);
GO



/*  5. ETL: LOAD DATA WAREHOUSE DIMENSIONS */

PRINT 'Executing ETL: Loading Dimensions';

/*   Generating Dim_Date (2020 to 2025) */

WITH DateCTE AS (
    SELECT CAST('2020-01-01' AS DATE) AS d
    UNION ALL
    SELECT DATEADD(DAY, 1, d) FROM DateCTE WHERE d < '2025-12-31'
)
INSERT INTO dbo.Dim_Date (DateKey, FullDate, [Year], [Month], Quarter)
SELECT 
    CAST(CONVERT(VARCHAR(8), d, 112) AS INT), d, YEAR(d), MONTH(d), DATEPART(QUARTER, d)
FROM DateCTE OPTION (MAXRECURSION 3000);


INSERT INTO dbo.Dim_Hospital (FacilityID, FacilityName, OverallRating)
SELECT FacilityID, FacilityName, OverallRating FROM dbo.ODS_Hospitals;


INSERT INTO dbo.Dim_Location (City, [State], ZipCode, County)
SELECT DISTINCT City, [State], ZipCode, County FROM dbo.ODS_Hospitals WHERE City IS NOT NULL;

/*   Loading Dim_Ownership (Unique Business Models) */
INSERT INTO dbo.Dim_Ownership (HospitalType, OwnershipType)
SELECT DISTINCT HospitalType, OwnershipType FROM dbo.ODS_Hospitals WHERE HospitalType IS NOT NULL;

INSERT INTO dbo.Dim_Measure (MeasureID, MeasureName, MetricCategory)
VALUES 
    ('Hybrid_HWR', 'Hospital-Wide All-Cause Readmission', 'Readmission'),
    ('OP_18b', 'Median Time Spent in Emergency Department', 'TimelyCare');
GO


/* 

6. ETL: LOAD DATA WAREHOUSE FACT TABLE 

*/

PRINT 'Executing ETL: Loading Fact Table via INNER JOINs';

INSERT INTO dbo.Fact_HospitalQuality (DateKey, HospitalKey, LocationKey, OwnershipKey, MeasureKey, DecimalScore, ComparedToNational)
SELECT 
    ISNULL(CAST(CONVERT(VARCHAR(8), r.EndDate, 112) AS INT), 20240101),
    dh.HospitalKey, 
    dl.LocationKey, 
    do.OwnershipKey, 
    dm.MeasureKey, 
    r.Score, 
    r.ComparedToNational
FROM dbo.ODS_Readmissions r
INNER JOIN dbo.ODS_Hospitals oh ON r.FacilityID = oh.FacilityID
INNER JOIN dbo.Dim_Hospital dh ON oh.FacilityID = dh.FacilityID
INNER JOIN dbo.Dim_Location dl ON oh.City = dl.City AND oh.[State] = dl.[State]
INNER JOIN dbo.Dim_Ownership do ON oh.HospitalType = do.HospitalType AND oh.OwnershipType = do.OwnershipType
INNER JOIN dbo.Dim_Measure dm ON r.MeasureID = dm.MeasureID;

/* ER Wait Times */
INSERT INTO dbo.Fact_HospitalQuality (DateKey, HospitalKey, LocationKey, OwnershipKey, MeasureKey, IntegerScore)
SELECT 
    ISNULL(CAST(CONVERT(VARCHAR(8), w.EndDate, 112) AS INT), 20240101),
    dh.HospitalKey, 
    dl.LocationKey, 
    do.OwnershipKey, 
    dm.MeasureKey, 
    w.WaitTimeMinutes
FROM dbo.ODS_ERWaitTimes w
INNER JOIN dbo.ODS_Hospitals oh ON w.FacilityID = oh.FacilityID
INNER JOIN dbo.Dim_Hospital dh ON oh.FacilityID = dh.FacilityID
INNER JOIN dbo.Dim_Location dl ON oh.City = dl.City AND oh.[State] = dl.[State]
INNER JOIN dbo.Dim_Ownership do ON oh.HospitalType = do.HospitalType AND oh.OwnershipType = do.OwnershipType
INNER JOIN dbo.Dim_Measure dm ON w.MeasureID = dm.MeasureID;
GO



/*
7. CLEANUP
*/
PRINT 'Dropping temporary staging tables';
DROP TABLE dbo.stg_Hospital;
DROP TABLE dbo.stg_Readmission;
DROP TABLE dbo.stg_TimelyCare;

PRINT 'End-to-End 5-Dimension Pipeline Execution';
GO