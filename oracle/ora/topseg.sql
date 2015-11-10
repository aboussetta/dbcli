/*[[Show top segments, default sort by logical reads. Usage: topseg [-d] [-u|-a|<owner>|<object_name>[.<partition_name>]]] [<sort_by_field>]
    Options:
        -d      :  Show the detail segment, instead of grouping by object name
        -u      :  Group the segments  by schema
        -a      :  Only show the segment statistics of current schema
    Tips:
        The query is based on GV$SEGMENT_STATISTICS which can be very slow. Use 'set instance' to limit the target instance.
    --[[
        &cols   : default={object_name,regexp_substr(object_type,'^[^ ]+')}, d={object_name,subobject_name,object_type}, a={'ALL'}
        &V2     : default={logi_reads}
        &Filter : default={instr('.'||owner||'.'||object_name||'.'||subobject_name||'.',upper('.'||:V1||'.'))>0}, u={owner=sys_context('userenv','current_schema')}
    --]]
]]*/
set rownum on sqltimeout 1800
SELECT /*+NO_EXPAND MONITOR*/ min(obj#) obj#,owner,  &cols object_type,
       SUM(DECODE(statistic_name, 'logical reads', VALUE)) logi_reads,
       SUM(DECODE(statistic_name, 'physical reads', VALUE)) phy_reads,
       SUM(DECODE(statistic_name, 'physical writes', VALUE)) phy_writes,
       SUM(DECODE(statistic_name, 'physical reads direct', VALUE)) direct_reads,
       SUM(DECODE(statistic_name, 'physical writes direct', VALUE)) direct_writes,
       SUM(DECODE(statistic_name, 'db block changes', VALUE)) block_chgs,
       SUM(DECODE(statistic_name, 'buffer busy waits', VALUE)) busy_waits,
       SUM(DECODE(statistic_name, 'ITL waits', VALUE)) itl_waits,
       SUM(DECODE(statistic_name, 'gc cr blocks received', VALUE)) gc_cr_blocks,
       SUM(DECODE(statistic_name, 'gc current blocks received', VALUE)) gc_cu_blocks
FROM   GV$SEGMENT_STATISTICS
WHERE  (:V1 is null OR (&filter))
GROUP  BY owner,  &cols
ORDER  BY &V2 DESC