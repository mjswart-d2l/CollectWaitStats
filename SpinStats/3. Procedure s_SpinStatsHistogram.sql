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
