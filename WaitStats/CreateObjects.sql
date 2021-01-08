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
CREATE OR ALTER VIEW dbo.ImportantWaits
AS
	SELECT * 
	FROM dbo.WaitStats
	WHERE WaitType NOT IN (
        N'BROKER_EVENTHANDLER', 
        N'BROKER_RECEIVE_WAITFOR', 
        N'BROKER_TASK_STOP', 
        N'BROKER_TO_FLUSH', 
        N'BROKER_TRANSMITTER', 
        N'CHECKPOINT_QUEUE', 
        N'CHKPT', 
        N'CLR_AUTO_EVENT', 
        N'CLR_MANUAL_EVENT', 
        N'CLR_SEMAPHORE', 
        N'CXCONSUMER', 
        N'DBMIRROR_DBM_EVENT', 
        N'DBMIRROR_EVENTS_QUEUE', 
        N'DBMIRROR_WORKER_QUEUE', 
        N'DBMIRRORING_CMD', 
        N'DIRTY_PAGE_POLL', 
        N'DISPATCHER_QUEUE_SEMAPHORE', 
        N'EXECSYNC', 
        N'FSAGENT', 
        N'FT_IFTS_SCHEDULER_IDLE_WAIT', 
        N'FT_IFTSHC_MUTEX', 
        N'HADR_CLUSAPI_CALL', 
        N'HADR_FILESTREAM_IOMGR_IOCOMPLETION', 
        N'HADR_LOGCAPTURE_WAIT', 
        N'HADR_NOTIFICATION_DEQUEUE', 
        N'HADR_TIMER_TASK', 
        N'HADR_WORK_QUEUE', 
        N'KSOURCE_WAKEUP', 
        N'LAZYWRITER_SLEEP', 
        N'LOGMGR_QUEUE', 
        N'MEMORY_ALLOCATION_EXT', 
        N'ONDEMAND_TASK_QUEUE', 
        N'PARALLEL_REDO_DRAIN_WORKER', 
        N'PARALLEL_REDO_LOG_CACHE', 
        N'PARALLEL_REDO_TRAN_LIST', 
        N'PARALLEL_REDO_WORKER_SYNC', 
        N'PARALLEL_REDO_WORKER_WAIT_WORK', 
        N'PREEMPTIVE_OS_FLUSHFILEBUFFERS', 
        N'PREEMPTIVE_XE_GETTARGETSTATE', 
        N'PWAIT_ALL_COMPONENTS_INITIALIZED', 
        N'PWAIT_DIRECTLOGCONSUMER_GETNEXT', 
        N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP', 
        N'QDS_ASYNC_QUEUE', 
        N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
        N'QDS_SHUTDOWN_QUEUE', 
        N'REDO_THREAD_PENDING_WORK', 
        N'REQUEST_FOR_DEADLOCK_SEARCH', 
        N'RESOURCE_QUEUE', 
        N'SERVER_IDLE_CHECK', 
        N'SLEEP_BPOOL_FLUSH', 
        N'SLEEP_DBSTARTUP', 
        N'SLEEP_DCOMSTARTUP', 
        N'SLEEP_MASTERDBREADY', 
        N'SLEEP_MASTERMDREADY', 
        N'SLEEP_MASTERUPGRADED', 
        N'SLEEP_MSDBSTARTUP', 
        N'SLEEP_SYSTEMTASK', 
        N'SLEEP_TASK', 
        N'SLEEP_TEMPDBSTARTUP', 
        N'SNI_HTTP_ACCEPT', 
        N'SOS_WORK_DISPATCHER', 
        N'SP_SERVER_DIAGNOSTICS_SLEEP', 
        N'SQLTRACE_BUFFER_FLUSH', 
        N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', 
        N'SQLTRACE_WAIT_ENTRIES', 
        N'VDI_CLIENT_OTHER', 
        N'WAIT_FOR_RESULTS', 
        N'WAITFOR', 
        N'WAITFOR_TASKSHUTDOWN', 
        N'WAIT_XTP_RECOVERY', 
        N'WAIT_XTP_HOST_WAIT', 
        N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', 
        N'WAIT_XTP_CKPT_CLOSE', 
        N'XE_DISPATCHER_JOIN', 
        N'XE_DISPATCHER_WAIT', 
        N'XE_TIMER_EVENT');
GO
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
GO
DECLARE @DBName sysname = DB_NAME();
DECLARE @JobName sysname = 'CollectWaitStats';

IF NOT EXISTS 
(
	SELECT *
	FROM msdb.dbo.sysjobs
	WHERE name = @JobName
)
BEGIN
	EXEC msdb.dbo.sp_add_job 
		@job_name = @JobName;

	EXEC msdb.dbo.sp_add_jobstep 
		@job_name = @JobName,
		@step_name = N'Collect Wait Stats',
		@command = N'exec s_CollectWaitStats @WaitThresholdInMs = 1000;', 
		@database_name = @DBName;
	
	EXEC msdb.dbo.sp_add_jobserver 
		@job_name = @JobName,
		@server_name = N'(local)';

	EXEC msdb.dbo.sp_add_jobschedule 
		@job_name = @JobName,
		@name=N'Minutely', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1;
END
GO
