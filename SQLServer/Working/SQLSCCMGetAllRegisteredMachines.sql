/* SCCM: SQL Query to return details on all Machines registerd in the SCCM Database */

-- Includes the following columns: 'Computer Name'; 'Operating System'; 'Service Pack Level'; 'Serial Number'; 'Model'; 'Memory'; IP Address'

select distinct v_R_System_Valid.Netbios_Name0 AS [Computer Name],
 v_GS_OPERATING_SYSTEM.Caption0 AS [Operating System],
 v_GS_OPERATING_SYSTEM.CSDVersion0 AS [Service Pack Level],
 v_GS_SYSTEM_ENCLOSURE_UNIQUE.SerialNumber0 AS [Serial Number],
 v_GS_COMPUTER_SYSTEM.Model0 AS [Model],
 v_GS_X86_PC_MEMORY.TotalPhysicalMemory0 AS [Memory (KBytes)],
 v_RA_System_IPAddresses.IP_Addresses0
FROM v_R_System_Valid
inner join v_GS_OPERATING_SYSTEM on (v_GS_OPERATING_SYSTEM.ResourceID = v_R_System_Valid.ResourceID)
 left join v_GS_SYSTEM_ENCLOSURE_UNIQUE on (v_GS_SYSTEM_ENCLOSURE_UNIQUE.ResourceID = v_R_System_Valid.ResourceID)
 inner join v_GS_COMPUTER_SYSTEM on (v_GS_COMPUTER_SYSTEM.ResourceID = v_R_System_Valid.ResourceID)
 inner join v_GS_X86_PC_MEMORY on (v_GS_X86_PC_MEMORY.ResourceID = v_R_System_Valid.ResourceID)
 inner join v_GS_PROCESSOR on (v_GS_PROCESSOR.ResourceID = v_R_System_Valid.ResourceID)
 inner join v_FullCollectionMembership on (v_FullCollectionMembership.ResourceID = v_R_System_Valid.ResourceID)
left join v_Site on (v_FullCollectionMembership.SiteCode = v_Site.SiteCode)
inner join v_GS_LOGICAL_DISK on (v_GS_LOGICAL_DISK.ResourceID = v_R_System_Valid.ResourceID) and v_GS_LOGICAL_DISK.DeviceID0=SUBSTRING(v_GS_OPERATING_SYSTEM.WindowsDirectory0,1,2)
left join v_GS_SYSTEM_CONSOLE_USAGE_MAXGROUP on (v_GS_SYSTEM_CONSOLE_USAGE_MAXGROUP.ResourceID = v_R_System_Valid.ResourceID)
left join v_RA_System_IPAddresses on (v_FullCollectionMembership.ResourceID = v_RA_System_IPAddresses.ResourceID)
--Where v_FullCollectionMembership.CollectionID = @COLLID
Order by [Computer Name]