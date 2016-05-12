powershell -command .\scriptdb.ps1 -server . -user sa -pwd 123 -dbname SGMODEL_DW -outfile InitSchemaDw 
powershell -command .\scriptdb.ps1 -server . -user sa -pwd 123 -dbname SGMODEL_HQ -outfile InitSchemaHq
powershell -command .\scriptdb.ps1 -server . -user sa -pwd 123 -dbname SGMODEL_STORE -outfile InitSchemaStore
