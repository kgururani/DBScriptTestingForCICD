 /*
##########################################################################
-- Name             : 2022-10-18 DSR_View_Script.sql
-- Version          : v1.0
-- Date             : 2022-10-18 
-- Author           : V V Anirudh
##########################################################################

SUMMARY OF CHANGES
Version(vX.x)   Date(yyyy-mm-dd)    Author              Comments
-------------   ------------------- ------------------- ------------------------------------------------------------
v2.0            2022-10-18          V V Anirudh       create Script of DSR View
														

##########################################################################*/
 
 
   CREATE OR ALTER  VIEW [dbo].[DSR_VIEW]  
 AS
SELECT 
ROW_NUMBER() OVER (ORDER BY DSR.DSR_ID) AS view_Id,          
   
 DSR.DSR_ID as DsrId  
 ,RDA.ENTITY_TYPE AS EntityType  
 ,RDA.ENTITY_ID AS EntityId  
 ,DSR.MODEL_ID AS ModelId      
 ,RDA.ASSOCIATION_DATE  AS AssociationDate  
 ,CASE WHEN FS.SUBMISSION_STATUS IN('Initial Assessment','Model Development','Model Validation') THEN 'Y' ELSE 'N' END AS EntityInProgress  
 ,DSR.DSR_TITLE AS Title 
 ,CASE WHEN FIS.AIT='N' THEN FIS.NON_AIT_PLATFORM ELSE RS.SYSTEM_NAME END AS ProductionPlatform  
 ,DSR.DEPLOYMENT_PRIOR_TO_Approval AS DeploymentPriorToApproval 
 ,DSR.RATIONALE AS Rationale  
 ,DSR.IMPL_TESTING_DUE_DATE AS ImplementationTestingDueDate  
 ,DSR.TARGET_DEPLOYMENT_DATE AS TargetDeploymentDate    
 ,DSR.ACTUAL_DEPLOYMENT_DATE AS ActualDeploymentDate  
 ,DSR.RELEASE_IDENTIFIER AS ReleaseIdentifier  
 ,RUB.FULL_NAME AS DsrReviewerName  
 ,CASE WHEN RDS.DSR_STATUS IN ('Deployed - Pending MRM Review','Complete') THEN 'Y' ELSE 'N' END AS DsrReviewerApproval
 ,CASE WHEN RDS.DSR_STATUS='Complete' THEN 'Y' ELSE 'N' END AS MRMAcknowledgement
 ,RDS.DSR_STATUS AS DSRStatus  
 ,DSR.AUDIT_CREATED_DATE_TIME AS AuditCreationDate  
 ,DSR.UPDATED_DATE_TIME AS AuditUpdateDate  
 ,DSR.DSR_CLOSURE_DATE AS AuditClosureDate  
  --SELECT *  
 FROM FACT_DSR DSR 
 --SELECT * FROM REL_DSR_ASSOCIATION 
 LEFT JOIN (
	SELECT DSR_ID,
	STRING_AGG(CONVERT(VARCHAR(20),ENTITY_ID),' | ')  WITHIN GROUP (ORDER BY DSR_ID) AS ENTITY_ID,
	'Submission' As ENTITY_TYPE,
	STRING_AGG(CONVERT(varchar(20),ASSOCIATION_DATE),' | ')  WITHIN GROUP (ORDER BY DSR_ID) AS ASSOCIATION_DATE,
	STRING_AGG(CONVERT(VARCHAR(20),ENTITY_IN_PROGRESS),' | ')  WITHIN GROUP (ORDER BY DSR_ID) AS ENTITY_IN_PROGRESS,
	STRING_AGG(CONVERT(VARCHAR(20),MODEL_ID),' | ')  WITHIN GROUP (ORDER BY DSR_ID) AS MODEL_ID
  FROM [REL_DSR_ASSOCIATION ] GROUP BY DSR_ID  
	 
 )RDA ON DSR.DSR_ID=RDA.DSR_ID  

 LEFT JOIN [REF_DSR_STATUS ] RDS ON DSR.DSR_STATUS_ID=RDS.DSR_STATUS_ID
 
 LEFT JOIN REF_USER_BASE RUB ON RUB.USER_ID=DSR.DSR_REVIEWER_ID  
 
 LEFT JOIN [REL_DSR_PLATFORM ] RDP ON DSR.DSR_ID=RDP.DSR_ID

 LEFT JOIN FACT_IMPLEMENTATION_SYSTEM FIS ON RDP.FACT_SYS_ID=FIS.FACT_IMPL_SYS_ID

 LEFT JOIN REF_SYSTEMS RS ON FIS.SYS_ID=RS.SYS_ID

 LEFT JOIN FACT_SUBMISSION FS ON DSR.SOURCE_ID=FS.SUBMISSION_ID
 
 where DSR.IS_ACTIVE=1
