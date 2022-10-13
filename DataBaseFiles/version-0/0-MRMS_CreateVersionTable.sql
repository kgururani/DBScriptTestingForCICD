USE [BACMRMQA]
GO

/****** Object:  Table [dbo].[USERS]    Script Date: 7/28/2022 3:17:43 PM *****/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PIPELINE_CICD_CODE_VERSION](
	[CURRENT_VERSION] [nvarchar](250) NOT NULL,
	[SUB_VERSION] [nvarchar](250) NOT NULL,
	)

GO

INSERT INTO [dbo].[PIPELINE_CICD_CODE_VERSION]
           ([CURRENT_VERSION]
           ,[SUB_VERSION])])
		   
     VALUES
           ('0'
           ,'0')
           
GO