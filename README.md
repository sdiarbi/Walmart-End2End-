# 🛒 Walmart Analytics dbt Project

This repository contains the dbt transformation pipelines for processing raw Walmart retail datasets from Snowflake into structured analytics layers (SCD1 & SCD2) ready for Power BI reporting.

## 🏗️ Architecture & Data Lineage

- **Raw Layer (Snowflake)**: Ingested raw source data tables residing in `WALMART_DB`.
- **Bronze Layer (`/models/staging`)**: Data ingestion, field renaming, and type casting (`stg_fact`, `stg_department`, `stg_stores`).
- **Silver Layer (`/models/silver` / `/snapshots`)**: Intermediate joins, business logic, surrogate key generation, and Slowly Changing Dimension (SCD Type 1 & SCD Type 2) versioning.
- **Gold Layer (`/models/gold`)**: Final dimension (`walmart_store_dim`, `walmart_date_dim`) and fact tables (`walmart_fact_table`) modeled for BI consumption.

## 🚀 Quick Start & Environment

- **Data Warehouse**: Snowflake (`WALMART_DB`)
- **Orchestration**: dbt Cloud IDE
- **dbt Version**: v1.8+ / v2 Stable
- **BI & Analytics**: Power BI (Star Schema / Composite Keys)

## 📊 Key Models & Data Architecture

- **SCD Type 1 Dimensions (Upsert)**: 
  - `walmart_date_dim.sql` — Calendar metrics & holiday tracking (`DATE_ID` PK).
  - `walmart_store_dim.sql` — Store types & size classifications (`STORE_ID`, `DEPT_ID` composite PK).
- **SCD Type 2 Fact Table (Versioned)**: 
  - `walmart_fact_table.sql` — Weekly sales, fuel prices, CPI, and temperature metrics versioned with `VRSN_START_DATE` and `VRSN_END_DATE`.
