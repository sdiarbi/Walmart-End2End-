# Walmart End-to-End Data Engineering & BI Pipeline

An end-to-end Data Engineering and Business Intelligence pipeline built to ingest Walmart store sales, metadata, and macroeconomic indicators from **AWS S3** into **Snowflake**, transform data using **dbt (Medallion Architecture)**, and expose analytics-ready dimensional models for **Python** and **Tableau**[cite: 2, 8, 16].

---

## Table of Contents
1. [Architecture & Tech Stack](#architecture--tech-stack)
2. [Repository Structure](#repository-structure)
3. [Step 1: Snowflake Infrastructure & Ingestion](#step-1-snowflake-infrastructure--ingestion)
4. [Step 2: Role-Based Access Control (RBAC) Setup](#step-2-role-based-access-control-rbac-setup)
5. [Step 3: dbt Environment Configuration](#step-3-dbt-environment-configuration)
6. [Step 4: Medallion Modeling Layer Implementation](#step-4-medallion-modeling-layer-implementation)
7. [Step 5: Macros & Warehouse Optimization](#step-5-macros--warehouse-optimization)
8. [Step 6: Data Quality Testing & Validation](#step-6-data-quality-testing--validation)
9. [Step 7: Business Intelligence & Reporting](#step-7-business-intelligence--reporting)

---

## Architecture & Tech Stack

```text
┌─────────────────┐       ┌─────────────────────────┐       ┌───────────────────────────────────────────────────┐
│                 │       │        SNOWFLAKE        │       │                        dbt                        │
│   AWS S3 Bucket ├──────►│   RAW (BRONZE LAYER)    ├──────►│               SILVER LAYER (INT)                  │
│   (Raw Files)   │       │ FACT | STORES | DEPT    │       │     Datatype Cleaning, Null Parsing & Joins       │
└─────────────────┘       └─────────────────────────┘       └─────────────────────────┬─────────────────────────┘
                                                                                      │
                                                                                      ▼
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                              GOLD LAYER (MARTS)                                              │
│               walmart_date_dim (SCD1) | walmart_store_dim (SCD1) | walmart_fact_table (SCD2)                 │
└──────────────────────────────────────────────────────┬───────────────────────────────────────────────────────┘
                                                       │
                                                       ▼
                                     ┌───────────────────────────────────┐
                                     │      BI & REPORTING LAYER         │
                                     │   Python Viz (Plotly) / Tableau   │
                                     └───────────────────────────────────┘
```
---

## Repository Structure

```text
dbt_walmart_e2e_project/
├── .gitignore                        # Git exclusion file[cite: 15]
├── dbt_project.yml                   # Core dbt project settings and schema configs
├── packages.yml                      # dbt external package dependencies
├── package-lock.yml                  # Locked package versions (`dbt_utils` v0.8.0)[cite: 17]
├── README.md                         # End-to-end documentation
├── macros/
│   ├── generate_schema_name.sql     # Macro for explicit custom schema assignment
│   └── query_tag.sql                 # Session query tagging for cost/performance monitoring
└── models/
    ├── bronze/                       # Bronze Layer: Direct staging views over RAW[cite: 16]
    │   ├── bronze.yml                # Source metadata mapping to WALMART_DB.RAW
    │   ├── stg_department.sql        # Department weekly sales staging
    │   ├── stg_fact.sql              # Macroeconomic indicators staging
    │   └── stg_stores.sql            # Store physical metadata staging
    ├── silver/                       # Silver Layer: Intermediate cleansed/joined view[cite: 16]
    │   ├── silver.yml                # Silver schema documentation and key tests
    │   └── int_walmart_sales_joined.sql # Intermediate table joining facts and stores
    └── gold/                         # Gold Layer: Star-schema production marts[cite: 16]
        ├── gold.yml                  # Gold schema documentation and validation tests
        ├── walmart_date_dim.sql      # Date dimension table (SCD1)[cite: 8, 9]
        ├── walmart_store_dim.sql     # Store & department dimension table (SCD1)[cite: 8, 11]
        └── walmart_fact_table.sql    # Central transactional sales fact table (SCD2)[cite: 8, 10]        
```
---

## Step 1: Snowflake Infrastructure & Ingestion
```text
Run the following SQL script in Snowflake as ACCOUNTADMIN to set up the database, S3 integration, and raw landing tables:

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

-- Database and Schema Setup
CREATE OR REPLACE DATABASE WALMART_DB;
CREATE OR REPLACE SCHEMA WALMART_DB.RAW;

-- External S3 Storage Integration
CREATE OR REPLACE STORAGE INTEGRATION WALMART_INT
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'S3'
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::568318157863:role/walmart_mysnowflakerole'
    STORAGE_ALLOWED_LOCATIONS = ('s3://walmart-data-e2e-sd/data/');

DESC INTEGRATION WALMART_INT;

-- Create External Stage
CREATE OR REPLACE STAGE WALMART_DB.RAW.WALMART_STAGE
    STORAGE_INTEGRATION = WALMART_INT
    URL = 's3://walmart-data-e2e-sd/data/';

-- CSV File Format Definition
CREATE OR REPLACE FILE FORMAT MY_CSV_FORMAT
  TYPE = CSV
  FIELD_DELIMITER = ','
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  SKIP_HEADER = 1
  NULL_IF = ('NULL', 'null')
  EMPTY_FIELD_AS_NULL = true;

-- Raw Table Ingestion
CREATE OR REPLACE TABLE WALMART_DB.RAW.FACT (
    STORE VARCHAR, DATE VARCHAR, TEMPERATURE VARCHAR, FUEL_PRICE VARCHAR,
    MARKDOWN1 VARCHAR, MARKDOWN2 VARCHAR, MARKDOWN3 VARCHAR, MARKDOWN4 VARCHAR,
    MARKDOWN5 VARCHAR, CPI VARCHAR, UNEMPLOYMENT VARCHAR, ISHOLIDAY VARCHAR
);

COPY INTO WALMART_DB.RAW.FACT
FROM @WALMART_DB.RAW.WALMART_STAGE
FILES = ('fact.csv')
FILE_FORMAT = (FORMAT_NAME = 'MY_CSV_FORMAT')
ON_ERROR = 'SKIP_FILE';

CREATE OR REPLACE TABLE WALMART_DB.RAW.DEPARTMENT (
    STORE VARCHAR, DEPT VARCHAR, DATE VARCHAR, WEEKLY_SALES VARCHAR, ISHOLIDAY VARCHAR
);

COPY INTO WALMART_DB.RAW.DEPARTMENT
FROM @WALMART_DB.RAW.WALMART_STAGE
FILES = ('department.csv')
FILE_FORMAT = (FORMAT_NAME = 'MY_CSV_FORMAT')
ON_ERROR = 'SKIP_FILE';

CREATE OR REPLACE TABLE WALMART_DB.RAW.STORES (
    STORE VARCHAR, TYPE VARCHAR, SIZE VARCHAR
);

COPY INTO WALMART_DB.RAW.STORES
FROM @WALMART_DB.RAW.WALMART_STAGE
FILES = ('stores.csv')
FILE_FORMAT = (FORMAT_NAME = 'MY_CSV_FORMAT')
ON_ERROR = 'SKIP_FILE';
```

---

## Step 2: Role-Based Access Control (RBAC) Setup
```text
Provision necessary access grants for the dbt execution role (PC_DBT_ROLE):

GRANT USAGE, CREATE SCHEMA ON DATABASE WALMART_DB TO ROLE PC_DBT_ROLE;

GRANT USAGE ON SCHEMA WALMART_DB.RAW TO ROLE PC_DBT_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA WALMART_DB.RAW TO ROLE PC_DBT_ROLE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA WALMART_DB.RAW TO ROLE PC_DBT_ROLE;

CREATE SCHEMA IF NOT EXISTS WALMART_DB.BRONZE;
GRANT ALL PRIVILEGES ON SCHEMA WALMART_DB.BRONZE TO ROLE PC_DBT_ROLE;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA WALMART_DB.BRONZE TO ROLE PC_DBT_ROLE;
GRANT ALL PRIVILEGES ON ALL VIEWS IN SCHEMA WALMART_DB.BRONZE TO ROLE PC_DBT_ROLE;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA WALMART_DB.BRONZE TO ROLE PC_DBT_ROLE;
GRANT ALL PRIVILEGES ON FUTURE VIEWS IN SCHEMA WALMART_DB.BRONZE TO ROLE PC_DBT_ROLE;
```





