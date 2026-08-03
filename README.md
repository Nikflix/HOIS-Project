Hospital Operations Intelligence System (HOIS)

Overview

The Hospital Operations Intelligence System (HOIS) is an end-to-end data engineering and business intelligence project. It evaluates the operational realities behind public healthcare ratings provided by the Centers for Medicare & Medicaid Services (CMS).

While CMS provides a consumer-facing 5-star rating system, this project investigates whether these overarching ratings accurately reflect specific clinical outcomes (such as patient readmission rates) and operational bottlenecks (such as emergency room wait times).

Architecture

This project implements a robust data pipeline utilizing a local SQL Server instance:

Staging & ODS: Extracts raw, denormalized government CSV data and cleanses it into a 3rd Normal Form (3NF) Operational Data Store (ODS).

Data Warehouse: Transforms the ODS data into a 5-Dimension Star Schema optimized for analytical queries in Power BI.

Graph Database POC: Utilizes SQL Server Graph capabilities (Nodes and Edges) to model regional patient transfer pathways and critical care escalations.

Key Findings

The Star Rating Reality: 1-star hospitals have an average readmission rate of 15.69, while 5-star hospitals maintain a rate of 14.52—an 8% performance gap validating the baseline rating system.

The "Illusion" Hospitals: 368 hospitals are rated 4 or 5 stars by CMS but perform statistically worse than the national average for readmissions (including major facilities like Rush University).

The Geographic Divide: Urban Acute Care hospitals average 190 minutes in ER wait times, compared to just 116 minutes for rural Critical Access hospitals.

The Ownership Impact: Physician-owned hospitals have the lowest readmission rates (14.52), while Government-State hospitals have the highest (15.28).

<img width="1350" height="784" alt="image" src="https://github.com/user-attachments/assets/d081acda-d13b-478a-8ec5-ef37ea06b725" />

Tech Stack

Database: Microsoft SQL Server (T-SQL, Graph DB)

Data Visualization: Power BI

Languages: SQL

Repository Contents

Prquery1.sql: Data Pipeline (Staging, ODS, and Star Schema creation)

Prquery2.sql: Analytical Queries answering core business hypotheses

Prquery3.sql: Advanced Graph Database Proof of Concept

HOIS_Final_Report.pdf/docx: Comprehensive 9-page technical analysis

HOIS_Dashboard.pbix: Interactive Power BI dashboard
