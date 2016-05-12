SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_CalcElapsedTime](@startTime DATETIME, @stopTime DATETIME)
	RETURNS VARCHAR(255) AS
BEGIN

declare @elapsed_time datetime
declare @elapsed_days int
declare @elapsed_hours int
declare @elapsed_minutes int
declare @elapsed_seconds int
declare @elapsed_milliseconds int

select @elapsed_time = @stopTime - @startTime
select @elapsed_days = datediff(day,0,@elapsed_time)
select @elapsed_hours = datepart(hour,@elapsed_time)
select @elapsed_minutes = datepart(minute,@elapsed_time)
select @elapsed_seconds = datepart(second,@elapsed_time)
select @elapsed_milliseconds = datepart(millisecond,@elapsed_time)

DECLARE @retVal VARCHAR(255)
SET @retVal = 
	RIGHT('00' + convert(varchar(20),@elapsed_hours), 2) + ':'
	+ RIGHT('00' + convert(varchar(20),@elapsed_minutes), 2) + ':'
	+ RIGHT('00' + convert(varchar(20),@elapsed_seconds), 2)+ '.'
	+ RIGHT('000' + convert(varchar(20), @elapsed_milliseconds), 3)
RETURN @retVal

END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_CalcGrossProfit](@retail NUMERIC(18,4), @cost NUMERIC(18,4))
	RETURNS NUMERIC(18,4) AS
BEGIN
 
DECLARE @grossProfit NUMERIC(18,4)
SET @grossProfit = (@retail-@cost) / @retail * 100.00
RETURN @grossProfit

END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[fn_CalcGrossProfitPct](@cost DECIMAL(10,4), @price DECIMAL(10,4), @roundTo INT)
RETURNS DECIMAL(10,4)
AS
BEGIN
 
	DECLARE @retVal DECIMAL(10,4)
	IF @price = 0 BEGIN
		SET @retVal = 0
	END ELSE BEGIN
		SET @retVal = ROUND((@price-@cost) / @price * 100, @roundTo)
	END
	RETURN @retVal

END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[fn_CalcPercentChange](@newValue NUMERIC(18,4), @old NUMERIC(18,4))
	RETURNS NUMERIC(18,4) AS
BEGIN
 
DECLARE @retVal NUMERIC(18,4)
IF ISNULL(@old, 0.00) = 0 BEGIN 
	SET @retVal = 0.00
END ELSE BEGIN
	SET @retVal = (@newValue - @old) / @old * 100
END
RETURN @retVal

END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_DateTimeToDateOnly](@someDate DATETIME)
	RETURNS DATETIME AS
BEGIN

RETURN CAST(CONVERT(VARCHAR, @someDate, 101) AS DATETIME)

END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_FormatBitForAudit](@someBit BIT)
	RETURNS VARCHAR(3) AS
BEGIN

RETURN CASE @someBit WHEN 1 THEN 'Yes' ELSE 'No' END

END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_GetAuditMode]()
RETURNS TINYINT 

AS
BEGIN

DECLARE @ci BINARY(128)
-- this works on SQL2005/SQL2008
SET @ci = CONTEXT_INFO()
-- this works on SQL2000
-- SELECT @ci = context_info FROM master.dbo.sysprocesses WHERE spid = @@SPID

DECLARE @auditMode TINYINT
SET @auditMode = 1
IF @ci <> 0x00 BEGIN
	SET @auditMode = CAST(SUBSTRING(@ci, 1, 1) AS TINYINT)
	IF @auditMode IS NULL BEGIN
		SET @auditMode = 1
	END
END

RETURN @auditMode

END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fn_GetChangeTrackingMode]() RETURNS TINYINT AS BEGIN

DECLARE @ci BINARY(128)
-- this works on SQL2005/SQL2008
SET @ci = CONTEXT_INFO()
-- this works on SQL2000
-- SELECT @ci = context_info FROM master.dbo.sysprocesses WHERE spid = @@SPID

DECLARE @mode TINYINT
SET @mode = 1
IF @ci <> 0x00 BEGIN
	SET @mode = CAST(SUBSTRING(@ci, 2, 1) AS TINYINT)
	IF @mode IS NULL BEGIN
		SET @mode = 1
	END
END
RETURN @mode
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[fn_GetContextInfo](@now DATETIME)
RETURNS @auditInfo TABLE
(
  AuditMode TINYINT,
  ChangeTrackMode TINYINT,
  AuditTime DATETIME,
  UserName VARCHAR(50),
  AuditSource VARCHAR(50),
  ExtraInfo VARCHAR(255)
)
AS
BEGIN

DECLARE @ci BINARY(128)

-- this works on SQL2005/SQL2008
SET @ci = CONTEXT_INFO()

-- this works on SQL2000
--SELECT @ci = context_info FROM master.dbo.sysprocesses WHERE spid = @@SPID

DECLARE @m1 INT
DECLARE @m2 INT
DECLARE @m3 INT
SET @m1 = CHARINDEX(0x01, @ci, 3)
SET @m2 = CHARINDEX(0x02, @ci)
SET @m3 = CHARINDEX(0x03, @ci)

DECLARE @auditMode TINYINT
DECLARE @changeTrackMode TINYINT
DECLARE @userName VARCHAR(50)
DECLARE @auditSource VARCHAR(50)
DECLARE @extraInfo VARCHAR(255)

-- AuditMode
SET @auditMode = CAST(SUBSTRING(@ci, 1, 1) AS TINYINT)
IF @auditMode IS NULL BEGIN
	SET @auditMode = 1
END

-- ChangeTrackMode
SET @changeTrackMode = CAST(SUBSTRING(@ci, 2, 1) AS TINYINT)
IF @changeTrackMode IS NULL BEGIN
	SET @changeTrackMode = 1
END

-- UserName, AuditSource, ExtraInfo

IF @m1 > 0 AND @m2 > 0 AND @m3 > 0 BEGIN
	SET @userName = CAST(SUBSTRING(@ci, 3, @m1-3) AS VARCHAR)
	SET @auditSource = CAST(SUBSTRING(@ci, @m1+1, @m2-@m1-1) AS VARCHAR)
	SET @extraInfo = CAST(SUBSTRING(@ci, @m2+1, @m3-@m2-1) AS VARCHAR)
END

IF ISNULL(@userName,'') = '' SET @userName = SYSTEM_USER
IF ISNULL(@auditSource,'') = ''  SET @auditSource = APP_NAME()
IF ISNULL(@extraInfo,'') = '' SET @extraInfo = NULL

INSERT INTO @auditInfo VALUES (@auditMode, @changeTrackMode, @now, @userName, @auditSource, @extraInfo)
RETURN

END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_GetSystemOptionAsSMALLINT](@optionName VARCHAR(50))
	RETURNS SMALLINT AS
BEGIN
 
DECLARE @val SMALLINT
SELECT 
	@val = CONVERT(SMALLINT, option_value) 
FROM 
	s3_system_option 
WHERE 
	option_name = @optionName
RETURN @val
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fn_Iss45ComparativePrice](@price SMALLMONEY, @multiple SMALLINT, @size NUMERIC(8,3), @uomDescr VARCHAR(30), @comparativeUom TINYINT, @unitFactor INT)
	RETURNS SMALLMONEY AS
BEGIN

DECLARE @retval SMALLMONEY
IF @price = 0 BEGIN
	RETURN @price
END

IF @size = 0 BEGIN
	RETURN 0
END

IF ISNULL(@unitFactor, 0) = 0 BEGIN
	SET @unitFactor = 1
END

DECLARE @unitPrice SMALLMONEY
IF ISNULL(@multiple,1) < 2 BEGIN
	SET @unitPrice = @price
END ELSE BEGIN
	SET @unitPrice = @price / CASE WHEN @multiple < 1 THEN 1 ELSE @multiple END
END

DECLARE @uomNum TINYINT
SELECT @uomNum = AltUomNmbr FROM Uom WHERE UomDescr = @uomDescr

DECLARE @convFactor FLOAT
SET @convFactor = 1.0

IF @uomNum = 1 BEGIN
  SET @convFactor = CASE
    WHEN @comparativeUom = 2 THEN 16
    WHEN @comparativeUom = 7 THEN 0.0352736
    WHEN @comparativeUom = 8 THEN 35.2736
    ELSE 1.0
  END
END

IF @uomNum = 2 BEGIN
  SET @convFactor = CASE
    WHEN @comparativeUom = 1 THEN 0.0625
    WHEN @comparativeUom = 7 THEN 0.0022046
    WHEN @comparativeUom = 8 THEN 2.20462
    ELSE 1.0
  END
END

IF @uomNum = 3 BEGIN
  SET @convFactor = CASE
    WHEN @comparativeUom = 4 THEN 0.001
    WHEN @comparativeUom = 13 THEN 3.785412
    WHEN @comparativeUom = 14 THEN 0.9463529
    WHEN @comparativeUom = 15 THEN 0.4731765
    WHEN @comparativeUom = 20 THEN 0.02957353
    WHEN @comparativeUom = $0 THEN $1
    ELSE 1.0
  END
END

IF @uomNum = 4 BEGIN
  SET @convFactor = CASE
    WHEN @comparativeUom = 3 THEN 1000
    WHEN @comparativeUom = 13 THEN 3785.412
    WHEN @comparativeUom = 14 THEN 946.35313
    WHEN @comparativeUom = 15 THEN 473.17656
    WHEN @comparativeUom = 20 THEN 29.57353
    ELSE 1.0
  END
END

IF @uomNum = 7 BEGIN
  SET @convFactor = CASE
    WHEN @comparativeUom = 1 THEN 28.34952
    WHEN @comparativeUom = 2 THEN 453.59237
    WHEN @comparativeUom = 8 THEN 1000
    ELSE 1.0
  END
END

IF @uomNum = 8 BEGIN
  SET @convFactor = CASE
    WHEN @comparativeUom = 1 THEN 0.02834952
    WHEN @comparativeUom = 2 THEN 0.4535924
    WHEN @comparativeUom = 7 THEN 0.001
    ELSE 1.0
  END
END

IF @uomNum = 9 BEGIN
  SET @convFactor = CASE
    WHEN @comparativeUom = 10 THEN 0.0254
    WHEN @comparativeUom = 11 THEN 0.3048
    WHEN @comparativeUom = 12 THEN 0.9144
    ELSE 1.0
  END
END

IF @uomNum = 10 BEGIN
  SET @convFactor = CASE
    WHEN @comparativeUom = 9 THEN 39.3701
    WHEN @comparativeUom = 11 THEN 12
    WHEN @comparativeUom = 12 THEN 36
    ELSE 1.0
  END
END

IF @uomNum = 11 BEGIN
  SET @convFactor = CASE
    WHEN @comparativeUom = 10 THEN 0.08333333
    WHEN @comparativeUom = 12 THEN 3
    ELSE 1.0
  END
END

IF @uomNum = 12 BEGIN
  SET @convFactor = CASE
    WHEN @comparativeUom = 9 THEN 1.09361
    WHEN @comparativeUom = 10 THEN 0.02777777
    WHEN @comparativeUom = 11 THEN 0.3333333
    ELSE 1.0
  END
END

IF @uomNum = 13 BEGIN
  SET @convFactor = CASE
    WHEN @comparativeUom = 3 THEN 0.26417205
    WHEN @comparativeUom = 4 THEN 0.000264172
    WHEN @comparativeUom = 14 THEN 0.25
    WHEN @comparativeUom = 15 THEN 0.125
    WHEN @comparativeUom = 20 THEN 0.0078125
    ELSE 1.0
  END
END

IF @uomNum = 14 BEGIN
  SET @convFactor = CASE
    WHEN @comparativeUom = 4 THEN 0.001056688
    WHEN @comparativeUom = 13 THEN 4
    WHEN @comparativeUom = 15 THEN 0.5
    WHEN @comparativeUom = 20 THEN 0.03125
    ELSE 1.0
  END
END

IF @uomNum = 15 BEGIN
  SET @convFactor = CASE
    WHEN @comparativeUom = 3 THEN 2.113376
    WHEN @comparativeUom = 4 THEN 0.002113376
    WHEN @comparativeUom = 13 THEN 8
    WHEN @comparativeUom = 14 THEN 2
    WHEN @comparativeUom = 20 THEN 0.0625
    ELSE 1.0
  END
END

IF @uomNum = 20 BEGIN
  SET @convFactor = CASE
    WHEN @comparativeUom = 3 THEN 33.81402
    WHEN @comparativeUom = 4 THEN 0.03381402
    WHEN @comparativeUom = 13 THEN 128
    WHEN @comparativeUom = 14 THEN 32
    WHEN @comparativeUom = 15 THEN 16
    ELSE 1.0
  END
END

IF @uomNum = 21 BEGIN
  SET @convFactor = CASE
    WHEN @comparativeUom = 22 THEN 0.11111
    ELSE 1.0
  END
END

IF @uomNum = 22 BEGIN
  SET @convFactor = CASE
    WHEN @comparativeUom = 21 THEN 9
    ELSE 1.0
  END
END
	

RETURN @unitPrice / @size * @convFactor * @unitFactor

END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_Iss45UomToDescr](@code TINYINT)
	RETURNS VARCHAR(30) AS
BEGIN

DECLARE @retVal VARCHAR(30)
SET @retVal = CASE
	WHEN @code=1 THEN  'Ounce' 
	WHEN @code=2 THEN  'Pound' 
	WHEN @code=3 THEN  'Liter' 
	WHEN @code=4 THEN  'Milliliter' 
	WHEN @code=5 THEN  'Box' 
	WHEN @code=6 THEN  'Package' 
	WHEN @code=7 THEN  'Gram' 
	WHEN @code=8 THEN  'Kilogram' 
	WHEN @code=9 THEN  'Meter' 
	WHEN @code=10 THEN  'Inch' 
	WHEN @code=11 THEN  'Foot' 
	WHEN @code=12 THEN  'Yard' 
	WHEN @code=13 THEN  'Gallon' 
	WHEN @code=14 THEN  'Quart' 
	WHEN @code=15 THEN  'Pint' 
	WHEN @code=16 THEN  'Carton' 
	WHEN @code=17 THEN  'Case' 
	WHEN @code=18 THEN  'Count' 
	WHEN @code=19 THEN  'Each' 
	WHEN @code=20 THEN  'Fluid Oz' 
	WHEN @code=21 THEN  'Sq Yard' 
	WHEN @code=22 THEN  'Sq Feet' 
	WHEN @code=23 THEN  'Units' 
END
RETURN @retVal
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[fn_Split](@text varchar(8000), @delimiter varchar(20) = ' ')
RETURNS @Strings TABLE
(   
  position int IDENTITY PRIMARY KEY,
  value varchar(8000)  
)
AS
BEGIN
 
DECLARE @index int
SET @index = -1
 
WHILE (LEN(@text) > 0)
  BEGIN 
    SET @index = CHARINDEX(@delimiter , @text) 
    IF (@index = 0) AND (LEN(@text) > 0) 
      BEGIN  
        INSERT INTO @Strings VALUES (@text)
          BREAK 
      END 
    IF (@index > 1) 
      BEGIN  
        INSERT INTO @Strings VALUES (LEFT(@text, @index - 1))  
        SET @text = RIGHT(@text, (LEN(@text) - @index)) 
      END 
    ELSE
      SET @text = RIGHT(@text, (LEN(@text) - @index))
    END
  RETURN
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[fn_SplitINT](@text varchar(8000), @delimiter varchar(20) = ' ')
RETURNS @entries TABLE
(   
  position int IDENTITY PRIMARY KEY,
  value INT
)
AS
BEGIN
 
DECLARE @index int
SET @index = -1
 
WHILE (LEN(@text) > 0)
  BEGIN 
    SET @index = CHARINDEX(@delimiter , @text) 
    IF (@index = 0) AND (LEN(@text) > 0) 
      BEGIN  
        INSERT INTO @entries VALUES (CAST(@text AS INT))
          BREAK 
      END 
    IF (@index > 1) 
      BEGIN  
        INSERT INTO @entries VALUES (CAST(LEFT(@text, @index - 1) AS INT))  
        SET @text = RIGHT(@text, (LEN(@text) - @index)) 
      END 
    ELSE
      SET @text = RIGHT(@text, (LEN(@text) - @index))
    END
  RETURN
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fn_SplitUpcList] (@text VARCHAR(MAX))

RETURNS @t TABLE ( [position] INT IDENTITY PRIMARY KEY, [Upc] CHAR(13) )   
AS
BEGIN
    DECLARE @xml XML
    SET @XML = N'<root><r>' + REPLACE(@text, ',', '</r><r>') + '</r></root>'

    INSERT INTO @t([Upc])
    SELECT r.value('.','VARCHAR(MAX)') AS Item
    FROM @xml.nodes('//root/r') AS RECORDS(r)

    RETURN
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fn_Today] 
(
)
RETURNS DATETIME
AS
BEGIN
	RETURN CAST(CONVERT(VARCHAR, GETDATE(), 101) AS DATETIME)
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AllowBatchDetail](
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AbId] [int] NOT NULL,
	[AllowAmt] [decimal](18, 4) NOT NULL,
	[CommonDealType] [bigint] NOT NULL,
 CONSTRAINT [PK_AllowBatchDetail] PRIMARY KEY CLUSTERED 
(
	[AbId] ASC,
	[Upc] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AllowBatchHeader](
	[AbId] [int] NOT NULL,
	[AbDescr] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SupplierId] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StartDt] [datetime] NOT NULL,
	[EndDt] [datetime] NOT NULL,
	[HostKey] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_AllowBatchHeader] PRIMARY KEY CLUSTERED 
(
	[AbId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AllowBatchStore](
	[AbId] [int] NOT NULL,
	[StoreId] [smallint] NOT NULL,
 CONSTRAINT [PK_AllowBatchStore] PRIMARY KEY CLUSTERED 
(
	[AbId] ASC,
	[StoreId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Batch](
	[BatchId] [int] NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[BatchType] [char](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ShortDescription] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CreateDatetime] [datetime] NOT NULL,
	[CreateLoginName] [varchar](25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ClosedDatetime] [datetime] NULL,
	[PolledDatetime] [datetime] NULL,
	[CertifyDatetime] [datetime] NULL,
	[CertifyLoginName] [char](25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comments] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[HistoryDatetime] [datetime] NULL,
	[HistoryLoginName] [char](25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_Batch] PRIMARY KEY CLUSTERED 
(
	[BatchId] ASC,
	[StoreId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BatchDescriptionMaster](
	[BatchType] [char](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ShortDescription] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Comments] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[BalancingBatchShortDescription] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_BatchDescriptionMaster] PRIMARY KEY NONCLUSTERED 
(
	[BatchType] ASC,
	[ShortDescription] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BatchItem](
	[BatchId] [int] NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[DepartmentId] [smallint] NOT NULL,
	[Qty] [decimal](18, 9) NOT NULL,
	[RegPriceAmt] [smallmoney] NOT NULL,
	[RegPriceMult] [int] NOT NULL,
	[RegUnitCost] [smallmoney] NOT NULL,
	[SalePriceAmt] [smallmoney] NOT NULL,
	[SalePriceMult] [int] NOT NULL,
	[SaleUnitCost] [smallmoney] NOT NULL,
	[Deposit] [decimal](18, 9) NOT NULL,
 CONSTRAINT [PK_BatchItem_1] PRIMARY KEY CLUSTERED 
(
	[BatchId] ASC,
	[StoreId] ASC,
	[Upc] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BatchTypeMaster](
	[BatchType] [char](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ShortDescription] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comments] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_BatchTypeMaster] PRIMARY KEY NONCLUSTERED 
(
	[BatchType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BillbackDetail](
	[BbNmbr] [int] NOT NULL,
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[BatchId] [int] NOT NULL,
 CONSTRAINT [PK_BillbackDetail] PRIMARY KEY CLUSTERED 
(
	[BbNmbr] ASC,
	[Upc] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BillbackHeader](
	[BbNmbr] [int] NOT NULL,
	[BbTypeCd] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StartDt] [datetime] NOT NULL,
	[EndDt] [datetime] NOT NULL,
	[BbAmt] [decimal](18, 2) NOT NULL,
 CONSTRAINT [PK_BillbackHeader] PRIMARY KEY CLUSTERED 
(
	[BbNmbr] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BillbackStore](
	[BbNmbr] [int] NOT NULL,
	[StoreId] [smallint] NOT NULL,
 CONSTRAINT [PK_BillbackStore] PRIMARY KEY CLUSTERED 
(
	[BbNmbr] ASC,
	[StoreId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BillbackType](
	[BbTypeCd] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[BbTypeDescr] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_BillbackType] PRIMARY KEY CLUSTERED 
(
	[BbTypeCd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Brand](
	[BrandId] [int] IDENTITY(1,1) NOT NULL,
	[BrandName] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_Brand] PRIMARY KEY CLUSTERED 
(
	[BrandId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CatClass](
	[CatClassId] [int] NOT NULL,
	[CatClassType] [tinyint] NOT NULL,
	[EndCatClass] [int] NULL,
	[CatClassDescr] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DepartmentId] [smallint] NULL,
	[LblSizeCd] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_CatClass] PRIMARY KEY CLUSTERED 
(
	[CatClassId] ASC,
	[CatClassType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChangeRequest](
	[RequestTime] [datetime] NOT NULL,
	[StoreId] [int] NOT NULL,
	[UserName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ColName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ReqValue] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[NotOnFile] [bit] NOT NULL,
 CONSTRAINT [PK_ChangeRequest_1] PRIMARY KEY CLUSTERED 
(
	[RequestTime] ASC,
	[StoreId] ASC,
	[UserName] ASC,
	[Upc] ASC,
	[ColName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChangesChangeRequest](
	[RowId] [bigint] IDENTITY(1,1) NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[ChgType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ChgTmsp] [datetime2](7) NOT NULL,
	[SrcTable] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[TrgType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[RequestTime] [datetime] NOT NULL,
	[UserName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ColName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_ChangesChangeRequest] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChangesInvoiceHeader](
	[RowId] [bigint] IDENTITY(1,1) NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[ChgType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ChgTmsp] [datetime2](7) NOT NULL,
	[SrcTable] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[TrgType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[InvId] [int] NOT NULL,
 CONSTRAINT [PK_ChangesInvoiceHeader] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChangesIss45MemberProm](
	[RowId] [bigint] IDENTITY(1,1) NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[ChgType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ChgTmsp] [datetime2](7) NOT NULL,
	[SrcTable] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[TrgType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[MMBR_PROM_ID] [float] NOT NULL,
 CONSTRAINT [PK_ChangesIss45MemberProm] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChangesOnHand](
	[RowId] [bigint] IDENTITY(1,1) NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[ChgType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ChgTmsp] [datetime2](7) NOT NULL,
	[SrcTable] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[TrgType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_ChangesOnHand] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChangesPriceBatch](
	[RowId] [bigint] IDENTITY(1,1) NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[ChgType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ChgTmsp] [datetime2](7) NOT NULL,
	[SrcTable] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[TrgType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[BatchId] [int] NOT NULL,
	[Description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_ChangesPriceBatch] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChangesProdPosIbmSa](
	[RowId] [bigint] IDENTITY(1,1) NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[ChgType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ChgTmsp] [datetime2](7) NOT NULL,
	[SrcTable] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[TrgType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_ChangesProdPosIbmSa] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChangesProdPosIss45](
	[RowId] [bigint] IDENTITY(1,1) NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[ChgType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ChgTmsp] [datetime2](7) NOT NULL,
	[SrcTable] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[TrgType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_ChangesProdPosIss45] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChangesProdPrice](
	[RowId] [bigint] IDENTITY(1,1) NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[ChgType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ChgTmsp] [datetime2](7) NOT NULL,
	[SrcTable] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[TrgType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[PriceType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_ChangesProdPrice] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChangesProdStore](
	[RowId] [bigint] IDENTITY(1,1) NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[ChgType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ChgTmsp] [datetime2](7) NOT NULL,
	[SrcTable] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[TrgType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_ChangesProdStore] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChangesRealtimeSalesSummary](
	[RowId] [bigint] IDENTITY(1,1) NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[ChgType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ChgTmsp] [datetime2](7) NOT NULL,
	[SrcTable] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[TrgType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_ChangesRealtimeSalesSummary] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChangesSpartanPriceAuditDetail](
	[RowId] [bigint] IDENTITY(1,1) NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[ChgType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ChgTmsp] [datetime2](7) NOT NULL,
	[SrcTable] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[TrgType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AuditDate] [datetime] NOT NULL,
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_ChangesSpartanPriceAuditDetail] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChargeType](
	[ChargeType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ChargeDescription] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_ChargeType_1] PRIMARY KEY CLUSTERED 
(
	[ChargeType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [PK_ChargeType] UNIQUE NONCLUSTERED 
(
	[ChargeType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CompetPrice](
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[CompetId] [int] NOT NULL,
	[EffDate] [datetime2](7) NOT NULL,
	[PriceMult] [int] NOT NULL,
	[PriceAmt] [decimal](18, 2) NOT NULL,
	[CompetUpc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_CompetPrice] PRIMARY KEY CLUSTERED 
(
	[Upc] ASC,
	[StoreId] ASC,
	[CompetId] ASC,
	[EffDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CsChangesManifest](
	[StoreId] [smallint] NOT NULL,
	[ManifestId] [float] NOT NULL,
	[ChangeRequest] [bigint] NOT NULL,
	[ProdPrice] [bigint] NOT NULL,
	[ProdStore] [bigint] NOT NULL,
	[ProdPosIbmSa] [bigint] NOT NULL,
	[ProdPosIss45] [bigint] NOT NULL,
	[InvoiceHeader] [bigint] NOT NULL,
	[PriceBatch] [bigint] NOT NULL,
	[RealtimeSales] [datetime] NOT NULL,
	[OnHand] [bigint] NOT NULL,
 CONSTRAINT [PK_CsChangesManifest] PRIMARY KEY CLUSTERED 
(
	[StoreId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CstBatchDetail](
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CbId] [int] NOT NULL,
	[OrderCode] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CaseCost] [decimal](18, 4) NULL,
	[CasePack] [int] NULL,
	[HasProcessed] [bit] NOT NULL,
 CONSTRAINT [PK_CstBatchDetail] PRIMARY KEY CLUSTERED 
(
	[CbId] ASC,
	[Upc] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CstBatchHeader](
	[CbId] [int] NOT NULL,
	[SupplierId] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SupplierZoneId] [int] NOT NULL,
	[CbDescr] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StartDt] [datetime] NOT NULL,
 CONSTRAINT [PK_CstBatchHeader] PRIMARY KEY CLUSTERED 
(
	[CbId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CtsErrorLog](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[LogTime] [datetime] NOT NULL,
	[Json] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ProcessTime] [datetime] NULL,
	[Program] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[MachineName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ExceptionType] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ExceptionMessage] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AppUserName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DoNotSubmit] [bit] NOT NULL,
 CONSTRAINT [PK_ErrorLog] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CtsGroup](
	[GroupName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_CtsGroup] PRIMARY KEY CLUSTERED 
(
	[GroupName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CtsGroupPermission](
	[GroupName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ModuleName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_CtsGroupPermission] PRIMARY KEY CLUSTERED 
(
	[GroupName] ASC,
	[ModuleName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CtsSecurableItem](
	[ModuleName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CategoryName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ModuleDescr] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_CtsSecurableItem] PRIMARY KEY CLUSTERED 
(
	[ModuleName] ASC,
	[CategoryName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CtsSystemOption](
	[OptionName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[OptionValue] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_CtsSystemOption] PRIMARY KEY CLUSTERED 
(
	[OptionName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CtsSystemOptionSet](
	[OptionSetName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[OptionSetData] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_CtsSystemOptionSet] PRIMARY KEY CLUSTERED 
(
	[OptionSetName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CtsUser](
	[UserName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Password] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[IsDisabled] [bit] NOT NULL,
	[EmailAddress] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[IsSuperUser] [bit] NOT NULL,
	[FullName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Comments] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[PasswordChangeRequired] [bit] NOT NULL,
	[LastPasswordChangeDate] [datetime] NOT NULL,
 CONSTRAINT [PK_CtsUser] PRIMARY KEY CLUSTERED 
(
	[UserName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CtsUserGroup](
	[UserName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[GroupName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_CtsUserGroup] PRIMARY KEY CLUSTERED 
(
	[UserName] ASC,
	[GroupName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CtsUserOptionSet](
	[UserName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[OptionSetName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[OptionSetData] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_CtsUserOptionSet] PRIMARY KEY CLUSTERED 
(
	[UserName] ASC,
	[OptionSetName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[date_dim](
	[date_key] [int] NOT NULL,
	[calendar_date] [smalldatetime] NOT NULL,
	[sales_year] [int] NOT NULL,
	[sales_week] [int] NOT NULL,
	[sales_quarter] [varchar](3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[sales_period] [int] NULL,
	[day_in_sales_year] [int] NULL,
	[day_in_sales_quarter] [int] NULL,
	[day_in_sales_period] [int] NULL,
	[day_in_sales_week] [int] NULL,
	[day_of_week] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[calendar_year] [int] NOT NULL,
	[calendar_month] [int] NOT NULL,
	[calendar_week] [int] NOT NULL,
	[calendar_quarter] [int] NOT NULL,
	[day_in_calendar_year] [int] NULL,
	[day_of_week_num] [tinyint] NULL,
	[date_month_text] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[absolute_day] [int] NULL,
	[absolute_week] [int] NULL,
 CONSTRAINT [PK_date_dim] PRIMARY KEY CLUSTERED 
(
	[date_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [IX_date] UNIQUE NONCLUSTERED 
(
	[calendar_date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DbVersion](
	[Timestamp] [bigint] NOT NULL,
	[Module] [nvarchar](250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Tag] [nvarchar](2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ExecutedTime] [datetime] NOT NULL,
 CONSTRAINT [PK_DbVersion] PRIMARY KEY CLUSTERED 
(
	[Timestamp] ASC,
	[Module] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DealType](
	[DealType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[DealDescription] [varchar](40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_DealType_1] PRIMARY KEY CLUSTERED 
(
	[DealType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [PK_DealType] UNIQUE NONCLUSTERED 
(
	[DealType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DeletedProductBatchDetail](
	[SessionId] [uniqueidentifier] NOT NULL,
	[UPC] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[BatchId] [int] NOT NULL,
	[BatchPriceMethod] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[BatchDealQty] [smallint] NULL,
	[BatchSpecialPrice] [smallmoney] NULL,
	[BatchDealPrice] [smallmoney] NULL,
	[BatchMultiPriceGroup] [smallint] NULL,
	[Advertised] [bit] NOT NULL,
	[CouponUPC] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PromoCode] [int] NULL,
	[ForcePosValid] [int] NULL,
	[HasStarted] [bit] NOT NULL,
	[HasEnded] [bit] NOT NULL,
	[LabelBatchId] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DeletedProductBatchHeader](
	[SessionId] [uniqueidentifier] NOT NULL,
	[DeleteUser] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[DeleteTime] [datetime] NOT NULL,
	[DeleteSource] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[BatchId] [int] NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[ProductBatchTypeId] [int] NULL,
	[StartDate] [smalldatetime] NULL,
	[EndDate] [smalldatetime] NULL,
	[Description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Sent] [tinyint] NULL,
	[DateSent] [smalldatetime] NULL,
	[ShowInProcessItemUpdates] [tinyint] NULL,
	[IsReadOnly] [bit] NULL,
	[DateSentToRCP] [smalldatetime] NULL,
	[ReleasedTime] [datetime] NULL,
	[CreateTime] [datetime] NULL,
	[LastChangeTime] [datetime] NULL,
	[AutoApplyOnTime] [datetime] NULL,
	[AutoApplyOnSentTime] [datetime] NULL,
	[AutoApplyOffTime] [datetime] NULL,
	[AutoApplyOffSentTime] [datetime] NULL,
	[HqNotes] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[StoreNotes] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_DeletedProductBatchHeader_1] PRIMARY KEY CLUSTERED 
(
	[SessionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DeletedProductBatchLog](
	[SessionId] [uniqueidentifier] NOT NULL,
	[RowId] [int] NOT NULL,
	[BatchId] [int] NOT NULL,
	[LogTime] [datetime] NOT NULL,
	[UserName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Source] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Message] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DeletedProductBatchStore](
	[SessionId] [uniqueidentifier] NOT NULL,
	[BatchId] [int] NOT NULL,
	[StoreId] [smallint] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Department](
	[DepartmentId] [smallint] NOT NULL,
	[DepartmentName] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[MajorDepartmentId] [smallint] NULL,
	[FoodStamp] [bit] NOT NULL,
	[TradingStamp] [bit] NOT NULL,
	[WIC] [bit] NOT NULL,
	[TaxA] [bit] NOT NULL,
	[TaxB] [bit] NOT NULL,
	[TaxC] [bit] NOT NULL,
	[TaxD] [bit] NOT NULL,
	[TaxE] [bit] NOT NULL,
	[TaxF] [bit] NOT NULL,
	[GeneralLedgerId] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[TaxId] [tinyint] NULL,
	[DeptCode] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Limit] [smallmoney] NULL,
	[Minimum] [smallmoney] NULL,
	[DepartmentKeyUpcCode] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DefaultMarkup] [numeric](9, 3) NOT NULL,
	[RewardsGivenUpcCode] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_Department] PRIMARY KEY CLUSTERED 
(
	[DepartmentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DepartmentGroup](
	[DepartmentGroupID] [int] NOT NULL,
	[DepartmentID] [int] NOT NULL,
	[DepartmentGroupName] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_DepartmentGroup] PRIMARY KEY CLUSTERED 
(
	[DepartmentGroupID] ASC,
	[DepartmentID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DepartmentIss45](
	[DepartmentId] [smallint] NOT NULL,
	[TAX_RATE1_FG] [bit] NOT NULL,
	[TAX_RATE2_FG] [bit] NOT NULL,
	[TAX_RATE3_FG] [bit] NOT NULL,
	[TAX_RATE4_FG] [bit] NOT NULL,
	[TAX_RATE5_FG] [bit] NOT NULL,
	[TAX_RATE6_FG] [bit] NOT NULL,
	[TAX_RATE7_FG] [bit] NOT NULL,
	[TAX_RATE8_FG] [bit] NOT NULL,
	[PMT_WITH_FOODSTAMP_FG] [bit] NOT NULL,
	[NON_MDSE_FG] [bit] NOT NULL,
	[NEG_FG] [bit] NOT NULL,
	[DCML_FG] [bit] NOT NULL,
	[WGT_FG] [bit] NOT NULL,
	[DISC_FG] [bit] NOT NULL,
	[WIC_FG] [bit] NOT NULL,
	[VALID_FG] [bit] NOT NULL,
	[CST_PLUS_FG] [bit] NOT NULL,
	[RPRT_HO_FG] [bit] NOT NULL,
	[STFF_DISC_DISALLW_FG] [bit] NOT NULL,
	[CLB_CARD_PT_DISALLW_FG] [bit] NOT NULL,
	[DPT_COUNTER_FG] [bit] NOT NULL,
	[DPT_SCAN_DISALLW_FG] [bit] NOT NULL,
	[TRAD_ELIGAL] [bit] NOT NULL,
	[DEP_MAX_AMT] [money] NOT NULL,
	[DEP_MIN_AMT] [money] NOT NULL,
	[DEP_MAX_AMT_CC] [tinyint] NULL,
	[DEP_MIN_AMT_CC] [tinyint] NULL,
	[CF_TAX_RATE1_FG] [bit] NOT NULL,
	[CF_TAX_RATE2_FG] [bit] NOT NULL,
	[CF_TAX_RATE3_FG] [bit] NOT NULL,
	[CF_TAX_RATE4_FG] [bit] NOT NULL,
	[CF_TAX_RATE5_FG] [bit] NOT NULL,
	[CF_TAX_RATE6_FG] [bit] NOT NULL,
	[CF_TAX_RATE7_FG] [bit] NOT NULL,
	[CF_TAX_RATE8_FG] [bit] NOT NULL,
	[GRP_NBR] [int] NULL,
	[DISC_NBR] [tinyint] NULL,
	[RE_DEP] [smallint] NULL,
	[EXTND_PROM_NBR] [int] NULL,
	[EXTND_BCKT_NBR] [int] NULL,
	[INTRNL_NBR] [decimal](14, 0) NULL,
	[RSTRCT_LAYOUT] [tinyint] NULL,
	[FUEL_GRP_ID] [tinyint] NULL,
	[PRTICIPT_DEP_FG] [bit] NOT NULL,
	[NOT_USE7_FG] [bit] NOT NULL,
	[STR_CPN_FG] [bit] NOT NULL,
	[EXCISE_TAX_FG] [bit] NOT NULL,
	[VEN_CPN_FG] [bit] NOT NULL,
	[BNS_CPN_FG] [bit] NOT NULL,
	[EXCLUD_MIN_PURCH_FG] [bit] NOT NULL,
	[FUEL_FG] [bit] NOT NULL,
	[NOT_USE5_FG] [bit] NOT NULL,
	[NOT_USE6_FG] [bit] NOT NULL,
	[POINT_PER_CENT] [int] NULL,
	[POINT_PER_SLS] [int] NULL,
	[MAINSTORE_FG] [bit] NULL,
	[NO_MANUAL_AMT_FG] [bit] NULL,
	[NON_SCN_DEP_FG] [bit] NULL,
	[POS_MSG] [tinyint] NULL,
	[POP_MSG_PLU_FG] [bit] NOT NULL,
	[HEAD_OFFICE_DEP] [int] NULL,
	[ACCOUNT_NO] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[NON_RX_HEALTH_FG] [bit] NOT NULL,
	[RX_FG] [bit] NOT NULL,
	[EXEMPT_FROM_PROM_FG] [bit] NULL,
	[WIC_CVV_FG] [bit] NOT NULL,
 CONSTRAINT [PK_DepartmentIss45] PRIMARY KEY CLUSTERED 
(
	[DepartmentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FutureProdRetail](
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[RzGrpId] [int] NOT NULL,
	[RzSegId] [int] NOT NULL,
	[StartDt] [datetime] NOT NULL,
	[PriceAmt] [decimal](18, 2) NOT NULL,
	[PriceMult] [int] NOT NULL,
	[Iss45MIX_MATCH_CD] [int] NOT NULL,
	[HasProcessed] [bit] NOT NULL,
	[ProcessTmsp] [datetime] NOT NULL,
	[BatchDescr] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ExportTmsp] [datetime] NULL,
	[IbmSaPriceMethod] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[IbmSaMpGroup] [tinyint] NOT NULL,
	[IbmSaDealPrice] [decimal](18, 2) NOT NULL,
 CONSTRAINT [PK_FutureProdRetail] PRIMARY KEY CLUSTERED 
(
	[Upc] ASC,
	[RzGrpId] ASC,
	[RzSegId] ASC,
	[StartDt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HhProfileDetail](
	[ProfileNumber] [int] NOT NULL,
	[ScreenName] [varchar](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ScreenType] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ScreenOrder] [tinyint] NULL,
	[ViewOnly] [bit] NOT NULL,
 CONSTRAINT [PK_HhProfileDetail] PRIMARY KEY NONCLUSTERED 
(
	[ProfileNumber] ASC,
	[ScreenName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HhProfileFieldMap](
	[ScreenType] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ScreenName] [varchar](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[IsObsolete] [bit] NULL,
	[ScreenPrompt] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[TableName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ColumnName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DisplayColumn] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IsUpdatable] [bit] NULL,
	[IsPosUpdate] [bit] NULL,
	[IsComplexField] [bit] NULL,
	[ClrDataType] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[NumericMinVal] [decimal](18, 4) NULL,
	[NumericMaxVal] [decimal](18, 4) NULL,
	[StringMaxLength] [smallint] NULL,
	[FieldHelpText] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[FieldCategory] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[StringCasing] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_HhProfileFieldMap] PRIMARY KEY CLUSTERED 
(
	[ScreenName] ASC,
	[ScreenType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HhProfileHeader](
	[ProfileNumber] [int] NOT NULL,
	[ProfileName] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ProfileDesc] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CloneMaker] [bit] NOT NULL,
	[ItemMaker] [bit] NOT NULL,
 CONSTRAINT [PK_HhProfileHeader] PRIMARY KEY CLUSTERED 
(
	[ProfileNumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HhProfileHeaderGroup](
	[ProfileNumber] [int] NOT NULL,
	[group_name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_HhProfileHeaderGroup] PRIMARY KEY CLUSTERED 
(
	[ProfileNumber] ASC,
	[group_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[IBM4680Sync](
	[DeviceDescription] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[UPC] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[QtyAllowed] [tinyint] NULL,
	[WeightPriceRequired] [tinyint] NULL,
	[QtyRequired] [tinyint] NULL,
	[PriceRequired] [tinyint] NULL,
	[ExceptLogitemsale] [tinyint] NULL,
	[AuthSale] [tinyint] NULL,
	[RestrictSaleHours] [tinyint] NULL,
	[KeepItemMovement] [tinyint] NULL,
	[TaxA] [tinyint] NULL,
	[TaxB] [tinyint] NULL,
	[TaxC] [tinyint] NULL,
	[TaxD] [tinyint] NULL,
	[FoodStamp] [tinyint] NULL,
	[TradingStamp] [tinyint] NULL,
	[Discountable] [tinyint] NULL,
	[CouponMultiple] [tinyint] NULL,
	[AllowPrint] [tinyint] NULL,
	[R1] [tinyint] NULL,
	[R2] [tinyint] NULL,
	[R3] [tinyint] NULL,
	[UF1] [tinyint] NULL,
	[UF2] [tinyint] NULL,
	[UF3] [tinyint] NULL,
	[UF4] [tinyint] NULL,
	[ItemType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PriceMethod] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Department] [int] NULL,
	[FamilynuCurrent] [smallint] NULL,
	[FamilynuPrevious] [smallint] NULL,
	[MPGroup] [tinyint] NULL,
	[SaleQty] [smallint] NULL,
	[UnitPrice] [smallmoney] NULL,
	[DealPrice] [smallmoney] NULL,
	[LinkedItem] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ItemDescription] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[UserExit1] [smallint] NULL,
	[UserExit2] [smallint] NULL,
	[Processed] [smallint] NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[IbmSaItem](
	[ItemCode] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ItemName] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Department] [smallint] NULL,
	[ItemType] [int] NULL,
	[PriceMethod] [int] NULL,
	[SalePrice] [smallmoney] NULL,
	[DealPrice] [smallmoney] NULL,
	[SaleQuantity] [int] NULL,
	[MPGroup] [int] NULL,
	[QtyNotAllowed_Indicate0x80] [bit] NOT NULL,
	[WeightPriceRequired_Indicate0x40] [bit] NOT NULL,
	[QtyRequired_Indicate0x20] [bit] NOT NULL,
	[PriceRequired_Indicate0x10] [bit] NOT NULL,
	[ExceptLogItemSale_Indicate0x08] [bit] NOT NULL,
	[NotAuthForSale_Indicate0x04] [bit] NOT NULL,
	[NotAuthDuringRestrictedHours_Indicate0x02] [bit] NOT NULL,
	[NoItemMovementKept_Indicate0x01] [bit] NOT NULL,
	[CouponFamilyCurrent] [int] NULL,
	[CouponFamilyPrevious] [int] NULL,
	[LinkedItemCode] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[NoShelfLabel_Indicate1Ax80] [bit] NOT NULL,
	[NotTerminalItemRecord_Indicate1Ax40] [bit] NOT NULL,
	[PointsOnly_Indicate1Ax20] [bit] NOT NULL,
	[ItemLinksToDeposit_Indicate1Ax10] [bit] NOT NULL,
	[UserFlag1_Indicate1Ax08] [bit] NOT NULL,
	[UserFlag2_Indicate1Ax04] [bit] NOT NULL,
	[UserFlag3_Indicate1Ax02] [bit] NOT NULL,
	[UserFlag4_Indicate1Ax01] [bit] NOT NULL,
	[TaxA_Indicate1x80] [bit] NOT NULL,
	[TaxB_Indicate1x40] [bit] NOT NULL,
	[TaxC_Indicate1x20] [bit] NOT NULL,
	[TaxD_Indicate1x10] [bit] NOT NULL,
	[FoodStamp_Indicate1x08] [bit] NOT NULL,
	[TradingStamp_Indicate1x04] [bit] NOT NULL,
	[NonDiscountable_Indicate1x02] [bit] NOT NULL,
	[CouponValueMultNotAllowed_Indicate1x01] [bit] NOT NULL,
	[UserExit1] [int] NULL,
	[UserExit2] [int] NULL,
	[RxPrescriptionItem] [bit] NOT NULL,
	[QhpQualifiedHealthcareItem] [bit] NOT NULL,
	[AuditTime] [datetime] NOT NULL,
	[WicItem] [bit] NOT NULL,
	[WicCvbItem] [bit] NOT NULL,
 CONSTRAINT [PK_IbmSaItem] UNIQUE NONCLUSTERED 
(
	[ItemCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InvoiceDetail](
	[InvId] [int] NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[LineSeq] [int] NOT NULL,
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CasePack] [smallint] NOT NULL,
	[CaseCost] [decimal](18, 4) NOT NULL,
	[UnitCost] [decimal](18, 4) NOT NULL,
	[CaseAllowAmt] [decimal](18, 4) NOT NULL,
	[UnitAllowAmt] [decimal](18, 4) NOT NULL,
	[InvCaseQty] [int] NOT NULL,
	[InvUnitQty] [int] NOT NULL,
	[InvWgtQty] [decimal](18, 4) NOT NULL,
	[FreeCaseQty] [int] NOT NULL,
	[FreeUnitQty] [int] NOT NULL,
	[FreeWgtQty] [decimal](18, 4) NOT NULL,
	[ExtCost] [decimal](18, 2) NOT NULL,
	[LowUnitPriceAmt] [decimal](18, 4) NOT NULL,
	[RegUnitPriceAmt] [decimal](18, 4) NOT NULL,
	[UnitSplitCharge] [decimal](18, 2) NOT NULL,
	[UnitDepositCharge] [decimal](18, 2) NOT NULL,
	[ExtDepositCharge] [decimal](18, 2) NOT NULL,
	[DepositDepartmentId] [smallint] NULL,
	[DepartmentId] [smallint] NOT NULL,
	[ChargeCaseAmt] [decimal](18, 4) NOT NULL,
	[ChargeUnitAmt] [decimal](18, 4) NOT NULL,
	[DealCaseAmt] [decimal](18, 4) NOT NULL,
	[DealUnitAmt] [decimal](18, 4) NOT NULL,
 CONSTRAINT [PK_InvoiceDetail] PRIMARY KEY CLUSTERED 
(
	[InvId] ASC,
	[StoreId] ASC,
	[LineSeq] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InvoiceHeader](
	[InvId] [int] NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[InvDt] [datetime] NOT NULL,
	[InvNmbr] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CreateDt] [datetime] NOT NULL,
	[UserName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[PoNmbr] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SupplierId] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[DocType] [int] NOT NULL,
	[DocStatus] [int] NOT NULL,
	[DepartmentId] [smallint] NULL,
	[StoreCaseQty] [int] NOT NULL,
	[StoreUnitQty] [int] NOT NULL,
	[StoreWgtQty] [decimal](12, 4) NOT NULL,
	[StoreExtCost] [decimal](18, 2) NOT NULL,
	[SuppCaseQty] [int] NOT NULL,
	[SuppUnitQty] [int] NOT NULL,
	[SuppWgtQty] [decimal](12, 4) NOT NULL,
	[SuppExtCost] [decimal](18, 2) NOT NULL,
	[ChargeAmt] [decimal](18, 2) NOT NULL,
	[DealAmt] [decimal](18, 2) NOT NULL,
	[InvNote] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[IsTotalsOnly] [bit] NOT NULL,
	[ExportStatus] [int] NOT NULL,
	[ExportCount] [int] NOT NULL,
	[ExportTime] [datetime] NOT NULL,
 CONSTRAINT [PK_InvoiceHeader] PRIMARY KEY CLUSTERED 
(
	[InvId] ASC,
	[StoreId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Iss45_COUPON](
	[COUP_NBR] [float] NOT NULL,
	[DESCR] [char](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Iss45_DEA_GRP](
	[ID] [int] NOT NULL,
	[DESCR] [varchar](16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Iss45_DISCOUNT](
	[DISC_NBR] [tinyint] NOT NULL,
	[DISC_DESCR] [char](18) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Iss45_LINKED_ITEMS_HDR](
	[LNK_NBR] [smallint] NOT NULL,
	[LNK_DESC] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Iss45_POST_ITM_MSG](
	[MSG_NBR] [tinyint] NOT NULL,
	[MSG_TXT] [varchar](100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Iss45_RTN_TYPE](
	[RTN_NBR] [tinyint] NOT NULL,
	[RTN_DESCR] [char](18) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Iss45_TARE_WGT](
	[TAR_WGT_NBR] [smallint] NOT NULL,
	[DESCR] [char](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Iss45MemberProm](
	[MMBR_PROM_ID] [float] NOT NULL,
	[MMBR_PROM_TYP] [tinyint] NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[PosValid] [bit] NOT NULL,
	[STRT_DATE] [datetime] NOT NULL,
	[STRT_TM] [datetime] NULL,
	[END_DATE] [datetime] NULL,
	[END_TM] [datetime] NULL,
	[PROM_DESC] [char](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[STR_HIER_ID] [int] NULL,
	[RWRD_TYP] [tinyint] NOT NULL,
	[RWRD_VAL] [float] NULL,
	[LMT_QTY] [float] NULL,
	[SUN_FG] [bit] NOT NULL,
	[MON_FG] [bit] NOT NULL,
	[TUE_FG] [bit] NOT NULL,
	[WED_FG] [bit] NOT NULL,
	[THU_FG] [bit] NOT NULL,
	[FRI_FG] [bit] NOT NULL,
	[SAT_FG] [bit] NOT NULL,
	[SUN_STRT_TM] [datetime] NULL,
	[SUN_END_TM] [datetime] NULL,
	[MON_STRT_TM] [datetime] NULL,
	[MON_END_TM] [datetime] NULL,
	[TUE_STRT_TM] [datetime] NULL,
	[TUE_END_TM] [datetime] NULL,
	[WED_STRT_TM] [datetime] NULL,
	[WED_END_TM] [datetime] NULL,
	[THU_STRT_TM] [datetime] NULL,
	[THU_END_TM] [datetime] NULL,
	[FRI_STRT_TM] [datetime] NULL,
	[FRI_END_TM] [datetime] NULL,
	[SAT_STRT_TM] [datetime] NULL,
	[SAT_END_TM] [datetime] NULL,
	[EXT_TRSHOLD_QTY] [float] NULL,
	[EXT_STEP_QTY] [float] NULL,
	[GRP1_TYP] [tinyint] NULL,
	[TRSHOLD1_QTY] [float] NULL,
	[TRIG1_FG] [bit] NOT NULL,
	[GRP2_TYP] [tinyint] NOT NULL,
	[TRSHOLD2_QTY] [float] NULL,
	[TRIG2_FG] [bit] NOT NULL,
	[GRP3_TYP] [tinyint] NOT NULL,
	[TRSHOLD3_QTY] [float] NOT NULL,
	[TRIG3_FG] [bit] NOT NULL,
	[LOW_HIGH_FG] [bit] NOT NULL,
	[MIN_VAL] [float] NULL,
	[MIN_WGT] [float] NULL,
	[MIN_PURCH] [float] NULL,
	[DELAY_PROM_FG] [bit] NOT NULL,
	[VAL_BY_CSHR_FG] [bit] NOT NULL,
	[CPN_RQRD] [float] NULL,
	[LNK_PROM] [float] NULL,
	[GRP4_TYP] [tinyint] NOT NULL,
	[TRSHOLD4_QTY] [float] NOT NULL,
	[TRIG4_FG] [bit] NOT NULL,
	[GRP5_TYP] [tinyint] NOT NULL,
	[TRSHOLD5_QTY] [float] NOT NULL,
	[TRIG5_FG] [bit] NOT NULL,
	[GRP6_TYP] [tinyint] NOT NULL,
	[TRSHOLD6_QTY] [float] NOT NULL,
	[TRIG6_FG] [bit] NOT NULL,
	[GRP7_TYP] [tinyint] NOT NULL,
	[TRSHOLD7_QTY] [float] NOT NULL,
	[TRIG7_FG] [bit] NOT NULL,
	[GRP8_TYP] [tinyint] NOT NULL,
	[TRSHOLD8_QTY] [float] NOT NULL,
	[TRIG8_FG] [bit] NOT NULL,
	[GRP9_TYP] [tinyint] NOT NULL,
	[TRSHOLD9_QTY] [float] NOT NULL,
	[TRIG9_FG] [bit] NOT NULL,
	[GRP10_TYP] [tinyint] NOT NULL,
	[TRSHOLD10_QTY] [float] NOT NULL,
	[TRIG10_FG] [bit] NOT NULL,
	[MAX_ITEM_WGT] [float] NULL,
	[RWRD_GRP1] [bit] NOT NULL,
	[RWRD_GRP2] [bit] NOT NULL,
	[RWRD_GRP3] [bit] NOT NULL,
	[RWRD_GRP4] [bit] NOT NULL,
	[RWRD_GRP5] [bit] NOT NULL,
	[RWRD_GRP6] [bit] NOT NULL,
	[RWRD_GRP7] [bit] NOT NULL,
	[RWRD_GRP8] [bit] NOT NULL,
	[RWRD_GRP9] [bit] NOT NULL,
	[RWRD_GRP10] [bit] NOT NULL,
	[LVL_QTY1] [float] NULL,
	[LVL_QTY2] [float] NULL,
	[LVL_QTY3] [float] NULL,
	[LVL_QTY4] [float] NULL,
	[LVL_QTY5] [float] NULL,
	[LVL_AMT1] [float] NULL,
	[LVL_AMT2] [float] NULL,
	[LVL_AMT3] [float] NULL,
	[LVL_AMT4] [float] NULL,
	[LVL_AMT5] [float] NULL,
	[LVL_RWRD_AMT1] [float] NULL,
	[LVL_RWRD_AMT2] [float] NULL,
	[LVL_RWRD_AMT3] [float] NULL,
	[LVL_RWRD_AMT4] [float] NULL,
	[LVL_RWRD_AMT5] [float] NULL,
	[CPN_REQ_TYP] [tinyint] NULL,
	[CRDT_PROG] [int] NULL,
	[PROM_EXT_ID] [int] NULL,
	[NON_NETTED_FG] [bit] NULL,
	[RWD_BY_THRESHOLD_FG] [bit] NULL,
	[POINTS_REDEMPTION_APPROVAL_FG] [bit] NULL,
	[PROM_IDEN] [varchar](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_MMBR_PROM] PRIMARY KEY CLUSTERED 
(
	[MMBR_PROM_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Iss45MemberPromLink](
	[MMBR_PROM_ID] [float] NOT NULL,
	[LNK_TYP] [tinyint] NOT NULL,
	[LNK_ID] [float] NOT NULL,
	[GRP_ID] [tinyint] NOT NULL,
 CONSTRAINT [PK_MMBR_PROM_LNKD] PRIMARY KEY CLUSTERED 
(
	[MMBR_PROM_ID] ASC,
	[LNK_TYP] ASC,
	[LNK_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Iss45MemberPromStore](
	[MMBR_PROM_ID] [float] NOT NULL,
	[StoreId] [smallint] NOT NULL,
 CONSTRAINT [PK_Iss45MemberPromStore] PRIMARY KEY CLUSTERED 
(
	[MMBR_PROM_ID] ASC,
	[StoreId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Iss45MixMatch](
	[MixMatchCd] [int] NOT NULL,
	[MixMatchDescr] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK__Iss45Mix__4F73162D4F089A18] PRIMARY KEY CLUSTERED 
(
	[MixMatchCd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LabelReportDef](
	[OutputType] [varchar](25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ReportName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[LblSizeCd] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[RowsPerPage] [int] NOT NULL,
	[ColsPerPage] [int] NOT NULL,
	[Disabled] [bit] NOT NULL,
	[ReportXml] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_LabelReportDef] PRIMARY KEY NONCLUSTERED 
(
	[OutputType] ASC,
	[ReportName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LblBatchDetail](
	[LblBatchId] [int] NOT NULL,
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[BrandName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ItemDescr] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Size] [numeric](8, 3) NULL,
	[UomCd] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[UomDescr] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[NormalPriceAmt] [decimal](18, 2) NULL,
	[NormalPriceMult] [int] NULL,
	[NormalPerUnitPrice] [decimal](18, 4) NULL,
	[SupplierId] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OrderCode] [varchar](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CasePack] [smallint] NULL,
	[IsDsd] [bit] NULL,
	[IsDiscontinued] [bit] NULL,
	[SoldAs] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DisplayBrand] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DisplayDescription] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DisplayComment1] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DisplayComment2] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DisplayComment3] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ItemAttribute1] [bit] NULL,
	[ItemAttribute2] [bit] NULL,
	[ItemAttribute3] [bit] NULL,
	[ItemAttribute4] [bit] NULL,
	[ItemAttribute5] [bit] NULL,
	[ItemAttribute6] [bit] NULL,
	[ItemAttribute7] [bit] NULL,
	[ItemAttribute8] [bit] NULL,
	[ItemAttribute9] [bit] NULL,
	[ItemAttribute10] [bit] NULL,
	[GroupSizeRange] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[GroupBrandName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[GroupItemDescription] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[GroupPrintQty] [int] NULL,
	[NormalFormattedPrice] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PromotedFormattedPrice] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[LblSizeCd] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PromotedStartDate] [datetime] NULL,
	[PromotedEndDate] [datetime] NULL,
	[PromotedSaveAmountText] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PromotedComment] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[FormattedUpc] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ProductStatusCd] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ProductStatusDescr] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IsWic] [bit] NULL,
	[GroupComment] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SizeAndUomCd] [varchar](25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SupplierName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[BatchId] [int] NULL,
	[IsDepositLink] [bit] NULL,
	[SectionId] [int] NULL,
	[DepartmentId] [smallint] NULL,
	[BatchDealQty] [smallint] NULL,
	[BatchSpecialPrice] [decimal](18, 2) NULL,
	[BatchDealPrice] [decimal](18, 2) NULL,
	[Iss45ComparativeUomCd] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Iss45ComparativePrice] [decimal](18, 2) NULL,
	[Iss45ComparativeUomDescr] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CrossDockCd] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_LblBatchDetail] PRIMARY KEY CLUSTERED 
(
	[LblBatchId] ASC,
	[Upc] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LblBatchHeader](
	[LblBatchId] [int] IDENTITY(1,1) NOT NULL,
	[OutputType] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CreateTime] [datetime] NOT NULL,
	[UserName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Comments] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CompletedTime] [datetime] NULL,
	[CompletedUserName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_LblBatchHeader] PRIMARY KEY CLUSTERED 
(
	[LblBatchId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LblSize](
	[LblSizeCd] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[LblSizeDescr] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_LblSize] PRIMARY KEY CLUSTERED 
(
	[LblSizeCd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MajorDepartment](
	[MajorDepartmentId] [smallint] NOT NULL,
	[MajorDepartmentName] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[MajorGrouping] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_MajorDepartment_1] PRIMARY KEY CLUSTERED 
(
	[MajorDepartmentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [PK_MajorDepartment] UNIQUE NONCLUSTERED 
(
	[MajorDepartmentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Numbers](
	[Number] [int] NOT NULL,
 CONSTRAINT [PK_Numbers] PRIMARY KEY CLUSTERED 
(
	[Number] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OnHand](
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[Qty] [decimal](18, 4) NOT NULL,
	[LastChgTm] [datetime] NOT NULL,
 CONSTRAINT [PK_OnHand_1] PRIMARY KEY CLUSTERED 
(
	[Upc] ASC,
	[StoreId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OnHandTxn](
	[AuditId] [bigint] IDENTITY(1,1) NOT NULL,
	[AuditSrc] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AuditUser] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AuditTime] [datetime] NOT NULL,
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[OldQty] [decimal](18, 4) NULL,
	[NewQty] [decimal](18, 2) NOT NULL,
	[PosTime] [datetime] NOT NULL,
	[PosQty] [decimal](18, 4) NOT NULL,
	[PosNmbr] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[PosTicket] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[PosCashier] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_OnHandTxn] PRIMARY KEY CLUSTERED 
(
	[AuditId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PosBatchDetail](
	[PosBatchId] [int] NOT NULL,
	[Seq] [int] NOT NULL,
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[BatchType] [int] NOT NULL,
	[BatchId] [int] NOT NULL,
	[OtherId] [float] NOT NULL,
	[ProcessTime] [datetime] NOT NULL,
	[ProcessStatus] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_PosBatchDetail] PRIMARY KEY CLUSTERED 
(
	[PosBatchId] ASC,
	[Seq] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PosBatchHeader](
	[PosBatchId] [int] IDENTITY(1,1) NOT NULL,
	[SubmitTime] [datetime] NOT NULL,
	[LoginName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Source] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Comments] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StartTime] [datetime] NOT NULL,
	[StopTime] [datetime] NOT NULL,
 CONSTRAINT [PK_PosBatchHeader] PRIMARY KEY CLUSTERED 
(
	[PosBatchId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PriceMethod](
	[PriceMethodCd] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ItemPriceMethodDescr] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CouponPriceMethodDescr] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AllowForItem] [bit] NOT NULL,
	[AllowForPriceBatch] [bit] NOT NULL,
	[AllowForCoupon] [bit] NOT NULL,
 CONSTRAINT [PK_PriceMethod] PRIMARY KEY NONCLUSTERED 
(
	[PriceMethodCd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Prod](
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[BrandName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ItemDescr] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Size] [numeric](8, 3) NOT NULL,
	[UomCd] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[DepartmentId] [smallint] NOT NULL,
	[SectionId] [int] NULL,
	[ProductTypeCd] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ProductStatusCd] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ReceiveByWeight] [bit] NOT NULL,
	[CreateDate] [datetime] NULL,
	[NewItemReviewDate] [datetime] NULL,
	[StatusModifiedDate] [datetime] NULL,
	[ProductAvailableDate] [datetime] NULL,
	[RzGrpId] [int] NOT NULL,
 CONSTRAINT [PK_Prod] PRIMARY KEY CLUSTERED 
(
	[Upc] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProdGroupDetail](
	[GroupId] [int] NOT NULL,
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_ProdGroupDetail] PRIMARY KEY CLUSTERED 
(
	[GroupId] ASC,
	[Upc] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProdGroupHeader](
	[GroupId] [int] IDENTITY(1,1) NOT NULL,
	[GroupName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[GroupType] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[UseForPricing] [bit] NOT NULL,
	[UseForAllowance] [bit] NOT NULL,
	[UseForCostBatch] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
 CONSTRAINT [PK_ProdGroupHeader] PRIMARY KEY CLUSTERED 
(
	[GroupId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProdPosIbmSa](
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[PosDescription] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Advertized] [bit] NOT NULL,
	[KeepItemMovement] [bit] NOT NULL,
	[PriceRequired] [bit] NOT NULL,
	[WeightPriceRequired] [bit] NOT NULL,
	[CouponFamilyCurrent] [smallint] NOT NULL,
	[CouponFamilyPrevious] [smallint] NOT NULL,
	[Discountable] [bit] NOT NULL,
	[CouponMultiple] [bit] NOT NULL,
	[ExceptLogItemSale] [bit] NOT NULL,
	[QtyAllowed] [bit] NOT NULL,
	[QtyRequired] [bit] NOT NULL,
	[AuthSale] [bit] NOT NULL,
	[RestrictSaleHours] [bit] NOT NULL,
	[TerminalItemRecord] [bit] NOT NULL,
	[AllowPrint] [bit] NOT NULL,
	[User1] [bit] NOT NULL,
	[User2] [bit] NOT NULL,
	[User3] [bit] NOT NULL,
	[User4] [bit] NOT NULL,
	[UserData1] [smallint] NULL,
	[UserData2] [smallint] NULL,
	[ApplyPoints] [bit] NOT NULL,
	[LinkCode] [smallint] NULL,
	[ItemLinkToDeposit] [tinyint] NULL,
	[FoodStamp] [bit] NULL,
	[TradingStamp] [bit] NULL,
	[Wic] [bit] NULL,
	[TaxA] [bit] NULL,
	[TaxB] [bit] NULL,
	[TaxC] [bit] NULL,
	[TaxD] [bit] NULL,
	[TaxE] [bit] NULL,
	[TaxF] [bit] NULL,
	[QhpQualifiedHealthcareItem] [bit] NULL,
	[RxPrescriptionItem] [bit] NULL,
	[WicCvv] [bit] NULL,
	[DepositUpc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CouponUpc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ReportingCode] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_ProdPosIbmSa] PRIMARY KEY CLUSTERED 
(
	[Upc] ASC,
	[StoreId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProdPosIss45](
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[MSG_CD] [tinyint] NULL,
	[DSPL_DESCR] [varchar](40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SLS_RESTRICT_GRP] [int] NULL,
	[RCPT_DESCR] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[NON_MDSE_ID] [int] NULL,
	[QTY_RQRD_FG] [tinyint] NULL,
	[SLS_AUTH_FG] [tinyint] NULL,
	[FOOD_STAMP_FG] [tinyint] NULL,
	[WIC_FG] [tinyint] NULL,
	[NG_ENTRY_FG] [tinyint] NULL,
	[STR_CPN_FG] [tinyint] NULL,
	[VEN_CPN_FG] [tinyint] NULL,
	[MAN_PRC_FG] [tinyint] NULL,
	[WGT_ITM_FG] [tinyint] NULL,
	[NON_DISC_FG] [tinyint] NULL,
	[COST_PLUS_FG] [tinyint] NULL,
	[PRC_VRFY_FG] [tinyint] NULL,
	[INHBT_QTY_FG] [tinyint] NULL,
	[DCML_QTY_FG] [tinyint] NULL,
	[TAX_RATE1_FG] [tinyint] NULL,
	[TAX_RATE2_FG] [tinyint] NULL,
	[TAX_RATE3_FG] [tinyint] NULL,
	[TAX_RATE4_FG] [tinyint] NULL,
	[TAX_RATE5_FG] [tinyint] NULL,
	[TAX_RATE6_FG] [tinyint] NULL,
	[TAX_RATE7_FG] [tinyint] NULL,
	[TAX_RATE8_FG] [tinyint] NULL,
	[MIX_MATCH_CD] [int] NULL,
	[RTN_CD] [tinyint] NULL,
	[FAMILY_CD] [smallint] NULL,
	[DISC_CD] [tinyint] NULL,
	[SCALE_FG] [tinyint] NULL,
	[WGT_SCALE_FG] [tinyint] NULL,
	[FREQ_SHOP_TYPE] [tinyint] NULL,
	[FREQ_SHOP_VAL] [money] NULL,
	[SEC_FAMILY] [smallint] NULL,
	[POS_MSG] [tinyint] NULL,
	[SHELF_LIFE_DAY] [smallint] NULL,
	[CPN_NBR] [float] NULL,
	[TAR_WGT_NBR] [tinyint] NULL,
	[CMPRTV_UOM] [tinyint] NULL,
	[CMPR_QTY] [int] NULL,
	[CMPR_UNT] [int] NULL,
	[BNS_CPN_FG] [tinyint] NULL,
	[EXCLUD_MIN_PURCH_FG] [tinyint] NULL,
	[FUEL_FG] [tinyint] NULL,
	[SPR_AUTH_RQRD_FG] [tinyint] NULL,
	[SSP_PRDCT_FG] [tinyint] NULL,
	[FREQ_SHOP_LMT] [tinyint] NULL,
	[DEA_GRP] [smallint] NULL,
	[BNS_BY_DESCR] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[COMP_TYPE] [smallint] NULL,
	[COMP_PRC] [float] NULL,
	[COMP_QTY] [int] NULL,
	[ASSUME_QTY_FG] [tinyint] NULL,
	[ITM_POINT] [int] NULL,
	[PRC_GRP_ID] [smallint] NULL,
	[SWW_CODE_FG] [float] NULL,
	[SHELF_STOCK_FG] [tinyint] NULL,
	[PRNT_PLU_ID_RCPT_FG] [bit] NULL,
	[BLK_GRP] [int] NULL,
	[EXCHANGE_TENDER_ID] [smallint] NULL,
	[CAR_WASH_FG] [bit] NULL,
	[PACKAGE_UOM] [tinyint] NULL,
	[UNIT_FACTOR] [int] NULL,
	[FS_QTY] [int] NULL,
	[NON_RX_HEALTH_FG] [bit] NULL,
	[RX_FG] [bit] NULL,
	[EXEMPT_FROM_PROM_FG] [bit] NULL,
	[WIC_CVV_FG] [bit] NULL,
	[LNK_NBR] [smallint] NULL,
	[SNAP_HIP_FG] [bit] NULL,
 CONSTRAINT [PK_ProdPosIss45] PRIMARY KEY CLUSTERED 
(
	[Upc] ASC,
	[StoreId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProdPrice](
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[PriceType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[PriceAmt] [decimal](18, 2) NOT NULL,
	[PriceMult] [int] NOT NULL,
	[IbmSaPriceMethod] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[IbmSaMpGroup] [tinyint] NOT NULL,
	[IbmSaDealPrice] [decimal](18, 2) NOT NULL,
 CONSTRAINT [PK_ProdPrice] PRIMARY KEY CLUSTERED 
(
	[Upc] ASC,
	[StoreId] ASC,
	[PriceType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProdPriceZone](
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[RzGrpId] [int] NOT NULL,
	[RzSegId] [int] NOT NULL,
	[PriceAmt] [decimal](18, 2) NOT NULL,
	[PriceMult] [int] NOT NULL,
	[IbmSaPriceMethod] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[IbmSaMpGroup] [tinyint] NOT NULL,
	[IbmSaDealPrice] [decimal](18, 2) NOT NULL,
	[Iss45MIX_MATCH_CD] [int] NOT NULL,
 CONSTRAINT [PK_ProdPriceZone] PRIMARY KEY CLUSTERED 
(
	[Upc] ASC,
	[RzGrpId] ASC,
	[RzSegId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProdSign](
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ReviewedDate] [datetime] NULL,
	[SoldAs] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DisplayBrand] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DisplayDescription] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DisplayComment1] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DisplayComment2] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DisplayComment3] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ItemAttribute1] [bit] NULL,
	[ItemAttribute2] [bit] NULL,
	[ItemAttribute3] [bit] NULL,
	[ItemAttribute4] [bit] NULL,
	[ItemAttribute5] [bit] NULL,
	[ItemAttribute6] [bit] NULL,
	[ItemAttribute7] [bit] NULL,
	[ItemAttribute8] [bit] NULL,
	[ItemAttribute9] [bit] NULL,
	[ItemAttribute10] [bit] NULL,
	[GroupSizeRange] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[GroupBrandName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[GroupItemDescription] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[GroupPrintQty] [int] NULL,
	[GroupComment] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_ProdSign] PRIMARY KEY CLUSTERED 
(
	[Upc] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProdStore](
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[PosValid] [bit] NOT NULL,
	[PriSupplierId] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CanReceive] [bit] NOT NULL,
	[QtyOnHand] [int] NULL,
	[OrderThreshold] [int] NULL,
	[InventoryCost] [decimal](18, 4) NULL,
	[LblSizeCd] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[LabelRequestDate] [datetime] NULL,
	[SignRequestDate] [datetime] NULL,
	[NewItemReviewDate] [datetime] NULL,
	[LabelRequestUser] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SignRequestUser] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[TargetGrossMargin] [int] NOT NULL,
	[CustomPriceCd] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_ProdStore] PRIMARY KEY CLUSTERED 
(
	[Upc] ASC,
	[StoreId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProductAudit](
	[row_id] [int] IDENTITY(1,1) NOT NULL,
	[audit_time] [datetime] NOT NULL,
	[audit_type] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[user_name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Source] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Category] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[FieldName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[NewValue] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OldValue] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ExtraInfo] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[StoreId] [smallint] NULL,
 CONSTRAINT [PK_ProductAudit] PRIMARY KEY CLUSTERED 
(
	[row_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProductBatchDetail](
	[UPC] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[BatchId] [int] NOT NULL,
	[BatchPriceMethod] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[BatchDealQty] [smallint] NULL,
	[BatchSpecialPrice] [smallmoney] NULL,
	[BatchDealPrice] [smallmoney] NULL,
	[BatchMultiPriceGroup] [smallint] NULL,
	[Advertised] [bit] NOT NULL,
	[CouponUPC] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PromoCode] [int] NULL,
	[ForcePosValid] [int] NULL,
	[HasStarted] [bit] NOT NULL,
	[HasEnded] [bit] NOT NULL,
	[LabelBatchId] [int] NULL,
 CONSTRAINT [PK_ProductBatchDetail] PRIMARY KEY NONCLUSTERED 
(
	[BatchId] ASC,
	[UPC] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProductBatchHeader](
	[BatchId] [int] IDENTITY(1,1) NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[ProductBatchTypeId] [int] NULL,
	[StartDate] [smalldatetime] NULL,
	[EndDate] [smalldatetime] NULL,
	[Description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Sent] [tinyint] NULL,
	[DateSent] [smalldatetime] NULL,
	[ShowInProcessItemUpdates] [tinyint] NULL,
	[IsReadOnly] [bit] NULL,
	[DateSentToRCP] [smalldatetime] NULL,
	[ReleasedTime] [datetime] NULL,
	[CreateTime] [datetime] NULL,
	[LastChangeTime] [datetime] NULL,
	[AutoApplyOnTime] [datetime] NULL,
	[AutoApplyOnSentTime] [datetime] NULL,
	[AutoApplyOffTime] [datetime] NULL,
	[AutoApplyOffSentTime] [datetime] NULL,
	[HqNotes] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[StoreNotes] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_ProductBatchHeader] PRIMARY KEY NONCLUSTERED 
(
	[BatchId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [IX_Description] UNIQUE NONCLUSTERED 
(
	[Description] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProductBatchLog](
	[RowId] [int] IDENTITY(1,1) NOT NULL,
	[BatchId] [int] NOT NULL,
	[LogTime] [datetime] NOT NULL,
	[UserName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Source] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Message] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_ProductBatchLog] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProductBatchStatus](
	[BatchStatusId] [int] NOT NULL,
	[BatchStatusDescription] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_ProductBatchStatus] PRIMARY KEY CLUSTERED 
(
	[BatchStatusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProductBatchStore](
	[BatchId] [int] NOT NULL,
	[StoreId] [smallint] NOT NULL,
 CONSTRAINT [PK_ProductBatchStore] PRIMARY KEY NONCLUSTERED 
(
	[BatchId] ASC,
	[StoreId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProductBatchType](
	[ProductBatchTypeId] [int] IDENTITY(1,1) NOT NULL,
	[TypeName] [varchar](25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[GroupName] [varchar](25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AffectsPricing] [bit] NOT NULL,
	[Priority] [smallint] NULL,
	[IsPromoted] [bit] NULL,
	[IsDisabled] [bit] NULL,
	[group_sort] [int] NOT NULL,
	[bucket_sort] [int] NOT NULL,
 CONSTRAINT [PK_ProductBatchType] PRIMARY KEY CLUSTERED 
(
	[ProductBatchTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProductStatus](
	[ProductStatusCd] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ProductStatusDescr] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_ProductStatus] PRIMARY KEY CLUSTERED 
(
	[ProductStatusCd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProductType](
	[ProductTypeCd] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ProductTypeDescr] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IncludeInSales] [bit] NULL,
 CONSTRAINT [PK_ProductType] PRIMARY KEY CLUSTERED 
(
	[ProductTypeCd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[realtime_sales_summary](
	[store_key] [int] NOT NULL,
	[record_type] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[record_key] [char](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[trans_date] [datetime] NOT NULL,
	[record_description] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[parent_record_key] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[sort_key] [int] NOT NULL,
	[sales_dollar_amount] [decimal](18, 4) NOT NULL,
	[customer_count] [decimal](18, 0) NOT NULL,
	[item_count] [decimal](18, 0) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivingDocStatus](
	[DocStatus] [int] NOT NULL,
	[Description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_ReceivingDocStatus] PRIMARY KEY CLUSTERED 
(
	[DocStatus] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivingDocType](
	[DocType] [int] NOT NULL,
	[Description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_ReceivingDocType] PRIMARY KEY CLUSTERED 
(
	[DocType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[report_queue](
	[row_id] [int] IDENTITY(1,1) NOT NULL,
	[report_type] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[printer_name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[number_of_copies] [int] NOT NULL,
	[args] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[submit_time] [datetime] NOT NULL,
	[submit_user] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[start_print_time] [datetime] NULL,
	[end_print_time] [datetime] NULL,
 CONSTRAINT [PK_report_queue] PRIMARY KEY CLUSTERED 
(
	[row_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RetailZoneGroup](
	[RzGrpId] [int] NOT NULL,
	[RzGrpDescr] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_RetailZoneGroup] PRIMARY KEY CLUSTERED 
(
	[RzGrpId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RetailZoneSegment](
	[RzGrpId] [int] NOT NULL,
	[RzSegId] [int] NOT NULL,
	[RzSegDescr] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_RetailZoneSegment] PRIMARY KEY CLUSTERED 
(
	[RzGrpId] ASC,
	[RzSegId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RetailZoneStore](
	[RzGrpId] [int] NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[RzSegId] [int] NOT NULL,
 CONSTRAINT [PK_RetailZoneStore] PRIMARY KEY CLUSTERED 
(
	[RzGrpId] ASC,
	[StoreId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Sequence](
	[SeqName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[NextInt] [int] NOT NULL,
	[NextDouble] [float] NOT NULL,
 CONSTRAINT [PK_Sequence] PRIMARY KEY CLUSTERED 
(
	[SeqName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ShipType](
	[ShipTypeCd] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ShipTypeDescr] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_ShipType] PRIMARY KEY CLUSTERED 
(
	[ShipTypeCd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SpartanAbsDeliverySchedule](
	[SupplierId] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Mon] [bit] NULL,
	[Tue] [bit] NULL,
	[Wed] [bit] NULL,
	[Thu] [bit] NULL,
	[Fri] [bit] NULL,
	[Sat] [bit] NULL,
	[Sun] [bit] NULL,
 CONSTRAINT [PK_SpartanAbsDeliverySchedule] PRIMARY KEY CLUSTERED 
(
	[SupplierId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SpartanAbsOrderDetail](
	[AdName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StartDate] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[EndDate] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[UPC] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SupplierSKU] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Cases] [smallint] NULL,
	[DeliveryDate] [datetime] NOT NULL,
	[MstoreOrderId] [int] NULL,
	[MstoreExportDate] [datetime] NULL,
 CONSTRAINT [PK_SpartanAbsOrderDetail] PRIMARY KEY CLUSTERED 
(
	[AdName] ASC,
	[StartDate] ASC,
	[EndDate] ASC,
	[SupplierSKU] ASC,
	[DeliveryDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SpartanAdLossProjections](
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NOT NULL,
	[ProductBatchTypeId] [int] NOT NULL,
	[ProjectedMovement] [decimal](9, 2) NOT NULL,
	[ProjectedUnitPrice] [decimal](9, 2) NOT NULL,
	[ProjectedUnitCost] [decimal](9, 2) NOT NULL,
 CONSTRAINT [PK_SpartanAdLossProjections] PRIMARY KEY NONCLUSTERED 
(
	[Upc] ASC,
	[StartDate] ASC,
	[EndDate] ASC,
	[ProductBatchTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SpartanC3AdDetail](
	[AdId] [int] NOT NULL,
	[RecordId] [int] IDENTITY(1,1) NOT NULL,
	[AdName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ProjectedSales] [money] NULL,
	[AdDate] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[StartDate] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EndDate] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[StyleName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Header] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Footer] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AdInformation] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[StoreNum] [int] NULL,
	[StoreName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[GroupName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[BlockNumber] [int] NULL,
	[PageNumber] [int] NULL,
	[BlockTypeId] [int] NULL,
	[BlockType] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Information] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[StoreMemo] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[LayoutMemo] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ProductId] [numeric](18, 4) NULL,
	[itemindex] [int] NULL,
	[itemcode] [varchar](7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ItemCodebar] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[upc] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[upcbar] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[brand] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[pack] [int] NULL,
	[Size] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CommodityId] [int] NULL,
	[Commodity] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Casecost] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[offinvoice] [smallmoney] NULL,
	[reflectstartdate] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[reflectenddate] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[groupId] [numeric](18, 4) NULL,
	[groupdescription] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Promotion] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[apbcoop] [smallmoney] NULL,
	[PaAmount] [smallmoney] NULL,
	[Minimum] [int] NULL,
	[Limit] [int] NULL,
	[pastartdate] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[paenddate] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CouponRefNumber] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[grMvt] [int] NULL,
	[plyMvt] [int] NULL,
	[GRPallet] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PLPallet] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RegRetail] [smallmoney] NULL,
	[AdOffer] [smallmoney] NULL,
	[BillBack] [smallmoney] NULL,
	[ScanAmount] [smallmoney] NULL,
	[CouponAmount] [smallmoney] NULL,
	[AdRetail] [varchar](100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[MinSuggested] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[MaxSuggested] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[netunit] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[isAdInfo] [bit] NOT NULL,
	[isBlockInfo] [bit] NOT NULL,
	[isStoreMemo] [bit] NOT NULL,
	[isLayoutMemo] [bit] NOT NULL,
	[grossprofit] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[VendorID] [int] NULL,
	[VendorName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[VendorStreet] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[VendorCity] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[VendorState] [varchar](2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[VendorZip] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[VendorContact] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DeleteFlag] [bit] NULL,
 CONSTRAINT [PK_SpartanC3AdDetail] PRIMARY KEY NONCLUSTERED 
(
	[AdId] ASC,
	[RecordId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [IX_AdId_RecordId] UNIQUE NONCLUSTERED 
(
	[AdId] ASC,
	[RecordId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SpartanC3AdHeader](
	[AdId] [int] IDENTITY(1,1) NOT NULL,
	[ImportFilename] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AdName] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AdDate] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StartDate] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[EndDate] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[MstoreBatchCreateDate] [datetime] NULL,
	[ScanbackItemCount] [int] NULL,
	[ScanbackCompletedDate] [datetime] NULL,
	[BillbackItemCount] [int] NULL,
	[BillbackCompletedDate] [smalldatetime] NULL,
	[MstoreBatchid] [int] NULL,
 CONSTRAINT [PK_SpartanC3AdHeader] PRIMARY KEY NONCLUSTERED 
(
	[AdId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SpartanC3OfferSubmission](
	[StoreId] [smallint] NOT NULL,
	[OfferNumber] [int] NOT NULL,
	[OfferStart] [datetime] NULL,
	[OfferEnd] [datetime] NULL,
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ScanAmount] [decimal](9, 4) NULL,
	[ScanUnits] [decimal](9, 4) NULL,
	[ExportDate] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SpartanMsrpBatchDetail](
	[BatchId] [int] NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Msrp] [smallmoney] NULL,
	[PackMsrpQty] [smallint] NULL,
 CONSTRAINT [PK_SpartanMsrpBatchDetail] PRIMARY KEY CLUSTERED 
(
	[BatchId] ASC,
	[Upc] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SpartanMsrpBatchHeader](
	[BatchId] [int] IDENTITY(1,1) NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[SupplierId] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[MsrpStartDate] [smalldatetime] NULL,
	[ApplyDate] [smalldatetime] NULL,
 CONSTRAINT [PK_SpartanMsrpBatchHeader] PRIMARY KEY CLUSTERED 
(
	[BatchId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SpartanOrderAudit](
	[OrderId] [int] NOT NULL,
	[AuditTime] [datetime] NOT NULL,
	[AuditInfo] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[LoginName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]

GO
CREATE CLUSTERED INDEX [IX_OrderID_AuditTime] ON [dbo].[SpartanOrderAudit]
(
	[OrderId] ASC,
	[AuditTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SpartanOrderDetail](
	[OrderItemId] [int] IDENTITY(1,1) NOT NULL,
	[OrderId] [int] NOT NULL,
	[UPC] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SupplierSKU] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Units] [smallint] NULL,
	[OrderCost] [smallmoney] NULL,
	[OriginalCost] [smallmoney] NULL,
	[LineItemSeq] [int] NULL,
	[SupplierId] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_SpartanOrderDetail] PRIMARY KEY NONCLUSTERED 
(
	[OrderItemId] ASC,
	[OrderId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SpartanOrderHeader](
	[OrderId] [int] IDENTITY(1,1) NOT NULL,
	[CreateDate] [smalldatetime] NULL,
	[DeliveryDate] [smalldatetime] NULL,
	[SupplierId] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DepartmentId] [smallint] NULL,
	[PONumber] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[TotalCase] [smallint] NULL,
	[TotalUnit] [smallint] NULL,
	[OrderStatus] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ConfirmationNumber] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AdvancedBuy] [tinyint] NULL,
 CONSTRAINT [PK_SpartanOrderHeader] PRIMARY KEY NONCLUSTERED 
(
	[OrderId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SpartanPriceAuditDetail](
	[AuditDate] [datetime] NOT NULL,
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[SystemPrice] [decimal](18, 3) NOT NULL,
	[MarkedPrice] [decimal](18, 3) NOT NULL,
	[PriceNotMarked] [bit] NOT NULL,
	[WrongPriceMarked] [bit] NOT NULL,
	[NotOnFile] [bit] NOT NULL,
 CONSTRAINT [PK_SpartanPriceAuditDetail] PRIMARY KEY NONCLUSTERED 
(
	[AuditDate] ASC,
	[Upc] ASC,
	[StoreId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SpartanProductXRef](
	[UPC] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ProductSize] [decimal](8, 3) NULL,
	[ProductUOM] [char](4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[BrandName] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[BrandItemDescription] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OrdDescription] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SectionId] [int] NULL,
	[ProductAvailableDate] [smalldatetime] NULL,
	[ProductStatus] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[StatusModifiedDate] [smalldatetime] NULL,
	[SupplierId] [int] NOT NULL,
	[SupplierSKU] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[PackageSize] [int] NULL,
	[ProductCost] [smallmoney] NULL,
	[CaseWeight] [decimal](9, 2) NULL,
	[CaseUPC] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SMI] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[FAC] [varchar](3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PRI] [varchar](3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ShipType] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_SpartanProductXRef] PRIMARY KEY CLUSTERED 
(
	[SupplierSKU] ASC,
	[UPC] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SpartanSilTempDetail](
	[BatchId] [varchar](8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SpartanSilTempDetailId] [int] NOT NULL,
	[Action] [varchar](6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[TableName] [varchar](8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Buffer] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Processed] [smallint] NULL,
	[RecordUsed] [smallint] NULL,
	[Reviewed] [smallint] NULL,
	[F01] [varchar](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F02] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F07] [tinyint] NULL,
	[F08] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F09] [smalldatetime] NULL,
	[F16] [int] NULL,
	[F17] [int] NULL,
	[F19] [smallint] NULL,
	[F20] [smallint] NULL,
	[F22] [varchar](9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F23] [char](4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F24] [float] NULL,
	[F26] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F28] [varchar](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F29] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F30] [float] NULL,
	[F31] [smallint] NULL,
	[F32] [int] NULL,
	[F33] [varchar](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F34] [varchar](2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F35] [smalldatetime] NULL,
	[F36] [smalldatetime] NULL,
	[F37] [varchar](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F38] [float] NULL,
	[F50] [float] NULL,
	[F62] [smallint] NULL,
	[F63] [float] NULL,
	[F64] [int] NULL,
	[F65] [numeric](10, 2) NULL,
	[F67] [numeric](10, 3) NULL,
	[F68] [smalldatetime] NULL,
	[F69] [smalldatetime] NULL,
	[F70] [tinyint] NULL,
	[F79] [varchar](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F80] [varchar](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F81] [varchar](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F90] [varchar](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F111] [float] NULL,
	[F112] [float] NULL,
	[F126] [smallint] NULL,
	[F129] [smalldatetime] NULL,
	[F130] [smalldatetime] NULL,
	[F135] [smallint] NULL,
	[F136] [float] NULL,
	[F137] [smalldatetime] NULL,
	[F138] [smalldatetime] NULL,
	[F139] [float] NULL,
	[F140] [float] NULL,
	[F142] [smallint] NULL,
	[F143] [smallint] NULL,
	[F144] [smalldatetime] NULL,
	[F145] [smalldatetime] NULL,
	[F146] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F147] [smallint] NULL,
	[F148] [float] NULL,
	[F151] [float] NULL,
	[F155] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F158] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F168] [float] NULL,
	[F179] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F181] [float] NULL,
	[F182] [smallint] NULL,
	[F183] [smalldatetime] NULL,
	[F184] [smalldatetime] NULL,
	[F185] [float] NULL,
	[F186] [float] NULL,
	[F188] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F199] [smalldatetime] NULL,
	[F200] [numeric](7, 2) NULL,
	[F201] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F202] [char](3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F203] [bit] NOT NULL,
	[F204] [bit] NOT NULL,
	[F205] [numeric](5, 0) NULL,
	[F206] [numeric](4, 0) NULL,
	[F207] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F208] [smallint] NULL,
	[F209] [smallint] NULL,
	[F210] [float] NULL,
	[F211] [smalldatetime] NULL,
	[F212] [smalldatetime] NULL,
	[F213] [varchar](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F214] [varchar](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F215] [smallint] NULL,
	[F216] [smalldatetime] NULL,
	[F217] [float] NULL,
	[F218] [char](4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F219] [smalldatetime] NULL,
	[F220] [int] NULL,
	[F221] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[FB10] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[FB11] [int] NULL,
	[FB12] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[FZ01] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[FZ02] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[FZ03] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[FZ04] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[FZ05] [char](3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[R1] [int] NULL,
	[R2] [int] NULL,
	[R3] [smallint] NULL,
	[R4] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[R5] [int] NULL,
	[R6] [smalldatetime] NULL,
	[R7] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[R8] [varchar](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[R9] [varchar](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[R10] [smallint] NULL,
	[R11] [int] NULL,
	[R12] [float] NULL,
	[R13] [smalldatetime] NULL,
	[R14] [smalldatetime] NULL,
	[R15] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[R16] [int] NULL,
	[R17] [bit] NOT NULL,
	[R18] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[R19] [int] NULL,
	[R20] [float] NULL,
	[R21] [smalldatetime] NULL,
	[R22] [smalldatetime] NULL,
	[R23] [smalldatetime] NULL,
	[R24] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[R26] [smalldatetime] NULL,
	[R27] [smalldatetime] NULL,
	[R28] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[R29] [smallint] NULL,
	[R30] [datetime] NULL,
	[R31] [datetime] NULL,
	[R32] [smalldatetime] NULL,
	[R34] [varchar](200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[R36] [smalldatetime] NULL,
	[R37] [smallint] NULL,
	[R38] [smalldatetime] NULL,
	[R39] [smalldatetime] NULL,
	[R40] [smalldatetime] NULL,
	[R41] [smalldatetime] NULL,
	[R42] [smalldatetime] NULL,
	[R43] [smalldatetime] NULL,
	[R44] [smalldatetime] NULL,
	[R45] [smalldatetime] NULL,
	[R25] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SM01] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SM02] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SM03] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SM04] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SM05] [smalldatetime] NULL,
	[SM06] [smalldatetime] NULL,
	[SM07] [numeric](7, 2) NULL,
	[SM08] [numeric](7, 2) NULL,
	[SM09] [numeric](7, 2) NULL,
	[SM10] [numeric](7, 2) NULL,
	[SM11] [numeric](7, 2) NULL,
	[SM12] [numeric](7, 2) NULL,
	[SM13] [numeric](7, 2) NULL,
	[SM14] [numeric](7, 2) NULL,
	[SM15] [numeric](7, 2) NULL,
	[SM16] [numeric](7, 2) NULL,
	[SM17] [numeric](7, 2) NULL,
	[SM18] [numeric](7, 2) NULL,
	[SM19] [numeric](7, 2) NULL,
	[SM20] [numeric](7, 2) NULL,
	[SM21] [numeric](7, 2) NULL,
	[SM23] [numeric](7, 2) NULL,
	[SM22] [numeric](7, 2) NULL,
	[SM24] [numeric](7, 2) NULL,
	[SM25] [int] NULL,
	[SM26] [numeric](4, 2) NULL,
	[SM27] [int] NULL,
	[R46] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F327] [numeric](7, 2) NULL,
	[F323] [char](3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F331] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F330] [int] NULL,
	[F325] [int] NULL,
	[F326] [int] NULL,
	[F329] [int] NULL,
	[F324] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F269] [smallmoney] NULL,
	[F270] [smallmoney] NULL,
	[F271] [smallint] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
CREATE CLUSTERED INDEX [PK_SpartanSilTempDetail] ON [dbo].[SpartanSilTempDetail]
(
	[BatchId] ASC,
	[SpartanSilTempDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SpartanSilTempDictionary](
	[SequenceId] [int] NOT NULL,
	[SILFile] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SILField] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_SpartanSilTempDictionary] PRIMARY KEY CLUSTERED 
(
	[SILFile] ASC,
	[SILField] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SpartanSilTempHeader](
	[BatchId] [varchar](8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SourceId] [varchar](6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DestinationId] [varchar](6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OriginalDate] [smalldatetime] NULL,
	[SoftwareRevision] [char](4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[TrailerCount] [int] NULL,
	[ProcessStartTime] [smalldatetime] NULL,
	[ProcessEndTime] [smalldatetime] NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SpartanSilTempMsrpDetail](
	[BatchId] [varchar](8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SpartanSilTempDetailId] [int] NOT NULL,
	[Action] [varchar](6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[TableName] [varchar](8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Buffer] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Processed] [smallint] NULL,
	[RecordUsed] [smallint] NULL,
	[Reviewed] [smallint] NULL,
	[F01] [varchar](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F02] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F07] [tinyint] NULL,
	[F08] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F09] [smalldatetime] NULL,
	[F16] [int] NULL,
	[F17] [int] NULL,
	[F19] [smallint] NULL,
	[F20] [smallint] NULL,
	[F22] [varchar](9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F23] [char](4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F24] [float] NULL,
	[F26] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F28] [varchar](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F29] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F30] [float] NULL,
	[F31] [smallint] NULL,
	[F32] [int] NULL,
	[F33] [varchar](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F34] [varchar](2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F35] [smalldatetime] NULL,
	[F36] [smalldatetime] NULL,
	[F37] [varchar](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F38] [float] NULL,
	[F50] [float] NULL,
	[F62] [smallint] NULL,
	[F63] [float] NULL,
	[F64] [int] NULL,
	[F65] [numeric](10, 2) NULL,
	[F67] [numeric](10, 3) NULL,
	[F68] [smalldatetime] NULL,
	[F69] [smalldatetime] NULL,
	[F70] [tinyint] NULL,
	[F79] [varchar](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F80] [varchar](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F81] [varchar](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F90] [varchar](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F111] [float] NULL,
	[F112] [float] NULL,
	[F126] [smallint] NULL,
	[F129] [smalldatetime] NULL,
	[F130] [smalldatetime] NULL,
	[F135] [smallint] NULL,
	[F136] [float] NULL,
	[F137] [smalldatetime] NULL,
	[F138] [smalldatetime] NULL,
	[F139] [float] NULL,
	[F140] [float] NULL,
	[F142] [smallint] NULL,
	[F143] [smallint] NULL,
	[F144] [smalldatetime] NULL,
	[F145] [smalldatetime] NULL,
	[F146] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F147] [smallint] NULL,
	[F148] [float] NULL,
	[F151] [float] NULL,
	[F155] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F158] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F168] [float] NULL,
	[F179] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F181] [float] NULL,
	[F182] [smallint] NULL,
	[F183] [smalldatetime] NULL,
	[F184] [smalldatetime] NULL,
	[F185] [float] NULL,
	[F186] [float] NULL,
	[F188] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F199] [smalldatetime] NULL,
	[F200] [numeric](7, 2) NULL,
	[F201] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F202] [char](3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F203] [bit] NOT NULL,
	[F204] [bit] NOT NULL,
	[F205] [numeric](5, 0) NULL,
	[F206] [numeric](4, 0) NULL,
	[F207] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F208] [smallint] NULL,
	[F209] [smallint] NULL,
	[F210] [float] NULL,
	[F211] [smalldatetime] NULL,
	[F212] [smalldatetime] NULL,
	[F213] [varchar](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F214] [varchar](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F215] [smallint] NULL,
	[F216] [smalldatetime] NULL,
	[F217] [float] NULL,
	[F218] [char](4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F219] [smalldatetime] NULL,
	[F220] [int] NULL,
	[F221] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[FB10] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[FB11] [int] NULL,
	[FB12] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[FZ01] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[FZ02] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[FZ03] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[FZ04] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[FZ05] [char](3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[R1] [int] NULL,
	[R2] [int] NULL,
	[R3] [smallint] NULL,
	[R4] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[R5] [int] NULL,
	[R6] [smalldatetime] NULL,
	[R7] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[R8] [varchar](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[R9] [varchar](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[R10] [smallint] NULL,
	[R11] [int] NULL,
	[R12] [float] NULL,
	[R13] [smalldatetime] NULL,
	[R14] [smalldatetime] NULL,
	[R15] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[R16] [int] NULL,
	[R17] [bit] NOT NULL,
	[R18] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[R19] [int] NULL,
	[R20] [float] NULL,
	[R21] [smalldatetime] NULL,
	[R22] [smalldatetime] NULL,
	[R23] [smalldatetime] NULL,
	[R24] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[R26] [smalldatetime] NULL,
	[R27] [smalldatetime] NULL,
	[R28] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[R29] [smallint] NULL,
	[R30] [smalldatetime] NULL,
	[R31] [smalldatetime] NULL,
	[R32] [smalldatetime] NULL,
	[R34] [varchar](200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[R36] [smalldatetime] NULL,
	[R37] [smallint] NULL,
	[R38] [smalldatetime] NULL,
	[R39] [smalldatetime] NULL,
	[R40] [smalldatetime] NULL,
	[R41] [smalldatetime] NULL,
	[R42] [smalldatetime] NULL,
	[R43] [smalldatetime] NULL,
	[R44] [smalldatetime] NULL,
	[R45] [smalldatetime] NULL,
	[R25] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SM01] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SM02] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SM03] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SM04] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SM05] [smalldatetime] NULL,
	[SM06] [smalldatetime] NULL,
	[SM07] [numeric](7, 2) NULL,
	[SM08] [numeric](7, 2) NULL,
	[SM09] [numeric](7, 2) NULL,
	[SM10] [numeric](7, 2) NULL,
	[SM11] [numeric](7, 2) NULL,
	[SM12] [numeric](7, 2) NULL,
	[SM13] [numeric](7, 2) NULL,
	[SM14] [numeric](7, 2) NULL,
	[SM15] [numeric](7, 2) NULL,
	[SM16] [numeric](7, 2) NULL,
	[SM17] [numeric](7, 2) NULL,
	[SM18] [numeric](7, 2) NULL,
	[SM19] [numeric](7, 2) NULL,
	[SM20] [numeric](7, 2) NULL,
	[SM21] [numeric](7, 2) NULL,
	[SM23] [numeric](7, 2) NULL,
	[SM22] [numeric](7, 2) NULL,
	[SM24] [numeric](7, 2) NULL,
	[SM25] [int] NULL,
	[SM26] [numeric](4, 2) NULL,
	[SM27] [int] NULL,
	[R46] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F327] [numeric](7, 2) NULL,
	[F323] [char](3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F331] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F330] [int] NULL,
	[F325] [int] NULL,
	[F326] [int] NULL,
	[F329] [int] NULL,
	[F324] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[F269] [smallmoney] NULL,
	[F270] [smallmoney] NULL,
	[F271] [smallint] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SpartanSilTempMsrpHeader](
	[BatchId] [varchar](8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SourceId] [varchar](6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DestinationId] [varchar](6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OriginalDate] [smalldatetime] NULL,
	[SoftwareRevision] [char](4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[TrailerCount] [int] NULL,
	[ProcessStartTime] [smalldatetime] NULL,
	[ProcessEndTime] [smalldatetime] NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SpartanSupplierSchedule](
	[SupplierId] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[DeliveryDate] [smalldatetime] NOT NULL,
	[DeliverySuffix] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OrderDueDate] [smalldatetime] NULL,
	[OrderBillDate] [smalldatetime] NULL,
	[OrderFacilityDate] [smalldatetime] NULL,
	[OrderDepartDate] [smalldatetime] NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SpartanSystemParameter](
	[param_name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[param_value] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[storeid] [int] NULL,
	[employeeid] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StoreConfig](
	[StoreId] [smallint] NOT NULL,
	[StoreName] [char](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[StoreAddress1] [varchar](40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[StoreAddress2] [varchar](40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[StoreCity] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[StoreState] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[StoreZip] [varchar](9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ToleranceType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ToleranceAmount] [numeric](10, 4) NULL,
	[SoftwareVersion] [char](3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PhysicalHostName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ServiceEndpoint] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IbmPosIpAddr] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IbmPosFtpUid] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IbmPosFtpPwd] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IbmPosFtpTlogPath] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IbmPosFtpTlogFilespec] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ConnectString] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IsOffline] [bit] NULL,
	[Iss45EjPath] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Iss45EjFileSpec] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[FinAcctSegment] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_StoreConfig] PRIMARY KEY CLUSTERED 
(
	[StoreId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Supplier](
	[SupplierId] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SupplierName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SupplierAddress1] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SupplierAddress2] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SupplierCity] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SupplierState] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SupplierZip] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SupplierPhone] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SupplierFax] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SupplierModem] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SupplierContact] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OrderSendProgram] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SupplierPhone2] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SupplierPhone3] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IsActive] [bit] NULL,
	[IsHighRisk] [bit] NULL,
	[IsTotalsOnly] [bit] NULL,
	[IsAutoReconcile] [bit] NULL,
	[IsApExport] [bit] NULL,
	[IsDsd] [bit] NULL,
	[Notes] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[TotalsOnlyMarkupAmount] [decimal](9, 4) NOT NULL,
	[IsAuthorizedForReceiving] [bit] NOT NULL,
	[IsAuthorizedForOrdering] [bit] NOT NULL,
	[InvoiceToleranceValue] [decimal](9, 4) NULL,
	[InvoiceTolerancePercent] [decimal](9, 4) NULL,
	[InvoiceToleranceType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DunsId] [varchar](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SupplierShortName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AllowAdjustCostDuringReceiving] [bit] NULL,
	[AllowAdjustCostDuringReconciliation] [bit] NULL,
	[CanOrderFrom] [varchar](155) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[InvoiceCostMode] [int] NOT NULL,
 CONSTRAINT [PK_Supplier] PRIMARY KEY CLUSTERED 
(
	[SupplierId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SupplierProd](
	[SupplierId] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CasePack] [smallint] NOT NULL,
	[CaseUpc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[OrderCode] [varchar](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CaseWeight] [numeric](7, 2) NOT NULL,
	[ShipTypeCd] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CrossDockCd] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_SupplierProd] PRIMARY KEY CLUSTERED 
(
	[Upc] ASC,
	[SupplierId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SupplierProdZone](
	[SupplierId] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SupplierZoneId] [int] NOT NULL,
	[CaseCost] [decimal](18, 4) NOT NULL,
	[UnitCost] [decimal](18, 4) NOT NULL,
	[DepositCharge] [decimal](18, 2) NOT NULL,
	[DepositDepartmentId] [smallint] NULL,
	[SplitCharge] [decimal](18, 2) NOT NULL,
	[SuggPriceAmt] [decimal](18, 2) NOT NULL,
	[SuggPriceMult] [int] NOT NULL,
 CONSTRAINT [PK_SupplierProdZone] PRIMARY KEY CLUSTERED 
(
	[SupplierId] ASC,
	[Upc] ASC,
	[SupplierZoneId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SupplierZone](
	[SupplierId] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SupplierZoneId] [int] NOT NULL,
	[SupplierZoneDescr] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_SupplierZone] PRIMARY KEY CLUSTERED 
(
	[SupplierId] ASC,
	[SupplierZoneId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SupplierZoneStore](
	[SupplierId] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[SupplierZoneId] [int] NOT NULL,
 CONSTRAINT [PK_SupplierZoneStore] PRIMARY KEY CLUSTERED 
(
	[SupplierId] ASC,
	[StoreId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Uom](
	[UomCd] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[UomDescr] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AltUomNmbr] [int] NOT NULL,
 CONSTRAINT [PK_Uom] PRIMARY KEY CLUSTERED 
(
	[UomCd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[item_view_ibmsa] AS
SELECT     
	-- Product (and lookup tables)
	p.Upc
	,p.BrandName
	,p.ItemDescr
	,p.Size
	,p.UomCd
	,u.UomDescr
	,d.DepartmentId
	,d.DepartmentName
	,CAST(d.DepartmentId AS VARCHAR) + '-' + d.DepartmentName AS DepartmentIdAndName
	,p.ProductTypeCd
	,ptype.ProductTypeDescr
	,pstatus.ProductStatusCd
	,pstatus.ProductStatusDescr
	,p.ProductAvailableDate
	,p.StatusModifiedDate
	,p.SectionId
	,cc.CatClassDescr
	,p.ReceiveByWeight AS ReceiveByWeight
	,p.CreateDate AS CreateDate
	,p.NewItemReviewDate

	-- SupplierProduct/Supplier (primary vendor only)
	,supp.SupplierId
	,supp.SupplierName AS [PrimSupplier]
	,supp.SupplierName
	,supp.SupplierShortName AS [SupplierShortName]
	,sp.OrderCode
	,sp.CasePack
	,spz.CaseCost
	,spz.UnitCost
	,spz.DepositCharge
	,spz.SplitCharge
	,sp.ShipTypeCd
	,st.ShipTypeDescr
	,sp.CrossDockCd

	-- normal price
	,ppn.PriceAmt AS RegPrice
	,ppn.PriceMult RegMultiple
	,ppn.IbmSaPriceMethod AS RegPriceMethod
	,ppn.IbmSaDealPrice AS RegDealPrice
	,ppn.IbmSaMpGroup AS RegMpGroup

	-- current price
	,ppc.PriceAmt AS CurrPrice
	,ppc.PriceMult AS CurrMultiple
	,ppc.IbmSaPriceMethod AS CurrPriceMethod
	,ppc.IbmSaDealPrice AS CurrDealPrice
	,ppc.IbmSaMpGroup AS CurrMpGroup

	-- ProductStore
	,CONVERT(BIT, ps.PosValid) AS PosValid
	,ISNULL(ps.QtyOnHand, 0) AS QtyOnHand
	,ps.LblSizeCd
	,ls.LblSizeDescr
	,ps.InventoryCost
	,ps.LabelRequestDate
	,ps.LabelRequestUser
	,ps.SignRequestDate
	,ps.SignRequestUser
	,CASE 
		WHEN ps.LabelRequestDate IS NULL THEN CAST(0 AS BIT)
		ELSE CAST(1 AS BIT)
	END AS IsLabelRequested
	,ps.NewItemReviewDate AS StoreNewItemReviewDate
	,ISNULL(ps.OrderThreshold, 0) AS OrderThreshold
	,CustomPriceCd
	
	-- ProductSign
	,psign.DisplayBrand
	,psign.DisplayDescription
	,psign.DisplayComment1
	,psign.DisplayComment2
	,psign.DisplayCOmment3
	,psign.ItemAttribute1
	,psign.ItemAttribute2
	,psign.ItemAttribute3
	,psign.ItemAttribute4
	,psign.ItemAttribute5
	,psign.ItemAttribute6
	,psign.ItemAttribute7
	,psign.ItemAttribute8
	,psign.ItemAttribute9
	,psign.ItemAttribute10
	,psign.SoldAs
	,psign.ReviewedDate
	,psign.GroupSizeRange
	,psign.GroupBrandName
	,psign.GroupItemDescription
	,psign.GroupPrintQty
	,psign.GroupComment

-- RegIbmSa
	,regIbmSa.PosDescription
	,regIbmSa.Advertized
	,regIbmSa.KeepItemMovement
	,regIbmSa.PriceRequired
	,regIbmSa.WeightPriceRequired
	,regIbmSa.CouponFamilyCurrent
	,regIbmSa.CouponFamilyPrevious
	,regIbmSa.Discountable
	,regIbmSa.CouponMultiple
	,regIbmSa.ExceptLogItemSale
	,regIbmSa.QtyAllowed
	,regIbmSa.QtyRequired
	,regIbmSa.AuthSale
	,regIbmSa.RestrictSaleHours
	,regIbmSa.TerminalItemRecord
	,regIbmSa.AllowPrint
	,regIbmSa.User1
	,regIbmSa.User2
	,regIbmSa.User3
	,regIbmSa.User4
	,regIbmSa.UserData1
	,regIbmSa.UserData2
	,regIbmSa.ApplyPoints
	,regIbmSa.LinkCode
	,regIbmSa.ItemLinkToDeposit
	,regIbmSa.FoodStamp
	,regIbmSa.TradingStamp
	,regIbmSa.Wic
	,regIbmSa.TaxA
	,regIbmSa.TaxB
	,regIbmSa.TaxC
	,regIbmSa.TaxD
	,regIbmSa.TaxE
	,regIbmSa.TaxF
	,regIbmSa.QhpQualifiedHealthcareItem
	,regIbmSa.RxPrescriptionItem
	,regIbmSa.WicCvv
	
	-- OnHand
	,ISNULL(oh.Qty, 0) AS OnhandQty
	,ISNULL(oh.LastChgTm,'1/1/1900') AS OnhandLastChangeTm
	
	,sc.StoreId
FROM         
	dbo.Prod p WITH (NOLOCK)
CROSS JOIN 
	StoreConfig AS sc
	
-- Common Stuff
LEFT OUTER JOIN dbo.Department d WITH (NOLOCK) ON 
	p.DepartmentId = d.DepartmentId 
LEFT OUTER JOIN ProdSign psign WITH (NOLOCK) ON
	psign.Upc = p.upc
	
-- Store Specific Stuff
LEFT OUTER JOIN ProdStore ps WITH (NOLOCK) ON
	ps.upc = p.upc
	AND ps.storeid = sc.StoreId
LEFT OUTER JOIN ProdPrice ppn WITH (NOLOCK) ON
	ppn.upc = p.upc
	AND ppn.pricetype = 'N'
	AND ppn.storeid = sc.StoreId
LEFT OUTER JOIN ProdPrice ppc WITH (NOLOCK) ON
	ppc.upc = p.upc
	AND ppc.pricetype = 'C'
	AND ppc.storeid = sc.StoreId
LEFT OUTER JOIN OnHand oh ON
	oh.Upc = p.Upc
	AND oh.StoreId = sc.StoreId

-- Supplier Stuff	
LEFT OUTER JOIN SupplierProd sp WITH (NOLOCK) ON
	sp.Upc = ps.Upc
	AND sp.supplierid = ps.PriSupplierId
LEFT OUTER JOIN SupplierZoneStore szs ON
	szs.SupplierId = ps.PriSupplierId
	AND szs.StoreId = ps.StoreId
LEFT OUTER JOIN SupplierProdZone spz ON
	spz.SupplierId = sp.SupplierId
	AND spz.SupplierZoneId = szs.SupplierZoneId
	AND spz.Upc = p.Upc
LEFT OUTER JOIN ShipType st WITH (NOLOCK) ON
	st.ShipTypeCd = sp.ShipTypeCd
LEFT OUTER JOIN supplier supp WITH (NOLOCK) ON
	supp.SupplierId = sp.SupplierId

-- Code->Description lookup tables
LEFT OUTER JOIN LblSize ls WITH (NOLOCK) ON
	ls.LblSizeCd = ps.LbLSizeCd
LEFT OUTER JOIN ProductStatus pstatus WITH (NOLOCK) ON
	pstatus.ProductStatusCd = p.ProductStatusCd
LEFT OUTER JOIN ProductType ptype WITH (NOLOCK) ON
	ptype.ProductTypeCd = p.ProductTypeCd
LEFT OUTER JOIN Uom u ON
	u.UomCd = p.UomCd
LEFT OUTER JOIN CatClass cc ON
	cc.CatClassId = p.SectionId
	AND cc.CatClassType = 50

-- ProdPosIbmSa	
LEFT OUTER JOIN ProdPosIbmSa regIbmSa ON
	regIbmSa.Upc = p.Upc
	AND regIbmSa.StoreId = sc.StoreId






GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE    VIEW [dbo].[item_view_iss45] AS

SELECT     
	
	-- Product (and lookup tables)
	p.Upc
	,p.BrandName
	,p.ItemDescr
	,p.Size
	,p.UomCd
	,u.UomDescr
	,d.DepartmentId
	,d.DepartmentName
	,CAST(d.DepartmentId AS VARCHAR) + '-' + d.DepartmentName AS DepartmentIdAndName
	,p.ProductTypeCd
	,ptype.ProductTypeDescr
	,pstatus.ProductStatusCd
	,pstatus.ProductStatusDescr
	,p.ProductAvailableDate
	,p.StatusModifiedDate
	,p.SectionId
	,cc.CatClassDescr

	,p.ReceiveByWeight AS ReceiveByWeight
	,p.CreateDate AS CreateDate
	,p.NewItemReviewDate

	-- SupplierProduct/Supplier (primary vendor only)
	,supp.SupplierId
	,supp.SupplierName as [PrimSupplier]
	,supp.SupplierName
	,supp.SupplierShortName As [SupplierShortName]
	,sp.OrderCode
	,sp.CasePack
	,spz.CaseCost
	,spz.UnitCost
	,spz.DepositCharge
	,spz.SplitCharge
	,sp.ShipTypeCd
	,st.ShipTypeDescr

	-- normal price
	,ppn.PriceAmt AS RegPrice
	,ppn.PriceMult RegMultiple

	-- current price
	,ppc.PriceAmt AS CurrPrice
	,ppc.PriceMult AS CurrMultiple

	-- ProductStore
	,CONVERT(bit, ps.PosValid) as PosValid
	,ISNULL(ps.QtyOnHand, 0) AS QtyOnHand
	,ps.LblSizeCd
	,ls.LblSizeDescr
	,ps.InventoryCost
	,ps.LabelRequestDate
	,ps.LabelRequestUser
	,ps.SignRequestDate
	,ps.SignRequestUser
	,CASE 
		WHEN ps.LabelRequestDate IS NULL THEN CAST(0 AS BIT)
		ELSE CAST(1 AS BIT)
	END AS IsLabelRequested
	,ps.NewItemReviewDate AS StoreNewItemReviewDate
	,ISNULL(ps.OrderThreshold, 0) AS OrderThreshold
	,ps.CustomPriceCd

	-- ProductSign
	,psign.DisplayBrand
	,psign.DisplayDescription
	,psign.DisplayComment1
	,psign.DisplayComment2
	,psign.DisplayCOmment3
	,psign.ItemAttribute1
	,psign.ItemAttribute2
	,psign.ItemAttribute3
	,psign.ItemAttribute4
	,psign.ItemAttribute5
	,psign.ItemAttribute6
	,psign.ItemAttribute7
	,psign.ItemAttribute8
	,psign.ItemAttribute9
	,psign.ItemAttribute10
	,psign.SoldAs
	,psign.ReviewedDate
	,psign.GroupSizeRange
	,psign.GroupBrandName
	,psign.GroupItemDescription
	,psign.GroupPrintQty
	,psign.GroupComment

	-- RegisterIss45
	,regIss45.MSG_CD
	,RTRIM(LTRIM(regIss45.DSPL_DESCR)) AS DSPL_DESCR
	,regIss45.SLS_RESTRICT_GRP
	,RTRIM(LTRIM(regIss45.RCPT_DESCR)) AS RCPT_DESCR
	,regIss45.NON_MDSE_ID
	,regIss45.QTY_RQRD_FG
	,regIss45.SLS_AUTH_FG
	,regIss45.FOOD_STAMP_FG
	,regIss45.WIC_FG
	,regIss45.NG_ENTRY_FG
	,regIss45.STR_CPN_FG
	,regIss45.VEN_CPN_FG
	,regIss45.MAN_PRC_FG
	,regIss45.WGT_ITM_FG
	,regIss45.NON_DISC_FG
	,regIss45.COST_PLUS_FG
	,regIss45.PRC_VRFY_FG
	,regIss45.INHBT_QTY_FG
	,regIss45.DCML_QTY_FG
	,regIss45.TAX_RATE1_FG
	,regIss45.TAX_RATE2_FG
	,regIss45.TAX_RATE3_FG
	,regIss45.TAX_RATE4_FG
	,regIss45.TAX_RATE5_FG
	,regIss45.TAX_RATE6_FG
	,regIss45.TAX_RATE7_FG
	,regIss45.TAX_RATE8_FG
	,regIss45.MIX_MATCH_CD
	,regIss45.RTN_CD
	,regIss45.FAMILY_CD
	,regIss45.DISC_CD
	,regIss45.SCALE_FG
	,regIss45.WGT_SCALE_FG
	,regIss45.FREQ_SHOP_TYPE
	,regIss45.FREQ_SHOP_VAL
	,regIss45.SEC_FAMILY
	,regIss45.POS_MSG
	,regIss45.SHELF_LIFE_DAY
	,regIss45.CPN_NBR
	,regIss45.TAR_WGT_NBR
	,regIss45.CMPRTV_UOM
	,dbo.fn_Iss45UomToDescr(regIss45.CMPRTV_UOM) AS CMPRTV_UOM_DESCR
	,regIss45.CMPR_QTY
	,regIss45.CMPR_UNT
	,regIss45.BNS_CPN_FG
	,regIss45.EXCLUD_MIN_PURCH_FG
	,regIss45.FUEL_FG
	,regIss45.SPR_AUTH_RQRD_FG
	,regIss45.SSP_PRDCT_FG
	,regIss45.FREQ_SHOP_LMT
	,regIss45.DEA_GRP
	,regIss45.BNS_BY_DESCR
	,regIss45.COMP_TYPE
	,regIss45.COMP_PRC
	,regIss45.COMP_QTY
	,regIss45.ASSUME_QTY_FG
	,regIss45.ITM_POINT
	,regIss45.PRC_GRP_ID
	,regIss45.SWW_CODE_FG
	,regIss45.SHELF_STOCK_FG
	,regIss45.PRNT_PLU_ID_RCPT_FG
	,regIss45.BLK_GRP
	,regIss45.EXCHANGE_TENDER_ID
	,regIss45.CAR_WASH_FG
	,regIss45.PACKAGE_UOM
	,dbo.fn_Iss45UomToDescr(regIss45.PACKAGE_UOM) AS PACKAGE_UOM_DESCR
	,regIss45.UNIT_FACTOR
	,regIss45.FS_QTY
	,regIss45.NON_RX_HEALTH_FG
	,regIss45.RX_FG
	,regIss45.EXEMPT_FROM_PROM_FG
	,regIss45.WIC_CVV_FG
	,regIss45.LNK_NBR
	,regIss45.SNAP_HIP_FG
	
	-- OnHand
	,ISNULL(oh.Qty, 0) AS OnhandQty
	,ISNULL(oh.LastChgTm,'1/1/1900') AS OnhandLastChangeTm
	
	-- Iss45 Lookup Tables
	,RTRIM(LTRIM(iss45mm.MixMatchDescr)) AS MixMatchDescr
	,RTRIM(LTRIM(iss45rt.RTN_DESCR)) AS RTN_DESCR
	,RTRIM(LTRIM(iss45tw.DESCR)) AS TAR_WGT_NBR_Descr
	,RTRIM(LTRIM(iss45pim.MSG_TXT)) AS POS_MSG_MSG_TXT
	,RTRIM(LTRIM(iss45dea.DESCR)) AS DEA_GRP_DESCR
	,RTRIM(LTRIM(iss45coup.DESCR)) AS CPN_NBR_DESCR
	,RTRIM(LTRIM(iss45li.LNK_DESC)) AS LNK_NBR_LNK_DESC
	
	,sc.StoreId
FROM         
	dbo.Prod p WITH (NOLOCK)
CROSS JOIN 
	StoreConfig AS sc
	
-- Common Stuff
LEFT OUTER JOIN dbo.Department d WITH (NOLOCK) ON 
	p.DepartmentId = d.DepartmentId 
LEFT OUTER JOIN ProdSign psign WITH (NOLOCK) ON
	psign.Upc = p.upc
LEFT OUTER JOIN CatClass cc WITH (NOLOCK) ON
	cc.CatClassId = p.SectionId
		
-- Store Specific Stuff
LEFT OUTER JOIN ProdStore ps WITH (NOLOCK) ON
	ps.upc = p.upc
	AND ps.storeid = sc.StoreId
LEFT OUTER JOIN ProdPrice ppn WITH (NOLOCK) ON
	ppn.upc = p.upc
	AND ppn.pricetype = 'N'
	AND ppn.storeid = sc.StoreId
LEFT OUTER JOIN ProdPrice ppc WITH (NOLOCK) ON
	ppc.upc = p.upc
	AND ppc.pricetype = 'C'
	AND ppc.storeid = sc.StoreId
LEFT OUTER JOIN ProdPosIss45 regIss45 ON
	regIss45.Upc = p.Upc
	AND regIss45.StoreId = sc.StoreId
LEFT OUTER JOIN OnHand oh ON
	oh.Upc = p.Upc
	AND oh.StoreId = sc.StoreId

-- Supplier Stuff	
LEFT OUTER JOIN SupplierProd sp WITH (NOLOCK) ON
	sp.Upc = ps.Upc
	AND sp.supplierid = ps.PriSupplierId
LEFT OUTER JOIN SupplierZoneStore szs ON
	szs.SupplierId = ps.PriSupplierId
	AND szs.StoreId = ps.StoreId
LEFT OUTER JOIN SupplierProdZone spz ON
	spz.SupplierId = sp.SupplierId
	AND spz.SupplierZoneId = szs.SupplierZoneId
	AND spz.Upc = p.Upc
LEFT OUTER JOIN ShipType st WITH (NOLOCK) ON
	st.ShipTypeCd = sp.ShipTypeCd
LEFT OUTER JOIN supplier supp WITH (NOLOCK) ON
	supp.SupplierId = sp.SupplierId

-- Code->Description lookup tables
LEFT OUTER JOIN LblSize ls WITH (NOLOCK) ON
	ls.LblSizeCd = ps.LblSizeCd
LEFT OUTER JOIN ProductStatus pstatus WITH (NOLOCK) ON
	pstatus.ProductStatusCd = p.ProductStatusCd
LEFT OUTER JOIN ProductType ptype WITH (NOLOCK) ON
	ptype.ProductTypeCd = p.ProductTypeCd
LEFT OUTER JOIN Iss45MixMatch iss45mm ON
	iss45mm.MixMatchCd = regIss45.MIX_MATCH_CD
LEFT OUTER JOIN Uom u ON
	u.UomCd = p.UomCd
LEFT OUTER JOIN Iss45_RTN_TYPE iss45rt ON
	iss45rt.RTN_NBR = regIss45.RTN_CD
LEFT OUTER JOIN Iss45_TARE_WGT iss45tw ON
	iss45tw.TAR_WGT_NBR = regIss45.TAR_WGT_NBR
LEFT OUTER JOIN Iss45_POST_ITM_MSG iss45pim ON
	iss45pim.MSG_NBR = regIss45.POS_MSG
LEFT OUTER JOIN Iss45_DEA_GRP iss45dea ON
	iss45dea.ID = regIss45.DEA_GRP
LEFT OUTER JOIN Iss45_COUPON iss45coup ON
	iss45coup.COUP_NBR = regIss45.CPN_NBR
LEFT OUTER JOIN Iss45_LINKED_ITEMS_HDR iss45li ON
	iss45li.LNK_NBR = regIss45.LNK_NBR



GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[ProductAudit_View]
AS

SELECT 
	row_id
   ,audit_time
   ,audit_type
   ,user_name
   ,Source
   ,Category
   ,Upc
   ,CASE
		WHEN FieldName = 'BrandId' THEN 'Brand'
		ELSE FieldName
	END AS FieldName
   ,CASE 
		WHEN FieldName <> 'BrandId' THEN NewValue
		ELSE (SELECT BrandName FROM Brand WHERE BrandId = NewValue)
	END AS NewValue 
   ,CASE
		WHEN FieldName <> 'BrandId' THEN OldValue
		ELSE (SELECT BrandName FROM Brand WHERE BrandId = OldValue)
	END AS OldValue 
   ,ExtraInfo
   ,StoreId 
FROM 
	ProductAudit AS pa

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE           VIEW [dbo].[ProductBatchHeader_View]
AS

SELECT
	pbh.BatchId
	,pbh.StoreId
	,(SELECT COUNT(pbs.StoreId) FROM ProductBatchStore pbs WHERE BatchId = pbh.BatchId) AS StoreCount
	,pbh.ProductBatchTypeId
	,pbt.TypeName
	,pbt.GroupName
	,pbt.AffectsPricing
	,pbt.Priority
	,pbh.StartDate
	,pbh.EndDate
	,pbh.Description
	,pbh.Sent
	,pbh.DateSent
	,pbh.ShowInProcessItemUpdates
	,pbh.DateSentToRcp
	,pbh.ReleasedTime
	,pbh.CreateTime
	,pbh.LastChangeTime
	,pbh.AutoApplyOnTime
	,pbh.AutoApplyOnSentTime
	,pbh.AutoApplyOffTime
	,pbh.AutoApplyOffSentTime
	,pbh.IsReadOnly

	,CASE
		-- StartDate only batches
		WHEN pbh.EndDate IS NULL 
				AND pbh.StartDate = dbo.fn_DateTimeToDateOnly(GETDATE())
				AND (SELECT COUNT(1) FROM ProductBatchDetail pbd WHERE pbd.BatchId = pbh.BatchId AND pbd.HasStarted = 0) > 0 
			THEN 1 -- STARTING TODAY
		WHEN pbh.EndDate IS NULL 
				AND pbh.StartDate < dbo.fn_DateTimeToDateOnly(GETDATE())
				AND (SELECT COUNT(1) FROM ProductBatchDetail pbd WHERE pbd.BatchId = pbh.BatchId AND pbd.HasStarted = 0) > 0 
			THEN 2 -- ACTIVE
		WHEN pbh.EndDate IS NULL 
				AND pbh.StartDate > dbo.fn_DateTimeToDateOnly(GETDATE())
			THEN 3 -- always 'FUTURE' if startdate > today
		WHEN pbh.EndDate IS NULL 
				AND (SELECT COUNT(1) FROM ProductBatchDetail pbd WHERE pbd.BatchId = pbh.BatchId AND pbd.HasStarted = 0) = 0 
			THEN 4 -- if Unapplied count = 0, ENDED

		-- StartDate/EndDate batches
		WHEN pbh.EndDate IS NOT NULL 
				AND pbh.StartDate = dbo.fn_DateTimeToDateOnly(GETDATE())
			THEN 1	-- STARTING TODAY
		WHEN pbh.EndDate IS NOT NULL 
				AND pbh.StartDate < dbo.fn_DateTimeToDateOnly(GETDATE()) 
				AND pbh.EndDate >= dbo.fn_DateTimeToDateOnly(GETDATE())
			THEN 2  -- ACTIVE
		WHEN pbh.EndDate IS NOT NULL 
				AND pbh.StartDate > dbo.fn_DateTimeToDateOnly(GETDATE())
			THEN 3 	-- FUTURE
		WHEN pbh.EndDate IS NOT NULL 
				AND pbh.EndDate < dbo.fn_DateTimeToDateOnly(GETDATE())
			THEN 4	-- ENDED
		
	END AS BatchStatusId
	,(SELECT COUNT(1) FROM ProductBatchDetail pbd WHERE pbd.BatchId = pbh.BatchId) 
		AS ItemCount
    ,(SELECT COUNT(1) FROM ProductBatchDetail pbd WHERE pbd.BatchId = pbh.BatchId AND pbd.HasStarted = 0) 
		AS UnappliedItemCount
    ,(SELECT COUNT(1) FROM ProductBatchDetail pbd WHERE pbd.BatchId = pbh.BatchId AND pbd.HasStarted = 1) 
		AS AppliedItemCount

    ,(SELECT COUNT(1) FROM ProductBatchDetail pbd WHERE pbd.BatchId = pbh.BatchId AND pbd.LabelBatchId IS NULL) 
		AS UnprintedItemCount

	-- time parts for Auto Apply ON
	,CASE
		WHEN pbh.AutoApplyOnTime IS NULL THEN NULL 
		ELSE DATEDIFF(dd, CAST(pbh.AutoApplyOnTime AS DATETIME), GETDATE()) 
	END AS days_since_auto_apply_on_time
	,CASE 
		WHEN pbh.AutoApplyOnTime IS NULL THEN NULL 
		ELSE DATEDIFF(mi, CAST(pbh.AutoApplyOnTime AS DATETIME), GETDATE()) 
	END AS minutes_since_auto_apply_on_time
	,CASE 
		WHEN pbh.AutoApplyOnTime IS NULL THEN NULL 
		ELSE DATEDIFF(ss, CAST(pbh.AutoApplyOnTime AS DATETIME), GETDATE()) 
	END AS seconds_since_auto_apply_on_time

	-- time parts for Auto Apply OFF
	,CASE
		WHEN pbh.AutoApplyOffTime IS NULL THEN NULL 
		ELSE DATEDIFF(dd, CAST(pbh.AutoApplyOffTime AS DATETIME), GETDATE()) 
	END AS days_since_auto_apply_off_time
	,CASE 
		WHEN pbh.AutoApplyOffTime IS NULL THEN NULL 
		ELSE DATEDIFF(mi, CAST(pbh.AutoApplyOffTime AS DATETIME), GETDATE()) 
	END AS minutes_since_auto_apply_off_time
	,CASE 
		WHEN pbh.AutoApplyOffTime IS NULL THEN NULL 
		ELSE DATEDIFF(ss, CAST(pbh.AutoApplyOffTime AS DATETIME), GETDATE()) 
	END AS seconds_since_auto_apply_off_time
FROM
	ProductBatchHeader pbh 
LEFT OUTER JOIN ProductBatchType pbt ON
	pbt.ProductBatchTypeId = pbh.ProductBatchTypeId

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE    VIEW [dbo].[Supplier_View]
AS

SELECT 
	SupplierId
   ,SupplierName
   ,SupplierAddress1
   ,SupplierAddress2
   ,SupplierCity
   ,SupplierState
   ,SupplierZip
   ,SupplierPhone
   ,SupplierFax
   ,SupplierModem
   ,SupplierContact
   ,OrderSendProgram
   ,SupplierPhone2
   ,SupplierPhone3
   ,IsActive
   ,IsHighRisk
   ,IsTotalsOnly
   ,IsAutoReconcile
   ,IsApExport
   ,IsDsd
   ,Notes
   ,TotalsOnlyMarkupAmount
   ,IsAuthorizedForReceiving
   ,IsAuthorizedForOrdering
   ,InvoiceToleranceValue
   ,InvoiceTolerancePercent
   ,InvoiceToleranceType
   ,DunsId
   ,SupplierShortName
   ,AllowAdjustCostDuringReceiving
   ,AllowAdjustCostDuringReconciliation 
   
   ,SupplierId + '-' + SupplierName AS SupplierIdAndName
   ,CAST(SupplierId AS BIGINT) AS NumericSupplierId
   ,SupplierName + '-' + SupplierId AS SupplierNameAndId
   ,SupplierId + '-' + s.SupplierShortName AS SupplierIdAndShortName
   ,CanOrderFrom
   ,InvoiceCostMode
   ,CASE 
		WHEN InvoiceCostMode = 1 THEN 'Base Cost less Allowances'
		ELSE 'Last Received Cost'
   END AS InvoiceCostModeString
FROM 
	Supplier AS s

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vwCatClass] AS

SELECT
	cc5.CatClassId AS cc5_id
	,cc5.CatClassType AS cc5_type
	,cc5.EndCatClass AS cc5_end_id
	,cc5.CatClassDescr AS cc5_desc
	,cc5.DepartmentId AS cc5_dept
	,cc5.LblSizeCd AS cc5_LblSizeCd

	,cc4.CatClassId AS cc4_id
	,cc4.CatClassType AS cc4_type
	,cc4.EndCatClass AS cc4_end_id
	,cc4.CatClassDescr AS cc4_desc
	,cc4.DepartmentId AS cc4_dept
	,cc4.LblSizeCd AS cc4_LblSizeCd

	,cc3.CatClassId AS cc3_id
	,cc3.CatClassType AS cc3_type
	,cc3.EndCatClass AS cc3_end_id
	,cc3.CatClassDescr AS cc3_desc
	,cc3.DepartmentId AS cc3_dept
	,cc3.LblSizeCd AS cc3_LblSizeCd

	,cc2.CatClassId AS cc2_id
	,cc2.CatClassType AS cc2_type
	,cc2.EndCatClass AS cc2_end_id
	,cc2.CatClassDescr AS cc2_desc
	,cc2.DepartmentId AS cc2_dept
	,cc2.LblSizeCd AS cc2_LblSizeCd

	,cc1.CatClassId AS cc1_id
	,cc1.CatClassType AS cc1_type
	,cc1.EndCatClass AS cc1_end_id
	,cc1.CatClassDescr AS cc1_desc
	,cc1.DepartmentId AS cc1_dept
	,cc1.LblSizeCd AS cc1_LblSizeCd
	
FROM 
	CatClass cc5  WITH (NOLOCK) 
LEFT OUTER JOIN CatClass cc4  WITH (NOLOCK) ON
	cc4.CatClassType=40
	AND cc4.CatClassId = (cc5.CatClassId - (cc5.CatClassId % 100))
LEFT OUTER JOIN CatClass cc3  WITH (NOLOCK) ON
	cc3.CatClassType=30
	AND cc3.CatClassId = (cc4.CatClassId - (cc4.CatClassId % 1000))
LEFT OUTER JOIN CatClass cc2  WITH (NOLOCK) ON
	cc2.CatClassType=20
	AND cc3.CatClassId BETWEEN cc2.CatClassId AND cc2.EndCatClass
LEFT OUTER JOIN CatClass cc1  WITH (NOLOCK) ON
	cc1.CatClassType=10
	AND cc2.CatClassId BETWEEN cc1.CatClassId AND cc1.EndCatClass	
WHERE
	cc5.CatClassType=50
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_Upc] ON [dbo].[AllowBatchDetail]
(
	[Upc] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_AbDescr] ON [dbo].[AllowBatchHeader]
(
	[AbDescr] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_HostKey] ON [dbo].[AllowBatchHeader]
(
	[HostKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_SupplierId_Description_HostKey] ON [dbo].[AllowBatchHeader]
(
	[SupplierId] ASC,
	[AbDescr] ASC,
	[HostKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_BrandName] ON [dbo].[Brand]
(
	[BrandName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_Upc] ON [dbo].[CstBatchDetail]
(
	[Upc] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_CbDescr] ON [dbo].[CstBatchHeader]
(
	[CbDescr] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_SupplierId] ON [dbo].[CstBatchHeader]
(
	[SupplierId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_Upc_InvId_StoreId] ON [dbo].[InvoiceDetail]
(
	[Upc] ASC,
	[InvId] ASC,
	[StoreId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_InvDt] ON [dbo].[InvoiceHeader]
(
	[InvDt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_InvNmbr] ON [dbo].[InvoiceHeader]
(
	[InvNmbr] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_SupplierId] ON [dbo].[InvoiceHeader]
(
	[SupplierId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_LNK_TYPE_LNK_ID] ON [dbo].[Iss45MemberPromLink]
(
	[LNK_TYP] ASC,
	[LNK_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_ProcessStatus_PosBatchId] ON [dbo].[PosBatchDetail]
(
	[ProcessStatus] ASC,
	[BatchId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_StartTimeStopTime] ON [dbo].[PosBatchHeader]
(
	[StartTime] ASC,
	[StopTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_BLK_GRP_Upc_StoreId] ON [dbo].[ProdPosIss45]
(
	[BLK_GRP] ASC,
	[Upc] ASC,
	[StoreId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_MIX_MATCH_CD_Upc_StoreId] ON [dbo].[ProdPosIss45]
(
	[MIX_MATCH_CD] ASC,
	[Upc] ASC,
	[StoreId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_LabelRequestDate] ON [dbo].[ProdStore]
(
	[LabelRequestDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_SignRequestDate] ON [dbo].[ProdStore]
(
	[SignRequestDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_audit_type_upc] ON [dbo].[ProductAudit]
(
	[audit_type] ASC,
	[Upc] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_source] ON [dbo].[ProductAudit]
(
	[Source] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_upc_audit_time] ON [dbo].[ProductAudit]
(
	[Upc] ASC,
	[audit_time] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_BatchId_HasEnded] ON [dbo].[ProductBatchDetail]
(
	[BatchId] ASC,
	[HasEnded] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_BatchId_HasStarted] ON [dbo].[ProductBatchDetail]
(
	[BatchId] ASC,
	[HasStarted] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_HasStarted] ON [dbo].[ProductBatchDetail]
(
	[HasStarted] ASC
)
INCLUDE ( 	[BatchId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_LabelBatchId] ON [dbo].[ProductBatchDetail]
(
	[LabelBatchId] ASC
)
INCLUDE ( 	[BatchId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_Upc] ON [dbo].[ProductBatchDetail]
(
	[UPC] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_EndDate] ON [dbo].[ProductBatchHeader]
(
	[EndDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_StartDate_EndDate] ON [dbo].[ProductBatchHeader]
(
	[StartDate] ASC,
	[EndDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_record_type_record_key] ON [dbo].[realtime_sales_summary]
(
	[record_type] ASC,
	[record_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_UniqueStorePerGroup] ON [dbo].[RetailZoneStore]
(
	[RzGrpId] ASC,
	[StoreId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_OrderId] ON [dbo].[SpartanOrderAudit]
(
	[OrderId] ASC,
	[AuditTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_OrderId_LineItemSeq] ON [dbo].[SpartanOrderDetail]
(
	[OrderId] ASC,
	[LineItemSeq] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_SpartanOrderDetailUnique] ON [dbo].[SpartanOrderDetail]
(
	[OrderId] ASC,
	[UPC] ASC,
	[SupplierSKU] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_SupplierSku_SupplierId] ON [dbo].[SpartanProductXRef]
(
	[SupplierSKU] ASC,
	[SupplierId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_Upc_SupplierId] ON [dbo].[SpartanProductXRef]
(
	[UPC] ASC,
	[SupplierId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_SupplierId_DeliveryDate] ON [dbo].[SpartanSupplierSchedule]
(
	[SupplierId] ASC,
	[DeliveryDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_SoftwareVersion] ON [dbo].[StoreConfig]
(
	[SoftwareVersion] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_IsDsd] ON [dbo].[Supplier]
(
	[IsDsd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_SupplierSku_SupplierId] ON [dbo].[SupplierProd]
(
	[OrderCode] ASC,
	[SupplierId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Department] ADD  CONSTRAINT [Department_DefaultMarkup_Default]  DEFAULT ((0)) FOR [DefaultMarkup]
GO
ALTER TABLE [dbo].[InvoiceHeader] ADD  CONSTRAINT [DF__InvoiceHe__Expor__57DD0BE4]  DEFAULT ((0)) FOR [ExportStatus]
GO
ALTER TABLE [dbo].[InvoiceHeader] ADD  CONSTRAINT [DF__InvoiceHe__Expor__58D1301D]  DEFAULT ((0)) FOR [ExportCount]
GO
ALTER TABLE [dbo].[ProductBatchHeader] ADD  CONSTRAINT [DF_ProductBatchHeader_IsReadOnly]  DEFAULT ((0)) FOR [IsReadOnly]
GO
ALTER TABLE [dbo].[Supplier] ADD  CONSTRAINT [DF_Supplier_InvoiceCostMode]  DEFAULT ((0)) FOR [InvoiceCostMode]
GO
ALTER TABLE [dbo].[AllowBatchDetail]  WITH CHECK ADD  CONSTRAINT [fk_AllowBatchDetail_AllowBatchHeader] FOREIGN KEY([AbId])
REFERENCES [dbo].[AllowBatchHeader] ([AbId])
GO
ALTER TABLE [dbo].[AllowBatchDetail] CHECK CONSTRAINT [fk_AllowBatchDetail_AllowBatchHeader]
GO
ALTER TABLE [dbo].[AllowBatchDetail]  WITH CHECK ADD  CONSTRAINT [fk_AllowBatchDetail_Prod] FOREIGN KEY([Upc])
REFERENCES [dbo].[Prod] ([Upc])
GO
ALTER TABLE [dbo].[AllowBatchDetail] CHECK CONSTRAINT [fk_AllowBatchDetail_Prod]
GO
ALTER TABLE [dbo].[AllowBatchHeader]  WITH CHECK ADD  CONSTRAINT [fk_AllowBatchHeader_Supplier] FOREIGN KEY([SupplierId])
REFERENCES [dbo].[Supplier] ([SupplierId])
GO
ALTER TABLE [dbo].[AllowBatchHeader] CHECK CONSTRAINT [fk_AllowBatchHeader_Supplier]
GO
ALTER TABLE [dbo].[AllowBatchStore]  WITH CHECK ADD  CONSTRAINT [fk_AllowBatchStore_AllowBatchHeader] FOREIGN KEY([AbId])
REFERENCES [dbo].[AllowBatchHeader] ([AbId])
GO
ALTER TABLE [dbo].[AllowBatchStore] CHECK CONSTRAINT [fk_AllowBatchStore_AllowBatchHeader]
GO
ALTER TABLE [dbo].[Batch]  WITH CHECK ADD  CONSTRAINT [FK_Batch_BatchTypeMaster] FOREIGN KEY([BatchType])
REFERENCES [dbo].[BatchTypeMaster] ([BatchType])
GO
ALTER TABLE [dbo].[Batch] CHECK CONSTRAINT [FK_Batch_BatchTypeMaster]
GO
ALTER TABLE [dbo].[BatchDescriptionMaster]  WITH CHECK ADD  CONSTRAINT [FK_BatchDescriptionMaster_BatchTypeMaster] FOREIGN KEY([BatchType])
REFERENCES [dbo].[BatchTypeMaster] ([BatchType])
GO
ALTER TABLE [dbo].[BatchDescriptionMaster] CHECK CONSTRAINT [FK_BatchDescriptionMaster_BatchTypeMaster]
GO
ALTER TABLE [dbo].[BatchItem]  WITH CHECK ADD  CONSTRAINT [FK_BatchItem_Batch] FOREIGN KEY([BatchId], [StoreId])
REFERENCES [dbo].[Batch] ([BatchId], [StoreId])
GO
ALTER TABLE [dbo].[BatchItem] CHECK CONSTRAINT [FK_BatchItem_Batch]
GO
ALTER TABLE [dbo].[BatchItem]  WITH CHECK ADD  CONSTRAINT [FK_BatchItem_Department] FOREIGN KEY([DepartmentId])
REFERENCES [dbo].[Department] ([DepartmentId])
GO
ALTER TABLE [dbo].[BatchItem] CHECK CONSTRAINT [FK_BatchItem_Department]
GO
ALTER TABLE [dbo].[BillbackDetail]  WITH CHECK ADD  CONSTRAINT [fk_BillbackDetail_BillbackHeader] FOREIGN KEY([BbNmbr])
REFERENCES [dbo].[BillbackHeader] ([BbNmbr])
GO
ALTER TABLE [dbo].[BillbackDetail] CHECK CONSTRAINT [fk_BillbackDetail_BillbackHeader]
GO
ALTER TABLE [dbo].[BillbackHeader]  WITH CHECK ADD  CONSTRAINT [fk_BillbackHeader_BillbackType] FOREIGN KEY([BbTypeCd])
REFERENCES [dbo].[BillbackType] ([BbTypeCd])
GO
ALTER TABLE [dbo].[BillbackHeader] CHECK CONSTRAINT [fk_BillbackHeader_BillbackType]
GO
ALTER TABLE [dbo].[BillbackStore]  WITH CHECK ADD  CONSTRAINT [fk_BillbackStore_BillbackHeader] FOREIGN KEY([BbNmbr])
REFERENCES [dbo].[BillbackHeader] ([BbNmbr])
GO
ALTER TABLE [dbo].[BillbackStore] CHECK CONSTRAINT [fk_BillbackStore_BillbackHeader]
GO
ALTER TABLE [dbo].[CstBatchDetail]  WITH CHECK ADD  CONSTRAINT [fk_CstBatchDetail_CstBatchHeader] FOREIGN KEY([CbId])
REFERENCES [dbo].[CstBatchHeader] ([CbId])
GO
ALTER TABLE [dbo].[CstBatchDetail] CHECK CONSTRAINT [fk_CstBatchDetail_CstBatchHeader]
GO
ALTER TABLE [dbo].[CstBatchDetail]  WITH CHECK ADD  CONSTRAINT [fk_CstBatchDetail_Prod] FOREIGN KEY([Upc])
REFERENCES [dbo].[Prod] ([Upc])
GO
ALTER TABLE [dbo].[CstBatchDetail] CHECK CONSTRAINT [fk_CstBatchDetail_Prod]
GO
ALTER TABLE [dbo].[CstBatchHeader]  WITH CHECK ADD  CONSTRAINT [fk_CstBatchHeader_Supplier] FOREIGN KEY([SupplierId])
REFERENCES [dbo].[Supplier] ([SupplierId])
GO
ALTER TABLE [dbo].[CstBatchHeader] CHECK CONSTRAINT [fk_CstBatchHeader_Supplier]
GO
ALTER TABLE [dbo].[CtsGroupPermission]  WITH CHECK ADD  CONSTRAINT [fk_CtsGroupPermission_CtsGroup_1] FOREIGN KEY([GroupName])
REFERENCES [dbo].[CtsGroup] ([GroupName])
GO
ALTER TABLE [dbo].[CtsGroupPermission] CHECK CONSTRAINT [fk_CtsGroupPermission_CtsGroup_1]
GO
ALTER TABLE [dbo].[CtsUserGroup]  WITH CHECK ADD  CONSTRAINT [fk_CtsUserGroup_CtsGroup_1] FOREIGN KEY([GroupName])
REFERENCES [dbo].[CtsGroup] ([GroupName])
GO
ALTER TABLE [dbo].[CtsUserGroup] CHECK CONSTRAINT [fk_CtsUserGroup_CtsGroup_1]
GO
ALTER TABLE [dbo].[CtsUserGroup]  WITH CHECK ADD  CONSTRAINT [fk_CtsUserGroup_CtsUser_1] FOREIGN KEY([UserName])
REFERENCES [dbo].[CtsUser] ([UserName])
GO
ALTER TABLE [dbo].[CtsUserGroup] CHECK CONSTRAINT [fk_CtsUserGroup_CtsUser_1]
GO
ALTER TABLE [dbo].[CtsUserOptionSet]  WITH CHECK ADD  CONSTRAINT [fk_CtsUserOptionSet_CtsUser_1] FOREIGN KEY([UserName])
REFERENCES [dbo].[CtsUser] ([UserName])
GO
ALTER TABLE [dbo].[CtsUserOptionSet] CHECK CONSTRAINT [fk_CtsUserOptionSet_CtsUser_1]
GO
ALTER TABLE [dbo].[Department]  WITH CHECK ADD  CONSTRAINT [FK_Department_MajorDepartment] FOREIGN KEY([MajorDepartmentId])
REFERENCES [dbo].[MajorDepartment] ([MajorDepartmentId])
GO
ALTER TABLE [dbo].[Department] CHECK CONSTRAINT [FK_Department_MajorDepartment]
GO
ALTER TABLE [dbo].[DepartmentIss45]  WITH CHECK ADD  CONSTRAINT [FK_DepartmentIss45_Department] FOREIGN KEY([DepartmentId])
REFERENCES [dbo].[Department] ([DepartmentId])
GO
ALTER TABLE [dbo].[DepartmentIss45] CHECK CONSTRAINT [FK_DepartmentIss45_Department]
GO
ALTER TABLE [dbo].[FutureProdRetail]  WITH CHECK ADD  CONSTRAINT [fk_FutureProdRetail_Prod] FOREIGN KEY([Upc])
REFERENCES [dbo].[Prod] ([Upc])
GO
ALTER TABLE [dbo].[FutureProdRetail] CHECK CONSTRAINT [fk_FutureProdRetail_Prod]
GO
ALTER TABLE [dbo].[HhProfileDetail]  WITH CHECK ADD  CONSTRAINT [FK_HhProfileDetail_HhProfileHeader] FOREIGN KEY([ProfileNumber])
REFERENCES [dbo].[HhProfileHeader] ([ProfileNumber])
GO
ALTER TABLE [dbo].[HhProfileDetail] CHECK CONSTRAINT [FK_HhProfileDetail_HhProfileHeader]
GO
ALTER TABLE [dbo].[Iss45MemberPromLink]  WITH CHECK ADD  CONSTRAINT [FK_Iss45MemberPromLink_Iss45MemberProm] FOREIGN KEY([MMBR_PROM_ID])
REFERENCES [dbo].[Iss45MemberProm] ([MMBR_PROM_ID])
GO
ALTER TABLE [dbo].[Iss45MemberPromLink] CHECK CONSTRAINT [FK_Iss45MemberPromLink_Iss45MemberProm]
GO
ALTER TABLE [dbo].[Iss45MemberPromStore]  WITH CHECK ADD  CONSTRAINT [FK_Iss45MemberPromStore_Iss45MemberProm] FOREIGN KEY([MMBR_PROM_ID])
REFERENCES [dbo].[Iss45MemberProm] ([MMBR_PROM_ID])
GO
ALTER TABLE [dbo].[Iss45MemberPromStore] CHECK CONSTRAINT [FK_Iss45MemberPromStore_Iss45MemberProm]
GO
ALTER TABLE [dbo].[LblBatchDetail]  WITH CHECK ADD  CONSTRAINT [fk_LblBatchDetail_LblBatchHeader_1] FOREIGN KEY([LblBatchId])
REFERENCES [dbo].[LblBatchHeader] ([LblBatchId])
GO
ALTER TABLE [dbo].[LblBatchDetail] CHECK CONSTRAINT [fk_LblBatchDetail_LblBatchHeader_1]
GO
ALTER TABLE [dbo].[LblBatchDetail]  WITH CHECK ADD  CONSTRAINT [fk_LblBatchDetail_Prod_1] FOREIGN KEY([Upc])
REFERENCES [dbo].[Prod] ([Upc])
GO
ALTER TABLE [dbo].[LblBatchDetail] CHECK CONSTRAINT [fk_LblBatchDetail_Prod_1]
GO
ALTER TABLE [dbo].[Prod]  WITH CHECK ADD  CONSTRAINT [fk_Prod_Department_1] FOREIGN KEY([DepartmentId])
REFERENCES [dbo].[Department] ([DepartmentId])
GO
ALTER TABLE [dbo].[Prod] CHECK CONSTRAINT [fk_Prod_Department_1]
GO
ALTER TABLE [dbo].[Prod]  WITH CHECK ADD  CONSTRAINT [fk_Prod_ProductStatus_1] FOREIGN KEY([ProductStatusCd])
REFERENCES [dbo].[ProductStatus] ([ProductStatusCd])
GO
ALTER TABLE [dbo].[Prod] CHECK CONSTRAINT [fk_Prod_ProductStatus_1]
GO
ALTER TABLE [dbo].[Prod]  WITH CHECK ADD  CONSTRAINT [fk_Prod_ProductType_1] FOREIGN KEY([ProductTypeCd])
REFERENCES [dbo].[ProductType] ([ProductTypeCd])
GO
ALTER TABLE [dbo].[Prod] CHECK CONSTRAINT [fk_Prod_ProductType_1]
GO
ALTER TABLE [dbo].[Prod]  WITH CHECK ADD  CONSTRAINT [fk_Prod_Uom_1] FOREIGN KEY([UomCd])
REFERENCES [dbo].[Uom] ([UomCd])
GO
ALTER TABLE [dbo].[Prod] CHECK CONSTRAINT [fk_Prod_Uom_1]
GO
ALTER TABLE [dbo].[ProdGroupDetail]  WITH CHECK ADD  CONSTRAINT [fk_ProdGroupDetail_Prod] FOREIGN KEY([Upc])
REFERENCES [dbo].[Prod] ([Upc])
GO
ALTER TABLE [dbo].[ProdGroupDetail] CHECK CONSTRAINT [fk_ProdGroupDetail_Prod]
GO
ALTER TABLE [dbo].[ProdGroupDetail]  WITH CHECK ADD  CONSTRAINT [fk_ProdGroupDetail_ProdGroupHeader] FOREIGN KEY([GroupId])
REFERENCES [dbo].[ProdGroupHeader] ([GroupId])
GO
ALTER TABLE [dbo].[ProdGroupDetail] CHECK CONSTRAINT [fk_ProdGroupDetail_ProdGroupHeader]
GO
ALTER TABLE [dbo].[ProdPosIbmSa]  WITH CHECK ADD  CONSTRAINT [fk_ProdPosIbmSa_Prod] FOREIGN KEY([Upc])
REFERENCES [dbo].[Prod] ([Upc])
GO
ALTER TABLE [dbo].[ProdPosIbmSa] CHECK CONSTRAINT [fk_ProdPosIbmSa_Prod]
GO
ALTER TABLE [dbo].[ProdPosIss45]  WITH CHECK ADD  CONSTRAINT [fk_ProdPosIss45_Prod] FOREIGN KEY([Upc])
REFERENCES [dbo].[Prod] ([Upc])
GO
ALTER TABLE [dbo].[ProdPosIss45] CHECK CONSTRAINT [fk_ProdPosIss45_Prod]
GO
ALTER TABLE [dbo].[ProdPrice]  WITH CHECK ADD  CONSTRAINT [fk_ProdPrice_Prod] FOREIGN KEY([Upc])
REFERENCES [dbo].[Prod] ([Upc])
GO
ALTER TABLE [dbo].[ProdPrice] CHECK CONSTRAINT [fk_ProdPrice_Prod]
GO
ALTER TABLE [dbo].[ProdPriceZone]  WITH CHECK ADD  CONSTRAINT [fk_ProdPriceZone_Prod] FOREIGN KEY([Upc])
REFERENCES [dbo].[Prod] ([Upc])
GO
ALTER TABLE [dbo].[ProdPriceZone] CHECK CONSTRAINT [fk_ProdPriceZone_Prod]
GO
ALTER TABLE [dbo].[ProdPriceZone]  WITH CHECK ADD  CONSTRAINT [fk_ProdPriceZone_RetailZoneSegment] FOREIGN KEY([RzGrpId], [RzSegId])
REFERENCES [dbo].[RetailZoneSegment] ([RzGrpId], [RzSegId])
GO
ALTER TABLE [dbo].[ProdPriceZone] CHECK CONSTRAINT [fk_ProdPriceZone_RetailZoneSegment]
GO
ALTER TABLE [dbo].[ProdSign]  WITH CHECK ADD  CONSTRAINT [fk_ProdSign_Prod] FOREIGN KEY([Upc])
REFERENCES [dbo].[Prod] ([Upc])
GO
ALTER TABLE [dbo].[ProdSign] CHECK CONSTRAINT [fk_ProdSign_Prod]
GO
ALTER TABLE [dbo].[ProdStore]  WITH CHECK ADD  CONSTRAINT [fk_ProdStore_Prod] FOREIGN KEY([Upc])
REFERENCES [dbo].[Prod] ([Upc])
GO
ALTER TABLE [dbo].[ProdStore] CHECK CONSTRAINT [fk_ProdStore_Prod]
GO
ALTER TABLE [dbo].[ProductBatchDetail]  WITH CHECK ADD  CONSTRAINT [fk_ProductBatchDetail_Prod_1] FOREIGN KEY([UPC])
REFERENCES [dbo].[Prod] ([Upc])
GO
ALTER TABLE [dbo].[ProductBatchDetail] CHECK CONSTRAINT [fk_ProductBatchDetail_Prod_1]
GO
ALTER TABLE [dbo].[ProductBatchDetail]  WITH CHECK ADD  CONSTRAINT [FK_ProductBatchDetail_ProductBatchHeader] FOREIGN KEY([BatchId])
REFERENCES [dbo].[ProductBatchHeader] ([BatchId])
GO
ALTER TABLE [dbo].[ProductBatchDetail] CHECK CONSTRAINT [FK_ProductBatchDetail_ProductBatchHeader]
GO
ALTER TABLE [dbo].[ProductBatchHeader]  WITH CHECK ADD  CONSTRAINT [FK_ProductBatchHeader_ProductBatchType] FOREIGN KEY([ProductBatchTypeId])
REFERENCES [dbo].[ProductBatchType] ([ProductBatchTypeId])
GO
ALTER TABLE [dbo].[ProductBatchHeader] CHECK CONSTRAINT [FK_ProductBatchHeader_ProductBatchType]
GO
ALTER TABLE [dbo].[ProductBatchStore]  WITH CHECK ADD  CONSTRAINT [FK_ProductBatchStore_ProductBatchHeader] FOREIGN KEY([BatchId])
REFERENCES [dbo].[ProductBatchHeader] ([BatchId])
GO
ALTER TABLE [dbo].[ProductBatchStore] CHECK CONSTRAINT [FK_ProductBatchStore_ProductBatchHeader]
GO
ALTER TABLE [dbo].[RetailZoneSegment]  WITH CHECK ADD  CONSTRAINT [fk_RetailZoneSegment_RetailZoneGroup_1] FOREIGN KEY([RzGrpId])
REFERENCES [dbo].[RetailZoneGroup] ([RzGrpId])
GO
ALTER TABLE [dbo].[RetailZoneSegment] CHECK CONSTRAINT [fk_RetailZoneSegment_RetailZoneGroup_1]
GO
ALTER TABLE [dbo].[RetailZoneStore]  WITH CHECK ADD  CONSTRAINT [fk_RetailZoneStore_RetailZoneSegment_1] FOREIGN KEY([RzGrpId], [RzSegId])
REFERENCES [dbo].[RetailZoneSegment] ([RzGrpId], [RzSegId])
GO
ALTER TABLE [dbo].[RetailZoneStore] CHECK CONSTRAINT [fk_RetailZoneStore_RetailZoneSegment_1]
GO
ALTER TABLE [dbo].[SpartanC3AdDetail]  WITH CHECK ADD  CONSTRAINT [FK_SpartanC3AdDetail_SpartanC3AdHeader] FOREIGN KEY([AdId])
REFERENCES [dbo].[SpartanC3AdHeader] ([AdId])
GO
ALTER TABLE [dbo].[SpartanC3AdDetail] CHECK CONSTRAINT [FK_SpartanC3AdDetail_SpartanC3AdHeader]
GO
ALTER TABLE [dbo].[SpartanMsrpBatchHeader]  WITH CHECK ADD  CONSTRAINT [FK_SpartanMsrpBatchHeader_Supplier] FOREIGN KEY([SupplierId])
REFERENCES [dbo].[Supplier] ([SupplierId])
GO
ALTER TABLE [dbo].[SpartanMsrpBatchHeader] CHECK CONSTRAINT [FK_SpartanMsrpBatchHeader_Supplier]
GO
ALTER TABLE [dbo].[SpartanOrderAudit]  WITH CHECK ADD  CONSTRAINT [FK_SpartanOrderAudit_SpartanOrderHeader] FOREIGN KEY([OrderId])
REFERENCES [dbo].[SpartanOrderHeader] ([OrderId])
GO
ALTER TABLE [dbo].[SpartanOrderAudit] CHECK CONSTRAINT [FK_SpartanOrderAudit_SpartanOrderHeader]
GO
ALTER TABLE [dbo].[SpartanOrderDetail]  WITH CHECK ADD  CONSTRAINT [FK_SpartanOrderDetail_SpartanOrderHeader] FOREIGN KEY([OrderId])
REFERENCES [dbo].[SpartanOrderHeader] ([OrderId])
GO
ALTER TABLE [dbo].[SpartanOrderDetail] CHECK CONSTRAINT [FK_SpartanOrderDetail_SpartanOrderHeader]
GO
ALTER TABLE [dbo].[SpartanOrderHeader]  WITH CHECK ADD  CONSTRAINT [FK_SpartanOrderHeader_Supplier] FOREIGN KEY([SupplierId])
REFERENCES [dbo].[Supplier] ([SupplierId])
GO
ALTER TABLE [dbo].[SpartanOrderHeader] CHECK CONSTRAINT [FK_SpartanOrderHeader_Supplier]
GO
ALTER TABLE [dbo].[SupplierProd]  WITH CHECK ADD  CONSTRAINT [fk_SupplierProd_Prod] FOREIGN KEY([Upc])
REFERENCES [dbo].[Prod] ([Upc])
GO
ALTER TABLE [dbo].[SupplierProd] CHECK CONSTRAINT [fk_SupplierProd_Prod]
GO
ALTER TABLE [dbo].[SupplierProd]  WITH CHECK ADD  CONSTRAINT [fk_SupplierProd_ShipType_1] FOREIGN KEY([ShipTypeCd])
REFERENCES [dbo].[ShipType] ([ShipTypeCd])
GO
ALTER TABLE [dbo].[SupplierProd] CHECK CONSTRAINT [fk_SupplierProd_ShipType_1]
GO
ALTER TABLE [dbo].[SupplierProd]  WITH CHECK ADD  CONSTRAINT [fk_SupplierProd_Supplier] FOREIGN KEY([SupplierId])
REFERENCES [dbo].[Supplier] ([SupplierId])
GO
ALTER TABLE [dbo].[SupplierProd] CHECK CONSTRAINT [fk_SupplierProd_Supplier]
GO
ALTER TABLE [dbo].[SupplierProdZone]  WITH CHECK ADD  CONSTRAINT [fk_SupplierProdZone_Prod] FOREIGN KEY([Upc])
REFERENCES [dbo].[Prod] ([Upc])
GO
ALTER TABLE [dbo].[SupplierProdZone] CHECK CONSTRAINT [fk_SupplierProdZone_Prod]
GO
ALTER TABLE [dbo].[SupplierProdZone]  WITH CHECK ADD  CONSTRAINT [fk_SupplierProdZone_SupplierProd] FOREIGN KEY([Upc], [SupplierId])
REFERENCES [dbo].[SupplierProd] ([Upc], [SupplierId])
GO
ALTER TABLE [dbo].[SupplierProdZone] CHECK CONSTRAINT [fk_SupplierProdZone_SupplierProd]
GO
ALTER TABLE [dbo].[SupplierProdZone]  WITH CHECK ADD  CONSTRAINT [fk_SupplierProdZone_SupplierZone] FOREIGN KEY([SupplierId], [SupplierZoneId])
REFERENCES [dbo].[SupplierZone] ([SupplierId], [SupplierZoneId])
GO
ALTER TABLE [dbo].[SupplierProdZone] CHECK CONSTRAINT [fk_SupplierProdZone_SupplierZone]
GO
ALTER TABLE [dbo].[SupplierZone]  WITH CHECK ADD  CONSTRAINT [fk_SupplierZone_Supplier] FOREIGN KEY([SupplierId])
REFERENCES [dbo].[Supplier] ([SupplierId])
GO
ALTER TABLE [dbo].[SupplierZone] CHECK CONSTRAINT [fk_SupplierZone_Supplier]
GO
ALTER TABLE [dbo].[SupplierZoneStore]  WITH CHECK ADD  CONSTRAINT [fk_SupplierZoneStore_SupplierZone] FOREIGN KEY([SupplierId], [SupplierZoneId])
REFERENCES [dbo].[SupplierZone] ([SupplierId], [SupplierZoneId])
GO
ALTER TABLE [dbo].[SupplierZoneStore] CHECK CONSTRAINT [fk_SupplierZoneStore_SupplierZone]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AllowanceBatch_Clone]
	@batchId INT
	,@newDescription VARCHAR(50) 
AS

BEGIN TRANSACTION

DECLARE @oldBatchId INT
SELECT @oldBatchId = BatchId FROM AllowanceBatchHeader abh WHERE abh.BatchId = @batchId
 
DECLARE @newBatchId INT
INSERT INTO AllowanceBatchHeader (
	StoreId
	,Description
	,SupplierId
	,AllowanceStartDate
	,AllowanceEndDate
	,HostCreated
	,HostKey
)
SELECT
	abh.StoreId
	,@newDescription
	,abh.SupplierId
	,dbo.fn_DateTimeToDateOnly(GETDATE())
	,dbo.fn_DateTimeToDateOnly(GETDATE())
	,0
	,NULL
FROM
	AllowanceBatchHeader abh
WHERE
	abh.BatchId = @oldBatchId

SET @newBatchId = SCOPE_IDENTITY()

INSERT INTO AllowanceBatchDetail (
	UPC
	,BatchId
	,StoreId
	,AllowanceThreshold
	,AllowanceType
	,AllowanceAmount
	,AllowancePercent
	,CommonDealType
)
SELECT
	UPC
	,@newBatchId
	,StoreId
	,AllowanceThreshold
	,AllowanceType
	,AllowanceAmount
	,AllowancePercent
	,CommonDealType
FROM
	AllowanceBatchDetail
WHERE
	BatchId = @oldBatchId
	
COMMIT TRANSACTION
SELECT @newBatchId

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE  PROCEDURE [dbo].[AllowanceBatch_SelectDetailByUpcStartDate]
	@upc CHAR(13)
	,@startDate DATETIME
AS

SELECT 
	abd.UPC
   ,abd.BatchId
   ,abd.AllowanceAmount
   ,abh.AllowanceStartDate
   ,abh.AllowanceEndDate
   ,abh.Description
FROM 
	allowancebatchdetail abd WITH (NOLOCK)
INNER JOIN allowancebatchheader abh WITH (NOLOCK) ON
	abh.batchid = abd.batchid
WHERE 
	abd.UPC = @upc
	AND abh.AllowanceStartDate <= @startDate
	AND abh.AllowanceEndDate >= @startDate

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AllowanceBatch_SelectDetailByUpcStartDateIntoFuture]
	@upc CHAR(13)
	,@startDate DATETIME
AS

SELECT 
	abd.UPC
   ,abd.BatchId
   ,abd.AllowanceAmount
   ,abh.AllowanceStartDate
   ,abh.AllowanceEndDate
   ,abh.Description
FROM 
	allowancebatchdetail abd WITH (NOLOCK)
INNER JOIN allowancebatchheader abh WITH (NOLOCK) ON
	abh.batchid = abd.batchid
WHERE 
	abd.UPC = @upc
	AND abh.AllowanceStartDate >= @startDate

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[Brand_Insert]
	@newBrandName VARCHAR(30)
	,@newBrandId INT OUTPUT
AS

IF EXISTS (SELECT 1 FROM Brand WHERE BrandName = @newBrandName) BEGIN
	SELECT @newBrandId = brandid FROM Brand WHERE BrandName = @newBrandName
END ELSE BEGIN
	INSERT INTO Brand (BrandName) VALUES (@newBrandName)
	SELECT @newBrandId = @@IDENTITY
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[CostBatch_Clone]
	@batchId INT
	,@newDescription VARCHAR(50) 
AS

BEGIN TRANSACTION

DECLARE @oldBatchId INT
SELECT @oldBatchId = BatchId FROM CostBatchHeader cbh WHERE cbh.BatchId = @batchId
 
DECLARE @newBatchId INT
INSERT INTO CostBatchHeader (
	StoreId
	,SupplierId
	,Description
	,StartDate
)
SELECT
	cbh.StoreId
	,cbh.SupplierId
	,@newDescription
	,dbo.fn_DateTimeToDateOnly(GETDATE())
FROM
	CostBatchHeader cbh
WHERE
	cbh.BatchId = @oldBatchId

SET @newBatchId = SCOPE_IDENTITY()

INSERT INTO CostBatchDetail (
	UPC
	,BatchId
	,StoreId
	,SKU
	,Cost
	,IsPrimary
	,CaseUPC
	,PackSize
	,ContainerUPC
	,HasProcessed
)
SELECT
	UPC
	,@newBatchId
	,StoreId
	,SKU
	,Cost
	,IsPrimary
	,CaseUPC
	,PackSize
	,ContainerUPC
	,0
FROM
	CostBatchDetail
WHERE
	BatchId = @oldBatchId
	
COMMIT TRANSACTION
SELECT @newBatchId

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[InventoryBatch_GetDetailForReport] (
		@batchId int,
		@storeId int
)

AS

SELECT
	bi.BatchId,
	bi.StoreId,
	p.DepartmentId AS DepartmentId,
	RTRIM(LTRIM(p.DepartmentName)) AS DepartmentName,
	bi.Upc,
	RTRIM(LTRIM(p.BrandName)) AS BrandName,
	RTRIM(LTRIM(p.BrandItemDescription)) AS BrandItemDescription,
	p.ProductSize AS ProductSize,
	p.ProductUOM AS ProductUom,
	CONVERT(NUMERIC(18,3), ISNULL(bi.Qty, 0)) as Qty,
	
	RegPriceAmt,
	RegPriceMult,
	CASE WHEN RegPriceMult > 1 
		THEN CONVERT(NUMERIC(18,3), RegPriceAmt / RegPriceMult) 
		ELSE CONVERT(NUMERIC(18,3), RegPriceAmt) 
	END AS RegularUnitPrice,
	
	CASE WHEN RegPriceMult > 1 
		THEN CONVERT(NUMERIC(18,3), RegPriceAmt / RegPriceMult * Qty) 
		ELSE CONVERT(NUMERIC(18,3), RegPriceAmt * Qty) 
	END AS RegularUnitPriceExt,
	
	SalePriceAmt,
	SalePriceMult,	
	CASE WHEN SalePriceMult > 1
		THEN CONVERT(NUMERIC(18,3), SalePriceAmt / SalePriceMult)
		ELSE CONVERT(NUMERIC(18,3), SalePriceAmt) 
	END AS PromotedUnitPrice,
	CASE WHEN SalePriceMult > 1
		THEN CONVERT(NUMERIC(18,3), SalePriceAmt / SalePriceMult * Qty) 
		ELSE CONVERT(NUMERIC(18,3), SalePriceAmt * Qty) 
	END AS PromotedUnitPriceExt,
	
	CONVERT(NUMERIC(18,3), RegUnitCost) AS RegularUnitCost,
	CONVERT(NUMERIC(18,3), RegUnitCost * Qty) AS RegularUnitCostExt,
	
	CONVERT(NUMERIC(18,3), SaleUnitCost) AS PromotedUnitCost,
	CONVERT(NUMERIC(18,3), SaleUnitCost * Qty) AS PromotedUnitCostExt
	
FROM
	BatchItem bi
INNER JOIN Batch b ON
	b.batchid = bi.batchid
	AND b.storeid = bi.storeid
LEFT OUTER JOIN item_view p ON
	p.upc = bi.upc
WHERE
	bi.BatchId = @batchId
	AND bi.StoreId = @storeId

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
ItemMaint_LoadByList '0001121300740,0000000004011'
*/
CREATE PROCEDURE [dbo].[ItemMaint_LoadByList]
	@listOfUpcs VARCHAR(8000) ,
	@delimiter VARCHAR(20) = ','
AS

CREATE TABLE #tempUpc (
	position INT IDENTITY
	,upc CHAR(13)
)

DECLARE @index int
SET @index = -1
 
WHILE (LEN(@listOfUpcs) > 0)
  BEGIN 
    SET @index = CHARINDEX(@delimiter , @listOfUpcs) 

    IF (@index = 0) AND (LEN(@listOfUpcs) > 0) BEGIN  
        INSERT INTO #tempUpc VALUES (@listOfUpcs)
          BREAK 
    END 

    IF (@index > 1) BEGIN  
        INSERT INTO #tempUpc VALUES (LEFT(@listOfUpcs, @index - 1))  
        SET @listOfUpcs = RIGHT(@listOfUpcs, (LEN(@listOfUpcs) - @index)) 
    END ELSE BEGIN
		SET @listOfUpcs = RIGHT(@listOfUpcs, (LEN(@listOfUpcs) - @index))
    END
END

SELECT 
	iv.*
FROM
	item_view iv
INNER JOIN #tempUpc t ON
	t.upc = iv.upc 
WHERE 
	iv.producttype NOT IN ('6', '7')

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ItemMaint_LoadByProductCategory]
    @level INT
    ,@startValue INT
	,@endValue INT = 0
AS

IF @level = 50 BEGIN
    SELECT
        iv.*
    FROM
        product p
    INNER JOIN item_view AS iv ON
        iv.upc = p.upc
    INNER JOIN categoryclass_view AS cv ON
        cv.cc5_id = p.SectionId
    WHERE
        cv.cc5_type = @level
        AND cv.cc5_id = @startValue
END

IF @level = 40 BEGIN
    SELECT
        iv.*
    FROM
        product p
    INNER JOIN item_view AS iv ON
        iv.upc = p.upc
    INNER JOIN categoryclass_view AS cv ON
        cv.cc5_id = p.SectionId
    WHERE
        cv.cc4_type = @level
        AND cv.cc4_id = @startValue
END

IF @level = 30 BEGIN
    SELECT
        iv.*
    FROM
        product p
    INNER JOIN item_view AS iv ON
        iv.upc = p.upc
    INNER JOIN categoryclass_view AS cv ON
        cv.cc5_id = p.SectionId
    WHERE
        cv.cc3_type = @level
        AND cv.cc3_id = @startValue
END

IF @level = 20 BEGIN
    SELECT
        iv.*
    FROM
        product p
    INNER JOIN item_view AS iv ON
        iv.upc = p.upc
    INNER JOIN categoryclass_view AS cv ON
        cv.cc5_id = p.SectionId
    WHERE
        cv.cc2_type = @level
        AND cv.cc2_id = @startValue
		AND cv.cc2_end_id = @endValue
END

IF @level = 10 BEGIN
    SELECT
        iv.*
    FROM
        product p
    INNER JOIN item_view AS iv ON
        iv.upc = p.upc
    INNER JOIN categoryclass_view AS cv ON
        cv.cc5_id = p.SectionId
    WHERE
        cv.cc1_type = @level
        AND cv.cc1_id = @startValue
		and cv.cc1_end_id = @endValue
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ItemMaint_LoadByProductGroup]
	@tagId INT
AS


SELECT 
	iv.*
FROM
	item_view iv
INNER JOIN ProductTag pt ON
	pt.upc = iv.upc 
	AND pt.TagId = @tagId
WHERE 
	iv.producttype NOT IN ('6', '7')

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[ItemMaint_SelectAllowAndCostBatchByUpcSupplierId]
	@upc CHAR(13)
	,@supplierId VARCHAR(15)
AS

SELECT
	abh.*
	,abd.*
FROM
	allowancebatchheader abh
INNER JOIN allowancebatchdetail abd ON
	abd.batchid = abh.batchid
WHERE
	abd.upc= @upc
	AND abh.supplierid = @supplierId
ORDER BY
	abh.allowancestartdate DESC
	,abh.allowanceenddate DESC

SELECT
	cbh.*
	,cbd.*
FROM
	costbatchheader cbh
INNER JOIN costbatchdetail cbd ON
	cbd.batchid = cbh.batchid
WHERE
	cbd.upc= @upc
	AND cbh.supplierid = @supplierId
ORDER BY
	cbh.startdate DESC

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[LabelBatch_PopulateByBatchIdStoreId] 
	@labelBatchId INT
	,@storeId INT
	,@batchId INT = NULL
	,@skuLength INT = 13
AS

UPDATE lbd SET
	lbd.BrandName = p.BrandName
	,lbd.ItemDescr = p.ItemDescr
	,lbd.Size = p.Size
	,lbd.UomCd = p.UomCd
	,lbd.NormalPriceAmt = ppn.PriceAmt
	,lbd.NormalPriceMult = ppn.PriceMult
	,lbd.NormalFormattedPrice = CASE 
		WHEN ppn.PriceMult > 1 THEN CONVERT(VARCHAR, ppn.PriceMult) + '/' + 
			CASE
				WHEN ppn.PriceAmt < 1.00 THEN RIGHT(CONVERT(VARCHAR, CAST(ppn.PriceAmt AS MONEY)), 2) + CHAR(162)
				ELSE '$' + CASE
								WHEN CAST(CAST(ppn.PriceAmt AS INT) AS MONEY)  = ppn.PriceAmt THEN CONVERT(VARCHAR, CAST(ppn.PriceAmt AS INT))
								ELSE CONVERT(VARCHAR, ppn.PriceAmt)
							END
			END
		ELSE 
			CASE
				WHEN ppn.PriceAmt < 1.00 THEN RIGHT(CONVERT(VARCHAR, CAST(ppn.PriceAmt AS MONEY)), 2) + CHAR(162)
				ELSE '$' + CASE
								WHEN CAST(CAST(ppn.PriceAmt AS INT) AS MONEY)  = ppn.PriceAmt THEN CONVERT(VARCHAR, CAST(ppn.PriceAmt AS INT))
								ELSE CONVERT(VARCHAR, ppn.PriceAmt)
							END
			END
	END		
	,lbd.NormalPerUnitPrice = CASE
		WHEN p.Size = 0 THEN 0
		ELSE ppn.PriceAmt / CASE WHEN ppn.PriceMult < 1 THEN 1 ELSE ppn.PriceMult END / sp.CasePack
	END
	,lbd.SupplierId = sp.SupplierId
	,lbd.OrderCode = RIGHT(sp.OrderCode, @skuLength)
	,lbd.CasePack = sp.CasePack
	,lbd.IsDsd = s.IsDsd
	,lbd.IsDiscontinued = CASE
		WHEN p.ProductStatusCd IN ('3','4') THEN 1
		ELSE 0
	END
	,lbd.SoldAs = psign.SoldAs
	,lbd.DisplayBrand = psign.DisplayBrand
	,lbd.DisplayDescription = psign.DisplayDescription
	,lbd.DisplayComment1 = psign.DisplayComment1
	,lbd.DisplayComment2 = psign.DisplayComment2
	,lbd.DisplayComment3 = psign.DisplayComment3
	,lbd.ItemAttribute1 = psign.ItemAttribute1
	,lbd.ItemAttribute2 = psign.ItemAttribute2
	,lbd.ItemAttribute3 = psign.ItemAttribute3
	,lbd.ItemAttribute4 = psign.ItemAttribute4
	,lbd.ItemAttribute5 = psign.ItemAttribute5
	,lbd.ItemAttribute6 = psign.ItemAttribute6
	,lbd.ItemAttribute7 = psign.ItemAttribute7
	,lbd.ItemAttribute8 = psign.ItemAttribute8
	,lbd.ItemAttribute9 = psign.ItemAttribute9
	,lbd.ItemAttribute10 = psign.ItemAttribute10
	,lbd.GroupSizeRange = psign.GroupSizeRange
	,lbd.GroupBrandName = psign.GroupBrandName
	,lbd.GroupItemDescription = psign.GroupItemDescription
	,lbd.GroupPrintQty = psign.GroupPrintQty
	,lbd.LblSizeCd = CASE
		WHEN ISNULL(ps.LblSizeCd, '') = '' THEN 'S'
		ELSE ps.LblSizeCd
	END
	,lbd.ProductStatusCd = p.ProductStatusCd
	,lbd.ProductStatusDescr = pstatus.ProductStatusDescr
	,lbd.IsWic = regIss45.WIC_FG
	,lbd.GroupComment = psign.GroupComment
	,lbd.SizeAndUomCd = CASE
		WHEN CAST(CAST(p.Size AS INT) AS SMALLMONEY) = p.Size THEN CONVERT(VARCHAR, CAST(p.Size AS INT)) + ' ' + p.UomCd
		ELSE CONVERT(VARCHAR, CAST(p.Size AS NUMERIC(9,2))) + ' ' + p.UomCd
	END
	,lbd.SupplierName = s.SupplierName
	,lbd.IsDepositLink = CASE
		WHEN ISNULL(reg.ItemLinkToDeposit, 0) = 1 THEN 1
		ELSE 0
	END
	,lbd.SectionId = p.SectionId
	,lbd.DepartmentId = p.DepartmentId
	,lbd.Iss45ComparativeUomCd = uom_CMPRTV.UomCd
	,lbd.Iss45ComparativePrice = dbo.fn_Iss45ComparativePrice(ppn.PriceAmt, ppn.PriceMult, p.Size, uom.UomDescr, regiss45.CMPRTV_UOM, regIss45.UNIT_FACTOR) 
	,lbd.Iss45ComparativeUomDescr = CASE 
		WHEN regIss45.UNIT_FACTOR > 1 THEN CAST(regiss45.UNIT_FACTOR AS VARCHAR) + ' ' + dbo.fn_Iss45UomToDescr(regIss45.CMPRTV_UOM)
		ELSE dbo.fn_Iss45UomToDescr(regIss45.CMPRTV_UOM)
	END
	,lbd.UomDescr = uom.UomDescr
FROM
	LblBatchDetail lbd
INNER JOIN Prod p ON
	p.Upc = lbd.Upc
INNER JOIN Uom ON
	uom.UomCd = p.UomCd
INNER JOIN ProductStatus pstatus ON
	pstatus.ProductStatusCd = p.ProductStatusCd
LEFT OUTER JOIN ProdPrice ppn ON
	ppn.UPC = lbd.Upc	
	AND ppn.StoreId = @storeId
	AND ppn.PriceType = 'N'
LEFT OUTER JOIN ProdStore ps ON
	ps.upc = lbd.Upc
	AND ps.StoreId = @storeId
LEFT OUTER JOIN ProdPosIbmSa reg ON
	reg.upc = lbd.Upc
	AND reg.StoreId = @storeId
LEFT OUTER JOIN SupplierProd sp ON
	sp.UPC = lbd.Upc
	AND sp.SupplierId = ps.PriSupplierId
LEFT OUTER JOIN Supplier s ON
	s.SupplierId = sp.SupplierId
LEFT OUTER JOIN ProdSign psign ON
	psign.Upc = lbd.Upc
LEFT OUTER JOIN ProdPosIss45 regIss45 ON
	regIss45.Upc = lbd.Upc
	AND regIss45.StoreId = @storeId
LEFT OUTER JOIN Uom uom_cmprtv ON
	uom_cmprtv.AltUomNmbr = regIss45.CMPRTV_UOM
WHERE
	lbd.LblBatchId = @labelBatchId

DECLARE @useAssignedBatchId BIT
IF @batchId = -1 BEGIN
	SET @useAssignedBatchId = 1
END

DECLARE @batchDealQty SMALLINT
DECLARE @batchSpecialPrice SMALLMONEY
DECLARE @batchDealPrice SMALLINT
DECLARE @batchFormattedPrice VARCHAR(50)
DECLARE @batchPerUnitPrice SMALLMONEY
DECLARE @startDate DATETIME
DECLARE @endDate DATETIME

DECLARE curItems CURSOR FOR SELECT Upc, BatchId FROM LblBatchDetail WHERE LblBatchId = @labelBatchId
OPEN curItems
DECLARE @upc CHAR(13)
DECLARE @assignedBatchId INT
FETCH NEXT FROM curItems INTO @upc, @assignedBatchId
WHILE @@FETCH_STATUS = 0 BEGIN

	DECLARE @tempUpc CHAR(11) 
	SET @tempUpc = RIGHT('00000000000' + @upc, 11)

	UPDATE LblBatchDetail SET
		FormattedUpc = 
			SUBSTRING(@tempUpc, 1, 1) + '-' + 
			SUBSTRING(@tempUpc, 2, 5) + '-' + 
			SUBSTRING(@tempUpc, 7, 5) 
	WHERE
		LblBatchId = @labelBatchId
		AND Upc = @upc

	IF @useAssignedBatchId = 1 BEGIN
		SET @batchId = @assignedBatchId
	END
	
	IF @batchId IS NOT NULL BEGIN
	
		SELECT
			@batchSpecialPrice = pbd.BatchSpecialPrice
			,@batchDealQty = pbd.BatchDealQty
			,@batchDealPrice = pbd.BatchDealPrice
			,@startDate = pbh.StartDate
			,@endDate = pbh.EndDate
		FROM
			ProductBatchDetail pbd
		INNER JOIN ProductBatchHeader AS pbh ON
			pbh.BatchId = @batchId
		WHERE
			pbd.BatchId = @batchId
			AND pbd.Upc = @upc

		IF @batchSpecialPrice IS NOT NULL AND @batchSpecialPrice <> 0.00 BEGIN
			SELECT @batchFormattedPrice = CASE
				WHEN @batchDealQty > 1 THEN CONVERT(VARCHAR, @batchDealQty) + '/' + 
					CASE
						WHEN @batchSpecialPrice < 1.00 THEN RIGHT(CONVERT(VARCHAR, CAST(@batchSpecialPrice AS SMALLMONEY)), 2) + CHAR(162)
						ELSE '$' + CASE
										WHEN CAST(CAST(@batchSpecialPrice AS INT) AS SMALLMONEY)  = @batchSpecialPrice THEN CONVERT(VARCHAR, CAST(@batchSpecialPrice AS INT))
										ELSE CONVERT(VARCHAR, @batchSpecialPrice)
									END
					END
				ELSE 
					CASE
						WHEN @batchSpecialPrice < 1.00 THEN RIGHT(CONVERT(VARCHAR, CAST(@batchSpecialPrice AS SMALLMONEY)), 2) + CHAR(162)
						ELSE '$' + CASE
										WHEN CAST(CAST(@batchSpecialPrice AS INT) AS SMALLMONEY)  = @batchSpecialPrice THEN CONVERT(VARCHAR, CAST(@batchSpecialPrice AS INT))
										ELSE CONVERT(VARCHAR, @batchSpecialPrice)
									END
					END
			END
	
			SELECT @batchPerUnitPrice = CASE
				WHEN p.Size = 0 THEN 0
				WHEN @batchDealQty = 0 THEN 0
				ELSE @batchSpecialPrice / @batchDealQty / p.Size END
			FROM 
				Prod p 
			WHERE
				p.Upc = @upc
	
			UPDATE lbd SET
				NormalPriceAmt = @batchSpecialPrice
				,NormalPriceMult = @batchDealQty
				,NormalFormattedPrice = @batchFormattedPrice
				,NormalPerUnitPrice = @batchPerUnitPrice
				,BatchDealQty = @batchDealQty
				,BatchSpecialPrice = @batchSpecialPrice
				,BatchDealPrice = @batchDealPrice
				,PromotedStartDate = @startDate
				,PromotedEndDate = @endDate
				,BatchId = @batchId

				,SupplierName = sv.SupplierName
				,SupplierId = sp.SupplierId
				,OrderCode = RIGHT(sp.OrderCode, @skuLength)
				,CasePack = sp.CasePack
				,IsDsd = sv.IsDsd
				,LblSizeCd = CASE
					WHEN ISNULL(ps.LblSizeCd, '') = '' THEN 'S'
					ELSE ps.LblSizeCd
				END
				,Iss45ComparativeUomCd = uom.UomCd
				,Iss45ComparativePrice = dbo.fn_Iss45ComparativePrice(@batchSpecialPrice, @batchDealQty, p.Size,  uom.UomDescr, regiss45.CMPRTV_UOM, regIss45.UNIT_FACTOR) 
				,lbd.Iss45ComparativeUomDescr = CASE 
					WHEN regIss45.UNIT_FACTOR > 1 THEN CAST(regiss45.UNIT_FACTOR AS VARCHAR) + ' ' + dbo.fn_Iss45UomToDescr(regIss45.CMPRTV_UOM)
					ELSE dbo.fn_Iss45UomToDescr(regIss45.CMPRTV_UOM)
				END
			FROM
				LblBatchDetail lbd
			INNER JOIN Prod p ON
				p.Upc = lbd.Upc
			INNER JOIN Uom ON
				uom.UomCd = p.UomCd
			LEFT OUTER JOIN ProdStore ps ON
				ps.Upc = lbd.Upc
				AND ps.StoreId = @storeId
			LEFT OUTER JOIN SupplierProd sp ON
				sp.Upc = lbd.Upc
				AND sp.SupplierId = ps.PriSupplierId
			LEFT OUTER JOIN supplier_view sv ON
				sv.SupplierId = sp.SupplierId
			LEFT OUTER JOIN ProdSign psign ON
				psign.Upc = lbd.Upc
			LEFT OUTER JOIN ProdPosIss45 regIss45 ON
				regIss45.Upc = lbd.Upc
				AND regIss45.StoreId = @storeId
			LEFT OUTER JOIN Uom u ON
				u.AltUomNmbr = regiss45.CMPRTV_UOM
			WHERE
				lbd.LblBatchId = @labelBatchId
				AND lbd.upc = @upc
				
			UPDATE ProductBatchDetail SET LabelBatchId = @labelBatchId 
				WHERE BatchId = @batchId AND Upc = @upc
		END
	END

	FETCH NEXT FROM curItems INTO @upc, @assignedBatchId
END
CLOSE curItems
DEALLOCATE curItems

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PriceBatch_CalcPriceByUpc]
	@upc CHAR(13)
	,@storeId INT
	,@batchId INT
	,@promoted_formatted_price VARCHAR(50) = NULL OUTPUT
	,@promoted_save_amount_text VARCHAR(50) = NULL OUTPUT
	,@promoted_comment VARCHAR(50)  = NULL OUTPUT
	,@skipLabelAndSignFields BIT = 0
	,@outBatchStartDate DATETIME = NULL OUTPUT
	,@outBatchEndDate DATETIME = NULL OUTPUT
	,@otherBatchId INT = NULL OUTPUT
	,@noResultset INT = 0
	,@alwaysShowDecimals BIT = 0
AS

SET NOCOUNT ON

DECLARE @innerBatchId INT

IF @batchId = -1 BEGIN
	DECLARE @lowPrice SMALLMONEY
	DECLARE @receivingPrice SMALLMONEY
	DECLARE @lowPriceBatchId INT
	DECLARE @lowPriceBatchEndDate DATETIME
	EXEC Product_FindLowestPriceByUpcIss45 @upc, @storeId, 1, @lowPrice OUTPUT, @receivingPrice OUTPUT, @lowPriceBatchId OUTPUT
	SET @innerBatchId = ISNULL(@lowPriceBatchId, @batchId)
END ELSE BEGIN
 	SET @innerBatchId = @batchId
END
SET @otherBatchId = @innerBatchId

CREATE TABLE #price (
	reg_price_method CHAR(1),
	reg_price SMALLMONEY,
	reg_dealqty SMALLINT,
	reg_unit_price SMALLMONEY,
	batchid INT,
	batch_price_method CHAR(1),
	batch_price SMALLMONEY,
	batch_multiple SMALLINT,
	batch_promo_code SMALLINT,
	batch_deal_price SMALLMONEY,
	batch_multi_price_group TINYINT,
	coupon_upc CHAR(13),
	coupon_type CHAR(1),
	coupon_price SMALLMONEY,
	coupon_deal_qty SMALLINT,
	advertized BIT,
	limit INT,
	price SMALLMONEY,
	coupon_reduction_amount SMALLMONEY,
	scan_price SMALLMONEY,
	handled INT,
	promoted_formatted_price VARCHAR(50),
	promoted_save_amount_text VARCHAR(50),
	promoted_comment VARCHAR(50)
)


SET NOCOUNT ON

-- regular retail
INSERT INTO #price SELECT 
	ppn.IbmSaPriceMethod,
	ppn.PriceAmt, 
	CASE WHEN ppn.PriceMult = 0 THEN 1 ELSE ppn.PriceMult END,
	ppn.PriceAmt / CASE WHEN ppn.PriceMult = 0 THEN 1 ELSE ppn.PriceMult END ,
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
FROM 
	ProdPrice ppn WITH (NOLOCK)
WHERE 
	PriceType = 'N' 
	AND Upc = @upc 
	AND StoreId = @storeId 

-- price from 1 batch
INSERT INTO #price SELECT
	ppn.IbmSaPriceMethod,
	ppn.PriceAmt,
	CASE WHEN ppn.PriceMult = 0 THEN 1 ELSE ppn.PriceMult END,
	ppn.PriceAmt / CASE WHEN ppn.PriceMult = 0 THEN 1 ELSE ppn.PriceMult END,
	pbd.BatchId,
	pbd.BatchPriceMethod,
	pbd.BatchSpecialPrice,
	CASE 
		WHEN ISNULL(pbd.BatchDealQty, 0) = 0 THEN 1
		ELSE pbd.BatchDealQty
	END,
	ISNULL(pbd.PromoCode, 0),
	pbd.BatchDealPrice,
	ISNULL(pbd.BatchMultiPriceGroup, 0),
	coup_ppn.Upc,
	coup_ppn.IbmSaPriceMethod,
	coup_ppn.PriceAmt,
	coup_ppn.PriceMult,
	coup_reg.Advertized, /* this means Points Only Coupon !!! */
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
FROM
	ProductBatchDetail pbd WITH (NOLOCK)
INNER JOIN ProdPrice ppn WITH (NOLOCK) ON
	ppn.Upc = pbd.upc
	AND ppn.PriceType = 'N'
	AND ppn.StoreId = @storeId
LEFT OUTER JOIN ProdPrice coup_ppn WITH (NOLOCK) ON
	coup_ppn.Upc = pbd.couponupc
	AND coup_ppn.PriceType='N'
	AND coup_ppn.StoreId = @storeId
LEFT OUTER JOIN ProdPosIbmSa coup_reg WITH (NOLOCK) ON
	coup_reg.Upc = pbd.CouponUPC
	AND coup_reg.StoreId = @storeId
INNER JOIN ProductBatchHeader pbh WITH (NOLOCK) ON
	pbh.BatchId = pbd.BatchId
WHERE
	pbd.Upc = @upc
	AND pbd.BatchID = @innerBatchId

-- just need to fill this out for the regular retail row
UPDATE #price SET price = reg_price / reg_dealqty WHERE batchid IS NULL
UPDATE #price SET coupon_reduction_amount = 0 WHERE batchid IS NULL 
UPDATE #price SET handled=0 WHERE batchid IS NULL

-- replace zero batch retail with lowest batch price 
SELECT TOP 1 * INTO #lowestBatchPrice FROM #price WHERE batchid IS NOT NULL AND batch_price > 0 ORDER BY batch_price/batch_multiple
IF EXISTS(SELECT * FROM #lowestBatchPrice) BEGIN

	UPDATE #price SET 
		batch_price = (SELECT batch_price FROM #lowestBatchPrice),
		batch_multiple = (SELECT batch_multiple FROM #lowestBatchPrice),
		batch_price_method = (SELECT batch_price_method FROM #lowestBatchPrice)
	WHERE 
		batchid IS NOT NULL 
		AND batch_price = 0

END

-- if there are still zero batch prices, replace zero batch price with regular retail
UPDATE #price SET 
	batch_price = reg_price,
	batch_multiple = reg_dealqty,
	batch_price_method = reg_price_method
WHERE 
	batchid IS NOT NULL 
	AND batch_price = 0

UPDATE #price SET batch_multiple = reg_dealqty WHERE batchid IS NOT NULL AND batch_multiple = 0

-- extend batch_price, batch_multiple
UPDATE #price SET price = batch_price / batch_multiple WHERE batchid IS NOT NULL AND batch_price_method IN ('A', 'B', 'C')
UPDATE #price SET price = batch_deal_price WHERE batchid IS NOT NULL AND batch_price_method IN ('D', 'E')

-- isolate limit for coupons where User3=0 (rightmost char OF a 2-digit integer)
UPDATE p SET 
	limit = coupon_deal_qty % 10 
FROM
	#price p 
INNER JOIN ProdPrice ppc ON
	ppc.Upc = p.coupon_upc
	AND ppc.PriceType ='N'
	AND ppc.StoreId = @storeId
INNER JOIN ProdPosIbmSa reg ON
	reg.Upc = p.coupon_upc
	AND reg.StoreID = @storeId
WHERE 
	p.coupon_deal_qty IS NOT NULL
	AND ISNULL(reg.User3, 0) = 0

-- if coupon's User3 flag is on (Big Cpn Limit), limit=entire DealQty
UPDATE p SET 
	limit = coupon_deal_qty
FROM
	#price p 
INNER JOIN ProdPrice ppc ON
	ppc.Upc = p.coupon_upc
	AND ppc.PriceType ='N'
	AND ppc.StoreId = @storeId
INNER JOIN ProdPosIbmSa reg ON
	reg.Upc = p.coupon_upc
	AND reg.StoreID = @storeId
WHERE 
	p.coupon_deal_qty IS NOT NULL
	AND ISNULL(reg.User3, 0) = 1

-- handle items in batches WITH no coupons attached
UPDATE #price SET 
	coupon_reduction_amount=0, 
	scan_price=price,
	handled = 1
	,promoted_formatted_price = 
		CASE
			WHEN batch_multiple > 1 THEN 
				CAST(batch_multiple AS VARCHAR) + '/' +
					CASE
							WHEN batch_price < 1.00 THEN RIGHT(CONVERT(VARCHAR, CAST(batch_price AS SMALLMONEY)), 2) + CHAR(162)
							ELSE '$' + CASE
											WHEN @alwaysShowDecimals = 0 AND CAST(CAST(batch_price AS INT) AS SMALLMONEY)  = batch_price THEN CONVERT(VARCHAR, CAST(batch_price AS INT))
											ELSE CONVERT(VARCHAR, batch_price)
										END

					END	
			ELSE
				CASE
					WHEN batch_price < 1.00 THEN RIGHT(CONVERT(VARCHAR, CAST(batch_price AS SMALLMONEY)), 2) + CHAR(162)
					ELSE '$' + CASE
									WHEN @alwaysShowDecimals = 0 AND CAST(CAST(batch_price AS INT) AS SMALLMONEY)  = batch_price THEN CONVERT(VARCHAR, CAST(batch_price AS INT))
									ELSE CONVERT(VARCHAR, batch_price)
								END

				END	
			END
	,promoted_save_amount_text = CASE
		WHEN (reg_price / reg_dealqty) - (batch_price / batch_multiple) < 1.00 THEN RIGHT(CONVERT(VARCHAR, CAST((reg_price / reg_dealqty) - (batch_price / batch_multiple) AS SMALLMONEY)), 2) + CHAR(162)
		ELSE '$' + CONVERT(VARCHAR, (reg_price / reg_dealqty) - (batch_price / batch_multiple))
	END
WHERE batchid IS NOT NULL AND coupon_upc IS NULL

-- calculate coupon_reduction_amount for %off promotions
UPDATE #price SET 
	coupon_reduction_amount = ((batch_price/batch_multiple) * ((coupon_price-980) * .1)), 
	handled=2 
	,promoted_formatted_price = CAST(CAST((coupon_price-980) * 10 AS INT) AS VARCHAR) + '% OFF'
WHERE coupon_type = 'E' AND coupon_price > 980.00 AND coupon_price < 990.00 AND handled IS NULL

UPDATE #price SET 
	coupon_reduction_amount = ((batch_price/batch_multiple) * ((coupon_price-990) * .1)), 
	handled=3 
	,promoted_formatted_price = CAST(CAST((coupon_price-990) * 10 AS INT) AS VARCHAR) + '% OFF'
WHERE coupon_type = 'E' AND coupon_price > 990.00 AND coupon_price < 999.01 AND handled IS NULL

-- cents OFF
UPDATE #price SET 
	coupon_reduction_amount = coupon_price / limit, 


	handled = 4
	,promoted_formatted_price = 
		CASE
			WHEN coupon_deal_qty BETWEEN 90 AND 99 THEN 
				CASE 
					WHEN price - (coupon_price / limit) < 1.00 THEN RIGHT(CONVERT(VARCHAR, CAST(price - (coupon_price / limit) AS SMALLMONEY)), 2) + CHAR(162)
					ELSE '$' + CAST(price - (coupon_price / limit) AS VARCHAR)
				END				 
			ELSE '???'
		END
	,promoted_save_amount_text = 
		CASE
			WHEN coupon_deal_qty BETWEEN 90 AND 99 THEN
				CASE
					WHEN reg_unit_price - price + (coupon_price/limit) < 1.00 THEN RIGHT(CONVERT(VARCHAR, CAST(reg_unit_price - price + (coupon_price/limit) AS SMALLMONEY)), 2) + CHAR(162)
					ELSE '$' + CASE
									WHEN CAST(CAST(reg_unit_price - price + (coupon_price/limit) AS INT) AS SMALLMONEY) = reg_unit_price - price + (coupon_price/limit) THEN CONVERT(VARCHAR, CAST(reg_unit_price - price + (coupon_price/limit) AS INT))
									ELSE CONVERT(VARCHAR, reg_unit_price - price + (coupon_price/limit))
								END

				END
			ELSE ''
		END
WHERE coupon_type = 'A' AND (advertized IS NOT NULL AND advertized = 0) AND handled IS NULL

-- cents OFF 'D' coupon
UPDATE #price SET 
	coupon_reduction_amount = coupon_price / limit, 
	handled=12
	,promoted_formatted_price = 
		CASE
			WHEN coupon_deal_qty BETWEEN 90 AND 99 THEN 
				CASE 
					WHEN price - (coupon_price / limit) < 1.00 THEN RIGHT(CONVERT(VARCHAR, CAST(price - (coupon_price / limit) AS SMALLMONEY)), 2) + CHAR(162)
					ELSE '$' + CAST(price - (coupon_price / limit) AS VARCHAR)
				END				 
			ELSE '???'
		END
	,promoted_save_amount_text = 
		CASE
			WHEN coupon_deal_qty BETWEEN 90 AND 99 THEN
				CASE
					WHEN reg_unit_price - price + (coupon_price/limit) < 1.00 THEN RIGHT(CONVERT(VARCHAR, CAST(reg_unit_price - price + (coupon_price/limit) AS SMALLMONEY)), 2) + CHAR(162)
					ELSE '$' + CASE
									WHEN CAST(CAST(reg_unit_price - price + (coupon_price/limit) AS INT) AS SMALLMONEY) = reg_unit_price - price + (coupon_price/limit) THEN CONVERT(VARCHAR, CAST(reg_unit_price - price + (coupon_price/limit) AS INT))
									ELSE CONVERT(VARCHAR, reg_unit_price - price + (coupon_price/limit))
								END

				END
			ELSE ''
		END
WHERE coupon_type = 'D' AND coupon_price > 0.01 AND (advertized IS NOT NULL AND advertized = 0) AND handled IS NULL

-- net price 
UPDATE #price SET 
	coupon_reduction_amount = price - coupon_price
	,handled = 5 
	,promoted_formatted_price = 
		CASE
			WHEN coupon_price < 1.00 THEN RIGHT(CONVERT(VARCHAR, CAST(coupon_price AS SMALLMONEY)), 2) + CHAR(162)
			ELSE '$' + CASE
							WHEN @alwaysShowDecimals = 0 AND CAST(CAST(coupon_price AS INT) AS SMALLMONEY) = coupon_price THEN CONVERT(VARCHAR, CAST(coupon_price AS INT))
							ELSE CONVERT(VARCHAR, coupon_price)
						END

		END
	,promoted_comment = 
		CASE
			WHEN CAST(coupon_deal_qty * .1 AS INT) BETWEEN 1 AND 8 THEN 'LIMIT ' + CAST(CAST(coupon_deal_qty * .1 AS INT) AS VARCHAR) + ' PLEASE'
			ELSE NULL
		END
	,promoted_save_amount_text =
		CASE
			WHEN reg_unit_price - coupon_price < 1.00 THEN RIGHT(CONVERT(VARCHAR, CAST(reg_unit_price - coupon_price AS SMALLMONEY)), 2) + CHAR(162)
			ELSE '$' + CONVERT(VARCHAR, reg_unit_price - coupon_price)
		END
WHERE coupon_type = 'E' AND coupon_price > 0 AND limit = 1 AND handled IS NULL

-- calculate the actual scanning price
UPDATE #price SET 
	scan_price = price - coupon_reduction_amount 
	,price = price - coupon_reduction_amount
WHERE handled IS NOT NULL

-- BxGy
UPDATE #price SET 
	coupon_reduction_amount = price / limit, 
	scan_price = price - (price/limit), 
	price = price - (price / limit),
	handled=6,
	promoted_formatted_price = 'BUY ' + CAST(limit-1 AS VARCHAR) + ' GET 1 FREE'
	,promoted_save_amount_text = CASE
		WHEN price < 1.00 THEN RIGHT(CONVERT(VARCHAR, CAST(price AS SMALLMONEY)), 2) + CHAR(162)
		ELSE '$' + CONVERT(VARCHAR, price)
	END
WHERE batchid IS NOT NULL AND coupon_type='E' AND coupon_price = 0 AND limit > 1 AND handled IS NULL

-- qty/price (e.g. 2/$5)
UPDATE #price SET 
	coupon_reduction_amount = price - (coupon_price/limit), 
	scan_price = coupon_price / limit, 
	price = coupon_price / limit, 
	handled = 7,
	promoted_formatted_price = CAST(limit AS VARCHAR) + '/' +
		CASE
				WHEN coupon_price < 1.00 THEN RIGHT(CONVERT(VARCHAR, CAST(coupon_price AS SMALLMONEY)), 2) + CHAR(162)
				ELSE '$' + CASE
								WHEN CAST(CAST(coupon_price AS INT) AS SMALLMONEY) = coupon_price THEN CONVERT(VARCHAR, CAST(coupon_price AS INT))
								ELSE CONVERT(VARCHAR, coupon_price)
							END
		END
	,promoted_save_amount_text = 
		CASE
			WHEN reg_unit_price - (coupon_price/limit) < 1.00 THEN RIGHT(CONVERT(VARCHAR, CAST(reg_unit_price - (coupon_price/limit) AS SMALLMONEY)), 2) + CHAR(162)
			ELSE '$' + CONVERT(VARCHAR, reg_unit_price - (coupon_price/limit))
		END
WHERE coupon_type = 'E' AND coupon_price <> 0 AND handled IS NULL

-- turkey buck
-- SET scan_price TO 0.02 TO make it beat ALL pricing schemes EXCEPT 'meal deal'
UPDATE #price SET 
	scan_price = 0.02, 
	coupon_reduction_amount = price - 0.02, 
	handled = 8 
	,promoted_formatted_price = 'BUY ' + CAST(limit AS VARCHAR) + ' GET ' + CAST(CAST(coupon_price * 100 AS INT) AS VARCHAR) + 
		CASE	
			WHEN CAST(coupon_price * 100 AS INT) > 1 THEN ' TURKEY BUCKS'
			ELSE ' TURKEY BUCK'
		END
WHERE coupon_type = 'A' AND advertized = 1 AND handled IS NULL

-- meal deal
-- SET scan_price TO 0.01 TO make it beat ALL pricing schemes including 'turkey buck'
UPDATE #price SET 
	scan_price = coupon_price / limit, 
	coupon_reduction_amount = price - (coupon_price/limit), 
	handled = 9 
WHERE coupon_type IN ('A', 'B', 'C', 'D') AND coupon_price = .01 AND handled IS NULL

-- Batch Price Method 'C': Qty Adjusted Price
UPDATE #price SET
	coupon_reduction_amount = price / batch_multiple,
	scan_price = price - (price / batch_multiple),
	handled = 10,
	promoted_formatted_price = 'BUY 1 GET 1',
	promoted_save_amount_text = CASE
		WHEN batch_price < 1.00 THEN RIGHT(CONVERT(VARCHAR, CAST(batch_price AS SMALLMONEY)), 2) + CHAR(162)
		ELSE '$' + CONVERT(VARCHAR, batch_price)
	END
WHERE batch_price_method = 'C' AND batch_price = batch_deal_price AND ISNULL(coupon_upc,'') = ''


-- PM D, Reduced $ w/ Minimum Qty
UPDATE #price SET 
	scan_price = batch_deal_price
	,handled = 10
	,promoted_formatted_price = CASE
		WHEN batch_deal_price < 1.00 THEN RIGHT(CONVERT(VARCHAR, CAST(batch_deal_price AS SMALLMONEY)), 2) + CHAR(162)
		ELSE '$' + CONVERT(VARCHAR, batch_deal_price)
	END
	,promoted_save_amount_text = CASE
		WHEN reg_unit_price - batch_deal_price < 1.00 THEN RIGHT(CONVERT(VARCHAR, CAST(reg_unit_price - batch_deal_price AS SMALLMONEY)), 2) + CHAR(162)
		ELSE '$' + CONVERT(VARCHAR, reg_unit_price - batch_deal_price)
	END
	,promoted_comment = 
		CASE
			WHEN batch_multiple BETWEEN 1 AND 99 THEN 'WITH PURCHASE OF ' + CAST(batch_multiple AS VARCHAR)
			ELSE NULL
		END
WHERE batch_price_method = 'D' AND ISNULL(coupon_upc,'') = ''

-- PM E, Reduced $ w/ Limited Qty
UPDATE #price SET 
	scan_price = batch_deal_price
	,handled = 11
	,promoted_formatted_price = CASE
		WHEN batch_deal_price < 1.00 THEN RIGHT(CONVERT(VARCHAR, CAST(batch_deal_price AS SMALLMONEY)), 2) + CHAR(162)
		ELSE '$' + CONVERT(VARCHAR, batch_deal_price)
	END
	,promoted_save_amount_text = CASE
		WHEN reg_unit_price - batch_deal_price < 1.00 THEN RIGHT(CONVERT(VARCHAR, CAST(reg_unit_price - batch_deal_price AS SMALLMONEY)), 2) + CHAR(162)
		ELSE '$' + CONVERT(VARCHAR, reg_unit_price - batch_deal_price)
	END
	,promoted_comment = 
		CASE
			WHEN batch_multiple BETWEEN 1 AND 99 THEN 'LIMIT ' + CAST(batch_multiple AS VARCHAR) + ' PLEASE'
			ELSE NULL
		END
WHERE batch_price_method = 'E' AND ISNULL(coupon_upc,'') = ''


IF @skipLabelAndSignFields = 0 BEGIN
	-- see if 'E' type coupon, is linked to a turkey-buck coupon
	-- if it is, put that information in 'promoted_comment'
	DECLARE @secondaryCouponLink AS CHAR(13)
	SELECT 
		@secondaryCouponLink = RIGHT('0000000000000' + CAST(reg.LinkCode AS VARCHAR), 13) 
	FROM
		ProdPosIbmSa reg
	WHERE
		Upc = (SELECT coupon_upc FROM #price WHERE batchid = @innerBatchId AND coupon_type = 'E')
		AND reg.LinkCode <> 0 
		AND reg.LinkCode IS NOT NULL
	
	
	IF @secondaryCouponLink IS NOT NULL BEGIN
		DECLARE @tbLimit INT
		DECLARE @tbPrice SMALLMONEY
		SELECT
			@tbLimit = PriceMult % 10
			,@tbPrice = PriceAmt
		FROM
			ProdPrice
		WHERE
			upc = @secondaryCouponLink
			AND storeid = @storeId
			AND pricetype = 'N'
	
		UPDATE 
			#price 
		SET 
			promoted_comment = 'BUY ' + CAST(@tbLimit AS VARCHAR) + ' GET ' + CAST(CAST(@tbPrice * 100 AS INT) AS VARCHAR) + 
				CASE	
					WHEN CAST(@tbPrice * 100 AS INT) > 1 THEN ' TURKEY BUCKS'
					ELSE ' TURKEY BUCK'
				END
		WHERE 
			batchid = @innerBatchId 
			AND coupon_type = 'E'
	END
	
	--never want to see a promoted save amount of zero
	UPDATE #price SET promoted_save_amount_text = NULL WHERE promoted_save_amount_text = '00?'
	
	-- use override fields for PromotedFormattedPrice/PromotedComment if 
	-- those values are enabled via ProductSign.ItemAttribute[1|2]
	DECLARE @coupUpc VARCHAR(13)
	DECLARE @attr1 BIT
	DECLARE @attr2 BIT
	DECLARE @displayComment1 VARCHAR(255)
	DECLARE @displayComment2 VARCHAR(255)
	SELECT
		@coupUpc = price.coupon_upc
		,@attr1 = ISNULL(ItemAttribute1, 0)
		,@attr2 = ISNULL(ItemAttribute2, 0)
		,@displayComment1 = ISNULL(DisplayComment1, '')
		,@displayComment2 = ISNULL(DisplayComment2, '')
	FROM
		#price price
	INNER JOIN ProdSign psign ON
		psign.upc = price.coupon_upc
	WHERE
		ISNULL(price.coupon_upc,'') <> ''
	
	IF @attr1 = 1 BEGIN
		UPDATE #price SET promoted_formatted_price = @displayComment1 WHERE coupon_upc = @coupUpc
	END
	IF @attr2 = 1 BEGIN
		UPDATE #price SET promoted_comment = @displayComment2 WHERE coupon_upc = @coupUpc
	END
	
	SELECT
		@promoted_formatted_price = promoted_formatted_price
		,@promoted_save_amount_text = promoted_save_amount_text
		,@promoted_comment = promoted_comment
	FROM
		#price
	WHERE
		batchid = @innerBatchId
	
	SELECT
		@outBatchStartDate = pbh.StartDate
		,@outBatchEndDate = pbh.EndDate
	FROM
		ProductBatchHeader pbh
	WHERE
		pbh.BatchId = @innerBatchId
END

SET NOCOUNT OFF

-- first row TO come back WHEN sorting 
-- BY 'scan_price' ascending IS lowest price
IF @noResultset = 0 BEGIN
	SELECT
		* 
	FROM 
		#price 
	WHERE
		batchid = @innerBatchId
	ORDER BY 
		scan_price
END




GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[PriceBatch_SelectUnapplied]
	@startDate DATETIME = NULL
	,@endDate DATETIME = NULL
AS

	IF @startDate IS NOT NULL AND @endDate IS NOT NULL BEGIN

		SELECT * FROM ProductBatchHeader_view WHERE  
			BatchId IN 
	            (SELECT BatchId FROM PRODUCTBATCHHEADER WITH (NOLOCK) WHERE 
	                StartDate BETWEEN CONVERT(VARCHAR, @startDate, 101) AND CONVERT(VARCHAR, @endDate, 101)
				)
			AND UnappliedItemCount > 0
			AND ReleasedTime IS NOT NULL

	END ELSE BEGIN

		-- price changes        
		SELECT * FROM ProductBatchHeader_view WHERE  
			BatchId IN 
	            (SELECT BatchId FROM PRODUCTBATCHHEADER WITH (NOLOCK) WHERE 
	                StartDate <= CONVERT(VARCHAR, GETDATE(), 101)
	                AND EndDate IS NULL)
			AND UnappliedItemCount > 0
			AND ReleasedTime IS NOT NULL

		-- ad on	
		SELECT * FROM ProductBatchHeader_view WHERE  
	        BatchId IN
	            (SELECT BatchId FROM PRODUCTBATCHHEADER WITH (NOLOCK) WHERE 
	                StartDate <= CONVERT(VARCHAR, GETDATE(), 101)
	                AND EndDate >= CONVERT(VARCHAR, GETDATE(), 101))
			AND UnappliedItemCount > 0
			AND ReleasedTime IS NOT NULL
	
		-- ad off
		;WITH adOff_cte (BatchId, NotEndedCt) AS 
		(
			SELECT 
				h.BatchId
				,(SELECT COUNT(1) FROM ProductBatchDetail d WHERE d.BatchId = h.BatchId AND d.HasEnded = 0)
			FROM 
				ProductBatchHeader h WITH (NOLOCK)
			WHERE 
				h.EndDate IS NOT NULL
				AND h.ReleasedTime IS NOT NULL
				AND h.EndDate < CONVERT(VARCHAR, GETDATE(), 101)
		)
		SELECT v.* FROM ProductBatchHeader_view v
		INNER JOIN adOff_cte c ON 
			c.BatchId = v.BatchId
			AND c.NotEndedCt > 0

	END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Product_Clone]
    @oldUpc CHAR(13)
   ,@newUpc CHAR(13)
   ,@cloneSource VARCHAR(50)
   ,@cloneUser VARCHAR(50)
   ,@markAsReviewed BIT = 0
AS 
IF EXISTS ( SELECT
                1
            FROM
                Prod
            WHERE
                upc = @newUpc ) 
    BEGIN
        DECLARE @extraInfo VARCHAR(255)
        SELECT
            @extraInfo = 'Brand: ' + p.BrandName + ' Description: ' + p.ItemDescr + ' Product Type: ' + pt.ProductTypeDescr
        FROM
            Prod p
        INNER JOIN ProductType pt
            ON pt.ProductTypeCd = p.ProductTypeCd
        WHERE
            p.upc = @newUpc
        RAISERROR('Cannot clone from [%s] into [%s] because the new upc already exists.  %s', 16, 1, @oldUpc, @newUpc, @extraInfo)
        RETURN
    END

BEGIN TRANSACTION

INSERT  INTO Prod (
	Upc
	,BrandName
	,ItemDescr
	,Size
	,UomCd
	,DepartmentId
	,SectionId
	,ProductTypeCd
	,ProductStatusCd
	,ReceiveByWeight
	,CreateDate
	,NewItemReviewDate
	,StatusModifiedDate
	,ProductAvailableDate
	,RzGrpId        
) SELECT
	@newUpc
	,p.BrandName
	,p.ItemDescr
	,p.Size
	,p.UomCd
	,p.DepartmentId
	,p.SectionId
	,p.ProductTypeCd
	,p.ProductStatusCd
	,p.ReceiveByWeight
	,GETDATE()
	,CASE
		WHEN @markAsReviewed = 1 THEN GETDATE()
		ELSE NULL
	END
	,GETDATE()
	,GETDATE()
	,p.RzGrpId        
	FROM
		Prod p
	WHERE
		p.Upc = @oldUpc

IF @@ERROR <> 0 BEGIN
	ROLLBACK TRANSACTION
	RETURN
END

-- ProdStore
INSERT INTO ProdStore (
	Upc
	,StoreId
	,PosValid
	,PriSupplierId
	,CanReceive
	,QtyOnHand
	,OrderThreshold
	,InventoryCost
	,LblSizeCd
	,LabelRequestDate
	,SignRequestDate
	,NewItemReviewDate
	,LabelRequestUser
	,SignRequestUser
	,TargetGrossMargin
	,CustomPriceCd
) SELECT
	@newUpc
	,x.StoreId
	,x.PosValid
	,x.PriSupplierId
	,x.CanReceive
	,0 -- QtyOnHand
	,OrderThreshold
	,0 -- InventoryCost
	,LblSizeCd
	,NULL -- LabelRequestDate
	,NULL -- SignRequestDate
	,NULL -- NewItemReviewDate
	,NULL -- LabelRequestUser
	,NULL -- SignRequestUser
	,x.TargetGrossMargin
	,''
FROM
	ProdStore x
WHERE
	X.Upc = @oldUpc
IF @@ERROR <> 0 BEGIN
	ROLLBACK TRANSACTION
	RETURN
END

-- ProdPrice
INSERT INTO ProdPrice (
	Upc
	,StoreId
	,PriceType
	,PriceAmt
	,PriceMult
	,IbmSaPriceMethod
	,IbmSaMpGroup
	,IbmSaDealPrice
) SELECT 
	@newUpc
	,x.StoreId
	,x.PriceType
	,x.PriceAmt
	,x.PriceMult
	,x.IbmSaPriceMethod
	,x.IbmSaMpGroup
	,x.IbmSaDealPrice
FROM
	ProdPrice x
WHERE
	x.Upc = @oldupc
IF @@ERROR <> 0 BEGIN
    ROLLBACK TRANSACTION
    RETURN
END

-- ProdPriceZone
INSERT INTO ProdPriceZone (
	Upc
	,RzGrpId
	,RzSegId
	,PriceAmt
	,PriceMult
	,IbmSaPriceMethod
	,IbmSaMpGroup
	,IbmSaDealPrice
	,Iss45MIX_MATCH_CD
) SELECT 
	@newUpc
	,x.RzGrpId
	,x.RzSegId
	,x.PriceAmt
	,x.PriceMult
	,x.IbmSaPriceMethod
	,x.IbmSaMpGroup
	,x.IbmSaDealPrice
	,x.Iss45MIX_MATCH_CD
FROM
	ProdPriceZone x
WHERE
	x.Upc = @oldupc
IF @@ERROR <> 0 BEGIN
    ROLLBACK TRANSACTION
    RETURN
END

-- ProdPosIbmSa
INSERT INTO ProdPosIbmSa (
	Upc
	,StoreId
	,PosDescription
	,Advertized
	,KeepItemMovement
	,PriceRequired
	,WeightPriceRequired
	,CouponFamilyCurrent
	,CouponFamilyPrevious
	,Discountable
	,CouponMultiple
	,ExceptLogItemSale
	,QtyAllowed
	,QtyRequired
	,AuthSale
	,RestrictSaleHours
	,TerminalItemRecord
	,AllowPrint
	,User1
	,User2
	,User3
	,User4
	,UserData1
	,UserData2
	,ApplyPoints
	,LinkCode
	,ItemLinkToDeposit
	,FoodStamp
	,TradingStamp
	,Wic
	,TaxA
	,TaxB
	,TaxC
	,TaxD
	,TaxE
	,TaxF
	,QhpQualifiedHealthcareItem
	,RxPrescriptionItem
	,WicCvv
) SELECT
	@newUpc
	,x.StoreId
	,x.PosDescription
	,x.Advertized
	,x.KeepItemMovement
	,x.PriceRequired
	,x.WeightPriceRequired
	,x.CouponFamilyCurrent
	,x.CouponFamilyPrevious
	,x.Discountable
	,x.CouponMultiple
	,x.ExceptLogItemSale
	,x.QtyAllowed
	,x.QtyRequired
	,x.AuthSale
	,x.RestrictSaleHours
	,x.TerminalItemRecord
	,x.AllowPrint
	,x.User1
	,x.User2
	,x.User3
	,x.User4
	,x.UserData1
	,x.UserData2
	,x.ApplyPoints
	,x.LinkCode
	,x.ItemLinkToDeposit
	,x.FoodStamp
	,x.TradingStamp
	,x.Wic
	,x.TaxA
	,x.TaxB
	,x.TaxC
	,x.TaxD
	,x.TaxE
	,x.TaxF
	,x.QhpQualifiedHealthcareItem
	,x.RxPrescriptionItem
	,x.WicCvv
FROM
	ProdPosIbmSa x
WHERE
	x.Upc = @oldUpc
IF @@ERROR <> 0 BEGIN
	ROLLBACK TRANSACTION
	RETURN
END
    
-- ProdPosIss45
INSERT INTO ProdPosIss45 (
	Upc
	,StoreId
	,MSG_CD
	,DSPL_DESCR
	,SLS_RESTRICT_GRP
	,RCPT_DESCR
	,NON_MDSE_ID
	,QTY_RQRD_FG
	,SLS_AUTH_FG
	,FOOD_STAMP_FG
	,WIC_FG
	,NG_ENTRY_FG
	,STR_CPN_FG
	,VEN_CPN_FG
	,MAN_PRC_FG
	,WGT_ITM_FG
	,NON_DISC_FG
	,COST_PLUS_FG
	,PRC_VRFY_FG
	,INHBT_QTY_FG
	,DCML_QTY_FG
	,TAX_RATE1_FG
	,TAX_RATE2_FG
	,TAX_RATE3_FG
	,TAX_RATE4_FG
	,TAX_RATE5_FG
	,TAX_RATE6_FG
	,TAX_RATE7_FG
	,TAX_RATE8_FG
	,MIX_MATCH_CD
	,RTN_CD
	,FAMILY_CD
	,DISC_CD
	,SCALE_FG
	,WGT_SCALE_FG
	,FREQ_SHOP_TYPE
	,FREQ_SHOP_VAL
	,SEC_FAMILY
	,POS_MSG
	,SHELF_LIFE_DAY
	,CPN_NBR
	,TAR_WGT_NBR
	,CMPRTV_UOM
	,CMPR_QTY
	,CMPR_UNT
	,BNS_CPN_FG
	,EXCLUD_MIN_PURCH_FG
	,FUEL_FG
	,SPR_AUTH_RQRD_FG
	,SSP_PRDCT_FG
	,FREQ_SHOP_LMT
	,DEA_GRP
	,BNS_BY_DESCR
	,COMP_TYPE
	,COMP_PRC
	,COMP_QTY
	,ASSUME_QTY_FG
	,ITM_POINT
	,PRC_GRP_ID
	,SWW_CODE_FG
	,SHELF_STOCK_FG
	,PRNT_PLU_ID_RCPT_FG
	,BLK_GRP
	,EXCHANGE_TENDER_ID
	,CAR_WASH_FG
	,PACKAGE_UOM
	,UNIT_FACTOR
	,FS_QTY
	,NON_RX_HEALTH_FG
	,RX_FG
	,EXEMPT_FROM_PROM_FG
	,WIC_CVV_FG
	,LNK_NBR
	,SNAP_HIP_FG
) SELECT 
	@newUpc
	,x.StoreId
	,x.MSG_CD
	,x.DSPL_DESCR
	,x.SLS_RESTRICT_GRP
	,x.RCPT_DESCR
	,x.NON_MDSE_ID
	,x.QTY_RQRD_FG
	,x.SLS_AUTH_FG
	,x.FOOD_STAMP_FG
	,x.WIC_FG
	,x.NG_ENTRY_FG
	,x.STR_CPN_FG
	,x.VEN_CPN_FG
	,x.MAN_PRC_FG
	,x.WGT_ITM_FG
	,x.NON_DISC_FG
	,x.COST_PLUS_FG
	,x.PRC_VRFY_FG
	,x.INHBT_QTY_FG
	,x.DCML_QTY_FG
	,x.TAX_RATE1_FG
	,x.TAX_RATE2_FG
	,x.TAX_RATE3_FG
	,x.TAX_RATE4_FG
	,x.TAX_RATE5_FG
	,x.TAX_RATE6_FG
	,x.TAX_RATE7_FG
	,x.TAX_RATE8_FG
	,x.MIX_MATCH_CD
	,x.RTN_CD
	,x.FAMILY_CD
	,x.DISC_CD
	,x.SCALE_FG
	,x.WGT_SCALE_FG
	,x.FREQ_SHOP_TYPE
	,x.FREQ_SHOP_VAL
	,x.SEC_FAMILY
	,x.POS_MSG
	,x.SHELF_LIFE_DAY
	,x.CPN_NBR
	,x.TAR_WGT_NBR
	,x.CMPRTV_UOM
	,x.CMPR_QTY
	,x.CMPR_UNT
	,x.BNS_CPN_FG
	,x.EXCLUD_MIN_PURCH_FG
	,x.FUEL_FG
	,x.SPR_AUTH_RQRD_FG
	,x.SSP_PRDCT_FG
	,x.FREQ_SHOP_LMT
	,x.DEA_GRP
	,x.BNS_BY_DESCR
	,x.COMP_TYPE
	,x.COMP_PRC
	,x.COMP_QTY
	,x.ASSUME_QTY_FG
	,x.ITM_POINT
	,x.PRC_GRP_ID
	,x.SWW_CODE_FG
	,x.SHELF_STOCK_FG
	,x.PRNT_PLU_ID_RCPT_FG
	,x.BLK_GRP
	,x.EXCHANGE_TENDER_ID
	,x.CAR_WASH_FG
	,x.PACKAGE_UOM
	,x.UNIT_FACTOR
	,x.FS_QTY
	,x.NON_RX_HEALTH_FG
	,x.RX_FG
	,x.EXEMPT_FROM_PROM_FG
	,x.WIC_CVV_FG
	,x.LNK_NBR
	,x.SNAP_HIP_FG
FROM 
	ProdPosIss45 x
WHERE
	x.Upc = @oldUpc
IF @@ERROR <> 0 BEGIN
	ROLLBACK TRANSACTION
	RETURN
END

-- ProdGroupDetail
INSERT INTO ProdGroupDetail (
    GroupId, 
    Upc
) SELECT 
	x.GroupId
	,@newUpc
FROM
	ProdGroupDetail x
WHERE
	x.Upc = @oldUpc
IF @@ERROR <> 0 BEGIN
	ROLLBACK TRANSACTION
	RETURN
END

-- SupplierProd
INSERT INTO SupplierProd (
	SupplierId
	,Upc
	,CasePack
	,CaseUpc
	,OrderCode
	,CaseWeight
	,ShipTypeCd
) SELECT
	x.SupplierId
	,@newupc
	,x.CasePack
	,x.CaseUpc
	,x.OrderCode
	,x.CaseWeight
	,x.ShipTypeCd
FROM
    SupplierProd x
INNER JOIN Supplier AS s ON 
	s.SupplierId = x.SupplierId
WHERE
	x.Upc = @oldUpc
IF @@ERROR <> 0 BEGIN
	ROLLBACK TRANSACTION
	RETURN
END

-- SupplierProd
INSERT INTO SupplierProdZone (
	SupplierId
	,Upc
	,SupplierZoneId
	,CaseCost
	,UnitCost
	,DepositCharge
	,DepositDepartmentId
	,SplitCharge
	,SuggPriceAmt
	,SuggPriceMult
) SELECT
	x.SupplierId
	,@newUpc
	,SupplierZoneId
	,CaseCost
	,UnitCost
	,DepositCharge
	,DepositDepartmentId
	,SplitCharge
	,SuggPriceAmt
	,SuggPriceMult
FROM
    SupplierProdZone x
INNER JOIN Supplier AS s ON 
	s.SupplierId = x.SupplierId
WHERE
	x.Upc = @oldUpc
IF @@ERROR <> 0 BEGIN
	ROLLBACK TRANSACTION
	RETURN
END


-- if the cloned item doesn't have a DSD supplier attached, create a record of the 'default_cloning_supplierid'
IF NOT EXISTS (SELECT 1 FROM SupplierProd AS sp WHERE Upc = @newUpc) BEGIN
	DECLARE @defCloningSupplierId VARCHAR(15)
	SELECT @defCloningSupplierId = ISNULL(sso.OptionValue,'') FROM CtsSystemOption AS sso WHERE sso.OptionName = 'default_cloning_supplierid'

	IF @defCloningSupplierId != '' BEGIN
		INSERT INTO SupplierProd (
			SupplierId
			,Upc
			,CasePack
			,CaseUpc
			,OrderCode
			,CaseWeight
			,ShipTypeCd
        ) VALUES (
	         @defCloningSupplierId
	         ,@newUpc
	         ,1		-- CasePack
	         ,''	-- CaseUPc
	         ,''	-- OrderCode
	         ,0		-- CaseWeight
	         ,''	-- ShipTypeCd
        )

	END
END

COMMIT TRANSACTION
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE                PROCEDURE [dbo].[Product_FindLowestPriceByUpc]
	@upc CHAR(13)
	,@storeId INT
	,@noResultset BIT = 0
	,@outLowPrice SMALLMONEY = NULL OUTPUT
	,@outReceivingPrice SMALLMONEY = NULL OUTPUT
	,@outLowPriceBatchId INT = NULL OUTPUT
	,@outHandledMethod INT = NULL OUTPUT
AS

SET NOCOUNT ON

CREATE TABLE #price (
	reg_price_method CHAR(1),
	reg_price SMALLMONEY,
	reg_dealqty SMALLINT,
	reg_unit_price SMALLMONEY,
	batchid INT,
	batch_price_method CHAR(1),
	batch_price SMALLMONEY,
	batch_multiple SMALLINT,
	batch_promo_code SMALLINT,
	batch_deal_price SMALLMONEY,
	batch_multi_price_group TINYINT,
	coupon_upc CHAR(13),
	coupon_type CHAR(1),
	coupon_price SMALLMONEY,
	coupon_deal_qty SMALLINT,
	advertized BIT,
	limit INT,
	price SMALLMONEY,
	coupon_reduction_amount SMALLMONEY,
	scan_price SMALLMONEY,
	handled INT
)

-- regular retail
INSERT INTO #price SELECT 
	ppn.pricemethod,
	ppn.price, 
	ppn.dealqty,
	ppn.price / CASE 
		WHEN ppn.dealqty = 0 THEN 1
		ELSE ppn.dealqty
	END,
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	999, NULL, NULL, NULL, NULL 
FROM 
	productprice ppn 
WHERE 
	pricetype='N' 
	AND upc=@upc 
	AND storeid = @storeId 

-- active batches
INSERT INTO #price SELECT
	ppn.pricemethod,
	ppn.price,
	ppn.dealqty,
	ppn.price / CASE 
		WHEN ppn.dealqty = 0 THEN 1
		ELSE ppn.dealqty
	END,
	pbd.batchid,
	pbd.batchpricemethod,
	pbd.batchspecialprice,
	CASE 
		WHEN ISNULL(pbd.batchdealqty, 0) = 0 THEN 1
		ELSE pbd.batchdealqty
	END,
	ISNULL(pbd.promocode, 0),
	pbd.batchdealprice,
	ISNULL(pbd.batchmultipricegroup, 0),
	coup_ppn.upc,
	coup_ppn.pricemethod,
	coup_ppn.price,
	coup_ppn.dealqty,
	coup_reg.advertized,
	NULL, NULL, NULL, NULL, NULL
FROM
	productbatchdetail pbd
INNER JOIN productprice ppn ON
	ppn.upc = pbd.upc
	AND ppn.pricetype='N'
	AND ppn.storeid = @storeId
LEFT OUTER JOIN productprice coup_ppn ON
	coup_ppn.upc = pbd.couponupc
	AND coup_ppn.pricetype='N'
	AND coup_ppn.storeid = @storeId
LEFT OUTER JOIN register4680 coup_reg ON
	coup_reg.upc = pbd.couponupc
	AND coup_reg.storeid = @storeId
INNER JOIN productbatchheader pbh ON
	pbh.batchid = pbd.batchid
 	AND CAST(CONVERT(varchar, pbh.startdate, 101) AS DATETIME) <= CAST(CONVERT(varchar, GETDATE(), 101) AS DATETIME)
 	AND CAST(CONVERT(varchar, pbh.enddate, 101) AS DATETIME) >= CAST(CONVERT(varchar, GETDATE(), 101) AS DATETIME)

	AND pbh.ReleasedTime IS NOT NULL
WHERE
	pbd.upc = @upc

-- TODO: throw error on coupon types B,C

-- just need TO fill this out FOR the regular retail row
UPDATE #price SET price = reg_price / CASE WHEN reg_dealqty = 0 THEN 1 ELSE reg_dealqty END WHERE batchid IS NULL
UPDATE #price SET coupon_reduction_amount = 0 WHERE batchid IS NULL 
UPDATE #price SET handled=0 WHERE batchid IS NULL

-- replace zero batch retail with lowest batch price 
SELECT TOP 1 * INTO #lowestBatchPrice FROM #price WHERE batchid IS NOT NULL AND batch_price > 0 ORDER BY batch_price / batch_multiple
IF EXISTS(SELECT * FROM #lowestBatchPrice) BEGIN

	UPDATE #price SET 
		batch_price = (SELECT batch_price FROM #lowestBatchPrice),
		batch_multiple = (SELECT batch_multiple FROM #lowestBatchPrice),
		batch_price_method = (SELECT batch_price_method FROM #lowestBatchPrice)
	WHERE 
		batchid IS NOT NULL 
		AND batch_price = 0

END
 
-- if there are still zero batch prices, replace zero batch price with regular retail
UPDATE #price SET 
	batch_price = reg_price,
	batch_multiple = reg_dealqty,
	batch_price_method = reg_price_method
WHERE 
	batchid IS NOT NULL 
	AND batch_price = 0

UPDATE #price SET batch_multiple = reg_dealqty WHERE batchid IS NOT NULL AND batch_multiple = 0

-- extend batch_price, batch_multiple
UPDATE #price SET price = batch_price / batch_multiple WHERE batchid IS NOT NULL AND batch_price_method IN ('A', 'B', 'C')
UPDATE #price SET price = batch_deal_price WHERE batchid IS NOT NULL AND batch_price_method IN ('D', 'E')

-- handle items in batches WITH no coupons attached
UPDATE #price SET 
	coupon_reduction_amount=0, 
	scan_price=price,
	handled = 1
WHERE 
	batchid IS NOT NULL 
	AND coupon_upc IS NULL
	AND batch_price_method IN ('A', 'B', 'C')

-- isolate limit for coupons where User3=0 (rightmost char OF a 2-digit integer)
UPDATE p SET 
	limit = coupon_deal_qty % 10 
FROM
	#price p 
INNER JOIN ProductPrice ppc ON
	ppc.Upc = p.coupon_upc
	AND ppc.PriceType ='N'
	AND ppc.StoreId = @storeId
INNER JOIN Register4680 reg ON
	reg.Upc = p.coupon_upc
	AND reg.StoreID = @storeId
WHERE 
	p.coupon_deal_qty IS NOT NULL
	AND ISNULL(reg.User3, 0) = 0

-- if coupon's User3 flag is on (Big Cpn Limit), limit=entire DealQty
UPDATE p SET 
	limit = coupon_deal_qty
FROM
	#price p 
INNER JOIN ProductPrice ppc ON
	ppc.Upc = p.coupon_upc
	AND ppc.PriceType ='N'
	AND ppc.StoreId = @storeId
INNER JOIN Register4680 reg ON
	reg.Upc = p.coupon_upc
	AND reg.StoreID = @storeId
WHERE 
	p.coupon_deal_qty IS NOT NULL
	AND ISNULL(reg.User3, 0) = 1

-- calculate coupon_reduction_amount for %off promotions
UPDATE #price SET 
	coupon_reduction_amount = ((batch_price / batch_multiple) * ((coupon_price-980) * .1)), 
	handled=2 
WHERE coupon_type = 'E' AND coupon_price > 980.00 AND coupon_price < 990.00 AND handled IS NULL
UPDATE #price SET 
	coupon_reduction_amount = ((batch_price / batch_multiple) * ((coupon_price-990) * .1)), 
	handled=3 
WHERE coupon_type = 'E' AND coupon_price > 990.00 AND coupon_price < 999.01 AND handled IS NULL

-- cents OFF
UPDATE #price SET 
	coupon_reduction_amount = coupon_price / limit, 
	handled=4 
WHERE coupon_type = 'A' AND coupon_price > 0.01 AND (advertized IS NOT NULL AND advertized = 0) AND handled IS NULL

-- cents OFF 'D' coupon
UPDATE #price SET 
	coupon_reduction_amount = coupon_price / limit, 
	handled=12 
WHERE coupon_type = 'D' AND  coupon_price > 0.01 AND (advertized IS NOT NULL AND advertized = 0) AND handled IS NULL

-- net price 
UPDATE #price SET 
	coupon_reduction_amount = price - coupon_price, 
	handled = 5 
WHERE coupon_type = 'E' AND coupon_price >= 0 AND limit = 1 AND handled IS NULL

-- calculate the actual scanning price (apply coupon_reduction_amount)
UPDATE #price SET 
	scan_price = price - coupon_reduction_amount 
	,price = price - coupon_reduction_amount
WHERE handled IS NOT NULL

-- BxGy
UPDATE #price SET 
	coupon_reduction_amount = price / limit, 
	scan_price = price - (price / limit),
	price = price - (price / limit),
	handled=6 
WHERE batchid IS NOT NULL AND coupon_type='E' AND coupon_price = 0 AND limit > 1 AND handled IS NULL

-- qty/price (e.g. 2/$5)
UPDATE #price SET 
	coupon_reduction_amount = price - (coupon_price / limit), 
	scan_price = coupon_price / limit,
	price = coupon_price / limit,
	handled = 7 
WHERE coupon_type = 'E' AND coupon_price <> 0 AND coupon_price > reg_unit_price AND handled IS NULL

-- turkey buck
-- SET scan_price TO 0.02 TO make it beat ALL pricing schemes EXCEPT 'meal deal'
UPDATE #price SET 
	scan_price = 0.02, 
	coupon_reduction_amount = price - 0.02, 
	handled = 8 
WHERE coupon_type = 'A' AND advertized = 1 AND handled IS NULL

-- meal deal
-- SET scan_price TO 0.01 TO make it beat ALL pricing schemes including 'turkey buck'
UPDATE #price SET 
	scan_price = 0.01, 
	coupon_reduction_amount = price - (coupon_price / limit), 
	handled = 9 
WHERE coupon_type IN ('A', 'B', 'C', 'D') AND coupon_price = .01 AND handled IS NULL

-- PM D, Reduced $ w/ Minimum Qty
UPDATE #price SET 
	scan_price = batch_deal_price
	,handled = 10
WHERE batch_price_method = 'D' AND ISNULL(coupon_upc,'') = ''

-- PM E, Reduced $ w/ Limited Qty
UPDATE #price SET 
	scan_price = batch_deal_price
	,handled = 11
WHERE batch_price_method = 'E' AND ISNULL(coupon_upc,'') = ''

-- net value with limit
UPDATE #price SET 
	coupon_reduction_amount = price - coupon_price, 
	scan_price = coupon_price,
	price = coupon_price ,
	handled = 12 
WHERE coupon_type = 'E' AND coupon_price <> 0 AND coupon_price <= reg_unit_price AND handled IS NULL

	
SET NOCOUNT OFF

SELECT TOP 1 
	@outLowPrice = scan_price
	,@outReceivingPrice = price
	,@outLowPriceBatchId = batchid
	,@outHandledMethod = handled
FROM
	#price
WHERE
	handled IS NOT NULL
ORDER BY 
	scan_price

IF @noResultset = 1 RETURN

-- first row TO come back WHEN sorting 
-- BY 'scan_price' ascending IS lowest price
SELECT
	lp.scan_price,
	lp.* 
FROM 
	#price lp
WHERE 
	lp.handled IS NOT NULL
ORDER BY 
	lp.scan_price ASC
	,lp.limit ASC
	,lp.handled DESC

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Product_FindLowestPriceByUpcIbmSa]
	@upc CHAR(13)
	,@storeId INT
	,@noResultset BIT = 0
	,@outLowPrice SMALLMONEY = NULL OUTPUT
	,@outReceivingPrice SMALLMONEY = NULL OUTPUT
	,@outLowPriceBatchId INT = NULL OUTPUT
	,@outHandledMethod INT = NULL OUTPUT
AS

SET NOCOUNT ON

CREATE TABLE #price (
	reg_price_method CHAR(1),
	reg_price SMALLMONEY,
	reg_dealqty SMALLINT,
	reg_unit_price SMALLMONEY,
	batchid INT,
	batch_price_method CHAR(1),
	batch_price SMALLMONEY,
	batch_multiple SMALLINT,
	batch_promo_code SMALLINT,
	batch_deal_price SMALLMONEY,
	batch_multi_price_group TINYINT,
	coupon_upc CHAR(13),
	coupon_type CHAR(1),
	coupon_price SMALLMONEY,
	coupon_deal_qty SMALLINT,
	advertized BIT,
	limit INT,
	price SMALLMONEY,
	coupon_reduction_amount SMALLMONEY,
	scan_price SMALLMONEY,
	handled INT
)

-- regular retail
INSERT INTO #price SELECT 
	ppn.IbmSaPriceMethod,
	ppn.PriceAmt, 
	ppn.PriceMult,
	ppn.PriceAmt / CASE 
		WHEN ppn.PriceMult = 0 THEN 1
		ELSE ppn.PriceMult
	END,
	NULL,	--batchid
	NULL,	--batch_price_method
	NULL,	--batch_price
	NULL,	--batch_multiple
	NULL,	--batch_promo_code
	NULL,	--batch_deal_price
	NULL,	--batch_multi_price_group
	NULL,	--coupon_upc
	NULL,	--coupon_type
	NULL,	--coupon_price
	NULL,	--coupon_deal_qty
	NULL,	--advertized
	999,	--limit
	NULL,	--price
	NULL,	--coupon_reduction_amount
	NULL,	--scan_price
	NULL	--handled
FROM 
	ProdPrice ppn 
WHERE 
	PriceType='N' 
	AND Upc=@upc 
	AND StoreId=@storeId 

-- active batches
INSERT INTO #price SELECT
	ppn.IbmSaPriceMethod,
	ppn.PriceAmt,
	ppn.PriceMult,
	ppn.PriceAmt / CASE 
		WHEN ppn.PriceMult = 0 THEN 1
		ELSE ppn.PriceMult
	END,
	pbd.BatchId,
	pbd.BatchPriceMethod,
	pbd.BatchSpecialPrice,
	CASE 
		WHEN ISNULL(pbd.BatchDealQty, 0) = 0 THEN 1
		ELSE pbd.BatchDealQty
	END,
	ISNULL(pbd.PromoCode, 0),
	pbd.BatchDealPrice,
	ISNULL(pbd.BatchMultiPriceGroup, 0),
	coup_ppn.Upc,
	coup_ppn.IbmSaPriceMethod,
	coup_ppn.PriceAmt,
	coup_ppn.PriceMult,
	coup_reg.Advertized,
	NULL,	--limit
	NULL,	--price
	NULL,	--coupon_reduction_amount
	NULL,	--scan_price
	NULL	--handled
FROM
	ProductBatchDetail pbd
INNER JOIN ProdPrice ppn ON
	ppn.Upc = pbd.upc
	AND ppn.PriceType='N'
	AND ppn.StoreId = @storeId
LEFT OUTER JOIN ProdPrice coup_ppn ON
	coup_ppn.Upc = pbd.CouponUPC
	AND coup_ppn.PriceType='N'
	AND coup_ppn.StoreId = @storeId
LEFT OUTER JOIN ProdPosIbmSa coup_reg ON
	coup_reg.Upc = pbd.CouponUPC
	AND coup_reg.StoreId = @storeId
INNER JOIN ProductBatchHeader pbh ON
	pbh.BatchId = pbd.BatchId
 	AND CAST(CONVERT(varchar, pbh.StartDate, 101) AS DATETIME) <= CAST(CONVERT(varchar, GETDATE(), 101) AS DATETIME)
 	AND CAST(CONVERT(varchar, pbh.EndDate, 101) AS DATETIME) >= CAST(CONVERT(varchar, GETDATE(), 101) AS DATETIME)
	AND pbh.ReleasedTime IS NOT NULL
WHERE
	pbd.UPC = @upc

-- TODO: throw error on coupon types B,C

-- just need TO fill this out FOR the regular retail row
UPDATE #price SET price = reg_price / CASE WHEN reg_dealqty = 0 THEN 1 ELSE reg_dealqty END WHERE batchid IS NULL
UPDATE #price SET coupon_reduction_amount = 0 WHERE batchid IS NULL 
UPDATE #price SET handled=0 WHERE batchid IS NULL

-- replace zero batch retail with lowest batch price 
SELECT TOP 1 * INTO #lowestBatchPrice FROM #price WHERE batchid IS NOT NULL AND batch_price > 0 ORDER BY batch_price / batch_multiple
IF EXISTS(SELECT * FROM #lowestBatchPrice) BEGIN

	UPDATE #price SET 
		batch_price = (SELECT batch_price FROM #lowestBatchPrice),
		batch_multiple = (SELECT batch_multiple FROM #lowestBatchPrice),
		batch_price_method = (SELECT batch_price_method FROM #lowestBatchPrice)
	WHERE 
		batchid IS NOT NULL 
		AND batch_price = 0

END
 
-- if there are still zero batch prices, replace zero batch price with regular retail
UPDATE #price SET 
	batch_price = reg_price,
	batch_multiple = CASE WHEN ISNULL(reg_dealqty,0) = 0 THEN 1 ELSE reg_dealqty END,
	batch_price_method = reg_price_method
WHERE 
	batchid IS NOT NULL 
	AND batch_price = 0

UPDATE #price SET batch_multiple = reg_dealqty WHERE batchid IS NOT NULL AND batch_multiple = 0

-- extend batch_price, batch_multiple
UPDATE #price SET price = batch_price / batch_multiple WHERE batchid IS NOT NULL AND batch_price_method IN ('A', 'B', 'C')
UPDATE #price SET price = batch_deal_price WHERE batchid IS NOT NULL AND batch_price_method IN ('D', 'E')

-- handle items in batches WITH no coupons attached
UPDATE #price SET 
	coupon_reduction_amount=0, 
	scan_price=price,
	handled = 1
WHERE 
	batchid IS NOT NULL 
	AND coupon_upc IS NULL
	AND batch_price_method IN ('A', 'B', 'C')

-- isolate limit for coupons where User3=0 (rightmost char OF a 2-digit integer)
UPDATE p SET 
	limit = coupon_deal_qty % 10 
FROM
	#price p 
INNER JOIN ProdPrice ppc ON
	ppc.Upc = p.coupon_upc
	AND ppc.PriceType ='N'
	AND ppc.StoreId = @storeId
INNER JOIN ProdPosIbmSa reg ON
	reg.Upc = p.coupon_upc
	AND reg.StoreID = @storeId
WHERE 
	p.coupon_deal_qty IS NOT NULL
	AND ISNULL(reg.User3, 0) = 0

-- if coupon's User3 flag is on (Big Cpn Limit), limit=entire DealQty
UPDATE p SET 
	limit = coupon_deal_qty
FROM
	#price p 
INNER JOIN ProdPrice ppc ON
	ppc.Upc = p.coupon_upc
	AND ppc.PriceType ='N'
	AND ppc.StoreId = @storeId
INNER JOIN ProdPosIbmSa reg ON
	reg.Upc = p.coupon_upc
	AND reg.StoreID = @storeId
WHERE 
	p.coupon_deal_qty IS NOT NULL
	AND ISNULL(reg.User3, 0) = 1

-- calculate coupon_reduction_amount for %off promotions
UPDATE #price SET 
	coupon_reduction_amount = ((batch_price / batch_multiple) * ((coupon_price-980) * .1)), 
	handled=2 
WHERE coupon_type = 'E' AND coupon_price > 980.00 AND coupon_price < 990.00 AND handled IS NULL
UPDATE #price SET 
	coupon_reduction_amount = ((batch_price / batch_multiple) * ((coupon_price-990) * .1)), 
	handled=3 
WHERE coupon_type = 'E' AND coupon_price > 990.00 AND coupon_price < 999.01 AND handled IS NULL

-- cents OFF
UPDATE #price SET 
	coupon_reduction_amount = coupon_price / limit, 
	handled=4 
WHERE coupon_type = 'A' AND coupon_price > 0.01 AND (advertized IS NOT NULL AND advertized = 0) AND handled IS NULL

-- cents OFF 'D' coupon
UPDATE #price SET 
	coupon_reduction_amount = coupon_price / limit, 
	handled=12 
WHERE coupon_type = 'D' AND  coupon_price > 0.01 AND (advertized IS NOT NULL AND advertized = 0) AND handled IS NULL

-- net price 
UPDATE #price SET 
	coupon_reduction_amount = price - coupon_price, 
	handled = 5 
WHERE coupon_type = 'E' AND coupon_price >= 0 AND limit = 1 AND handled IS NULL

-- calculate the actual scanning price (apply coupon_reduction_amount)
UPDATE #price SET 
	scan_price = price - coupon_reduction_amount 
	,price = price - coupon_reduction_amount
WHERE handled IS NOT NULL

-- BxGy
UPDATE #price SET 
	coupon_reduction_amount = price / limit, 
	scan_price = price - (price / limit),
	price = price - (price / limit),
	handled=6 
WHERE batchid IS NOT NULL AND coupon_type='E' AND coupon_price = 0 AND limit > 1 AND handled IS NULL

-- qty/price (e.g. 2/$5)
UPDATE #price SET 
	coupon_reduction_amount = price - (coupon_price / limit), 
	scan_price = coupon_price / limit,
	price = coupon_price / limit,
	handled = 7 
WHERE coupon_type = 'E' AND coupon_price <> 0 AND coupon_price > reg_unit_price AND handled IS NULL

-- turkey buck
-- SET scan_price TO 0.02 TO make it beat ALL pricing schemes EXCEPT 'meal deal'
UPDATE #price SET 
	scan_price = 0.02, 
	coupon_reduction_amount = price - 0.02, 
	handled = 8 
WHERE coupon_type = 'A' AND advertized = 1 AND handled IS NULL

-- meal deal
-- SET scan_price TO 0.01 TO make it beat ALL pricing schemes including 'turkey buck'
UPDATE #price SET 
	scan_price = 0.01, 
	coupon_reduction_amount = price - (coupon_price / limit), 
	handled = 9 
WHERE coupon_type IN ('A', 'B', 'C', 'D') AND coupon_price = .01 AND handled IS NULL

-- PM D, Reduced $ w/ Minimum Qty
UPDATE #price SET 
	scan_price = batch_deal_price
	,handled = 10
WHERE batch_price_method = 'D' AND ISNULL(coupon_upc,'') = ''

-- PM E, Reduced $ w/ Limited Qty
UPDATE #price SET 
	scan_price = batch_deal_price
	,handled = 11
WHERE batch_price_method = 'E' AND ISNULL(coupon_upc,'') = ''

-- net value with limit
UPDATE #price SET 
	coupon_reduction_amount = price - coupon_price, 
	scan_price = coupon_price,
	price = coupon_price ,
	handled = 12 
WHERE coupon_type = 'E' AND coupon_price <> 0 AND coupon_price <= reg_unit_price AND handled IS NULL

	
SET NOCOUNT OFF

SELECT TOP 1 
	@outLowPrice = scan_price
	,@outReceivingPrice = price
	,@outLowPriceBatchId = batchid
	,@outHandledMethod = handled
FROM
	#price
WHERE
	handled IS NOT NULL
ORDER BY 
	scan_price

IF @noResultset = 1 RETURN

-- first row TO come back WHEN sorting 
-- BY 'scan_price' ascending IS lowest price
SELECT 
	scan_price
	,reg_price_method
	,reg_price
	,reg_dealqty
	,reg_unit_price
	,batchid
	,batch_price_method
	,batch_price
	,batch_multiple
	,batch_promo_code
	,batch_deal_price
	,batch_multi_price_group
	,coupon_upc
	,coupon_type
	,coupon_price
	,coupon_deal_qty
	,advertized
	,limit
	,price
	,coupon_reduction_amount
	,handled
FROM #price
WHERE 
	handled IS NOT NULL
ORDER BY
	scan_price ASC
	,limit ASC
	,handled DESC

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Product_FindLowestPriceByUpcIss45]
	@upc CHAR(13)
	,@storeId INT
	,@noResultset BIT = 0
	,@outLowPrice SMALLMONEY = NULL OUTPUT
	,@outReceivingPrice SMALLMONEY = NULL OUTPUT
	,@outLowPriceBatchId INT = NULL OUTPUT
	,@outHandledMethod INT = NULL OUTPUT
AS

SET NOCOUNT ON

CREATE TABLE #price (
	reg_price_method CHAR(1),
	reg_price SMALLMONEY,
	reg_dealqty SMALLINT,
	reg_unit_price SMALLMONEY,
	batchid INT,
	batch_price_method CHAR(1),
	batch_price SMALLMONEY,
	batch_multiple SMALLINT,
	batch_mix_match INT,
	price SMALLMONEY,
	scan_price SMALLMONEY,
	handled INT
)

-- regular retail
INSERT INTO #price SELECT 
	ppn.IbmSaPriceMethod,
	ppn.PriceAmt, 
	ppn.PriceMult,
	ppn.PriceAmt / CASE 
		WHEN ppn.PriceMult = 0 THEN 1
		ELSE ppn.PriceMult
	END,	-- reg_unit_price
	NULL,	-- batchid
	NULL,	-- batch_price_method
	NULL,	-- batch_price
	NULL,	-- batch_multiple
	NULL,	-- batch_mix_match
	NULL,	-- price
	NULL,	-- scan_price
	999		-- handled
FROM 
	ProdPrice ppn 
WHERE 
	PriceType = 'N' 
	AND Upc = @upc 
	AND StoreId = @storeId 

-- active batches
INSERT INTO #price SELECT
	ppn.IbmSaPriceMethod
	,ppn.PriceAmt
	,ppn.PriceMult
	,ppn.PriceAmt / CASE 
		WHEN ppn.PriceMult = 0 THEN 1
		ELSE ppn.PriceMult
	END
	,pbd.batchid
	,pbd.batchpricemethod
	,pbd.batchspecialprice
	,CASE 
		WHEN ISNULL(pbd.batchdealqty, 0) = 0 THEN 1
		ELSE pbd.batchdealqty
	END		-- batch_multiple
	,ISNULL(pbd.PromoCode, 0)	-- batch_mix_match
	,NULL	-- price
	,NULL	-- scan_price
	,NULL	-- handled
FROM
	ProductBatchDetail pbd
INNER JOIN ProdPrice ppn ON
	ppn.Upc = pbd.Upc
	AND ppn.PriceType = 'N'
	AND ppn.StoreId = @storeId
INNER JOIN ProductBatchHeader pbh ON
	pbh.BatchId = pbd.BatchId
 	AND CAST(CONVERT(varchar, pbh.StartDate, 101) AS DATETIME) <= CAST(CONVERT(varchar, GETDATE(), 101) AS DATETIME)
 	AND CAST(CONVERT(varchar, pbh.EndDate, 101) AS DATETIME) >= CAST(CONVERT(varchar, GETDATE(), 101) AS DATETIME)
	AND pbh.ReleasedTime IS NOT NULL
WHERE
	pbd.upc = @upc

-- calcs for normal price
UPDATE #price SET price = reg_price / CASE WHEN reg_dealqty = 0 THEN 1 ELSE reg_dealqty END WHERE batchid IS NULL
UPDATE #price SET handled=0, scan_price=price WHERE batchid IS NULL

-- TODO: might not need this?
-- UPDATE #price SET batch_multiple = reg_dealqty WHERE batchid IS NOT NULL AND batch_multiple = 0

-- extend batch_price, batch_multiple
UPDATE #price SET price = batch_price / batch_multiple WHERE batchid IS NOT NULL

-- handle items in batches WITH no coupons attached
UPDATE #price SET 
	scan_price=price,
	handled = 1
WHERE 
	batchid IS NOT NULL 

SET NOCOUNT OFF
SELECT TOP 1 
	@outLowPrice = scan_price
	,@outReceivingPrice = price
	,@outLowPriceBatchId = batchid
	,@outHandledMethod = handled
FROM
	#price
WHERE
	handled IS NOT NULL
ORDER BY 
	scan_price

IF @noResultset = 1 RETURN

-- first row TO come back WHEN sorting 
-- BY 'scan_price' ascending IS lowest price
SELECT
	scan_price
	,reg_price_method
	,reg_price
	,reg_dealqty
	,reg_unit_price
	,batchid
	,batch_price_method
	,batch_price
	,batch_multiple
	,batch_mix_match
	,price
	,handled
FROM 
	#price 
WHERE 
	handled IS NOT NULL
ORDER BY 
	scan_price ASC
	,handled DESC

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Product_Search]
	@SearchKeys VARCHAR(1024),
	@searchUpc bit,
	@searchSku bit,
	@searchDescription bit,
	@searchBrand bit,
	@wildcardMode int,
	@matchPhrase bit = 0,
	@restrictDepartment int = NULL,
	@posType VARCHAR(10) = NULL
AS

-- wildcard mode:  0-match within, 1-match beginning, 2- match ending
-- exact match: 0-don't parse into keywords, 1-parse keywords

    SET NOCOUNT ON
  	DECLARE @searchstr VARCHAR(1024)

    declare @delimpos int
    declare @start int 
    declare @word varchar(1024)
    DECLARE @numwords INT

-- temp table to hold list of items matched
    CREATE TABLE #allkeys ( upc char(13) )
    CREATE INDEX IX_upc ON #allkeys(upc)
    CREATE TABLE #brandkeys ( upc char(13), word varchar(50) )
    CREATE INDEX IX_upc_word ON #brandkeys(upc, word)
    CREATE TABLE #descrkeys ( upc char(13), word varchar(50) )
    CREATE INDEX IX_upc_word ON #descrkeys(upc, word)

    IF @SearchKeys = '' RETURN

-- support UPC search
	IF @searchUpc = 1 BEGIN
	    IF LEN(RTRIM(LTRIM(@SearchKeys))) <= 13 BEGIN
	        IF ISNUMERIC(@SearchKeys) = 1  BEGIN

				IF @wildcardMode = 0 BEGIN
	                SELECT @searchstr = '%' + @SearchKeys + '%'
				END ELSE IF @wildcardMode = 1 BEGIN
	                SELECT @searchstr = @SearchKeys + '%'
				END ELSE IF @wildcardMode = 2 BEGIN
	                SELECT @searchstr = '%' + @SearchKeys 
				END

	            INSERT #allkeys
	                SELECT 
						upc
	                FROM 
						Prod p
	                WHERE 
						Upc like @searchstr
	        END
	    END 
	END

-- OrderCode search
	IF @searchSku = 1 BEGIN
        IF ISNUMERIC(@SearchKeys) = 1 BEGIN

			IF @wildcardMode = 0 BEGIN
                SELECT @searchstr = '%' + @SearchKeys + '%'
			END ELSE IF @wildcardMode = 1 BEGIN
                SELECT @searchstr = @SearchKeys + '%'
			END ELSE IF @wildcardMode = 2 BEGIN
                SELECT @searchstr = '%' + @SearchKeys 
			END


            INSERT #allkeys
                SELECT upc
                FROM SupplierProd sp
                WHERE OrderCode like @searchstr


        END
	END


	IF @searchDescription = 1 BEGIN

	    create table #searchkeys (word VARCHAR(1024))
		IF @matchPhrase = 0 BEGIN
-- parse into individual keywords
		    select @start=1
		    NEXTPART:
		    select @delimpos = CHARINDEX(' ', @SearchKeys, @start)
		    IF @delimpos <> 0 begin
		        select @word = SUBSTRING(@SearchKeys, @start, @delimpos - @start)
		    END ELSE BEGIN
		        SELECT @word = SUBSTRING(@SearchKeys, @start, LEN(@SearchKeys) - @start + 1)
		    END


		    INSERT INTO #searchkeys (word) VALUES (@word)
		    SELECT @start = @start + LEN(@word) + 1
		    IF @start < LEN(@SearchKeys) BEGIN
		        GOTO NEXTPART
		    END
		END ELSE BEGIN
			INSERT INTO #searchkeys VALUES (@SearchKeys)
		END

-- filter dupes and empty strings
	    SELECT DISTINCT word INTO #searchkeys2 FROM #searchkeys WHERE word <> '' AND word IS NOT NULL

	    DECLARE Words_Cursor CURSOR FOR SELECT word FROM #searchkeys2
	    OPEN Words_Cursor
	    FETCH NEXT FROM Words_Cursor INTO @word
	    WHILE @@FETCH_STATUS <> -1 BEGIN

				IF @wildcardMode = 0 BEGIN
	                SELECT @searchstr = '%' + @word + '%'
				END ELSE IF @wildcardMode = 1 BEGIN
	                SELECT @searchstr = @word + '%'
				END ELSE IF @wildcardMode = 2 BEGIN
	                SELECT @searchstr = '%' + @word 
				END

-- search product.branditemdescription
	        INSERT #descrkeys SELECT DISTINCT 
				Upc, 
				LEFT(@word, 255)
	        FROM        
				Prod p
	        WHERE
	            ItemDescr LIKE @searchstr

	        FETCH NEXT FROM Words_Cursor INTO @word
	    END
	    CLOSE Words_Cursor
	    DEALLOCATE Words_Cursor

-- only return the items that matches all search terms		
	    SELECT @numwords = COUNT(*) FROM #searchkeys2
	    SELECT upc, COUNT(*) as hits INTO #descmatchall FROM #descrkeys GROUP BY UPC HAVING COUNT(*) = @numwords

	    INSERT #allkeys SELECT upc FROM #descmatchall

	END

	IF @searchBrand = 1 BEGIN
		create table #brandsearchkeys (word VARCHAR(1024))
		IF @matchPhrase = 0 BEGIN
-- parse into individual keywords
			select @start=1
			NEXTPART_1:
			select @delimpos = CHARINDEX(' ', @SearchKeys, @start)
			IF @delimpos <> 0 begin
				select @word = SUBSTRING(@SearchKeys, @start, @delimpos - @start)
			END ELSE BEGIN
				SELECT @word = SUBSTRING(@SearchKeys, @start, LEN(@SearchKeys) - @start + 1)
			END

			INSERT INTO #brandsearchkeys (word) VALUES (@word)
			SELECT @start = @start + LEN(@word) + 1
			IF @start < LEN(@SearchKeys) BEGIN
				GOTO NEXTPART_1
			END
		END ELSE BEGIN
			INSERT INTO #brandsearchkeys VALUES (@SearchKeys)
		END
-- filter dupes and empty strings
	    SELECT DISTINCT word INTO #brandsearchkeys2 FROM #brandsearchkeys WHERE word <> '' AND word IS NOT NULL

	    DECLARE Words_Cursor CURSOR FOR SELECT word FROM #brandsearchkeys
	    OPEN Words_Cursor
	    FETCH NEXT FROM Words_Cursor INTO @word
	    WHILE @@FETCH_STATUS <> -1 BEGIN

			IF @wildcardMode = 0 BEGIN
                SELECT @searchstr = '%' + @word + '%'
			END ELSE IF @wildcardMode = 1 BEGIN
                SELECT @searchstr = @word + '%'
			END ELSE IF @wildcardMode = 2 BEGIN
                SELECT @searchstr = '%' + @word
			END

-- search brand.brandname
	        INSERT #brandkeys SELECT DISTINCT 
				Upc, 
				LEFT(@word, 30)
	        FROM        
				Prod p
			WHERE
	            p.BrandName LIKE @searchstr 
	        ORDER BY upc

	        FETCH NEXT FROM Words_Cursor INTO @word
	    END
	    CLOSE Words_Cursor
	    DEALLOCATE Words_Cursor

	    SELECT @numwords = COUNT(*) FROM #brandsearchkeys2

	    SELECT upc, COUNT(*) as hits INTO #brandmatchall FROM #brandkeys GROUP BY UPC HAVING COUNT(*) = @numwords
	    INSERT #allkeys SELECT upc FROM #brandmatchall

	END

-- restrict to a specific department
    IF @restrictDepartment IS NOT NULL BEGIN
		DELETE FROM #allkeys WHERE #allkeys.upc IN (
			SELECT 
				k.upc 
			FROM 
				#allkeys k 			
			INNER JOIN Prod p ON
		    	p.Upc = k.Upc
	       	WHERE
	        	p.DepartmentId <> @restrictDepartment
		)
    END

-- filter dupe upc's
    SELECT DISTINCT upc INTO #keys FROM #allkeys  
    CREATE INDEX IX_upc ON #keys(upc)

-- final output
    SET NOCOUNT OFF
	IF @posType = 'ISS45' BEGIN
	    SELECT iv.* FROM item_view_iss45 iv INNER JOIN #keys k ON k.upc = iv.upc WHERE ProductTypeCd NOT IN ('6', '7')
	END ELSE IF @posType = 'IBMSA' BEGIN
		SELECT iv.* FROM item_view_ibmsa iv INNER JOIN #keys k ON k.upc = iv.upc WHERE ProductTypeCd NOT IN ('6', '7')
	END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Product_SelectAllInfoForCouponMaint]
	@upc CHAR(13)
	,@storeId SMALLINT
AS

SELECT 
	iv.*
FROM 
	item_view iv 
WHERE upc = @upc

SELECT * FROM ProductPrice WHERE upc = @upc AND StoreId = @storeId AND PriceType = 'N'
SELECT * FROM ProductStore WHERE upc = @upc AND StoreId = @storeId
SELECT * FROM Register4680 WHERE upc = @upc AND StoreId = @storeId

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE [dbo].[Product_SelectByLabelRequestDate]
	@startDate DATETIME = '1/1/1900'
	,@endDate DATETIME = '12/31/2999'
AS

SELECT 
	iv.* 
	,iv.LabelRequestUser AS RequestUser
	,iv.LabelRequestDate AS RequestDate
FROM 
	item_view iv
WHERE 
	iv.LabelRequestDate IS NOT NULL	
	AND iv.LabelRequestDate BETWEEN @startDate AND @endDate

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE [dbo].[Product_SelectBySignRequestDate]
	@startDate DATETIME = '1/1/1900'
	,@endDate DATETIME = '12/31/2999'
AS

SELECT 
	iv.* 
	,iv.SignRequestUser AS RequestUser
	,iv.SignRequestDate AS RequestDate
FROM 
	item_view iv
WHERE 
	iv.SignRequestDate IS NOT NULL	
	AND iv.SignRequestDate BETWEEN @startDate AND @endDate

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    PROCEDURE [dbo].[ProductAudit_SelectByUpcStartDateEndDate]
	@upc CHAR(13)
	,@startDate DATETIME = NULL
	,@endDate DATETIME = NULL
AS

SELECT 
	pa.*
FROM
	ProductAudit_View pa WITH (NOLOCK)
WHERE
	pa.upc = @upc
	AND (
		(pa.audit_time BETWEEN @startDate AND @endDate)
		OR
		(@startDate IS NULL AND @endDate IS NULL)
	)

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE        PROCEDURE [dbo].[ProductBatch_Clone]
	@batchId INT
	,@newBatchDescription VARCHAR(255)
	,@readOnly BIT = NULL
	,@newBatchId INT OUTPUT
AS 

DECLARE @error INT
DECLARE @startDate DATETIME
DECLARE @endDate DATETIME

-- make sure the batch being cloned exists
IF NOT EXISTS ( SELECT
                    batchid
                FROM
                    productbatchheader
                WHERE
                    batchid = @batchId ) 
   BEGIN
         RAISERROR ( 'Unable to clone price batch %0d because it does not exist' , 16 , 1 , @batchId )
         RETURN
   END

-- make sure the new batch description does not already exist
IF EXISTS ( SELECT
                batchid
            FROM
                productbatchheader
            WHERE
                description = @newBatchDescription ) 
   BEGIN
         RAISERROR ( 'Unable to clone price batch %0d to ''%s'' because that description has already been used' , 16 , 1 , @batchId , @newBatchDescription )
         RETURN
   END

-- get the current store id, so when corp batches are cloned they become store batches
DECLARE @localStoreNumber INT
SELECT
    @localStoreNumber = CONVERT(INT, option_value)
FROM
    s3_system_option
WHERE
    option_name = 'store_number'
IF @localStoreNumber IS NULL 
   BEGIN
         RAISERROR ( 'Unable to read system option for ''store_number''' , 16 , 1 )
         RETURN
   END

SELECT
    @startDate = startdate
   ,@endDate = enddate
FROM
    productbatchheader
WHERE
    batchid = @batchId

BEGIN TRANSACTION

INSERT INTO ProductBatchHeader (
	StoreId
	,ProductBatchTypeId
	,StartDate
	,EndDate
	,Description
	,ShowInProcessItemUpdates
	,IsReadOnly
	,CreateTime
	,AutoApplyOnTime
	,AutoApplyOffTime
	,HqNotes
	,StoreNotes
) SELECT
	@localStoreNumber
	,ProductBatchTypeId
	,@startDate
	,@endDate
	,@newBatchDescription
	,ShowInProcessItemUpdates
	,CASE
		WHEN @readOnly IS NULL THEN IsReadOnly
		ELSE @readOnly
	END
	,GETDATE()
	,AutoApplyOnTime
	,AutoApplyOffTime
	,HqNotes
	,StoreNotes
FROM
    productbatchheader
WHERE
    batchid = @batchId

SET @error = @@ERROR
IF @error <> 0 
   BEGIN
         ROLLBACK TRANSACTION
         RETURN
   END

-- save for usage later on
SET @newBatchId = SCOPE_IDENTITY()

INSERT INTO
    ProductBatchStore
    SELECT
       @newBatchId
       ,@localStoreNumber

SET @error = @@ERROR
IF @error <> 0 
   BEGIN
         ROLLBACK TRANSACTION
         RETURN
   END

INSERT INTO
    ProductBatchDetail
    SELECT
        upc
       ,@newBatchId
       ,batchpricemethod
       ,batchdealqty
       ,batchspecialprice
       ,batchdealprice
       ,batchmultipricegroup
       ,advertised
       ,couponupc
       ,promocode
       ,ForcePosValid
       ,0
       ,0
       ,NULL
    FROM
        productbatchdetail
    WHERE
        batchid = @batchid

SET @error = @@ERROR
IF @error <> 0 
   BEGIN
         ROLLBACK TRANSACTION
         RETURN
   END


COMMIT TRANSACTION

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[ProductBatch_FindBatchesToAutoApply]
	@maxDays INT
AS

-- FPRICE ON
SELECT
	'FPRICE' AS type
	,'ON' AS direction
    ,*
FROM
    ProductBatchHeader_View AS pbhv
WHERE
    pbhv.EndDate IS NULL
	AND pbhv.ReleasedTime IS NOT NULL
    AND pbhv.AutoApplyOnTime IS NOT NULL
    AND pbhv.AutoApplyOnSentTime IS NULL
    AND pbhv.days_since_auto_apply_on_time BETWEEN 0 AND @maxDays
	AND pbhv.minutes_since_auto_apply_on_time >= 0

-- FSPRICE OFF
SELECT
	'FPRICE' AS type
	,'OFF' AS direction
    ,*
FROM
    ProductBatchHeader_View AS pbhv
WHERE
    pbhv.EndDate IS NOT NULL
	AND pbhv.ReleasedTime IS NOT NULL
    AND pbhv.AutoApplyOffTime IS NOT NULL
    AND pbhv.AutoApplyOffSentTime IS NULL
    AND pbhv.days_since_auto_apply_off_time BETWEEN 0 AND @maxDays
    AND pbhv.minutes_since_auto_apply_off_time >= 0


-- FSPRICE ON
SELECT
	'FSPRICE' AS type
	,'ON' AS direction
    ,*
FROM
    ProductBatchHeader_View AS pbhv
WHERE
    pbhv.EndDate IS NOT NULL
	AND pbhv.ReleasedTime IS NOT NULL
    AND pbhv.AutoApplyOnTime IS NOT NULL
    AND pbhv.AutoApplyOnSentTime IS NULL
    AND pbhv.days_since_auto_apply_on_time BETWEEN 0 AND @maxDays
	AND DATEPART(dy, pbhv.StartDate) = DATEPART(dy, pbhv.AutoApplyOnTime)
	AND pbhv.minutes_since_auto_apply_on_time >= 0

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[ProductBatch_Search]
	@searchType INT
	,@searchString VARCHAR(256) = NULL
	,@onlyWithEndDate BIT = 0
AS

DECLARE @batches TABLE (
	BatchId INT NOT NULL PRIMARY KEY
)

-- just get all batches
IF @searchType = 0 BEGIN
	INSERT INTO @batches SELECT BatchId FROM ProductBatchHeader pbh WITH (NOLOCK) 
	WHERE 
		(@onlyWithEndDate = 0 OR pbh.EndDate IS NOT NULL)
END

-- search by batch description
IF @searchType = 1 BEGIN
	SET @searchString = '%' + LTRIM(RTRIM(@searchString)) + '%'
	INSERT INTO @batches SELECT DISTINCT BatchId FROM ProductBatchHeader pbh WITH (NOLOCK) 
	WHERE 
		Description like @searchString
		AND (@onlyWithEndDate = 0 OR pbh.EndDate IS NOT NULL)
END

-- search by upc code
IF @searchType = 2 BEGIN
	SET @searchString = '%' + LTRIM(RTRIM(@searchString)) + '%'
	INSERT INTO @batches SELECT DISTINCT pbd.BatchId 
	FROM ProductBatchDetail pbd  WITH (NOLOCK) 
	INNER JOIN ProductBatchHeader pbh WITH (NOLOCK) ON
		pbh.BatchId = pbd.BatchId
		AND (@onlyWithEndDate = 0 OR pbh.EndDate IS NOT NULL)
	WHERE 
		Upc like @searchString
END

-- search by batchid
IF @searchType = 3 BEGIN
	INSERT INTO @batches (BatchId) VALUES (CONVERT(INT,@searchString))
END

SELECT
	pbs.BatchStatusDescription
	,pbhv.*
FROM
	ProductBatchHeader_View AS pbhv
INNER JOIN ProductBatchStatus AS pbs ON
	pbs.BatchStatusId = pbhv.BatchStatusId
INNER JOIN @batches b ON
	b.BatchId = pbhv.BatchId

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE     PROCEDURE [dbo].[ProductBatch_Split]
	@batchId INT,
	@maxItemsPerBatch INT
AS

DECLARE @error INT
DECLARE @startDate DATETIME
DECLARE @endDate DATETIME

-- make sure the batch being cloned exists
IF NOT EXISTS(SELECT batchid FROM productbatchheader WHERE batchid=@batchId) BEGIN
	RAISERROR ('Unable to clone product batch with BatchId=%0d because it does not exist', 16, 1, @batchId)
	RETURN
END

BEGIN TRANSACTION

-- this will hold the batchid's of all the new batches that get created
CREATE TABLE #newBatches (
	new_batchid INT NOT NULL
)

-- get a list if the upc's in the batch into a temp table, with an identity column, so we can have row #'s
CREATE TABLE #items (
	rownum INT IDENTITY(1,1) NOT NULL
	,upc CHAR(13) NOT NULL
)

INSERT INTO #items (upc) SELECT DISTINCT
	upc
FROM
	productbatchdetail
WHERE
	batchid = @batchId
ORDER BY
	upc

DECLARE @maxRowNum INT
SELECT @maxRowNum = MAX(rownum) FROM #items

DECLARE @startRowNum INT
DECLARE @endRowNum INT

-- leave the first '@maxItemsPerBatch' in the original batch
SET @startRowNum = @maxItemsPerBatch + 1

-- figure out the base description for the new batches
DECLARE @newBatchDescr VARCHAR(255)
DECLARE @suffix VARCHAR(5)
DECLARE @descr VARCHAR(255)
SELECT @descr = pbh.description FROM productbatchheader pbh WHERE batchid = @batchId


SET @suffix = ''
-- TODO: need to deal with '_CORP' suffixes anymore???
-- DECLARE @corpPosn INT
-- SET @corpPosn = CHARINDEX('_CORP', @descr)
-- IF @corpPosn IS NOT NULL AND @corpPosn > 0 BEGIN
-- 	SET @descr = SUBSTRING(@descr, 1, @corpPosn-1)
-- 	SET @suffix = '_CORP'
-- END


DECLARE @batchSeq INT
SET @batchSeq = 1

WHILE @startRowNum <= @maxRowNum BEGIN
	SET @endRowNum = @startRowNum + @maxItemsPerBatch - 1


	RetryBatchDescr:	
	SET @newBatchDescr = CAST(@descr + '.' + CAST(@batchSeq AS VARCHAR) + @suffix AS VARCHAR(255))
	IF EXISTS (SELECT 1 FROM ProductBatchHeader WHERE Description = @newBatchDescr) BEGIN
		SET @batchSeq = @batchSeq + 1
		GOTO RetryBatchDescr
	END

	-- create new ProductBatchHeader
	INSERT INTO productbatchheader (
		StoreId
		,ProductBatchTypeId
		,StartDate
		,EndDate
		,Description
		,ShowInProcessItemUpdates
		,IsReadOnly
		,CreateTime
		,AutoApplyOnTime
		,AutoApplyOffTime
		,HqNotes
		,StoreNotes
		,ReleasedTime
	)
	SELECT
		StoreId
		,ProductBatchTypeId
		,StartDate
		,EndDate
		,@newBatchDescr
		,ShowInProcessItemUpdates
		,IsReadOnly
		,CreateTime
		,AutoApplyOnTime
		,AutoApplyOffTime
		,HqNotes
		,StoreNotes
		,ReleasedTime
	FROM
		productbatchheader
	WHERE
		batchid = @batchId
	
	SET @error = @@ERROR
	IF @error <> 0 BEGIN
		ROLLBACK TRANSACTION
		RETURN
	END

	-- increment for next batch
	SET @batchSeq = @batchSeq + 1
	
	DECLARE @newBatchId INT
	SET @newBatchId = @@IDENTITY

	-- create new ProductBatchStore
	INSERT INTO productbatchstore SELECT
		@newBatchId
		,StoreId
	FROM
		ProductBatchStore pbs 
	WHERE
		pbs.BatchId = @batchId
	
	SET @error = @@ERROR
	IF @error <> 0 BEGIN
		ROLLBACK TRANSACTION
		RETURN
	END

	-- create new ProductBatchDetail
	INSERT INTO ProductBatchDetail SELECT
	        pbd.upc
	       ,@newBatchId
	       ,pbd.batchpricemethod
	       ,pbd.batchdealqty
	       ,pbd.batchspecialprice
	       ,pbd.batchdealprice
	       ,pbd.batchmultipricegroup
	       ,pbd.advertised
	       ,pbd.couponupc
	       ,pbd.promocode
	       ,pbd.ForcePosValid
	       ,0
	       ,0
	       ,NULL
	    FROM
	        productbatchdetail pbd
		INNER JOIN #items i ON
			i.upc = pbd.upc
			AND i.rownum BETWEEN @startRowNum AND @endRowNum
	    WHERE
	        batchid = @batchid


	SET @error = @@ERROR
	IF @error <> 0 BEGIN
		ROLLBACK TRANSACTION
		RETURN
	END

	-- remove items from original ProductBatchDetail
	DELETE 
		pbd
	FROM 
		productbatchdetail pbd
	INNER JOIN #items i ON
		i.upc = pbd.upc 
		AND i.rownum BETWEEN @startRowNum AND @endRowNum	
	WHERE 
		batchid = @batchId

	-- save batchid of the new batch
	INSERT INTO #newBatches VALUES (@newBatchId)

	SET @startRowNum = @endRowNum + 1
END

-- return a list of all the new batches created
SELECT 
	pbh.BatchId
	,pbh.StartDate
	,pbh.EndDate
	,pbh.Description
	,(SELECT COUNT(1) FROM ProductBatchDetail pbd WHERE pbd.batchid = pbh.BatchId) AS ItemCount
FROM 
	#newBatches nb
INNER JOIN ProductBatchHeader pbh ON
	pbh.batchid = nb.new_batchid


COMMIT TRANSACTION

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ProductBatch_Validate]
	@batchId INT
AS

DECLARE @error INT

-- make sure the batch being cloned exists
IF NOT EXISTS(SELECT batchid FROM productbatchheader WHERE batchid=@batchId) BEGIN
	RAISERROR ('Unable to validate product batch with BatchId=%0d because it does not exist', 16, 1, @batchId)
	RETURN
END

CREATE TABLE #problems (
	Upc CHAR(13) NOT NULL
	,StoreId SMALLINT NOT NULL
	,Problem VARCHAR(255) NOT NULL
)

-- validate zero or missing retail
INSERT INTO #problems SELECT
	pbd.Upc
	,pbs.StoreId
	,'Price zero or missing' AS Problem
FROM
	productbatchdetail pbd WITH (NOLOCK)
INNER JOIN productbatchstore pbs WITH (NOLOCK) ON
	pbs.batchid = pbd.batchid
LEFT OUTER JOIN productprice ppn WITH (NOLOCK) ON
	ppn.StoreId = pbs.StoreId
	AND ppn.upc = pbd.upc
	AND ppn.pricetype='N'
WHERE
	pbd.batchid = @batchId
	AND (
		ppn.price IS NULL
		OR ppn.price = 0
	)

-- validate bad or missing pos description
INSERT INTO #problems SELECT
	pbd.Upc
	,pbs.StoreId AS StoreId
	,'Invalid POS Description: ' + ISNULL(reg.PosDescription, '(no value)') AS Problem
FROM
	productbatchdetail pbd WITH (NOLOCK)
INNER JOIN productbatchstore pbs WITH (NOLOCK) ON
	pbs.batchid = pbd.batchid
LEFT OUTER JOIN register4680 reg WITH (NOLOCK) ON
	reg.storeid = pbs.StoreId
	AND reg.upc = pbd.upc
WHERE
	pbd.batchid = @batchId
	AND (
		reg.posdescription IS NULL
		OR reg.posdescription = ''
		OR reg.posdescription = 'Model UPC'
	)

-- validate missing primary supplier
INSERT INTO #problems SELECT
	pbd.Upc
	,pbs.StoreId AS StoreId
	,'No primary supplier' AS Problem
FROM
	productbatchdetail pbd WITH (NOLOCK)
INNER JOIN productbatchstore pbs WITH (NOLOCK) ON
	pbs.batchid = pbd.batchid
LEFT OUTER JOIN multistoresupplier mss WITH (NOLOCK) ON
	mss.storeid = pbs.StoreId
	AND mss.upc = pbd.upc
	AND mss.isprimarysupplier = 1
WHERE
	pbd.batchid = @batchId
	AND (
		mss.isprimarysupplier IS NULL
	)

SELECT 
	prob.* 
	,b.BrandName
	,p.BrandItemDescription
	,p.ProductSize AS Size
	,p.ProductUOM AS Uom
	,p.DepartmentId AS DepartmentId
	,d.DepartmentName
FROM 
	#problems prob
INNER JOIN product p ON
	p.upc = prob.upc
INNER JOIN brand b ON
	b.brandid = p.brandid
INNER JOIN department d ON
	d.departmentid = p.departmentid
ORDER BY
	prob.upc
	,prob.storeid

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ProductBatchDetail_SelectByApplied]
	@batchId INT
	,@includeApplied BIT
	,@includeUnapplied BIT
AS

SELECT
	iv.upc
	,iv.brandname
	,iv.branditemdescription
	,iv.productsize
	,iv.productuom
	,CAST(ISNULL(pbd.HasStarted, 0) AS BIT) AS HasStarted
FROM
	productbatchdetail pbd WITH (NOLOCK)
INNER JOIN item_view iv ON
	iv.upc = pbd.upc
WHERE
	batchid = @batchId
	AND (
		(@includeApplied=1 AND pbd.HasStarted = 1)
		OR
		(@includeUnapplied=1 AND (ISNULL(pbd.HasStarted, 0) <> 1))
	)

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE     PROCEDURE [dbo].[ProductBatchDetail_SelectByBatchId]
	@batchId INT
	,@storeId SMALLINT
AS

-- create temporary table with ProductCostAdjustment details: upc, # of adjustments, sum of adjustment amount
SET NOCOUNT ON
SELECT
	pbd.upc
	,COUNT(pca.upc) AS number_of_adjustments
	,SUM(pca.Amount) AS total_adjustment_amount
INTO 
	#tempAdjustment
FROM
	ProductBatchDetail pbd
INNER JOIN ProductBatchHeader pbh ON
	pbh.BatchId = pbd.BatchId
INNER JOIN ProductCostAdjustment pca ON
	pca.upc = pbd.upc
	AND pca.StartDate = pbh.StartDate
WHERE
	pbd.BatchId = @batchId
GROUP BY
	pbd.upc
SET NOCOUNT OFF

SELECT
	pbd.BatchPriceMethod
	,pbd.BatchSpecialPrice
	,pbd.BatchDealQty
	,RIGHT(pbd.CouponUPC,5) AS CouponUPC
	,pbd.PromoCode
	,pbd.ForcePosValid
	,pbd.Advertised
	,pbd.HasStarted
	,pbd.HasEnded
	,pbd.BatchMultiPriceGroup
	,pbd.BatchDealPrice
	,ISNULL(ppcoup.Price, 0.00) AS CouponPrice
	,ISNULL(ppcoup.PriceMethod, '') AS CouponPriceMethod
	,ISNULL(ppcoup.DealQty, 0) AS CouponDealQty
	,ISNULL(ppcoup.PriceMult, 0) AS CouponPriceMult
	,pbd.LabelBatchId

	,iv.UPC
	,iv.BrandName
	,iv.BrandItemDescription
	,iv.ProductSize
	,iv.ProductUOM
	,iv.DepartmentId
	,iv.DepartmentName
	,iv.PrimSupplier
	,iv.SupplierName
	,iv.suppliersku
	,iv.ProductType
	,iv.ProductTypeDescription
	,iv.PosValid
	,iv.SKU
	,iv.Pack
	,iv.RegMultiple
	,iv.RegPrice
	,iv.RegPM
	,iv.RegCPI
	,iv.CurrMultiple
	,iv.CurrPrice
	,iv.CurrPM
	,iv.ProductStatus
	,iv.ProductStatusDescription
	,iv.SupplierId
	,iv.SMI
	,iv.TaxA
	,iv.WIC AS IsWicItem
	,iv.FoodStamp
	,iv.CurrentCoupon
	,iv.ReportingCode
	,iv.QtyOnHand
	,iv.DepositUPC
	,iv.PriceRequired
	,iv.WeightPriceRequired
	,iv.QtyAllowed
	,iv.QtyRequired
	,iv.User1
	,iv.User2
	,iv.User3
	,iv.User4
	,iv.UserData1
	,iv.UserData2
	,iv.ProductAvailableDate
	,iv.POSDescription
	,iv.ItemLinkToDeposit
	,iv.LabelSize
	,iv.SectionId
	,iv.CategoryClassDesc
	,iv.LabelSizeDescription
	,iv.RestrictSaleHours
	,iv.ApplyPoints
	,iv.CouponMultiple
	,iv.CouponFamilyCurrent
	,iv.CouponFamilyPrevious
	,iv.TaxB
	,iv.TaxC
	,iv.TaxD

	,pbh.BatchId AS HeaderBatchId
	,pbh.Description AS HeaderBatchDescription
	,pbh.StartDate AS HeaderStartDate
	,pbh.EndDate AS HeaderEndDate

	,CASE
		WHEN pbd.BatchSpecialPrice = 0 THEN NULL
		WHEN iv.RegPrice = 0 THEN NULL
		WHEN (pbd.BatchDealQty/pbd.BatchSpecialPrice) - (iv.RegMultiple/iv.RegPrice) > 0 THEN 'D'
		WHEN (pbd.BatchDealQty/pbd.BatchSpecialPrice) - (iv.RegMultiple/iv.RegPrice) < 0 THEN 'U'
		ELSE 'S'
	END AS price_diff
	
	,iv.AisleName
	,iv.AisleSort
	,iv.PositionName
	,iv.PositionSort
	,iv.PositionSeq
	,iv.Wic
	,iv.LabelRequestDate
	,iv.SignRequestDate

	,ISNULL(ta.number_of_adjustments, 0) AS number_of_adjustments
	,ISNULL(ta.total_adjustment_amount, 0.00) AS total_adjustment_amount

FROM
	productbatchdetail pbd
INNER JOIN item_view iv ON
	iv.upc = pbd.upc
	AND iv.StoreId = @storeId
INNER JOIN productbatchheader pbh ON
	pbh.batchid = pbd.batchid
LEFT OUTER JOIN productprice ppcoup ON
	ppcoup.upc = pbd.couponupc
	AND ppcoup.pricetype='N'
	AND ppcoup.StoreId = @storeId
LEFT JOIN #tempAdjustment ta ON
	ta.upc = pbd.upc
WHERE
	pbd.batchid=@batchId

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ProductBatchDetail_SelectByCouponUpc]
	@couponUpc CHAR(13)
AS

SELECT
	pbh.BatchId
	,pbh.Description
	,pbh.StartDate
	,pbh.EndDate
	,pbd.Upc
	,iv.BrandName
	,iv.BrandItemDescription
	,iv.DepartmentName
	,iv.DepartmentId
	,iv.ProductSize
	,iv.ProductUom
	,pbd.BatchPriceMethod
	,pbd.BatchSpecialPrice
	,pbd.BatchDealQty
	,RIGHT(pbd.CouponUPC,5) AS CouponUpc
	,pbd.PromoCode
FROM
	productbatchdetail pbd
INNER JOIN productbatchheader pbh ON
	pbh.batchid = pbd.batchid
INNER JOIN item_view iv ON
	iv.upc = pbd.upc
WHERE
	couponupc = @couponUpc

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  PROCEDURE [dbo].[ProductBatchDetail_SelectByUpcStoreIdForItemMaintenance]
	@upc CHAR(13)
	,@storeId SMALLINT
AS

SELECT
	CONVERT(BIT, 
		CASE
			WHEN DATEDIFF(dd, pbh.StartDate, GETDATE()) >= 0 AND pbh.EndDate IS NOT NULL AND DATEDIFF(dd, pbh.EndDate, GETDATE()) <= 0 THEN 1
			WHEN DATEDIFF(dd, pbh.StartDate, GETDATE()) >= 0 AND pbh.EndDate IS NOT NULL AND DATEDIFF(dd, pbh.EndDate, GETDATE()) >= 0 THEN 0
			WHEN DATEDIFF(dd, pbh.StartDate, GETDATE()) BETWEEN 0 AND 6 AND pbh.EndDate IS NULL THEN 1
			ELSE 0
		END
	) AS Active
	,pbh.BatchId
	,pbh.StartDate
	,pbh.EndDate
	,pbh.Description As BatchDescr
	,pbd.BatchSpecialPrice AS BatchPrice
	,pbd.BatchDealQty AS BatchDq
	,RIGHT(pbd.CouponUpc, 5) AS Coup
	,coupPpn.Price AS CoupPrice
	,coupPpn.DealQty AS CoupDq
	,pbd.Advertised
	,pbd.BatchDealPrice
	,pbd.BatchPriceMethod
FROM 
	productbatchdetail pbd 
INNER JOIN productbatchheader pbh ON
	pbh.batchid = pbd.batchid
LEFT OUTER JOIN productprice coupPpn ON
	coupPpn.StoreId = @storeId
	AND coupPpn.upc = pbd.CouponUpc
	AND coupPpn.PriceType = 'N'
WHERE
	pbd.upc = @upc

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ProductBatchDetail_SelectSentCountsByBatchId]
	@batchId INT
AS

SET NOCOUNT ON
DECLARE @appliedCount INT
SELECT 
	@appliedCount = ISNULL(COUNT(UPC),0)
FROM
	ProductBatchDetail pbd
WHERE
	pbd.batchid = @batchId
	AND ISNULL(pbd.HasStarted, 0) = 1

DECLARE @unappliedCount INT
SELECT 
	@unappliedCount = ISNULL(COUNT(UPC),0)
FROM
	ProductBatchDetail pbd
WHERE
	pbd.batchid = @batchId
	AND ISNULL(pbd.HasStarted,0) <> 1 

SET NOCOUNT OFF
SELECT
	@appliedCount AS applied_count
	,@unappliedCount AS unapplied_count

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE       PROCEDURE [dbo].[ProfileDetail_SelectByProfileNumber]
	@profileNumber INT
AS

SELECT
	d.ScreenOrder
	,m.ScreenType
	,m.ScreenName
	,m.IsUpdatable
	,d.ViewOnly
	,m.DisplayColumn
	,m.ScreenPrompt
	,m.NumericMinVal
	,m.NumericMaxVal
	,m.StringMaxLength
	,m.ClrDataType
	,m.IsPosUpdate
	,m.FieldHelpText
	,m.TableName
FROM
	ProfileDetail d
INNER JOIN ProfileFieldMap m ON
	m.ScreenName = d.ScreenName
	AND m.ScreenType = d.ScreenType
	AND m.IsObsolete = 0
WHERE
	d.ProfileNumber = @profileNumber
ORDER BY 
	d.ScreenOrder

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SignBatch_PopulateByBatchIdStoreId] 
	@labelBatchId INT
	,@storeId INT
	,@skuLength INT = 13
	,@alwaysShowDecimals BIT = 0
AS

SET NOCOUNT ON

UPDATE lbd SET
	lbd.BrandName = p.BrandName
	,lbd.ItemDescr = p.ItemDescr
	,lbd.Size = p.Size
	,lbd.UomCd= p.UomCd
	,lbd.NormalPriceAmt = ppn.PriceAmt
	,lbd.NormalPriceMult = ppn.PriceMult
	,lbd.NormalFormattedPrice = CASE 
		WHEN ppn.PriceMult > 1 THEN CONVERT(VARCHAR, ppn.PriceMult) + '/' + 
			CASE
				WHEN ppn.PriceAmt < 1.00 THEN RIGHT(CONVERT(VARCHAR, CAST(ppn.PriceAmt AS SMALLMONEY)), 2) + CHAR(162)
				ELSE '$' + CASE
								WHEN @alwaysShowDecimals = 0 AND CAST(CAST(ppn.PriceAmt AS INT) AS SMALLMONEY)  = ppn.PriceAmt THEN CONVERT(VARCHAR, CAST(ppn.PriceAmt AS INT))
								ELSE CONVERT(VARCHAR, ppn.PriceAmt)
							END
			END
		ELSE 
			CASE
				WHEN ppn.PriceAmt < 1.00 THEN RIGHT(CONVERT(VARCHAR, CAST(ppn.PriceAmt AS SMALLMONEY)), 2) + CHAR(162)
				ELSE '$' + CASE
								WHEN @alwaysShowDecimals = 0 AND CAST(CAST(ppn.PriceAmt AS INT) AS SMALLMONEY)  = ppn.PriceAmt THEN CONVERT(VARCHAR, CAST(ppn.PriceAmt AS INT))
								ELSE CONVERT(VARCHAR, ppn.PriceAmt)
							END
			END
	END		
	,lbd.NormalPerUnitPrice = CASE
		WHEN p.Size = 0 THEN 0
		WHEN ppn.PriceMult = 0 THEN 0
		ELSE ppn.PriceAmt / ppn.PriceMult / p.Size
	END
	,lbd.SupplierId = sp.SupplierId
	,lbd.OrderCode = RIGHT(sp.OrderCode, @skuLength)
	,lbd.CasePack = sp.CasePack
	,lbd.IsDsd = s.IsDsd
	,lbd.IsDiscontinued = CASE
		WHEN p.ProductStatusCd = '3' THEN 1
		ELSE 0
	END
	,lbd.SoldAs = psign.SoldAs
	,lbd.DisplayBrand = psign.DisplayBrand
	,lbd.DisplayDescription = psign.DisplayDescription
	,lbd.DisplayComment1 = psign.DisplayComment1
	,lbd.DisplayComment2 = psign.DisplayComment2
	,lbd.DisplayComment3 = psign.DisplayComment3
	,lbd.ItemAttribute1 = psign.ItemAttribute1
	,lbd.ItemAttribute2 = psign.ItemAttribute2
	,lbd.ItemAttribute3 = psign.ItemAttribute3
	,lbd.ItemAttribute4 = psign.ItemAttribute4
	,lbd.ItemAttribute5 = psign.ItemAttribute5
	,lbd.ItemAttribute6 = psign.ItemAttribute6
	,lbd.ItemAttribute7 = psign.ItemAttribute7
	,lbd.ItemAttribute8 = psign.ItemAttribute8
	,lbd.ItemAttribute9 = psign.ItemAttribute9
	,lbd.ItemAttribute10 = psign.ItemAttribute10
	,lbd.GroupSizeRange = psign.GroupSizeRange
	,lbd.GroupBrandName = psign.GroupBrandName
	,lbd.GroupItemDescription = psign.GroupItemDescription
	,lbd.GroupPrintQty = psign.GroupPrintQty
	,lbd.LblSizeCd = CASE
		WHEN ISNULL(ps.LblSizeCd, '') = '' THEN 'S'
		ELSE ps.LblSizeCd
	END
	,lbd.ProductStatusCd = p.ProductStatusCd
	,lbd.ProductStatusDescr= pstatus.ProductStatusDescr
	,lbd.IsWic = regiss45.WIC_FG
	,lbd.GroUpcomment = psign.GroupComment
	,lbd.SizeAndUomCd = CASE
		WHEN CAST(CAST(p.Size AS INT) AS SMALLMONEY)  = p.Size THEN	CONVERT(VARCHAR, CAST(p.Size AS INT)) + ' ' + p.UomCd
		ELSE CONVERT(VARCHAR, CAST(p.Size AS NUMERIC(9,2))) + ' ' + p.UomCd
	END
	,lbd.SupplierName = s.SupplierName
	,lbd.IsDepositLink = CASE
		WHEN ISNULL(reg.ItemLinkToDeposit, 0) = 1 THEN 1
		ELSE 0
	END
	,lbd.SectionId = p.SectionId
	,lbd.DepartmentId = p.DepartmentId
	,lbd.Iss45ComparativeUomCd = u2.UomCd
	,lbd.Iss45ComparativePrice = dbo.fn_Iss45ComparativePrice(ppn.PriceAmt, ppn.PriceMult, p.Size, u.UomDescr, regiss45.CMPRTV_UOM, regIss45.UNIT_FACTOR) 
	,lbd.Iss45ComparativeUomDescr = CASE 
		WHEN regIss45.UNIT_FACTOR > 1 THEN CAST(regiss45.UNIT_FACTOR AS VARCHAR) + ' ' + dbo.fn_Iss45UomToDescr(regIss45.CMPRTV_UOM)
		ELSE dbo.fn_Iss45UomToDescr(regIss45.CMPRTV_UOM)
	END
	,lbd.UomDescr = u.UomDescr

FROM
	dbo.LblBatchDetail lbd
INNER JOIN Prod p ON
	p.Upc = lbd.Upc
INNER JOIN Uom u ON
	u.UomCd = p.UomCd
INNER JOIN ProductStatus pstatus ON
	pstatus.ProductStatusCd = p.ProductStatusCd
LEFT OUTER JOIN ProdPrice ppn ON
	ppn.Upc = lbd.Upc	
	AND ppn.StoreId = @storeId
	AND ppn.PriceType = 'N'
LEFT OUTER JOIN ProdStore ps ON
	ps.Upc = lbd.Upc
	AND ps.StoreId = @storeId
LEFT OUTER JOIN dbo.ProdPosIbmSa reg ON
	reg.Upc = lbd.Upc
	AND reg.StoreID = @storeId
LEFT OUTER JOIN SupplierProd sp ON
	sp.Upc = lbd.Upc
	AND sp.SupplierId = ps.PriSupplierId
LEFT OUTER JOIN Supplier s ON
	s.SupplierId = sp.SupplierId
LEFT OUTER JOIN ProdSign psign ON
	psign.Upc = lbd.Upc
LEFT OUTER JOIN dbo.ProdPosIss45 regIss45 ON
	regIss45.Upc = lbd.Upc
	AND regIss45.StoreId = @storeId
LEFT OUTER JOIN Uom u2 ON
	u2.AltUomNmbr = regiss45.CMPRTV_UOM
WHERE
	lbd.LblBatchId = @labelBatchId

DECLARE @batchId INT
DECLARE curBatchIds CURSOR FOR SELECT DISTINCT BatchId FROM LblBatchDetail WHERE LblBatchId = @labelBatchId
OPEN curBatchIds
FETCH NEXT FROM curBatchIds INTO @batchId
WHILE @@FETCH_STATUS = 0 BEGIN

	-- iterate over all items in the batch
	-- and do sign-specific stuff
	DECLARE @promoted_formatted_price VARCHAR(50)
	DECLARE @promoted_save_amount_text VARCHAR(50)
	DECLARE @promoted_comment VARCHAR(50)
	DECLARE @batchStartDate DATETIME
	DECLARE @batchEndDate DATETIME
	DECLARE @otherBatchId INT

	DECLARE curItems CURSOR FOR 
		SELECT 
			Upc 
		FROM 
			LblBatchDetail 
		WHERE 
			LblBatchId = @labelBatchId
			AND BatchId = @batchId

	OPEN curItems
	DECLARE @Upc CHAR(13)
	FETCH NEXT FROM curItems INTO @Upc
	WHILE @@FETCH_STATUS = 0 BEGIN
	
		DECLARE @tempUpc CHAR(11) 
		SET @tempUpc = RIGHT('00000000000' + @Upc, 11)
	
		SET @promoted_formatted_price = NULL
		SET @promoted_save_amount_text = NULL
		SET @promoted_comment = NULL
		SET @batchStartDate = NULL
		SET @batchEndDate = NULL

		EXEC PriceBatch_CalcPriceByUpc 
			@Upc, 
			@storeId, 
			@batchId, 
			@promoted_formatted_price OUTPUT, 	
			@promoted_save_amount_text OUTPUT, 
			@promoted_comment OUTPUT, 
			0, 
			@batchStartDate OUTPUT, 
			@batchEndDate OUTPUT,
			@otherBatchId OUTPUT
			,1 -- don't return the resultset
			,@alwaysShowDecimals
			

		-- if the item is not in any active batch, copy 'NormalFormattedPrice' to 'PromotedFormattedPrice'
		IF @promoted_formatted_price IS NULL BEGIN
			SELECT 
				@promoted_formatted_price = NormalFormattedPrice
			FROM
				LblBatchDetail
			WHERE
				LblBatchId= @labelBatchId
				AND Upc = @Upc
		END

		DECLARE @batchDealQty SMALLINT
		DECLARE @batchSpecialPrice SMALLMONEY
		DECLARE @batchDealPrice SMALLINT

		SELECT
			@batchDealQty = pbd.BatchDealQty
			,@batchSpecialPrice = pbd.BatchSpecialPrice
			,@batchDealPrice = pbd.BatchDealPrice
		FROM
			ProductBatchDetail AS pbd
		WHERE
			pbd.BatchId = @otherBatchId
			AND Upc = @Upc

		UPDATE ProductBatchDetail SET LabelBatchId = @labelBatchId 
			WHERE BatchId = @otherBatchId AND Upc = @Upc
	
		UPDATE lbd SET
			PromotedFormattedPrice = @promoted_formatted_price
			,PromotedSaveAmountText = @promoted_save_amount_text
			,PromotedComment = @promoted_comment
			,FormattedUpc = 
				SUBSTRING(@tempUpc, 1, 1) + '-' + 
				SUBSTRING(@tempUpc, 2, 5) + '-' + 
				SUBSTRING(@tempUpc, 7, 5) 

			,lbd.PromotedStartDate = pbh.StartDate
			,lbd.PromotedEndDate = pbh.EndDate
			,lbd.BatchId = pbh.BatchId
			,lbd.BatchDealQty = @batchDealQty
			,lbd.BatchSpecialPrice = @batchSpecialPrice
			,lbd.BatchDealPrice = @batchDealPrice
			,lbd.Iss45ComparativeUomCd = uom_CMPRTV.UomCd
			,lbd.Iss45ComparativePrice = dbo.fn_Iss45ComparativePrice(@batchSpecialPrice, @batchDealQty, lbd.Size, lbd.UomDescr, regiss45.CMPRTV_UOM, regiss45.UNIT_FACTOR) 
			,lbd.Iss45ComparativeUomDescr = CASE 
				WHEN regIss45.UNIT_FACTOR > 1 THEN CAST(regiss45.UNIT_FACTOR AS VARCHAR) + ' ' + dbo.fn_Iss45UomToDescr(regIss45.CMPRTV_UOM)
				ELSE dbo.fn_Iss45UomToDescr(regIss45.CMPRTV_UOM)
			END
		FROM
			LblBatchDetail lbd
		LEFT OUTER JOIN ProductBatchHeader pbh ON
			pbh.BatchId = lbd.BatchId
		LEFT OUTER JOIN ProdPosIss45 regIss45 ON
			regIss45.Upc = lbd.Upc
			AND regIss45.StoreId = @storeId
		LEFT OUTER JOIN Uom uom_cmprtv ON
			uom_cmprtv.AltUomNmbr = regIss45.CMPRTV_UOM

		WHERE
			lbd.LblBatchId = @labelBatchId
			AND lbd.Upc = @Upc
			AND lbd.BatchId = @batchId

	
		IF @batchId = -1 BEGIN
			-- use @batchId to get these fields then save them on LabelBatchDetail

			UPDATE LblBatchDetail SET
				PromotedStartDate = @batchStartDate
				,PromotedEndDate = @batchEndDate
				,BatchId = @otherBatchId
			WHERE
				LblBatchId = @labelBatchId
				AND Upc = @Upc
		END
		
		FETCH NEXT FROM curItems INTO @Upc
	END
	CLOSE curItems
	DEALLOCATE curItems

	FETCH NEXT FROM curBatchIds INTO @batchId
END
CLOSE curBatchIds
DEALLOCATE curBatchIds


SET NOCOUNT OFF
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[tc_ChangeRequest_Insert] ON [dbo].[ChangeRequest] FOR INSERT AS BEGIN

IF @@ROWCOUNT = 0 RETURN
IF dbo.fn_GetChangeTrackingMode() = 0 RETURN
INSERT INTO ChangesChangeRequest (StoreId, ChgType, ChgTmsp, SrcTable, TrgType, RequestTime, UserName, Upc, ColName) SELECT DISTINCT
	i.StoreId			-- StoreId
	,'C'				-- ChgType
	,GETDATE()			-- ChgTmsp
	,'ChangeRequest'	-- SrcTable
	,'I'				-- TrgType
	,i.RequestTime		-- RequestTime
	,i.UserName			-- UserName
	,i.Upc				-- Upc
	,i.ColName			-- ColName
FROM
	INSERTED i
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[ad_FutureProdRetail]
   ON [dbo].[FutureProdRetail] 
   AFTER DELETE
AS 
BEGIN

IF dbo.fn_GetAuditMode() = 0 BEGIN
	RETURN
END

SET NOCOUNT ON
DECLARE @now DATETIME
SET @now = GETDATE()
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime , 'Delete', ai.UserName, ai.AuditSource, 'PriceChange', Upc, 'Upc', d.Upc, NULL,  'Zone:' + CONVERT(VARCHAR, RzGrpDescr) + ', Segment:' + CONVERT(VARCHAR, rzs.RzSegDescr) + ', StartDt:' + CONVERT(VARCHAR, d.StartDt, 101) + ', Retail:' + CONVERT(VARCHAR, d.PriceMult) + '/'+ CONVERT(VARCHAR, d.PriceAmt), null
	FROM DELETED d CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN RetailZoneGroup rzg ON rzg.RzGrpId = d.RzGrpId
	INNER JOIN RetailZoneSegment rzs ON rzs.RzGrpId = d.RzGrpId AND rzs.RzSegId = d.RzSegId 
SET NOCOUNT OFF

END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[ai_FutureProdRetail]
   ON [dbo].[FutureProdRetail] 
   AFTER INSERT
AS 
BEGIN

IF dbo.fn_GetAuditMode() = 0 BEGIN
	RETURN
END

SET NOCOUNT ON

DECLARE @now DATETIME
SET @now = GETDATE()

INSERT ProductAudit(audit_time, audit_type, user_name, Source, Category, Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Insert', ai.UserName, ai.AuditSource, 'PriceChange', i.Upc, 'PriceChange', CONVERT(VARCHAR, i.PriceMult) + '/'+ CONVERT(VARCHAR, i.PriceAmt), '', 'Zone:' + CONVERT(VARCHAR, i.RzGrpId) + ', Segment:' + CONVERT(VARCHAR, i.RzSegId) + ', StartDt:' + CONVERT(VARCHAR, i.StartDt, 101), null
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
SET NOCOUNT OFF
END


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[au_FutureProdRetail]
   ON [dbo].[FutureProdRetail] 
   AFTER UPDATE
AS 
BEGIN

IF dbo.fn_GetAuditMode() = 0 BEGIN
	RETURN
END

SET NOCOUNT ON

DECLARE @now DATETIME
SET @now = GETDATE()

-- PriceAmt
INSERT ProductAudit(audit_time, audit_type, [user_name], Source, Category, Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'PriceChange', i.Upc, 'PriceAmt',  CONVERT(VARCHAR, i.PriceAmt),  CONVERT(VARCHAR, d.PriceAmt), 'Zone:' + CONVERT(VARCHAR, RzGrpDescr) + ', Segment:' + CONVERT(VARCHAR, rzs.RzSegDescr) + ', StartDt:' + CONVERT(VARCHAR, i.StartDt, 101) + ', Retail:' + CONVERT(VARCHAR, i.PriceMult) + '/'+ CONVERT(VARCHAR, i.PriceAmt), null
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai
	INNER JOIN RetailZoneGroup rzg ON rzg.RzGrpId = i.RzGrpId
	INNER JOIN RetailZoneSegment rzs ON rzs.RzGrpId = i.RzGrpId AND rzs.RzSegId = i.RzSegId 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.RzGrpId = i.RzGrpId AND d.RzSegId = i.RzSegId AND d.StartDt = i.StartDt
	WHERE ISNULL(d.PriceAmt,-1) <> ISNULL(i.PriceAmt,-1)

-- PriceMult
INSERT ProductAudit(audit_time, audit_type, [user_name], Source, Category, Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'PriceChange', i.Upc, 'PriceMult',  CONVERT(VARCHAR, i.PriceMult),  CONVERT(VARCHAR, d.PriceMult), 'Zone:' + CONVERT(VARCHAR, RzGrpDescr) + ', Segment:' + CONVERT(VARCHAR, rzs.RzSegDescr) + ', StartDt:' + CONVERT(VARCHAR, i.StartDt, 101) + ', Retail:' + CONVERT(VARCHAR, i.PriceMult) + '/'+ CONVERT(VARCHAR, i.PriceAmt), null
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN RetailZoneGroup rzg ON rzg.RzGrpId = i.RzGrpId
	INNER JOIN RetailZoneSegment rzs ON rzs.RzGrpId = i.RzGrpId AND rzs.RzSegId = i.RzSegId 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.RzGrpId = i.RzGrpId AND d.RzSegId = i.RzSegId AND d.StartDt = i.StartDt
	WHERE ISNULL(d.PriceMult,-1) <> ISNULL(i.PriceMult,-1)

-- MIX_MATCH_CD
INSERT ProductAudit(audit_time, audit_type, [user_name], Source, Category, Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'PriceChange', i.Upc, 'MixMatchCd', CAST(i.Iss45MIX_MATCH_CD AS VARCHAR) + ': ' + ISNULL(l1.MixMatchDescr,'(none)	'), CAST(d.Iss45MIX_MATCH_CD AS VARCHAR) + ': ' + ISNULL(l2.MixMatchDescr,'(none)	'), 'Zone:' + CONVERT(VARCHAR, RzGrpDescr) + ', Segment:' + CONVERT(VARCHAR, rzs.RzSegDescr) + ', StartDt:' + CONVERT(VARCHAR, i.StartDt, 101) + ', Retail:' + CONVERT(VARCHAR, i.PriceMult) + '/'+ CONVERT(VARCHAR, i.PriceAmt), null
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN RetailZoneGroup rzg ON rzg.RzGrpId = i.RzGrpId
	INNER JOIN RetailZoneSegment rzs ON rzs.RzGrpId = i.RzGrpId AND rzs.RzSegId = i.RzSegId 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.RzGrpId = i.RzGrpId AND d.RzSegId = i.RzSegId AND d.StartDt = i.StartDt
	LEFT OUTER JOIN Iss45MixMatch l1 ON l1.MixMatchCd = i.Iss45MIX_MATCH_CD
	LEFT OUTER JOIN Iss45MixMatch l2 ON l2.MixMatchCd = d.Iss45MIX_MATCH_CD
	WHERE ISNULL(i.Iss45MIX_MATCH_CD, 0) <> ISNULL(d.Iss45MIX_MATCH_CD, 0)

-- HasProcessed
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'PriceChange', i.Upc, 'HasProcessed', dbo.fn_FormatBitForAudit(i.HasProcessed), dbo.fn_FormatBitForAudit(d.HasProcessed), 'Zone:' + CONVERT(VARCHAR, RzGrpDescr) + ', Segment:' + CONVERT(VARCHAR, rzs.RzSegDescr) + ', StartDt:' + CONVERT(VARCHAR, i.StartDt, 101) + ', Retail:' + CONVERT(VARCHAR, i.PriceMult) + '/'+ CONVERT(VARCHAR, i.PriceAmt), null
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN RetailZoneGroup rzg ON rzg.RzGrpId = i.RzGrpId
	INNER JOIN RetailZoneSegment rzs ON rzs.RzGrpId = i.RzGrpId AND rzs.RzSegId = i.RzSegId 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.RzGrpId = i.RzGrpId AND d.RzSegId = i.RzSegId AND d.StartDt = i.StartDt
	WHERE ISNULL(i.HasProcessed,0) <> ISNULL(d.HasProcessed,0) 

-- BatchDescr
INSERT ProductAudit(audit_time, audit_type, [user_name], Source, Category, Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'PriceChange', i.Upc, 'BatchDescr',  CONVERT(VARCHAR, i.BatchDescr),  CONVERT(VARCHAR, d.BatchDescr), 'Zone:' + CONVERT(VARCHAR, RzGrpDescr) + ', Segment:' + CONVERT(VARCHAR, rzs.RzSegDescr) + ', StartDt:' + CONVERT(VARCHAR, i.StartDt, 101) + ', Retail:' + CONVERT(VARCHAR, i.PriceMult) + '/'+ CONVERT(VARCHAR, i.PriceAmt), null
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN RetailZoneGroup rzg ON rzg.RzGrpId = i.RzGrpId
	INNER JOIN RetailZoneSegment rzs ON rzs.RzGrpId = i.RzGrpId AND rzs.RzSegId = i.RzSegId 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.RzGrpId = i.RzGrpId AND d.RzSegId = i.RzSegId AND d.StartDt = i.StartDt
	WHERE ISNULL(i.BatchDescr,'') <> ISNULL(d.BatchDescr,'')

-- ExportTmsp
INSERT ProductAudit(audit_time, audit_type, [user_name], Source, Category, Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'PriceChange', i.Upc, 'ExportTmsp',  CONVERT(VARCHAR, i.PriceMult),  CONVERT(VARCHAR, d.PriceMult), 'Zone:' + CONVERT(VARCHAR, RzGrpDescr) + ', Segment:' + CONVERT(VARCHAR, rzs.RzSegDescr) + ', StartDt:' + CONVERT(VARCHAR, i.StartDt, 101) + ', Retail:' + CONVERT(VARCHAR, i.PriceMult) + '/'+ CONVERT(VARCHAR, i.PriceAmt), null
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN RetailZoneGroup rzg ON rzg.RzGrpId = i.RzGrpId
	INNER JOIN RetailZoneSegment rzs ON rzs.RzGrpId = i.RzGrpId AND rzs.RzSegId = i.RzSegId 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.RzGrpId = i.RzGrpId AND d.RzSegId = i.RzSegId AND d.StartDt = i.StartDt
	WHERE ISNULL(d.ExportTmsp,'') <> ISNULL(i.ExportTmsp,'')

SET NOCOUNT OFF
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE TRIGGER [dbo].[ad_InvoiceHeader]
   ON [dbo].[InvoiceHeader] 
   AFTER DELETE
AS 
BEGIN

IF dbo.fn_GetAuditMode() = 0 BEGIN
	RETURN
END

SET NOCOUNT ON
DECLARE @now DATETIME
SET @now = GETDATE()
INSERT InvoiceAudit (AuditTime, AuditType, UserName, Source, Category, InvId, StoreId, FieldName, NewValue, OldValue, ExtraInfo) 
	SELECT ai.AuditTime , 'Delete', ai.UserName, ai.AuditSource, 'InvoiceHeader', InvId, StoreId, d.SupplierId + '-' + s.SupplierName, CONVERT(VARCHAR, d.InvDt, 101), d.InvNmbr, ai.ExtraInfo
	FROM DELETED d CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN Supplier s ON s.SupplierId = d.SupplierId
SET NOCOUNT OFF
END



GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE TRIGGER [dbo].[au_InvoiceHeader]
   ON [dbo].[InvoiceHeader] 
   AFTER UPDATE
AS 
BEGIN

IF dbo.fn_GetAuditMode() = 0 BEGIN
	RETURN
END

SET NOCOUNT ON
DECLARE @now DATETIME
SET @now = GETDATE()

-- InvDt
INSERT InvoiceAudit (AuditTime, AuditType, UserName, Source, Category, InvId, StoreId, FieldName, NewValue, OldValue, ExtraInfo) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'InvoiceHeader', i.InvId, i.StoreId, 'InvDt', CONVERT(VARCHAR, i.InvDt, 101), CONVERT(VARCHAR, d.InvDt, 101), ai.ExtraInfo
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.InvId = i.InvId AND d.StoreId = i.StoreId
	WHERE ISNULL(d.InvDt,'1900-01-01') <> ISNULL(i.InvDt, '1900-01-01')

-- InvNmbr
INSERT InvoiceAudit (AuditTime, AuditType, UserName, Source, Category, InvId, StoreId, FieldName, NewValue, OldValue, ExtraInfo) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'InvoiceHeader', i.InvId, i.StoreId, 'InvNmbr', i.InvNmbr, d.InvNmbr, ai.ExtraInfo
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.InvId = i.InvId AND d.StoreId = i.StoreId
	WHERE ISNULL(d.InvNmbr,'') <> ISNULL(i.InvNmbr,'')

-- CreateDt
-- UserName
-- PoNmbr
-- SupplierId
-- DocType

-- DocStatus
INSERT InvoiceAudit (AuditTime, AuditType, UserName, Source, Category, InvId, StoreId, FieldName, NewValue, OldValue, ExtraInfo) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'InvoiceHeader', i.InvId, i.StoreId, 'DocStatus', i.DocStatus, d.DocStatus, ai.ExtraInfo
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.InvId = i.InvId AND d.StoreId = i.StoreId
	WHERE ISNULL(d.DocStatus, -1) <> ISNULL(i.DocStatus, -1)

-- DepartmentId
-- StoreCaseQty
-- StoreUnitQty
-- StoreWgtQty

-- StoreExtCost
INSERT InvoiceAudit (AuditTime, AuditType, UserName, Source, Category, InvId, StoreId, FieldName, NewValue, OldValue, ExtraInfo) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'InvoiceHeader', i.InvId, i.StoreId, 'StoreExtCost', i.StoreExtCost, d.StoreExtCost, ai.ExtraInfo
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.InvId = i.InvId AND d.StoreId = i.StoreId
	WHERE ISNULL(d.StoreExtCost, -1) <> ISNULL(i.StoreExtCost, -1)

-- SuppCaseQty
-- SuppUnitQty
-- SuppWgtQty
-- SuppExtCost

-- ChargeAmt
INSERT InvoiceAudit (AuditTime, AuditType, UserName, Source, Category, InvId, StoreId, FieldName, NewValue, OldValue, ExtraInfo) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'InvoiceHeader', i.InvId, i.StoreId, 'ChargeAmt', i.ChargeAmt, d.ChargeAmt, ai.ExtraInfo
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.InvId = i.InvId AND d.StoreId = i.StoreId
	WHERE ISNULL(d.ChargeAmt, -1) <> ISNULL(i.ChargeAmt, -1)

-- DealAmt
INSERT InvoiceAudit (AuditTime, AuditType, UserName, Source, Category, InvId, StoreId, FieldName, NewValue, OldValue, ExtraInfo) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'InvoiceHeader', i.InvId, i.StoreId, 'DealAmt', i.DealAmt, d.DealAmt, ai.ExtraInfo
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.InvId = i.InvId AND d.StoreId = i.StoreId
	WHERE ISNULL(d.DealAmt, -1) <> ISNULL(i.DealAmt, -1)

-- InvNote
INSERT InvoiceAudit (AuditTime, AuditType, UserName, Source, Category, InvId, StoreId, FieldName, NewValue, OldValue, ExtraInfo) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'InvoiceHeader', i.InvId, i.StoreId, 'InvNote', i.InvNote, d.InvNote, ai.ExtraInfo
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.InvId = i.InvId AND d.StoreId = i.StoreId
	WHERE ISNULL(d.InvNote, '') <> ISNULL(i.InvNote, '')

-- IsTotalsOnly

-- ExportStatus
INSERT InvoiceAudit (AuditTime, AuditType, UserName, Source, Category, InvId, StoreId, FieldName, NewValue, OldValue, ExtraInfo) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'InvoiceHeader', i.InvId, i.StoreId, 'ExportStatus', i.ExportStatus, d.ExportStatus, ai.ExtraInfo
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.InvId = i.InvId AND d.StoreId = i.StoreId
	WHERE ISNULL(d.ExportStatus, -1) <> ISNULL(i.ExportStatus, -1)

-- ExportCount
INSERT InvoiceAudit (AuditTime, AuditType, UserName, Source, Category, InvId, StoreId, FieldName, NewValue, OldValue, ExtraInfo) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'InvoiceHeader', i.InvId, i.StoreId, 'ExportCount', i.ExportCount, d.ExportCount, ai.ExtraInfo
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.InvId = i.InvId AND d.StoreId = i.StoreId
	WHERE ISNULL(d.ExportCount, -1) <> ISNULL(i.ExportCount, -1)

-- ExportTime
INSERT InvoiceAudit (AuditTime, AuditType, UserName, Source, Category, InvId, StoreId, FieldName, NewValue, OldValue, ExtraInfo) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'InvoiceHeader', i.InvId, i.StoreId, 'ExportTime', CONVERT(VARCHAR, i.ExportTime, 121), CONVERT(VARCHAR, d.ExportTime, 121), ai.ExtraInfo
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.InvId = i.InvId AND d.StoreId = i.StoreId
	WHERE ISNULL(d.ExportTime,'1900-01-01') <> ISNULL(i.ExportTime, '1900-01-01')

SET NOCOUNT OFF
END



GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[tc_InvoiceHeader_Update] ON [dbo].[InvoiceHeader] FOR UPDATE AS BEGIN
IF @@ROWCOUNT = 0 RETURN
IF dbo.fn_GetChangeTrackingMode() = 0 RETURN
INSERT INTO ChangesInvoiceHeader (StoreId, ChgType, ChgTmsp, SrcTable, TrgType, InvId) SELECT DISTINCT
	i.StoreId			-- StoreId
	,'C'				-- ChgType
	,GETDATE()			-- ChgTmsp
	,'InvoiceHeader'	-- SrcTable
	,'U'				-- TrgType
	,i.InvId			-- BatchId
FROM
	INSERTED i
WHERE
	i.DocStatus=2
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[tc_Iss45MemberProm_Delete] ON [dbo].[Iss45MemberProm] FOR DELETE AS BEGIN
IF @@ROWCOUNT = 0 RETURN
IF dbo.fn_GetChangeTrackingMode() = 0 RETURN
INSERT INTO ChangesIss45MemberProm (StoreId, ChgType, ChgTmsp, SrcTable, TrgType, MMBR_PROM_ID) SELECT DISTINCT
	d.StoreId			-- StoreId
	,'D'				-- ChgType
	,GETDATE()			-- ChgTmsp
	,'Iss45MemberProm'	-- SrcTable
	,'D'				-- TrgType
	,d.MMBR_PROM_ID		-- MMBR_PROM_ID
FROM
	DELETED d
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[tc_Iss45MemberProm_Update] ON [dbo].[Iss45MemberProm] FOR UPDATE AS BEGIN
IF @@ROWCOUNT = 0 RETURN
IF dbo.fn_GetChangeTrackingMode() = 0 RETURN
INSERT INTO ChangesIss45MemberProm (StoreId, ChgType, ChgTmsp, SrcTable, TrgType, MMBR_PROM_ID) SELECT DISTINCT
	i.StoreId			-- StoreId
	,'C'				-- ChgType
	,GETDATE()			-- ChgTmsp
	,'Iss45MemberProm'	-- SrcTable
	,'U'				-- TrgType
	,i.MMBR_PROM_ID		-- MMBR_PROM_ID
FROM
	INSERTED i
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[tc_Iss45MemberPromLink_Delete] ON [dbo].[Iss45MemberPromLink] FOR DELETE AS BEGIN
IF @@ROWCOUNT = 0 RETURN
IF dbo.fn_GetChangeTrackingMode() = 0 RETURN
INSERT INTO ChangesIss45MemberProm (StoreId, ChgType, ChgTmsp, SrcTable, TrgType, MMBR_PROM_ID) SELECT DISTINCT
	mp.StoreId				-- StoreId
	,'C'					-- ChgType
	,GETDATE()				-- ChgTmsp
	,'Iss45MemberPromLink'	-- SrcTable
	,'D'					-- TrgType
	,d.MMBR_PROM_ID			-- MMBR_PROM_ID
FROM
	DELETED d
INNER JOIN Iss45MemberProm mp ON
	mp.MMBR_PROM_ID = d.MMBR_PROM_ID
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[tc_Iss45MemberPromLink_Insert] ON [dbo].[Iss45MemberPromLink] FOR INSERT AS BEGIN
IF @@ROWCOUNT = 0 RETURN
IF dbo.fn_GetChangeTrackingMode() = 0 RETURN
INSERT INTO ChangesIss45MemberProm (StoreId, ChgType, ChgTmsp, SrcTable, TrgType, MMBR_PROM_ID) SELECT DISTINCT
	mp.StoreId				-- StoreId
	,'C'					-- ChgType
	,GETDATE()				-- ChgTmsp
	,'Iss45MemberPromLink'	-- SrcTable
	,'I'					-- TrgType
	,i.MMBR_PROM_ID			-- MMBR_PROM_ID
FROM
	INSERTED i
INNER JOIN Iss45MemberProm mp ON
	mp.MMBR_PROM_ID = i.MMBR_PROM_ID
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[tc_Iss45MemberPromLink_Update] ON [dbo].[Iss45MemberPromLink] FOR UPDATE AS BEGIN
IF @@ROWCOUNT = 0 RETURN
IF dbo.fn_GetChangeTrackingMode() = 0 RETURN
INSERT INTO ChangesIss45MemberProm (StoreId, ChgType, ChgTmsp, SrcTable, TrgType, MMBR_PROM_ID) SELECT DISTINCT
	mp.StoreId				-- StoreId
	,'C'					-- ChgType
	,GETDATE()				-- ChgTmsp
	,'Iss45MemberPromLink'	-- SrcTable
	,'U'					-- TrgType
	,i.MMBR_PROM_ID			-- MMBR_PROM_ID
FROM
	INSERTED i
INNER JOIN Iss45MemberProm mp ON
	mp.MMBR_PROM_ID = i.MMBR_PROM_ID
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[tc_OnHand_Insert] ON [dbo].[OnHand] FOR INSERT AS BEGIN
IF @@ROWCOUNT = 0 RETURN
IF dbo.fn_GetChangeTrackingMode() = 0 RETURN
INSERT INTO ChangesOnHand (StoreId, ChgType, ChgTmsp, SrcTable, TrgType, Upc) SELECT DISTINCT
	i.StoreId		-- StoreId
	,'C'			-- ChgType
	,GETDATE()		-- ChgTmsp
	,'OnHand'	-- SrcTable
	,'I'			-- TrgType
	,i.Upc			-- Upc
FROM
	INSERTED i
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[tc_OnHand_Update] ON [dbo].[OnHand] FOR UPDATE AS BEGIN
IF @@ROWCOUNT = 0 RETURN
IF dbo.fn_GetChangeTrackingMode() = 0 RETURN
INSERT INTO ChangesOnHand (StoreId, ChgType, ChgTmsp, SrcTable, TrgType, Upc) SELECT DISTINCT
	i.StoreId		-- StoreId
	,'C'			-- ChgType
	,GETDATE()		-- ChgTmsp
	,'OnHand'	-- SrcTable
	,'U'			-- TrgType
	,i.Upc			-- Upc
FROM
	INSERTED i
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


 
 CREATE TRIGGER [dbo].[ad_Prod]
   ON [dbo].[Prod] 
   AFTER DELETE
AS 
BEGIN

IF dbo.fn_GetAuditMode() = 0 BEGIN
	RETURN
END

SET NOCOUNT ON
DECLARE @now DATETIME
SET @now = GETDATE()
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime , 'Delete', ai.UserName, ai.AuditSource, 'Product', Upc, 'Upc', d.Upc, NULL, ai.ExtraInfo, NULL
	FROM DELETED d CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
SET NOCOUNT OFF

END




GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE TRIGGER [dbo].[ai_Prod]
   ON [dbo].[Prod] 
   AFTER INSERT
AS 
BEGIN

IF dbo.fn_GetAuditMode() = 0 BEGIN
	RETURN
END

SET NOCOUNT ON

DECLARE @now DATETIME
SET @now = GETDATE()

-- Upc
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime , 'Insert', ai.UserName, ai.AuditSource, 'Product', Upc, 'Upc', i.Upc, NULL, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
SET NOCOUNT OFF
END



GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE TRIGGER [dbo].[au_Prod]
   ON [dbo].[Prod] 
   AFTER UPDATE
AS 
BEGIN

IF dbo.fn_GetAuditMode() = 0 BEGIN
	RETURN
END

SET NOCOUNT ON
DECLARE @now DATETIME
SET @now = GETDATE()

-- BrandName
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Product', i.Upc, 'Brand', i.BrandName, d.BrandName, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.BrandName,0) <> ISNULL(i.BrandName,0)

-- ItemDescr
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Product', i.Upc, 'ItemDescription', i.ItemDescr, d.ItemDescr, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.ItemDescr,'') <> ISNULL(i.ItemDescr,'')

-- Size
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Product', i.Upc, 'ProductSize', i.Size, d.Size, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.Size,-1) <> ISNULL(i.Size,-1)

-- UomCd
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Product', i.Upc, 'ProductUom', i.UomCd, d.UomCd, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.UomCd,'') <> ISNULL(i.UomCd,'')

-- DepartmentId
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Product', i.Upc, 'Department', CAST(i.DepartmentId AS VARCHAR) + '-' + lu.DepartmentName, CAST(d.DepartmentId AS VARCHAR)+ '-' + lu2.DepartmentName, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	INNER JOIN Department lu ON lu.DepartmentId = i.DepartmentId 
	INNER JOIN Department lu2 ON lu2.DepartmentId = d.DepartmentId 
	WHERE ISNULL(d.DepartmentId,-1) <> ISNULL(i.DepartmentId,-1)

-- SectionId
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Product', i.Upc, 'SectionId', CAST(i.SectionId AS VARCHAR) + '-' + lu.CatClassDescr, CASt(d.SectionId AS VARCHAR) + '-' + lu2.CatClassDescr, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	INNER JOIN CatClass lu ON lu.CatClassId = i.SectionId
	INNER JOIN CatClass lu2 ON lu2.CatClassId = d.SectionId
	WHERE ISNULL(d.SectionId,-1) <> ISNULL(i.SectionId,-1)

-- ProductTypeCd
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Product', i.Upc, 'ProductType', lu.ProductTypeDescr, lu2.ProductTypeDescr, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	INNER JOIN ProductType lu ON lu.ProductTypeCd = i.ProductTypeCd 
	INNER JOIN ProductType lu2 ON lu2.ProductTypeCd = d.ProductTypeCd 
	WHERE ISNULL(d.ProductTypeCd,'') <> ISNULL(i.ProductTypeCd,'')

-- ProductStatusCd
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Product', i.Upc, 'ProductStatus', lu.ProductStatusDescr, lu2.ProductStatusDescr, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	INNER JOIN ProductStatus lu ON lu.ProductStatusCd = i.ProductStatusCd 
	INNER JOIN ProductStatus lu2 ON lu2.ProductStatusCd = d.ProductStatusCd 
	WHERE ISNULL(d.ProductStatusCd,'') <> ISNULL(i.ProductStatusCd,'')

-- ReceiveByWeight
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Product', i.Upc, 'ReceiveByWeight', CASE i.ReceiveByWeight WHEN 1 THEN 'Yes' ELSE 'No' END, CASE d.ReceiveByWeight WHEN 1 THEN 'Yes' ELSE 'No' END, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.ReceiveByWeight,0) <> ISNULL(i.ReceiveByWeight,0)

-- CreateDate NOT AUDITED

-- NewItemReviewDate
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Product', i.Upc, 'NewItemReviewDate', i.NewItemReviewDate, d.NewItemReviewDate, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.NewItemReviewDate,'1900-01-01') <> ISNULL(i.NewItemReviewDate,'1900-01-01')

-- StatusModifiedDate
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Product', i.Upc, 'StatusModifiedDate', i.StatusModifiedDate, d.StatusModifiedDate, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.StatusModifiedDate,'1900-01-01') <> ISNULL(i.StatusModifiedDate,'1900-01-01')

-- ProductAvailableDate
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Product', i.Upc, 'ProductAvailableDate', i.ProductAvailableDate, d.ProductAvailableDate, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.ProductAvailableDate,'1900-01-01') <> ISNULL(i.ProductAvailableDate,'1900-01-01')

-- RzGrpId
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Product', i.Upc, 'RetailZone', lu.RzGrpDescr, lu2.RzGrpDescr, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	INNER JOIN RetailZoneGroup lu ON lu.RzGrpId = i.RzGrpId
	INNER JOIN RetailZoneGroup lu2 ON lu2.RzGrpId = d.RzGrpId 
	WHERE ISNULL(d.RzGrpId,'') <> ISNULL(i.RzGrpId,'')

SET NOCOUNT OFF

END



GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[au_ProdPosIbmSa]
   ON [dbo].[ProdPosIbmSa] 
   AFTER UPDATE
AS 
BEGIN

IF dbo.fn_GetAuditMode() = 0 BEGIN
	RETURN
END

SET NOCOUNT ON

DECLARE @now DATETIME
SET @now = GETDATE()

-- PosDescription
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'PosDescription', i.PosDescription, d.PosDescription, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.POSDescription,'') <> ISNULL(i.POSDescription,'')

-- Advertized
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'Advertized', dbo.fn_FormatBitForAudit(i.Advertized), dbo.fn_FormatBitForAudit(d.Advertized), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.Advertized,0) <> ISNULL(i.Advertized,0)

-- KeepItemMovement
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'KeepItemMovement', dbo.fn_FormatBitForAudit(i.KeepItemMovement), dbo.fn_FormatBitForAudit(d.KeepItemMovement), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.KeepItemMovement,0) <> ISNULL(i.KeepItemMovement,0)

-- PriceRequired
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'PriceRequired', dbo.fn_FormatBitForAudit(i.PriceRequired), dbo.fn_FormatBitForAudit(d.PriceRequired), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.PriceRequired,0) <> ISNULL(i.PriceRequired,0)

-- WeightPriceRequired
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'WeightPriceRequired', dbo.fn_FormatBitForAudit(i.WeightPriceRequired), dbo.fn_FormatBitForAudit(d.WeightPriceRequired), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.WeightPriceRequired,0) <> ISNULL(i.WeightPriceRequired,0)

-- CouponFamilyCurrent
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'CouponFamilyCurrent', i.CouponFamilyCurrent, d.CouponFamilyCurrent, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.CouponFamilyCurrent,0) <> ISNULL(i.CouponFamilyCurrent,0)

-- CouponFamilyPrevious
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'CouponFamilyPrevious', i.CouponFamilyPrevious, d.CouponFamilyPrevious, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.CouponFamilyPrevious,0) <> ISNULL(i.CouponFamilyPrevious,0)

-- Discountable
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'Discountable', dbo.fn_FormatBitForAudit(i.Discountable), dbo.fn_FormatBitForAudit(d.Discountable), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.Discountable,0) <> ISNULL(i.Discountable,0)

-- CouponMultiple
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'CouponMultiple', dbo.fn_FormatBitForAudit(i.CouponMultiple), dbo.fn_FormatBitForAudit(d.CouponMultiple), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.CouponMultiple,0) <> ISNULL(i.CouponMultiple,0)

-- ExceptLogItemSale
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'ExceptLogItemSale', dbo.fn_FormatBitForAudit(i.ExceptLogItemSale), dbo.fn_FormatBitForAudit(d.ExceptLogItemSale), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.ExceptLogItemSale,0) <> ISNULL(i.ExceptLogItemSale,0)

-- QtyAllowed
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'QtyAllowed', dbo.fn_FormatBitForAudit(i.QtyAllowed), dbo.fn_FormatBitForAudit(d.QtyAllowed), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.QtyAllowed,0) <> ISNULL(i.QtyAllowed,0)

-- QtyRequired
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'QtyRequired', dbo.fn_FormatBitForAudit(i.QtyRequired), dbo.fn_FormatBitForAudit(d.QtyRequired), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.QtyRequired,0) <> ISNULL(i.QtyRequired,0)

-- AuthSale
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'AuthSale', dbo.fn_FormatBitForAudit(i.AuthSale), dbo.fn_FormatBitForAudit(d.AuthSale), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.AuthSale,0) <> ISNULL(i.AuthSale,0)

-- RestrictSaleHours
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'RestrictSaleHours', dbo.fn_FormatBitForAudit(i.RestrictSaleHours), dbo.fn_FormatBitForAudit(d.RestrictSaleHours), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.RestrictSaleHours,0) <> ISNULL(i.RestrictSaleHours,0)

-- TerminalItemRecord
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'TerminalItemRecord', dbo.fn_FormatBitForAudit(i.TerminalItemRecord), dbo.fn_FormatBitForAudit(d.TerminalItemRecord), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.TerminalItemRecord,0) <> ISNULL(i.TerminalItemRecord,0)

-- AllowPrint
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'AllowPrint', dbo.fn_FormatBitForAudit(i.AllowPrint), dbo.fn_FormatBitForAudit(d.AllowPrint), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.AllowPrint,0) <> ISNULL(i.AllowPrint,0)

-- User1
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'User1', dbo.fn_FormatBitForAudit(i.User1), dbo.fn_FormatBitForAudit(d.User1), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.User1,0) <> ISNULL(i.User1,0)

-- User2
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'User2', dbo.fn_FormatBitForAudit(i.User2), dbo.fn_FormatBitForAudit(d.User2), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.User2,0) <> ISNULL(i.User2,0)

-- User3
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'User3', dbo.fn_FormatBitForAudit(i.User3), dbo.fn_FormatBitForAudit(d.User3), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.User3,0) <> ISNULL(i.User3,0)

-- User4
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'User4', dbo.fn_FormatBitForAudit(i.User4), dbo.fn_FormatBitForAudit(d.User4), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.User4,0) <> ISNULL(i.User4,0)

-- UserData1
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'UserData1', i.UserData1, d.UserData1, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.UserData1,0) <> ISNULL(i.UserData1,0)

-- UserData2
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'UserData2', i.UserData2, d.UserData2, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.UserData2,0) <> ISNULL(i.UserData2,0)

-- ApplyPoints
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'ApplyPoints', dbo.fn_FormatBitForAudit(i.ApplyPoints), dbo.fn_FormatBitForAudit(d.ApplyPoints), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.ApplyPoints,0) <> ISNULL(i.ApplyPoints,0)

-- LinkCode
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'LinkCode', i.LinkCode, d.LinkCode, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.LinkCode,0) <> ISNULL(i.LinkCode,0)

-- ItemLinkToDeposit
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'ItemLinkToDeposit', dbo.fn_FormatBitForAudit(i.ItemLinkToDeposit), dbo.fn_FormatBitForAudit(d.ItemLinkToDeposit), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.ItemLinkToDeposit,0) <> ISNULL(i.ItemLinkToDeposit,0)

-- FoodStamp
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'FoodStamp', dbo.fn_FormatBitForAudit(i.FoodStamp), dbo.fn_FormatBitForAudit(d.FoodStamp), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.FoodStamp,0) <> ISNULL(i.FoodStamp,0)

-- TradingStamp
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'TradingStamp', dbo.fn_FormatBitForAudit(i.TradingStamp), dbo.fn_FormatBitForAudit(d.TradingStamp), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.TradingStamp,0) <> ISNULL(i.TradingStamp,0)

-- Wic
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'Wic', dbo.fn_FormatBitForAudit(i.Wic), dbo.fn_FormatBitForAudit(d.Wic), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.Wic,0) <> ISNULL(i.Wic,0)

-- TaxA
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'TaxA', dbo.fn_FormatBitForAudit(i.TaxA), dbo.fn_FormatBitForAudit(d.TaxA), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.TaxA,0) <> ISNULL(i.TaxA,0)

-- TaxB
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'TaxB', dbo.fn_FormatBitForAudit(i.TaxB), dbo.fn_FormatBitForAudit(d.TaxB), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.TaxB,0) <> ISNULL(i.TaxB,0)

-- TaxC
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'TaxC', dbo.fn_FormatBitForAudit(i.TaxC), dbo.fn_FormatBitForAudit(d.TaxC), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.TaxC,0) <> ISNULL(i.TaxC,0)

-- TaxD
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'TaxD', dbo.fn_FormatBitForAudit(i.TaxD), dbo.fn_FormatBitForAudit(d.TaxD), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.TaxD,0) <> ISNULL(i.TaxD,0)

-- TaxE
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'TaxE', dbo.fn_FormatBitForAudit(i.TaxE), dbo.fn_FormatBitForAudit(d.TaxE), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.TaxE,0) <> ISNULL(i.TaxE,0)

-- TaxF
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'TaxF', dbo.fn_FormatBitForAudit(i.TaxF), dbo.fn_FormatBitForAudit(d.TaxF), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.TaxF,0) <> ISNULL(i.TaxF,0)

-- QhpQualifiedHealthcareItem
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'QhpQualifiedHealthcareItem', dbo.fn_FormatBitForAudit(i.QhpQualifiedHealthcareItem), dbo.fn_FormatBitForAudit(d.QhpQualifiedHealthcareItem), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.QhpQualifiedHealthcareItem,0) <> ISNULL(i.QhpQualifiedHealthcareItem,0)

-- RxPrescriptionItem
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'RxPrescriptionItem', dbo.fn_FormatBitForAudit(i.RxPrescriptionItem), dbo.fn_FormatBitForAudit(d.RxPrescriptionItem), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.RxPrescriptionItem,0) <> ISNULL(i.RxPrescriptionItem,0)

-- WicCvv
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'WicCvv', dbo.fn_FormatBitForAudit(i.WicCvv), dbo.fn_FormatBitForAudit(d.WicCvv), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.WicCvv,0) <> ISNULL(i.WicCvv,0)

-- DepositUpc
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'WicCvv', i.DepositUpc, d.DepositUpc, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.DepositUpc,'') <> ISNULL(i.DepositUpc,'')

-- CouponUpc
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'WicCvv', i.CouponUpc, d.CouponUpc, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.CouponUpc,'') <> ISNULL(i.CouponUpc,'')

-- ReportingCode
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'WicCvv', i.ReportingCode, d.ReportingCode, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.ReportingCode,'') <> ISNULL(i.ReportingCode,'')


SET NOCOUNT OFF

END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[tc_ProdPosIbmSa_Insert] ON [dbo].[ProdPosIbmSa] FOR INSERT AS BEGIN
IF @@ROWCOUNT = 0 RETURN
IF dbo.fn_GetChangeTrackingMode() = 0 RETURN
INSERT INTO ChangesProdPosIbmSa (StoreId, ChgType, ChgTmsp, SrcTable, TrgType, Upc) SELECT DISTINCT
	i.StoreId		-- StoreId
	,'C'			-- ChgType
	,GETDATE()		-- ChgTmsp
	,'ProdPosIbmSa'	-- SrcTable
	,'I'			-- TrgType
	,i.Upc			-- Upc
FROM
	INSERTED i
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[tc_ProdPosIbmSa_Update] ON [dbo].[ProdPosIbmSa] FOR UPDATE AS BEGIN
IF @@ROWCOUNT = 0 RETURN
IF dbo.fn_GetChangeTrackingMode() = 0 RETURN
INSERT INTO ChangesProdPosIbmSa (StoreId, ChgType, ChgTmsp, SrcTable, TrgType, Upc) SELECT DISTINCT
	i.StoreId		-- StoreId
	,'C'			-- ChgType
	,GETDATE()		-- ChgTmsp
	,'ProdPosIbmSa'	-- SrcTable
	,'U'			-- TrgType
	,i.Upc			-- Upc
FROM
	INSERTED i
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[au_ProdPosIss45]
   ON [dbo].[ProdPosIss45] 
   AFTER UPDATE
AS 
BEGIN

IF dbo.fn_GetAuditMode() = 0 BEGIN
	RETURN
END

SET NOCOUNT ON

DECLARE @now DATETIME
SET @now = GETDATE()


-- MSG_CD
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'MsgCd', i.MSG_CD, d.MSG_CD, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.MSG_CD, '') <> ISNULL(d.MSG_CD, '')

-- DSPL_DESCR
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'DsplDescr', i.DSPL_DESCR, d.DSPL_DESCR, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.DSPL_DESCR, '') <> ISNULL(d.DSPL_DESCR, '')

-- SLS_RESTRICT_GRP
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'SlsRestrictGrp', i.SLS_RESTRICT_GRP, d.SLS_RESTRICT_GRP, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.SLS_RESTRICT_GRP, '') <> ISNULL(d.SLS_RESTRICT_GRP, '')

-- RCPT_DESCR
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'RcptDescr', i.RCPT_DESCR, d.RCPT_DESCR, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.RCPT_DESCR, '') <> ISNULL(d.RCPT_DESCR, '')

-- NON_MDSE_ID
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'NonMdseId', i.NON_MDSE_ID, d.NON_MDSE_ID, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.NON_MDSE_ID, '') <> ISNULL(d.NON_MDSE_ID, '')

-- QTY_RQRD_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'QtyRqrdFg', dbo.fn_FormatBitForAudit(i.QTY_RQRD_FG), dbo.fn_FormatBitForAudit(d.QTY_RQRD_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.QTY_RQRD_FG, '') <> ISNULL(d.QTY_RQRD_FG, '')

-- SLS_AUTH_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'SlsAuthFg', dbo.fn_FormatBitForAudit(i.SLS_AUTH_FG), dbo.fn_FormatBitForAudit(d.SLS_AUTH_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.SLS_AUTH_FG, '') <> ISNULL(d.SLS_AUTH_FG, '')

-- FOOD_STAMP_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'FoodStampFg', dbo.fn_FormatBitForAudit(i.FOOD_STAMP_FG), dbo.fn_FormatBitForAudit(d.FOOD_STAMP_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.FOOD_STAMP_FG, '') <> ISNULL(d.FOOD_STAMP_FG, '')

-- WIC_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'WicFg', dbo.fn_FormatBitForAudit(i.WIC_FG), dbo.fn_FormatBitForAudit(d.WIC_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.WIC_FG, '') <> ISNULL(d.WIC_FG, '')

-- NG_ENTRY_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'NgEntryFg', dbo.fn_FormatBitForAudit(i.NG_ENTRY_FG), dbo.fn_FormatBitForAudit(d.NG_ENTRY_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.NG_ENTRY_FG, '') <> ISNULL(d.NG_ENTRY_FG, '')

-- STR_CPN_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'StrCpnFg', dbo.fn_FormatBitForAudit(i.STR_CPN_FG), dbo.fn_FormatBitForAudit(d.STR_CPN_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.STR_CPN_FG, '') <> ISNULL(d.STR_CPN_FG, '')

-- VEN_CPN_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'VenCpnFg', dbo.fn_FormatBitForAudit(i.VEN_CPN_FG), dbo.fn_FormatBitForAudit(d.VEN_CPN_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.VEN_CPN_FG, '') <> ISNULL(d.VEN_CPN_FG, '')

-- MAN_PRC_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'ManPrcFg', dbo.fn_FormatBitForAudit(i.MAN_PRC_FG), dbo.fn_FormatBitForAudit(d.MAN_PRC_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.MAN_PRC_FG, '') <> ISNULL(d.MAN_PRC_FG, '')

-- WGT_ITM_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'WgtItmFg', dbo.fn_FormatBitForAudit(i.WGT_ITM_FG), dbo.fn_FormatBitForAudit(d.WGT_ITM_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.WGT_ITM_FG, '') <> ISNULL(d.WGT_ITM_FG, '')

-- NON_DISC_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'NonDiscFg', dbo.fn_FormatBitForAudit(i.NON_DISC_FG), dbo.fn_FormatBitForAudit(d.NON_DISC_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.NON_DISC_FG, '') <> ISNULL(d.NON_DISC_FG, '')

-- COST_PLUS_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'CostPlusFg', dbo.fn_FormatBitForAudit(i.COST_PLUS_FG), dbo.fn_FormatBitForAudit(d.COST_PLUS_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.COST_PLUS_FG, '') <> ISNULL(d.COST_PLUS_FG, '')

-- PRC_VRFY_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'PrcVrfyFg', dbo.fn_FormatBitForAudit(i.PRC_VRFY_FG), dbo.fn_FormatBitForAudit(d.PRC_VRFY_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.PRC_VRFY_FG, '') <> ISNULL(d.PRC_VRFY_FG, '')

-- INHBT_QTY_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'InhbtQtyFg', dbo.fn_FormatBitForAudit(i.INHBT_QTY_FG), dbo.fn_FormatBitForAudit(d.INHBT_QTY_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.INHBT_QTY_FG, '') <> ISNULL(d.INHBT_QTY_FG, '')

-- DCML_QTY_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'DcmlQtyFg', dbo.fn_FormatBitForAudit(i.DCML_QTY_FG), dbo.fn_FormatBitForAudit(d.DCML_QTY_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.DCML_QTY_FG, '') <> ISNULL(d.DCML_QTY_FG, '')

-- TAX_RATE1_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'TaxRate1Fg', dbo.fn_FormatBitForAudit(i.TAX_RATE1_FG), dbo.fn_FormatBitForAudit(d.TAX_RATE1_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.TAX_RATE1_FG, '') <> ISNULL(d.TAX_RATE1_FG, '')

-- TAX_RATE2_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'TaxRate2Fg', dbo.fn_FormatBitForAudit(i.TAX_RATE2_FG), dbo.fn_FormatBitForAudit(d.TAX_RATE2_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.TAX_RATE2_FG, '') <> ISNULL(d.TAX_RATE2_FG, '')

-- TAX_RATE3_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'TaxRate3Fg', dbo.fn_FormatBitForAudit(i.TAX_RATE3_FG), dbo.fn_FormatBitForAudit(d.TAX_RATE3_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.TAX_RATE3_FG, '') <> ISNULL(d.TAX_RATE3_FG, '')

-- TAX_RATE4_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'TaxRate4Fg', dbo.fn_FormatBitForAudit(i.TAX_RATE4_FG), dbo.fn_FormatBitForAudit(d.TAX_RATE4_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.TAX_RATE4_FG, '') <> ISNULL(d.TAX_RATE4_FG, '')

-- TAX_RATE5_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'TaxRate5Fg', dbo.fn_FormatBitForAudit(i.TAX_RATE5_FG), dbo.fn_FormatBitForAudit(d.TAX_RATE5_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.TAX_RATE5_FG, '') <> ISNULL(d.TAX_RATE5_FG, '')

-- TAX_RATE6_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'TaxRate6Fg', dbo.fn_FormatBitForAudit(i.TAX_RATE6_FG), dbo.fn_FormatBitForAudit(d.TAX_RATE6_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.TAX_RATE6_FG, '') <> ISNULL(d.TAX_RATE6_FG, '')

-- TAX_RATE7_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'TaxRate5Fg', dbo.fn_FormatBitForAudit(i.TAX_RATE7_FG), dbo.fn_FormatBitForAudit(d.TAX_RATE7_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.TAX_RATE7_FG, '') <> ISNULL(d.TAX_RATE7_FG, '')

-- TAX_RATE8_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'TaxRate8Fg', dbo.fn_FormatBitForAudit(i.TAX_RATE8_FG), dbo.fn_FormatBitForAudit(d.TAX_RATE8_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.TAX_RATE8_FG, '') <> ISNULL(d.TAX_RATE8_FG, '')

-- MIX_MATCH_CD
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'MixMatchCd', CAST(i.MIX_MATCH_CD AS VARCHAR) + ': ' + ISNULL(l1.MixMatchDescr,'(none)	'), CAST(d.MIX_MATCH_CD AS VARCHAR) + ': ' + ISNULL(l2.MixMatchDescr, '(none)'), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	LEFT OUTER JOIN Iss45MixMatch l1 ON l1.MixMatchCd = i.MIX_MATCH_CD
	LEFT OUTER JOIN Iss45MixMatch l2 ON l2.MixMatchCd = d.MIX_MATCH_CD
	WHERE ISNULL(i.MIX_MATCH_CD, 0) <> ISNULL(d.MIX_MATCH_CD, 0)

-- RTN_CD
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'RtnCd', i.RTN_CD, d.RTN_CD, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.RTN_CD, '') <> ISNULL(d.RTN_CD, '')

-- FAMILY_CD
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'FamilyCd', i.FAMILY_CD, d.FAMILY_CD, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.FAMILY_CD, '') <> ISNULL(d.FAMILY_CD, '')

-- DISC_CD
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'DiscCd', i.DISC_CD, d.DISC_CD, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.DISC_CD, '') <> ISNULL(d.DISC_CD, '')

-- SCALE_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'ScaleFg', dbo.fn_FormatBitForAudit(i.SCALE_FG), dbo.fn_FormatBitForAudit(d.SCALE_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.SCALE_FG, '') <> ISNULL(d.SCALE_FG, '')

-- WGT_SCALE_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'WgtScaleFg', dbo.fn_FormatBitForAudit(i.WGT_SCALE_FG), dbo.fn_FormatBitForAudit(d.WGT_SCALE_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.WGT_SCALE_FG, '') <> ISNULL(d.WGT_SCALE_FG, '')

-- FREQ_SHOP_TYPE
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'FreqShopType', i.FREQ_SHOP_TYPE, d.FREQ_SHOP_TYPE, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.FREQ_SHOP_TYPE, '') <> ISNULL(d.FREQ_SHOP_TYPE, '')

-- FREQ_SHOP_VAL
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'FreqShopVal', i.FREQ_SHOP_VAL, d.FREQ_SHOP_VAL, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.FREQ_SHOP_VAL, '') <> ISNULL(d.FREQ_SHOP_VAL, '')

-- SEC_FAMILY
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'SecFamily', i.SEC_FAMILY, d.SEC_FAMILY, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.SEC_FAMILY, '') <> ISNULL(d.SEC_FAMILY, '')

-- POS_MSG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'PosMsg', i.POS_MSG, d.POS_MSG, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.POS_MSG, '') <> ISNULL(d.POS_MSG, '')

-- SHELF_LIFE_DAY
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'ShelfLifeDay', i.SHELF_LIFE_DAY, d.SHELF_LIFE_DAY, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.SHELF_LIFE_DAY, '') <> ISNULL(d.SHELF_LIFE_DAY, '')

-- CPN_NBR
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'CpnNbr', i.CPN_NBR, d.CPN_NBR, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.CPN_NBR, '') <> ISNULL(d.CPN_NBR, '')

-- TAR_WGT_NBR
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'TarWgtNbr', i.TAR_WGT_NBR, d.TAR_WGT_NBR, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.TAR_WGT_NBR, '') <> ISNULL(d.TAR_WGT_NBR, '')

-- CMPRTV_UOM
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'CmprtvUom', l1.UomDescr, l2.UomDescr, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	INNER JOIN Uom l1 ON l1.AltUomNmbr = i.CMPRTV_UOM
	INNER JOIN Uom l2 ON l2.AltUomNmbr = d.CMPRTV_UOM
	WHERE ISNULL(i.CMPRTV_UOM, '') <> ISNULL(d.CMPRTV_UOM, '')

-- CMPR_QTY
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'CmprQty', i.CMPR_QTY, d.CMPR_QTY, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.CMPR_QTY, '') <> ISNULL(d.CMPR_QTY, '')

-- CMPR_UNT
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'CmprUnt', i.CMPR_UNT, d.CMPR_UNT, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.CMPR_UNT, '') <> ISNULL(d.CMPR_UNT, '')

-- BNS_CPN_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'BnsCpnFg', dbo.fn_FormatBitForAudit(i.BNS_CPN_FG), dbo.fn_FormatBitForAudit(d.BNS_CPN_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.BNS_CPN_FG, '') <> ISNULL(d.BNS_CPN_FG, '')

-- EXCLUD_MIN_PURCH_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'ExcludMinPurchFg', dbo.fn_FormatBitForAudit(i.EXCLUD_MIN_PURCH_FG), dbo.fn_FormatBitForAudit(d.EXCLUD_MIN_PURCH_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.EXCLUD_MIN_PURCH_FG, '') <> ISNULL(d.EXCLUD_MIN_PURCH_FG, '')

-- FUEL_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'FuelFg', dbo.fn_FormatBitForAudit(i.FUEL_FG), dbo.fn_FormatBitForAudit(d.FUEL_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.FUEL_FG, '') <> ISNULL(d.FUEL_FG, '')

-- SPR_AUTH_RQRD_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'SprAuthRqrdFg', dbo.fn_FormatBitForAudit(i.SPR_AUTH_RQRD_FG), dbo.fn_FormatBitForAudit(d.SPR_AUTH_RQRD_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.SPR_AUTH_RQRD_FG, '') <> ISNULL(d.SPR_AUTH_RQRD_FG, '')

-- SSP_PRDCT_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'SspPrdctFg', dbo.fn_FormatBitForAudit(i.SSP_PRDCT_FG), dbo.fn_FormatBitForAudit(d.SSP_PRDCT_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.SSP_PRDCT_FG, '') <> ISNULL(d.SSP_PRDCT_FG, '')

-- FREQ_SHOP_LMT
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'FreqShipLmt', i.FREQ_SHOP_LMT, d.FREQ_SHOP_LMT, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.FREQ_SHOP_LMT, '') <> ISNULL(d.FREQ_SHOP_LMT, '')

-- DEA_GRP
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'DeaGrp', i.DEA_GRP, d.DEA_GRP, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.DEA_GRP, '') <> ISNULL(d.DEA_GRP, '')

-- BNS_BY_DESCR
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'BnsByDescr', i.BNS_BY_DESCR, d.BNS_BY_DESCR, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.BNS_BY_DESCR, '') <> ISNULL(d.BNS_BY_DESCR, '')

-- COMP_TYPE
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'CompType', i.COMP_TYPE, d.COMP_TYPE, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.COMP_TYPE, '') <> ISNULL(d.COMP_TYPE, '')

-- COMP_PRC
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'CompPrc', i.COMP_PRC, d.COMP_PRC, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.COMP_PRC, '') <> ISNULL(d.COMP_PRC, '')

-- COMP_QTY
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'CompQty', i.COMP_QTY, d.COMP_QTY, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.COMP_QTY, '') <> ISNULL(d.COMP_QTY, '')

-- ASSUME_QTY_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'AssumeQtyFg', dbo.fn_FormatBitForAudit(d.ASSUME_QTY_FG), dbo.fn_FormatBitForAudit(d.ASSUME_QTY_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.ASSUME_QTY_FG, '') <> ISNULL(d.ASSUME_QTY_FG, '')

-- ITM_POINT
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'ItmPoint', i.ITM_POINT, d.ITM_POINT, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.ITM_POINT, '') <> ISNULL(d.ITM_POINT, '')

-- PRC_GRP_ID
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'PrcGrpId', i.PRC_GRP_ID, d.PRC_GRP_ID, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.PRC_GRP_ID, '') <> ISNULL(d.PRC_GRP_ID, '')

-- SWW_CODE_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'SwwCodeFg', dbo.fn_FormatBitForAudit(i.SWW_CODE_FG), dbo.fn_FormatBitForAudit(d.SWW_CODE_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.SWW_CODE_FG, '') <> ISNULL(d.SWW_CODE_FG, '')

-- SHELF_STOCK_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'ShelfStockFg', dbo.fn_FormatBitForAudit(i.SHELF_STOCK_FG), dbo.fn_FormatBitForAudit(d.SHELF_STOCK_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.SHELF_STOCK_FG, '') <> ISNULL(d.SHELF_STOCK_FG, '')

-- PRNT_PLU_ID_RCPT_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'PrntPluIdRcptFg', dbo.fn_FormatBitForAudit(i.PRNT_PLU_ID_RCPT_FG), dbo.fn_FormatBitForAudit(d.PRNT_PLU_ID_RCPT_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.PRNT_PLU_ID_RCPT_FG, '') <> ISNULL(d.PRNT_PLU_ID_RCPT_FG, '')

-- BLK_GRP
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'BlkGrp', i.BLK_GRP, d.BLK_GRP, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.BLK_GRP, '') <> ISNULL(d.BLK_GRP, '')

-- EXCHANGE_TENDER_ID
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'ExchangeTenderId', i.EXCHANGE_TENDER_ID, d.EXCHANGE_TENDER_ID, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.EXCHANGE_TENDER_ID, '') <> ISNULL(d.EXCHANGE_TENDER_ID, '')

-- CAR_WASH_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'CarWashFg', dbo.fn_FormatBitForAudit(i.CAR_WASH_FG), dbo.fn_FormatBitForAudit(d.CAR_WASH_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.CAR_WASH_FG, '') <> ISNULL(d.CAR_WASH_FG, '')

-- PACKAGE_UOM
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'PackageUom', l1.UomDescr, l2.UomDescr, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	INNER JOIN Uom l1 ON l1.AltUomNmbr = i.PACKAGE_UOM
	INNER JOIN Uom l2 ON l2.AltUomNmbr = d.PACKAGE_UOM
	WHERE ISNULL(i.PACKAGE_UOM, '') <> ISNULL(d.PACKAGE_UOM, '')

-- UNIT_FACTOR
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'UnitFactor', i.UNIT_FACTOR, d.UNIT_FACTOR, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.UNIT_FACTOR, '') <> ISNULL(d.UNIT_FACTOR, '')

-- FS_QTY
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'FsQty', i.FS_QTY, d.FS_QTY, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.FS_QTY, '') <> ISNULL(d.FS_QTY, '')

-- NON_RX_HEALTH_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'NonRxHealthFg', dbo.fn_FormatBitForAudit(i.NON_RX_HEALTH_FG), dbo.fn_FormatBitForAudit(d.NON_RX_HEALTH_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.NON_RX_HEALTH_FG, '') <> ISNULL(d.NON_RX_HEALTH_FG, '')

-- RX_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'RxFg', dbo.fn_FormatBitForAudit(i.RX_FG), dbo.fn_FormatBitForAudit(d.RX_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.RX_FG, '') <> ISNULL(d.RX_FG, '')

-- EXEMPT_FROM_PROM_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'ExemptFromPromFg', dbo.fn_FormatBitForAudit(i.EXEMPT_FROM_PROM_FG), dbo.fn_FormatBitForAudit(d.EXEMPT_FROM_PROM_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.EXEMPT_FROM_PROM_FG, '') <> ISNULL(d.EXEMPT_FROM_PROM_FG, '')

-- WIC_CVV_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'WicCvvFg', dbo.fn_FormatBitForAudit(i.WIC_CVV_FG), dbo.fn_FormatBitForAudit(d.WIC_CVV_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.WIC_CVV_FG, '') <> ISNULL(d.WIC_CVV_FG, '')

-- LNK_NBR
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'LnkNbr', i.LNK_NBR, d.LNK_NBR, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.LNK_NBR, '') <> ISNULL(d.LNK_NBR, '')

-- SNAP_HIP_FG
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'SnapHipFg', dbo.fn_FormatBitForAudit(i.SNAP_HIP_FG), dbo.fn_FormatBitForAudit(d.SNAP_HIP_FG), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(i.SNAP_HIP_FG, '') <> ISNULL(d.SNAP_HIP_FG, '')
 
SET NOCOUNT OFF

END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[tc_ProdPosIss45_Insert] ON [dbo].[ProdPosIss45] FOR INSERT AS BEGIN
IF @@ROWCOUNT = 0 RETURN
IF dbo.fn_GetChangeTrackingMode() = 0 RETURN
INSERT INTO ChangesProdPosIss45 (StoreId, ChgType, ChgTmsp, SrcTable, TrgType, Upc) SELECT DISTINCT
	i.StoreId		-- StoreId
	,'C'			-- ChgType
	,GETDATE()		-- ChgTmsp
	,'ProdPosIss45'	-- SrcTable
	,'I'			-- TrgType
	,i.Upc			-- Upc
FROM
	INSERTED i
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[tc_ProdPosIss45_Update] ON [dbo].[ProdPosIss45] FOR UPDATE AS BEGIN
IF @@ROWCOUNT = 0 RETURN
IF dbo.fn_GetChangeTrackingMode() = 0 RETURN
INSERT INTO ChangesProdPosIss45 (StoreId, ChgType, ChgTmsp, SrcTable, TrgType, Upc) SELECT DISTINCT
	i.StoreId		-- StoreId
	,'C'			-- ChgType
	,GETDATE()		-- ChgTmsp
	,'ProdPosIss45'	-- SrcTable
	,'U'			-- TrgType
	,i.Upc			-- Upc
FROM
	INSERTED i
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[au_ProdPrice]
   ON [dbo].[ProdPrice] 
   AFTER UPDATE
AS 
BEGIN

IF dbo.fn_GetAuditMode() = 0 BEGIN
	RETURN
END

SET NOCOUNT ON

DECLARE @now DATETIME
SET @now = GETDATE()

-- PriceAmt
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Price', i.Upc, 'PriceAmt', CONVERT(VARCHAR, i.PriceAmt), CONVERT(VARCHAR, d.PriceAmt), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.PriceAmt,-1) <> ISNULL(i.PriceAmt,-1) AND i.PriceType <> 'C'

-- PriceMult
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Price', i.Upc, 'PriceMult', i.PriceMult, d.PriceMult, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.PriceMult,-1) <> ISNULL(i.PriceMult,-1) AND i.PriceType <> 'C'

-- IbmSaPriceMethod
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Price', i.Upc, 'IbmSaPriceMethod', i.IbmSaPriceMethod, d.IbmSaPriceMethod, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.IbmSaPriceMethod,'') <> ISNULL(i.IbmSaPriceMethod,'') AND i.PriceType <> 'C'

-- IbmSaMpGroup
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Price', i.Upc, 'IbmSaMpGroup', i.IbmSaMpGroup, d.IbmSaMpGroup, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.IbmSaMpGroup,-1) <> ISNULL(i.IbmSaMpGroup,-1) AND i.PriceType <> 'C'

-- IbmSaDealPrice
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Price', i.Upc, 'IbmSaDealPrice', CONVERT(VARCHAR, i.IbmSaDealPrice), CONVERT(VARCHAR, d.IbmSaDealPrice), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.IbmSaDealPrice,-1) <> ISNULL(i.IbmSaDealPrice,-1) AND i.PriceType <> 'C'

SET NOCOUNT OFF

END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[tc_ProdPrice_Insert] ON [dbo].[ProdPrice] FOR INSERT AS BEGIN
IF @@ROWCOUNT = 0 RETURN
IF dbo.fn_GetChangeTrackingMode() = 0 RETURN
INSERT INTO ChangesProdPrice (StoreId, ChgType, ChgTmsp, SrcTable, TrgType, Upc, PriceType) SELECT DISTINCT
	i.StoreId		-- StoreId
	,'C'			-- ChgType
	,GETDATE()		-- ChgTmsp
	,'ProdPrice'	-- SrcTable
	,'I'			-- TrgType
	,i.Upc			-- Upc
	,i.PriceType	-- PriceType
FROM
	INSERTED i
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[tc_ProdPrice_Update] ON [dbo].[ProdPrice] FOR UPDATE AS BEGIN
IF @@ROWCOUNT = 0 RETURN
IF dbo.fn_GetChangeTrackingMode() = 0 RETURN
INSERT INTO ChangesProdPrice (StoreId, ChgType, ChgTmsp, SrcTable, TrgType, Upc, PriceType) SELECT DISTINCT
	i.StoreId		-- StoreId
	,'C'			-- ChgType
	,GETDATE()		-- ChgTmsp
	,'ProdPrice'	-- SrcTable
	,'U'			-- TrgType
	,i.Upc			-- Upc
	,i.PriceType 	-- PriceType
FROM
	INSERTED i
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[au_ProdPriceZone]
   ON [dbo].[ProdPriceZone] 
   AFTER UPDATE
AS 
BEGIN

IF dbo.fn_GetAuditMode() = 0 BEGIN
	RETURN
END

SET NOCOUNT ON

DECLARE @now DATETIME
SET @now = GETDATE()

-- PriceAmt
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'ZonePrice', i.Upc, 'PriceAmt', i.PriceAmt, d.PriceAmt, 'Zone:' + rzg.RzGrpDescr + ', Seg:' + rzs.RzSegDescr, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.RzGrpId = i.RzGrpId AND d.RzSegId = i.RzSegId
	INNER JOIN RetailZoneSegment rzs ON rzs.RzGrpId = i.RzGrpId AND rzs.RzSegId = i.RzSegId
	INNER JOIN RetailZoneGroup rzg ON rzg.RzGrpId = i.RzGrpId
	WHERE ISNULL(d.PriceAmt,0) <> ISNULL(i.PriceAmt,0)

-- PriceMult
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'ZonePrice', i.Upc, 'PriceMult', i.PriceMult, d.PriceMult, 'Zone:' + rzg.RzGrpDescr + ', Seg:' + rzs.RzSegDescr, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.RzGrpId = i.RzGrpId AND d.RzSegId = i.RzSegId
	INNER JOIN RetailZoneSegment rzs ON rzs.RzGrpId = i.RzGrpId AND rzs.RzSegId = i.RzSegId
	INNER JOIN RetailZoneGroup rzg ON rzg.RzGrpId = i.RzGrpId
	WHERE ISNULL(d.PriceMult,0) <> ISNULL(i.PriceMult,0)

-- IbmSaPriceMethod
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'ZonePrice', i.Upc, 'IbmSaPriceMethod', i.IbmSaPriceMethod, d.IbmSaPriceMethod, 'Zone:' + rzg.RzGrpDescr + ', Seg:' + rzs.RzSegDescr, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.RzGrpId = i.RzGrpId AND d.RzSegId = i.RzSegId
	INNER JOIN RetailZoneSegment rzs ON rzs.RzGrpId = i.RzGrpId AND rzs.RzSegId = i.RzSegId
	INNER JOIN RetailZoneGroup rzg ON rzg.RzGrpId = i.RzGrpId
	WHERE ISNULL(d.IbmSaPriceMethod,0) <> ISNULL(i.IbmSaPriceMethod,0)

-- IbmSaMpGroup
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'ZonePrice', i.Upc, 'IbmSaMpGroup', i.IbmSaMpGroup, d.IbmSaMpGroup, 'Zone:' + rzg.RzGrpDescr + ', Seg:' + rzs.RzSegDescr, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.RzGrpId = i.RzGrpId AND d.RzSegId = i.RzSegId
	INNER JOIN RetailZoneSegment rzs ON rzs.RzGrpId = i.RzGrpId AND rzs.RzSegId = i.RzSegId
	INNER JOIN RetailZoneGroup rzg ON rzg.RzGrpId = i.RzGrpId
	WHERE ISNULL(d.IbmSaMpGroup,0) <> ISNULL(i.IbmSaMpGroup,0)

-- IbmSaDealPrice
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'ZonePrice', i.Upc, 'IbmSaDealPrice', i.IbmSaDealPrice, d.IbmSaDealPrice, 'Zone:' + rzg.RzGrpDescr + ', Seg:' + rzs.RzSegDescr, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.RzGrpId = i.RzGrpId AND d.RzSegId = i.RzSegId
	INNER JOIN RetailZoneSegment rzs ON rzs.RzGrpId = i.RzGrpId AND rzs.RzSegId = i.RzSegId
	INNER JOIN RetailZoneGroup rzg ON rzg.RzGrpId = i.RzGrpId
	WHERE ISNULL(d.IbmSaDealPrice,0) <> ISNULL(i.IbmSaDealPrice,0)

-- Iss45MIX_MATCH_CD
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'ZonePrice', i.Upc, 'Iss45MixMatchCd', CAST(i.Iss45MIX_MATCH_CD AS VARCHAR) + ': ' + ISNULL(l1.MixMatchDescr,'(none)	'), CAST(d.Iss45MIX_MATCH_CD AS VARCHAR) + ': ' + ISNULL(l2.MixMatchDescr, '(none)'), 'Zone:' + rzg.RzGrpDescr + ', Seg:' + rzs.RzSegDescr, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.RzGrpId = i.RzGrpId AND d.RzSegId = i.RzSegId
	INNER JOIN RetailZoneSegment rzs ON rzs.RzGrpId = i.RzGrpId AND rzs.RzSegId = i.RzSegId
	INNER JOIN RetailZoneGroup rzg ON rzg.RzGrpId = i.RzGrpId
	LEFT OUTER JOIN Iss45MixMatch l1 ON l1.MixMatchCd = i.Iss45MIX_MATCH_CD
	LEFT OUTER JOIN Iss45MixMatch l2 ON l2.MixMatchCd = d.Iss45MIX_MATCH_CD
	WHERE ISNULL(d.Iss45MIX_MATCH_CD,0) <> ISNULL(i.Iss45MIX_MATCH_CD,0)

SET NOCOUNT OFF

END


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE TRIGGER [dbo].[au_ProdSign]
   ON [dbo].[ProdSign] 
   AFTER UPDATE
AS 
BEGIN

IF dbo.fn_GetAuditMode() = 0 BEGIN
	RETURN
END

SET NOCOUNT ON

DECLARE @now DATETIME
SET @now = GETDATE()

-- ReviewedDate
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Sign', i.Upc, 'ReviewedDate', i.ReviewedDate, d.ReviewedDate, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.ReviewedDate,'19000101') <> ISNULL(i.ReviewedDate,'19000101')
-- SoldAs
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Sign', i.Upc, 'SoldAs', i.SoldAs, d.SoldAs, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.SoldAs,'') <> ISNULL(i.SoldAs,'')
-- DisplayBrand
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Sign', i.Upc, 'DisplayBrand', i.DisplayBrand, d.DisplayBrand, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.DisplayBrand,'') <> ISNULL(i.DisplayBrand,'')
-- DisplayDescription
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Sign', i.Upc, 'DisplayDescription', i.DisplayDescription, d.DisplayDescription, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.DisplayDescription,'') <> ISNULL(i.DisplayDescription,'')
-- DisplayComment1
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Sign', i.Upc, 'DisplayComment1', i.DisplayComment1, d.DisplayComment1, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.DisplayComment1,'') <> ISNULL(i.DisplayComment1,'')
-- DisplayComment2
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Sign', i.Upc, 'DisplayComment2', i.DisplayComment2, d.DisplayComment2, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.DisplayComment2,'') <> ISNULL(i.DisplayComment2,'')
-- DisplayComment3
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Sign', i.Upc, 'DisplayComment3', i.DisplayComment3, d.DisplayComment3, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.DisplayComment3,'') <> ISNULL(i.DisplayComment3,'')
-- ItemAttribute1
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Sign', i.Upc, 'ItemAttribute1', dbo.fn_FormatBitForAudit(i.ItemAttribute1), dbo.fn_FormatBitForAudit(d.ItemAttribute1), ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.ItemAttribute1,0) <> ISNULL(i.ItemAttribute1,0)
-- ItemAttribute2
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Sign', i.Upc, 'ItemAttribute2', dbo.fn_FormatBitForAudit(i.ItemAttribute2), dbo.fn_FormatBitForAudit(d.ItemAttribute2), ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.ItemAttribute2,0) <> ISNULL(i.ItemAttribute2,0)
-- ItemAttribute3
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Sign', i.Upc, 'ItemAttribute3', dbo.fn_FormatBitForAudit(i.ItemAttribute3), dbo.fn_FormatBitForAudit(d.ItemAttribute3), ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.ItemAttribute3,0) <> ISNULL(i.ItemAttribute3,0)
-- ItemAttribute4
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Sign', i.Upc, 'ItemAttribute4', dbo.fn_FormatBitForAudit(i.ItemAttribute4), dbo.fn_FormatBitForAudit(d.ItemAttribute4), ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.ItemAttribute4,0) <> ISNULL(i.ItemAttribute4,0)
-- ItemAttribute5
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Sign', i.Upc, 'ItemAttribute5', dbo.fn_FormatBitForAudit(i.ItemAttribute5), dbo.fn_FormatBitForAudit(d.ItemAttribute5), ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.ItemAttribute5,0) <> ISNULL(i.ItemAttribute5,0)
-- ItemAttribute6
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Sign', i.Upc, 'ItemAttribute6', dbo.fn_FormatBitForAudit(i.ItemAttribute6), dbo.fn_FormatBitForAudit(d.ItemAttribute6), ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.ItemAttribute6,0) <> ISNULL(i.ItemAttribute6,0)
-- ItemAttribute7
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Sign', i.Upc, 'ItemAttribute7', dbo.fn_FormatBitForAudit(i.ItemAttribute7), dbo.fn_FormatBitForAudit(d.ItemAttribute7), ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.ItemAttribute7,0) <> ISNULL(i.ItemAttribute7,0)
-- ItemAttribute8
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Sign', i.Upc, 'ItemAttribute8', dbo.fn_FormatBitForAudit(i.ItemAttribute8), dbo.fn_FormatBitForAudit(d.ItemAttribute8), ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.ItemAttribute8,0) <> ISNULL(i.ItemAttribute8,0)
-- ItemAttribute9
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Sign', i.Upc, 'ItemAttribute9', dbo.fn_FormatBitForAudit(i.ItemAttribute9), dbo.fn_FormatBitForAudit(d.ItemAttribute9), ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.ItemAttribute9,0) <> ISNULL(i.ItemAttribute9,0)
-- ItemAttribute10
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Sign', i.Upc, 'ItemAttribute10', dbo.fn_FormatBitForAudit(i.ItemAttribute10), dbo.fn_FormatBitForAudit(d.ItemAttribute10), ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.ItemAttribute10,0) <> ISNULL(i.ItemAttribute10,0)
-- GroupSizeRange
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Sign', i.Upc, 'GroupSizeRange', i.GroupSizeRange, d.GroupSizeRange, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.GroupSizeRange,'') <> ISNULL(i.GroupSizeRange,'')
-- GroupBrandName
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Sign', i.Upc, 'GroupBrandName', i.GroupBrandName, d.GroupBrandName, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.GroupBrandName,'') <> ISNULL(i.GroupBrandName,'')
-- GroupItemDescription
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Sign', i.Upc, 'GroupItemDescription', i.GroupItemDescription, d.GroupItemDescription, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.GroupItemDescription,'') <> ISNULL(i.GroupItemDescription,'')
-- GroupPrintQty
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Sign', i.Upc, 'GroupPrintQty', i.GroupPrintQty, d.GroupPrintQty, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.GroupPrintQty,0) <> ISNULL(i.GroupPrintQty,0)
-- GroupComment
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Sign', i.Upc, 'GroupComment', i.GroupComment, d.GroupComment, ai.ExtraInfo, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc
	WHERE ISNULL(d.GroupComment,'') <> ISNULL(i.GroupComment,'')

SET NOCOUNT OFF

END


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[au_ProdStore]
   ON [dbo].[ProdStore] 
   AFTER UPDATE
AS 
BEGIN

IF dbo.fn_GetAuditMode() = 0 BEGIN
	RETURN
END

SET NOCOUNT ON

DECLARE @now DateTime
SET @now = GETDATE()

-- PosValid
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'PosValid', dbo.fn_FormatBitForAudit(i.PosValid), dbo.fn_FormatBitForAudit(d.PosValid), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.PosValid,0) <> ISNULL(i.PosValid,0) 

-- PriSupplierId
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'PriSupplierId', i.PriSupplierId + ': ' + s1.SupplierName, d.PriSupplierId + ': ' + s2.SupplierName, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	LEFT OUTER JOIN Supplier s1 ON s1.SupplierId = i.PriSupplierId
    LEFT OUTER JOIN Supplier s2 ON s2.SupplierId = d.PriSupplierId
	WHERE ISNULL(d.PriSupplierId,'') <> ISNULL(i.PriSupplierId,'') 

-- CanReceive
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'CanReceive', dbo.fn_FormatBitForAudit(i.CanReceive), dbo.fn_FormatBitForAudit(d.CanReceive), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.CanReceive,0) <> ISNULL(i.CanReceive,0) 

-- QtyOnHand
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'QtyOnHand', i.QtyOnHand, d.QtyOnHand, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.QtyOnHand,-1) <> ISNULL(i.QtyOnHand,-1) 

-- OrderThreshold
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'OrderThreshold', i.OrderThreshold, d.OrderThreshold, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.OrderThreshold,-1) <> ISNULL(i.OrderThreshold,-1) 

-- InventoryCost
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'InventoryCost', CONVERT(VARCHAR, i.InventoryCost), CONVERT(VARCHAR, d.InventoryCost), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.InventoryCost,-1) <> ISNULL(i.InventoryCost,-1) 

-- LblSizeCd
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'LblSizeCd', i.LblSizeCd, d.LblSizeCd, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.LblSizeCd,'') <> ISNULL(i.LblSizeCd,'') 

-- LabelRequestDate
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'LabelRequestDate', i.LabelRequestDate, d.LabelRequestDate, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.LabelRequestDate,'') <> ISNULL(i.LabelRequestDate,'') 

-- SignRequestDate
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'SignRequestDate', i.SignRequestDate, d.SignRequestDate, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.SignRequestDate,'') <> ISNULL(i.SignRequestDate,'') 

-- NewItemReviewDate
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'NewItemReviewDate', i.NewItemReviewDate, d.NewItemReviewDate, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.NewItemReviewDate,'') <> ISNULL(i.NewItemReviewDate,'') 

-- LabelRequestUser
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'LabelRequestUser', i.LabelRequestUser, d.LabelRequestUser, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.LabelRequestUser,'') <> ISNULL(i.LabelRequestUser,'') 

-- SignRequestUser
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Pos', i.Upc, 'SignRequestUser', i.SignRequestUser, d.SignRequestUser, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.SignRequestUser,'') <> ISNULL(i.SignRequestUser,'') 

-- TargetGrossMargin
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Product', i.Upc, 'TargetGrossMargin', CONVERT(VARCHAR, i.TargetGrossMargin), CONVERT(VARCHAR, d.TargetGrossMargin), ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.TargetGrossMargin,-1) <> ISNULL(i.TargetGrossMargin,-1)

-- CustomPriceCd
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Price', i.Upc, 'CustomPriceCd', i.CustomPriceCd, d.CustomPriceCd, ai.ExtraInfo, i.StoreId 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.StoreId = i.StoreId
	WHERE ISNULL(d.CustomPriceCd,'') <> ISNULL(i.CustomPriceCd,'') 

SET NOCOUNT OFF

END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[tc_ProdStore_Insert] ON [dbo].[ProdStore] FOR INSERT AS BEGIN
IF @@ROWCOUNT = 0 RETURN
IF dbo.fn_GetChangeTrackingMode() = 0 RETURN
INSERT INTO ChangesProdStore (StoreId, ChgType, ChgTmsp, SrcTable, TrgType, Upc) SELECT DISTINCT
	i.StoreId		-- StoreId
	,'C'			-- ChgType
	,GETDATE()		-- ChgTmsp
	,'ProdStore'	-- SrcTable
	,'I'			-- TrgType
	,i.Upc			-- Upc
FROM
	INSERTED i
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[tc_ProdStore_Update] ON [dbo].[ProdStore] FOR UPDATE AS BEGIN
IF @@ROWCOUNT = 0 RETURN
IF dbo.fn_GetChangeTrackingMode() = 0 RETURN
INSERT INTO ChangesProdStore (StoreId, ChgType, ChgTmsp, SrcTable, TrgType, Upc) SELECT DISTINCT
	i.StoreId		-- StoreId
	,'C'			-- ChgType
	,GETDATE()		-- ChgTmsp
	,'ProdStore'	-- SrcTable
	,'U'			-- TrgType
	,i.Upc			-- Upc
FROM
	INSERTED i
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[tc_ProductBatchDetail_Delete] ON [dbo].[ProductBatchDetail] FOR DELETE AS BEGIN
IF @@ROWCOUNT = 0 RETURN
IF dbo.fn_GetChangeTrackingMode() = 0 RETURN
INSERT INTO ChangesPriceBatch (StoreId, ChgType, ChgTmsp, SrcTable, TrgType, BatchId, Description) SELECT DISTINCT
	h.StoreId				-- StoreId
	,'C'					-- ChgType
	,GETDATE()				-- ChgTmsp
	,'ProductBatchDetail'	-- SrcTable
	,'D'					-- TrgType
	,h.BatchId				-- BatchId
	,h.Description			-- Description
FROM
	DELETED d
INNER JOIN ProductBatchHeader h ON
	h.BatchId = d.BatchId
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[tc_ProductBatchDetail_Insert] ON [dbo].[ProductBatchDetail] FOR INSERT AS BEGIN
IF @@ROWCOUNT = 0 RETURN
IF dbo.fn_GetChangeTrackingMode() = 0 RETURN
INSERT INTO ChangesPriceBatch (StoreId, ChgType, ChgTmsp, SrcTable, TrgType, BatchId, Description) SELECT DISTINCT
	h.StoreId				-- StoreId
	,'C'					-- ChgType
	,GETDATE()				-- ChgTmsp
	,'ProductBatchDetail'	-- SrcTable
	,'I'					-- TrgType
	,h.BatchId				-- BatchId
	,h.Description			-- Description
FROM
	INSERTED i
INNER JOIN ProductBatchHeader h ON
	h.BatchId = i.BatchId
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[tc_ProductBatchDetail_Update] ON [dbo].[ProductBatchDetail] FOR UPDATE AS BEGIN
IF @@ROWCOUNT = 0 RETURN
IF dbo.fn_GetChangeTrackingMode() = 0 RETURN
INSERT INTO ChangesPriceBatch (StoreId, ChgType, ChgTmsp, SrcTable, TrgType, BatchId, Description) SELECT DISTINCT
	h.StoreId				-- StoreId
	,'C'					-- ChgType
	,GETDATE()				-- ChgTmsp
	,'ProductBatchDetail'	-- SrcTable
	,'U'					-- TrgType
	,h.BatchId				-- BatchId
	,h.Description			-- Description
FROM
	INSERTED i
INNER JOIN ProductBatchHeader h ON
	h.BatchId = i.BatchId
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[tc_ProductBatchHeader_Delete] ON [dbo].[ProductBatchHeader] FOR DELETE AS BEGIN
IF @@ROWCOUNT = 0 RETURN
IF dbo.fn_GetChangeTrackingMode() = 0 RETURN
INSERT INTO ChangesPriceBatch (StoreId, ChgType, ChgTmsp, SrcTable, TrgType, BatchId, Description) SELECT DISTINCT
	d.StoreId				-- StoreId
	,'D'					-- ChgType
	,GETDATE()				-- ChgTmsp
	,'ProductBatchHeader'	-- SrcTable
	,'D'					-- TrgType
	,d.BatchId				-- BatchId
	,d.Description			-- Description
FROM
	DELETED d
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[tc_ProductBatchHeader_Insert] ON [dbo].[ProductBatchHeader] FOR INSERT AS BEGIN
IF @@ROWCOUNT = 0 RETURN
IF dbo.fn_GetChangeTrackingMode() = 0 RETURN
INSERT INTO ChangesPriceBatch (StoreId, ChgType, ChgTmsp, SrcTable, TrgType, BatchId, Description) SELECT DISTINCT
	i.StoreId				-- StoreId
	,'C'					-- ChgType
	,GETDATE()				-- ChgTmsp
	,'ProductBatchHeader'	-- SrcTable
	,'I'					-- TrgType
	,i.BatchId				-- BatchId
	,i.Description			-- Description
FROM
	INSERTED i
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[tc_ProductBatchHeader_Update] ON [dbo].[ProductBatchHeader] FOR UPDATE AS BEGIN
IF @@ROWCOUNT = 0 RETURN
IF dbo.fn_GetChangeTrackingMode() = 0 RETURN
INSERT INTO ChangesPriceBatch (StoreId, ChgType, ChgTmsp, SrcTable, TrgType, BatchId, Description) SELECT DISTINCT
	i.StoreId				-- StoreId
	,'C'					-- ChgType
	,GETDATE()				-- ChgTmsp
	,'ProductBatchHeader'	-- SrcTable
	,'U'					-- TrgType
	,i.BatchId				-- BatchId
	,i.Description			-- Description
FROM
	INSERTED i
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    TRIGGER [dbo].[ti_SpartanOrderHeader] ON [dbo].[SpartanOrderHeader] FOR INSERT AS 
BEGIN

	SET NOCOUNT ON
	INSERT INTO SpartanOrderAudit (
		OrderId
		,AuditTime
		,AuditInfo
		,LoginName
	)
	SELECT
		OrderId
		,GETDATE()
		,'ORDER CREATED:  Supplier ' + SupplierId
		,ISNULL(SYSTEM_USER, 'n/a')
	FROM
		INSERTED
	SET NOCOUNT OFF

END










GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    TRIGGER [dbo].[tu_SpartanOrderHeader] ON [dbo].[SpartanOrderHeader] FOR UPDATE AS 
BEGIN

SET NOCOUNT ON

DECLARE @now DateTime
SET @now = GETDATE()

-- ConfirmationNumber
INSERT SpartanOrderAudit (OrderId, AuditTime, AuditInfo, LoginName) 
	SELECT i.OrderId, @now, 'Confirmation Number set to ' + i.ConfirmationNumber, ai.UserName 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.OrderId = i.OrderId
	WHERE ISNULL(d.ConfirmationNumber,'') <> ISNULL(i.ConfirmationNumber,'') 

-- PONumber
INSERT SpartanOrderAudit (OrderId, AuditTime, AuditInfo, LoginName) 
	SELECT i.OrderId, @now, 'PONumber set to ' + i.PONumber, ai.UserName 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.OrderId = i.OrderId
	WHERE ISNULL(d.PONumber,'') <> ISNULL(i.PONumber,'') 

-- OrderStatus 
INSERT SpartanOrderAudit (OrderId, AuditTime, AuditInfo, LoginName) 
	SELECT i.OrderId, @now, 'Order Status set to ' + CASE
				WHEN i.OrderStatus = '4' THEN '"Open" (4)'
				WHEN i.OrderStatus = '7' THEN '"Closed" (7)'
				WHEN i.OrderStatus = '14' THEN '"Sent" (14)'
				ELSE i.OrderStatus
			END, ai.UserName 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.OrderId = i.OrderId
	WHERE ISNULL(d.OrderStatus,'') <> ISNULL(i.OrderStatus,'') 

SET NOCOUNT OFF

END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[tc_SpartanPriceAuditDetail_Insert] ON [dbo].[SpartanPriceAuditDetail] FOR INSERT AS BEGIN
IF @@ROWCOUNT = 0 RETURN
IF dbo.fn_GetChangeTrackingMode() = 0 RETURN
INSERT INTO ChangesSpartanPriceAuditDetail (StoreId, ChgType, ChgTmsp, SrcTable, TrgType, AuditDate, Upc) SELECT DISTINCT
	i.StoreId					-- StoreId
	,'C'						-- ChgType
	,GETDATE()					-- ChgTmsp
	,'SpartanPriceAuditDetail'	-- SrcTable
	,'I'						-- TrgType
	,i.AuditDate				-- AuditDate
	,i.Upc						-- Upc
FROM
	INSERTED i
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[tc_SpartanPriceAuditDetail_Update] ON [dbo].[SpartanPriceAuditDetail] FOR UPDATE AS BEGIN
IF @@ROWCOUNT = 0 RETURN
IF dbo.fn_GetChangeTrackingMode() = 0 RETURN
INSERT INTO ChangesSpartanPriceAuditDetail (StoreId, ChgType, ChgTmsp, SrcTable, TrgType, AuditDate, Upc) SELECT DISTINCT
	i.StoreId					-- StoreId
	,'C'						-- ChgType
	,GETDATE()					-- ChgTmsp
	,'SpartanPriceAuditDetail'	-- SrcTable
	,'U'						-- TrgType
	,i.AuditDate				-- AuditDate
	,i.Upc						-- Upc
FROM
	INSERTED i
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[ad_SupplierProd]
   ON  [dbo].[SupplierProd]
   AFTER DELETE
AS 
BEGIN

IF dbo.fn_GetAuditMode() = 0 BEGIN
	RETURN
END

SET NOCOUNT ON

DECLARE @now DATETIME
SET @now = GETDATE()

INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime , 'Delete', ai.UserName, ai.AuditSource, 'Supplier', Upc, 'SupplierId', NULL, d.SupplierId, 'Unassigned ' + lu.SupplierId + '-' + lu.SupplierName, NULL
	FROM DELETED d CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN Supplier lu ON lu.SupplierId = d.SupplierId

SET NOCOUNT OFF

END


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[ai_SupplierProd]
   ON  [dbo].[SupplierProd]
   AFTER INSERT
AS 
BEGIN

IF dbo.fn_GetAuditMode() = 0 BEGIN
	RETURN
END

SET NOCOUNT ON

DECLARE @now DATETIME
SET @now = GETDATE()

INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime , 'Insert', ai.UserName, ai.AuditSource, 'Supplier', Upc, 'SupplierId', i.SupplierId, NULL, 'Assigned ' + lu.SupplierId + '-' + lu.SupplierName, NULL
	FROM inserted i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN Supplier lu ON lu.SupplierId = i.SupplierId

SET NOCOUNT OFF

END


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[au_SupplierProd]
   ON [dbo].[SupplierProd] 
   AFTER UPDATE
AS 
BEGIN

IF dbo.fn_GetAuditMode() = 0 BEGIN
	RETURN
END

SET NOCOUNT ON

DECLARE @now DATETIME
SET @now = GETDATE()


-- CasePack
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Supplier', i.Upc, 'CasePack', i.CasePack, d.CasePack, i.SupplierId + '-' + supp.SupplierName, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.SupplierId = i.SupplierId
	INNER JOIN Supplier supp ON supp.SupplierId = i.SupplierId
	WHERE ISNULL(d.CasePack,0) <> ISNULL(i.CasePack,0)

-- CaseUpc
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Supplier', i.Upc, 'CaseUpc', i.CaseUpc, d.CaseUpc, i.SupplierId + '-' + supp.SupplierName, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.SupplierId = i.SupplierId
	INNER JOIN Supplier supp ON supp.SupplierId = i.SupplierId
	WHERE ISNULL(d.CaseUpc,'') <> ISNULL(i.CaseUpc,'')

-- OrderCode
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Supplier', i.Upc, 'OrderCode', i.OrderCode, d.OrderCode, i.SupplierId + '-' + supp.SupplierName, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.SupplierId = i.SupplierId
	INNER JOIN Supplier supp ON supp.SupplierId = i.SupplierId
	WHERE ISNULL(d.OrderCode,'') <> ISNULL(i.OrderCode,'')

-- CaseWeight
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Supplier', i.Upc, 'CaseWeight', i.CaseWeight, d.CaseWeight, i.SupplierId + '-' + supp.SupplierName, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.SupplierId = i.SupplierId
	INNER JOIN Supplier supp ON supp.SupplierId = i.SupplierId
	WHERE ISNULL(d.CaseWeight,0) <> ISNULL(i.CaseWeight,0)

-- ShipTypeCd
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Supplier', i.Upc, 'ShipTypeCd', i.ShipTypeCd, d.ShipTypeCd, i.SupplierId + '-' + supp.SupplierName, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.SupplierId = i.SupplierId
	INNER JOIN Supplier supp ON supp.SupplierId = i.SupplierId
	WHERE ISNULL(d.ShipTypeCd,'') <> ISNULL(i.ShipTypeCd,'')

-- CrossDockCd
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Supplier', i.Upc, 'CrossDockCd', i.CrossDockCd, d.CrossDockCd, i.SupplierId + '-' + supp.SupplierName, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.SupplierId = i.SupplierId
	INNER JOIN Supplier supp ON supp.SupplierId = i.SupplierId
	WHERE ISNULL(d.CrossDockCd,'') <> ISNULL(i.CrossDockCd,'')
SET NOCOUNT OFF

END


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[au_SupplierProdZone]
   ON [dbo].[SupplierProdZone] 
   AFTER UPDATE
AS 
BEGIN

IF dbo.fn_GetAuditMode() = 0 BEGIN
	RETURN
END

SET NOCOUNT ON

DECLARE @now DATETIME
SET @now = GETDATE()


-- CaseCost
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Supplier', i.Upc, 'CaseCost', i.CaseCost, d.CaseCost, i.SupplierId + '-' + supp.SupplierName + ' ' + l1.SupplierZoneDescr, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.SupplierId = i.SupplierId
	INNER JOIN Supplier supp ON supp.SupplierId = i.SupplierId
	INNER JOIN SupplierZone l1 ON l1.SupplierId = i.SupplierId AND l1.SupplierZoneId = i.SupplierZoneId
	WHERE ISNULL(d.CaseCost,0) <> ISNULL(i.CaseCost,0)

-- DepositCharge
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Supplier', i.Upc, 'DepositCharge', i.DepositCharge, d.DepositCharge, i.SupplierId + '-' + supp.SupplierName + ' ' + l1.SupplierZoneDescr, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.SupplierId = i.SupplierId
	INNER JOIN Supplier supp ON supp.SupplierId = i.SupplierId
	INNER JOIN SupplierZone l1 ON l1.SupplierId = i.SupplierId AND l1.SupplierZoneId = i.SupplierZoneId
	WHERE ISNULL(d.DepositCharge,0) <> ISNULL(i.DepositCharge,0)

-- DepositDepartmentId
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Supplier', i.Upc, 'DepositDepartment', CAST(i.DepositDepartmentId AS VARCHAR) + '-' + lu.DepartmentName, CAST(d.DepositDepartmentId AS VARCHAR)+ '-' + lu2.DepartmentName, i.SupplierId + '-' + supp.SupplierName + ' ' + l1.SupplierZoneDescr, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.SupplierId = i.SupplierId
	INNER JOIN Supplier supp ON supp.SupplierId = i.SupplierId
	INNER JOIN SupplierZone l1 ON l1.SupplierId = i.SupplierId AND l1.SupplierZoneId = i.SupplierZoneId
	LEFT OUTER JOIN Department lu ON lu.DepartmentId = i.DepositDepartmentId
	LEFT OUTER JOIN Department lu2 ON lu2.DepartmentId = d.DepositDepartmentId
	WHERE ISNULL(d.DepositDepartmentId,'') <> ISNULL(i.DepositDepartmentId,'')

-- SplitCharge
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Supplier', i.Upc, 'SplitCharge', i.SplitCharge, d.SplitCharge, i.SupplierId + '-' + supp.SupplierName + ' ' + l1.SupplierZoneDescr, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.SupplierId = i.SupplierId
	INNER JOIN Supplier supp ON supp.SupplierId = i.SupplierId
	INNER JOIN SupplierZone l1 ON l1.SupplierId = i.SupplierId AND l1.SupplierZoneId = i.SupplierZoneId
	WHERE ISNULL(d.SplitCharge,0) <> ISNULL(i.SplitCharge,0)

-- SuggPriceAmt
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Supplier', i.Upc, 'SuggPriceAmt', i.SuggPriceAmt, d.SuggPriceAmt, i.SupplierId + '-' + supp.SupplierName + ' ' + l1.SupplierZoneDescr, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.SupplierId = i.SupplierId
	INNER JOIN Supplier supp ON supp.SupplierId = i.SupplierId
	INNER JOIN SupplierZone l1 ON l1.SupplierId = i.SupplierId AND l1.SupplierZoneId = i.SupplierZoneId
	WHERE ISNULL(d.SuggPriceAmt,0) <> ISNULL(i.SuggPriceAmt,0)

-- SuggPriceMult
INSERT ProductAudit (audit_time, audit_type, [user_name], [Source], [Category], Upc, FieldName, NewValue, OldValue, ExtraInfo, StoreId) 
	SELECT ai.AuditTime, 'Update', ai.UserName, ai.AuditSource, 'Supplier', i.Upc, 'SuggPriceMult', i.SuggPriceMult, d.SuggPriceMult, i.SupplierId + '-' + supp.SupplierName + ' ' + l1.SupplierZoneDescr, NULL 
	FROM INSERTED i CROSS JOIN dbo.fn_GetContextInfo(@now) ai 
	INNER JOIN DELETED d ON d.Upc = i.Upc AND d.SupplierId = i.SupplierId
	INNER JOIN Supplier supp ON supp.SupplierId = i.SupplierId
	INNER JOIN SupplierZone l1 ON l1.SupplierId = i.SupplierId AND l1.SupplierZoneId = i.SupplierZoneId
	WHERE ISNULL(d.SuggPriceMult,0) <> ISNULL(i.SuggPriceMult,0)

SET NOCOUNT OFF

END

GO
CREATE STATISTICS [Statistic_NewValue] ON [dbo].[ProductAudit]([NewValue], [row_id])
GO
CREATE STATISTICS [Statistic_OldValue] ON [dbo].[ProductAudit]([OldValue], [row_id])
GO
