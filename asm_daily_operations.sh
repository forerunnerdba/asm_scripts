#################################
#1. ASMCMD – The Everyday Tool
#################################

#As a best practice, create individual environment variable files: one dedicated to ASM and another for Oracle database operations.
 
$ vi asm.env
export ORACLE_SID=+ASM1
export ORACLE_HOME=/u01/app/oracle/19.3.0/grid/bin

#Load asm profile
$ . asm.env

#You can start asmcmd in two modes: with the -p option or without it. The -p flag displays the current working directory in the prompt.
$ asmcmd 

$ asmcmd -p

#You can run ASMCMD in Interactive and Non-Interactive modes.
#Interactive Mode:
$ asmcmd -p
$ ASMCMD [+]
$ ASMCMD [+] > cd DATA
$ ASMCMD [+DATA] > lsdg

#Non-Interactive Mode:
#It's kind of running asmcmd commands in a single line with command options. This is more useful when running asmcmd commands inside a script.
#It exists after generating any output.

$ asmcmd ls -l
$ asmcmd lsdg

#Few asmcmd commands which will be helpful in day to day activities.

#V : Check the Version of ASM
$ asmcmd -V

#V : Check the Version of ASM
$ ASMCMD [+] > ls
$ ASMCMD [+] > ls -l
$ ASMCMD [+] > ls +DATA
$ ASMCMD [+] > ls -l +DATA/ORCL/DATAFILE

#lsdg : View the information of all disks or of a particular diskgroup disks
#list all diskgroups
$ ASMCMD [+] > lsdg

#list ACFSDG DiskGroup
$ ASMCMD [+] > lsdg -G ACFSDG

#lsdsk : Displays information for all disks or restricts the output to disks within a specified disk group.
#list all disks
$ ASMCMD [+] > lsdsk

#Provides details about the disks associated with a specific Diskgroup 
$ ASMCMD [+] > lsdsk -t -G ACFSDG 

#cd : Change directory
$ ASMCMD [+] > cd DATA/USPRD/DATAFILES
$ ASMCMD [+DATA/USPRD/DATAFILES] > cd ..
$ ASMCMD [+DATA/USPRD] >

#find : Search for files
$ ASMCMD [+] > find +DATA -type f -name "*.dbf"

#du: Checks the space usage of all disk groups or a specified disk group.
$ ASMCMD [+] > du -H +ACFSDG

$ ASMCMD [+] > du +DATA/USPRD/DATAFILES
$ ASMCMD [+DATA/USPRD/DATAFILES] > du

#rm : To remove a directory or file
#Remove directory TEMP which is under USPRD parent directory
$ ASMCMD [+DATA/USPRD] > rm TEMP

#Removing a specific file
$ ASMCMD [+DATA/USPRD/TEMP] > rm test.dbf
$ ASMCMD [+DATA/USPRD/TEMP] > rm +DATA/USPRD/CONTROLFILE/current.ctl

#mkdir : Create a new directory
#Creating a single directory
$ ASMCMD [+DATA/USPRD] > mkdir TEMP

#Creating multiple directories
$ ASMCMD [+DATA/USPRD] > mkdir DATAFILES ONLINELOGS TEMPFILE

#iostat : Displays I/O performance statistics for ASM disks and disk groups, similar to the Linux iostat utility
#To display a cumulative I/O statistics for all disks
$ ASMCMD [+] > iostat

#To display a cumulative I/O statistics for a specifi disk group
$ ASMCMD [+] > iostat -G +DATA

#mount : Mount a diskgroup
$ ASMCMD [+] > mount DATA

#umount : To unmount a diskgroup
$ ASMCMD [+] > umount TESTDG

#help : Displays usage, syntax, and descriptions for specific commands.
$ ASMCMD [+] > help du

########################################
#2. ORACLEASM – Disk Provisioning Tool 
########################################

#Most commonly used asmlib commands
#Configure ASM before running asmlib commands
$ oracleasm configure -i

# Initialize the driver
$ oracleasm init

#Start the ASMLib driver using either the /etc/init.d/oracleasm script or the systemctl command.
$ oracleasm start

$ systemctl start oracleasm

#To stop the ASM library driver (oracleasm), execute the command below as root.
#Need to stop database instance, asm before stopping ASMLib driver
$ oracleasm stop

#Restart the Oracle ASMLib service (oracleasm); this performs a graceful stop and start of the driver.
$ oracleasm restart

$ systemctl restart oracleasm

#Check the Status of oracleasm
$ oracleasm status

#Validates the specified ASM disk label and reveals the precise block device it maps to.
$ oracleasm querydisk -p DATA001

#Deletes the ASM Disk
#For RAC setups, create the ASM disk on a single node and perform a scandisk on the other nodes to detect it.
$ oracleasm deletedisk DATA001

#List all Disks
$ oracleasm listdisks

#Creating ASM Disk, 
#For RAC setups, create the ASM disk on a single node and perform a scandisk on the other nodes to detect it.
$ oracleasm createdisk DATA002 /dev/sdc1

#Renames the specified ASM disk label
$ oracleasm renamedisk DATA001 DATA002

#Always run scandisks after creating disk as well as deleting disk.
$ oracleasm scandisks

#############################################
#3. SQL*PLUS as SYSASM – Most Powerful Tool 
#############################################
#Diskgroup Information

SQL> conn /as sysasm

#ASM Instance Status
SQL> SELECT instance_name, status, database_status FROM v$instance;

#Check DiskGroup Information
SQL> select name, total_mb, free_mb from v$asm_diskgroup;

#Create a new Disk Group
#External Redundancy
CREATE DISKGROUP DATA EXTERNAL REDUNDANCY
  DISK '/dev/oracleasm/disks/DATA001',
       '/dev/oracleasm/disks/DATA002',
       '/dev/oracleasm/disks/DATA003';
            
#Normal Redundancy
CREATE DISKGROUP DATA NORMAL REDUNDANCY
  FAILGROUP FG1 DISK '/dev/oracleasm/disks/DATA001',
                     '/dev/oracleasm/disks/DATA002'
  FAILGROUP FG2 DISK '/dev/oracleasm/disks/DATA003',
                     '/dev/oracleasm/disks/DATA004';

#High Redundancy
CREATE DISKGROUP DGCRI HIGH REDUNDANCY
  FAILGROUP FG1 DISK '/dev/oracleasm/disks/DGCRT001'
  FAILGROUP FG2 DISK '/dev/oracleasm/disks/DGCRT002'
  FAILGROUP FG3 DISK '/dev/oracleasm/disks/DGCRT003' ;

#Add disk to the existing diskgroup with rebalance power
ALTER DISKGROUP DATA ADD DISK '/dev/oracleasm/disks/DATA005' REBALANCE POWER 6;

#Drop Disk from existing Disk Group
ALTER DISKGROUP DATA DROP DISK DATA005;

#To control the Rebalance power while dropping disk if we wish to speed up the operation
ALTER DISKGROUP DATA DROP DISK DATA03 REBALANCE POWER 8;

#Monitor the Rebalance operation
SELECT group_number, operation, state, power, sofar, est_work
FROM   v$asm_operation;

#Drop the entire Disk Group
DROP DISKGROUP ACFSDG FORCE INCLUDING CONTENTS;