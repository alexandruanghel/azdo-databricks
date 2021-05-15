# Databricks notebook source
# MAGIC %md
# MAGIC # Silver pipeline

# COMMAND ----------

# MAGIC %md
# MAGIC #### Set widgets

# COMMAND ----------

dbutils.widgets.text("bronzeTable", "default.bronze")
dbutils.widgets.text("silverTable", "default.silver")

# COMMAND ----------

bronzeTable = dbutils.widgets.get("bronzeTable")
silverTable = dbutils.widgets.get("silverTable")

# COMMAND ----------

# MAGIC %md
# MAGIC #### Check Bronze table

# COMMAND ----------

display(spark.sql("DESCRIBE DETAIL {}".format(bronzeTable)))

# COMMAND ----------

# MAGIC %md
# MAGIC #### Read Bronze table

# COMMAND ----------

bronzeDF = spark.read.table(bronzeTable)

# COMMAND ----------

bronzeDF.printSchema()

# COMMAND ----------

# MAGIC %md
# MAGIC #### Transform Bronze data

# COMMAND ----------

from pyspark.sql import functions as F

transformedDF = (bronzeDF
  .withColumnRenamed("temp", "temperature")
  .withColumn("date", F.to_date(F.col("date"), "yyyy-MM-dd"))
)

# COMMAND ----------

# MAGIC %md
# MAGIC #### Create the Delta Silver table if not exists

# COMMAND ----------

(transformedDF
  .limit(0)
  .write
  .format("delta")
  .mode("ignore")
  .saveAsTable(silverTable)
)

# COMMAND ----------

# MAGIC %md
# MAGIC #### Write to Delta Silver table
# MAGIC Using `MERGE` to avoid duplicates

# COMMAND ----------

from delta.tables import *

deltaSilverTable = DeltaTable.forName(spark, silverTable)

(deltaSilverTable.alias("silver").merge(
    transformedDF.alias("updates"),
    "silver.date = updates.date")
  .whenNotMatchedInsertAll()
  .execute()
)

# COMMAND ----------

# MAGIC %md
# MAGIC #### Optimize Delta table

# COMMAND ----------

spark.sql("OPTIMIZE {}".format(silverTable))

# COMMAND ----------

# MAGIC %md
# MAGIC #### Verify Delta table

# COMMAND ----------

display(spark.sql("DESCRIBE DETAIL {}".format(silverTable)))

# COMMAND ----------

display(spark.sql("SELECT COUNT(*) FROM {}".format(silverTable)))

# COMMAND ----------
