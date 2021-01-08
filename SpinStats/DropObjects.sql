IF EXISTS ( SELECT * FROM msdb.dbo.sysjobs WHERE name = 'CollectSpinStats' )
BEGIN
	EXEC msdb.dbo.sp_delete_job @job_name = 'CollectSpinStats';
END;

DROP PROCEDURE IF EXISTS dbo.s_CollectSpinStats;
DROP PROCEDURE IF EXISTS dbo.s_SpinStatsHistogram;
DROP TABLE IF EXISTS dbo.SpinStats;