IF NOT EXISTS (
	SELECT *
	FROM sys.tables
	WHERE object_id = object_id('dbo.SpinStats')
)
BEGIN
	CREATE TABLE dbo.SpinStats
	(
		[Name] nvarchar(256),
		Collisions bigint,
		Spins bigint,
		SpinsPerCollision real,
		SleepTime bigint,
		Backoffs int,
		CollectionDate datetime,
		CONSTRAINT PK_SpinStats
			PRIMARY KEY ([Name], CollectionDate)
	);
END
GO
CREATE OR ALTER PROCEDURE dbo.s_CollectSpinStats (
	@CollisionsThreshold bigint
)
AS
	INSERT dbo.SpinStats( 
		[Name],
		Collisions,
		Spins,
		SpinsPerCollision,
		SleepTime,
		Backoffs,
		CollectionDate
	)
	SELECT 
		[name], 
		collisions, 
		spins, 
		spins_per_collision,
		sleep_time,
		backoffs,
		GETUTCDATE()
	FROM sys.dm_os_spinlock_stats
	WHERE collisions > @CollisionsThreshold;

	-- Clean up
	DELETE dbo.SpinStats
	WHERE CollectionDate < DATEADD( DAY, -7, GETUTCDATE() );
GO
CREATE OR ALTER PROCEDURE dbo.s_SpinStatsHistogram
	@HistogramBucketSizeInMinutes INT = 60
AS

WITH WaitStatsHistogram AS
(
    SELECT S.[Name],
           C.GroupedCollectionDate AS CollectionDate,
           MAX(Collisions) AS Collisions
    FROM   SpinStats S
    CROSS APPLY ( SELECT DATEADD(
                    MINUTE, 
                    (DATEDIFF(MINUTE, 0, S.CollectionDate ) / @HistogramBucketSizeInMinutes) * @HistogramBucketSizeInMinutes, 
                    0) ) AS C(GroupedCollectionDate)
    GROUP BY S.[Name], C.GroupedCollectionDate
)
SELECT [Name],
       CollectionDate,
       Collisions - 
  	     LAG(Collisions, 1, NULL) OVER ( 
           PARTITION BY ([Name]) 
           ORDER BY (CollectionDate)) as Collisions
FROM   WaitStatsHistogram;
GO
DECLARE @DBName sysname = DB_NAME();
DECLARE @JobName sysname = 'CollectSpinStats';

IF NOT EXISTS 
(
	SELECT *
	FROM msdb.dbo.sysjobs
	WHERE name = @JobName
)
BEGIN
	EXEC msdb.dbo.sp_add_job 
		@job_name = @JobName;

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
