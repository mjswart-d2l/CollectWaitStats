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
