/* MOSS 2007: SQL Query To Report On Your Document Versions Over Time */
-- Resource: http://todd-carter.com/post/2010/12/14/How-Many-Versions-Do-You-Have.aspx
-- Includes history of versions over the years
-- Also includes a summary of all version numbers along with sizes and total counts

WITH VersionAgeTable
AS
(
SELECT  DATEDIFF(year, [TimeCreated], GETUTCDATE()) AS [YearsOfAge],
        SUM(CAST([Size] AS BIGINT)) AS [SizeByYear],
        COUNT(*) AS [DocCountByYear]
FROM [dbo].[AllDocVersions] WITH (NOLOCK)
GROUP BY DATEDIFF(year, [TimeCreated], GETUTCDATE())
)
SELECT  d.[YearsOfAge],
        d.[SizeByYear] AS [SizeByYear],
        (SELECT SUM([SizeByYear]) FROM VersionAgeTable WHERE [YearsOfAge] >= d.[YearsOfAge]) AS [TotalSize],
        d.[DocCountByYear] AS [DocCountByYear],
        (SELECT SUM([DocCountByYear]) FROM VersionAgeTable WHERE [YearsOfAge] >= d.[YearsOfAge]) AS [TotalDocCount]
FROM VersionAgeTable AS d
ORDER BY d.[YearsOfAge];
 
 
WITH VersionTable
AS
(
    SELECT  [Version]/512 AS [Version],
            SUM(CAST([Size] AS BIGINT)) AS [SizeByVersion],
            COUNT(*) AS [DocCountByVersion]
    FROM [dbo].[AllDocVersions] WITH (NOLOCK)
    GROUP BY [Version]/512
)
SELECT  d.[Version],
        d.[SizeByVersion] AS [SizeByVersion],
        (SELECT SUM([SizeByVersion]) FROM VersionTable WHERE [Version] >= d.[Version]) AS [TotalSize],
        d.[DocCountByVersion] AS [DocCountByVersion],
        (SELECT SUM([DocCountByVersion]) FROM VersionTable WHERE [Version] >= d.[Version]) AS [TotalDocCount]
FROM VersionTable AS d
ORDER BY d.[Version];


/* SharePoint Server 2010: SQL Query To Report On Your Document Versions Over Time */
-- Resource: http://todd-carter.com/post/2010/12/14/How-Many-Versions-Do-You-Have.aspx
-- Includes history of versions over the years
-- Also includes a summary of all version numbers along with sizes and total counts

WITH VersionAgeTable
AS
(
SELECT  DATEDIFF(year, [TimeCreated], GETUTCDATE()) AS [YearsOfAge],
        SUM(CAST([Size] AS BIGINT)) AS [SizeByYear],
        COUNT(*) AS [DocCountByYear]
FROM [dbo].[AllDocVersions] WITH (NOLOCK)
GROUP BY DATEDIFF(year, [TimeCreated], GETUTCDATE())
)
SELECT  d.[YearsOfAge],
        d.[SizeByYear] AS [SizeByYear],
        (SELECT SUM([SizeByYear]) FROM VersionAgeTable WHERE [YearsOfAge] >= d.[YearsOfAge]) AS [TotalSize],
        d.[DocCountByYear] AS [DocCountByYear],
        (SELECT SUM([DocCountByYear]) FROM VersionAgeTable WHERE [YearsOfAge] >= d.[YearsOfAge]) AS [TotalDocCount]
FROM VersionAgeTable AS d
ORDER BY d.[YearsOfAge];
 
 
WITH VersionTable
AS
(
    SELECT  [InternalVersion]/512 AS [Version],
            SUM(CAST([Size] AS BIGINT)) AS [SizeByVersion],
            COUNT(*) AS [DocCountByVersion]
    FROM [dbo].[AllDocVersions] WITH (NOLOCK)
    GROUP BY [InternalVersion]/512
)
SELECT  d.[Version],
        d.[SizeByVersion] AS [SizeByVersion],
        (SELECT SUM([SizeByVersion]) FROM VersionTable WHERE [Version] >= d.[Version]) AS [TotalSize],
        d.[DocCountByVersion] AS [DocCountByVersion],
        (SELECT SUM([DocCountByVersion]) FROM VersionTable WHERE [Version] >= d.[Version]) AS [TotalDocCount]
FROM VersionTable AS d
ORDER BY d.[Version];