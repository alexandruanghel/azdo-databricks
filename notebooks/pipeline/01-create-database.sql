-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Create Database

-- COMMAND ----------

-- MAGIC %md
-- MAGIC #### Set widgets

-- COMMAND ----------

CREATE WIDGET TEXT DATABASE_NAME DEFAULT "default";
CREATE WIDGET TEXT DATABASE_LOCATION DEFAULT "dbfs:/user/hive/warehouse"

-- COMMAND ----------

-- MAGIC %md
-- MAGIC #### Create database

-- COMMAND ----------

CREATE DATABASE IF NOT EXISTS $DATABASE_NAME LOCATION '$DATABASE_LOCATION'

-- COMMAND ----------

-- MAGIC %md
-- MAGIC #### Verify database

-- COMMAND ----------

DESCRIBE DATABASE EXTENDED $DATABASE_NAME
