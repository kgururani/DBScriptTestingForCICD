USE [BACMRMQA]
GO

INSERT INTO [dbo].[PIPELINE_CICD_TESTING]
           ([FIRST_NAME]
           ,[LAST_NAME]
           ,[EMAIL_ID]
           ,[CURRENT_VERSION])
		   
     VALUES
           ('Azure1'
           ,'Testing1'
           ,'kgururani@deloitte.com'
           ,'1')
		   
GO

UPDATE [dbo].[PIPELINE_CICD_TESTING]
SET CURRENT_VERSION = '1'
