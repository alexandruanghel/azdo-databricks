# Databricks notebook source
# MAGIC %md
# MAGIC ### Show current user (API method)

# COMMAND ----------

# MAGIC %md
# MAGIC ##### Get the API url and bearer token

# COMMAND ----------

API_URL = dbutils.notebook.entry_point.getDbutils().notebook().getContext().apiUrl().getOrElse(None)
TOKEN = dbutils.notebook.entry_point.getDbutils().notebook().getContext().apiToken().getOrElse(None)

# COMMAND ----------

# MAGIC %md
# MAGIC ##### Call the SCIM API

# COMMAND ----------

import requests
import pprint

response = requests.get(
    API_URL + '/api/2.0/preview/scim/v2/Me',
    headers={"Authorization": "Bearer " + TOKEN}
)

if response.status_code == 200:
    pprint.pprint(response.json())
    userName = response.json()["userName"]
    print(userName)
else:
    print("Error: %s: %s" % (response.json()["error_code"], response.json()["message"]))

# COMMAND ----------

# MAGIC %md
# MAGIC ### Show current user (SQL method)

# COMMAND ----------

spark.conf.set("spark.databricks.userInfoFunctions.enabled", True)
userName = spark.sql("SELECT current_user as user").collect()[0].user

print(userName)

# COMMAND ----------

# MAGIC %md
# MAGIC ### Exit notebook with a value

# COMMAND ----------

dbutils.notebook.exit(userName)
