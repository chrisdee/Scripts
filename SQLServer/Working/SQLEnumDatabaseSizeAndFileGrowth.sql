/* SQL Server:  Query To Get Database Details And File Growth Settings And Sizes For All Databases In An Instance*/

-- Environments: SQL Server 2008 / 2012

declare @GB    float
declare @MB    float
declare @KB    float
declare @B     float

set @GB   =  (cast(8192 as float) / cast(1073741824 as float))
set @MB   =  (cast(8192 as float) / cast(1048576 as float))
set @KB   =  (cast(8192 as float) / cast(1024 as float))
set @B    =  (cast(8192 as float))

select db_name(database_id) as 'Database Name',      
       database_id as 'Database ID',
      (case type
            when 0 then 'Data File'
            when 1 then 'Log File'
            when 2 then 'Filestream File'
            when 3 then 'Other – N/A'
            when 4 then 'Full Text Catalog File'
            else ''
       end) as 'FIle Type',
       name as 'Logical File Name',
       physical_name as 'Physical File Name and Location',
     ((convert(float,size) * CONVERT(float,8)) / CONVERT(float,1024)) as 'Declared Size in MB',
      (case when (cast(size as float) * @GB) > (cast(1 as float))
            then (convert(varchar(16),(cast(size as float) * @GB)) +  ' GB')
            else (case when (cast(size as float) * @MB) > (cast(1 as float))
                       then (convert(varchar(16),(cast(size as float) * @MB)) + ' MB')
                       else (case when (cast(size as float) * @KB) > (cast(1 as float))
                                  then (convert(varchar(16),(cast(size as float) * @KB)) + ' KB')
                                  else ((convert(varchar(16),(cast(size as float) * @B))) + ' Bytes')
                             end)                 
                  end)        
       end) as 'Actual Size',       
      (case when is_percent_growth = 0                  
            then (case when (cast(growth as float) * @GB) > (cast(1 as float))
                       then (convert(varchar(16),(cast(growth as float) * @GB)) +  ' GB')
                       else (case when (cast(growth as float) * @MB) > (cast(1 as float))
                                  then  (convert(varchar(16),(cast(growth as float) * @MB)) + ' MB')
                                  else (case when (cast(growth as float) * @KB) > (cast(1 as float))
                                             then (convert(varchar(16),(cast(growth as float) * @KB)) + ' KB')
                                             else ((convert(varchar(16),(cast(growth as float) * @B))) + ' Bytes')
                                        end)
                             end)
                  end)
            when is_percent_growth = 1
            then (case growth
                       when 0 then 'N/A'
                       else (convert(varchar(16),(cast(growth as float))) + ' %')
                  end)
            else ''
       end) as 'Growth Method'
 from  master.sys.master_files
 order by database_id, type, size desc