USE [IHG_DW]
GO

/****** Object:  StoredProcedure [dbo].[Spel_Create_EMIS_Research]    Script Date: 18/01/2024 15:55:07 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Stewart Greenwood
-- Create date: 18/01/2023
-- Description:	Creates EMIS Research Invite
-- =============================================
ALTER PROCEDURE [dbo].[Spel_Create_EMIS_Research]
AS
BEGIN
	SELECT DISTINCT [patient_id]
		,PT.[registration_guid] AS [registration id]
		,CONCAT (
			PT.[patient_givenname]
			,' '
			,[patient_surname]
			) AS [Full_Name] -- task asks for full name doesn't specify format
		,PT.[postcode]
		,DATEDIFF(year, pt.[date_of_birth], GETDATE()) AS [Age] -- age shows as 0 in raw data assumed age as of report run
		,[gender]
	FROM [IHG_DW].[dbo].[Patient] AS PT
	LEFT JOIN [IHG_DW].[dbo].[Observations] AS obs ON pt.[registration_guid] = obs.[registration_guid]
	LEFT JOIN [IHG_DW].[dbo].[Clinical_Code] AS CC ON OBS.[emis_code_id] = CC.[code_id]
	LEFT JOIN [IHG_DW].[dbo].[Medication] AS MED ON MED.[registration_guid] = PT.[registration_guid]
	WHERE PT.[postcode] LIKE 'LS99%'
		OR PT.[postcode] LIKE 'S72%' -- initial query identifies these two postcodes (ignoring NULL postcode) -1842 patients
		AND [refset_simple_id] = '999012891000230104' -- Asthmatic patients
		AND OBS.[snomed_concept_id] != '162660004' --code for Asthma Resolved found at https://www.england.nhs.uk/wp-content/uploads/2019/07/qsr-sfl-2019-20-codes-list.xlsm
		AND CC.[snomed_concept_id] IN (
			'129490002'
			,'108606009'
			,'702408004'
			,'702801003'
			,'704459002'
			)
		AND obs.[readv2_code] NOT LIKE '137R.00' -- non smoker -- task uses same  999012891000230104 as asthma - Read code substitited from https://www.mygp.com/help/connect/smoking-status/
		AND obs.[snomed_concept_id] != '27113001' -- not less than 40kg
		AND CC.[refset_simple_id] != '999011571000230107' -- no COPD
		AND obs.dummy_patient_flag = 'false' -- only actual patients are invited
		AND date_of_death IS NULL -- ensures that relatives of deceased patients are not alarmed
END