CREATE OR ALTER PROCEDURE dbo.s_WaitStatsHistogram
	@HistogramBucketSizeInMinutes INT = 60
AS

WITH WaitStatsHistogram AS
(
    SELECT W.WaitType,
           C.GroupedCollectionDate AS CollectionDate,
           MAX(WaitTimeMs) AS WaitTimeMs
    FROM   ImportantWaits W
    CROSS APPLY ( SELECT DATEADD(
                    MINUTE, 
                    (DATEDIFF(MINUTE, 0, W.CollectionDate ) / @HistogramBucketSizeInMinutes) * @HistogramBucketSizeInMinutes, 
                    0) ) AS C(GroupedCollectionDate)
    GROUP BY W.WaitType, C.GroupedCollectionDate
)
SELECT WaitType,
       CollectionDate,
       WaitTimeMs - 
  	     LAG(WaitTimeMs, 1, NULL) OVER ( 
           PARTITION BY (WaitType) 
           ORDER BY (CollectionDate)) as WaitTimeMs
FROM   WaitStatsHistogram;
