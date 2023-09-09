# Databricks notebook source
# MAGIC %md
# MAGIC # Bronze pipeline

# COMMAND ----------

# MAGIC %md
# MAGIC #### Set widgets

# COMMAND ----------

dbutils.widgets.removeAll()

# COMMAND ----------

dbutils.widgets.text("sourcePath", "/databricks-datasets/weather/high_temps")
dbutils.widgets.text("bronzeTable", "default.bronze")

# COMMAND ----------

sourcePath = dbutils.widgets.get("sourcePath")
bronzeTable = dbutils.widgets.get("bronzeTable")

# COMMAND ----------

# MAGIC %md
# MAGIC #### Check source data

# COMMAND ----------

dbutils.fs.ls(sourcePath)

# COMMAND ----------

# MAGIC %md
# MAGIC #### Read source data

# COMMAND ----------

csvDF = (
    spark.read.option(  # The DataFrameReader
        "header", "true"
    )  # Use first line of all files as header
    .option("sep", ",")  # Use comma delimiter (default)
    .option("inferSchema", "true")  # Automatically infer schema
    .csv(sourcePath)  # Creates a DataFrame from CSV after reading in the file(s)
)

# COMMAND ----------

csvDF.printSchema()

# COMMAND ----------

display(csvDF.limit(5))

# COMMAND ----------

# MAGIC %md
# MAGIC #### Write to Delta Bronze table

# COMMAND ----------

(csvDF.write.format("delta").mode("append").saveAsTable(bronzeTable))

# COMMAND ----------

# MAGIC %md
# MAGIC #### Optimize Delta table

# COMMAND ----------

spark.sql("OPTIMIZE {}".format(bronzeTable))

# COMMAND ----------

# MAGIC %md
# MAGIC #### Verify Delta table

# COMMAND ----------

display(spark.sql("DESCRIBE DETAIL {}".format(bronzeTable)))

# COMMAND ----------

display(spark.sql("SELECT COUNT(*) FROM {}".format(bronzeTable)))
