USE [BACMRMQA]
GO

/****** Object:  Table [dbo].[USERS]    Script Date: 7/28/2022 3:17:43 PM *******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PIPELINE_CICD_CODE_VERSION](
	[PREVIOUS_VERSION] [nvarchar](250) NOT NULL,
	[CURRENT_VERSION] [nvarchar](250) NOT NULL,
	[LAST_EXECUTED_CURRENT_FILE_VERSION] [nvarchar](250) NOT NULL,
	[TIMESTAMP] [nvarchar](250) NOT NULL,
	[MESSAGE] [nvarchar](250) NOT NULL
	)

GO

CREATE TABLE [dbo].[PIPELINE_CICD_VERSION_LOGS](
	[VERSIONS] [nvarchar](250) UNIQUE NOT NULL,
	[LAST_EXECUTED_VERSION] [nvarchar](250) NOT NULL
	)
GO

INSERT INTO [dbo].[PIPELINE_CICD_CODE_VERSION]
           ([PREVIOUS_VERSION]
	   ,[CURRENT_VERSION]
	   ,[LAST_EXECUTED_CURRENT_FILE_VERSION]
	   ,[TIMESTAMP]
	   ,[MESSAGE])
		   
     VALUES
           ('0'
			,'0'
			,'0'
			,CURRENT_TIMESTAMP
			,''
		)
           
GO
