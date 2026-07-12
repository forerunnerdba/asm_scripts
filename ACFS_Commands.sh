#Before partitioning the storage disks
[root@oradb02 ~]# lsblk
NAME                  MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
fd0                     2:0    1    4K  0 disk
......
......
sdo                     8:224  0   16T  0 disk
sdq                    65:0    0   16T  0 disk
sdv                    65:80   0   16T  0 disk
sdw                    65:96   0   16T  0 disk

#Partitioning the storage
[root@oradb02 ~]# parted /dev/sdo --script mklabel gpt mkpart primary xfs 0% 100%
[root@oradb02 ~]# parted /dev/sdq --script mklabel gpt mkpart primary xfs 0% 100%
[root@oradb02 ~]# parted /dev/sdv --script mklabel gpt mkpart primary xfs 0% 100%
[root@oradb02 ~]# parted /dev/sdw --script mklabel gpt mkpart primary xfs 0% 100%

#Check filesystem after creating partitions
[root@oradb02 ~]# lsblk
NAME                  MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
fd0                     2:0    1    4K  0 disk
.......
.......
sdo                     8:224  0   16T  0 disk
└─sdo1                  8:225  0   16T  0 part
sdq                    65:0    0   16T  0 disk
└─sdq1                 65:1    0   16T  0 part
sdv                    65:80   0   16T  0 disk
└─sdv1                 65:81   0   16T  0 part
sdw                    65:96   0   16T  0 disk
└─sdw1                 65:97   0   16T  0 part


#Create ASM Disks
[root@oradb02 ~]# oracleasm createdisk ACFSDG001 /dev/sdo1
Writing disk header: done
Instantiating disk: done
[root@oradb02 ~]# oracleasm createdisk ACFSDG002 /dev/sdq1
Writing disk header: done
Instantiating disk: done
[root@oradb02 ~]# oracleasm createdisk ACFSDG003 /dev/sdv1
Writing disk header: done
Instantiating disk: done
[root@oradb02 ~]# oracleasm createdisk ACFSDG004 /dev/sdw1
Writing disk header: done
Instantiating disk: done

#Scan ASM Disks - not required after you create disk using oracleasm, but it's always safe if we run scandisks.
[root@oradb02 ~]# oracleasm scandisks
Reloading disk partitions: done
Cleaning any stale ASM disks...
Scanning system for ASM disks...

# List ASM Disks to check the newly created disks
[root@pnapdploradb02 ~]# oracleasm listdisks
ACFSDG001
ACFSDG002
ACFSDG003
ACFSDG004

#Start the acfs
[root@oradb02 ~]# /u01/app/19.3.0/grid/bin/acfsload start
ACFS-9391: Checking for existing ADVM/ACFS installation.
ACFS-9392: Validating ADVM/ACFS installation files for operating system.
ACFS-9393: Verifying ASM Administrator setup.
ACFS-9308: Loading installed ADVM/ACFS drivers.
ACFS-9325:     Driver OS kernel version = 3.10.0-862.el7.x86_64.
ACFS-9326:     Driver build number = 220322.1.
ACFS-9231:     Driver build version = 19.0.0.0.0 (19.15.0.0.0).
ACFS-9547:     Driver available build number = 220322.1.
ACFS-9232:     Driver available build version = 19.0.0.0.0 (19.15.0.0.0).
ACFS-9549:     Kernel and command versions.
Kernel:
    Build version: 19.0.0.0.0
    Build full version: 19.15.0.0.0
    Build hash:    9256567290
    Bug numbers:   NoTransactionInformation
Commands:
    Build version: 19.0.0.0.0
    Build full version: 19.15.0.0.0
    Build hash:    9256567290
    Bug numbers:   NoTransactionInformation
ACFS-9327: Verifying ADVM/ACFS devices.
ACFS-9156: Detecting control device '/dev/asm/.asm_ctl_spec'.
ACFS-9156: Detecting control device '/dev/ofsctl'.
ACFS-9294: updating file /etc/sysconfig/oracledrivers.conf
ACFS-9322: completed

#Displays the currently loaded Linux Kernel Modules of oracle
[root@oradb02 ~]# /sbin/lsmod | grep oracle
oracleacfs           5205867  0
oracleadvm           1172063  0
oracleoks             762371  2 oracleacfs,oracleadvm
oracleasm              59173  1

#Running commands using asmcmd, need to set environmental variables of ORACLE_SID=+ASM1 and ORACLE_HOME=<grid_home>/bin

[oracle@oradb02 ~]$ asmcmd -p
ASMCMD [+] > ls
ACFSDG/


#Creating acfs volume
ASMCMD [+] > volcreate -G ACFSDG -s 63T ACFSFS

#Check acfs volumes
ASMCMD [+] > volinfo --all
Diskgroup Name: ACFSDG

         Volume Name: ACFSFS
         Volume Device: /dev/asm/acfsfs-055
         State: ENABLED
         Size (MB): 66060288
         Resize Unit (MB): 64
         Redundancy: UNPROT
         Stripe Columns: 8
         Stripe Width (K): 1024
         Usage:
         Mountpath:

#In this scenario, the ASM disk group was unexpectedly disconnected/unmounted. Remount the disk group and re‑enable all associated ACFS volumes.
[oracle@oradb02 ~]$ asmcmd -p
ASMCMD [+] > ls
DATA/


#Mounting ASM Diskgroup
ASMCMD [+] > mount ACFSDG

#After mounting the ASM disk group, the ACFS volume shows a DISABLED state. The volume must be re‑enabled to restore functionality
ASMCMD [+] > volinfo --all
Diskgroup Name: ACFSDG

         Volume Name: ACFSFS
         Volume Device: /dev/asm/acfsfs-055
         State: DISABLED
         Size (MB): 66060288
         Resize Unit (MB): 64
         Redundancy: UNPROT
         Stripe Columns: 8
         Stripe Width (K): 1024
         Usage:
         Mountpath:
		 
#Enabling acfs volume
ASMCMD [+] > volenable -G ACFSDG ACFSFS

#Check the volume after enabling
ASMCMD [+] > volinfo --all
Diskgroup Name: ACFSDG

         Volume Name: ACFSFS
         Volume Device: /dev/asm/acfsfs-055
         State: ENABLED
         Size (MB): 66060288
         Resize Unit (MB): 64
         Redundancy: UNPROT
         Stripe Columns: 8
         Stripe Width (K): 1024
         Usage:
         Mountpath:


#Now create an ACFS file system in our file system.
/sbin/mkfs -t acfs /dev/asm/acfsfs-055

#Create mount point for the ACFS file system.
[root@oradb02 /]# mkdir /u12

#Mount the ACFS file system to the mount point.
[root@oradb02 /]#  /bin/mount -t acfs /dev/asm/acfsfs-055 /u12

#Check the file sytem 
[root@oradb02 /]# df -h
Filesystem                                        Size  Used Avail Use% Mounted on
devtmpfs                                          252G     0  252G   0% /dev
/dev/asm/acfsfs-055                               63T  129G   63T   1% /u12



#Creating ACFS volume
ASMCMD [+] > volcreate -G ACFSDG -s 2G ACFSFS

#Check ACFS volume 
ASMCMD [+] > volinfo --all
Diskgroup Name: ACFSDG

         Volume Name: ACFSFS
         Volume Device: /dev/asm/acfsfs-055
         State: ENABLED
         Size (MB): 2048
         Resize Unit (MB): 64
         Redundancy: UNPROT
         Stripe Columns: 8
         Stripe Width (K): 1024
         Usage:
         Mountpath:

#Create an ACFS filesystem in our file system which is of 2GB size
[root@oradb02 ~]# /sbin/mkfs -t acfs /dev/asm/acfsfs-055
mkfs.acfs: version                   = 19.0.0.0.0
mkfs.acfs: on-disk version           = 46.0
mkfs.acfs: volume                    = /dev/asm/acfsfs-055
mkfs.acfs: volume size               = 2147483648  (   2.00 GB )
mkfs.acfs: Format complete.

#Create mount point for the ACFS file system.
[root@oradb02 /]# mkdir /u12

#Mount the ACFS file system to the mount point.
[root@oradb02 ~]# /bin/mount -t acfs /dev/asm/acfsfs-055 /u12
[root@oradb02 ~]# df -h
Filesystem                                                                Size  Used Avail Use% Mounted on
devtmpfs                                                                   32G     0   32G   0% /dev
/dev/asm/acfsfs-055                                                       2.0G  313M  1.7G  16% /u12


#Resize the current ACFS file system to incorporate the newly added OS-level disks.
#At the OS level, we added additional storage, created new ASM disks, and then added those disks to the existing ASM disk group
[root@oradb02 ~]# acfsutil size 1945G /u12
acfsutil size: Resizing file system in steps
acfsutil size: Resizing file system to 0.0176 TB
acfsutil size: Resizing file system to 0.0332 TB
....
....
....
acfsutil size: Resizing file system to 1.8994 TB
acfsutil size: new file system size: 2088427847680 (1991680MB)

#Check the Diskgroup Size
ASMCMD [+] > lsdg -g ACFSDG
Inst_ID  State    Type    Rebal  Sector  Logical_Sector  Block       AU  Total_MB  Free_MB  Req_mir_free_MB  Usable_file_MB  Offline_disks  Voting_files  Name
      1  MOUNTED  EXTERN  N         512             512   4096  4194304   2097144   105348                0          105348              0             N  ACFSDG/

#Check the ACFS volume to confirm that it shows the expanded capacity
ASMCMD [+] > volinfo --all
Diskgroup Name: ACFSDG

         Volume Name: ACFSFS
         Volume Device: /dev/asm/acfsfs-055
         State: ENABLED
         Size (MB): 1991680
         Resize Unit (MB): 64
         Redundancy: UNPROT
         Stripe Columns: 8
         Stripe Width (K): 1024
         Usage: ACFS
         Mountpath: /u12


#Check the file sytem at the OS level.
[root@qnalbploradb02 ~]# df -h
Filesystem                                                                Size  Used Avail Use% Mounted on
devtmpfs                                                                   32G     0   32G   0% /dev
/dev/asm/acfsfs-055                                                       1.9T  4.5G  1.9T   1% /u12


# Ummount and Delete the ACFS Volumes

#Check all the information related to ACFS file system
$/sbin/acfsutil info fs
$/sbin/acfsutil info fs /u12

#Deregister the file system from the ACFS registry
$ /sbin/acfsutil registry -d /dev/asm/acfsfs-055
acfsutil registry: successfully removed ACFS mount point
   /oracle/acfsmounts/acfs1 from Oracle Registry

#After deregistering the file system from the ACFS registry unmount the ACFS mount point
$ /bin/umount -t acfs /dev/asm/acfsfs-055 /u12

#Remove the file system
$ /sbin/acfsutil rmfs /dev/asm/acfsfs-055

#Check all ACFS file systems
$ /sbin/acfsutil info fs

#Now we can disable the ACFS Volume
ASMCMD [+] > voldisable -G ACFSDG ACFSFS

#After disabling the Volume, we can delete ACFS Volume
ASMCMD [+] > voldelete -G ACFSDG ACFSFS
