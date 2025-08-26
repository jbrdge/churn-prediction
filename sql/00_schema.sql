-- schema_and_clean.sql

-- Create DB and base table
CREATE DATABASE IF NOT EXISTS churn_project;
USE churn_project;

DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
  customerID        VARCHAR(20) PRIMARY KEY,
  gender            VARCHAR(10),
  SeniorCitizen     TINYINT,
  Partner           VARCHAR(10),
  Dependents        VARCHAR(10),
  tenure            INT,
  PhoneService      VARCHAR(10),
  MultipleLines     VARCHAR(30),
  InternetService   VARCHAR(30),
  OnlineSecurity    VARCHAR(30),
  OnlineBackup      VARCHAR(30),
  DeviceProtection  VARCHAR(30),
  TechSupport       VARCHAR(30),
  StreamingTV       VARCHAR(30),
  StreamingMovies   VARCHAR(30),
  Contract          VARCHAR(30),
  PaperlessBilling  VARCHAR(10),
  PaymentMethod     VARCHAR(50),
  MonthlyCharges    DECIMAL(10,2),
  TotalCharges      VARCHAR(20),  -- loaded as text first; we clean next to handle nulls
  Churn             VARCHAR(10)
);