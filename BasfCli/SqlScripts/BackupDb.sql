﻿BACKUP DATABASE [{{DBNAME}}] TO  
	DISK = N' {{BACKUPFILENAME}}' 
	WITH  
		FORMAT, 
		INIT,  
		SKIP, 
		NOREWIND, 
		NOUNLOAD