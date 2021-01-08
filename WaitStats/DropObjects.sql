IF EXISTS ( SELECT * FROM msdb.dbo.sysjobs WHERE name = 'CollectWaitStats' )
BEGIN
	EXEC msdb.dbo.sp_delete_job @job_name = 'CollectWaitStats';
END;

DROP PROCEDURE IF EXISTS dbo.s_CollectWaitStats;
DROP PROCEDURE IF EXISTS dbo.s_WaitStatsHistogram;
DROP VIEW IF EXISTS dbo.ImportantWaits;
DROP TABLE IF EXISTS dbo.WaitStats;