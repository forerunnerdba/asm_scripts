#!/bin/bash
# ================================================
# Oracle ASM Daily Health Check Script - v1.1
# Author: Chakravarthy Patchigolla
# Features: Error handling, Email notification, Logging
# ================================================

# ============== CONFIGURATION ==============
ORACLE_SID=+ASM1
ORACLE_HOME=/u01/app/19.3.0/grid
OUTPUT_FILE="asm_daily_report_$(date +%Y%m%d_%H%M).txt"
LOG_FILE="asm_health_check.log"
EMAIL_TO="tochakravarthy@gmail.com"          # Change this
EMAIL_SUBJECT="ASM Daily Health Check Report - $(hostname) - $(date +%Y-%m-%d)"

# Export Oracle environment
export ORACLE_SID ORACLE_HOME
export PATH=$ORACLE_HOME/bin:$PATH
echo $ORACLE_SID $ORACLE_HOME $PATH

# ============== FUNCTIONS ==============
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

check_error() {
    if [ $? -ne 0 ]; then
        log_message "ERROR: $1"
        echo "ERROR: $1" >> $OUTPUT_FILE
        send_email "ERROR" "ASM Health Check failed. Check log."
        exit 1
    fi
}

send_email() {
    local status=$1
    local body=$2

    if command -v mailx >/dev/null 2>&1; then
        if [ "$status" = "ERROR" ]; then
            mailx -s "$EMAIL_SUBJECT" $EMAIL_TO < $LOG_FILE
        else
            mailx -s "$EMAIL_SUBJECT" $EMAIL_TO <<EOF

ASM Health Check Completed Successfully.

Report: $OUTPUT_FILE
Host: $(hostname)
Date: $(date)

`cat $OUTPUT_FILE`
EOF
        fi
        log_message "Email notification sent to $EMAIL_TO"
    else
        log_message "Warning: mailx not found. Email not sent."
    fi
}

# ============== START SCRIPT ==============
log_message "Starting ASM Health Check"

echo "=====================================================" > $OUTPUT_FILE
echo "Oracle ASM Daily Health Check Report - v1.2" >> $OUTPUT_FILE
echo "Generated on: $(date)" >> $OUTPUT_FILE
echo "Host: $(hostname)" >> $OUTPUT_FILE
echo "ASM Instance: $ORACLE_SID" >> $OUTPUT_FILE
echo "=====================================================" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

{
    # 1. Diskgroup Overview
    echo "=== 1. DISKGROUP SPACE USAGE ===" >> $OUTPUT_FILE
    sqlplus -s / as sysdba <<EOF >> $OUTPUT_FILE
SET PAGES 100 LINES 150
COL name FORMAT A20
COL state FORMAT A10
SELECT name, state, type AS redundancy,
       ROUND(total_mb/1024, 2) AS total_gb,
       ROUND(free_mb/1024, 2) AS free_gb,
       ROUND(usable_file_mb/1024, 2) AS usable_gb,
       ROUND((total_mb - free_mb)/total_mb * 100, 2) AS used_pct
FROM v\$asm_diskgroup ORDER BY name;
EOF
    check_error "Failed to query diskgroup usage"

    # 2. Disk Status
    echo "=== 2. ASM DISK STATUS ===" >> $OUTPUT_FILE
    sqlplus -s / as sysdba <<EOF >> $OUTPUT_FILE
SET PAGES 100 LINES 200
COL diskgroup FORMAT A15
COL disk_name FORMAT A20
COL path FORMAT A50
SELECT dg.name AS diskgroup, d.disk_number, d.name AS disk_name, d.path,
       d.mount_status, d.header_status, d.state, d.failgroup,
       ROUND(d.total_mb/1024,2) total_gb, ROUND(d.free_mb/1024,2) free_gb
FROM v\$asm_disk d LEFT JOIN v\$asm_diskgroup dg ON d.group_number = dg.group_number
ORDER BY dg.name, d.disk_number;
EOF
    check_error "Failed to query disk status"

    # 3. Current Operations
    echo "=== 3. CURRENT ASM OPERATIONS ===" >> $OUTPUT_FILE
    sqlplus -s / as sysdba <<EOF >> $OUTPUT_FILE
SET PAGES 50 LINES 150
SELECT group_number, operation, state, power,  est_minutes AS est_time_min
FROM v\$asm_operation;
EOF

    # 4. I/O Balance
    echo "=== 4. I/O DISTRIBUTION ===" >> $OUTPUT_FILE
    sqlplus -s / as sysdba <<EOF >> $OUTPUT_FILE
SET PAGES 100 LINES 150
COL diskgroup FORMAT A15
COL disk FORMAT A20
SELECT dg.name AS diskgroup, d.name AS disk, d.reads, d.writes,
       d.read_errs, d.write_errs,
       ROUND(100 * (d.reads + d.writes) / SUM(d.reads + d.writes) OVER (PARTITION BY dg.name), 2) AS io_pct
FROM v\$asm_disk d JOIN v\$asm_diskgroup dg ON d.group_number = dg.group_number
WHERE d.mount_status = 'CACHED' ORDER BY dg.name, io_pct DESC;
EOF

    # 5. Voting Files
    echo "=== 5. VOTING FILES ===" >> $OUTPUT_FILE
    sqlplus -s / as sysdba <<EOF >> $OUTPUT_FILE
SELECT name, path FROM v\$asm_disk WHERE voting_file = 'Y';
EOF

    # 6. ASM Attributes
    echo "=== 6. ASM ATTRIBUTES ===" >> $OUTPUT_FILE
    sqlplus -s / as sysdba <<EOF >> $OUTPUT_FILE
SET PAGES 100 LINES 150
COL name FORMAT A30
COL value FORMAT A30
SELECT dg.name AS diskgroup, a.name, a.value
FROM v\$asm_attribute a JOIN v\$asm_diskgroup dg ON a.group_number = dg.group_number
WHERE a.name IN ('compatible.asm','compatible.rdbms','au_size','disk_repair_time')
ORDER BY dg.name, a.name;
EOF

    # 7. Top Space Consumers
    echo "=== 7. TOP SPACE CONSUMERS ===" >> $OUTPUT_FILE
    sqlplus -s / as sysdba <<EOF >> $OUTPUT_FILE
SET PAGES 100 LINES 150
COL diskgroup FORMAT A15
COL type FORMAT A20
SELECT dg.name AS diskgroup, f.type, COUNT(*) AS files,
       ROUND(SUM(f.blocks * f.block_size)/1024/1024/1024, 2) AS size_gb
FROM v\$asm_file f JOIN v\$asm_diskgroup dg ON f.group_number = dg.group_number
GROUP BY dg.name, f.type ORDER BY size_gb DESC;
EOF

} || {
    log_message "Critical error during SQL execution"
    send_email "ERROR" "ASM script failed during execution"
    exit 1
}

echo "" >> $OUTPUT_FILE
echo "=== ASM Health Check Completed Successfully ===" >> $OUTPUT_FILE

log_message "Health check completed successfully"
send_email "SUCCESS" "ASM Daily report generated"

echo "ASM Health Check Completed! Report: $OUTPUT_FILE"
echo "Email sent to $EMAIL_TO (if mailx is configured)"
