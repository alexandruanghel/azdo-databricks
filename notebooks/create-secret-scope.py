# Databricks notebook source
# MAGIC %md
# MAGIC ### Get the API url and bearer token

# COMMAND ----------

import requests
 
API_URL = dbutils.notebook.entry_point.getDbutils().notebook().getContext().apiUrl().getOrElse(None)
TOKEN = dbutils.notebook.entry_point.getDbutils().notebook().getContext().apiToken().getOrElse(None)

# COMMAND ----------

# MAGIC %md
# MAGIC ### Create a Databricks Secret Scope

# COMMAND ----------

payload='{"scope": "'+dbutils.widgets.get("secretScope")+'"}'

response = requests.post(
  API_URL + '/api/2.0/secrets/scopes/create',
  headers={"Authorization": "Bearer " + TOKEN},
  data=payload
)

if response.status_code == 200:
  dbutils.notebook.exit("CREATED_SUCCESSFULLY")
else:
  if 'error_code' in response.json().keys() and response.json()['error_code'] == "RESOURCE_ALREADY_EXISTS":
    print("Full response payload: %s:" % (response.json()))
    dbutils.notebook.exit("RESOURCE_ALREADY_EXISTS")
  else:
    print("Full response payload: %s:" % (response.json()))
    raise Exception("ERROR: %s:" % (response.json()))
