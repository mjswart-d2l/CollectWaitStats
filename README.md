# CollectWaitStats
Collect wait statistics from SQL Server's system views.

The three system views:
* sys.dm_os_wait_stats
* sys.dm_os_latch_stats
* sys.dm_os_spinlock_stats

have useful information which is aggregated over time. These scripts create a job to collect this information into a table every minute. That information can be used to explore how that data changes over time.

# Instructions
Run `CreateObjects.sql` in a database on a server whose stats you want to collect.

A table will be created to store the statistics. A procedure and a sql agent job are created to collect statistics and store them into that table every minute. Data older than a week is deleted.

Another procedure `s_WaitStatsHistogram` is created which compares the `wait_time_ms` of two samples and reports the difference. This default bucket size of the histogram is 60 minutes.

To clean up the objects and jobs created here, run `DropObjects.sql`