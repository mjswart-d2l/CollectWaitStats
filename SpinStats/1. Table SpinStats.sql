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