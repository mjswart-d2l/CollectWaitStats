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
