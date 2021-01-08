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
