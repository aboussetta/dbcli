/*[[cellcli list offload]]*/
SELECT extractvalue(xmltype(a.confval), '/cli-output/context/@cell') cell,
       b.*
FROM   v$cell_config_info a,
       XMLTABLE('/cli-output/offloadgroup' PASSING xmltype(a.confval) COLUMNS --
                name VARCHAR2(300) path 'name',
                package VARCHAR2(300) path 'package'
                ) b
WHERE  conftype = 'OFFLOAD'
ORDER BY 1,2