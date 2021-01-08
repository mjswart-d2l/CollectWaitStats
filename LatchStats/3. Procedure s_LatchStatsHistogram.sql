CREATE OR ALTER PROCEDURE dbo.s_LatchStatsHistogram
	@HistogramBucketSizeInMinutes INT = 60
AS

WITH LatchStatsHistogram AS
(
    SELECT L.LatchClass,
           C.GroupedCollectionDate AS CollectionDate,
           MAX(WaitTimeMs) AS WaitTimeMs
    FROM   LatchStats L
    CROSS APPLY ( SELECT DATEADD(
                    MINUTE, 
                    (DATEDIFF(MINUTE, 0, L.CollectionDate ) / @HistogramBucketSizeInMinutes) * @HistogramBucketSizeInMinutes, 
                    0) ) AS C(GroupedCollectionDate)
    GROUP BY L.LatchClass, C.GroupedCollectionDate
)
SELECT LatchClass,
       CollectionDate,
       WaitTimeMs - 
  	     LAG(WaitTimeMs, 1, NULL) OVER ( 
           PARTITION BY (LatchClass) 
           ORDER BY (CollectionDate)) as LatchTimeMs
FROM   LatchStatsHistogram;
