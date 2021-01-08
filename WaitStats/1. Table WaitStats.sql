IF NOT EXISTS (
	SELECT *
	FROM sys.tables
	WHERE object_id = object_id('dbo.WaitStats')
)
BEGIN
	CREATE TABLE dbo.WaitStats
	(
		WaitType NVARCHAR(60),
		WaitingTasksCount BIGINT,
		WaitTimeMs BIGINT,
		MaxWaitTimeMs BIGINT,
		SignalWaitTimeMs BIGINT,
		CollectionDate DATETIME,
		CONSTRAINT PK_WaitStats
			PRIMARY KEY CLUSTERED (WaitType, CollectionDate)
	);
END
GO

CREATE OR ALTER PROCEDURE dbo.s_CollectWaitStats (
	@WaitThresholdInMs bigint
)
AS
	INSERT dbo.WaitStats( 
		WaitType, 
		WaitingTasksCount, 
		WaitTimeMs, 
		MaxWaitTimeMs,
		SignalWaitTimeMs,
		CollectionDate
	)
	SELECT 
		wait_type, 
		waiting_tasks_count, 
		wait_time_ms, 
		max_wait_time_ms,
		signal_wait_time_ms,
		GETUTCDATE()
	FROM sys.dm_os_wait_stats
	WHERE wait_time_ms > @WaitThresholdInMs;

	-- Clean up
	DELETE dbo.WaitStats
	WHERE CollectionDate < DATEADD( DAY, -7, GETUTCDATE() );
GO


