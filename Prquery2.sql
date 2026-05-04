/*


Script 2: Analytical Queries (Data Warehouse)


Objective: Extract business intelligence from the 5-Dimension Star Schema 
           to answer the project hypotheses.

*/

USE HOIS;
GO

/*

Do lower star ratings actually correlate with worse readmissions?

*/

PRINT 'Star Ratings vs. Readmission Rates';

SELECT 
    dh.OverallRating,
    COUNT(DISTINCT dh.HospitalKey) AS TotalHospitals,
    CAST(AVG(fhq.DecimalScore) AS DECIMAL(5,2)) AS AvgReadmissionScore,
    MIN(fhq.DecimalScore) AS MinReadmissionScore,
    MAX(fhq.DecimalScore) AS MaxReadmissionScore
FROM dbo.Fact_HospitalQuality fhq
INNER JOIN dbo.Dim_Hospital dh 
    ON fhq.HospitalKey = dh.HospitalKey
INNER JOIN dbo.Dim_Measure dm 
    ON fhq.MeasureKey = dm.MeasureKey
WHERE dh.OverallRating IS NOT NULL
  AND dm.MeasureID = 'Hybrid_HWR'  
  AND fhq.DecimalScore IS NOT NULL
GROUP BY dh.OverallRating
ORDER BY dh.OverallRating DESC;
GO



/* Do hospitals with statistically worse readmission rates 
   also struggle with ER wait times?
*/


PRINT ' Readmission Performance vs. ER Wait Times';

WITH ReadmissionPerformance AS (
    SELECT 
        fhq.HospitalKey,
        fhq.ComparedToNational,
        CASE 
            WHEN fhq.ComparedToNational LIKE '%Worse%' THEN 'Underperforming (Worse than National)'
            ELSE 'Standard / Better' 
        END AS ReadmissionCohort
    FROM dbo.Fact_HospitalQuality fhq
    INNER JOIN dbo.Dim_Measure dm 
        ON fhq.MeasureKey = dm.MeasureKey
    WHERE dm.MeasureID = 'Hybrid_HWR'
      AND fhq.ComparedToNational IS NOT NULL
      AND fhq.ComparedToNational <> 'Not Available'
),
ERWaitTimes AS (
    SELECT 
        fhq.HospitalKey,
        fhq.IntegerScore AS ERWaitTime_Minutes
    FROM dbo.Fact_HospitalQuality fhq
    INNER JOIN dbo.Dim_Measure dm 
        ON fhq.MeasureKey = dm.MeasureKey
    WHERE dm.MeasureID = 'OP_18b'
      AND fhq.IntegerScore IS NOT NULL
)
SELECT 
    rp.ReadmissionCohort,
    COUNT(DISTINCT rp.HospitalKey) AS SampleSize,
    CAST(AVG(CAST(ew.ERWaitTime_Minutes AS DECIMAL(8,2))) AS DECIMAL(6,2)) AS AvgERWaitTime_Minutes
FROM ReadmissionPerformance rp
INNER JOIN ERWaitTimes ew 
    ON rp.HospitalKey = ew.HospitalKey
GROUP BY rp.ReadmissionCohort
ORDER BY AvgERWaitTime_Minutes DESC;
GO


/*Ownership Impact on Clinical Outcomes
*/

PRINT 'For Profit vs. Non Profit Readmissions';

SELECT 
    do.OwnershipType,
    COUNT(DISTINCT fhq.HospitalKey) AS TotalHospitals,
    CAST(AVG(fhq.DecimalScore) AS DECIMAL(5,2)) AS AvgReadmissionScore,
    MIN(fhq.DecimalScore) AS MinReadmissionScore,
    MAX(fhq.DecimalScore) AS MaxReadmissionScore
FROM dbo.Fact_HospitalQuality fhq
INNER JOIN dbo.Dim_Ownership do 
    ON fhq.OwnershipKey = do.OwnershipKey
INNER JOIN dbo.Dim_Measure dm 
    ON fhq.MeasureKey = dm.MeasureKey
WHERE dm.MeasureID = 'Hybrid_HWR'
  AND fhq.DecimalScore IS NOT NULL
  AND do.OwnershipType IS NOT NULL
GROUP BY do.OwnershipType
ORDER BY AvgReadmissionScore ASC;
GO


/* 
Operational Bottlenecks by Hospital Type (Rural vs. Acute)
*/
PRINT 'Running Analysis 4: ER Wait Times by Hospital Type';

SELECT 
    do.HospitalType,
    COUNT(DISTINCT fhq.HospitalKey) AS TotalHospitals,
    CAST(AVG(CAST(fhq.IntegerScore AS DECIMAL(8,2))) AS DECIMAL(6,2)) AS AvgERWaitTime_Minutes,
    MAX(fhq.IntegerScore) AS Worst_ERWaitTime
FROM dbo.Fact_HospitalQuality fhq
INNER JOIN dbo.Dim_Ownership do 
    ON fhq.OwnershipKey = do.OwnershipKey
INNER JOIN dbo.Dim_Measure dm 
    ON fhq.MeasureKey = dm.MeasureKey
WHERE dm.MeasureID = 'OP_18b'
  AND fhq.IntegerScore IS NOT NULL
  AND do.HospitalType IS NOT NULL
GROUP BY do.HospitalType
ORDER BY AvgERWaitTime_Minutes DESC;
GO



/*
Outlier Detection

 Filter for hospitals with high overall ratings but statistically 
 worse clinical outcomes based on CMS national comparisons.
 */

PRINT 'High Rating but Worse Readmissions';

SELECT 
    dh.FacilityID,
    dh.FacilityName,
    dl.[State],
    dh.OverallRating,
    fhq.DecimalScore AS ReadmissionScore,
    fhq.ComparedToNational
FROM dbo.Fact_HospitalQuality fhq
INNER JOIN dbo.Dim_Hospital dh 
    ON fhq.HospitalKey = dh.HospitalKey
INNER JOIN dbo.Dim_Measure dm 
    ON fhq.MeasureKey = dm.MeasureKey
INNER JOIN dbo.Dim_Location dl 
    ON fhq.LocationKey = dl.LocationKey
WHERE dm.MeasureID = 'Hybrid_HWR'
  AND dh.OverallRating >= 4 
  AND fhq.ComparedToNational LIKE '%Worse%'
ORDER BY dh.OverallRating DESC, fhq.DecimalScore DESC;
GO