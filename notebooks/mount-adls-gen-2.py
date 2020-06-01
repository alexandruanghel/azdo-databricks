# Databricks notebook source
# MAGIC %md
# MAGIC ### Get the API url and bearer token

# COMMAND ----------

import requests

API_URL = dbutils.notebook.entry_point.getDbutils().notebook().getContext().apiUrl().getOrElse(None)
TOKEN = dbutils.notebook.entry_point.getDbutils().notebook().getContext().apiToken().getOrElse(None)

# COMMAND ----------

# MAGIC %md
# MAGIC ### Set mount config

# COMMAND ----------

configs = {
  "fs.azure.account.auth.type": "OAuth",
  "fs.azure.account.oauth.provider.type": "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
  "fs.azure.account.oauth2.client.id": dbutils.secrets.get(scope = dbutils.widgets.get("secretScopeName"), key = dbutils.widgets.get("spClientIdKeyName")),
  "fs.azure.account.oauth2.client.secret": dbutils.secrets.get(scope = dbutils.widgets.get("secretScopeName"), key = dbutils.widgets.get("spClientSecretKeyName")),
  "fs.azure.account.oauth2.client.endpoint": "https://login.microsoftonline.com/"+dbutils.widgets.get("tenantId")+"/oauth2/token"
}

# COMMAND ----------

# MAGIC %md
# MAGIC ### Mount with the config

# COMMAND ----------

mountPoint="/mnt/"+dbutils.widgets.get("storageAccountName")+"-"+dbutils.widgets.get("storageContainerName")
mountSource="abfss://"+dbutils.widgets.get("storageContainerName")+"@"+dbutils.widgets.get("storageAccountName")+".dfs.core.windows.net/"

if mountPoint not in list(map(lambda m: m.mountPoint, dbutils.fs.mounts())):
  spark.conf.set("fs.azure.createRemoteFileSystemDuringInitialization", "true")
  dbutils.fs.mount(
    source = mountSource,
    mount_point = mountPoint,
    extra_configs = configs
  )
else:
  print("Already mounted")

# COMMAND ----------

# MAGIC %md
# MAGIC ### Exit notebook

# COMMAND ----------

dbutils.notebook.exit('{"mountSource": "'+mountSource+'", "mountPoint": "'+mountPoint+'"}')
