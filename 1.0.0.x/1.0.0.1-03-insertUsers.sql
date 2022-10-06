USE [BACMRMQA]
GO

INSERT INTO [dbo].[PIPELINE_CICD_TESTING]
           ([FIRST_NAME]
           ,[LAST_NAME]
           ,[EMAIL_ID]
           ,[USER_NAME]
           ,[USER_TYPE]
           ,[PASSWORD]
           ,[PASSWORD_1]
           ,[PASSWORD_2]
           ,[PASSWORD_3]
           ,[PASSWORD_4]
           ,[PASSWORD_5]
           ,[STATUS]
           ,[LAST_LOGIN_DATE]
           ,[LAST_PASSWORD_DATE]
           ,[UPDATED_BY]
           ,[UPDATED_DATE]
           ,[ATTEMPT_COUNT]
           ,[SAML_ENABLED]
           ,[MFA_ENABLED]
           ,[OTP]
           ,[OTP_REQUESTED_TIME]
		   ,[CURRENT_VERSION])
		   
     VALUES
           ('Azure2'
           ,'Testing2'
           ,'kgururani@deloitte.com'
           ,'tester2'
           ,'U'
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,'Active'
           ,'2022-07-08 08:20:19.000'
           ,'2020-07-28 03:13:54.000'
           ,'1'
           ,'2022-05-13 08:20:19.000'
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
		   ,'1')
		   
GO

UPDATE [dbo].[PIPELINE_CICD_TESTING]
SET CURRENT_VERSION = '1.0.0.1';
