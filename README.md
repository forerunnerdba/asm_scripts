# Oracle ASM Daily Health Check Script

A comprehensive, production-ready shell script for daily monitoring and troubleshooting of Oracle Automatic Storage Management (ASM).

## Features (v1.1)

- ✅ Diskgroup space usage with usable space
- ✅ Detailed disk status (Mount, Header, Failgroup)
- ✅ Current ASM operations (rebalance, add/drop, etc.)
- ✅ I/O balance & error monitoring
- ✅ Voting files location
- ✅ ASM attributes (compatibility, AU size, etc.)
- ✅ Top space-consuming file types
- **Error Handling** – Graceful failure with detailed logging
- **Email Notification** – Success & failure alerts
- Timestamped reports
- Logging support

## Files

- asm_daily_health_check.sh → Main script
- README.md → This file

## Prerequisites

- Oracle ASM instance running
- sqlplus accessible
- mailx installed (for email functionality)

## Configuration

Edit the top section of the script:

#!/bin/bash
ORACLE_SID="+ASM1"
ORACLE_HOME="/u01/app/oracle/product/19.0.0/grid"
EMAIL_TO="your.email@company.com"
