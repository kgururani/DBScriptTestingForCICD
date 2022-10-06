USE [BACMRMQA]
GO

/****** Object:  Table [dbo].[USERS]    Script Date: 7/28/2022 3:17:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PIPELINE_CICD_TESTING](
	[USER_ID] [int] IDENTITY(1,1) NOT NULL,
	[FIRST_NAME] [nvarchar](250) NOT NULL,
	[LAST_NAME] [nvarchar](250) NOT NULL,
	[EMAIL_ID] [nvarchar](250) NOT NULL,
	[USER_NAME] [nvarchar](250) NOT NULL,
	[USER_TYPE] [varchar](1) NOT NULL,
	[PASSWORD] [varchar](75) NULL,
	[PASSWORD_1] [varchar](75) NULL,
	[PASSWORD_2] [varchar](75) NULL,
	[PASSWORD_3] [varchar](75) NULL,
	[PASSWORD_4] [varchar](75) NULL,
	[PASSWORD_5] [varchar](75) NULL,
	[STATUS] [varchar](10) NULL,
	[LAST_LOGIN_DATE] [datetime] NULL,
	[LAST_PASSWORD_DATE] [datetime] NULL,
	[UPDATED_BY] [int] NULL,
	[UPDATED_DATE] [datetime] NULL,
	[ATTEMPT_COUNT] [int] NULL,
	[SAML_ENABLED] [varchar](1) NULL,
	[MFA_ENABLED] [varchar](10) NULL,
	[OTP] [varchar](10) NULL,
	[OTP_REQUESTED_TIME] [datetime] NULL,
	[CURRENT_VERSION][nvarchar](250) NOT NULL
PRIMARY KEY CLUSTERED 
(
	[USER_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

UPDATE [dbo].[PIPELINE_CICD_TESTING]
SET CURRENT_VERSION = '1.0.1.0';


