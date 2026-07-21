## Oracle ASM Management Every DBA Needs

Automatic Storage Management (ASM) is the heart of Oracle database storage. ASMCMD vs oracleasm vs SQL*Plus (SYSASM). Understanding the right tools and concepts has become even more critical.

In this guide, we explore the differences between # ASMCMD, # oracleasm, and # SQL*Plus as SYSASM, along with practical examples and redundancy levels.

Oracle provides three primary ways to interact with ASM:

ASMCMD – File system like command line tool
oracleasm – OS-level disk management tool (ASMLib)
SQL*Plus as SYSASM – Full SQL based administrative access

Each tool has its own strengths, and some DBAs use all three depending on the task.

## 1. ASMCMD – The Everyday Tool
ASMCMD is a command-line utility that you can use to manage Oracle ASM instances, disk groups, file access control for disk groups, files and directories within disk groups, templates for disk groups, and volumes. 

You can run the ASMCMD utility in either interactive or noninteractive mode. 

Note: File Names are not case sensitive, but are case retentive. If you type a path name as lowercase, ASMCMD retains the lowercase.

Before running asmcmd we need to set 
ORACLE_HOME=ASM_HOME (Grid Home) 
and ORACLE_SID=ASM1 (ASM Instance)

As a best practice, create individual environment variable files: one dedicated to ASM and another for Oracle database operations.

#### asm.env
export ORACLE_SID=+ASM1 \
export ORACLE_HOME=/u01/app/oracle/19.3.0/grid/bin 

#### db.env
export ORACLE_SID=+PROD1 \
export ORACLE_HOME=/u01/app/oracle/19.3.0/db/bin

Tip : asmcmd can be launched either with or without the -p option. When enabled, the -p flag shows the current working directory in the prompt.

## Few asmcmd commands for daily use 
V : Check the Version of ASM \
ls : List disk groups and files \
lsdg : View the information of all disks or of a particular diskgroup disks \
lsdsk : Displays information for all disks or restricts the output to disks within a specified disk group. \
cd : Change directory \
find : Search for files \
du: Checks the space usage of all disk groups or a specified disk group. \
rm : To remove a directory or file \
mkdir : Create a new directory \
iostat : Displays I/O performance statistics for ASM disks and disk groups, similar to the Linux iostat utility \
mount : Mount a Diskgroup \
umount : Unmount a Diskgroup \
help : Displays usage, syntax, and descriptions for specific commands. \

## 2. ORACLEASM – Disk Provisioning Tool
oracleasm is part of ASMLib and is used to label disks at the OS level so ASM can recognize them.

Manage ASM disks by running the following commands from the Linux root level.

Most commonly used ASMLib commands

## 3. SQL*PLUS as SYSASM – Most Powerful Tool 
For advanced ASM administration, the most effective approach is to connect directly to the ASM instance using SQL*Plus.

## How to Connect:

Before running sqlplus as sysasm we need to set 
ORACLE_HOME=ASM_HOME (Grid Home) 
and ORACLE_SID=ASM1 (ASM Instance)

export ORACLE_SID=+ASM1
export ORACLE_HOME=/u01/app/oracle/19.3.0/grid/bin

Choosing the right redundancy while creating disk group is critical for availability and performance.

### External Redundancy

No mirroring by ASM.
Relies on external storage (e.g., SAN RAID, Exadata).
Use Case: When storage array already provides high redundancy.
Lowest overhead, highest usable space.
EXTERNAL REDUNDANCY means ASM does not mirror the data; redundancy is handled by storage (e.g., RAID).

### Normal Redundancy (Default)

Two-way mirroring.
Can survive one disk or one failure group failure.
Requires at least 2 failure groups.
Good balance between protection and space.
It requires additional storage, and more storage ultimately means higher cost.

### High Redundancy

Three-way mirroring.
Can survive two disk or failure group failures.
Requires at least 3 failure groups.
Best for mission-critical databases. 
It requires additional storage, and more storage ultimately means higher cost.

### Create and Alter Diskgroup
### Drop Disks & Disk Group

ASM automatically starts a rebalance when you drop a disk.ASM begins a rebalance to redistribute data from DATA005 to the remaining disks.
The disk is removed only after the rebalance completes.
Higher power → faster rebalance but more CPU/I/O usage.

## TIPS & BEST PRACTICES
1. Always run ASMCMD and SQL*Plus commands as the Grid Infrastructure owner (grid user)
2. Monitor rebalance with V$ASM_OPERATION
3. Document your disk group design and redundancy strategy.
4. Transition away from oracleasm, since it is progressively deprecated in releases after 19c.
5. Regularly test failure scenarios.
