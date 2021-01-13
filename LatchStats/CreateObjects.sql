IF NOT EXISTS (
	SELECT *
	FROM sys.tables
	WHERE object_id = object_id('dbo.LatchStats')
)
BEGIN
	CREATE TABLE dbo.LatchStats
	(
		LatchClass NVARCHAR(60),
		WaitingRequestsCount BIGINT,
		WaitTimeMs BIGINT,
		MaxWaitTimeMs BIGINT,
		CollectionDate DATETIME,
		CONSTRAINT PK_LatchStats
			PRIMARY KEY (CollectionDate, LatchClass)
	);
END
GO
CREATE OR ALTER PROCEDURE dbo.s_CollectLatchStats (
	@WaitThresholdInMs BIGINT
)
AS
	INSERT dbo.LatchStats( 
		LatchClass, 
		WaitingRequestsCount, 
		WaitTimeMs, 
		MaxWaitTimeMs,
		CollectionDate
	)
	SELECT 
		latch_class, 
		waiting_requests_count, 
		wait_time_ms, 
		max_wait_time_ms,
		GETUTCDATE()
	FROM sys.dm_os_latch_stats
	WHERE wait_time_ms > @WaitThresholdInMs;

	-- Clean up
	DELETE dbo.LatchStats
	WHERE CollectionDate < DATEADD( DAY, -7, GETUTCDATE() );
GO
CREATE OR ALTER PROCEDURE dbo.s_LatchStatsHistogram
	@HistogramBucketSizeInMinutes INT = 60
AS

WITH LatchStatsHistogram AS
(
    SELECT L.LatchClass,
           C.GroupedCollectionDate AS CollectionDate,
           MAX(WaitTimeMs) AS WaitTimeMs
    FROM   LatchStats L
    CROSS APPLY ( SELECT DATEADD(
                    MINUTE, 
                    (DATEDIFF(MINUTE, 0, L.CollectionDate ) / @HistogramBucketSizeInMinutes) * @HistogramBucketSizeInMinutes, 
                    0) ) AS C(GroupedCollectionDate)
    GROUP BY L.LatchClass, C.GroupedCollectionDate
)
SELECT LatchClass,
       CollectionDate,
       WaitTimeMs - 
  	     LAG(WaitTimeMs, 1, NULL) OVER ( 
           PARTITION BY (LatchClass) 
           ORDER BY (CollectionDate)) as LatchTimeMs
FROM   LatchStatsHistogram;
GO
DECLARE @DBName sysname = DB_NAME();
DECLARE @JobName sysname = 'CollectLatchStats';
DECLARE @JobDesc sysname
    = ' Source:   ' + 'https://github.com/mjswart/CollectWaitStats. ;' 
	+ ' Created:   '+ CAST(GETDATE() AS VARCHAR(20)) + ';'
    + ' By:    '+ SUSER_NAME() + ';';

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
		@step_name = N'Collect Latch Stats',
		@command = N'exec s_CollectLatchStats @WaitThresholdInMs = 100;', 
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
