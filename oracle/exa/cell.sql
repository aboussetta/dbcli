/*[[cellcli list cell]]*/
set printsize 3000 feed off
SELECT a.cellname, b.*
FROM   v$cell_config a,
       XMLTABLE('/cli-output/cell' PASSING xmltype(a.confval) COLUMNS
                "name" VARCHAR2(300) path 'name',
                "upTime" VARCHAR2(300) path 'upTime',
                "accessLevelPerm" VARCHAR2(300) path 'accessLevelPerm',
                "status" VARCHAR2(300) path 'status',
                "bbuStatus" VARCHAR2(300) path 'bbuStatus',
                "cpuCount" VARCHAR2(300) path 'cpuCount',
                "temperatureReading" VARCHAR2(300) path 'temperatureReading',
                "diagHistoryDays" VARCHAR2(300) path 'diagHistoryDays',
                "fanCount" VARCHAR2(300) path 'fanCount',
                "fanStatus" VARCHAR2(300) path 'fanStatus',
                "flashCacheMode" VARCHAR2(300) path 'flashCacheMode',
                "flashCacheCompress" VARCHAR2(300) path 'flashCacheCompress',
                "id" VARCHAR2(300) path 'id',
                "cellVersion" VARCHAR2(300) path 'cellVersion',
                "interconnectCount" VARCHAR2(300) path 'interconnectCount',
                "interconnect1" VARCHAR2(300) path 'interconnect1',
                "interconnect2" VARCHAR2(300) path 'interconnect2',
                "iormBoost" VARCHAR2(300) path 'iormBoost',
                "ipaddress1" VARCHAR2(300) path 'ipaddress1',
                "ipaddress2" VARCHAR2(300) path 'ipaddress2',
                "kernelVersion" VARCHAR2(300) path 'kernelVersion',
                "locatorLEDStatus" VARCHAR2(300) path 'locatorLEDStatus',
                "makeModel" VARCHAR2(300) path 'makeModel',
                "memoryGB" VARCHAR2(300) path 'memoryGB',
                "metricHistoryDays" VARCHAR2(300) path 'metricHistoryDays',
                "notificationMethod" VARCHAR2(300) path 'notificationMethod',
                "notificationPolicy" VARCHAR2(300) path 'notificationPolicy',
                "smtpPort" VARCHAR2(300) path 'smtpPort',
                "smtpServer" VARCHAR2(300) path 'smtpServer',
                "smtpToAddr" VARCHAR2(300) path 'smtpToAddr',
                "smtpUseSSL" VARCHAR2(300) path 'smtpUseSSL',
                "offloadGroupEvents" VARCHAR2(300) path 'offloadGroupEvents',
                "powerCount" VARCHAR2(300) path 'powerCount',
                "powerStatus" VARCHAR2(300) path 'powerStatus',
                "releaseImageStatus" VARCHAR2(300) path 'releaseImageStatus',
                "releaseVersion" VARCHAR2(300) path 'releaseVersion',
                "rpmVersion" VARCHAR2(300) path 'rpmVersion',
                "releaseTrackingBug" VARCHAR2(300) path 'releaseTrackingBug',
                "rollbackVersion" VARCHAR2(300) path 'rollbackVersion',
                "temperatureStatus" VARCHAR2(300) path 'temperatureStatus',
                "usbStatus" VARCHAR2(300) path 'usbStatus') b
WHERE  conftype = 'CELL'
ORDER BY 2;

col total_size,free_size,HD_SIZE,FD_SIZE,flash_cache,flash_log format kmg
col FC_ALLOC,ALLOC_OLTP,ALLOC_OLTP_KEEP,alloc_unflush_keep,ALLOC_UNFLUSH,USED,OLTP,KEEP,OLTP_KEEP,FCC,FCC_KEEP format kmg
grid {[[
        SELECT * FROM (
        SELECT  NVL((SELECT extractvalue(xmltype(c.confval), '/cli-output/context/@cell')
                        FROM   v$cell_config c
                        WHERE  c.CELLNAME = a.CELLNAME
                        AND    rownum < 2),'--TOTAL') cell,
                nvl(cellhash,0) cellhash,
                SUM(DECODE(disktype, 'HardDisk', 1,0)) HD,
                SUM(DECODE(disktype, 'HardDisk', 0,1))  FD,
                SUM(siz) total_size,
                SUM(freeSpace) free_size,
                SUM(DECODE(disktype, 'HardDisk', siz)) HD_SIZE,
                SUM(DECODE(disktype, 'FlashDisk', siz)) FD_SIZE,
                SUM(fl) flash_log,
                '|' "|"
        FROM   (SELECT  CELLNAME,CELLHASH,
                        b.*,
                        (SELECT SUM(siz)
                                FROM   v$cell_state d,
                                XMLTABLE('/flashlogstore_stats' PASSING XMLTYPE(d.statistics_value) COLUMNS --
                                        celldisk VARCHAR2(100) path 'stat[@name="celldisk"]',
                                        siz INT path 'stat[@name="size"]') c
                                WHERE  d.statistics_type = 'FLASHLOG'
                                AND    d.cell_name = a.cellname
                                AND    c.celldisk = b.name) fl
                FROM   v$cell_config a,
                XMLTABLE('//celldisk' PASSING xmltype(a.confval) COLUMNS --
                            NAME VARCHAR2(300) path 'name',
                            diskType VARCHAR2(300) path 'diskType',
                            siz INT path 'size',
                            freeSpace INT path 'freeSpace') b
                WHERE  conftype = 'CELLDISKS') a
        GROUP  BY rollup((cellname,CELLHASH))) 
        RIGHT JOIN (SELECT * FROM (
                SELECT nvl(cell_hash,0) cellhash,metric_name n, sum(metric_value) v 
                FROM  v$cell_global 
                WHERE metric_name LIKE '%alloc%' OR metric_name LIKE '%use%' 
                group by metric_name,rollup(cell_hash)
                ) PIVOT (
                MAX(v) FOR n IN(
                'Flash cache bytes allocated' AS fc_alloc,
                'Flash cache bytes allocated for OLTP data' AS alloc_oltp,
                'Flash cache bytes allocated for OLTP keep objects' AS alloc_oltp_keep,
                'Flash cache bytes allocated for unflushed data' AS alloc_unflush,
                'Flash cache bytes allocated for unflushed keep objects' AS alloc_unflush_keep,
                'Flash cache bytes used' AS used,
                'Flash cache bytes used for OLTP data' AS oltp,
                'Flash cache bytes used - keep objects' AS keep,
                'Flash cache bytes allocated for OLTP keep objects' AS oltp_keep,
                'Flash cache bytes used - columnar' AS fcc,
                'Flash cache bytes used - columnar keep' AS fcc_keep))) b 
        USING(cellhash)
]],'-',[[
        WITH grid AS(
                SELECT b.*
                FROM   v$cell_config a,
                        XMLTABLE('/cli-output/griddisk' PASSING xmltype(a.confval) COLUMNS --
                                cellDisk VARCHAR2(300) path 'cellDisk', "name" VARCHAR2(300) path 'name', diskType VARCHAR2(300) path 'diskType',
                                errors VARCHAR2(300) path 'errorCount',
                                DISKGROUP VARCHAR2(300) path 'asmDiskGroupName', asmDiskName VARCHAR2(300) path 'asmDiskName',
                                FAILGROUP VARCHAR2(300) path 'asmFailGroupName', "availableTo" VARCHAR2(300) path 'availableTo',
                                cachedBy VARCHAR2(300) path 'cachedBy', "cachingPolicy" VARCHAR2(300) path 'cachingPolicy',
                                "creationTime" VARCHAR2(300) path 'creationTime', "id" VARCHAR2(300) path 'id') b
                WHERE  conftype = 'GRIDDISKS')
        SELECT  /*+no_merge(c) no_merge(a) use_hash(c a)*/
                DISTINCT a.*, listagg(tbs,',') WITHIN GROUP(ORDER BY tbs) OVER(PARTITION BY DISKGROUP) tbs
        FROM   (SELECT  /*+no_merge(c) no_merge(b) use_hash(c b)*/
                        b.DISKGROUP,
                        SUM(decode(diskType, 'HardDisk', 1, 0))||'/'||SUM(decode(diskType, 'HardDisk', 0, 1)) "HD/FD",
                        sum(errors) errs,
                        MAX(NVL2(TRIM(REPLACE(cachedBy, '"')), 'Y', 'N')) FC,
                        SUM(TOTAL_MB) * 1024 * 1024 total_size,
                        SUM(FREE_MB) * 1024 * 1024 free_size
                        --,regexp_replace(listagg(b.FAILGROUP, '/') WITHIN GROUP(ORDER BY b.failgroup), '([^/]+)(/\1)+', '\1') failgroups
                FROM   v$asm_disk c, grid b
                WHERE  c.name = b.asmDiskName
                GROUP  BY DISKGROUP) a,
        (SELECT DISTINCT tbs, regexp_substr(FILE_NAME, '[^\+\\\/]+') dg
                FROM   (SELECT TABLESPACE_NAME tbs, file_name
                        FROM   dba_data_files
                        UNION ALL
                        SELECT TABLESPACE_NAME tbs, file_name
                        FROM   dba_temp_files
                        UNION ALL
                        SELECT 'Redo' tbs, MEMBER
                        FROM   gv$logfile
                        UNION ALL
                        SELECT 'FlashBack', NAME
                        FROM   V$FLASHBACK_DATABASE_LOGFILE
                        WHERE  ROWNUM <= 30
                        UNION ALL
                        SELECT 'ArchiveLog', NAME
                        FROM   V$ARCHIVED_LOG
                        WHERE  ROWNUM <= 30)) c
        WHERE  a.DISKGROUP = c.dg(+)
        ORDER  BY 1]]}
