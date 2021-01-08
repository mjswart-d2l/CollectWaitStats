CREATE OR ALTER PROCEDURE dbo.s_CollectWaitStats (
	@WaitThresholdInMs BIGINT
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
