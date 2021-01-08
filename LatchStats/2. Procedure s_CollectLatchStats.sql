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


