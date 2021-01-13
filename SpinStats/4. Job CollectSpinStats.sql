DECLARE @DBName sysname = DB_NAME();
DECLARE @JobName sysname = 'CollectSpinStats';
DECLARE @JobDesc sysname
    = 'Source: ' + CHAR(9) + 'https://github.com/mjswart/CollectWaitStats.' 
	+ 'Created: '+ CHAR(9) + CAST(GETDATE() AS VARCHAR(20))
    + 'By: '+ CHAR(9) + SUSER_NAME();

IF NOT EXISTS 
(
	SELECT *
FROM msdb.dbo.sysjobs
WHERE name = @JobName
)
BEGIN
	EXEC msdb.dbo.sp_add_job 
		@job_name = @JobName,
		@description = @JobDesc;

	EXEC msdb.dbo.sp_add_jobstep 
		@job_name = @JobName,
		@step_name = N'Collect Spin Stats',
		@command = N'exec s_CollectSpinStats @CollisionsThreshold = 100;', 
		@database_name = @DBName;

	EXEC msdb.dbo.sp_add_jobserver 
		@job_name = @JobName,
		@server_name = N'(local)';

	EXEC msdb.dbo.sp_add_jobschedule 
		@job_name = @JobName,
		@name=N'Minutely', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1;
END
GO
