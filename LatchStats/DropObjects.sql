IF EXISTS ( SELECT * FROM msdb.dbo.sysjobs WHERE name = 'CollectLatchStats' )
BEGIN
	EXEC msdb.dbo.sp_delete_job @job_name = 'CollectLatchStats';
END;

DROP PROCEDURE IF EXISTS dbo.s_CollectLatchStats;
DROP PROCEDURE IF EXISTS dbo.s_LatchStatsHistogram;
DROP TABLE IF EXISTS dbo.LatchStats;