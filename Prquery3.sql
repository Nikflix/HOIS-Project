/*
Script 3
Objective: Implement a SQL Graph database architecture to model a simulated 
           Patient Transfer Network, demonstrating MATCH() capabilities.
*/

USE HOIS;
GO



/* 
GRAPH NODES & EDGES
*/
PRINT 'Creating Graph Schema';


CREATE TABLE dbo.Node_Facility (
    FacilityID VARCHAR(50) NOT NULL,
    FacilityName VARCHAR(200) NOT NULL,
    [State] VARCHAR(10) NOT NULL,
    OverallRating INT NULL,
    CONSTRAINT PK_Node_Facility PRIMARY KEY CLUSTERED (FacilityID)
) AS NODE;


CREATE TABLE dbo.Edge_PatientTransfer (
    TransferReason VARCHAR(100) NOT NULL,
    SimulatedDistanceMiles INT NULL
) AS EDGE;
GO


/*
POPULATE THE GRAPH
*/
PRINT 'Populating Graph Nodes';

INSERT INTO dbo.Node_Facility (FacilityID, FacilityName, [State], OverallRating)
SELECT FacilityID, FacilityName, [State], OverallRating 
FROM dbo.ODS_Hospitals;

PRINT 'Edge Relationships ';

INSERT INTO dbo.Edge_PatientTransfer ($from_id, $to_id, TransferReason, SimulatedDistanceMiles)
SELECT 
    fromNode.$node_id, 
    toNode.$node_id, 
    'Critical Care Escalation',
    CAST(RAND(CHECKSUM(NEWID())) * 60 AS INT) + 10 
FROM dbo.Node_Facility fromNode
INNER JOIN dbo.Node_Facility toNode 
    ON fromNode.[State] = toNode.[State] 
    AND fromNode.OverallRating <= 2     
    AND toNode.OverallRating >= 4       
WHERE fromNode.FacilityID <> toNode.FacilityID;
GO


/*
QUERYING THE GRAPH WITH MATCH()
*/
SELECT 
    h_from.FacilityName AS ReferringHospital,
    h_from.OverallRating AS ReferringRating,
    h_from.[State] AS Region,
    e.TransferReason,
    e.SimulatedDistanceMiles,
    h_to.FacilityName AS ReceivingHubHospital,
    h_to.OverallRating AS ReceivingRating
FROM dbo.Node_Facility h_from,           
     dbo.Edge_PatientTransfer e,         
     dbo.Node_Facility h_to              
WHERE MATCH(h_from-(e)->h_to)
ORDER BY h_from.[State] ASC, e.SimulatedDistanceMiles DESC;
GO