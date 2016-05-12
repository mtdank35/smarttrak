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
CREATE FUNCTION [dbo].[fn_DateToDateKey] (@inputDate DATETIME)
RETURNS INT AS  
BEGIN 
	DECLARE @retVal INT
	SELECT @retVal = CONVERT(INT, CONVERT(VARCHAR, @inputDate, 112))
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
CREATE FUNCTION [dbo].[fn_SplitStores](@text varchar(8000), @delimiter varchar(20) = ' ')
RETURNS @entries TABLE
(   
	store_key INT
)
AS
BEGIN

IF @text IS NULL BEGIN
	INSERT INTO @entries SELECT store_key from store_dim
END ELSE BEGIN
	INSERT INTO @entries SELECT
		s.store_key
	FROM
		store_dim s
	INNER JOIN fn_Split(@text, @delimiter) AS vals ON
		vals.value = s.store_key
END

RETURN
END


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_SplitSubdepartments](@text varchar(8000), @delimiter varchar(20) = ' ')
RETURNS @entries TABLE
(   
	subdepartment_key INT
)
AS
BEGIN

IF @text IS NULL BEGIN
	INSERT INTO @entries SELECT subdepartment_key from subdepartment_dim
END ELSE BEGIN
	INSERT INTO @entries SELECT
		sd.subdepartment_key
	FROM
		subdepartment_dim sd
	INNER JOIN fn_Split(@text, @delimiter) AS vals ON
		vals.value = sd.subdepartment_key
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
CREATE TABLE [dbo].[audit_dupe_primary](
	[row_key] [int] IDENTITY(1,1) NOT NULL,
	[audit_date_key] [int] NOT NULL,
	[upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[storeid] [smallint] NOT NULL,
	[howmany_primary_supp] [int] NULL,
 CONSTRAINT [PK_audit_dupe_primary] PRIMARY KEY CLUSTERED 
(
	[row_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[audit_not_on_file](
	[row_key] [int] IDENTITY(1,1) NOT NULL,
	[tlog_file_key] [int] NOT NULL,
	[store_key] [int] NOT NULL,
	[terminal] [int] NOT NULL,
	[exception_timestamp] [datetime] NOT NULL,
	[operator] [int] NOT NULL,
	[item_code] [char](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_audit_not_on_file] PRIMARY KEY CLUSTERED 
(
	[row_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[audit_sales_adjustment](
	[row_key] [int] IDENTITY(1,1) NOT NULL,
	[tlog_date_key] [int] NOT NULL,
	[subdepartment_key] [int] NOT NULL,
	[store_key] [int] NOT NULL,
	[new_sales_dollar_amount] [decimal](9, 2) NOT NULL,
	[old_sales_dollar_amount] [decimal](9, 2) NOT NULL,
	[audit_date] [datetime] NOT NULL,
	[audit_user] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_audit_sales_adjustment] PRIMARY KEY CLUSTERED 
(
	[row_key] ASC
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
 CONSTRAINT [PK_batch_1] PRIMARY KEY NONCLUSTERED 
(
	[BatchId] ASC,
	[StoreId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
CREATE CLUSTERED INDEX [PK_Batch] ON [dbo].[Batch]
(
	[BatchId] ASC,
	[StoreId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BatchItem](
	[BatchId] [int] NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[DepartmentId] [smallint] NULL,
	[Qty] [decimal](18, 9) NOT NULL,
	[RegPriceAmt] [smallmoney] NULL,
	[RegPriceMult] [smallmoney] NULL,
	[RegUnitCost] [smallmoney] NULL,
	[SalePriceAmt] [smallmoney] NULL,
	[SalePriceMult] [smallmoney] NULL,
	[SaleUnitCost] [smallmoney] NULL,
	[Deposit] [decimal](18, 9) NOT NULL,
 CONSTRAINT [PK_BatchItem_2] PRIMARY KEY NONCLUSTERED 
(
	[BatchId] ASC,
	[StoreId] ASC,
	[Upc] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
CREATE CLUSTERED INDEX [PK_BatchItem] ON [dbo].[BatchItem]
(
	[BatchId] ASC,
	[Upc] ASC,
	[StoreId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[daily_bucket_sales](
	[tlog_date_key] [int] NOT NULL,
	[store_key] [int] NOT NULL,
	[subdepartment_key] [int] NOT NULL,
	[pricing_bucket_key] [int] NOT NULL,
	[tlog_file_key] [int] NOT NULL,
	[sales_dollar_amount] [decimal](10, 4) NOT NULL,
	[cost_dollar_amount] [decimal](10, 4) NOT NULL,
	[markdown_dollar_amount] [decimal](10, 4) NOT NULL,
	[regular_retail_sales_dollar_amount] [decimal](10, 4) NOT NULL,
	[base_cost_dollar_amount] [decimal](10, 4) NOT NULL
) ON [PRIMARY]

GO
CREATE UNIQUE CLUSTERED INDEX [PK_daily_bucket_sales] ON [dbo].[daily_bucket_sales]
(
	[tlog_date_key] ASC,
	[store_key] ASC,
	[subdepartment_key] ASC,
	[pricing_bucket_key] ASC,
	[tlog_file_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[daily_department_sales](
	[tlog_date_key] [int] NOT NULL,
	[store_key] [smallint] NOT NULL,
	[department_key] [smallint] NOT NULL,
	[tlog_file_key] [int] NOT NULL,
	[sales_dollar_amount] [numeric](9, 2) NOT NULL,
	[cost_dollar_amount] [numeric](18, 2) NOT NULL,
	[customer_count] [int] NOT NULL,
	[item_count] [int] NOT NULL,
 CONSTRAINT [PK_daily_department_sales] PRIMARY KEY CLUSTERED 
(
	[tlog_date_key] ASC,
	[store_key] ASC,
	[department_key] ASC,
	[tlog_file_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[daily_group_counts](
	[tlog_date_key] [int] NOT NULL,
	[store_key] [smallint] NOT NULL,
	[major_grouping] [char](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[tlog_file_key] [int] NOT NULL,
	[customer_count] [int] NOT NULL,
	[item_count] [int] NOT NULL,
 CONSTRAINT [PK_daily_group_counts] PRIMARY KEY CLUSTERED 
(
	[tlog_date_key] ASC,
	[store_key] ASC,
	[major_grouping] ASC,
	[tlog_file_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[daily_group_sales](
	[tlog_date_key] [int] NOT NULL,
	[store_key] [smallint] NOT NULL,
	[major_grouping] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[tlog_file_key] [int] NOT NULL,
	[sales_dollar_amount] [numeric](38, 2) NULL,
 CONSTRAINT [PK_daily_group_sales] PRIMARY KEY CLUSTERED 
(
	[tlog_date_key] ASC,
	[store_key] ASC,
	[major_grouping] ASC,
	[tlog_file_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[daily_sales_fact](
	[trans_date_key] [int] NOT NULL,
	[product_key] [int] NOT NULL,
	[store_key] [smallint] NOT NULL,
	[tlog_file_key] [int] NOT NULL,
	[sales_quantity] [decimal](9, 2) NOT NULL,
	[sales_dollar_amount] [decimal](9, 2) NOT NULL,
	[cost_dollar_amount] [decimal](9, 2) NOT NULL,
	[assumed_cost_flag] [tinyint] NOT NULL,
	[pricing_bucket_key] [smallint] NULL,
	[regular_retail_unit_price] [smallmoney] NULL,
	[base_unit_cost] [smallmoney] NULL,
	[promoted_unit_cost] [smallmoney] NULL,
	[markdown_dollar_amount] [decimal](9, 2) NULL,
 CONSTRAINT [PK_daily_sales_fact] PRIMARY KEY CLUSTERED 
(
	[trans_date_key] ASC,
	[product_key] ASC,
	[store_key] ASC,
	[tlog_file_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[daily_sales_fact_staging](
	[trans_date] [datetime] NOT NULL,
	[upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[store_id] [smallint] NOT NULL,
	[tlog_file_key] [int] NOT NULL,
	[sales_quantity] [decimal](9, 2) NOT NULL,
	[sales_dollar_amount] [decimal](9, 2) NOT NULL,
	[cost_dollar_amount] [decimal](9, 2) NOT NULL,
 CONSTRAINT [PK_daily_sales_fact_staging_1] PRIMARY KEY CLUSTERED 
(
	[trans_date] ASC,
	[upc] ASC,
	[store_id] ASC,
	[tlog_file_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[daily_sales_fact_staging2](
	[trans_date_key] [int] NOT NULL,
	[product_key] [int] NOT NULL,
	[store_key] [smallint] NOT NULL,
	[tlog_file_key] [int] NOT NULL,
	[sales_quantity] [decimal](9, 2) NOT NULL,
	[sales_dollar_amount] [decimal](9, 2) NOT NULL,
	[cost_dollar_amount] [decimal](9, 2) NOT NULL
) ON [PRIMARY]

GO
CREATE CLUSTERED INDEX [PK_daily_sales_fact_staging] ON [dbo].[daily_sales_fact_staging2]
(
	[trans_date_key] ASC,
	[product_key] ASC,
	[store_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[daily_subdepartment_sales](
	[tlog_date_key] [int] NOT NULL,
	[store_key] [smallint] NOT NULL,
	[subdepartment_key] [smallint] NOT NULL,
	[tlog_file_key] [int] NOT NULL,
	[sales_dollar_amount] [numeric](9, 2) NOT NULL,
	[cost_dollar_amount] [numeric](18, 2) NOT NULL,
	[customer_count] [int] NOT NULL,
	[item_count] [int] NOT NULL,
 CONSTRAINT [PK_daily_subdepartment_sales] PRIMARY KEY CLUSTERED 
(
	[tlog_date_key] ASC,
	[store_key] ASC,
	[subdepartment_key] ASC,
	[tlog_file_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[daily_total_store_counts](
	[tlog_date_key] [int] NOT NULL,
	[store_key] [smallint] NOT NULL,
	[tlog_file_key] [int] NOT NULL,
	[customer_count] [int] NOT NULL,
	[item_count] [int] NOT NULL,
 CONSTRAINT [PK_daily_total_store_counts] PRIMARY KEY CLUSTERED 
(
	[tlog_date_key] ASC,
	[store_key] ASC,
	[tlog_file_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

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
CREATE TABLE [dbo].[department_dim](
	[department_key] [int] NOT NULL,
	[department_name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[major_grouping] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[sort_key] [int] NULL,
	[is_active] [bit] NULL,
 CONSTRAINT [PK_department_dim] PRIMARY KEY CLUSTERED 
(
	[department_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dw_key_sequence](
	[KeyType] [char](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[NextNumber] [int] NULL,
 CONSTRAINT [PK_dw_key_sequence] PRIMARY KEY CLUSTERED 
(
	[KeyType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DwStatus](
	[LastDwLoadTime] [datetime] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[event_calendar_dim](
	[event_key] [int] IDENTITY(1,1) NOT NULL,
	[effective_date_key] [int] NOT NULL,
	[expiration_date_key] [int] NOT NULL,
	[event_description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[create_date_key] [int] NOT NULL,
	[store_key] [smallint] NULL,
	[show_on_sales_screens] [bit] NULL,
 CONSTRAINT [PK_event_calendar_dim] PRIMARY KEY CLUSTERED 
(
	[event_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[iss45_member_promotion_fact](
	[record_id] [bigint] IDENTITY(1,1) NOT NULL,
	[tlog_file_key] [int] NOT NULL,
	[MMBR_PROM_ID] [float] NOT NULL,
	[store_key] [int] NOT NULL,
	[subdepartment_key] [int] NOT NULL,
	[qty] [decimal](9, 2) NOT NULL,
	[amount] [decimal](9, 2) NOT NULL,
	[tail_time] [datetime] NOT NULL,
	[tail_pos_nmbr] [int] NOT NULL,
	[tail_ticket_nmbr] [int] NOT NULL,
	[tail_cashier_nmbr] [int] NOT NULL,
 CONSTRAINT [PK_iss45_member_promotion_fact] PRIMARY KEY CLUSTERED 
(
	[record_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[item_not_in_db_history](
	[row_key] [int] IDENTITY(1,1) NOT NULL,
	[tlog_file_key] [int] NOT NULL,
	[audit_date_key] [int] NOT NULL,
	[store_key] [int] NOT NULL,
	[upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[sales_quantity] [decimal](9, 2) NULL,
	[sales_dollar_amount] [decimal](9, 2) NULL,
 CONSTRAINT [PK_not_on_file_history] PRIMARY KEY CLUSTERED 
(
	[row_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[item_selling_dept_history](
	[row_key] [int] IDENTITY(1,1) NOT NULL,
	[tlog_file_key] [int] NOT NULL,
	[audit_date_key] [int] NOT NULL,
	[store_key] [int] NOT NULL,
	[upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[occurrence_count] [int] NOT NULL,
	[pos_department] [smallint] NOT NULL,
	[host_department] [smallint] NOT NULL,
 CONSTRAINT [PK_item_selling_dept_history] PRIMARY KEY CLUSTERED 
(
	[row_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[load_Allow](
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AllowAmt] [smallmoney] NOT NULL,
	[SupplierId] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NOT NULL,
	[StoreId] [smallint] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[load_Department](
	[DepartmentId] [smallint] NOT NULL,
	[DepartmentName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[MajorDepartmentId] [int] NOT NULL,
	[SortOrder] [int] NOT NULL,
	[DepartmentKeyUpcCode] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[DefaultMarkup] [numeric](9, 3) NOT NULL,
	[RewardsGivenUpcCode] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_load_DepartmentDepartment] PRIMARY KEY CLUSTERED 
(
	[DepartmentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[load_Item](
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[BrandName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[BrandItemDescription] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ProductSize] [numeric](8, 3) NOT NULL,
	[ProductUom] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[DepartmentId] [smallint] NOT NULL,
	[TypeCd] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StatusCd] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StatusDescr] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_load_Item] PRIMARY KEY CLUSTERED 
(
	[Upc] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[load_ItemType](
	[ProductType] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ProductTypeDescription] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IncludeInSales] [bit] NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[load_MajorDepartment](
	[MajorDepartmentId] [smallint] NOT NULL,
	[MajorDepartmentName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[MajorGrouping] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SortOrder] [int] NOT NULL,
 CONSTRAINT [PK_load_MajorDepartment] PRIMARY KEY CLUSTERED 
(
	[MajorDepartmentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[load_MemberProm](
	[MMBR_PROM_ID] [float] NOT NULL,
	[PROM_DESC] [char](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[STRT_DATE] [datetime] NOT NULL,
	[STRT_TM] [datetime] NULL,
	[END_DATE] [datetime] NULL,
	[END_TM] [datetime] NULL,
	[Upc] [varchar](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[StoreId] [smallint] NOT NULL,
	[MON_FG] [bit] NOT NULL,
	[TUE_FG] [bit] NOT NULL,
	[WED_FG] [bit] NOT NULL,
	[THU_FG] [bit] NOT NULL,
	[FRI_FG] [bit] NOT NULL,
	[SAT_FG] [bit] NOT NULL,
	[SUN_FG] [bit] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[load_PricingBucket](
	[ProductBatchTypeId] [int] NOT NULL,
	[TypeName] [varchar](25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[GroupName] [varchar](25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AffectsPricing] [bit] NOT NULL,
	[Priority] [smallint] NULL,
	[IsPromoted] [bit] NULL,
	[IsDisabled] [bit] NULL,
	[group_sort] [int] NOT NULL,
	[bucket_sort] [int] NOT NULL,
 CONSTRAINT [PK_load_pricingbucket] PRIMARY KEY CLUSTERED 
(
	[ProductBatchTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[load_PromPrice](
	[BatchId] [int] NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NOT NULL,
	[ProductBatchTypeId] [int] NOT NULL,
	[StoreId] [int] NOT NULL,
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[PriceAmt] [smallmoney] NOT NULL,
	[PriceMult] [smallmoney] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[load_ScanOption](
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[BbAmt] [smallmoney] NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NOT NULL,
	[CostAdjustmentType] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[GroupCode] [int] NOT NULL,
	[BatchId] [int] NOT NULL,
	[StoreId] [smallint] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[load_StoreItem](
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[PriceAmt] [smallmoney] NOT NULL,
	[PriceMult] [smallint] NOT NULL,
	[SupplierId] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[PosValid] [bit] NOT NULL,
	[SupplierZoneId] [int] NOT NULL,
 CONSTRAINT [PK_load_StoreItem] PRIMARY KEY CLUSTERED 
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
CREATE TABLE [dbo].[load_Supplier](
	[SupplierId] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SupplierName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SupplierShortName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_load_Supplier] PRIMARY KEY NONCLUSTERED 
(
	[SupplierId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[load_SupplierItem](
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SupplierId] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ProductCost] [smallmoney] NOT NULL,
	[PackageSize] [smallint] NOT NULL,
	[ShipType] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SupplierSku] [varchar](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SplitCharge] [smallmoney] NOT NULL,
	[SupplierZoneId] [int] NOT NULL,
 CONSTRAINT [PK_load_SupplierItem] PRIMARY KEY CLUSTERED 
(
	[Upc] ASC,
	[SupplierId] ASC,
	[SupplierZoneId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[lowbatch1](
	[upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[batchid] [int] NOT NULL,
	[price] [smallmoney] NULL,
	[storeid] [smallint] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
CREATE CLUSTERED INDEX [IX_upc_storeid] ON [dbo].[lowbatch1]
(
	[upc] ASC,
	[storeid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[lowbatch2](
	[upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[batchid] [int] NOT NULL,
	[price] [smallmoney] NULL,
	[storeid] [smallint] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
CREATE UNIQUE CLUSTERED INDEX [IX_upc_storeid] ON [dbo].[lowbatch2]
(
	[upc] ASC,
	[storeid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pricing_bucket_dim](
	[pricing_bucket_key] [smallint] NOT NULL,
	[bucket_name] [varchar](25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[group_name] [varchar](25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[affects_pricing] [bit] NOT NULL,
	[priority] [smallint] NOT NULL,
	[is_promoted] [bit] NOT NULL,
	[is_disabled] [bit] NOT NULL,
	[group_sort] [int] NOT NULL,
	[bucket_sort] [int] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[prod_store_dim_history](
	[date_key] [int] NOT NULL,
	[product_key] [int] NOT NULL,
	[store_key] [smallint] NOT NULL,
	[lowest_unit_price] [decimal](18, 4) NOT NULL,
	[normal_unit_price] [decimal](18, 4) NOT NULL,
	[pricing_bucket_key] [smallint] NOT NULL,
	[pri_supplier_key] [int] NOT NULL,
	[supplier_zone_id] [int] NOT NULL,
	[case_pack] [int] NOT NULL,
	[base_unit_cost] [decimal](18, 4) NOT NULL,
	[ext_unit_cost] [decimal](18, 4) NOT NULL,
	[unit_allow_amt] [decimal](18, 4) NOT NULL,
	[markup_amt] [decimal](18, 4) NOT NULL,
	[ext_bb_amt] [decimal](18, 4) NOT NULL,
	[review_flag] [int] NOT NULL,
 CONSTRAINT [PK_prod_store_dim_history_1] PRIMARY KEY CLUSTERED 
(
	[date_key] ASC,
	[product_key] ASC,
	[store_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[product_dim](
	[product_key] [int] NOT NULL,
	[upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[brand_name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[item_description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[product_size] [numeric](8, 3) NOT NULL,
	[unit_of_measure] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[department_key] [int] NOT NULL,
	[department_name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[subdepartment_key] [int] NOT NULL,
	[subdepartment_name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[product_type_code] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[product_type_desc] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[product_status_code] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[product_status_desc] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[create_date_key] [int] NOT NULL,
	[change_date_key] [int] NOT NULL,
	[delete_date_key] [int] NOT NULL,
	[fc_dept] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[fc_subdept] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[fc_category] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[fc_subcategory] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[fc_class] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_product_dim] PRIMARY KEY CLUSTERED 
(
	[product_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[product_dim_staging](
	[product_key] [int] IDENTITY(1,1) NOT NULL,
	[upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[brand_name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[item_description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[product_size] [numeric](8, 3) NOT NULL,
	[unit_of_measure] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[department_key] [int] NOT NULL,
	[department_name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[subdepartment_key] [int] NOT NULL,
	[subdepartment_name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[product_type_code] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[product_type_desc] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[product_status_code] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[product_status_desc] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[create_date_key] [int] NOT NULL,
	[change_date_key] [int] NOT NULL,
	[delete_date_key] [int] NOT NULL,
	[fc_dept] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[fc_subdept] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[fc_category] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[fc_subcategory] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[fc_class] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_product_dim_staging] PRIMARY KEY NONCLUSTERED 
(
	[product_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[product_dim_temp](
	[upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[brand_name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[item_description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[product_size] [numeric](8, 3) NOT NULL,
	[unit_of_measure] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[department_key] [int] NOT NULL,
	[department_name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[subdepartment_key] [int] NOT NULL,
	[subdepartment_name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[product_type_code] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[product_type_desc] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[product_status_code] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[product_status_desc] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[fc_dept] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[fc_subdept] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[fc_category] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[fc_subcategory] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[fc_class] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_product_dim_temp] PRIMARY KEY NONCLUSTERED 
(
	[upc] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[product_list](
	[session_key] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_product_list] PRIMARY KEY CLUSTERED 
(
	[session_key] ASC,
	[upc] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[product_store_dim](
	[product_key] [int] NOT NULL,
	[store_key] [smallint] NOT NULL,
	[primary_vendor_key] [int] NOT NULL,
	[lowest_unit_price] [smallmoney] NOT NULL,
	[normal_unit_price] [smallmoney] NOT NULL,
	[promoted_unit_price] [smallmoney] NOT NULL,
	[pos_valid_flag] [bit] NOT NULL,
	[create_date_key] [int] NOT NULL,
	[change_date_key] [int] NOT NULL,
	[delete_date_key] [int] NOT NULL,
	[pricing_bucket_key] [smallint] NOT NULL,
	[supplier_zone_id] [int] NOT NULL,
	[unit_allow_amt] [decimal](18, 4) NOT NULL,
	[ext_bb_amt] [decimal](18, 4) NOT NULL,
	[ext_unit_cost] [decimal](18, 4) NOT NULL,
 CONSTRAINT [PK_product_store_dim] PRIMARY KEY CLUSTERED 
(
	[product_key] ASC,
	[store_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[product_store_dim_temp](
	[product_key] [int] NOT NULL,
	[store_key] [smallint] NOT NULL,
	[primary_vendor_key] [int] NOT NULL,
	[lowest_unit_price] [smallmoney] NOT NULL,
	[normal_unit_price] [smallmoney] NOT NULL,
	[promoted_unit_price] [smallmoney] NOT NULL,
	[pos_valid_flag] [bit] NOT NULL,
	[pricing_bucket_key] [smallint] NULL,
	[supplier_zone_id] [int] NOT NULL,
	[unit_allow_amt] [decimal](18, 4) NOT NULL,
	[ext_bb_amt] [decimal](18, 4) NOT NULL,
	[ext_unit_cost] [decimal](18, 4) NOT NULL,
 CONSTRAINT [PK_product_store_temp] PRIMARY KEY CLUSTERED 
(
	[product_key] ASC,
	[store_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProductSalesStatistic](
	[UPC] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StoreId] [smallint] NOT NULL,
	[avg_13wk_cases_sold] [decimal](18, 4) NOT NULL,
	[avg_26wk_cases_sold] [decimal](18, 4) NOT NULL,
	[SalesVelocityIndicator] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
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
	[parent_record_key] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[sort_key] [int] NULL,
	[sales_dollar_amount] [decimal](18, 4) NOT NULL,
	[customer_count] [decimal](18, 0) NOT NULL,
	[item_count] [decimal](18, 0) NOT NULL,
 CONSTRAINT [PK_realtime_sales_summary_1] PRIMARY KEY CLUSTERED 
(
	[store_key] ASC,
	[record_type] ASC,
	[record_key] ASC,
	[trans_date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[realtime_sales_summary_staging](
	[RequestId] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[store_key] [int] NOT NULL,
	[record_type] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[record_key] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[record_description] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[parent_record_key] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[sort_key] [int] NULL,
	[sales_dollar_amount] [decimal](18, 4) NOT NULL,
	[customer_count] [decimal](18, 0) NOT NULL,
	[item_count] [decimal](18, 0) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[s3_message_log](
	[row_id] [int] IDENTITY(1,1) NOT NULL,
	[log_time] [datetime] NOT NULL,
	[source] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[is_error] [bit] NOT NULL,
	[message] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[exception_text] [varchar](4096) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[store_id] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[store_dim](
	[store_key] [smallint] NOT NULL,
	[store_id] [smallint] NOT NULL,
	[short_name] [char](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[long_name] [char](25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[opening_date_key] [int] NULL,
	[tlog_sales_date_offset] [smallint] NULL,
	[weather_airport_code] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[store_group] [varchar](25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_StoreDimension] PRIMARY KEY CLUSTERED 
(
	[store_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[subdepartment_dim](
	[subdepartment_key] [int] NOT NULL,
	[subdepartment_name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[department_key] [int] NOT NULL,
	[subdept_sort_order] [int] NULL,
	[department_key_upc_code] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[rewards_given_upc_code] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[default_markup] [numeric](9, 3) NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[supplier_dim](
	[supplier_key] [int] NOT NULL,
	[supplier_Id] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[supplier_Name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SupplierShortName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[create_date_key] [int] NOT NULL,
	[change_date_key] [int] NOT NULL,
	[delete_date_key] [int] NOT NULL,
 CONSTRAINT [PK_supplier_dim] PRIMARY KEY CLUSTERED 
(
	[supplier_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[supplier_dim_staging](
	[supplier_key] [int] IDENTITY(1,1) NOT NULL,
	[Supplier_Id] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Supplier_Name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SupplierShortName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[create_date_key] [int] NOT NULL,
	[change_date_key] [int] NOT NULL,
	[delete_date_key] [int] NOT NULL,
 CONSTRAINT [PK_supplier_dim_staging] PRIMARY KEY CLUSTERED 
(
	[supplier_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[supplier_product_dim](
	[product_key] [int] NOT NULL,
	[supplier_key] [int] NOT NULL,
	[pack] [int] NOT NULL,
	[sku] [varchar](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[base_unit_cost] [smallmoney] NOT NULL,
	[markup_amount] [smallmoney] NOT NULL,
	[create_date_key] [int] NOT NULL,
	[change_date_key] [int] NOT NULL,
	[delete_date_key] [int] NOT NULL,
	[supplier_zone_id] [int] NOT NULL,
 CONSTRAINT [PK_supplier_product_dim] PRIMARY KEY CLUSTERED 
(
	[product_key] ASC,
	[supplier_key] ASC,
	[supplier_zone_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[supplier_product_dim_temp](
	[product_key] [int] NOT NULL,
	[supplier_key] [int] NOT NULL,
	[pack] [int] NOT NULL,
	[sku] [varchar](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[base_unit_cost] [smallmoney] NOT NULL,
	[markup_amount] [smallmoney] NOT NULL,
	[supplier_zone_id] [int] NOT NULL,
 CONSTRAINT [PK_supplier_product_dim_temp] PRIMARY KEY NONCLUSTERED 
(
	[product_key] ASC,
	[supplier_key] ASC,
	[supplier_zone_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[temp_department_count](
	[department_key] [smallint] NOT NULL,
	[count_type] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[count_value] [int] NOT NULL,
 CONSTRAINT [PK_temp_department_count] PRIMARY KEY CLUSTERED 
(
	[department_key] ASC,
	[count_type] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[temp_dept_rollup](
	[department_key] [int] NOT NULL,
	[sales_dollar_amount] [decimal](38, 2) NULL,
	[cost_dollar_amount] [decimal](38, 2) NULL,
	[customer_count] [int] NOT NULL,
	[item_count] [int] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[temp_group_count](
	[major_grouping] [char](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[count_type] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[count_value] [int] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[temp_price](
	[storeid] [int] NULL,
	[upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[reg_price] [smallmoney] NULL,
	[reg_dealqty] [smallint] NULL,
	[reg_unit_price] [smallmoney] NULL,
	[batchid] [int] NULL,
	[batch_price_method] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[batch_price] [smallmoney] NULL,
	[batch_multiple] [smallint] NULL,
	[batch_promo_code] [smallint] NULL,
	[batch_deal_price] [smallmoney] NULL,
	[batch_multi_price_group] [tinyint] NULL,
	[coupon_upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[coupon_type] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[coupon_price] [smallmoney] NULL,
	[coupon_deal_qty] [smallint] NULL,
	[coupon_pts_only] [bit] NULL,
	[limit] [int] NULL,
	[price] [smallmoney] NULL,
	[coupon_reduction_amount] [smallmoney] NULL,
	[scan_price] [smallmoney] NULL,
	[handled] [int] NULL,
	[row_id] [int] IDENTITY(1,1) NOT NULL,
	[pricing_bucket_key] [smallint] NULL,
	[priority] [smallint] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
CREATE CLUSTERED INDEX [IX_upc_storeid_price_limit] ON [dbo].[temp_price]
(
	[upc] ASC,
	[storeid] ASC,
	[price] ASC,
	[limit] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[temp_raw_billback](
	[Upc] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[BBAmount] [smallmoney] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[temp_rollup](
	[subdepartment_key] [int] NOT NULL,
	[sales_dollar_amount] [decimal](38, 2) NULL,
	[cost_dollar_amount] [decimal](38, 2) NULL,
	[customer_count] [int] NOT NULL,
	[item_count] [int] NOT NULL
) ON [PRIMARY]

GO
CREATE UNIQUE CLUSTERED INDEX [IX_subdepartment_key] ON [dbo].[temp_rollup]
(
	[subdepartment_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[temp_scanback](
	[UPC] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[BbAmount] [smallmoney] NOT NULL,
	[ExpireDate] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[temp_subdepartment_count](
	[subdepartment_key] [smallint] NOT NULL,
	[count_type] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[count_value] [int] NOT NULL,
 CONSTRAINT [PK_temp_subdepartment_count] PRIMARY KEY CLUSTERED 
(
	[subdepartment_key] ASC,
	[count_type] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[temp_tlog_temp_costs](
	[tlog_file_key] [int] NOT NULL,
	[store_key] [smallint] NOT NULL,
	[trans_date_key] [int] NOT NULL,
	[product_key] [int] NOT NULL,
	[primary_vendor_key] [int] NOT NULL,
	[extended_unit_cost] [smallmoney] NOT NULL,
	[audit_date_key] [int] NOT NULL,
	[psh_audit_id] [int] NULL,
	[pricing_bucket_key] [smallint] NULL,
	[regular_retail_unit_price] [smallmoney] NULL,
	[base_unit_cost] [smallmoney] NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[time_dim](
	[time_key] [smallint] NOT NULL,
	[time_string] [varchar](5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[hour_of_day] [tinyint] NOT NULL,
	[am_pm_flag] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[time_string_15min] [varchar](8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_time_dim] PRIMARY KEY CLUSTERED 
(
	[time_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tlog_header](
	[row_key] [int] IDENTITY(1,1) NOT NULL,
	[trans_num] [char](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[trans_date] [datetime] NOT NULL,
	[trans_type] [char](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[terminal] [char](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[opr] [char](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[pwd] [char](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tlog_history](
	[tlog_file_key] [int] IDENTITY(1,1) NOT NULL,
	[file_name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[calendar_year] [int] NOT NULL,
	[file_path] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[file_date] [datetime] NULL,
	[file_length] [bigint] NULL,
	[tlog_date_key] [int] NOT NULL,
	[store_key] [smallint] NOT NULL,
	[process_start_time] [datetime] NULL,
	[process_stop_time] [datetime] NULL,
 CONSTRAINT [PK_tlog_history] PRIMARY KEY CLUSTERED 
(
	[tlog_file_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UNQ_store_key_file_name_calendar_year] UNIQUE NONCLUSTERED 
(
	[store_key] ASC,
	[file_name] ASC,
	[calendar_year] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tlog_item](
	[row_key] [int] IDENTITY(1,1) NOT NULL,
	[header_row_key] [int] NOT NULL,
	[item_code] [char](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[quantity] [decimal](18, 5) NOT NULL,
	[extended_price] [decimal](18, 5) NOT NULL,
	[department] [smallint] NOT NULL,
	[sale_type] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[store_coupon_key] [bit] NULL,
	[mfg_coupon_key] [bit] NULL,
	[deposit_key] [bit] NULL,
	[cancel_key] [bit] NULL,
	[refund_key] [bit] NULL,
	[item_lookup_method] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tlog_temp_costs](
	[tlog_file_key] [int] NOT NULL,
	[store_key] [smallint] NOT NULL,
	[trans_date_key] [int] NOT NULL,
	[product_key] [int] NOT NULL,
	[primary_vendor_key] [int] NOT NULL,
	[extended_unit_cost] [smallmoney] NOT NULL,
	[audit_date_key] [int] NOT NULL,
	[psh_audit_id] [int] NULL,
	[pricing_bucket_key] [smallint] NULL,
	[regular_retail_unit_price] [smallmoney] NULL,
	[base_unit_cost] [smallmoney] NULL
) ON [PRIMARY]

GO
CREATE CLUSTERED INDEX [ix_tlog_temp_costs] ON [dbo].[tlog_temp_costs]
(
	[product_key] ASC,
	[trans_date_key] ASC,
	[store_key] ASC,
	[tlog_file_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[weather_history](
	[store_key] [smallint] NOT NULL,
	[date_key] [int] NOT NULL,
	[weather_airport_code] [char](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[mean_temperature] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[min_temperature] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[max_temperature] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[precipitation] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[snowfall] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[events] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[weekly_group_sales](
	[major_grouping] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[sales_year] [int] NOT NULL,
	[sales_week] [int] NOT NULL,
	[sales_quarter] [varchar](3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[date_key] [int] NOT NULL,
	[store_key] [smallint] NOT NULL,
	[sales_dollar_amount] [numeric](38, 2) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
CREATE UNIQUE CLUSTERED INDEX [PK_weekly_group_sales_unique] ON [dbo].[weekly_group_sales]
(
	[major_grouping] ASC,
	[sales_year] ASC,
	[sales_week] ASC,
	[sales_quarter] ASC,
	[date_key] ASC,
	[store_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[weekly_sales_summary](
	[store_key] [int] NOT NULL,
	[product_key] [int] NOT NULL,
	[absolute_week] [int] NOT NULL,
	[unit_qty_sold] [decimal](18, 4) NOT NULL,
	[cases_sold] [decimal](18, 4) NOT NULL,
	[sales_dollar_amount] [decimal](18, 4) NOT NULL,
	[cost_dollar_amount] [decimal](18, 4) NOT NULL,
	[regular_retail_sales_dollar_amount] [decimal](18, 4) NOT NULL,
	[avg_13wk_cases_sold] [decimal](18, 4) NULL,
	[avg_26wk_cases_sold] [decimal](18, 4) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_BatchType_StoreId] ON [dbo].[Batch]
(
	[StoreId] ASC,
	[BatchType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_tlog_file_key] ON [dbo].[daily_bucket_sales]
(
	[tlog_file_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_product_key_trans_date_key] ON [dbo].[daily_sales_fact]
(
	[product_key] ASC,
	[trans_date_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_tlog_file_key] ON [dbo].[daily_sales_fact]
(
	[tlog_file_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_product_key] ON [dbo].[daily_sales_fact_staging2]
(
	[product_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_store_key] ON [dbo].[daily_sales_fact_staging2]
(
	[store_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_absolute_day] ON [dbo].[date_dim]
(
	[absolute_day] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_absolute_week] ON [dbo].[date_dim]
(
	[absolute_week] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_sales_week_sales_year_day_of_week_num] ON [dbo].[date_dim]
(
	[sales_week] ASC,
	[sales_year] ASC,
	[day_of_week_num] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_major_grouping_department_key] ON [dbo].[department_dim]
(
	[department_key] ASC,
	[major_grouping] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_MMBR_PROM_ID_date_key_store_key] ON [dbo].[iss45_member_promotion_fact]
(
	[MMBR_PROM_ID] ASC,
	[tlog_file_key] ASC,
	[store_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_audit_date_key] ON [dbo].[item_selling_dept_history]
(
	[audit_date_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_tlog_file_key] ON [dbo].[item_selling_dept_history]
(
	[tlog_file_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [ix_StoreId_IncludedCols] ON [dbo].[load_StoreItem]
(
	[StoreId] ASC
)
INCLUDE ( 	[PosValid],
	[PriceAmt],
	[PriceMult],
	[SupplierId],
	[Upc]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [_dta_index_prod_store_dim_history_12_859150106__K2_K3_K1_7] ON [dbo].[prod_store_dim_history]
(
	[product_key] ASC,
	[store_key] ASC,
	[date_key] ASC
)
INCLUDE ( 	[pri_supplier_key]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_store_key_date_key_includes] ON [dbo].[prod_store_dim_history]
(
	[store_key] ASC,
	[date_key] ASC
)
INCLUDE ( 	[base_unit_cost],
	[ext_unit_cost],
	[normal_unit_price],
	[pri_supplier_key],
	[pricing_bucket_key],
	[product_key]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_upc] ON [dbo].[product_dim]
(
	[upc] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_RequestId] ON [dbo].[realtime_sales_summary_staging]
(
	[RequestId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_log_time] ON [dbo].[s3_message_log]
(
	[log_time] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_subdepartment_key] ON [dbo].[subdepartment_dim]
(
	[subdepartment_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [IX_supplier_product_dim_product_key_sku] ON [dbo].[supplier_product_dim]
(
	[supplier_key] ASC
)
INCLUDE ( 	[product_key],
	[sku]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_batchid] ON [dbo].[temp_price]
(
	[batchid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [PK_weekly_sales_summary] ON [dbo].[weekly_sales_summary]
(
	[absolute_week] ASC,
	[store_key] ASC,
	[product_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[load_StoreItem] ADD  CONSTRAINT [DF_load_StoreItem_SupplierZoneId]  DEFAULT ((1)) FOR [SupplierZoneId]
GO
ALTER TABLE [dbo].[load_SupplierItem] ADD  CONSTRAINT [DF_load_SupplierItem_SupplierZoneId]  DEFAULT ((1)) FOR [SupplierZoneId]
GO
ALTER TABLE [dbo].[pricing_bucket_dim] ADD  CONSTRAINT [DF__pricing_b__is_pr__6F9F86DC]  DEFAULT ((0)) FOR [is_promoted]
GO
ALTER TABLE [dbo].[pricing_bucket_dim] ADD  CONSTRAINT [DF__pricing_b__is_di__7093AB15]  DEFAULT ((0)) FOR [is_disabled]
GO
ALTER TABLE [dbo].[product_dim_temp] ADD  CONSTRAINT [DF_product_temp_brand_name]  DEFAULT ('Missing') FOR [brand_name]
GO
ALTER TABLE [dbo].[product_dim_temp] ADD  CONSTRAINT [DF_product_temp_item_description]  DEFAULT ('MISSING') FOR [item_description]
GO
ALTER TABLE [dbo].[product_dim_temp] ADD  CONSTRAINT [DF_product_temp_product_size]  DEFAULT ((0)) FOR [product_size]
GO
ALTER TABLE [dbo].[product_dim_temp] ADD  CONSTRAINT [DF_product_temp_unit_of_measure]  DEFAULT ('XX') FOR [unit_of_measure]
GO
ALTER TABLE [dbo].[product_store_dim] ADD  CONSTRAINT [DF_product_store_dim_supplier_zone_id]  DEFAULT ((1)) FOR [supplier_zone_id]
GO
ALTER TABLE [dbo].[product_store_dim_temp] ADD  CONSTRAINT [DF_product_store_dim_temp_supplier_zone_id]  DEFAULT ((1)) FOR [supplier_zone_id]
GO
ALTER TABLE [dbo].[subdepartment_dim] ADD  CONSTRAINT [DF_subdepartment_dim_default_markup]  DEFAULT ((0.0)) FOR [default_markup]
GO
ALTER TABLE [dbo].[supplier_product_dim] ADD  CONSTRAINT [DF__supplier___marku__48C5B0DD]  DEFAULT ((0)) FOR [markup_amount]
GO
ALTER TABLE [dbo].[supplier_product_dim] ADD  CONSTRAINT [DF_supplier_product_dim_supplier_zone_id]  DEFAULT ((1)) FOR [supplier_zone_id]
GO
ALTER TABLE [dbo].[supplier_product_dim_temp] ADD  CONSTRAINT [DF__supplier___marku__47D18CA4]  DEFAULT ((0)) FOR [markup_amount]
GO
ALTER TABLE [dbo].[supplier_product_dim_temp] ADD  CONSTRAINT [DF_supplier_product_dim_temp_SupplierZoneId]  DEFAULT ((1)) FOR [supplier_zone_id]
GO
ALTER TABLE [dbo].[BatchItem]  WITH CHECK ADD  CONSTRAINT [FK_BatchItem_Batch] FOREIGN KEY([BatchId], [StoreId])
REFERENCES [dbo].[Batch] ([BatchId], [StoreId])
GO
ALTER TABLE [dbo].[BatchItem] CHECK CONSTRAINT [FK_BatchItem_Batch]
GO
ALTER TABLE [dbo].[daily_department_sales]  WITH CHECK ADD  CONSTRAINT [FK_daily_department_sales_store_dim] FOREIGN KEY([store_key])
REFERENCES [dbo].[store_dim] ([store_key])
GO
ALTER TABLE [dbo].[daily_department_sales] CHECK CONSTRAINT [FK_daily_department_sales_store_dim]
GO
ALTER TABLE [dbo].[daily_group_counts]  WITH CHECK ADD  CONSTRAINT [FK_daily_group_counts_store_dim] FOREIGN KEY([store_key])
REFERENCES [dbo].[store_dim] ([store_key])
GO
ALTER TABLE [dbo].[daily_group_counts] CHECK CONSTRAINT [FK_daily_group_counts_store_dim]
GO
ALTER TABLE [dbo].[daily_sales_fact]  WITH CHECK ADD  CONSTRAINT [FK_daily_sales_fact_product_dim] FOREIGN KEY([product_key])
REFERENCES [dbo].[product_dim] ([product_key])
GO
ALTER TABLE [dbo].[daily_sales_fact] CHECK CONSTRAINT [FK_daily_sales_fact_product_dim]
GO
ALTER TABLE [dbo].[daily_sales_fact]  WITH CHECK ADD  CONSTRAINT [FK_daily_sales_fact_store_dim] FOREIGN KEY([store_key])
REFERENCES [dbo].[store_dim] ([store_key])
GO
ALTER TABLE [dbo].[daily_sales_fact] CHECK CONSTRAINT [FK_daily_sales_fact_store_dim]
GO
ALTER TABLE [dbo].[daily_sales_fact]  WITH NOCHECK ADD  CONSTRAINT [FK_daily_sales_fact_tlog_date_dim] FOREIGN KEY([trans_date_key])
REFERENCES [dbo].[date_dim] ([date_key])
GO
ALTER TABLE [dbo].[daily_sales_fact] CHECK CONSTRAINT [FK_daily_sales_fact_tlog_date_dim]
GO
ALTER TABLE [dbo].[daily_subdepartment_sales]  WITH CHECK ADD  CONSTRAINT [FK_daily_subdepartment_sales_store_dim] FOREIGN KEY([store_key])
REFERENCES [dbo].[store_dim] ([store_key])
GO
ALTER TABLE [dbo].[daily_subdepartment_sales] CHECK CONSTRAINT [FK_daily_subdepartment_sales_store_dim]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE    PROCEDURE [dbo].[ApplyMaintBatch_realtime_sales_summary_Change]
	@SessionKey VARCHAR(100)
AS

DECLARE @error INT

DECLARE @rowsToProcess INT
SELECT @rowsToProcess = COUNT(1) FROM maint_staging_realtime_sales_summary WHERE session_key = @SessionKey
IF @rowsToProcess = 0 BEGIN
	RETURN
END

BEGIN TRANSACTION

-- find the store number for this request
DECLARE @storeKey INT
SELECT 
	@storeKey = store_key 
FROM 
	maint_staging_realtime_sales_summary 
WHERE 
	session_key = @SessionKey
SET @error = @@ERROR
IF @error <> 0 BEGIN
	ROLLBACK TRANSACTION
	RETURN
END
IF @storeKey IS NULL BEGIN
	RAISERROR ('Unable to get store_number for session_key=%0', 16, 1, @SessionKey)
	ROLLBACK TRANSACTION
	RETURN
END

-- clear existing data from realtime_sales_summary for this request's store number
DELETE FROM 
	realtime_sales_summary 
WHERE
	store_key = @storeKey
SET @error = @@ERROR
IF @error <> 0 BEGIN
	ROLLBACK TRANSACTION
	RETURN
END

-- push data from staging table into production table
INSERT INTO realtime_sales_summary SELECT 
	store_key,
	record_type,
	record_key,
	trans_date,
	record_description,
	parent_record_key,
	sort_key,
	sales_dollar_amount,
	customer_count,
	item_count
FROM
	maint_staging_realtime_sales_summary s WITH (NOLOCK)
WHERE
	session_key = @sessionKey
	AND NOT EXISTS (SELECT 1 FROM realtime_sales_summary rss WHERE
		rss.store_key = s.store_key
		AND rss.record_type = s.record_type
		AND rss.record_key = s.record_key
		AND rss.trans_date = s.trans_date
	)

SET @error = @@ERROR
IF @error <> 0 BEGIN
	ROLLBACK TRANSACTION
	RETURN
END

-- clear data from staging table
DELETE FROM maint_staging_realtime_sales_summary WHERE session_key = @SessionKey
SET @error = @@ERROR
IF @error <> 0 BEGIN
	ROLLBACK TRANSACTION
	RETURN
END

-- all good, commit
COMMIT TRANSACTION


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Audit_ItemsSoldInWrongDepartment]
AS

DECLARE @cutoffDateKey INT
SELECT 
	@cutoffdateKey = da.date_key
FROM
	date_dim da
WHERE
	da.absolute_day = (SELECT absolute_day-7 FROM date_dim da2 WHERE da2.date_key = dbo.fn_DateToDateKey(GETDATE()))

SELECT
	da.calendar_date AS CalendarDate
	,s.store_id AS StoreNumber
	,RTRIM(s.long_name) AS StoreName
	,h.Upc
	,RTRIM(p.brand_name) AS BrandName
	,RTRIM(p.item_description) AS ItemDescription
	,h.occurrence_count AS NumberOfTimes
	,pos_department AS PosDepartment
	,RTRIM(sd1.subdepartment_name) AS PosDepartmentName
	,host_department AS HostDepartment
	,RTRIM(sd2.subdepartment_name) AS HostDepartmentName
FROM
	item_selling_dept_history AS h
INNER JOIN product_dim p ON
	p.upc = h.Upc
	AND p.product_type_code = '0'
INNER JOIN subdepartment_dim AS sd1 ON
	sd1.subdepartment_key = h.pos_department
INNER JOIN subdepartment_dim AS sd2 ON
	sd2.subdepartment_key = h.host_department
INNER JOIN date_dim da ON
	da.date_key = h.audit_date_key
INNER JOIN store_dim AS s ON
	s.store_key = h.store_key
WHERE
	h.pos_department <> h.host_department
	AND h.pos_department <> -1
	AND h.audit_date_key >= @cutoffDateKey
ORDER BY
	da.date_key DESC


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[Audit_NotOnFileItemsSold]
AS

DECLARE @cutoffDateKey INT
SELECT 
	@cutoffdateKey = da.date_key
FROM
	date_dim da
WHERE
	da.absolute_day = (SELECT absolute_day-7 FROM date_dim da2 WHERE da2.date_key = dbo.fn_DateToDateKey(GETDATE()))

SELECT 
	da.calendar_date AS CalendarDate
	,s.store_id AS StoreNumber
	,RTRIM(s.long_name) AS StoreName
	,Upc
	,sales_quantity AS SalesQuantity
	,sales_dollar_amount AS SalesDollarAmount
FROM 
	item_not_in_db_history AS h
INNER JOIN date_dim da ON
	da.date_key = h.audit_date_key
INNER JOIN store_dim AS s ON
	s.store_key = h.store_key
WHERE
	h.audit_date_key >= @cutoffDateKey
	--AND upc NOT LIKE '005%'
	--AND upc NOT LIKE '099%'
ORDER BY
	da.date_key DESC


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ChangeTlogDate]
    @tlogFileKey INTEGER
	,@newDateKey INTEGER
AS

UPDATE daily_subdepartment_sales SET tlog_date_key = @newDateKey WHERE tlog_file_key = @tlogFileKey
UPDATE daily_department_sales SET tlog_date_key = @newDateKey WHERE tlog_file_key = @tlogFileKey
UPDATE daily_total_store_counts SET tlog_date_key = @newDateKey WHERE tlog_file_key = @tlogFileKey
UPDATE daily_group_counts SET tlog_date_key = @newDateKey WHERE tlog_file_key = @tlogFileKey
UPDATE daily_group_sales SET tlog_date_key = @newDateKey WHERE tlog_file_key = @tlogFileKey
UPDATE daily_bucket_sales SET tlog_date_key = @newDateKey WHERE tlog_file_key = @tlogFileKey
UPDATE tlog_history SET tlog_date_key = @newDateKey WHERE tlog_file_key = @tlogFileKey


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CreateSessionKey] AS

	SELECT SUSER_SNAME() + '[' + CONVERT(VARCHAR,GETDATE(), 21) + ']' AS session_key


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[DailySalesSelectByUpcDateRange]
	@startDate DATETIME
	,@endDate DATETIME
	,@upc CHAR(13)
AS

SET NOCOUNT ON
DECLARE @sql NVARCHAR(4000)

SELECT
	da.date_key
	,da.sales_year
	,da.sales_week
	,da.sales_quarter
	,da.sales_period
	,RTRIM(LTRIM(da.day_of_week)) AS day_of_week
	,da.calendar_date
	,s.short_name
	,s.store_key
INTO 
	#temp
FROM
	date_dim da
CROSS JOIN 
	[store_dim] s 
WHERE
	da.date_key BETWEEN dbo.fn_DateToDateKey(@startDate) and dbo.fn_DateToDateKey(@endDate)

SELECT 
	ds.trans_date_key
	,ds.store_key
	,SUM(ds.sales_quantity) AS sales_quantity
	,SUM(ds.sales_dollar_amount) AS sales_dollar_amount
	,SUM(ds.cost_dollar_amount) AS cost_dollar_amount
	,SUM(ds.sales_dollar_amount - ds.cost_dollar_amount) AS gm_dollars
	,SUM(ds.markdown_dollar_amount) AS markdown_dollar_amount
INTO 
	#foo
from
	product_dim p WITH (NOLOCK)
inner join 	daily_sales_fact ds WITH (NOLOCK) ON
	p.product_key = ds.product_key
	AND ds.trans_date_key between dbo.fn_DateToDateKey(@startDate) and dbo.fn_DateToDateKey(@endDate)
WHERE
	p.upc = @upc
GROUP BY
	ds.trans_date_key
	,ds.store_key

SELECT
	t.*
	,f.sales_quantity
	,f.sales_dollar_amount
	,f.cost_dollar_amount
	,f.gm_dollars
	,f.markdown_dollar_amount
FROM
	#temp t
LEFT OUTER JOIN #foo f ON
	f.store_key = t.store_key
	AND f.trans_date_key = t.date_key


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DailySalesSelectForProductMovement]
-- 	@tlogDateKey INT
	@transDateKey INT
AS

SELECT
	p.upc
	,ds.store_key
	,da2.calendar_date
	,SUM(ds.sales_quantity) AS sales_quantity
	,SUM(ds.cost_dollar_amount) AS cost_dollar_amount
	,SUM(ds.sales_dollar_amount) AS sales_dollar_amount
-- 	,CASE
-- 		WHEN ds.pricing_bucket_key IN (1,2,3,10,11,12,13,15) THEN 1
-- 		ELSE 0
-- 	END AS OnSale
	,0 AS OnSale
	,-1 AS TimeFrame
FROM
	daily_sales_fact ds WITH (NOLOCK)
-- INNER JOIN tlog_history th WITH (NOLOCK) ON
-- 	th.tlog_file_key = ds.tlog_file_key
-- INNER JOIN date_dim da WITH (NOLOCK) ON
-- 	da.date_key = th.tlog_date_key
INNER JOIN date_dim da2 WITH (NOLOCK) ON
	da2.date_key = ds.trans_date_key
INNER JOIN product_dim p WITH (NOLOCK) ON
	p.product_key = ds.product_key
WHERE
-- 	th.tlog_date_key = @tlogDateKey
	ds.trans_date_key = @transDateKey
--	AND p.upc = '0000000000001'
GROUP BY
	p.upc
	,ds.store_key
	,da2.calendar_date


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
EXEC DateDim_PopulateYear 2002, '2001-12-31', 52, 4, 3
EXEC DateDim_PopulateYear 2003, '2002-12-30', 52, 4, 3
EXEC DateDim_PopulateYear 2004, '2003-12-29', 53, 4, 3
EXEC DateDim_PopulateYear 2005, '2005-01-03', 52, 4, 3
EXEC DateDim_PopulateYear 2006, '2006-01-02', 52, 4, 3
EXEC DateDim_PopulateYear 2007, '2007-01-01', 52, 4, 3
EXEC DateDim_PopulateYear 2008, '2007-12-31', 52, 4, 3
EXEC DateDim_PopulateYear 2009, '2008-12-29', 53, 4, 3
*/

CREATE    PROCEDURE [dbo].[DateDim_PopulateYear]
	@salesYear INT
	,@startingDate DATETIME
	,@weeksInYear INT
	,@weeksPerPeriod INT
	,@periodsPerQuarter INT
AS

-- SET @salesYear = 2010
-- SET @startingDate = '1/4/2010'
-- SET @weeksInYear = 52
-- SET @weeksPerPeriod = 4
-- SET @periodsPerQuarter = 3
-- q4 periods always fills out the rest of the year, 
-- so a '53rd week' always goes in Q4


DECLARE @existingRecCount INT
SELECT @existingRecCount = COUNT(*) FROM date_dim WHERE sales_year >= @salesYear
IF @existingRecCount > 0 BEGIN
	RAISERROR ('Table [date_dim] cannot be populated for year ''%d'' because data already exists for that year or a future year', 16, 1, @salesYear)
	RETURN
END

SET NOCOUNT ON

DECLARE @qNum INT
DECLARE @salesPeriod INT
DECLARE @salesWeek INT
DECLARE @dayInSalesYear INT
DECLARE @dayInSalesQuarter INT
DECLARE @dayInSalesPeriod INT
DECLARE @dayInSalesWeek INT
DECLARE @calYear INT
DECLARE @calMonth INT
DECLARE @calWeek INT
DECLARE @calQuarter INT		-- remove ??????
DECLARE @dayInCalYear INT
DECLARE @dayOfWeekNum INT
DECLARE @dayOfWeek CHAR(15)
DECLARE @dateMonthText CHAR(15)
DECLARE @absDay INT
DECLARE @absWeek INT


SET @salesWeek = 1
SET @salesPeriod = 1
SET @qNum = 1
SET @dayInSalesYear = 1
SET @dayInSalesQuarter = 1
SET @dayInSalesPeriod = 1
SET @dayInSalesWeek = 1

SELECT @absDay = MAX(absolute_day) + 1 FROM date_dim
SELECT @absWeek = MAX(absolute_week) + 1 FROM date_dim

DECLARE @date DATETIME
SET @date = @startingDate

DECLARE @dayCounter INT
SELECT @dayCounter=0
DECLARE @weekCounter INT
SELECT @weekCounter=0
DECLARE @periodCounter INT
SET @periodCounter = 0

DECLARE @done INT
SET @done = 0
WHILE @done = 0 BEGIN
	DECLARE @dateKey INT
	SELECT @dateKey = CONVERT(INT, CONVERT(VARCHAR,@date, 112))

	SET @dayOfWeek = SUBSTRING(DATENAME(dw, @date),1, 3)
	SET @calYear = DATEPART(yy, @date)
	SET @calMonth = DATEPART(mm, @date)
	SET @calWeek = DATEPART(ww, @date)
	SET @calQuarter = DATEPART(qq, @date)
	SET @dateMonthText = RIGHT('00' + CONVERT(varchar, DATEPART(dd,@date),101),2) + '-' + SUBSTRING(CONVERT(varchar, DATENAME(mm,@date)),1,3)

	DECLARE @firstOfYear DATETIME
	SET @firstOfYear = DATEADD(yy, DATEDIFF(yy, 0, @date), 0)
	SET @dayInCalYear = DATEDIFF(dd, @firstOfYear, @date) + 1

	INSERT INTO date_dim (
		date_key
		,calendar_date
		,sales_year
		,sales_quarter
		,sales_period
		,sales_week
		,day_in_sales_year
		,day_in_sales_quarter
		,day_in_sales_period
		,day_in_sales_week
		,calendar_year
		,calendar_month
		,calendar_week
		,calendar_quarter
		,day_in_calendar_year
		,day_of_week_num
		,day_of_week
		,date_month_text
		,absolute_day
		,absolute_week
	)
	VALUES
	(
		@dateKey
		,@date
		,@salesYear
		,'Q' + CAST(@qNum AS VARCHAR(1))
		,@salesPeriod
		,@salesWeek
		,@dayInSalesYear
		,@dayInSalesQuarter
		,@dayInSalesPeriod
		,@dayInSalesWeek
		,@calYear
		,@calMonth
		,@calWeek
		,@calQuarter
		,@dayInCalYear
		,@dayOfWeekNum
		,@dayOfWeek
		,@dateMonthText
		,@absDay
		,@absWeek
	)

	SET @absDay = @absDay + 1

	SET @dayInSalesYear = @dayInSalesYear + 1
	SET @dayInSalesQuarter = @dayInSalesQuarter + 1
	SET @dayInSalesPeriod = @dayInSalesPeriod + 1
	SET @dayInSalesWeek = @dayInSalesWeek + 1

	-- see if the week has switched
	SET @dayCounter = @dayCounter + 1
	IF @dayCounter = 7 BEGIN
		SET @dayCounter = 0
		SET @dayInSalesWeek = 1
		SET @weekCounter = @weekCounter + 1

		IF @salesWeek <> @weeksInYear BEGIN

			SET @absWeek = @absWeek + 1
			SET @salesWeek = @salesWeek + 1

			-- see if we need to increment the period
			IF @weekCounter = @weeksPerPeriod AND @qNum <= 4 AND @salesPeriod < 13 BEGIN
				SET @weekCounter = 0

				SET @salesPeriod = @salesPeriod + 1
				SET @dayInSalesPeriod = 1

				SET @periodCounter = @periodCounter + 1

				-- see if we need to increment the quarter
				IF @periodCounter = @periodsPerQuarter  AND @qNum < 4 BEGIN
					SET @periodCounter = 0
					SET @qNum = @qNum + 1
					SET @dayInSalesQuarter = 1
				END

			END
			
		END ELSE BEGIN
			SET @done = 1
		END
	END

	
    SET @date = DATEADD(day, 1, @date)
END


-- show day count for the year
SELECT 
	sales_year
	,MIN(calendar_date) AS first_day
	,MAX(calendar_date) AS last_day
	,COUNT(*) as days_in_year
FROM
	date_dim
WHERE 
	sales_year = @salesYear
GROUP BY
	sales_year
ORDER BY
	sales_year
	
-- show day counts by quarter
SELECT 
	sales_year
	,sales_quarter
	,MIN(calendar_date) AS first_day
	,MAX(calendar_date) AS last_day
	,COUNT(*) as days_in_quarter
FROM
	date_dim
WHERE 
	sales_year = @salesYear
GROUP BY
	sales_year
	,sales_quarter
ORDER BY
	sales_year
	,sales_quarter
	
-- show day counts by period
SELECT 
	sales_year
	,sales_quarter
	,sales_period
	,MIN(calendar_date) AS first_day
	,MAX(calendar_date) AS last_day
	,COUNT(*) as days_in_period
FROM
	date_dim
WHERE 
	sales_year = @salesYear
GROUP BY
	sales_year
	,sales_quarter
	,sales_period
ORDER BY
	sales_year
	,sales_quarter
	,sales_period


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DateDim_PopulateYearByPeriodWeeks]
	@salesYear INT
	,@startingDate DATETIME
	,@numberOfPeriodsInYear INT	-- 12 or 13
	,@numberOfWeeksInYear INT	-- 52 or 53
	,@weeksPerPeriod VARCHAR(255)
AS

DECLARE @existingRecCount INT
SELECT @existingRecCount = COUNT(*) FROM date_dim WHERE sales_year >= @salesYear
IF @existingRecCount > 0 BEGIN
	RAISERROR ('Table [date_dim] cannot be populated for year ''%d'' because data already exists for that year or a future year', 16, 1, @salesYear)
	RETURN
END

SET NOCOUNT ON

DECLARE @periods TABLE (
	period INT NOT NULL ,
	weeks INT NOT NULL
)
INSERT INTO @periods SELECT * FROM dbo.fn_SplitINT(@weeksPerPeriod, ',')

DECLARE @weeksSupplied INT
SELECT @weeksSupplied = SUM(weeks) FROM @periods
IF @weeksSupplied <> @numberOfWeeksInYear BEGIN
	RAISERROR ('Wrong number of weeks supplied in @weeksPerPeriod param.  Expected %d, but %d were supplied. ', 16, 1, @numberOfWeeksInYear, @weeksSupplied)
	RETURN
END

DECLARE @periodsSupplied INT
SELECT @periodsSupplied = COUNT(*) FROM @periods

IF @periodsSupplied <> @numberOfPeriodsInYear BEGIN
	RAISERROR ('Wrong number of periods supplied in @weeksPerPeriod param.  Expected %d, but %d were supplied. ', 16, 1, @numberOfPeriodsInYear,@periodsSupplied)
	RETURN
END

DECLARE @qNum INT
DECLARE @salesWeek INT
DECLARE @dayInSalesYear INT
DECLARE @dayInSalesQuarter INT
DECLARE @dayInSalesPeriod INT
DECLARE @dayInSalesWeek INT
DECLARE @calYear INT
DECLARE @calMonth INT
DECLARE @calWeek INT
DECLARE @calQuarter INT		-- remove ??????
DECLARE @dayInCalYear INT
DECLARE @dayOfWeekNum INT
DECLARE @dayOfWeek CHAR(15)
DECLARE @dateMonthText CHAR(15)
DECLARE @absDay INT
DECLARE @absWeek INT


SET @salesWeek = 1
SET @qNum = 1
SET @dayInSalesYear = 1
SET @dayInSalesQuarter = 1
SET @dayInSalesPeriod = 1
SET @dayInSalesWeek = 1

SELECT @absDay = MAX(absolute_day) + 1 FROM date_dim
SELECT @absWeek = MAX(absolute_week) + 1 FROM date_dim

DECLARE @date DATETIME
SET @date = @startingDate

DECLARE @dayCounter INT
SELECT @dayCounter=0

DECLARE @weekCounter INT
SELECT @weekCounter=0

DECLARE @periodCounter INT
SET @periodCounter = 0


DECLARE curPeriods CURSOR FOR SELECT period, weeks FROM @periods
OPEN curPeriods
DECLARE @currPeriodNum INT
DECLARE @currPeriodWeeks INT
FETCH NEXT FROM curPeriods INTO @currPeriodNum, @currPeriodWeeks
WHILE @@FETCH_STATUS = 0 BEGIN

	DECLARE @done INT
	SET @done = 0
	WHILE @done = 0 BEGIN
		DECLARE @dateKey INT
		SELECT @dateKey = CONVERT(INT, CONVERT(VARCHAR,@date, 112))
	
		SET @dayOfWeek = SUBSTRING(DATENAME(dw, @date),1, 3)
		SET @calYear = DATEPART(yy, @date)
		SET @calMonth = DATEPART(mm, @date)
		SET @calWeek = DATEPART(ww, @date)
		SET @calQuarter = DATEPART(qq, @date)
		SET @dateMonthText = RIGHT('00' + CONVERT(varchar, DATEPART(dd,@date),101),2) + '-' + SUBSTRING(CONVERT(varchar, DATENAME(mm,@date)),1,3)
	
		DECLARE @firstOfYear DATETIME
		SET @firstOfYear = DATEADD(yy, DATEDIFF(yy, 0, @date), 0)
		SET @dayInCalYear = DATEDIFF(dd, @firstOfYear, @date) + 1
	
		INSERT INTO date_dim (
			date_key
			,calendar_date
			,sales_year
			,sales_quarter
			,sales_period
			,sales_week
			,day_in_sales_year
			,day_in_sales_quarter
			,day_in_sales_period
			,day_in_sales_week
			,calendar_year
			,calendar_month
			,calendar_week
			,calendar_quarter
			,day_in_calendar_year
			,day_of_week_num
			,day_of_week
			,date_month_text
			,absolute_day
			,absolute_week
		)
		VALUES
		(
			@dateKey
			,@date
			,@salesYear
			,'Q' + CAST(@qNum AS VARCHAR(1))
			,@currPeriodNum
			,@salesWeek
			,@dayInSalesYear
			,@dayInSalesQuarter
			,@dayInSalesPeriod
			,@dayInSalesWeek
			,@calYear
			,@calMonth
			,@calWeek
			,@calQuarter
			,@dayInCalYear
			,@dayOfWeekNum
			,@dayOfWeek
			,@dateMonthText
			,@absDay
			,@absWeek
		)
	
		SET @absDay = @absDay + 1
	
		SET @dayInSalesYear = @dayInSalesYear + 1
		SET @dayInSalesQuarter = @dayInSalesQuarter + 1
		SET @dayInSalesPeriod = @dayInSalesPeriod + 1
		SET @dayInSalesWeek = @dayInSalesWeek + 1
	
		-- see if the week has switched
		SET @dayCounter = @dayCounter + 1
		IF @dayCounter = 7 BEGIN
			SET @dayCounter = 0
			SET @dayInSalesWeek = 1
	
			SET @absWeek = @absWeek + 1
			SET @salesWeek = @salesWeek + 1
			
			-- drop out of this loop after the correct # of weeks have been
			-- created for the current period
			SET @weekCounter = @weekCounter + 1
			IF @weekCounter = @currPeriodWeeks BEGIN
				SET @done = 1
			END
		END
	
		
	    SET @date = DATEADD(day, 1, @date)
	END
	
	FETCH NEXT FROM curPeriods INTO @currPeriodNum, @currPeriodWeeks

	SET @weekCounter = 0
	SET @dayInSalesPeriod = 1

	-- increment the quarter every 3 periods, 
	-- except for the 4th quarter which can contain 12 or 13 periods
	SET @periodCounter = @periodCounter + 1
	IF @periodCounter = 3 AND @qNum < 4 BEGIN
		SET @periodCounter = 0
		SET @qNum = @qNum + 1
		SET @dayInSalesQuarter = 1
	END

END




-- show day count for the year
SELECT 
	sales_year
	,MIN(calendar_date) AS first_day
	,MAX(calendar_date) AS last_day
	,COUNT(*) as days_in_year
FROM
	date_dim
WHERE 
	sales_year = @salesYear
GROUP BY
	sales_year
ORDER BY
	sales_year
	
-- show day counts by quarter
SELECT 
	sales_year
	,sales_quarter
	,MIN(calendar_date) AS first_day
	,MAX(calendar_date) AS last_day
	,COUNT(*) as days_in_quarter
FROM
	date_dim
WHERE 
	sales_year = @salesYear
GROUP BY
	sales_year
	,sales_quarter
ORDER BY
	sales_year
	,sales_quarter
	
-- show day counts by period
SELECT 
	sales_year
	,sales_quarter
	,sales_period
	,MIN(calendar_date) AS first_day
	,MAX(calendar_date) AS last_day
	,COUNT(*) as days_in_period
FROM
	date_dim
WHERE 
	sales_year = @salesYear
GROUP BY
	sales_year
	,sales_quarter
	,sales_period
ORDER BY
	sales_year
	,sales_quarter
	,sales_period


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DwLoad_Department]
	@dateKey INT
AS

INSERT INTO department_dim (
	department_key
	,department_name
	,major_grouping
	,sort_key
	,is_active
) SELECT
	l.MajorDepartmentId
	,l.MajorDepartmentName	
	,l.MajorGrouping
	,l.MajorDepartmentId
	,1
FROM
	load_MajorDepartment l
WHERE NOT EXISTS (
	SELECT 1 FROM department_dim d WHERE d.department_key = l.MajorDepartmentId
)

UPDATE d SET
	d.department_name = l.MajorDepartmentName
	,d.major_grouping = l.MajorGrouping
FROM
	department_dim d
INNER JOIN load_MajorDepartment l ON
	l.MajorDepartmentId = d.department_key
	AND (
		l.MajorDepartmentName <> d.department_name
		OR ISNULL(l.MajorGrouping,'') <> ISNULL(d.major_grouping,'')
	)
	
INSERT INTO subdepartment_dim (
	subdepartment_key
	,subdepartment_name
	,department_key
	,subdept_sort_order
	,department_key_upc_code
	,rewards_given_upc_code
	,default_markup
) SELECT
	l.DepartmentId
	,l.DepartmentName
	,l.MajorDepartmentId
	,l.SortOrder
	,l.DepartmentKeyUpcCode
	,l.RewardsGivenUpcCode
	,l.DefaultMarkup
FROM
	load_Department l
WHERE NOT EXISTS (
	SELECT 1 FROM subdepartment_dim sd WHERE sd.subdepartment_key = l.DepartmentId
)

UPDATE sd SET
	sd.department_key = l.MajorDepartmentId
	,sd.subdepartment_name = l.DepartmentName
	,sd.department_key_upc_code = l.DepartmentKeyUpcCode
	,sd.rewards_given_upc_code = l.RewardsGivenUpcCode
	,sd.subdept_sort_order = l.SortOrder
	,sd.default_markup = l.DefaultMarkup
FROM
	subdepartment_dim sd
INNER JOIN load_Department l ON
	l.DepartmentId = sd.subdepartment_key
	AND (
		l.MajorDepartmentId <> sd.department_key
		OR l.DepartmentName <> sd.subdepartment_name
		OR ISNULL(l.DepartmentKeyUpcCode,'') <> ISNULL(sd.department_key_upc_code, '')
		OR ISNULL(l.RewardsGivenUpcCode,'') <> ISNULL(sd.rewards_given_upc_code, '')
		OR ISNULL(l.SortOrder,'') <> ISNULL(sd.subdept_sort_order, '')
		OR ISNULL(l.DefaultMarkup, 0.0) <> ISNULL(sd.default_markup, 0.0)
	)


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[DwLoad_MemberProm]
	@dateKey INT
AS

-- just need a placeholder here so the sproc is syntactically correct
SELECT COUNT(*) FROM load_MemberProm


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DwLoad_PricingBucket]
	@dateKey INT
AS

INSERT INTO pricing_bucket_dim (
	pricing_bucket_key
	,bucket_name
	,group_name
	,affects_pricing
	,priority
	,is_promoted
	,is_disabled
	,group_sort
	,bucket_sort
)
SELECT
	l.ProductBatchTypeId
	,l.TypeName
	,l.GroupName
	,l.AffectsPricing
	,l.Priority
	,l.IsPromoted
	,l.IsDisabled
	,l.group_sort
	,l.bucket_sort
FROM
	load_PricingBucket l
WHERE 
	NOT EXISTS (SELECT * FROM pricing_bucket_dim b 
					WHERE b.pricing_bucket_key = l.ProductBatchTypeId)

UPDATE b SET
	b.bucket_name = l.TypeName
	,b.group_name = l.GroupName
	,b.affects_pricing = l.AffectsPricing
	,b.priority = l.Priority
	,b.is_promoted = l.IsPromoted
	,b.is_disabled = l.IsDisabled
	,b.group_sort = l.group_sort
	,b.bucket_sort = l.bucket_sort
FROM
	pricing_bucket_dim b
INNER JOIN load_PricingBucket l ON
	l.ProductBatchTypeId = b.pricing_bucket_key


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DwLoad_Product]
	@dateKey INT
AS

-- rebuild product_dim_temp
TRUNCATE TABLE product_dim_temp
INSERT INTO product_dim_temp (
    upc
    ,brand_name
    ,item_description
    ,product_size
    ,unit_of_measure
    ,department_key
    ,department_name
    ,subdepartment_key
    ,subdepartment_name
    ,product_type_code
    ,product_type_desc
	,product_status_code 
	,product_status_desc 
)
SELECT
    l.Upc
    ,l.BrandName
    ,l.BrandItemDescription
    ,l.ProductSize
    ,l.ProductUom
    ,d.department_key
    ,d.department_name
	,sd.subdepartment_key
	,sd.subdepartment_name
    ,l.TypeCd
    ,it.ProductTypeDescription
	,l.StatusCd
	,l.StatusDescr
FROM 
	load_Item l
INNER JOIN subdepartment_dim sd on
    sd.subdepartment_key = l.departmentid
INNER JOIN department_dim d on
    d.department_key = sd.department_key
INNER JOIN load_ItemType it ON
	it.ProductType = l.TypeCd

-- add new rows to product_staging
INSERT INTO product_dim_staging (
    upc
    ,brand_name
    ,item_description
    ,product_size
    ,unit_of_measure
    ,department_key 
    ,department_name
    ,subdepartment_key
    ,subdepartment_name
    ,product_type_code
    ,product_type_desc
	,product_status_code 
	,product_status_desc 
    ,create_date_key
    ,change_date_key
    ,delete_date_key
)
SELECT
    T.upc
    ,T.brand_name
    ,T.item_description
    ,T.product_size
    ,T.unit_of_measure
    ,T.department_key
    ,T.department_name
    ,T.subdepartment_key
    ,T.subdepartment_name
    ,T.product_type_code
    ,T.product_type_desc
	,t.product_status_code 
	,t.product_status_desc 
    ,@dateKey
    ,19000101
    ,19000101
FROM product_dim_temp T 
LEFT OUTER JOIN product_dim_staging S ON 
    S.upc = T.upc
WHERE 
    S.product_key IS NULL

-- add new rows to product_dim
INSERT INTO product_dim (
    product_key
    ,upc 
    ,brand_name 
    ,item_description 
    ,product_size 
    ,unit_of_measure 
    ,department_key 
    ,department_name
    ,subdepartment_key
    ,subdepartment_name
    ,product_type_code
    ,product_type_desc
	,product_status_code 
	,product_status_desc 
    ,create_date_key
    ,change_date_key
    ,delete_date_key
)
SELECT     
    S.product_key
    ,S.upc
    ,S.brand_name
    ,S.item_description
    ,S.product_size
    ,S.unit_of_measure
    ,S.department_key 
    ,S.department_name
    ,S.subdepartment_key
    ,S.subdepartment_name
    ,S.product_type_code
    ,S.product_type_desc
	,S.product_status_code 
	,S.product_status_desc 
    ,S.create_date_key
    ,S.change_date_key
    ,S.delete_date_key
FROM product_dim_staging S 
LEFT OUTER JOIN product_dim dw ON 
    dw.upc = S.upc
WHERE 
    dw.product_key IS NULL

DECLARE @product_staging_upc_checksum TABLE (
	[upc] [char](13) NOT NULL,
	[checksum] [int] NOT NULL,
	PRIMARY KEY (upc)
)
INSERT @product_staging_upc_checksum SELECT 
	upc, 
	CHECKSUM(brand_name, item_description, product_size, unit_of_measure, department_key, department_name, subdepartment_key, subdepartment_name, product_type_code, product_type_desc, product_status_code, product_status_desc) AS checksum 
from product_dim_staging

DECLARE @temp_checksum TABLE (
	[upc] [char](13) NOT NULL,
	[checksum] [int] NOT NULL
	PRIMARY KEY (upc)
)

INSERT INTO @temp_checksum SELECT 
	upc, 
	CHECKSUM(brand_name, item_description, product_size, unit_of_measure, department_key, department_name, subdepartment_key, subdepartment_name, product_type_code, product_type_desc, product_status_code, product_status_desc) AS checksum 
FROM product_dim_temp

UPDATE s SET
    s.brand_name = t.brand_name
    ,s.item_description = t.item_description
    ,s.product_size = t.product_size
    ,s.unit_of_measure = t.unit_of_measure
    ,s.department_key = t.department_key
    ,s.department_name = t.department_name
    ,s.subdepartment_key = t.subdepartment_key
    ,s.subdepartment_name = t.subdepartment_name
    ,s.product_type_code = t.product_type_code
    ,s.product_type_desc = t.product_type_desc
	,product_status_code = t.product_status_code
	,product_status_desc = t.product_status_desc
	,s.change_date_key = @dateKey
FROM 
	product_dim_staging s
INNER JOIN product_dim_temp t ON
    t.upc = s.upc
WHERE 
    t.upc in (
        select sc.upc from @product_staging_upc_checksum sc
            inner join @temp_checksum t on t.upc = sc.upc
            where sc.checksum <> t.checksum )

DECLARE @product_staging_product_key_checksum TABLE (
	[product_key] INT NOT NULL,
	[checksum] [int] NOT NULL,
	PRIMARY KEY (product_key)
)
INSERT @product_staging_product_key_checksum SELECT 
	product_key, 
	checksum(
		upc, 
		brand_name, 
		item_description, 
		product_size, 
		unit_of_measure, 
		department_key, 
		department_name, 
		subdepartment_key, 
		subdepartment_name, 
		product_type_code, 
		product_type_desc, 
		product_status_code, 
		product_status_desc) as checksum 
FROM product_dim_staging

DECLARE @product_dim_checksum TABLE (
	[product_key] INT NOT NULL,
	[checksum] [int] NOT NULL
	PRIMARY KEY (product_key)
)

INSERT @product_dim_checksum SELECT 
	product_key, 
	checksum(
		upc, 
		brand_name, 
		item_description, 
		product_size, 
		unit_of_measure, 
		department_key, 
		department_name, 
		subdepartment_key, 
		subdepartment_name, 
		product_type_code, 
		product_type_desc) as checksum 
FROM product_dim

UPDATE p SET
    p.brand_name = s.brand_name
    ,p.item_description = s.item_description
    ,p.product_size = s.product_size
    ,p.unit_of_measure = s.unit_of_measure
    ,p.department_key = s.department_key
    ,p.department_name = s.department_name
    ,p.subdepartment_key = s.subdepartment_key
    ,p.subdepartment_name = s.subdepartment_name
    ,p.product_type_code = s.product_type_code
    ,p.product_type_desc = s.product_type_desc
	,p.product_status_code  = s.product_status_code
	,p.product_status_desc = s.product_status_desc
    ,p.change_date_key = s.change_date_key
FROM 
	product_dim p
INNER JOIN product_dim_staging s ON
    s.product_key = p.product_key
WHERE 
    s.product_key IN (
        SELECT sc.product_key FROM @product_staging_product_key_checksum sc
            INNER JOIN @product_dim_checksum dw ON dw.product_key = sc.product_key
            WHERE sc.checksum <> dw.checksum )

-- 'mark' deleted records
DECLARE @del_item TABLE (
	Upc CHAR(13) NOT NULL,
	PRIMARY KEY (Upc)
)
	
INSERT INTO @del_item SELECT UPC FROM product_dim p WHERE NOT EXISTS (
	SELECT upc FROM load_Item l WHERE l.upc = p.upc
)
UPDATE p SET 
	delete_date_key = @dateKey
FROM 
	product_dim p
INNER JOIN @del_item di ON
	di.upc = p.upc
WHERE
	p.delete_date_key = 19000101

-- resurrect deleted items
UPDATE product_dim SET 
	delete_date_key = 19000101 
WHERE 
	product_key IN (
		SELECT DISTINCT product_key from product_dim p WHERE 
			p.delete_date_key <> 19000101 
			AND EXISTS (
				SELECT upc FROM load_Item li WHERE li.Upc = p.upc
			)
	)


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DwLoad_ProductStore] 
	@dateKey INT
	,@posType VARCHAR(10)
	,@regRetailBucketKey INT
	,@memberPromotionBucket INT
AS

--DECLARE @posType VARCHAR(10); SET @posType = 'ISS45'
--DECLARE @regRetailBucketKey INT; SET @regRetailBucketKey = 1
--DECLARE @memberPromotionBucket INT; SET @memberPromotionBucket = 2

TRUNCATE TABLE product_store_dim_temp
INSERT product_store_dim_temp WITH (TABLOCKX) SELECT
	p.product_key
	,s.store_key
    ,ISNULL(supp.supplier_key, 0)
    ,0  -- lowest_unit_price
    ,CASE 
		WHEN l.PriceAmt IS NULL THEN 0
			WHEN l.PriceMult=1 OR l.PriceMult IS NULL OR PriceMult=0 THEN l.PriceAmt
			WHEN l.PriceMult>1 THEN l.PriceAmt / l.PriceMult
		END  -- normal_unit_price
    ,0  -- promoted_unit_price
    ,l.PosValid
	,@regRetailBucketKey
	,l.SupplierZoneId
	,0		-- unit_allow_amt
	,0		-- ext_bb_amt
	,0		-- ext_unit_cost
FROM 
	load_StoreItem l
INNER JOIN product_dim p ON
	p.upc = l.Upc
INNER JOIN store_dim s ON
	s.store_key = l.StoreId
INNER JOIN supplier_dim supp ON
    supp.supplier_id = l.SupplierId
LEFT OUTER JOIN supplier_product_dim spd ON
    spd.product_key = p.product_key
    AND spd.supplier_key = supp.supplier_key
	AND spd.supplier_zone_id = l.SupplierZoneId

-- calculate allowances/billbacks as of yesterday
DECLARE @today DATETIME; SELECT @today=CONVERT(VARCHAR,DATEADD(dd,-1,GETDATE()),101)

-- calculate unit_allow_amt
;WITH cte AS (
	SELECT
		p.product_key
		,la.StoreId AS store_key
		,supplier_key
		,SUM(la.AllowAmt) AS case_allow_amt
		,COUNT(la.Upc) AS allow_count
	FROM
		load_Allow la 
	INNER JOIN supplier_dim s ON
		s.supplier_Id = la.SupplierId
	INNER JOIN product_dim p ON
		p.upc = la.Upc
	WHERE
		la.StartDate <= @today
		AND la.EndDate >= @today
	GROUP BY 
		p.product_key
		,la.StoreId
		,s.supplier_key
)
UPDATE psdt SET
	unit_allow_amt = cte.case_allow_amt / spd.pack
FROM
	product_store_dim_temp psdt
INNER JOIN supplier_product_dim spd ON
	spd.product_key = psdt.product_key
	AND spd.supplier_key = psdt.primary_vendor_key
	AND spd.supplier_zone_id = psdt.supplier_zone_id
INNER JOIN cte ON
	cte.product_key = psdt.product_key
	AND cte.store_key = psdt.store_key
	AND cte.supplier_key = psdt.primary_vendor_key
		 
-- calculate ext_bb_amt
;WITH cte AS (
	SELECT
		p.product_key
		,ls.StoreId AS store_key
		,SUM(ls.BbAmt) AS ext_bb_amt
		,COUNT(ls.Upc) AS bb_count
	FROM
		load_ScanOption ls
	INNER JOIN product_dim p ON
		p.upc = ls.Upc
	WHERE
		ls.StartDate <= @today
		AND ls.EndDate >= @today
	GROUP BY 
		p.product_key
		,ls.StoreId
)
UPDATE psdt SET
	ext_bb_amt = cte.ext_bb_amt
FROM
	product_store_dim_temp psdt
INNER JOIN cte ON
	cte.product_key = psdt.product_key
	AND cte.store_key = psdt.store_key

-- calculate ext_unit_cost
UPDATE psdt SET
	ext_unit_cost = spd.base_unit_cost - psdt.unit_allow_amt - psdt.ext_bb_amt
FROM
	product_store_dim_temp psdt
INNER JOIN supplier_product_dim spd ON
	spd.product_key = psdt.product_key
	AND spd.supplier_key = psdt.primary_vendor_key
	AND spd.supplier_zone_id = psdt.supplier_zone_id


-- get the regular retails
TRUNCATE TABLE temp_price
DROP INDEX [temp_price].[IX_batchid]
DROP INDEX [temp_price].[IX_upc_storeid_price_limit]

IF @posType = 'ISS45' BEGIN
	INSERT INTO temp_price WITH (TABLOCKX) 
		(storeid, upc, reg_price, reg_dealqty, reg_unit_price, 
		batchid, batch_price_method, batch_price, batch_multiple, batch_promo_code, batch_deal_price, batch_multi_price_group,
		coupon_upc, coupon_type, coupon_price, coupon_deal_qty, coupon_pts_only, limit,
		price, coupon_reduction_amount, scan_price, handled, pricing_bucket_key, priority)
	SELECT 
		si.StoreId, si.Upc, si.PriceAmt, si.PriceMult, si.PriceAmt / si.PriceMult,
		NULL, NULL, NULL, NULL, NULL, NULL, NULL, 
		NULL, NULL, NULL, NULL, NULL, NULL,
		CASE 
			WHEN SUBSTRING(si.Upc, 1,3) = '002' THEN si.PriceAmt
			ELSE si.PriceAmt / si.PriceMult
		END,  -- price
		0, -- coupon_reduction_amount
		CASE 
			WHEN SUBSTRING(si.Upc, 1,3) = '002' THEN si.PriceAmt
			ELSE si.PriceAmt / si.PriceMult -- scan_price
		END,
		1, -- handled
		@regRetailBucketKey,
		0  -- priority
	FROM 
		load_StoreItem si WITH (NOLOCK)
END

-- TODO: implementation
--IF @posType = 'IBMSA' BEGIN
--END

-- push all active batches into temp_price 
-- for batches that have a type where productbatchtype.affectspricing=1 (yes)
INSERT INTO temp_price WITH (TABLOCKX) (
	storeid, upc, reg_price, reg_dealqty, reg_unit_price, -- regular retail stuff
	batchid, batch_price_method, batch_price, batch_multiple,  -- 'straight batch price stuff
	batch_promo_code, batch_deal_price, batch_multi_price_group, coupon_upc, coupon_type, coupon_price, coupon_deal_qty, coupon_pts_only, limit,
	price, coupon_reduction_amount, scan_price, handled, pricing_bucket_key, priority)
SELECT
	promp.StoreId,
	promp.upc,
	si.PriceAmt,
	si.PriceMult,
	si.PriceAmt / si.PriceMult,
	
	promp.BatchId,
	CASE
		WHEN @posType = 'ISS45' THEN 'A'
		-- FUTURE: WHEN @posType = 'IBMSA' THEN promp.IbmPriceMethod
	End, -- batch_price_method
	promp.PriceAmt,
	promp.PriceMult,
	
	-- IBM SA fields
	0, -- promo code
	0, -- pbd.batchdealprice,
	0, -- pbd.batchmultipricegroup,
	NULL, -- coup_ppn.upc,
	NULL, -- coup_ppn.pricemethod,
	0.0, -- coup_ppn.price,
	0, -- coup_ppn.dealqty,
	0, -- coup_reg.advertized,
	NULL, -- limit
	
	NULL, NULL, NULL, NULL, ISNULL(bu.pricing_bucket_key, 0), bu.priority
FROM 
	load_PromPrice promp WITH (NOLOCK)
INNER JOIN load_StoreItem si WITH (NOLOCK) ON
	si.upc = promp.upc
	AND si.StoreId = promp.StoreId
INNER JOIN pricing_bucket_dim bu WITH (NOLOCK) ON
	bu.pricing_bucket_key = promp.ProductBatchTypeId
	AND bu.affects_pricing = 1
WHERE 
	promp.StartDate <= CONVERT(VARCHAR,DATEADD(dd, -1, GETDATE()),101)
	AND promp.EndDate >= CONVERT(VARCHAR,DATEADD(dd, -1, GETDATE()),101)

CREATE  CLUSTERED  INDEX [IX_upc_storeid_price_limit] ON [dbo].[temp_price]([upc], [storeid], [price], [limit]) ON [PRIMARY]
CREATE  INDEX [IX_batchid] ON [dbo].[temp_price]([batchid]) ON [PRIMARY]

---- TODO: maybe skip this, maybe IBM only?
---- copy price, dealqty, pricemethod to all batches with zero price, from the 'lowest' batch price
--SELECT @timeStr = CONVERT(VARCHAR, GETDATE(), 109)
--RAISERROR('[%s] finding low batch price in temp_price',10,1, @timeStr) WITH NOWAIT
--SELECT DISTINCT 
--	storeid, 
--	upc,
--	(SELECT TOP 1 
--		batchid 
--	FROM 
--		temp_price p2 
--	WHERE 
--		p2.storeid = p1.storeid 
--		AND p2.upc = p1.upc 
--		AND batchid IS NOT NULL 
--		AND batch_price > 0	
--	ORDER BY 
--		p2.batch_price, 
--		p2.limit ) as batchid
--INTO
--	#lowestBatch
--FROM
--	temp_price p1
--WHERE
--	batchid IS NOT NULL
	
---- TODO: maybe skip this
--SELECT @timeStr = CONVERT(VARCHAR, GETDATE(), 109)
--RAISERROR('[%s] updating zero batch prices with low batch price in temp_price',10,1, @timeStr) WITH NOWAIT
--UPDATE p SET
--	p.batch_price = p2.batch_price,
--	p.batch_multiple = p2.batch_multiple,
--	p.batch_price_method = p2.batch_price_method
--FROM
--	temp_price p WITH (tablockx) 
--INNER JOIN #lowestBatch l ON
--	l.storeid = p.storeid
--	AND l.upc = p.upc
--INNER JOIN temp_price p2 ON
--	p2.upc = l.upc
--	AND p2.batchid = l.batchid
--	AND p2.storeid = l.storeid
--WHERE
--	p.batchid IS NOT NULL 
--	AND p.batch_price = 0

---- TODO: maybe skip this
---- if there are still zero batch prices, replace zero batch price with regular retail
--SELECT @timeStr = CONVERT(VARCHAR, GETDATE(), 109)
--RAISERROR('[%s] updating zero batch prices regular retail temp_price',10,1, @timeStr) WITH NOWAIT
--UPDATE temp_price WITH (tablockx) SET 
--	batch_price = reg_price,
--	batch_multiple = reg_dealqty,
--	batch_price_method = reg_price_method
--WHERE 
--	batchid IS NOT NULL 
--	AND batch_price = 0

--UPDATE temp_price WITH (tablockx) SET 
--	batch_multiple = reg_dealqty 
--WHERE 
--	batchid IS NOT NULL 
--	AND batch_multiple = 0

-- extend batch_price, batch_multiple to unit price
UPDATE temp_price WITH (tablockx) SET 
	price = CASE
				WHEN SUBSTRING(upc,1,3) = '002' THEN batch_price
				ELSE batch_price / batch_multiple 
			END
WHERE 
	batchid IS NOT NULL

-- handle promotional prices that are straight pricing (eg no coupons attached)
-- this is identical for ISS45 AND IBMSA
UPDATE temp_price WITH (tablockx) SET 
	coupon_reduction_amount=0, 
	scan_price=price,
	handled = 1
WHERE 
	batchid IS NOT NULL 
	AND coupon_upc IS NULL
	AND batch_price_method IN ('A', 'B', 'C')

-- TODO: implementation
--IF @posType = 'IBMSA' BEGIN
	---- isolate limit for coupons where User3=0 (rightmost char OF a 2-digit integer)
	--UPDATE p SET 
	--	limit = coupon_deal_qty % 10 
	--FROM
	--	temp_price p WITH (TABLOCKX)
	--INNER JOIN raw_ProductPriceNormal AS ppc ON
	--	ppc.Upc = p.coupon_upc
	--	AND ppc.PriceType ='N'
	--	AND ppc.StoreId = p.storeid
	--INNER JOIN raw_Register4680 reg ON
	--	reg.Upc = p.coupon_upc
	--	AND reg.StoreID = p.storeid
	--WHERE 
	--	p.coupon_deal_qty IS NOT NULL
	--	AND ISNULL(reg.User3, 0) = 0

	---- if coupon's User3 flag is on (Big Cpn Limit), limit=entire DealQty
	--UPDATE p SET 
	--	limit = coupon_deal_qty
	--FROM
	--	temp_price p WITH (TABLOCKX)
	--INNER JOIN raw_ProductPriceNormal ppc ON
	--	ppc.Upc = p.coupon_upc
	--	AND ppc.PriceType ='N'
	--	AND ppc.StoreId = p.storeid
	--INNER JOIN raw_Register4680 reg ON
	--	reg.Upc = p.coupon_upc
	--	AND reg.StoreID = p.storeid
	--WHERE 
	--	p.coupon_deal_qty IS NOT NULL
	--	AND ISNULL(reg.User3, 0) = 1
		
	---- calculate coupon_reduction_amount for %off promotions
	--UPDATE temp_price WITH (tablockx) SET 
	--	coupon_reduction_amount = ((batch_price/batch_multiple) * ((coupon_price-980) * .1)), 
	--	handled=2 
	--WHERE coupon_type = 'E' AND coupon_price > 980.00 AND coupon_price < 990.00 AND handled IS NULL
	--UPDATE temp_price SET 
	--	coupon_reduction_amount = ((batch_price/batch_multiple) * ((coupon_price-990) * .1)), 
	--	handled=3 
	--WHERE coupon_type = 'E' AND coupon_price > 990.00 AND coupon_price < 999.01 AND handled IS NULL

	---- cents OFF
	--UPDATE temp_price WITH (tablockx) SET 
	--	coupon_reduction_amount = coupon_price / limit, 
	--	handled=4 
	--WHERE coupon_type = 'A' AND coupon_price > 0.01 AND (coupon_pts_only IS NULL OR coupon_pts_only = 0) AND handled IS NULL

	---- cents OFF 'D' coupon
	--UPDATE temp_price WITH (tablockx) SET 
	--	coupon_reduction_amount = coupon_price / limit, 
	--	handled=12 
	--WHERE coupon_type = 'D' AND coupon_price > 0.01 AND (coupon_pts_only IS NULL OR coupon_pts_only = 0) AND handled IS NULL

	---- net price 
	--UPDATE temp_price WITH (tablockx) SET 
	--	coupon_reduction_amount = price - coupon_price, 
	--	handled = 5 
	--WHERE coupon_type = 'E' AND coupon_price >= 0 AND limit = 1 AND handled IS NULL

	---- calculate the actual scanning price (apply coupon_reduction_amount)
	--UPDATE temp_price WITH (tablockx) SET 
	--	scan_price = price - coupon_reduction_amount 
	--WHERE handled IS NOT NULL

	---- BxGy
	--UPDATE temp_price WITH (tablockx) SET 
	--	coupon_reduction_amount = price / limit, 
	--	scan_price = price - (price/limit), 
	--	handled=6 
	--WHERE batchid IS NOT NULL AND coupon_type='E' AND coupon_price = 0 AND limit > 1 AND handled IS NULL

	---- qty/price (e.g. 2/$5)
	--UPDATE temp_price WITH (tablockx) SET 
	--	scan_price = coupon_price / limit, 
	--	coupon_reduction_amount = price - (coupon_price/limit), 
	--	handled = 7 
	--WHERE coupon_type = 'E' AND coupon_price <> 0 AND coupon_price > reg_unit_price AND handled IS NULL

	---- steves on 2008-09-29 ignore turkey buck pricing schemes
	---- for purposes of calculating price history in data warehouse
	---- turkey buck
	---- SET scan_price TO 0.02 TO make it beat ALL pricing schemes EXCEPT 'meal deal'
	---- UPDATE temp_price WITH (tablockx) SET 
	---- 	scan_price = 0.02, 
	---- 	coupon_reduction_amount = price - 0.02, 
	---- 	handled = 8 
	---- WHERE coupon_type = 'A' AND coupon_pts_only = 1 AND handled IS NULL

	---- steves on 2008-09-29 ignore this pricing schemes
	---- for purposes of calculating price history in data warehouse
	---- meal deal
	---- SET scan_price TO 0.01 TO make it beat ALL pricing schemes including 'turkey buck'
	---- UPDATE temp_price WITH (tablockx) SET 
	---- 	scan_price = coupon_price / limit, 
	---- 	coupon_reduction_amount = price - (coupon_price/limit), 
	---- 	handled = 9 
	---- WHERE coupon_type = 'D' AND coupon_price = .01 AND handled IS NULL

	---- steves on 2008-09-29 ignore this pricing schemes
	---- for purposes of calculating price history in data warehouse
	---- freebie
	---- UPDATE temp_price WITH (tablockx) SET 
	---- 	coupon_reduction_amount = price, 
	---- 	scan_price = 0.00, 
	---- 	handled=10 
	---- WHERE batchid IS NOT NULL AND coupon_type='E' AND coupon_price = 0 AND limit = 1 AND handled IS NULL

	---- PM D, Reduced $ w/ Minimum Qty
	--UPDATE temp_price WITH (tablockx) SET 
	--	scan_price = batch_deal_price
	--	,handled = 10
	--WHERE batch_price_method = 'D' AND ISNULL(coupon_upc,'') = ''

	---- PM E, Reduced $ w/ Limited Qty
	--UPDATE temp_price WITH (tablockx) SET 
	--	scan_price = batch_deal_price
	--	,handled = 11
	--WHERE batch_price_method = 'E' AND ISNULL(coupon_upc,'') = ''

	---- net value with limit
	--UPDATE temp_price SET 
	--	coupon_reduction_amount = price - coupon_price, 
	--	scan_price = coupon_price,
	--	price = coupon_price ,
	--	handled = 12 
	--WHERE coupon_type = 'E' AND coupon_price <> 0 AND coupon_price <= reg_unit_price AND handled IS NULL
--END

-- get just the lowest prices, 1 row per upc & store
DECLARE @lowprice TABLE (
	StoreId SMALLINT NOT NULL,
	Upc CHAR(13) NOT NULL,
	row_id INT NOT NULL,
	PRIMARY KEY(Upc, StoreID)
)
INSERT INTO @lowPrice (StoreId, Upc, row_id) SELECT DISTINCT 
	storeid, 
	upc,
	(SELECT TOP 1 
		row_id
	FROM 
		temp_price p2 WITH (TABLOCKX)
	WHERE 
		p2.storeid = p1.storeid 
		AND p2.upc = p1.upc 
		AND p2.handled IS NOT NULL
	ORDER BY 
		p2.scan_price, 
		p2.limit,
		p2.priority DESC) as row_id
FROM
	temp_price p1

-- set promoted_unit_price on product_store_dim_temp
UPDATE pst SET
	pst.promoted_unit_price = p2.scan_price,
	pst.pricing_bucket_key = p2.pricing_bucket_key
FROM
	product_store_dim_temp pst WITH (TABLOCKX)
INNER JOIN product_dim p WITH (TABLOCKX) ON
	p.product_key = pst.product_key
INNER JOIN @lowPrice l ON
	l.StoreId = pst.store_key
	AND l.Upc = p.upc
	AND l.row_id IS NOT NULL
INNER JOIN temp_price p2 WITH (TABLOCKX) ON
	p2.storeid = l.storeid
	AND p2.upc = l.upc
	AND p2.row_id = l.row_id
WHERE
	p2.batchid IS NOT NULL


-- pick out the lowest price
UPDATE product_store_dim_temp SET
	lowest_unit_price = CASE
	    WHEN promoted_unit_price < normal_unit_price AND promoted_unit_price <> 0 THEN promoted_unit_price
	    ELSE normal_unit_price
	END

-- special processing for for ISS45, 
IF @posType = 'ISS45' AND @memberPromotionBucket > 0 BEGIN

	-- for any items that were in active member promotions yesterday, force them into @memberPromotionBucket
	DECLARE @yestDate DATETIME
	SELECT @yestDate = (SELECT calendar_date FROM date_dim WHERE absolute_day = (SELECT absolute_day-1 FROM date_dim WHERE date_key = @dateKey))
	DECLARE @bucketLock TABLE (
		product_key INT NOT NULL,
		store_key INT NOT NULL,
		pricing_bucket_key INT NOT NULL
	)
	INSERT INTO @bucketLock SELECT
		pst.product_key
		,pst.store_key
		,@memberPromotionBucket
	FROM 
		product_store_dim_temp pst
	INNER JOIN product_dim p ON
		p.product_key = pst.product_key
	INNER JOIN load_MemberProm mp ON
		mp.StoreId = pst.store_key
		AND mp.Upc = p.upc
	WHERE
		mp.STRT_DATE <= @yestDate
		AND mp.END_DATE >= @yestDate
		AND 
		(
			(mp.SUN_FG=1 AND DATEPART(weekday, @yestDate) = 1)
			OR (mp.MON_FG=1 AND DATEPART(weekday, @yestDate) = 2)
			OR (mp.TUE_FG=1 AND DATEPART(weekday, @yestDate) = 3)
			OR (mp.WED_FG=1 AND DATEPART(weekday, @yestDate) = 4)
			OR (mp.THU_FG=1 AND DATEPART(weekday, @yestDate) = 5)
			OR (mp.FRI_FG=1 AND DATEPART(weekday, @yestDate) = 6)
			OR (mp.SAT_FG=1 AND DATEPART(weekday, @yestDate) = 7)
		)

	-- also force subdepartment_dim.rewards_given_upc_code to @memberPromotionBucket
	INSERT INTO @bucketLock SELECT
		p.product_key
		,s.store_key
		,@memberPromotionBucket
	FROM
		subdepartment_dim sd
	INNER JOIN product_dim p ON
		p.upc = sd.rewards_given_upc_code
	CROSS JOIN store_dim s

	UPDATE psdt SET
		pricing_bucket_key = bl.pricing_bucket_key
	FROM
		product_store_dim_temp psdt
	INNER JOIN @bucketLock bl ON
		bl.product_key = psdt.product_key
		AND bl.store_key = psdt.store_key
END


-- add new records to product_store_dim
INSERT INTO product_store_dim (
    product_key
    ,store_key
    ,primary_vendor_key
    ,lowest_unit_price
    ,normal_unit_price
    ,promoted_unit_price
    ,pos_valid_flag
    ,create_date_key
    ,change_date_key
    ,delete_date_key
	,pricing_bucket_key
	,supplier_zone_id
	,unit_allow_amt
	,ext_bb_amt
	,ext_unit_cost
)
SELECT     
    ps.product_key
    ,ps.store_key
    ,ps.primary_vendor_key
    ,ps.lowest_unit_price
    ,ps.normal_unit_price
    ,ps.promoted_unit_price
    ,ps.pos_valid_flag
    ,@dateKey
    ,19000101
    ,19000101
	,ps.pricing_bucket_key
	,ps.supplier_zone_id
	,ps.unit_allow_amt
	,ps.ext_bb_amt
	,ps.ext_unit_cost
FROM 
	product_store_dim_temp ps 
LEFT OUTER JOIN product_store_dim dw ON 
    dw.product_key = ps.product_key
    AND dw.store_key = ps.store_key
WHERE 
    dw.product_key IS NULL
    AND dw.store_key IS NULL

-- calculate checksums to get differences betwen _temp and _dimension 
DECLARE @product_store_dim_temp_checksum TABLE(
	product_key INT NOT NULL,
	store_key INT NOT NULL,
	checksum INT NOT NULL,
	PRIMARY KEY (product_key, store_key)
)
INSERT @product_store_dim_temp_checksum SELECT 
    product_key, 
    store_key,
    checksum(primary_vendor_key, lowest_unit_price, normal_unit_price, pricing_bucket_key, supplier_zone_id, unit_allow_amt, ext_bb_amt, ext_unit_cost) as checksum 
FROM product_store_dim_temp WITH (TABLOCKX)

DECLARE @product_store_dim_checksum TABLE(
	product_key INT NOT NULL,
	store_key INT NOT NULL,
	checksum INT NOT NULL,
	PRIMARY KEY (product_key, store_key)
)
INSERT @product_store_dim_checksum SELECT 
    product_key, 
    store_key,
    CHECKSUM(primary_vendor_key, lowest_unit_price, normal_unit_price, pricing_bucket_key, supplier_zone_id, unit_allow_amt, ext_bb_amt, ext_unit_cost) as checksum 
    FROM product_store_dim WITH (TABLOCKX)

UPDATE d SET
	d.primary_vendor_key = t.primary_vendor_key
	,d.lowest_unit_price = t.lowest_unit_price
	,d.normal_unit_price = t.normal_unit_price
	,d.promoted_unit_price = t.promoted_unit_price
	,d.pos_valid_flag = t.pos_valid_flag
	,d.change_date_key = @dateKey
	,d.pricing_bucket_key = t.pricing_bucket_key
	,d.supplier_zone_id = t.supplier_zone_id
	,d.unit_allow_amt = t.unit_allow_amt
	,d.ext_bb_amt = t.ext_bb_amt
	,d.ext_unit_cost = t.ext_unit_cost
FROM 
	product_store_dim d
INNER JOIN product_store_dim_temp t ON
    t.product_key = d.product_key
    and t.store_key = d.store_key
INNER JOIN @product_store_dim_temp_checksum tc ON
    tc.product_key = d.product_key
    and tc.store_key = d.store_key
INNER JOIN @product_store_dim_checksum dc ON
    dc.product_key = d.product_key
    and dc.store_key = d.store_key
WHERE 
    tc.checksum <> dc.checksum

-- prod_store_dim_history
DECLARE @psdhLatestChkSum TABLE (
	product_key INT NOT NULL,
	store_key INT NOT NULL,
	date_key INT NOT NULL,
	chksum INT NOT NULL,
	PRIMARY KEY (product_key, store_key, date_key)
)
;WITH CteLatest AS (
	SELECT
		product_key
		,store_key
		,MAX(date_key) AS date_key
	FROM
		prod_store_dim_history
	GROUP BY 
		product_key
		,store_key
)
INSERT INTO @psdhLatestChkSum SELECT
	cte.product_key
	,cte.store_key
	,cte.date_key
	,CHECKSUM(
		psdh.lowest_unit_price, 
		psdh.normal_unit_price, 
		psdh.pricing_bucket_key, 
		psdh.pri_supplier_key, 
		psdh.supplier_zone_id, 
		psdh.case_pack, 
		psdh.base_unit_cost, 
		psdh.ext_unit_cost, 
		psdh.unit_allow_amt, 
		psdh.markup_amt, 
		psdh.ext_bb_amt)
FROM
	CteLatest cte
INNER JOIN prod_store_dim_history psdh ON
	psdh.product_key = cte.product_key
	AND psdh.store_key = cte.store_key
	AND psdh.date_key = cte.date_key

DECLARE @psdhCurrChkSum TABLE (
	product_key INT NOT NULL,
	store_key INT NOT NULL,
	date_key INT NOT NULL,
	chksum INT NOT NULL,
	PRIMARY KEY (product_key, store_key, date_key)
)

INSERT INTO @psdhCurrChkSum SELECT 
	psd.product_key
	,psd.store_key
	,@dateKey
	,CHECKSUM(
		CAST(psd.lowest_unit_price AS DECIMAL(18,4)), 
		CAST(psd.normal_unit_price AS DECIMAL(18,4)), 
		psd.pricing_bucket_key, 
		psd.primary_vendor_key, 
		psd.supplier_zone_id, 
		spd.pack, 
		CAST(spd.base_unit_cost AS DECIMAL(18,4)), 
		psd.ext_unit_cost, 
		psd.unit_allow_amt, 
		CAST(spd.markup_amount AS DECIMAL(18,4)), 
		psd.ext_bb_amt
	)
FROM 
	product_store_dim psd
INNER JOIN supplier_product_dim spd ON
	spd.supplier_key = psd.primary_vendor_key
	AND spd.product_key = psd.product_key
	AND spd.supplier_zone_id = psd.supplier_zone_id

-- update existing prod_store_dim_history
;WITH cte AS (
	SELECT 
		latest.product_key
		,latest.store_key
	FROM
		@psdhLatestChkSum latest
	INNER JOIN @psdhCurrChkSum curr ON
		curr.product_key = latest.product_key
		AND curr.store_key = latest.store_key
		AND curr.chksum <> latest.chksum
)
UPDATE psdh SET
	psdh.lowest_unit_price = psd.lowest_unit_price
	,psdh.normal_unit_price = psd.normal_unit_price
	,psdh.pricing_bucket_key = psd.pricing_bucket_key
	,psdh.pri_supplier_key = psd.primary_vendor_key
	,psdh.supplier_zone_id = psd.supplier_zone_id
	,psdh.case_pack = spd.pack
	,psdh.base_unit_cost = spd.base_unit_cost
	,psdh.ext_unit_cost = psd.ext_unit_cost
	,psdh.unit_allow_amt = psd.unit_allow_amt
	,psdh.markup_amt = spd.markup_amount
	,psdh.ext_bb_amt = psd.ext_bb_amt
FROM
	cte
INNER JOIN prod_store_dim_history psdh ON
	psdh.product_key = cte.product_key
	AND psdh.store_key = cte.store_key
	AND psdh.date_key = @datekey
INNER JOIN product_store_dim psd ON
	psd.product_key = cte.product_key
	AND psd.store_key = cte.store_key
INNER JOIN supplier_product_dim spd ON
	spd.product_key = cte.product_key
	AND spd.supplier_key = psd.primary_vendor_key
	AND spd.supplier_zone_id = psd.supplier_zone_id

-- insert new prod_store_dim_history (existing items)
;WITH cte AS (
	SELECT 
		latest.product_key
		,latest.store_key
	FROM
		@psdhLatestChkSum latest
	INNER JOIN @psdhCurrChkSum curr ON
		curr.product_key = latest.product_key
		AND curr.store_key = latest.store_key
		AND curr.chksum <> latest.chksum
)
INSERT INTO prod_store_dim_history SELECT
	@dateKey
	,cte.product_key
	,cte.store_key
	,psd.lowest_unit_price
	,psd.normal_unit_price
	,psd.pricing_bucket_key
	,psd.primary_vendor_key
	,psd.supplier_zone_id
	,spd.pack
	,spd.base_unit_cost
	,psd.ext_unit_cost
	,psd.unit_allow_amt
	,spd.markup_amount
	,psd.ext_bb_amt
	,0	-- review_flag (TODO: drop column)
FROM
	cte
LEFT OUTER JOIN prod_store_dim_history psdh ON
	psdh.product_key = cte.product_key
	AND psdh.store_key = cte.store_key
	AND psdh.date_key = @dateKey
INNER JOIN product_store_dim psd ON
	psd.product_key = cte.product_key
	AND psd.store_key = cte.store_key
INNER JOIN supplier_product_dim spd ON
	spd.product_key = cte.product_key
	AND spd.supplier_key = psd.primary_vendor_key
	AND spd.supplier_zone_id = psd.supplier_zone_id
WHERE
	psdh.product_key IS NULL
	AND psdh.store_key IS NULL
	AND psdh.date_key IS NULL


-- insert new prod_store_dim_history (new items)
;WITH cte AS (
	SELECT 
		curr.product_key
		,curr.store_key
	FROM
		@psdhCurrChkSum curr
	LEFT OUTER JOIN @psdhLatestChkSum latest ON
		latest.product_key = curr.product_key
		AND latest.store_key = curr.store_key
	WHERE
		latest.product_key IS NULL
		AND latest.store_key IS NULL
)
INSERT INTO prod_store_dim_history SELECT
	@dateKey
	,cte.product_key
	,cte.store_key
	,psd.lowest_unit_price
	,psd.normal_unit_price
	,psd.pricing_bucket_key
	,psd.primary_vendor_key
	,psd.supplier_zone_id
	,spd.pack
	,spd.base_unit_cost
	,psd.ext_unit_cost
	,psd.unit_allow_amt
	,spd.markup_amount
	,psd.ext_bb_amt
	,0	-- review_flag (TODO: drop column)
FROM
	cte
LEFT OUTER JOIN prod_store_dim_history psdh ON
	psdh.product_key = cte.product_key
	AND psdh.store_key = cte.store_key
	AND psdh.date_key = @dateKey
INNER JOIN product_store_dim psd ON
	psd.product_key = cte.product_key
	AND psd.store_key = cte.store_key
INNER JOIN supplier_product_dim spd ON
	spd.product_key = cte.product_key
	AND spd.supplier_key = psd.primary_vendor_key
	AND spd.supplier_zone_id = psd.supplier_zone_id
WHERE
	psdh.product_key IS NULL
	AND psdh.store_key IS NULL
	AND psdh.date_key IS NULL

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[DwLoad_Supplier] 
	@dateKey INT
AS


-- add new rows to product_staging
INSERT INTO supplier_dim_staging (
	supplier_Id
	,supplier_Name
	,SupplierShortName
	,create_date_key
	,change_date_key
	,delete_date_key
)
SELECT
	l.SupplierId
	,l.SupplierName
	,l.SupplierShortName
    ,@dateKey
    ,19000101
    ,19000101
FROM load_Supplier l
LEFT OUTER JOIN supplier_dim_staging S ON 
    s.supplier_id = l.supplierid
WHERE 
    s.supplier_key IS NULL

-- add new rows to supplier_dim
INSERT INTO supplier_dim (
	supplier_key
	,supplier_Id
	,supplier_Name
	,SupplierShortName
	,create_date_key
	,change_date_key
	,delete_date_key
) SELECT 
	s.supplier_key
	,s.supplier_Id
	,s.supplier_Name
	,s.SupplierShortName
	,s.create_date_key
	,s.change_date_key
	,s.delete_date_key
FROM 
	supplier_dim_staging s
LEFT OUTER JOIN supplier_dim d ON 
    d.supplier_key = S.supplier_key
WHERE 
    d.supplier_key IS NULL

-- process changes from raw -> staging
DECLARE @supplier_staging_supplier_id_checksum TABLE (
	supplier_id VARCHAR(15) NOT NULL,
	checksum INT NOT NULL,
	PRIMARY KEY (supplier_id)
)	
INSERT @supplier_staging_supplier_id_checksum SELECT supplier_id, CHECKSUM(
	Supplier_Id, 
	Supplier_Name, 
	SupplierShortName) 
AS checksum from supplier_dim_staging

-- DROP TABLE #temp_checksum 
DECLARE @temp_checksum TABLE (
	SupplierId VARCHAR(15) NOT NULL,
	checksum INT NOT NULL
)
INSERT INTO @temp_checksum SELECT supplierid, CHECKSUM(SupplierId, SupplierName, SupplierShortName) as checksum from load_Supplier
UPDATE s SET
	s.Supplier_Id = l.SupplierId
	,s.Supplier_Name = l.SupplierName
	,s.SupplierShortName  = l.SupplierShortName 
	,s.change_date_key = @dateKey
FROM 
	supplier_dim_staging s
INNER JOIN load_Supplier l ON
    l.supplierid = s.supplier_id
WHERE 
    l.supplierid in (
        select sc.supplier_id from @supplier_staging_supplier_id_checksum sc
            inner join @temp_checksum t on t.supplierid = sc.supplier_id
            where sc.checksum <> t.checksum )

DECLARE @supplier_staging_supplier_key_checksum TABLE (
	supplier_key INT NOT NULL,
	checksum INT NOT NULL,
	PRIMARY KEY(supplier_key)
)
INSERT @supplier_staging_supplier_key_checksum SELECT supplier_key, CHECKSUM(Supplier_Id, Supplier_Name, SupplierShortName) as checksum from supplier_dim_staging
 
DECLARE @supplier_dim_supplier_key_checksum TABLE (
	supplier_key INT NOT NULL,
	checksum INT NOT NULL,
	PRIMARY KEY(supplier_key)
)
INSERT @supplier_dim_supplier_key_checksum SELECT supplier_key, CHECKSUM(supplier_Id, supplier_Name, SupplierShortName) from supplier_dim
 
UPDATE d SET
	d.supplier_Id = s.supplier_Id
	,d.supplier_Name = s.supplier_Name
	,d.SupplierShortName = s.SupplierShortName
	,d.create_date_key = s.create_date_key
	,d.change_date_key = s.change_date_key
	,d.delete_date_key = s.delete_date_key
FROM 
	supplier_dim d
INNER JOIN supplier_dim_staging s ON
    s.supplier_key = d.supplier_key
WHERE 
    s.supplier_key in (
        SELECT sc.supplier_key FROM @supplier_staging_supplier_key_checksum sc
            INNER JOIN @supplier_dim_supplier_key_checksum dw on dw.supplier_key = sc.supplier_key
            WHERE sc.checksum <> dw.checksum )


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DwLoad_SupplierItem] 
	@dateKey INT
AS

TRUNCATE TABLE supplier_product_dim_temp
INSERT supplier_product_dim_temp WITH (TABLOCKX) SELECT
	p.product_key
	,s.supplier_key
	,pack=packagesize
    ,sku=CASE
        when suppliersku = '0000000000000' THEN ''
        else ISNULL(suppliersku, '') 
	END
    ,base_unit_cost=CASE
				when packagesize = 0 THEN 0
				when packagesize IS NULL THEN 0
				else ISNULL(productcost, 0)/packagesize 
	END
	,markup_amount = l.SplitCharge
	,supplier_zone_id = l.SupplierZoneId
FROM 
	load_SupplierItem l
INNER JOIN product_dim p ON
    p.upc = l.upc
INNER JOIN supplier_dim s ON
    s.supplier_id = l.supplierid

-- add new records to supplier_product_dim
INSERT INTO supplier_product_dim (
    product_key,
    supplier_key, 
    pack,        
    sku,           
    base_unit_cost, 
	markup_amount,
    create_date_key,
    change_date_key,
    delete_date_key,
	supplier_zone_id
)
SELECT     
    t.product_key,
    t.supplier_key, 
    t.pack,        
    t.sku,           
    t.base_unit_cost, 
	t.markup_amount,
    @dateKey,
    19000101,
    19000101,
	t.supplier_zone_id
FROM 
	supplier_product_dim_temp t 
LEFT OUTER JOIN supplier_product_dim d ON 
    d.product_key = t.product_key
    AND d.supplier_key = t.supplier_key
	AND d.supplier_zone_id = t.supplier_zone_id
WHERE 
    d.product_key IS NULL
    AND d.supplier_key IS NULL
	AND d.supplier_zone_id IS NULL

-- find rows to mark as deleted
DECLARE @deleteKeys TABLE (
	product_key INT NOT NULL,
	supplier_key INT NOT NULL,
	supplier_zone_id INT NOT NULL
)
INSERT INTO @deleteKeys SELECT
	spd.product_key
	,spd.supplier_key
	,spd.supplier_zone_id
FROM
	supplier_product_dim spd 
LEFT OUTER JOIN supplier_product_dim_temp t ON
	t.supplier_key = spd.supplier_key
	AND t.product_key = spd.product_key
	AND t.supplier_zone_id = spd.supplier_zone_id
WHERE
	t.supplier_key IS NULL
	and t.product_key IS NULL
	AND t.supplier_zone_id IS NULL
	AND spd.delete_date_key = 19000101

-- mark rows as deleted
UPDATE spd SET
	delete_date_key = @dateKey
FROM
	supplier_product_dim spd
INNER JOIN @deleteKeys k ON
	k.product_key = spd.product_key
	AND k.supplier_key = spd.supplier_key
	AND k.supplier_zone_id = spd.supplier_zone_id

-- calculate checksums to get differences betwen _temp and _dimension
-- specifying '19000101' for delete_date_key is necessary to 'resurrect' 
-- suplierproduct records there went away and then come back later on the same item.
DECLARE @supplier_product_temp_checksum TABLE (
	product_key INT NOT NULL,
	supplier_key INT NOT NULL,
	supplier_zone_id INT NOT NULL,
	checksum INT NOT NULL,
	PRIMARY KEY(product_key, supplier_key, supplier_zone_id)
)
INSERT @supplier_product_temp_checksum SELECT 
    product_key, 
    supplier_key, 
	supplier_zone_id,
    checksum(pack,sku,base_unit_cost,markup_amount,19000101) as checksum 
    from supplier_product_dim_temp

DECLARE @supplier_product_dim_checksum TABLE (
	product_key INT NOT NULL,
	supplier_key INT NOT NULL,
	supplier_zone_id INT NOT NULL,
	checksum INT NOT NULL,
	PRIMARY KEY(product_key, supplier_key, supplier_zone_id)
)
INSERT @supplier_product_dim_checksum SELECT 
    product_key, 
    supplier_key,
	supplier_zone_id,
    checksum(pack,sku,base_unit_cost,markup_amount,delete_date_key) as checksum 
    from supplier_product_dim

UPDATE d SET
    d.pack = t.pack,
    d.sku = t.sku,
    d.base_unit_cost = t.base_unit_cost,
    d.change_date_key = @dateKey,
	d.delete_date_key = 19000101,
	d.markup_amount = t.markup_amount
FROM 
	supplier_product_dim d
INNER JOIN supplier_product_dim_temp t on
    t.supplier_key = d.supplier_key
    and t.product_key = d.product_key
	and t.supplier_zone_id = d.supplier_zone_id
INNER JOIN @supplier_product_temp_checksum tc on
    tc.supplier_key = d.supplier_key
    and tc.product_key = d.product_key
	and tc.supplier_zone_id = d.supplier_zone_id
INNER JOIN @supplier_product_dim_checksum dc on
    dc.supplier_key = d.supplier_key
    and dc.product_key = d.product_key
	and dc.supplier_zone_id = d.supplier_zone_id
WHERE 
    tc.checksum <> dc.checksum

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    PROCEDURE [dbo].[Get_customer_counts_by_week_year]
	@salesWeek INT,
	@salesYear INT,
	@groupName CHAR(10), 
	@storeKey INT = NULL,
	@daysToInclude INT = 7,
	@sameStoresDateKey INT = NULL
AS


-- this allow for totaling some days of a week, for week-to-date (WTD) totals
IF @daysToInclude IS NULL BEGIN
	SELECT @daysToInclude = 7
END

DECLARE @maxDateKey INT
SELECT @maxDateKey = date_key FROM date_dim 
WHERE 
	sales_year = @salesYear 
	AND sales_week = @salesWeek
	AND day_in_sales_week = @daysToInclude


-- one store or all stores?
DECLARE @stores TABLE (store_key INT)
IF @storeKey IS NULL BEGIN
	IF @sameStoresDateKey = NULL OR @sameStoresDateKey = 0 BEGIN
	    INSERT @stores SELECT store_key FROM store_dim
	END ELSE BEGIN
	    INSERT @stores SELECT store_key FROM store_dim WHERE opening_date_key <= @sameStoresDateKey
	END
END ELSE BEGIN
    INSERT @stores SELECT @storeKey
END


SELECT
	da.date_key,
    RTRIM(LTRIM(da.day_of_week)) + ' ' + RTRIM(LTRIM(da.date_month_text)) as column_name,
	SUM(customer_count) AS customer_count
FROM
	daily_group_counts dgc
INNER JOIN @stores s ON
    s.store_key = dgc.store_key
RIGHT OUTER JOIN date_dim da ON
    da.date_key = dgc.tlog_date_key
WHERE
    da.sales_week = @salesWeek
    AND da.sales_year = @salesYear
    AND dgc.major_grouping = @groupName
    AND dgc.tlog_date_key <= @maxDateKey
GROUP BY 
	da.date_key,
	RTRIM(LTRIM(da.day_of_week)) + ' ' + RTRIM(LTRIM(da.date_month_text))
ORDER BY 
	da.date_key


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE                   PROCEDURE [dbo].[Get_department_sales_store_dept]
    @salesWeek INT,
    @salesYear INT,
    @storeKey INT = NULL,
    @departmentKey INT,
	@sameStoresDateKey INT = NULL
AS

SET NOCOUNT ON

DECLARE @stores TABLE (store_key INT)
IF @storeKey IS NULL BEGIN
	IF @sameStoresDateKey = NULL OR @sameStoresDateKey = 0 BEGIN
	    INSERT @stores SELECT store_key FROM store_dim
	END ELSE BEGIN
	    INSERT @stores SELECT store_key FROM store_dim WHERE opening_date_key <= @sameStoresDateKey
	END
END ELSE BEGIN
    INSERT @stores SELECT @storeKey
END


DECLARE @depts TABLE (department_key INT)
INSERT @depts SELECT @departmentKey

SELECT
    da.date_key,
    RTRIM(da.day_of_week) + ' ' + RTRIM(da.date_month_text) as date_text,
	RTRIM(da.day_of_week) AS day_of_week,
	da.day_in_sales_week,
    ISNULL(SUM(sales_dollar_amount),0) AS sales_dollar_amount,
    ISNULL(SUM(customer_count),0) AS customer_count,
    ISNULL(SUM(item_count),0) AS item_count,
    CONVERT(DECIMAL(18,2), 0) AS avg_item_price,
    CONVERT(DECIMAL(18,2), 0) AS avg_customer_sale,
	CONVERT(DECIMAL(18,2), 0) AS distro,
	CONVERT(DECIMAL(18,2), 0) AS group_sales_dollar_amount
INTO 
	#temp
FROM date_dim da
LEFT OUTER JOIN daily_department_sales s ON
    da.date_key = s.tlog_date_key
    AND s.department_key IN (select department_key FROM @depts)
    AND s.store_key IN (select store_key from @stores)
WHERE
    da.sales_week = @salesWeek
    AND da.sales_year = @salesYear
GROUP BY
    da.date_key,
    RTRIM(da.day_of_week) + ' ' + RTRIM(da.date_month_text),
	RTRIM(da.day_of_week),
	da.day_in_sales_week
ORDER BY 
    da.date_key


-- TODO: Review with Al
-- IF @departmentKey = -1 BEGIN
-- 	-- override counts with 'Food' counts when 'All Food Departments' are specified
-- 	UPDATE #temp SET
--     #temp.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc
--         WHERE 
--             dgc.store_key IN (select store_key FROM @stores)
--             AND dgc.tlog_date_key = #temp.date_key
--             AND dgc.major_grouping = 'Food'),0),
--     #temp.item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
--         WHERE 
--             dgc.store_key IN (select store_key FROM @stores)
--             AND dgc.tlog_date_key = #temp.date_key
--             AND dgc.major_grouping = 'Food'), 0)
-- END

-- compute averages
UPDATE #temp SET avg_item_price = sales_dollar_amount / item_count WHERE item_count <> 0
UPDATE #temp SET avg_customer_sale = sales_dollar_amount / customer_count WHERE customer_count <> 0

-- compute distro for group
DECLARE @majorGrouping VARCHAR(20)
SELECT 
	@majorGrouping = d.major_grouping 
FROM 
	department_dim d
WHERE 
	department_key = @departmentKey


SELECT 
	da.date_key,
	SUM(sales_dollar_amount) AS group_sales_dollar_amount
INTO #temp_group_sales
FROM date_dim da
LEFT OUTER JOIN daily_subdepartment_sales s ON
    da.date_key = s.tlog_date_key
    AND s.store_key in (SELECT store_key FROM @stores)
INNER JOIN subdepartment_dim sd ON
	sd.subdepartment_key = s.subdepartment_key
INNER JOIN department_dim d ON
	d.department_key = sd.department_key
WHERE
    da.sales_week = @salesWeek
    AND da.sales_year = @salesYear
	AND d.major_grouping = @majorGrouping
GROUP BY
    da.date_key

UPDATE t SET 
	distro = sales_dollar_amount / gs.group_sales_dollar_amount * 100,
	t.group_sales_dollar_amount = gs.group_sales_dollar_amount
FROM #temp t
INNER JOIN #temp_group_sales gs ON
	gs.date_key = t.date_key
WHERE
	gs.group_sales_dollar_amount <> 0

SET NOCOUNT OFF
SELECT * FROM #temp


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE        PROCEDURE [dbo].[Get_department_sales_store_dept_multi]
    @salesWeek INT,
    @salesYear INT,
    @storeKey INT = NULL,
    @departmentKey INT,
	@sameStoresDateKey INT = NULL
AS

-- find the absolute_week for the passed @salesWeek and @salesYear
DECLARE @year INT
DECLARE @week INT
DECLARE @absWeek INT
SELECT @absWeek = absolute_week FROM date_dim WHERE sales_week = @salesWeek AND sales_year = @salesyear

-- 104 weeks ago
SELECT @year = sales_year, @week = sales_week FROM date_dim WHERE absolute_week = @absWeek-52-52
EXEC Get_department_sales_store_dept @week, @year, @storeKey, @departmentKey, @sameStoresDateKey

-- 52 weeks ago
SELECT @year = sales_year, @week = sales_week FROM date_dim WHERE absolute_week = @absWeek-52
EXEC Get_department_sales_store_dept @week, @year, @storeKey, @departmentKey, @sameStoresDateKey

-- specified week
EXEC Get_department_sales_store_dept @salesWeek, @salesYear, @storeKey, @departmentKey, @sameStoresDateKey


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC [Get_department_sales_store_deptgroup] 40, 2012, NULL, 'Normal'
CREATE PROCEDURE [dbo].[Get_department_sales_store_deptgroup]
    @salesWeek INT,
    @salesYear INT,
    @storeKey INT = NULL,
    @majorGrouping VARCHAR(255),
	@sameStoresDateKey INT = NULL
AS

SET NOCOUNT ON

DECLARE @stores TABLE (store_key INT)
IF @storeKey IS NULL BEGIN
	IF @sameStoresDateKey = NULL OR @sameStoresDateKey = 0 BEGIN
	    INSERT @stores SELECT store_key FROM store_dim
	END ELSE BEGIN
	    INSERT @stores SELECT store_key FROM store_dim WHERE opening_date_key <= @sameStoresDateKey
	END
END ELSE BEGIN
    INSERT @stores SELECT @storeKey
END

SET NOCOUNT ON
SELECT
	da.date_key
	,RTRIM(da.day_of_week) + ' ' + RTRIM(da.date_month_text) as date_text
	,RTRIM(da.day_of_week) AS day_of_week
	,da.day_in_sales_week
    ,ISNULL(SUM(sales_dollar_amount),0) AS sales_dollar_amount
    ,ISNULL(SUM(c.customer_count),0) AS customer_count
    ,ISNULL(SUM(c.item_count),0) AS item_count
	,CONVERT(DECIMAL(18,2), 0) AS avg_item_price
	,CONVERT(DECIMAL(18,2), 0) AS avg_customer_sale
	,CONVERT(DECIMAL(18,2), 100) AS distro
	,ISNULL(SUM(sales_dollar_amount),0) AS group_sales_dollar_amount
INTO
	#temp
FROM
    daily_group_sales s
INNER JOIN date_dim da ON
    da.date_key = s.tlog_date_key
INNER JOIN daily_group_counts c ON
	c.store_key = s.store_key
	AND c.tlog_file_key = s.tlog_file_key
	AND c.major_grouping = @majorGrouping
INNER JOIN @stores stores ON
	stores.store_key = s.store_key
WHERE
    da.sales_year = @salesYear
    AND da.sales_week = @salesWeek
    AND s.major_grouping = @majorGrouping
GROUP BY
	da.date_key
	,RTRIM(da.day_of_week) + ' ' + RTRIM(da.date_month_text)
	,RTRIM(da.day_of_week) 
	,da.day_in_sales_week
ORDER BY 
    da.date_key

UPDATE #temp SET avg_item_price = sales_dollar_amount / item_count WHERE item_count <> 0
UPDATE #temp SET avg_customer_sale = sales_dollar_amount / customer_count WHERE customer_count <> 0

SET NOCOUNT OFF
SELECT * FROM #temp


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Get_department_sales_store_deptgroup_multi]
    @salesWeek INT,
    @salesYear INT,
    @majorGrouping VARCHAR(255),
    @storeKey INT = NULL,
	@sameStoresDateKey INT = NULL
AS

-- find the absolute_week for the passed @salesWeek and @salesYear
DECLARE @year INT
DECLARE @week INT
DECLARE @absWeek INT
SELECT @absWeek = absolute_week FROM date_dim WHERE sales_week = @salesWeek AND sales_year = @salesyear

-- 104 weeks ago
SELECT @year = sales_year, @week = sales_week FROM date_dim WHERE absolute_week = @absWeek-52-52
EXEC Get_department_sales_store_deptgroup @week, @year, @storeKey, @majorGrouping, @sameStoresDateKey

-- 52 weeks ago
SELECT @year = sales_year, @week = sales_week FROM date_dim WHERE absolute_week = @absWeek-52
EXEC Get_department_sales_store_deptgroup @week, @year, @storeKey, @majorGrouping, @sameStoresDateKey

-- specified week
EXEC Get_department_sales_store_deptgroup @salesWeek, @salesYear, @storeKey, @majorGrouping, @sameStoresDateKey


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE                PROCEDURE [dbo].[Get_department_sales_store_subdept]
    @salesWeek INT,
    @salesYear INT,
    @storeKey INT = NULL,
    @subdepartmentKey INT,
	@sameStoresDateKey INT = NULL
AS

SET NOCOUNT ON

DECLARE @stores TABLE (store_key INT)
IF @storeKey IS NULL BEGIN
	IF @sameStoresDateKey = NULL OR @sameStoresDateKey = 0 BEGIN
	    INSERT @stores SELECT store_key FROM store_dim
	END ELSE BEGIN
	    INSERT @stores SELECT store_key FROM store_dim WHERE opening_date_key <= @sameStoresDateKey
	END
END ELSE BEGIN
    INSERT @stores SELECT @storeKey
END

SELECT
    da.date_key,
    RTRIM(da.day_of_week) + ' ' + RTRIM(da.date_month_text) as date_text,
	RTRIM(da.day_of_week) AS day_of_week,
	da.day_in_sales_week,
    ISNULL(SUM(sales_dollar_amount),0) AS sales_dollar_amount,
    ISNULL(SUM(customer_count),0) AS customer_count,
    ISNULL(SUM(item_count),0) AS item_count,
    CONVERT(DECIMAL(18,2), 0) AS avg_item_price,
    CONVERT(DECIMAL(18,2), 0) AS avg_customer_sale,
	CONVERT(DECIMAL(18,2), 0) AS distro,
	CONVERT(DECIMAL(18,2), 0) AS group_sales_dollar_amount
INTO 
	#temp
FROM date_dim da
LEFT OUTER JOIN daily_subdepartment_sales s ON
    da.date_key = s.tlog_date_key
    AND s.subdepartment_key = @subdepartmentKey
    AND s.store_key in (SELECT store_key FROM @stores)
WHERE
    da.sales_week = @salesWeek
    AND da.sales_year = @salesYear
GROUP BY
    da.date_key,
    RTRIM(da.day_of_week) + ' ' + RTRIM(da.date_month_text),
	RTRIM(da.day_of_week),
	da.day_in_sales_week
ORDER BY 
    da.date_key

-- compute averages
UPDATE #temp SET avg_item_price = sales_dollar_amount / item_count WHERE item_count <> 0
UPDATE #temp SET avg_customer_sale = sales_dollar_amount / customer_count WHERE customer_count <> 0

-- compute distro for group
DECLARE @majorGrouping VARCHAR(20)
SELECT 
	@majorGrouping = d.major_grouping 
FROM 
	subdepartment_dim sd
INNER JOIN department_dim d ON
	d.department_key = sd.department_key
WHERE 
	subdepartment_key = @subdepartmentKey

-- DECLARE @departmentKey INT
-- SELECT 
-- 	@departmentKey = sd.department_key 
-- FROM 
-- 	subdepartment_dim sd
-- WHERE 
-- 	subdepartment_key = @subdepartmentKey

SELECT 
	da.date_key,
	SUM(sales_dollar_amount) AS group_sales_dollar_amount
INTO 
	#temp_group_sales
FROM date_dim da
LEFT OUTER JOIN daily_subdepartment_sales s ON
    da.date_key = s.tlog_date_key
    AND s.store_key in (SELECT store_key FROM @stores)
INNER JOIN subdepartment_dim sd ON
	sd.subdepartment_key = s.subdepartment_key
INNER JOIN department_dim d ON
	d.department_key = sd.department_key
WHERE
    da.sales_week = @salesWeek
    AND da.sales_year = @salesYear
--	AND d.department_key = @departmentKey
	AND d.major_grouping = @majorGrouping
GROUP BY
    da.date_key

UPDATE t SET 
	distro = sales_dollar_amount / gs.group_sales_dollar_amount * 100,
	t.group_sales_dollar_amount = gs.group_sales_dollar_amount
FROM #temp t
INNER JOIN #temp_group_sales gs ON
	gs.date_key = t.date_key
WHERE 
    gs.group_sales_dollar_amount <> 0

SET NOCOUNT OFF

SELECT * FROM #temp


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE        PROCEDURE [dbo].[Get_department_sales_store_subdept_multi]
    @salesWeek INT,
    @salesYear INT,
    @storeKey INT = NULL,
    @subdepartmentKey INT,
	@sameStoresDateKey INT = NULL
AS

-- find the absolute_week for the passed @salesWeek and @salesYear
DECLARE @year INT
DECLARE @week INT
DECLARE @absWeek INT
SELECT @absWeek = absolute_week FROM date_dim WHERE sales_week = @salesWeek AND sales_year = @salesyear

-- 104 weeks ago
SELECT @year = sales_year, @week = sales_week FROM date_dim WHERE absolute_week = @absWeek-52-52
EXEC Get_department_sales_store_subdept @week, @year, @storeKey, @subdepartmentKey, @sameStoresDateKey

-- 52 weeks ago
SELECT @year = sales_year, @week = sales_week FROM date_dim WHERE absolute_week = @absWeek-52
EXEC Get_department_sales_store_subdept @week, @year, @storeKey, @subdepartmentKey, @sameStoresDateKey

-- specified week
EXEC Get_department_sales_store_subdept @salesWeek, @salesYear, @storeKey, @subdepartmentKey, @sameStoresDateKey


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE        procedure [dbo].[Get_department_sales_store_year]
    @storeKey INT,
    @salesYear INT,
    @salesWeek INT,
    @group VARCHAR(10),
	@sameStoresDateKey INT = NULL
AS


SET NOCOUNT ON

DECLARE @stores TABLE (store_key INT)
IF @storeKey IS NULL BEGIN
	IF @sameStoresDateKey = NULL OR @sameStoresDateKey = 0 BEGIN
	    INSERT @stores SELECT store_key FROM store_dim
	END ELSE BEGIN
	    INSERT @stores SELECT store_key FROM store_dim WHERE opening_date_key <= @sameStoresDateKey
	END
END ELSE BEGIN
    INSERT @stores SELECT @storeKey
END

SET NOCOUNT OFF

SELECT
    RTRIM(LTRIM(da.day_of_week)) + ' ' + RTRIM(LTRIM(da.date_month_text)) as column_name,
    s.department_key,
    sales_dollar_amount,
    item_count,
    customer_count
FROM
    daily_department_sales s
INNER JOIN @stores stores ON
    stores.store_key = s.store_key
INNER JOIN date_dim da ON
    da.date_key = s.tlog_date_key
INNER JOIN department_dim d ON
    d.department_key = s.department_key
    AND d.major_grouping = @group
    AND d.is_active = 1
WHERE
    da.sales_year = @salesYear
    AND da.sales_week = @salesWeek
    AND s.department_key <> 0
ORDER BY 
    da.date_key,
    s.department_key,
    s.store_key


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE       PROCEDURE [dbo].[Get_item_movement]
	@upc CHAR(13),
	@today DATETIME,
	@storeKey INT
AS


DECLARE @qtyToday DECIMAL(9,2)
DECLARE @qtyToday2 DECIMAL(9,2)
DECLARE @qtyYesterday DECIMAL(9,2)
DECLARE @qtyYesterday2 DECIMAL(9,2)
DECLARE @qtyWeekToDate DECIMAL(9,2)
DECLARE @qtyWeekToDate2 DECIMAL(9,2)
DECLARE @qtyPeriodToDate DECIMAL(9,2)
DECLARE @qtyPeriodToDate2 DECIMAL(9,2)
DECLARE @qtyYearToDate DECIMAL(9,2)
DECLARE @qtyYearToDate2 DECIMAL(9,2)

DECLARE @minDate INT
DECLARE @maxDate INT
DECLARE @weekStartDate DATETIME
DECLARE @weekEndDate DATETIME
DECLARE @salesWeek INT
DECLARE @salesYear INT
DECLARE @todayDateKey INT
DECLARE @absWeek INT

SELECT @todayDateKey = dbo.fn_DateToDateKey(@today)
SELECT @salesWeek = sales_week, @salesYear = sales_year, @absWeek = absolute_week FROM date_dim WHERE date_key = dbo.fn_DateToDateKey(@today)
SELECT @weekStartDate = calendar_date FROM date_dim WHERE sales_week = @salesWeek AND sales_year = @salesYear AND day_in_sales_week = 1
SELECT @weekEndDate = calendar_date FROM date_dim WHERE sales_week = @salesWeek AND sales_year = @salesYear AND day_in_sales_week = 7

DECLARE @productKey INT
SELECT @productKey = product_key FROM product_dim WHERE upc=@upc

-- today
-- 'today' value comes from instore realtime sales
-- TODO: EXEC Get_item_movement_by_date_range @productKey, @storeKey, @minDate, @maxDate, @qtyToday OUTPUT 

-- year ago today
SELECT @minDate = date_key from date_dim where calendar_date = DATEADD(WW, -52, @today)
SET @maxDate =@minDate
EXEC Get_item_movement_by_date_range @productKey, @storeKey, @minDate, @maxDate, @qtyToday2 OUTPUT 

-- yesterday
SET @minDate = dbo.fn_DateToDateKey(DATEADD(dd, -1, @today))
SET @maxDate = @minDate
EXEC Get_item_movement_by_date_range @productKey, @storeKey, @minDate, @maxDate, @qtyYesterday OUTPUT 

-- yesterday year ago
SELECT @minDate = date_key from date_dim where calendar_date = dateadd(WW, -52, DATEADD(dd, -1, @today))
SET @maxDate =@minDate
EXEC Get_item_movement_by_date_range @productKey, @storeKey, @minDate, @maxDate, @qtyYesterday2 OUTPUT 

-- week to date
SELECT @minDate = MIN(date_key) FROM date_dim WHERE absolute_week = @absWeek
SELECT @maxDate = @todayDateKey
EXEC Get_item_movement_by_date_range @productKey, @storeKey, @minDate, @maxDate, @qtyWeekToDate OUTPUT  

-- week to date year ago
SELECT @minDate = MIN(date_key) FROM date_dim WHERE absolute_week = @absWeek - 52
SELECT @maxDate = date_key from date_dim where calendar_date = DATEADD(WW, -52, @today)
EXEC Get_item_movement_by_date_range @productKey, @storeKey, @minDate, @maxDate, @qtyWeekToDate2 OUTPUT  

-- 13 weeks
SELECT @minDate = dbo.fn_DateToDateKey(DATEADD(ww, -12, @weekStartDate))
SELECT @maxDate = @todaydateKey
EXEC Get_item_movement_by_date_range @productKey, @storeKey, @minDate, @maxDate, @qtyPeriodToDate OUTPUT  

-- 13 weeks year ago
SELECT @minDate = dbo.fn_DateToDateKey(DATEADD(ww, -64, @weekStartDate))
SELECT @maxDate = dbo.fn_DateToDateKey(DATEADD(ww, -52, @today))
EXEC Get_item_movement_by_date_range @productKey, @storeKey, @minDate, @maxDate, @qtyPeriodToDate2 OUTPUT  

-- year to date, this year
SELECT @minDate = date_key FROM date_dim WHERE sales_year = @salesYear AND day_in_sales_year = 1
SELECT @maxDate = dbo.fn_DateToDateKey(@today)
EXEC Get_item_movement_by_date_range @productKey, @storeKey, @minDate, @maxDate, @qtyYearToDate OUTPUT -- 

-- year to date, last year
SELECT @minDate = date_key FROM date_dim WHERE sales_year = @salesYear-1 AND day_in_sales_year = 1
SELECT @maxDate = dbo.fn_DateToDateKey(DATEADD(ww, -52, @today))
EXEC Get_item_movement_by_date_range @productKey, @storeKey, @minDate, @maxDate, @qtyYearToDate2 OUTPUT --  

DECLARE @firstSaleDateKey INT
DECLARE @lastSaleDateKey INT
SELECT 
	@firstSaleDateKey = MIN(trans_date_key) 
	,@lastSaleDateKey = MAX(trans_date_key)
FROM 
	daily_sales_fact WITH (NOLOCK)
WHERE
	product_key = @productKey
	AND store_key = @storeKey

DECLARE @firstSaleDate DATETIME
SELECT
	@firstSaleDate = calendar_date
FROM
	date_dim
WHERE
	date_key = @firstSaleDateKey

DECLARE @lastSaleDate DATETIME
SELECT
	@lastSaleDate = calendar_date
FROM
	date_dim
WHERE
	date_key = @lastSaleDateKey

-- final select
SELECT
	ISNULL(@qtyToday, 0) as today,
	ISNULL(@qtyToday2, 0) as today2,
	ISNULL(@qtyYesterday, 0) as yesterday,
	ISNULL(@qtyYesterday2, 0) as yesterday2,
	ISNULL(@qtyWeekToDate, 0) as weektodate,
	ISNULL(@qtyWeekToDate2, 0) as weektodate2,
	ISNULL(@qtyPeriodToDate, 0) as periodtodate,
	ISNULL(@qtyPeriodToDate2, 0) as periodtodate2,
	ISNULL(@qtyYearToDate, 0) as yeartodate,
	ISNULL(@qtyYearToDate2, 0) as yeartodate2,
	@firstSaleDate as firstsaledate,
	@lastSaleDate AS lastsaledate


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    PROCEDURE [dbo].[Get_item_movement_by_date_range]
	@productKey INT,
	@storeKey INT,
	@minDate INT,
	@maxDate INT,
	@qty DECIMAL(9,2) OUTPUT
AS

DECLARE @innerMinDate INT
DECLARE @innerMaxDate INT

SET @innerMinDate = @minDate
SET @innerMaxDate = @maxDate
SELECT 
	@qty = SUM(sales_quantity) 
from 
	daily_sales_fact WITH (NOLOCK)
where 
	product_key = @productKey 
	and trans_date_key BETWEEN @innerMinDate AND @innerMaxDate 
	AND store_key = @storeKey


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE          PROCEDURE [dbo].[Get_sales_department_year]
    @departmentKey INT,
    @salesYear INT,
    @salesWeek INT
AS


SET NOCOUNT ON
DECLARE @depts TABLE (department_key INT)
-- IF @departmentKey IS NULL BEGIN
--     INSERT @depts SELECT department_key FROM department_dim
IF @departmentKey = -1 BEGIN
    INSERT @depts SELECT department_key FROM department_dim WHERE major_grouping = 'Food' AND is_active = 1
END ELSE BEGIN
    INSERT @depts SELECT @departmentKey
END

-- figure out what group we're working with (food, rx, misc)
DECLARE @majorGrouping VARCHAR(255)
IF @departmentKey <> -1 BEGIN
	SELECT 
	    @majorGrouping = major_grouping 
	FROM 
	    department_dim d 
	WHERE 
	    d.department_key = @departmentKey
END ELSE BEGIN
	SELECT @majorGrouping = 'Food'
END

SET NOCOUNT OFF

SELECT
    RTRIM(LTRIM(da.day_of_week)) + ' ' + RTRIM(LTRIM(da.date_month_text)) as column_name,
    s.store_key,
	s.department_key,
    sales_dollar_amount,
    item_count,
    customer_count,
    CONVERT(NUMERIC(18,4), CASE 
        WHEN item_count = 0 THEN 0
        ELSE sales_dollar_amount / item_count
    END) AS avg_item_price,
    CONVERT(NUMERIC(18,4), CASE
        WHEN customer_count=0 THEN 0
        ELSE sales_dollar_amount / customer_count
    END) AS avg_customer_sale
FROM
    daily_department_sales s
INNER JOIN @depts depts ON
    depts.department_key = s.department_key
INNER JOIN date_dim da ON
    da.date_key = s.tlog_date_key
INNER JOIN department_dim d ON
    d.department_key = depts.department_key
    AND d.is_active = 1
WHERE
    da.sales_year = @salesYear
    AND da.sales_week = @salesWeek
ORDER BY 
    da.date_key,
    s.store_key

    
-- also return total store sales in same format - used
-- to compute distribution 
SET NOCOUNT ON
SELECT
    RTRIM(LTRIM(da.day_of_week)) + ' ' + RTRIM(LTRIM(da.date_month_text)) as column_name,
    da.date_key,
    s.store_key,
    sum(sales_dollar_amount) as sales_dollar_amount,
    0 as item_count,
    0 as customer_count,
    CONVERT(NUMERIC(18,4),0) as avg_item_price,
    CONVERT(NUMERIC(18,4),0) as avg_customer_sale
INTO #temp
FROM
    daily_subdepartment_sales s
INNER JOIN date_dim da ON
    da.date_key = s.tlog_date_key
INNER JOIN subdepartment_dim sd ON
    sd.subdepartment_key = s.subdepartment_key
INNER JOIN department_dim d ON
    d.department_key = sd.department_key
    AND d.is_active = 1
    AND d.major_grouping = @majorGrouping
WHERE
    da.sales_year = @salesYear
    AND da.sales_week = @salesWeek
GROUP BY 
    RTRIM(LTRIM(da.day_of_week)) + ' ' + RTRIM(LTRIM(da.date_month_text)),
    da.date_key,
    s.store_key

-- pull customer counts into #temp
-- pull item counts into #temp
UPDATE #temp SET
    #temp.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc
        WHERE 
            dgc.store_key = #temp.store_key 
            AND dgc.tlog_date_key = #temp.date_key
            AND dgc.major_grouping = @majorGrouping),0),
    #temp.item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
        WHERE 
            dgc.store_key = #temp.store_key 
            AND dgc.tlog_date_key = #temp.date_key
            AND dgc.major_grouping = @majorGrouping), 0)

-- compute $/item and $/cust
UPDATE #temp SET avg_item_price = sales_dollar_amount / item_count WHERE item_count <> 0
UPDATE #temp SET avg_customer_sale = sales_dollar_amount / customer_count WHERE customer_count <> 0


-- now return the data.
SET NOCOUNT OFF
SELECT * FROM #temp


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE        PROCEDURE [dbo].[Get_sales_subdepartment_year]
    @subdepartmentKey INT,
    @salesYear INT,
    @salesWeek INT,
	@storeKey INT = NULL
AS


SET NOCOUNT ON

DECLARE @stores TABLE (store_key INT)
IF @storeKey IS NOT NULL BEGIN
	INSERT INTO @stores SELECT @storeKey
END ELSE BEGIN
	INSERT INTO @stores SELECT store_key FROM store_dim
END

DECLARE @subdepts TABLE (subdepartment_key INT)
IF @subdepartmentKey IS NULL BEGIN
    INSERT @subdepts SELECT subdepartment_key FROM subdepartment_dim
END ELSE BEGIN
    INSERT @subdepts SELECT @subdepartmentKey
END

-- figure out what group we're working with (food, rx, misc)
DECLARE @majorGrouping VARCHAR(255)
select @majorGrouping = major_grouping from department_dim d inner join subdepartment_dim sd on sd.department_key = d.department_key where sd.subdepartment_key = @subdepartmentKey

SET NOCOUNT OFF

SELECT
    RTRIM(LTRIM(da.day_of_week)) + ' ' + RTRIM(LTRIM(da.date_month_text)) as column_name,
    s.store_key,
    sales_dollar_amount,
    item_count,
    customer_count,
    CASE 
        WHEN item_count = 0 THEN 0
        ELSE sales_dollar_amount / item_count
    END AS avg_item_price,
    CASE
        WHEN customer_count=0 THEN 0
        ELSE sales_dollar_amount / customer_count
    END AS avg_customer_sale
FROM
    daily_subdepartment_sales s
INNER JOIN @subdepts subdepts ON
    subdepts.subdepartment_key = s.subdepartment_key
INNER JOIN date_dim da ON
    da.date_key = s.tlog_date_key
INNER JOIN subdepartment_dim sd ON
    sd.subdepartment_key = subdepts.subdepartment_key
INNER JOIN department_dim d ON
    d.department_key = sd.department_key
    AND d.is_active = 1
INNER JOIN @stores stores ON
	stores.store_key = s.store_key
WHERE
    da.sales_year = @salesYear
    AND da.sales_week = @salesWeek
ORDER BY 
    da.date_key,
    s.store_key

SET NOCOUNT ON
    
-- also return total store sales in same format - used
-- to compute distribution 
SELECT
    RTRIM(LTRIM(da.day_of_week)) + ' ' + RTRIM(LTRIM(da.date_month_text)) as column_name,
    da.date_key,
    s.store_key,
    sum(sales_dollar_amount) as sales_dollar_amount,
    0 as item_count,
    0 as customer_count,
    CONVERT(NUMERIC(18,2),0) as avg_item_price,
    CONVERT(NUMERIC(18,2),0) as avg_customer_sale
INTO #temp
FROM
    daily_subdepartment_sales s
INNER JOIN date_dim da ON
    da.date_key = s.tlog_date_key
INNER JOIN subdepartment_dim sd ON
    sd.subdepartment_key = s.subdepartment_key
INNER JOIN department_dim d ON
    d.department_key = sd.department_key
    AND d.is_active = 1
    AND d.major_grouping = @majorGrouping
INNER JOIN @stores stores ON
	stores.store_key = s.store_key
WHERE
    da.sales_year = @salesYear
    AND da.sales_week = @salesWeek
GROUP BY 
    RTRIM(LTRIM(da.day_of_week)) + ' ' + RTRIM(LTRIM(da.date_month_text)),
    da.date_key,
    s.store_key

-- pull customer counts into #temp
-- pull item counts into #temp
UPDATE #temp SET
    #temp.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc
        WHERE 
            dgc.store_key = #temp.store_key 
            AND dgc.tlog_date_key = #temp.date_key
            AND dgc.major_grouping = @majorGrouping),0),
    #temp.item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
        WHERE 
            dgc.store_key = #temp.store_key 
            AND dgc.tlog_date_key = #temp.date_key
            AND dgc.major_grouping = @majorGrouping), 0)

UPDATE #temp SET avg_item_price = sales_dollar_amount / item_count WHERE item_count <> 0
UPDATE #temp SET avg_customer_sale = sales_dollar_amount / customer_count WHERE customer_count <> 0

SET NOCOUNT OFF

-- now return the data.
SELECT * FROM #temp


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Get_store_airport_codes] AS

SELECT DISTINCT
	weather_airport_code
FROM
	store_dim
WHERE
	weather_airport_code is not null
ORDER BY
	weather_airport_code


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE        procedure [dbo].[Get_subdepartment_sales_store_year]
    @storeKey INT,
    @salesYear INT,
    @salesWeek INT,
    @departmentKey INT,
	@sameStoresDateKey INT = NULL
AS


SET NOCOUNT ON

DECLARE @stores TABLE (store_key INT)
IF @storeKey IS NULL BEGIN
	IF @sameStoresDateKey = NULL OR @sameStoresDateKey = 0 BEGIN
	    INSERT @stores SELECT store_key FROM store_dim
	END ELSE BEGIN
	    INSERT @stores SELECT store_key FROM store_dim WHERE opening_date_key <= @sameStoresDateKey
	END
END ELSE BEGIN
    INSERT @stores SELECT @storeKey
END

SET NOCOUNT OFF

SELECT
    RTRIM(LTRIM(da.day_of_week)) + ' ' + RTRIM(LTRIM(da.date_month_text)) as column_name,
    s.subdepartment_key,
    sales_dollar_amount,
    item_count,
    customer_count
FROM
    daily_subdepartment_sales s
INNER JOIN @stores stores ON
    stores.store_key = s.store_key
INNER JOIN date_dim da ON
    da.date_key = s.tlog_date_key
INNER JOIN subdepartment_dim sd ON
    sd.subdepartment_key = s.subdepartment_key
INNER JOIN department_dim d ON
    d.department_key = sd.department_key
WHERE
    da.sales_year = @salesYear
    AND da.sales_week = @salesWeek
    AND d.department_key = @departmentKey
ORDER BY 
    da.date_key,
    s.subdepartment_key,
    s.store_key


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE                PROCEDURE [dbo].[Get_weekly_sales_by_week_store_group]
	@salesWeek INT,
	@salesYear INT,
	@groupName CHAR(10), 
	@storeKey INT = NULL,
	@daysToInclude INT = 7,
	@sameStoresDateKey INT = NULL
AS

SET NOCOUNT ON

-- this allow for totaling some days of a week, for week-to-date (WTD) totals
IF @daysToInclude IS NULL BEGIN
	SELECT @daysToInclude = 7
END

DECLARE @maxDateKey INT
SELECT @maxDateKey = date_key FROM date_dim 
WHERE 
	sales_year = @salesYear 
	AND sales_week = @salesWeek
	AND day_in_sales_week = @daysToInclude

--SELECT @maxDateKey

-- one store or all stores?
DECLARE @stores TABLE (store_key INT)
IF @storeKey IS NULL BEGIN
	IF @sameStoresDateKey = NULL OR @sameStoresDateKey = 0 BEGIN
	    INSERT @stores SELECT store_key FROM store_dim
	END ELSE BEGIN
	    INSERT @stores SELECT store_key FROM store_dim WHERE opening_date_key <= @sameStoresDateKey
	END
END ELSE BEGIN
    INSERT @stores SELECT @storeKey
END

SELECT
    ISNULL(SUM(sales_dollar_amount),0) AS sales_dollar_amount,
    0 AS customer_count,
    0 AS item_count,
    CONVERT(DECIMAL(18,4),0) AS avg_item_price,
    CONVERT(DECIMAL(18,4),0) AS avg_customer_sale
INTO #temp    
FROM daily_department_sales dds
INNER JOIN @stores s ON
    s.store_key = dds.store_key
INNER JOIN department_dim d ON
    d.department_key = dds.department_key
    AND 
		((d.major_grouping = @groupName) OR (@groupName IS NULL))
RIGHT OUTER JOIN date_dim da ON
    da.date_key = dds.tlog_date_key
WHERE
    da.sales_week = @salesWeek
    AND da.sales_year = @salesYear
    AND dds.department_key <> 0
    AND dds.tlog_date_key <= @maxDateKey

-- pull in customer & item counts
IF @groupName IS NOT NULL BEGIN
	-- get counts at the group level, like 'Food', 'Rx' or 'Misc'
	UPDATE #temp SET
	    #temp.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc INNER JOIN @stores s on dgc.store_key = s.store_key INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key WHERE da.sales_year = @salesYear AND da.sales_week = @salesWeek AND dgc.major_grouping = @groupName AND dgc.tlog_date_key <= @maxDateKey),0),
	    #temp.item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc INNER JOIN @stores s on dgc.store_key = s.store_key INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key WHERE da.sales_year = @salesYear AND da.sales_week = @salesWeek AND dgc.major_grouping = @groupName AND dgc.tlog_date_key <= @maxDateKey), 0)
END ELSE BEGIN
	-- get counts at the total store level, like 'Food', 'Rx' or 'Misc'
	UPDATE #temp SET
	    #temp.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_total_store_counts dtsc INNER JOIN @stores s on dtsc.store_key = s.store_key INNER JOIN date_dim da ON da.date_key = dtsc.tlog_date_key WHERE da.sales_year = @salesYear AND da.sales_week = @salesWeek AND dtsc.tlog_date_key <= @maxDateKey),0),
	    #temp.item_count = ISNULL((SELECT SUM(item_count) FROM daily_total_store_counts dtsc INNER JOIN @stores s on dtsc.store_key = s.store_key INNER JOIN date_dim da ON da.date_key = dtsc.tlog_date_key WHERE da.sales_year = @salesYear AND da.sales_week = @salesWeek AND dtsc.tlog_date_key <= @maxDateKey), 0)
END

-- calculate avg_item_price and avg_customer_sale
UPDATE #temp SET avg_item_price = sales_dollar_amount / item_count WHERE item_count <> 0
UPDATE #temp SET avg_customer_sale = sales_dollar_amount / customer_count WHERE customer_count <> 0

SET NOCOUNT OFF

-- now return the data
SELECT * FROM #temp


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE         PROCEDURE [dbo].[Get_weekly_sales_by_week_store_group_multi]
    @salesWeek INT,
    @salesYear INT,
    @groupName CHAR(10),
    @storeKey INT = NULL,
    @daysToInclude INT = 7,
	@sameStoresDateKey INT = NULL
AS

-- find the absolute_week for the passed @salesWeek and @salesYear
DECLARE @year INT
DECLARE @week INT
DECLARE @absWeek INT
SELECT @absWeek = absolute_week FROM date_dim WHERE sales_week = @salesWeek AND sales_year = @salesyear


-- 104 weeks ago
SELECT @year = sales_year, @week = sales_week FROM date_dim WHERE absolute_week = @absWeek-52-52
EXEC Get_weekly_sales_by_week_store_group @week, @year, @groupName, @storeKey, @daysToInclude, @sameStoresDateKey

-- 52 weeks ago
SELECT @year = sales_year, @week = sales_week FROM date_dim WHERE absolute_week = @absWeek-52
EXEC Get_weekly_sales_by_week_store_group @week, @year, @groupName, @storeKey, @daysToInclude, @sameStoresDateKey

-- specified week
EXEC Get_weekly_sales_by_week_store_group @salesWeek, @salesYear, @groupName, @storeKey, @daysToInclude, @sameStoresDateKey


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[GetDepartmentSalesByDateRangeRollup]
	@startDate INT,
	@endDate INT,
	@departmentKey SMALLINT,
	@storeNumber INT = NULL,
	@sameStoresDateKey INT = NULL
AS

-- figure what stores to report on
-- figure what stores to report on
DECLARE @stores TABLE (store_key INT)
IF @storeNumber IS NULL BEGIN
	IF @sameStoresDateKey = NULL OR @sameStoresDateKey = 0 BEGIN
	    INSERT @stores SELECT store_key FROM store_dim
	END ELSE BEGIN
	    INSERT @stores SELECT store_key FROM store_dim WHERE opening_date_key <= @sameStoresDateKey
	END
END ELSE BEGIN
    INSERT @stores SELECT @storeNumber
END


-- get qtd values for department
SET NOCOUNT ON 
SELECT
    ISNULL(SUM(sales_dollar_amount),0.00) AS sales_dollar_amount,
    0 AS customer_count,
    0 AS item_count,
	@startDate AS startDate,
	@endDate AS endDate
INTO #temp
FROM daily_subdepartment_sales dss
INNER JOIN @stores s ON
	s.store_key = dss.store_key
INNER JOIN date_dim da ON
	da.date_key = dss.tlog_date_key
INNER JOIN subdepartment_dim sd ON
	sd.subdepartment_key = dss.subdepartment_key
INNER JOIN department_dim dd ON
	dd.department_key = sd.department_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND dd.department_key = @departmentKey

UPDATE #temp SET
    #temp.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_department_sales dds
		INNER JOIN date_dim da ON da.date_key = dds.tlog_date_key
		INNER JOIN @stores s ON s.store_key = dds.store_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dds.department_key = @departmentKey), 0),
    #temp.item_count = ISNULL((SELECT SUM(item_count) FROM daily_department_sales dds 
		INNER JOIN date_dim da ON da.date_key = dds.tlog_date_key
		INNER JOIN @stores s ON s.store_key = dds.store_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dds.department_key = @departmentKey), 0)


-- find group for department
DECLARE @majorGrouping VARCHAR(255)
SELECT 
	@majorGrouping = d.major_grouping 
FROM 
	department_dim d 
WHERE 
	d.department_key = @departmentKey

-- get sales for group
SELECT
    ISNULL(SUM(sales_dollar_amount),0.00) AS sales_dollar_amount,
    0 AS customer_count,
    0 AS item_count
INTO #group_totals
FROM daily_group_sales dgs 
INNER JOIN @stores s ON
	s.store_key = dgs.store_key
INNER JOIN date_dim da ON
	da.date_key = dgs.tlog_date_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND dgs.major_grouping = @majorGrouping

-- get counts for group
UPDATE #group_totals SET
    #group_totals.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		INNER JOIN @stores s ON s.store_key = dgc.store_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping),0),
    #group_totals.item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		INNER JOIN @stores s ON s.store_key = dgc.store_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping), 0)

SET NOCOUNT OFF
SELECT 
	t.sales_dollar_amount,
	CASE 
		WHEN gt.sales_dollar_amount = 0 THEN 0
		ELSE t.sales_dollar_amount / gt.sales_dollar_amount * 100 
	END AS sales_dist,
	t.customer_count,
	CASE 
		WHEN gt.customer_count = 0 THEN 0
		ELSE CONVERT(NUMERIC(18,2), t.customer_count) / CONVERT(NUMERIC(18,2), gt.customer_count) * 100 
	END AS customer_dist,
	t.item_count,
	CASE
		WHEN gt.item_count = 0 THEN 0
		ELSE CONVERT(NUMERIC(18,2), t.item_count) / CONVERT(NUMERIC(18,2), gt.item_count) * 100 
	END AS item_dist,
	@startDate AS start_date_key,
	@endDate AS end_date_key
FROM
	#temp t 
CROSS JOIN #group_totals gt


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    PROCEDURE [dbo].[GetGroupSalesByDateRange]
	@startDate INT,
	@endDate INT,
	@groupName CHAR(10), 
	@storeNumber INT = NULL,
	@sameStoresDateKey INT = NULL
AS


DECLARE @stores TABLE (store_key INT)
IF @storeNumber IS NULL BEGIN
	IF @sameStoresDateKey IS NULL OR @sameStoresDateKey = 0 BEGIN
	    INSERT @stores SELECT store_key FROM store_dim
	END ELSE BEGIN
		INSERT @stores SELECT store_key FROM store_dim WHERE opening_date_key <= @sameStoresDateKey
	END
END ELSE BEGIN
    INSERT @stores SELECT @storeNumber
END


SET NOCOUNT ON 
SELECT
    ISNULL(SUM(sales_dollar_amount),0) AS sales_dollar_amount,
     0 AS customer_count,
     0 AS item_count,
     0 AS store_customer_count,
     0 AS store_item_count,
	 @startDate AS start_date_key,
	 @endDate AS end_date_key
INTO 
	#temp
FROM 
	daily_group_sales dgs 
INNER JOIN @stores s ON
	s.store_key = dgs.store_key
INNER JOIN date_dim da ON
	da.date_key = dgs.tlog_date_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND dgs.major_grouping = @groupName

UPDATE #temp SET
    #temp.store_customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_total_store_counts dtsc 
		INNER JOIN @stores s on dtsc.store_key = s.store_key 
		INNER JOIN date_dim da ON da.date_key = dtsc.tlog_date_key
		WHERE da.date_key BETWEEN @startDate AND @endDate ),0),
    #temp.store_item_count = ISNULL((SELECT SUM(item_count) FROM daily_total_store_counts dtsc 
		INNER JOIN @stores s on dtsc.store_key = s.store_key 
		INNER JOIN date_dim da ON da.date_key = dtsc.tlog_date_key
		WHERE da.date_key BETWEEN @startDate AND @endDate), 0)

UPDATE #temp SET
    #temp.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc 
		INNER JOIN @stores s on dgc.store_key = s.store_key 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @groupName),0),
    #temp.item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
		INNER JOIN @stores s on dgc.store_key = s.store_key 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE 
			da.date_key BETWEEN @startDate AND @endDate  
			AND dgc.major_grouping = @groupName), 0)

-- UPDATE #temp SET
--     #temp.food_customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc 
-- 		INNER JOIN @stores s on dgc.store_key = s.store_key 
-- 		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
-- 		WHERE da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = 'Food'),0),
--     #temp.food_item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
-- 		INNER JOIN @stores s on dgc.store_key = s.store_key 
-- 		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
-- 		WHERE 
-- 			da.date_key BETWEEN @startDate AND @endDate  
-- 			AND dgc.major_grouping = 'Food'), 0)
-- 
-- UPDATE #temp SET
--     #temp.rx_customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc 
-- 		INNER JOIN @stores s on dgc.store_key = s.store_key 
-- 		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
-- 		WHERE da.date_key BETWEEN @startDate AND @endDate  AND dgc.major_grouping = 'Rx'),0),
--     #temp.rx_item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
-- 		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
-- 		INNER JOIN @stores s on dgc.store_key = s.store_key 
-- 		WHERE da.date_key BETWEEN @startDate AND @endDate  AND dgc.major_grouping = 'Rx'), 0)
-- 
-- UPDATE #temp SET
--     #temp.misc_customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc 
-- 		INNER JOIN @stores s on dgc.store_key = s.store_key 
-- 		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
-- 		WHERE da.date_key BETWEEN @startDate AND @endDate  AND dgc.major_grouping = 'Misc'),0),
--     #temp.misc_item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
-- 		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
-- 		INNER JOIN @stores s on dgc.store_key = s.store_key 
-- 		WHERE da.date_key BETWEEN @startDate AND @endDate  AND dgc.major_grouping = 'Misc'), 0)

SET NOCOUNT OFF
SELECT * FROM #temp


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetItemSalesByUpcDateRange]
	@upc CHAR(13),
	@storeKey INT,
	@startDateKey INT,
	@endDateKey INT
AS

SELECT 
	ISNULL(SUM(sales_quantity), 0.00) AS sales_quantity
	,ISNULL(SUM(sales_dollar_amount), 0.00) AS sales_dollar_amount
FROM 
	daily_sales_fact s WITH (NOLOCK)
INNER JOIN product_dim p WITH (NOLOCK) ON
	p.product_key = s.product_key
	AND p.upc = @upc
WHERE 
	trans_date_key BETWEEN @startDateKey AND @endDateKey
	AND store_key = @storeKey


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetLastNWeeksMovementByUpcSupplierId] 
        @upc char(13),
        @supplierId VARCHAR(20),
        @howMany int = 10
    AS


    SET NOCOUNT ON


    -- make weeks begin on Monday
    SET DATEFIRST 1
    DECLARE @dayOfWeek INT
    DECLARE @weekStart DATETIME
    DECLARE @theDate DATETIME
    SELECT @theDate = CONVERT(datetime,CONVERT(varchar, GETDATE(), 101))
    SELECT @dayOfWeek = DATEPART(dw, @theDate)
    SELECT @weekStart = DATEADD(dd, -1 * (@dayOfWeek-1), @theDate)

    -- temp table of the weeks we want
    --declare @weeks TABLE (weekStartDate DATETIME, weekStopDate DATETIME, quantity DECIMAL(9,4))
    create table #weeks (weekStartDate DATETIME, weekStopDate DATETIME, quantity DECIMAL(9,4))
    declare @count INT
    select @count = 0
    DECLARE @start DATETIME
    DECLARE @stop DATETIME
    SELECT @start = @weekStart
    WHILE @count < @howMany BEGIN
        select @start = DATEADD(ww, -1 * @count, @weekStart)
        select @stop = DATEADD(dd, 6, @start)
        INSERT INTO #weeks (weekStartDate, weekStopDate, quantity) VALUES (@start, @stop, 0)
        SELECT @count = @count + 1
    END


    --drop table #weeks
    --SELECT * into #weeks from @weeks

	DECLARE @startDateKey INT
	SET @startDateKey = dbo.fn_DateToDateKey(@start)
	DECLARE @stopDateKey INT
	SET @stopDateKey = dbo.fn_DateToDateKey(@stop)

    UPDATE #weeks SET quantity =
        (SELECT 
            ISNULL(SUM(sales_quantity),0)
        FROM 
            daily_sales_fact s WITH (NOLOCK) 
		INNER JOIN product_dim p WITH (NOLOCK) ON
			p.product_key = s.product_key
        INNER JOIN date_dim dd ON
            dd.date_key = s.trans_date_key
            AND dd.calendar_date between #weeks.weekStartDate and #weeks.weekStopDate
        WHERE
            p.upc = @upc
			AND s.trans_date_key BETWEEN @startDateKey AND @stopDateKey
        )


     DECLARE @pack INT
--     select @pack = ISNULL(sp.packagesize,1) 
--     FROM 
-- 	supplierproduct sp
--     WHERE
--         sp.upc = @upc 
--         AND sp.supplierid = @supplierId


    SET NOCOUNT OFF
    SELECT 
		weekStartDate
		,quantity as units
		,CONVERT(numeric(9,2), quantity/@pack) as cases 
	from 
		#weeks


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    PROCEDURE [dbo].[GetPriceAuditSummaryByWeekYear]
	@week INT,
	@year INT
AS

SET NOCOUNT ON

DECLARE @wkBeginDateKey INT
DECLARE @wkEndDateKey INT
SELECT
	@wkBeginDateKey = MIN(date_key),
	@wkEndDateKey = MAX(date_key)
FROM
	date_dim
WHERE
	sales_year = @year
	and sales_week = @week

DECLARE @wkEndDate DATETIME
SELECT @wkEndDate = calendar_date FROM date_dim WHERE date_key = @wkEndDateKey

--
-- week to date
--
CREATE TABLE #tempWeek (
	store_key INT
	,period_scan_count INT
	,period_wrong_count INT
	,period_wrong_percent DECIMAL(9,2)
	,period_nof_count INT
	,period_nof_percent DECIMAL(9,2)
	,period_no_loc_count INT
	,period_no_loc_percent DECIMAL(9,2)
	,period_wrong_loc_count INT
	,period_wrong_loc_percent DECIMAL(9,2)
)

INSERT #tempWeek SELECT	
	store_key, COUNT(pa.upc) as item_count,0,0,0,0,0,0,0,0
FROM
	price_audit_detail_fact pa
INNER JOIN date_dim da ON
	da.date_key = pa.audit_date_key
WHERE
	da.sales_year = @year
	AND da.sales_week = @week
GROUP BY
	pa.store_key

DECLARE @wrong TABLE (
	store_key INT,
	wrong_count INT
)
DECLARE @nof TABLE (
	store_key INT,
	nof_count INT
)
DECLARE @no_loc TABLE (
	store_key INT,
	no_loc_count INT
)
DECLARE @wrong_loc TABLE (
	store_key INT,
	wrong_loc_count INT
)

INSERT INTO @wrong SELECT store_key, COUNT(*) FROM price_audit_detail_fact pa INNER JOIN date_dim da ON da.date_key = pa.audit_date_key
	WHERE
		da.sales_year = @year
		AND da.sales_week = @week
		and pa.wrong_price_marked = 1
	GROUP BY
		pa.store_key
INSERT INTO @nof SELECT pa.store_key, COUNT(*) FROM price_audit_detail_fact pa INNER JOIN date_dim da ON da.date_key = pa.audit_date_key
	WHERE
		da.sales_year = @year
		AND da.sales_week = @week
		and pa.not_on_file = 1
	GROUP BY
		pa.store_key
INSERT INTO @no_loc SELECT pa.store_key, COUNT(*) FROM price_audit_detail_fact pa INNER JOIN date_dim da ON da.date_key = pa.audit_date_key
	WHERE
		da.sales_year = @year
		AND da.sales_week = @week
		and pa.location_not_assigned = 1
	GROUP BY
		pa.store_key
INSERT INTO @wrong_loc SELECT pa.store_key, COUNT(*) FROM price_audit_detail_fact pa INNER JOIN date_dim da ON da.date_key = pa.audit_date_key
	WHERE
		da.sales_year = @year
		AND da.sales_week = @week
		and pa.wrong_location_assigned = 1
	GROUP BY
		pa.store_key

UPDATE tp SET 
	period_wrong_count = w.wrong_count
	,period_nof_count = n.nof_count
	,period_no_loc_count = nl.no_loc_count
	,period_wrong_loc_count = wl.wrong_loc_count
FROM
	#tempWeek tp
LEFT OUTER JOIN @wrong w ON
	w.store_key = tp.store_key
LEFT OUTER JOIN @nof n ON
	n.store_key = tp.store_key
LEFT OUTER JOIN @no_loc nl ON
	nl.store_key = tp.store_key
LEFT OUTER JOIN @wrong_loc wl ON
	wl.store_key = tp.store_key


UPDATE tp SET
	period_wrong_percent = CONVERT(numeric,period_wrong_count) / CONVERT(numeric,period_scan_count)  * 100
	,period_nof_percent = CONVERT(numeric,period_nof_count) / CONVERT(numeric,period_scan_count)  * 100
	,period_no_loc_percent = CONVERT(numeric,period_no_loc_count) / CONVERT(numeric,period_scan_count)  * 100
	,period_wrong_loc_percent = CONVERT(numeric,period_wrong_loc_count) / CONVERT(numeric,period_scan_count)  * 100
FROM
	#tempWeek tp
WHERE
	tp.period_scan_count <> 0

--
-- quarter to date
--
DECLARE @currQtr VARCHAR(3)
DECLARE @qtrEndDateKey INT
DECLARE @qtrStartDateKey INT
SELECT @currQtr = sales_quarter FROM date_dim da1 WHERE da1.sales_year = @year and sales_week = @week
SELECT @qtrStartDateKey = MIN(date_key) FROM date_dim WHERE sales_year = @year and sales_quarter = @currQtr
SELECT @qtrEndDateKey = MAX(date_key) FROM date_dim WHERE sales_year = @year and sales_quarter = @currQtr
CREATE TABLE #tempQuarter (
	store_key INT
	,quarter_scan_count INT
	,quarter_wrong_count INT
	,quarter_wrong_percent DECIMAL(9,2)
	,quarter_nof_count INT
	,quarter_nof_percent DECIMAL(9,2)
	,quarter_no_loc_count INT
	,quarter_no_loc_percent DECIMAL(9,2)
	,quarter_wrong_loc_count INT
	,quarter_wrong_loc_percent DECIMAL(9,2)
)

INSERT #tempQuarter SELECT 
	store_key, 
	COUNT(pa.upc) as item_count,
	0,0,0,0,0,0,0,0
FROM
	price_audit_detail_fact pa
INNER JOIN date_dim da ON
	da.date_key= pa.audit_date_key
WHERE
	da.sales_year = @year
 	and pa.audit_date_key >= @qtrStartDateKey
 	and pa.audit_date_key <= @qtrEndDateKey
	and pa.audit_date_key <= @wkEndDateKey
GROUP BY 
	pa.store_key

DELETE FROM @wrong
INSERT INTO @wrong SELECT store_key, COUNT(*) FROM price_audit_detail_fact pa INNER JOIN date_dim da ON da.date_key = pa.audit_date_key
	WHERE
		da.sales_year = @year
	 	and pa.audit_date_key >= @qtrStartDateKey
	 	and pa.audit_date_key <= @qtrEndDateKey
		and pa.audit_date_key <= @wkEndDateKey
		and pa.wrong_price_marked = 1
	GROUP BY
		pa.store_key

DELETE FROM @nof
INSERT INTO @nof SELECT pa.store_key, COUNT(*) FROM price_audit_detail_fact pa INNER JOIN date_dim da ON da.date_key = pa.audit_date_key
	WHERE
		da.sales_year = @year
	 	and pa.audit_date_key >= @qtrStartDateKey
	 	and pa.audit_date_key <= @qtrEndDateKey
		and pa.audit_date_key <= @wkEndDateKey
		and pa.not_on_file = 1
	GROUP BY
		pa.store_key
DELETE FROM @no_loc
INSERT INTO @no_loc SELECT pa.store_key, COUNT(*) FROM price_audit_detail_fact pa INNER JOIN date_dim da ON da.date_key = pa.audit_date_key
	WHERE
		da.sales_year = @year
	 	and pa.audit_date_key >= @qtrStartDateKey
	 	and pa.audit_date_key <= @qtrEndDateKey
		and pa.audit_date_key <= @wkEndDateKey
		and pa.location_not_assigned = 1
	GROUP BY
		pa.store_key
DELETE FROM @wrong_loc
INSERT INTO @wrong_loc SELECT pa.store_key, COUNT(*) FROM price_audit_detail_fact pa INNER JOIN date_dim da ON da.date_key = pa.audit_date_key
	WHERE
		da.sales_year = @year
	 	and pa.audit_date_key >= @qtrStartDateKey
	 	and pa.audit_date_key <= @qtrEndDateKey
		and pa.audit_date_key <= @wkEndDateKey
		and pa.wrong_location_assigned = 1
	GROUP BY
		pa.store_key


UPDATE tq SET 
	quarter_wrong_count = w.wrong_count
	,quarter_nof_count = n.nof_count
	,quarter_no_loc_count = nl.no_loc_count
	,quarter_wrong_loc_count = wl.wrong_loc_count
FROM
	#tempQuarter tq
LEFT OUTER JOIN @wrong w ON
	w.store_key = tq.store_key
LEFT OUTER JOIN @nof n ON
	n.store_key = tq.store_key
LEFT OUTER JOIN @no_loc nl ON
	nl.store_key = tq.store_key
LEFT OUTER JOIN @wrong_loc wl ON
	wl.store_key = tq.store_key

UPDATE tq SET
	quarter_wrong_percent = CONVERT(numeric,quarter_wrong_count) / CONVERT(numeric,quarter_scan_count)  * 100
	,quarter_nof_percent = CONVERT(numeric,quarter_nof_count) / CONVERT(numeric,quarter_scan_count)  * 100
	,quarter_no_loc_percent = CONVERT(numeric,quarter_no_loc_count) / CONVERT(numeric,quarter_scan_count)  * 100
	,quarter_wrong_loc_percent = CONVERT(numeric,quarter_wrong_loc_count) / CONVERT(numeric,quarter_scan_count)  * 100
FROM
	#tempQuarter tq
WHERE
	tq.quarter_scan_count <> 0


--
-- year to date
--
DECLARE @currYear VARCHAR(3)
DECLARE @yearEndDateKey INT
SELECT @currYear = sales_quarter FROM date_dim da1 WHERE da1.sales_year = @year and sales_week = @week
SELECT @yearEndDateKey = MAX(date_key) FROM date_dim WHERE sales_year = @year and sales_quarter = @currYear
CREATE TABLE #tempYear (
	store_key INT
	,year_scan_count INT
	,year_wrong_count INT
	,year_wrong_percent DECIMAL(9,2)
	,year_nof_count INT
	,year_nof_percent DECIMAL(9,2)
	,year_no_loc_count INT
	,year_no_loc_percent DECIMAL(9,2)
	,year_wrong_loc_count INT
	,year_wrong_loc_percent DECIMAL(9,2)
)


INSERT #tempYear SELECT 
	store_key, 
	COUNT(pa.upc),
	0,0,0,0,0,0,0,0
FROM
	price_audit_detail_fact pa
INNER JOIN date_dim da ON
	da.date_key = pa.audit_date_key
WHERE
	da.sales_year = @year
 	and pa.audit_date_key <= @yearEndDateKey
	and pa.audit_date_key <= @wkEndDateKey
GROUP BY 
	pa.store_key

DELETE FROM @wrong
INSERT INTO @wrong SELECT store_key, COUNT(*) FROM price_audit_detail_fact pa INNER JOIN date_dim da ON da.date_key = pa.audit_date_key
	WHERE
		da.sales_year = @year
	 	and pa.audit_date_key <= @yearEndDateKey
		and pa.audit_date_key <= @wkEndDateKey
		and pa.wrong_price_marked = 1
	GROUP BY
		pa.store_key

DELETE FROM @nof
INSERT INTO @nof SELECT pa.store_key, COUNT(*) FROM price_audit_detail_fact pa INNER JOIN date_dim da ON da.date_key = pa.audit_date_key
	WHERE
		da.sales_year = @year
	 	and pa.audit_date_key <= @yearEndDateKey
		and pa.audit_date_key <= @wkEndDateKey
		and pa.not_on_file = 1
	GROUP BY
		pa.store_key
DELETE FROM @no_loc
INSERT INTO @no_loc SELECT pa.store_key, COUNT(*) FROM price_audit_detail_fact pa INNER JOIN date_dim da ON da.date_key = pa.audit_date_key
	WHERE
		da.sales_year = @year
	 	and pa.audit_date_key <= @yearEndDateKey
		and pa.audit_date_key <= @wkEndDateKey
		and pa.location_not_assigned = 1
	GROUP BY
		pa.store_key
DELETE FROM @wrong_loc
INSERT INTO @wrong_loc SELECT pa.store_key, COUNT(*) FROM price_audit_detail_fact pa INNER JOIN date_dim da ON da.date_key = pa.audit_date_key
	WHERE
		da.sales_year = @year
	 	and pa.audit_date_key <= @yearEndDateKey
		and pa.audit_date_key <= @wkEndDateKey
		and pa.wrong_location_assigned = 1
	GROUP BY
		pa.store_key


UPDATE ty SET 
	year_wrong_count = w.wrong_count
	,year_nof_count = n.nof_count
	,year_no_loc_count = nl.no_loc_count
	,year_wrong_loc_count = wl.wrong_loc_count
FROM
	#tempYear ty
LEFT OUTER JOIN @wrong w ON
	w.store_key = ty.store_key
LEFT OUTER JOIN @nof n ON
	n.store_key = ty.store_key
LEFT OUTER JOIN @no_loc nl ON
	nl.store_key = ty.store_key
LEFT OUTER JOIN @wrong_loc wl ON
	wl.store_key = ty.store_key

UPDATE ty SET
	year_wrong_percent = CONVERT(numeric,year_wrong_count) / CONVERT(numeric,year_scan_count)  * 100,
	year_nof_percent = CONVERT(numeric,year_nof_count) / CONVERT(numeric,year_scan_count)  * 100
	,year_no_loc_percent = CONVERT(numeric,year_no_loc_count) / CONVERT(numeric,year_scan_count)  * 100
	,year_wrong_loc_percent = CONVERT(numeric,year_wrong_loc_count) / CONVERT(numeric,year_scan_count)  * 100
FROM
	#tempYear ty
WHERE
	ty.year_scan_count <> 0

SET NOCOUNT OFF
SELECT
	s.store_key
	,s.short_name

	,period_scan_count
	,period_wrong_count
	,period_wrong_percent
	,period_nof_count
	,period_nof_percent 
	,period_no_loc_count
	,period_no_loc_percent
	,period_wrong_loc_count
	,period_wrong_loc_percent

	,quarter_scan_count
	,quarter_wrong_count
	,quarter_wrong_percent
	,quarter_nof_count
	,quarter_nof_percent
	,quarter_no_loc_count
	,quarter_no_loc_percent
	,quarter_wrong_loc_count
	,quarter_wrong_loc_percent

	,year_scan_count
	,year_wrong_count
	,year_wrong_percent
	,year_nof_count
	,year_nof_percent
	,year_no_loc_count
	,year_no_loc_percent
	,year_wrong_loc_count
	,year_wrong_loc_percent

FROM 
	store_dim s 
LEFT OUTER JOIN #tempWeek tp ON
	tp.store_key = s.store_key
LEFT OUTER JOIN #tempQuarter tq ON
	tq.store_key = s.store_key
LEFT OUTER JOIN #tempYear ty ON
	ty.store_key = s.store_key


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC GetPriceAuditSummaryByWeekYear2 36, 2008
-- EXEC GetPriceAuditSummaryByWeekYear 36, 2008
CREATE  PROCEDURE [dbo].[GetPriceAuditSummaryByWeekYear2]
	@week INT,
	@year INT
AS

SET NOCOUNT ON

DECLARE @wkBeginDateKey INT
DECLARE @wkEndDateKey INT
SELECT
	@wkBeginDateKey = MIN(date_key),
	@wkEndDateKey = MAX(date_key)
FROM
	date_dim
WHERE
	sales_year = @year
	and sales_week = @week

DECLARE @wkEndDate DATETIME
SELECT @wkEndDate = calendar_date FROM date_dim WHERE date_key = @wkEndDateKey

--
-- week to date
--
CREATE TABLE #tempWeek (
	store_key INT
	,period_scan_count INT
	,period_wrong_count INT
	,period_wrong_percent DECIMAL(9,2)
	,period_nof_count INT
	,period_nof_percent DECIMAL(9,2)
	,period_no_loc_count INT
	,period_no_loc_percent DECIMAL(9,2)
	,period_wrong_loc_count INT
	,period_wrong_loc_percent DECIMAL(9,2)
)

INSERT #tempWeek SELECT	
	store_key, COUNT(pa.upc) as item_count,0,0,0,0,0,0,0,0
FROM
	price_audit_detail_fact pa
INNER JOIN date_dim da ON
	da.date_key = pa.audit_date_key
WHERE
	da.sales_year = @year
	AND da.sales_week = @week
GROUP BY
	pa.store_key

DECLARE @wrong TABLE (
	store_key INT,
	wrong_count INT
)
DECLARE @nof TABLE (
	store_key INT,
	nof_count INT
)
DECLARE @no_loc TABLE (
	store_key INT,
	no_loc_count INT
)
DECLARE @wrong_loc TABLE (
	store_key INT,
	wrong_loc_count INT
)

INSERT INTO @wrong SELECT store_key, COUNT(*) FROM price_audit_detail_fact pa INNER JOIN date_dim da ON da.date_key = pa.audit_date_key
	WHERE
		da.sales_year = @year
		AND da.sales_week = @week
		and pa.wrong_price_marked = 1
	GROUP BY
		pa.store_key
INSERT INTO @nof SELECT pa.store_key, COUNT(*) FROM price_audit_detail_fact pa INNER JOIN date_dim da ON da.date_key = pa.audit_date_key
	WHERE
		da.sales_year = @year
		AND da.sales_week = @week
		and pa.not_on_file = 1
	GROUP BY
		pa.store_key
INSERT INTO @no_loc SELECT pa.store_key, COUNT(*) FROM price_audit_detail_fact pa INNER JOIN date_dim da ON da.date_key = pa.audit_date_key
	WHERE
		da.sales_year = @year
		AND da.sales_week = @week
		and pa.location_not_assigned = 1
	GROUP BY
		pa.store_key
INSERT INTO @wrong_loc SELECT pa.store_key, COUNT(*) FROM price_audit_detail_fact pa INNER JOIN date_dim da ON da.date_key = pa.audit_date_key
	WHERE
		da.sales_year = @year
		AND da.sales_week = @week
		and pa.wrong_location_assigned = 1
	GROUP BY
		pa.store_key

UPDATE tp SET 
	period_wrong_count = w.wrong_count
	,period_nof_count = n.nof_count
	,period_no_loc_count = nl.no_loc_count
	,period_wrong_loc_count = wl.wrong_loc_count
FROM
	#tempWeek tp
LEFT OUTER JOIN @wrong w ON
	w.store_key = tp.store_key
LEFT OUTER JOIN @nof n ON
	n.store_key = tp.store_key
LEFT OUTER JOIN @no_loc nl ON
	nl.store_key = tp.store_key
LEFT OUTER JOIN @wrong_loc wl ON
	wl.store_key = tp.store_key


UPDATE tp SET
	period_wrong_percent = CONVERT(numeric,period_wrong_count) / CONVERT(numeric,period_scan_count)  * 100
	,period_nof_percent = CONVERT(numeric,period_nof_count) / CONVERT(numeric,period_scan_count)  * 100
	,period_no_loc_percent = CONVERT(numeric,period_no_loc_count) / CONVERT(numeric,period_scan_count)  * 100
	,period_wrong_loc_percent = CONVERT(numeric,period_wrong_loc_count) / CONVERT(numeric,period_scan_count)  * 100
FROM
	#tempWeek tp
WHERE
	tp.period_scan_count <> 0

--
-- quarter to date
--
DECLARE @currQtr VARCHAR(3)
DECLARE @qtrEndDateKey INT
DECLARE @qtrStartDateKey INT
SELECT @currQtr = sales_quarter FROM date_dim da1 WHERE da1.sales_year = @year and sales_week = @week
SELECT @qtrStartDateKey = MIN(date_key) FROM date_dim WHERE sales_year = @year and sales_quarter = @currQtr
SELECT @qtrEndDateKey = MAX(date_key) FROM date_dim WHERE sales_year = @year and sales_quarter = @currQtr
CREATE TABLE #tempQuarter (
	store_key INT
	,quarter_scan_count INT
	,quarter_wrong_count INT
	,quarter_wrong_percent DECIMAL(9,2)
	,quarter_nof_count INT
	,quarter_nof_percent DECIMAL(9,2)
	,quarter_no_loc_count INT
	,quarter_no_loc_percent DECIMAL(9,2)
	,quarter_wrong_loc_count INT
	,quarter_wrong_loc_percent DECIMAL(9,2)
)

INSERT #tempQuarter SELECT 
	store_key, 
	COUNT(pa.upc) as item_count,
	0,0,0,0,0,0,0,0
FROM
	price_audit_detail_fact pa
INNER JOIN date_dim da ON
	da.date_key= pa.audit_date_key
WHERE
	da.sales_year = @year
 	and pa.audit_date_key >= @qtrStartDateKey
 	and pa.audit_date_key <= @qtrEndDateKey
	and pa.audit_date_key <= @wkEndDateKey
GROUP BY 
	pa.store_key

DELETE FROM @wrong
INSERT INTO @wrong SELECT store_key, COUNT(*) FROM price_audit_detail_fact pa INNER JOIN date_dim da ON da.date_key = pa.audit_date_key
	WHERE
		da.sales_year = @year
	 	and pa.audit_date_key >= @qtrStartDateKey
	 	and pa.audit_date_key <= @qtrEndDateKey
		and pa.audit_date_key <= @wkEndDateKey
		and pa.wrong_price_marked = 1
	GROUP BY
		pa.store_key

DELETE FROM @nof
INSERT INTO @nof SELECT pa.store_key, COUNT(*) FROM price_audit_detail_fact pa INNER JOIN date_dim da ON da.date_key = pa.audit_date_key
	WHERE
		da.sales_year = @year
	 	and pa.audit_date_key >= @qtrStartDateKey
	 	and pa.audit_date_key <= @qtrEndDateKey
		and pa.audit_date_key <= @wkEndDateKey
		and pa.not_on_file = 1
	GROUP BY
		pa.store_key
DELETE FROM @no_loc
INSERT INTO @no_loc SELECT pa.store_key, COUNT(*) FROM price_audit_detail_fact pa INNER JOIN date_dim da ON da.date_key = pa.audit_date_key
	WHERE
		da.sales_year = @year
	 	and pa.audit_date_key >= @qtrStartDateKey
	 	and pa.audit_date_key <= @qtrEndDateKey
		and pa.audit_date_key <= @wkEndDateKey
		and pa.location_not_assigned = 1
	GROUP BY
		pa.store_key
DELETE FROM @wrong_loc
INSERT INTO @wrong_loc SELECT pa.store_key, COUNT(*) FROM price_audit_detail_fact pa INNER JOIN date_dim da ON da.date_key = pa.audit_date_key
	WHERE
		da.sales_year = @year
	 	and pa.audit_date_key >= @qtrStartDateKey
	 	and pa.audit_date_key <= @qtrEndDateKey
		and pa.audit_date_key <= @wkEndDateKey
		and pa.wrong_location_assigned = 1
	GROUP BY
		pa.store_key


UPDATE tq SET 
	quarter_wrong_count = w.wrong_count
	,quarter_nof_count = n.nof_count
	,quarter_no_loc_count = nl.no_loc_count
	,quarter_wrong_loc_count = wl.wrong_loc_count
FROM
	#tempQuarter tq
LEFT OUTER JOIN @wrong w ON
	w.store_key = tq.store_key
LEFT OUTER JOIN @nof n ON
	n.store_key = tq.store_key
LEFT OUTER JOIN @no_loc nl ON
	nl.store_key = tq.store_key
LEFT OUTER JOIN @wrong_loc wl ON
	wl.store_key = tq.store_key

UPDATE tq SET
	quarter_wrong_percent = CONVERT(numeric,quarter_wrong_count) / CONVERT(numeric,quarter_scan_count)  * 100
	,quarter_nof_percent = CONVERT(numeric,quarter_nof_count) / CONVERT(numeric,quarter_scan_count)  * 100
	,quarter_no_loc_percent = CONVERT(numeric,quarter_no_loc_count) / CONVERT(numeric,quarter_scan_count)  * 100
	,quarter_wrong_loc_percent = CONVERT(numeric,quarter_wrong_loc_count) / CONVERT(numeric,quarter_scan_count)  * 100
FROM
	#tempQuarter tq
WHERE
	tq.quarter_scan_count <> 0


--
-- year to date
--
DECLARE @currYear VARCHAR(3)
DECLARE @yearEndDateKey INT
SELECT @currYear = sales_quarter FROM date_dim da1 WHERE da1.sales_year = @year and sales_week = @week
SELECT @yearEndDateKey = MAX(date_key) FROM date_dim WHERE sales_year = @year and sales_quarter = @currYear
CREATE TABLE #tempYear (
	store_key INT
	,year_scan_count INT
	,year_wrong_count INT
	,year_wrong_percent DECIMAL(9,2)
	,year_nof_count INT
	,year_nof_percent DECIMAL(9,2)
	,year_no_loc_count INT
	,year_no_loc_percent DECIMAL(9,2)
	,year_wrong_loc_count INT
	,year_wrong_loc_percent DECIMAL(9,2)
)


INSERT #tempYear SELECT 
	store_key, 
	COUNT(pa.upc),
	0,0,0,0,0,0,0,0
FROM
	price_audit_detail_fact pa
INNER JOIN date_dim da ON
	da.date_key = pa.audit_date_key
WHERE
	da.sales_year = @year
 	and pa.audit_date_key <= @yearEndDateKey
	and pa.audit_date_key <= @wkEndDateKey
GROUP BY 
	pa.store_key

DELETE FROM @wrong
INSERT INTO @wrong SELECT store_key, COUNT(*) FROM price_audit_detail_fact pa INNER JOIN date_dim da ON da.date_key = pa.audit_date_key
	WHERE
		da.sales_year = @year
	 	and pa.audit_date_key <= @yearEndDateKey
		and pa.audit_date_key <= @wkEndDateKey
		and pa.wrong_price_marked = 1
	GROUP BY
		pa.store_key

DELETE FROM @nof
INSERT INTO @nof SELECT pa.store_key, COUNT(*) FROM price_audit_detail_fact pa INNER JOIN date_dim da ON da.date_key = pa.audit_date_key
	WHERE
		da.sales_year = @year
	 	and pa.audit_date_key <= @yearEndDateKey
		and pa.audit_date_key <= @wkEndDateKey
		and pa.not_on_file = 1
	GROUP BY
		pa.store_key
DELETE FROM @no_loc
INSERT INTO @no_loc SELECT pa.store_key, COUNT(*) FROM price_audit_detail_fact pa INNER JOIN date_dim da ON da.date_key = pa.audit_date_key
	WHERE
		da.sales_year = @year
	 	and pa.audit_date_key <= @yearEndDateKey
		and pa.audit_date_key <= @wkEndDateKey
		and pa.location_not_assigned = 1
	GROUP BY
		pa.store_key
DELETE FROM @wrong_loc
INSERT INTO @wrong_loc SELECT pa.store_key, COUNT(*) FROM price_audit_detail_fact pa INNER JOIN date_dim da ON da.date_key = pa.audit_date_key
	WHERE
		da.sales_year = @year
	 	and pa.audit_date_key <= @yearEndDateKey
		and pa.audit_date_key <= @wkEndDateKey
		and pa.wrong_location_assigned = 1
	GROUP BY
		pa.store_key


UPDATE ty SET 
	year_wrong_count = w.wrong_count
	,year_nof_count = n.nof_count
	,year_no_loc_count = nl.no_loc_count
	,year_wrong_loc_count = wl.wrong_loc_count
FROM
	#tempYear ty
LEFT OUTER JOIN @wrong w ON
	w.store_key = ty.store_key
LEFT OUTER JOIN @nof n ON
	n.store_key = ty.store_key
LEFT OUTER JOIN @no_loc nl ON
	nl.store_key = ty.store_key
LEFT OUTER JOIN @wrong_loc wl ON
	wl.store_key = ty.store_key

UPDATE ty SET
	year_wrong_percent = CONVERT(numeric,year_wrong_count) / CONVERT(numeric,year_scan_count)  * 100,
	year_nof_percent = CONVERT(numeric,year_nof_count) / CONVERT(numeric,year_scan_count)  * 100
	,year_no_loc_percent = CONVERT(numeric,year_no_loc_count) / CONVERT(numeric,year_scan_count)  * 100
	,year_wrong_loc_percent = CONVERT(numeric,year_wrong_loc_count) / CONVERT(numeric,year_scan_count)  * 100
FROM
	#tempYear ty
WHERE
	ty.year_scan_count <> 0

SET NOCOUNT OFF
SELECT
	s.store_key
	,s.short_name

	,period_scan_count
	,period_wrong_count
	,period_wrong_percent
	,period_nof_count
	,period_nof_percent 
	,period_no_loc_count
	,period_no_loc_percent
	,period_wrong_loc_count
	,period_wrong_loc_percent

	,quarter_scan_count
	,quarter_wrong_count
	,quarter_wrong_percent
	,quarter_nof_count
	,quarter_nof_percent
	,quarter_no_loc_count
	,quarter_no_loc_percent
	,quarter_wrong_loc_count
	,quarter_wrong_loc_percent

	,year_scan_count
	,year_wrong_count
	,year_wrong_percent
	,year_nof_count
	,year_nof_percent
	,year_no_loc_count
	,year_no_loc_percent
	,year_wrong_loc_count
	,year_wrong_loc_percent

FROM 
	store_dim s 
LEFT OUTER JOIN #tempWeek tp ON
	tp.store_key = s.store_key
LEFT OUTER JOIN #tempQuarter tq ON
	tq.store_key = s.store_key
LEFT OUTER JOIN #tempYear ty ON
	ty.store_key = s.store_key


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROCEDURE [dbo].[GetPtdDates]
	@salesWeek INT, 
	@salesYear INT, 
	@dayOfWeekNumMax INT , 
	@period INT OUTPUT, 
	@absWeek INT OUTPUT, 
	@absDay INT OUTPUT, 
	@cutoffDate DATETIME OUTPUT, 
	@firstDateInPeriod DATETIME OUTPUT, 
	@dayInPeriod INT OUTPUT
AS

-- find fiscal period for @salesWeek, @salesYear 
SELECT DISTINCT @period = sales_period, @absWeek = absolute_week from date_dim where sales_year = @salesYear AND sales_week = @salesWeek
IF @absWeek IS NULL BEGIN
	RAISERROR('''sales_period'' not found for Year: %d Week: %d', 16, 1, @salesYear, @salesWeek)
	RETURN
END


-- find absolute_week for @salesWeek, @salesYear
SELECT 
	@absWeek = absolute_week, 
	@absDay = absolute_day 
FROM date_dim 
WHERE 
	sales_year = @salesyear 
	AND sales_period = @period 
	AND day_in_sales_period = 1

IF @absWeek IS NULL BEGIN
	RAISERROR('''absolute_week'' not found for Year: %d Week: %d', 16, 1, @salesYear, @salesWeek)
	RETURN
END

-- figure out the cutoff date if we're not including the full week
SELECT @cutoffDate = (SELECT TOP 1 calendar_date FROM date_dim WHERE sales_year = @salesYear AND sales_week = @salesWeek AND day_in_sales_week <= @dayOfWeekNumMax ORDER BY date_key DESC)

-- find the first day the period
select @firstDateInPeriod = (select top 1 calendar_date from date_dim WHERE sales_year = @salesYear AND sales_period = @period ORDER BY date_key)

-- calculate how many days of sales to include
SELECT @dayInPeriod = COUNT(*) FROM date_dim WHERE calendar_date between @firstDateInPeriod AND @cutoffDate


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[GetPtdSalesTotalCompanyByGroupMulti]
	@salesWeek INT,
	@salesYear INT,
	@dayOfWeekNumMax INT,
	@groupName VARCHAR(255), 
	@storeNumber INT = NULL,
	@sameStoresDateKey INT = NULL
AS


DECLARE @period INT
DECLARE @absWeek INT
DECLARE @absDay INT
DECLARE @cutoffDate DATETIME
DECLARE @firstDateInPeriod DATETIME
DECLARE @dayInPeriod INT
EXEC GetPtdDates @salesWeek, @salesYear, @dayOfWeekNumMax, @period OUTPUT, @absWeek OUTPUT, @absDay OUTPUT, @cutoffDate OUTPUT, @firstDateInPeriod OUTPUT, @dayInPeriod OUTPUT


-- for 1 & 2 years ago, don't use the fiscal calendar for those years.  
-- instead, take '@dayInPeriod' days, starting from the 52 & 104 weeks, 
-- backing up from @salesWeek and @salesYear
DECLARE @startDate INT
DECLARE @endDate INT

-- 104 weeks ago
SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek-52-52 AND day_in_sales_week = 1
SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInPeriod-1
EXEC GetGroupSalesByDateRange @startDate, @endDate, @groupName, @storeNumber, @sameStoresDateKey

-- 52 weeks ago
SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek-52 AND day_in_sales_week = 1
SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInPeriod-1
EXEC GetGroupSalesByDateRange @startDate, @endDate, @groupName, @storeNumber, @sameStoresDateKey

-- current period
SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek AND day_in_sales_week = 1
SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInPeriod-1
EXEC GetGroupSalesByDateRange @startDate, @endDate, @groupName, @storeNumber, @sameStoresDateKey





PRINT @startDate
PRINT @endDate
PRINT @groupName
PRINT @storeNumber
PRINT @sameStoresDateKey


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE      PROCEDURE [dbo].[GetPtdTotalsByDepartment]
	@salesWeek INT,
	@salesYear INT,
	@dayOfWeekNumMax INT,
	@departmentKey SMALLINT,
	@storeNumber INT = NULL,
	@sameStoresDateKey INT = NULL
AS

DECLARE @period INT
DECLARE @absWeek INT
DECLARE @absDay INT
DECLARE @cutoffDate DATETIME
DECLARE @firstDateInPeriod DATETIME
DECLARE @dayInPeriod INT
EXEC GetPtdDates @salesWeek, @salesYear, @dayOfWeekNumMax, @period OUTPUT, @absWeek OUTPUT, @absDay OUTPUT, @cutoffDate OUTPUT, @firstDateInPeriod OUTPUT, @dayInPeriod OUTPUT

DECLARE @startDate INT
DECLARE @endDate INT
SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek AND day_in_sales_week = 1
SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInPeriod-1

-- figure what stores to report on
DECLARE @stores TABLE (store_key INT)
IF @storeNumber IS NULL BEGIN
	IF @sameStoresDateKey = NULL OR @sameStoresDateKey = 0 BEGIN
	    INSERT @stores SELECT store_key FROM store_dim
	END ELSE BEGIN
	    INSERT @stores SELECT store_key FROM store_dim WHERE opening_date_key <= @sameStoresDateKey
	END
END ELSE BEGIN
    INSERT @stores SELECT @storeNumber
END


SET NOCOUNT ON 
-- get ptd values for department
SELECT
	dss.store_key,
    ISNULL(SUM(sales_dollar_amount),0.00) AS sales_dollar_amount,
    0 AS customer_count,
    0 AS item_count,
	@startDate AS startDate,
	@endDate AS endDate
INTO #temp
FROM daily_subdepartment_sales dss
INNER JOIN @stores s ON
	s.store_key = dss.store_key
INNER JOIN date_dim da ON
	da.date_key = dss.tlog_date_key
INNER JOIN subdepartment_dim sd ON
	sd.subdepartment_key = dss.subdepartment_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND sd.department_key = @departmentKey
GROUP BY
	dss.store_key

UPDATE #temp SET
    #temp.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_department_sales dds 
		INNER JOIN date_dim da ON da.date_key = dds.tlog_date_key
		WHERE dds.store_key = #temp.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dds.department_key = @departmentKey), 0),
    #temp.item_count = ISNULL((SELECT SUM(item_count) FROM daily_department_sales dds 
		INNER JOIN date_dim da ON da.date_key = dds.tlog_date_key
		WHERE dds.store_key = #temp.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dds.department_key = @departmentKey), 0)

-- find group for department
DECLARE @majorGrouping VARCHAR(255)
SELECT @majorGrouping = d.major_grouping FROM department_dim d WHERE department_key = @departmentKey

-- get sales for group
SELECT
	dgs.store_key,
    ISNULL(SUM(sales_dollar_amount),0.00) AS sales_dollar_amount,
    0 AS customer_count,
    0 AS item_count
INTO #group_totals
FROM daily_group_sales dgs 
INNER JOIN @stores s ON
	s.store_key = dgs.store_key
INNER JOIN date_dim da ON
	da.date_key = dgs.tlog_date_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND dgs.major_grouping = @majorGrouping
GROUP BY
	dgs.store_key

-- get counts for group
UPDATE #group_totals SET
    #group_totals.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE dgc.store_key = #group_totals.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping),0),
    #group_totals.item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE dgc.store_key = #group_totals.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping), 0)
	
SET NOCOUNT OFF
SELECT 
	t.store_key,
	t.sales_dollar_amount,
	CASE
		WHEN gt.sales_dollar_amount = 0 THEN 0 
		ELSE t.sales_dollar_amount / gt.sales_dollar_amount * 100 
	END AS sales_dist,
	t.customer_count,
	CASE
		WHEN gt.customer_count=0 THEN 0 
		ELSE CONVERT(NUMERIC(18,2), t.customer_count) / CONVERT(NUMERIC(18,2), gt.customer_count) * 100 
	END AS customer_dist,
	t.item_count,
	CASE
		WHEN gt.item_count=0 THEN 0
		ELSE CONVERT(NUMERIC(18,2), t.item_count) / CONVERT(NUMERIC(18,2), gt.item_count) * 100 
	END AS item_dist
FROM
	#temp t 
INNER JOIN #group_totals gt ON
	gt.store_key = t.store_key


SELECT
	SUM(t.sales_dollar_amount) AS sales_dollar_amount,
	CASE
		WHEN SUM(gt.sales_dollar_amount) = 0 THEN 0
		ELSE SUM(t.sales_dollar_amount) / SUM(gt.sales_dollar_amount) * 100 
	END AS sales_dist,
	SUM(t.customer_count) AS customer_count,
	CASE
		WHEN SUM(gt.customer_count) = 0 THEN 0
		ELSE (CONVERT(NUMERIC(18,2), SUM(t.customer_count)) / CONVERT(NUMERIC(18,2), SUM(gt.customer_count))) * 100 
	END AS customer_dist,
	SUM(t.item_count) AS item_count,
	CASE
		WHEN SUM(gt.item_count) = 0 THEN 0
		ELSE (CONVERT(NUMERIC(18,2), SUM(t.item_count)) / CONVERT(NUMERIC(18,2), SUM(gt.item_count))) * 100 
	END AS item_dist
FROM
	#temp t
INNER JOIN #group_totals gt ON
	gt.store_key = t.store_key


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[GetPtdTotalsByDepartmentMulti]
	@salesWeek INT,
	@salesYear INT,
	@dayOfWeekNumMax INT,
	@departmentKey SMALLINT,
	@storeNumber INT = NULL,
	@sameStoresDateKey INT = NULl
AS

DECLARE @Period VARCHAR(10)
DECLARE @absWeek INT
DECLARE @absDay INT
DECLARE @cutoffDate DATETIME
DECLARE @firstDateInPeriod DATETIME
DECLARE @dayInPeriod INT
EXEC GetPtdDates @salesWeek, @salesYear, @dayOfWeekNumMax, @Period OUTPUT, @absWeek OUTPUT, @absDay OUTPUT, @cutoffDate OUTPUT, @firstDateInPeriod OUTPUT, @dayInPeriod OUTPUT


DECLARE @startDate INT
DECLARE @endDate INT

-- 104 weeks ago
SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek-52-52 AND day_of_week_num = 1
SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInPeriod-1
EXEC GetDepartmentSalesByDateRangeRollup @startDate, @endDate, @departmentKey, @storeNumber, @sameStoresDateKey

-- 52 weeks ago
SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek-52 AND day_of_week_num = 1
SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInPeriod-1
EXEC GetDepartmentSalesByDateRangeRollup @startDate, @endDate, @departmentKey, @storeNumber, @sameStoresDateKey

-- current period
SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek AND day_of_week_num = 1
SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInPeriod-1
EXEC GetDepartmentSalesByDateRangeRollup @startDate, @endDate, @departmentKey, @storeNumber, @sameStoresDateKey


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE      PROCEDURE [dbo].[GetPtdTotalsByGroup]
	@salesWeek INT,
	@salesYear INT,
	@dayOfWeekNumMax INT,
	@majorGrouping VARCHAR(255),
	@storeNumber INT = NULL,
	@sameStoresDateKey INT = NULL
AS


DECLARE @Period VARCHAR(10)
DECLARE @absWeek INT
DECLARE @absDay INT
DECLARE @cutoffDate DATETIME
DECLARE @firstDateInPeriod DATETIME
DECLARE @dayInPeriod INT
EXEC GetPtdDates @salesWeek, @salesYear, @dayOfWeekNumMax, @Period OUTPUT, @absWeek OUTPUT, @absDay OUTPUT, @cutoffDate OUTPUT, @firstDateInPeriod OUTPUT, @dayInPeriod OUTPUT

DECLARE @startDate INT
DECLARE @endDate INT
SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek AND day_in_sales_week = 1
SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInPeriod-1

-- figure what stores to report on
DECLARE @stores TABLE (store_key INT)
IF @storeNumber IS NULL BEGIN
	IF @sameStoresDateKey = NULL OR @sameStoresDateKey = 0 BEGIN
	    INSERT @stores SELECT store_key FROM store_dim
	END ELSE BEGIN
	    INSERT @stores SELECT store_key FROM store_dim WHERE opening_date_key <= @sameStoresDateKey
	END
END ELSE BEGIN
    INSERT @stores SELECT @storeNumber
END


SET NOCOUNT ON 
SELECT
	dgs.store_key,
    ISNULL(SUM(sales_dollar_amount),0) AS sales_dollar_amount,
	100 AS sales_dist,
    0 AS customer_count,
	100 AS customer_dist,
    0 AS item_count,
	100 AS  item_dist,
	@startDate AS startDate,
	@endDate AS endDate
INTO #temp
FROM daily_group_sales dgs 
INNER JOIN @stores s ON
	s.store_key = dgs.store_key
INNER JOIN date_dim da ON
	da.date_key = dgs.tlog_date_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND dgs.major_grouping = @majorGrouping
GROUP BY
	dgs.store_key

UPDATE #temp SET
    #temp.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE dgc.store_key = #temp.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping),0),
    #temp.item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE dgc.store_key = #temp.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping), 0)


SET NOCOUNT OFF

-- 1 record for every store
SELECT * FROM #temp

-- totals
SELECT
	SUM(sales_dollar_amount) AS sales_dollar_amount,
	100.00 AS sales_dist,
	SUM(customer_count) AS customer_count,
	100.00 AS customer_dist,
	SUM(item_count) AS item_count,
	100.00 as item_dist
FROM
	#temp


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROCEDURE [dbo].[GetPtdTotalsBySubdepartment]
	@salesWeek INT,
	@salesYear INT,
	@dayOfWeekNumMax INT,
	@subdepartmentKey SMALLINT,
	@storeNumber INT = NULL,
	@sameStoresDateKey INT = NULL
AS


DECLARE @Period VARCHAR(10)
DECLARE @absWeek INT
DECLARE @absDay INT
DECLARE @cutoffDate DATETIME
DECLARE @firstDateInPeriod DATETIME
DECLARE @dayInPeriod INT
EXEC GetPtdDates @salesWeek, @salesYear, @dayOfWeekNumMax, @Period OUTPUT, @absWeek OUTPUT, @absDay OUTPUT, @cutoffDate OUTPUT, @firstDateInPeriod OUTPUT, @dayInPeriod OUTPUT

DECLARE @startDate INT
DECLARE @endDate INT
SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek AND day_in_sales_week = 1
SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInPeriod-1

-- figure what stores to report on
DECLARE @stores TABLE (store_key INT)
IF @storeNumber IS NULL BEGIN
	IF @sameStoresDateKey = NULL OR @sameStoresDateKey = 0 BEGIN
	    INSERT @stores SELECT store_key FROM store_dim
	END ELSE BEGIN
	    INSERT @stores SELECT store_key FROM store_dim WHERE opening_date_key <= @sameStoresDateKey
	END
END ELSE BEGIN
    INSERT @stores SELECT @storeNumber
END


-- get Ptd values for subdepartment
SET NOCOUNT ON 
SELECT
	dss.store_key,
    ISNULL(SUM(sales_dollar_amount),0.00) AS sales_dollar_amount,
    0 AS customer_count,
    0 AS item_count,
	@startDate AS startDate,
	@endDate AS endDate
INTO #temp
FROM daily_subdepartment_sales dss
INNER JOIN @stores s ON
	s.store_key = dss.store_key
INNER JOIN date_dim da ON
	da.date_key = dss.tlog_date_key
INNER JOIN subdepartment_dim sd ON
	sd.subdepartment_key = dss.subdepartment_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND sd.subdepartment_key = @subdepartmentKey
GROUP BY
	dss.store_key

UPDATE #temp SET
    #temp.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_subdepartment_sales dss 
		INNER JOIN date_dim da ON da.date_key = dss.tlog_date_key
		WHERE dss.store_key = #temp.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dss.subdepartment_key = @subdepartmentKey), 0),
    #temp.item_count = ISNULL((SELECT SUM(item_count) FROM daily_subdepartment_sales dss 
		INNER JOIN date_dim da ON da.date_key = dss.tlog_date_key
		WHERE dss.store_key = #temp.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dss.subdepartment_key = @subdepartmentKey), 0)

-- find group for department
DECLARE @majorGrouping VARCHAR(255)
SELECT 
	@majorGrouping = d.major_grouping 
FROM 
	department_dim d 
INNER JOIN subdepartment_dim sd ON
	sd.department_key = d.department_key
WHERE 
	sd.subdepartment_key = @subdepartmentKey

-- get sales for group
SELECT
	dgs.store_key,
    ISNULL(SUM(sales_dollar_amount),0.00) AS sales_dollar_amount,
    0 AS customer_count,
    0 AS item_count
INTO #group_totals
FROM daily_group_sales dgs 
INNER JOIN @stores s ON
	s.store_key = dgs.store_key
INNER JOIN date_dim da ON
	da.date_key = dgs.tlog_date_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND dgs.major_grouping = @majorGrouping
GROUP BY
	dgs.store_key

-- get counts for group
UPDATE #group_totals SET
    #group_totals.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE dgc.store_key = #group_totals.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping),0),
    #group_totals.item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE dgc.store_key = #group_totals.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping), 0)
	
SET NOCOUNT OFF
SELECT 
	t.store_key,
	t.sales_dollar_amount,
	CASE 
		WHEN gt.sales_dollar_amount = 0 THEN 0
		ELSE t.sales_dollar_amount / gt.sales_dollar_amount * 100 
	END AS sales_dist,
	t.customer_count,
	CASE 
		WHEN gt.customer_count = 0 THEN 0
		ELSE CONVERT(NUMERIC(18,2), t.customer_count) / CONVERT(NUMERIC(18,2), gt.customer_count) * 100 
	END AS customer_dist,
	t.item_count,
	CASE
		WHEN gt.item_count = 0 THEN 0
		ELSE CONVERT(NUMERIC(18,2), t.item_count) / CONVERT(NUMERIC(18,2), gt.item_count) * 100 
	END AS item_dist
FROM
	#temp t 
INNER JOIN #group_totals gt ON
	gt.store_key = t.store_key

SELECT
	SUM(t.sales_dollar_amount) AS sales_dollar_amount,
	CASE
		WHEN SUM(gt.sales_dollar_amount) = 0 THEN 0
		ELSE SUM(t.sales_dollar_amount) / SUM(gt.sales_dollar_amount) * 100 
	END AS sales_dist,
	SUM(t.customer_count) AS customer_count,
	CASE
		WHEN SUM(gt.customer_count) = 0 THEN 0 
		ELSE CONVERT(NUMERIC(18,2), SUM(t.customer_count)) / CONVERT(NUMERIC(18,2), SUM(gt.customer_count)) * 100 
	END AS customer_dist,
	SUM(t.item_count) AS item_count,
	CASE
		WHEN SUM(gt.item_count) = 0 THEN 0
		ELSE CONVERT(NUMERIC(18,2), SUM(t.item_count)) / CONVERT(NUMERIC(18,2), SUM(gt.item_count)) * 100 
	END AS item_dist
FROM
	#temp t
INNER JOIN #group_totals gt ON
	gt.store_key = t.store_key


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    PROCEDURE [dbo].[GetPtdTotalsBySubdepartmentMulti]
	@salesWeek INT,
	@salesYear INT,
	@dayOfWeekNumMax INT,
	@subdepartmentKey SMALLINT,
	@storeNumber INT = NULL,
	@sameStoresDateKey INT = NULL
AS


DECLARE @Period VARCHAR(10)
DECLARE @absWeek INT
DECLARE @absDay INT
DECLARE @cutoffDate DATETIME
DECLARE @firstDateInPeriod DATETIME
DECLARE @dayInPeriod INT
EXEC GetPtdDates @salesWeek, @salesYear, @dayOfWeekNumMax, @Period OUTPUT, @absWeek OUTPUT, @absDay OUTPUT, @cutoffDate OUTPUT, @firstDateInPeriod OUTPUT, @dayInPeriod OUTPUT


DECLARE @startDate INT
DECLARE @endDate INT

-- 104 weeks ago
SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek-52-52 AND day_in_sales_week = 1
SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInPeriod-1
EXEC GetSubdepartmentSalesByDateRangeRollup @startDate, @endDate, @subdepartmentKey, @storeNumber, @sameStoresDateKey

-- 52 weeks ago
SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek-52 AND day_in_sales_week = 1
SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInPeriod-1
EXEC GetSubdepartmentSalesByDateRangeRollup @startDate, @endDate, @subdepartmentKey, @storeNumber, @sameStoresDateKey

-- current period
SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek AND day_in_sales_week = 1
SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInPeriod-1
EXEC GetSubdepartmentSalesByDateRangeRollup @startDate, @endDate, @subdepartmentKey, @storeNumber, @sameStoresDateKey


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    PROCEDURE [dbo].[GetQtdDates]
	@salesWeek INT, 
	@salesYear INT, 
	@dayOfWeekNumMax INT , 
	@quarter varchar(10) OUTPUT, 
	@absWeek INT OUTPUT, 
	@absDay INT OUTPUT, 
	@cutoffDate DATETIME OUTPUT, 
	@firstDateInQuarter DATETIME OUTPUT, 
	@dayInQuarter INT OUTPUT
AS

-- find fiscal quarter for @salesWeek, @salesYear 
SELECT DISTINCT @quarter = sales_quarter, @absWeek = absolute_week from date_dim where sales_year = @salesYear AND sales_week = @salesWeek
IF @absWeek IS NULL BEGIN
	RAISERROR('''sales_quarter'' not found for Year: %d Week: %d', 16, 1, @salesYear, @salesWeek)
	RETURN
END


-- find absolute_week for @salesWeek, @salesYear
SELECT @absWeek = absolute_week, @absDay = absolute_day FROM date_dim WHERE sales_year = @salesyear AND  sales_quarter = @quarter AND day_in_sales_quarter = 1

IF @absWeek IS NULL BEGIN
	RAISERROR('''absolute_week'' not found for Year: %d Week: %d', 16, 1, @salesYear, @salesWeek)
	RETURN
END

-- figure out the cutoff date if we're not including the full week
SELECT @cutoffDate = (SELECT TOP 1 calendar_date FROM date_dim WHERE sales_year = @salesYear AND sales_week = @salesWeek AND day_in_sales_week <= @dayOfWeekNumMax ORDER BY date_key DESC)

-- find the first day the quarter
select @firstDateInQuarter = (select top 1 calendar_date from date_dim WHERE sales_year = @salesYear AND sales_quarter = @quarter ORDER BY date_key)

-- calculate how many days of sales to include
SELECT @dayInQuarter = COUNT(*) FROM date_dim WHERE calendar_date between @firstDateInQuarter AND @cutoffDate


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[GetQtdSalesTotalCompanyByGroup]
	@salesYear INT,
	@quarter VARCHAR(10),
	@days INT,
	@groupName CHAR(10), 
	@storeNumber INT = NULL
AS


DECLARE @stores TABLE (store_key INT)
IF @storeNumber IS NULL BEGIN
    INSERT @stores SELECT store_key FROM store_dim
END ELSE BEGIN
    INSERT @stores SELECT @storeNumber
END


DECLARE @startDate INT
DECLARE @endDate INT
SET @startDate = (SELECT TOP 1 date_key FROM date_dim WHERE 
	sales_year = @salesYear 
	AND sales_quarter = @quarter
ORDER BY
	date_key)

SET @endDate = (SELECT TOP 1 date_key FROM date_dim WHERE
	sales_year = @salesYear
	AND sales_quarter = @quarter
	AND day_in_sales_quarter = @days
ORDER BY
	date_key DESC)

SET NOCOUNT ON 
SELECT
    ISNULL(SUM(sales_dollar_amount),0) AS sales_dollar_amount,
     0 AS food_customer_count,
     0 AS food_item_count,
     0 AS rx_customer_count,
     0 AS rx_item_count,
     0 AS store_customer_count,
     0 AS store_item_count,
	 0 AS misc_customer_count,
	 0 AS misc_item_count,
	 @startDate AS startDate,
	 @endDate AS endDate
INTO #temp
FROM daily_group_sales dgs 
INNER JOIN @stores s ON
	s.store_key = dgs.store_key
INNER JOIN date_dim da ON
	da.date_key = dgs.tlog_date_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND dgs.major_grouping = @groupName

UPDATE #temp SET
    #temp.store_customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_total_store_counts dtsc 
		INNER JOIN @stores s on dtsc.store_key = s.store_key 
		INNER JOIN date_dim da ON da.date_key = dtsc.tlog_date_key
		WHERE da.date_key BETWEEN @startDate AND @endDate ),0),
    #temp.store_item_count = ISNULL((SELECT SUM(item_count) FROM daily_total_store_counts dtsc 
		INNER JOIN @stores s on dtsc.store_key = s.store_key 
		INNER JOIN date_dim da ON da.date_key = dtsc.tlog_date_key
		WHERE da.date_key BETWEEN @startDate AND @endDate), 0)

UPDATE #temp SET
    #temp.food_customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc 
		INNER JOIN @stores s on dgc.store_key = s.store_key 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = 'Food'),0),
    #temp.food_item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
		INNER JOIN @stores s on dgc.store_key = s.store_key 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE 
			da.date_key BETWEEN @startDate AND @endDate  
			AND dgc.major_grouping = 'Food'), 0)

UPDATE #temp SET
    #temp.rx_customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc 
		INNER JOIN @stores s on dgc.store_key = s.store_key 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE da.date_key BETWEEN @startDate AND @endDate  AND dgc.major_grouping = 'Rx'),0),
    #temp.rx_item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		INNER JOIN @stores s on dgc.store_key = s.store_key 
		WHERE da.date_key BETWEEN @startDate AND @endDate  AND dgc.major_grouping = 'Rx'), 0)

UPDATE #temp SET
    #temp.misc_customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc 
		INNER JOIN @stores s on dgc.store_key = s.store_key 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE da.date_key BETWEEN @startDate AND @endDate  AND dgc.major_grouping = 'Misc'),0),
    #temp.misc_item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		INNER JOIN @stores s on dgc.store_key = s.store_key 
		WHERE da.date_key BETWEEN @startDate AND @endDate  AND dgc.major_grouping = 'Misc'), 0)

SET NOCOUNT OFF
SELECT * FROM #temp


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE         PROCEDURE [dbo].[GetQtdSalesTotalCompanyByGroupMulti]
	@salesWeek INT,
	@salesYear INT,
	@dayOfWeekNumMax INT,
	@groupName VARCHAR(255), 
	@storeNumber INT = NULL,
	@sameStoresDateKey INT = NULL
AS


DECLARE @quarter VARCHAR(10)
DECLARE @absWeek INT
DECLARE @absDay INT
DECLARE @cutoffDate DATETIME
DECLARE @firstDateInQuarter DATETIME
DECLARE @dayInQuarter INT
EXEC GetQtdDates @salesWeek, @salesYear, @dayOfWeekNumMax, @quarter OUTPUT, @absWeek OUTPUT, @absDay OUTPUT, @cutoffDate OUTPUT, @firstDateInQuarter OUTPUT, @dayInQuarter OUTPUT


-- for 1 & 2 years ago, don't use the fiscal calendar for those years.  
-- instead, take '@dayInQuarter' days, starting from the 52 & 104 weeks, 
-- backing up from @salesWeek and @salesYear
DECLARE @startDate INT
DECLARE @endDate INT

-- 104 weeks ago
SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek-52-52 AND day_in_sales_week = 1
SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInQuarter-1
EXEC GetGroupSalesByDateRange @startDate, @endDate, @groupName, @storeNumber, @sameStoresDateKey

-- 52 weeks ago
SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek-52 AND day_in_sales_week = 1
SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInQuarter-1
EXEC GetGroupSalesByDateRange @startDate, @endDate, @groupName, @storeNumber, @sameStoresDateKey

-- current period
SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek AND day_in_sales_week = 1
SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInQuarter-1
EXEC GetGroupSalesByDateRange @startDate, @endDate, @groupName, @storeNumber, @sameStoresDateKey


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROCEDURE [dbo].[GetQtdTotalsByDepartment]
	@salesWeek INT,
	@salesYear INT,
	@dayOfWeekNumMax INT,
	@departmentKey SMALLINT,
	@storeNumber INT = NULL,
	@sameStoresDateKey INT = NULL
AS

DECLARE @quarter VARCHAR(10)
DECLARE @absWeek INT
DECLARE @absDay INT
DECLARE @cutoffDate DATETIME
DECLARE @firstDateInQuarter DATETIME
DECLARE @dayInQuarter INT
EXEC GetQtdDates @salesWeek, @salesYear, @dayOfWeekNumMax, @quarter OUTPUT, @absWeek OUTPUT, @absDay OUTPUT, @cutoffDate OUTPUT, @firstDateInQuarter OUTPUT, @dayInQuarter OUTPUT

DECLARE @startDate INT
DECLARE @endDate INT
SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek AND day_in_sales_week = 1
SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInQuarter-1

-- figure what stores to report on
DECLARE @stores TABLE (store_key INT)
IF @storeNumber IS NULL BEGIN
	IF @sameStoresDateKey = NULL OR @sameStoresDateKey = 0 BEGIN
	    INSERT @stores SELECT store_key FROM store_dim
	END ELSE BEGIN
	    INSERT @stores SELECT store_key FROM store_dim WHERE opening_date_key <= @sameStoresDateKey
	END
END ELSE BEGIN
    INSERT @stores SELECT @storeNumber
END


SET NOCOUNT ON 
-- get qtd values for department
SELECT
	dss.store_key,
    ISNULL(SUM(sales_dollar_amount),0.00) AS sales_dollar_amount,
    0 AS customer_count,
    0 AS item_count,
	@startDate AS startDate,
	@endDate AS endDate
INTO #temp
FROM daily_subdepartment_sales dss
INNER JOIN @stores s ON
	s.store_key = dss.store_key
INNER JOIN date_dim da ON
	da.date_key = dss.tlog_date_key
INNER JOIN subdepartment_dim sd ON
	sd.subdepartment_key = dss.subdepartment_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND sd.department_key = @departmentKey
GROUP BY
	dss.store_key

UPDATE #temp SET
    #temp.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_department_sales dds 
		INNER JOIN date_dim da ON da.date_key = dds.tlog_date_key
		WHERE dds.store_key = #temp.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dds.department_key = @departmentKey), 0),
    #temp.item_count = ISNULL((SELECT SUM(item_count) FROM daily_department_sales dds 
		INNER JOIN date_dim da ON da.date_key = dds.tlog_date_key
		WHERE dds.store_key = #temp.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dds.department_key = @departmentKey), 0)

-- find group for department
DECLARE @majorGrouping VARCHAR(255)
SELECT @majorGrouping = d.major_grouping FROM department_dim d WHERE department_key = @departmentKey

-- get sales for group
SELECT
	dgs.store_key,
    ISNULL(SUM(sales_dollar_amount),0.00) AS sales_dollar_amount,
    0 AS customer_count,
    0 AS item_count
INTO #group_totals
FROM daily_group_sales dgs 
INNER JOIN @stores s ON
	s.store_key = dgs.store_key
INNER JOIN date_dim da ON
	da.date_key = dgs.tlog_date_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND dgs.major_grouping = @majorGrouping
GROUP BY
	dgs.store_key

-- get counts for group
UPDATE #group_totals SET
    #group_totals.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE dgc.store_key = #group_totals.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping),0),
    #group_totals.item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE dgc.store_key = #group_totals.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping), 0)
	
SET NOCOUNT OFF
SELECT 
	t.store_key,
	t.sales_dollar_amount,
	CASE
		WHEN gt.sales_dollar_amount = 0 THEN 0 
		ELSE t.sales_dollar_amount / gt.sales_dollar_amount * 100 
	END AS sales_dist,
	t.customer_count,
	CASE
		WHEN gt.customer_count=0 THEN 0 
		ELSE CONVERT(NUMERIC(18,2), t.customer_count) / CONVERT(NUMERIC(18,2), gt.customer_count) * 100 
	END AS customer_dist,
	t.item_count,
	CASE
		WHEN gt.item_count=0 THEN 0
		ELSE CONVERT(NUMERIC(18,2), t.item_count) / CONVERT(NUMERIC(18,2), gt.item_count) * 100 
	END AS item_dist
FROM
	#temp t 
INNER JOIN #group_totals gt ON
	gt.store_key = t.store_key


SELECT
	SUM(t.sales_dollar_amount) AS sales_dollar_amount,
	CASE
		WHEN SUM(gt.sales_dollar_amount) = 0 THEN 0
		ELSE SUM(t.sales_dollar_amount) / SUM(gt.sales_dollar_amount) * 100 
	END AS sales_dist,
	SUM(t.customer_count) AS customer_count,
	CASE
		WHEN SUM(gt.customer_count) = 0 THEN 0
		ELSE (CONVERT(NUMERIC(18,2), SUM(t.customer_count)) / CONVERT(NUMERIC(18,2), SUM(gt.customer_count))) * 100 
	END AS customer_dist,
	SUM(t.item_count) AS item_count,
	CASE
		WHEN SUM(gt.item_count) = 0 THEN 0
		ELSE (CONVERT(NUMERIC(18,2), SUM(t.item_count)) / CONVERT(NUMERIC(18,2), SUM(gt.item_count))) * 100 
	END AS item_dist
FROM
	#temp t
INNER JOIN #group_totals gt ON
	gt.store_key = t.store_key


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    PROCEDURE [dbo].[GetQtdTotalsByDepartmentMulti]
	@salesWeek INT,
	@salesYear INT,
	@dayOfWeekNumMax INT,
	@departmentKey SMALLINT,
	@storeNumber INT = NULL,
	@sameStoresDateKey INT = NULL
AS

DECLARE @quarter VARCHAR(10)
DECLARE @absWeek INT
DECLARE @absDay INT
DECLARE @cutoffDate DATETIME
DECLARE @firstDateInQuarter DATETIME
DECLARE @dayInQuarter INT
EXEC GetQtdDates @salesWeek, @salesYear, @dayOfWeekNumMax, @quarter OUTPUT, @absWeek OUTPUT, @absDay OUTPUT, @cutoffDate OUTPUT, @firstDateInQuarter OUTPUT, @dayInQuarter OUTPUT


DECLARE @startDate INT
DECLARE @endDate INT

-- 104 weeks ago
SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek-52-52 AND day_in_sales_week = 1
SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInQuarter-1
EXEC GetDepartmentSalesByDateRangeRollup @startDate, @endDate, @departmentKey, @storeNumber, @sameStoresDateKey

-- 52 weeks ago
SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek-52 AND day_in_sales_week = 1
SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInQuarter-1
EXEC GetDepartmentSalesByDateRangeRollup @startDate, @endDate, @departmentKey, @storeNumber, @sameStoresDateKey

-- current period
SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek AND day_in_sales_week = 1
SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInQuarter-1
EXEC GetDepartmentSalesByDateRangeRollup @startDate, @endDate, @departmentKey, @storeNumber, @sameStoresDateKey


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetQtdTotalsByDepartmentRollup]
	@salesYear INT,
	@quarter VARCHAR(10),
	@days INT,
	@departmentKey SMALLINT,
	@storeNumber INT = NULL
AS

-- figure what stores to report on
DECLARE @stores TABLE (store_key INT)
IF @storeNumber IS NULL BEGIN
    INSERT @stores SELECT store_key FROM store_dim
END ELSE BEGIN
    INSERT @stores SELECT @storeNumber
END

-- calc dates: start of qtr & 
DECLARE @startDate INT
DECLARE @endDate INT
SET @startDate = (SELECT TOP 1 date_key FROM date_dim WHERE 
	sales_year = @salesYear 
	AND sales_quarter = @quarter
ORDER BY
	date_key)

SET @endDate = (SELECT TOP 1 date_key FROM date_dim WHERE
	sales_year = @salesYear
	AND sales_quarter = @quarter
	AND day_in_sales_quarter = @days
ORDER BY
	date_key DESC)

-- get qtd values for department
SET NOCOUNT ON 
SELECT
    ISNULL(SUM(sales_dollar_amount),0.00) AS sales_dollar_amount,
    0 AS customer_count,
    0 AS item_count,
	@startDate AS startDate,
	@endDate AS endDate
INTO #temp
FROM daily_subdepartment_sales dss
INNER JOIN @stores s ON
	s.store_key = dss.store_key
INNER JOIN date_dim da ON
	da.date_key = dss.tlog_date_key
INNER JOIN subdepartment_dim sd ON
	sd.subdepartment_key = dss.subdepartment_key
INNER JOIN department_dim dd ON
	dd.department_key = sd.department_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND dd.department_key = @departmentKey

UPDATE #temp SET
    #temp.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_department_sales dds
		INNER JOIN date_dim da ON da.date_key = dds.tlog_date_key
		INNER JOIN @stores s ON s.store_key = dds.store_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dds.department_key = @departmentKey), 0),
    #temp.item_count = ISNULL((SELECT SUM(item_count) FROM daily_department_sales dds 
		INNER JOIN date_dim da ON da.date_key = dds.tlog_date_key
		INNER JOIN @stores s ON s.store_key = dds.store_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dds.department_key = @departmentKey), 0)


-- find group for department
DECLARE @majorGrouping VARCHAR(255)
SELECT 
	@majorGrouping = d.major_grouping 
FROM 
	department_dim d 
WHERE 
	d.department_key = @departmentKey

-- get sales for group
SELECT
    ISNULL(SUM(sales_dollar_amount),0.00) AS sales_dollar_amount,
    0 AS customer_count,
    0 AS item_count
INTO #group_totals
FROM daily_group_sales dgs 
INNER JOIN @stores s ON
	s.store_key = dgs.store_key
INNER JOIN date_dim da ON
	da.date_key = dgs.tlog_date_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND dgs.major_grouping = @majorGrouping

-- get counts for group
UPDATE #group_totals SET
    #group_totals.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		INNER JOIN @stores s ON s.store_key = dgc.store_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping),0),
    #group_totals.item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		INNER JOIN @stores s ON s.store_key = dgc.store_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping), 0)

SET NOCOUNT OFF
SELECT 
	t.sales_dollar_amount,
	CASE 
		WHEN gt.sales_dollar_amount = 0 THEN 0
		ELSE t.sales_dollar_amount / gt.sales_dollar_amount * 100 
	END AS sales_dist,
	t.customer_count,
	CASE 
		WHEN gt.customer_count = 0 THEN 0
		ELSE CONVERT(NUMERIC(18,2), t.customer_count) / CONVERT(NUMERIC(18,2), gt.customer_count) * 100 
	END AS customer_dist,
	t.item_count,
	CASE
		WHEN gt.item_count = 0 THEN 0
		ELSE CONVERT(NUMERIC(18,2), t.item_count) / CONVERT(NUMERIC(18,2), gt.item_count) * 100 
	END AS item_dist,
	@startDate AS start_date_key,
	@endDate AS end_date_key
FROM
	#temp t 
CROSS JOIN #group_totals gt


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROCEDURE [dbo].[GetQtdTotalsByGroup]
	@salesWeek INT,
	@salesYear INT,
	@dayOfWeekNumMax INT,
	@majorGrouping VARCHAR(255),
	@storeNumber INT = NULL,
	@sameStoresDateKey INT = NULL
AS


DECLARE @quarter VARCHAR(10)
DECLARE @absWeek INT
DECLARE @absDay INT
DECLARE @cutoffDate DATETIME
DECLARE @firstDateInQuarter DATETIME
DECLARE @dayInQuarter INT
EXEC GetQtdDates @salesWeek, @salesYear, @dayOfWeekNumMax, @quarter OUTPUT, @absWeek OUTPUT, @absDay OUTPUT, @cutoffDate OUTPUT, @firstDateInQuarter OUTPUT, @dayInQuarter OUTPUT

DECLARE @startDate INT
DECLARE @endDate INT
SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek AND day_in_sales_week = 1
SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInQuarter-1

-- figure what stores to report on
DECLARE @stores TABLE (store_key INT)
IF @storeNumber IS NULL BEGIN
	IF @sameStoresDateKey = NULL OR @sameStoresDateKey = 0 BEGIN
	    INSERT @stores SELECT store_key FROM store_dim
	END ELSE BEGIN
	    INSERT @stores SELECT store_key FROM store_dim WHERE opening_date_key <= @sameStoresDateKey
	END
END ELSE BEGIN
    INSERT @stores SELECT @storeNumber
END


SET NOCOUNT ON 
SELECT
	dgs.store_key,
    ISNULL(SUM(sales_dollar_amount),0) AS sales_dollar_amount,
	100 AS sales_dist,
    0 AS customer_count,
	100 AS customer_dist,
    0 AS item_count,
	100 AS  item_dist,
	@startDate AS startDate,
	@endDate AS endDate
INTO #temp
FROM daily_group_sales dgs 
INNER JOIN @stores s ON
	s.store_key = dgs.store_key
INNER JOIN date_dim da ON
	da.date_key = dgs.tlog_date_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND dgs.major_grouping = @majorGrouping
GROUP BY
	dgs.store_key

UPDATE #temp SET
    #temp.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE dgc.store_key = #temp.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping),0),
    #temp.item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE dgc.store_key = #temp.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping), 0)


SET NOCOUNT OFF

-- 1 record for every store
SELECT * FROM #temp

-- totals
SELECT
	SUM(sales_dollar_amount) AS sales_dollar_amount,
	100.00 AS sales_dist,
	SUM(customer_count) AS customer_count,
	100.00 AS customer_dist,
	SUM(item_count) AS item_count,
	100.00 as item_dist
FROM
	#temp


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    PROCEDURE [dbo].[GetQtdTotalsBySubdepartment]
	@salesWeek INT,
	@salesYear INT,
	@dayOfWeekNumMax INT,
	@subdepartmentKey SMALLINT,
	@storeNumber INT = NULL,
	@sameStoresDateKey INT = NULL
AS


DECLARE @quarter VARCHAR(10)
DECLARE @absWeek INT
DECLARE @absDay INT
DECLARE @cutoffDate DATETIME
DECLARE @firstDateInQuarter DATETIME
DECLARE @dayInQuarter INT
EXEC GetQtdDates @salesWeek, @salesYear, @dayOfWeekNumMax, @quarter OUTPUT, @absWeek OUTPUT, @absDay OUTPUT, @cutoffDate OUTPUT, @firstDateInQuarter OUTPUT, @dayInQuarter OUTPUT

DECLARE @startDate INT
DECLARE @endDate INT
SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek AND day_in_sales_week = 1
SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInQuarter-1

-- figure what stores to report on
DECLARE @stores TABLE (store_key INT)
IF @storeNumber IS NULL BEGIN
	IF @sameStoresDateKey = NULL OR @sameStoresDateKey = 0 BEGIN
	    INSERT @stores SELECT store_key FROM store_dim
	END ELSE BEGIN
	    INSERT @stores SELECT store_key FROM store_dim WHERE opening_date_key <= @sameStoresDateKey
	END
END ELSE BEGIN
    INSERT @stores SELECT @storeNumber
END


-- get qtd values for subdepartment
SET NOCOUNT ON 
SELECT
	dss.store_key,
    ISNULL(SUM(sales_dollar_amount),0.00) AS sales_dollar_amount,
    0 AS customer_count,
    0 AS item_count,
	@startDate AS startDate,
	@endDate AS endDate
INTO #temp
FROM daily_subdepartment_sales dss
INNER JOIN @stores s ON
	s.store_key = dss.store_key
INNER JOIN date_dim da ON
	da.date_key = dss.tlog_date_key
INNER JOIN subdepartment_dim sd ON
	sd.subdepartment_key = dss.subdepartment_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND sd.subdepartment_key = @subdepartmentKey
GROUP BY
	dss.store_key

UPDATE #temp SET
    #temp.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_subdepartment_sales dss 
		INNER JOIN date_dim da ON da.date_key = dss.tlog_date_key
		WHERE dss.store_key = #temp.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dss.subdepartment_key = @subdepartmentKey), 0),
    #temp.item_count = ISNULL((SELECT SUM(item_count) FROM daily_subdepartment_sales dss 
		INNER JOIN date_dim da ON da.date_key = dss.tlog_date_key
		WHERE dss.store_key = #temp.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dss.subdepartment_key = @subdepartmentKey), 0)

-- find group for department
DECLARE @majorGrouping VARCHAR(255)
SELECT 
	@majorGrouping = d.major_grouping 
FROM 
	department_dim d 
INNER JOIN subdepartment_dim sd ON
	sd.department_key = d.department_key
WHERE 
	sd.subdepartment_key = @subdepartmentKey

-- get sales for group
SELECT
	dgs.store_key,
    ISNULL(SUM(sales_dollar_amount),0.00) AS sales_dollar_amount,
    0 AS customer_count,
    0 AS item_count
INTO #group_totals
FROM daily_group_sales dgs 
INNER JOIN @stores s ON
	s.store_key = dgs.store_key
INNER JOIN date_dim da ON
	da.date_key = dgs.tlog_date_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND dgs.major_grouping = @majorGrouping
GROUP BY
	dgs.store_key

-- get counts for group
UPDATE #group_totals SET
    #group_totals.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE dgc.store_key = #group_totals.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping),0),
    #group_totals.item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE dgc.store_key = #group_totals.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping), 0)
	
SET NOCOUNT OFF
SELECT 
	t.store_key,
	t.sales_dollar_amount,
	CASE 
		WHEN gt.sales_dollar_amount = 0 THEN 0
		ELSE t.sales_dollar_amount / gt.sales_dollar_amount * 100 
	END AS sales_dist,
	t.customer_count,
	CASE 
		WHEN gt.customer_count = 0 THEN 0
		ELSE CONVERT(NUMERIC(18,2), t.customer_count) / CONVERT(NUMERIC(18,2), gt.customer_count) * 100 
	END AS customer_dist,
	t.item_count,
	CASE
		WHEN gt.item_count = 0 THEN 0
		ELSE CONVERT(NUMERIC(18,2), t.item_count) / CONVERT(NUMERIC(18,2), gt.item_count) * 100 
	END AS item_dist
FROM
	#temp t 
INNER JOIN #group_totals gt ON
	gt.store_key = t.store_key

SELECT
	SUM(t.sales_dollar_amount) AS sales_dollar_amount,
	CASE
		WHEN SUM(gt.sales_dollar_amount) = 0 THEN 0
		ELSE SUM(t.sales_dollar_amount) / SUM(gt.sales_dollar_amount) * 100 
	END AS sales_dist,
	SUM(t.customer_count) AS customer_count,
	CASE
		WHEN SUM(gt.customer_count) = 0 THEN 0 
		ELSE CONVERT(NUMERIC(18,2), SUM(t.customer_count)) / CONVERT(NUMERIC(18,2), SUM(gt.customer_count)) * 100 
	END AS customer_dist,
	SUM(t.item_count) AS item_count,
	CASE
		WHEN SUM(gt.item_count) = 0 THEN 0
		ELSE CONVERT(NUMERIC(18,2), SUM(t.item_count)) / CONVERT(NUMERIC(18,2), SUM(gt.item_count)) * 100 
	END AS item_dist
FROM
	#temp t
INNER JOIN #group_totals gt ON
	gt.store_key = t.store_key


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    PROCEDURE [dbo].[GetQtdTotalsBySubdepartmentMulti]
	@salesWeek INT,
	@salesYear INT,
	@dayOfWeekNumMax INT,
	@subdepartmentKey SMALLINT,
	@storeNumber INT = NULL,
	@sameStoresDateKey INT = NULL
AS


DECLARE @quarter VARCHAR(10)
DECLARE @absWeek INT
DECLARE @absDay INT
DECLARE @cutoffDate DATETIME
DECLARE @firstDateInQuarter DATETIME
DECLARE @dayInQuarter INT
EXEC GetQtdDates @salesWeek, @salesYear, @dayOfWeekNumMax, @quarter OUTPUT, @absWeek OUTPUT, @absDay OUTPUT, @cutoffDate OUTPUT, @firstDateInQuarter OUTPUT, @dayInQuarter OUTPUT


DECLARE @startDate INT
DECLARE @endDate INT

-- 104 weeks ago
SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek-52-52 AND day_in_sales_week = 1
SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInQuarter-1
EXEC GetSubdepartmentSalesByDateRangeRollup @startDate, @endDate, @subdepartmentKey, @storeNumber,@sameStoresDateKey

-- 52 weeks ago
SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek-52 AND day_in_sales_week = 1
SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInQuarter-1
EXEC GetSubdepartmentSalesByDateRangeRollup @startDate, @endDate, @subdepartmentKey, @storeNumber, @sameStoresDateKey

-- current period
SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek AND day_in_sales_week = 1
SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInQuarter-1
EXEC GetSubdepartmentSalesByDateRangeRollup @startDate, @endDate, @subdepartmentKey, @storeNumber, @sameStoresDateKey


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetQtdTotalsBySubdepartmentRollup]
	@salesYear INT,
	@quarter VARCHAR(10),
	@days INT,
	@subdepartmentKey SMALLINT,
	@storeNumber INT = NULL
AS

-- figure what stores to report on
DECLARE @stores TABLE (store_key INT)
IF @storeNumber IS NULL BEGIN
    INSERT @stores SELECT store_key FROM store_dim
END ELSE BEGIN
    INSERT @stores SELECT @storeNumber
END

-- calc dates: start of qtr & 
DECLARE @startDate INT
DECLARE @endDate INT
SET @startDate = (SELECT TOP 1 date_key FROM date_dim WHERE 
	sales_year = @salesYear 
	AND sales_quarter = @quarter
ORDER BY
	date_key)

SET @endDate = (SELECT TOP 1 date_key FROM date_dim WHERE
	sales_year = @salesYear
	AND sales_quarter = @quarter
	AND day_in_sales_quarter = @days
ORDER BY
	date_key DESC)

-- get qtd values for subdepartment
SET NOCOUNT ON 
SELECT
    ISNULL(SUM(sales_dollar_amount),0.00) AS sales_dollar_amount,
    0 AS customer_count,
    0 AS item_count,
	@startDate AS startDate,
	@endDate AS endDate
INTO #temp
FROM daily_subdepartment_sales dss
INNER JOIN @stores s ON
	s.store_key = dss.store_key
INNER JOIN date_dim da ON
	da.date_key = dss.tlog_date_key
INNER JOIN subdepartment_dim sd ON
	sd.subdepartment_key = dss.subdepartment_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND sd.subdepartment_key = @subdepartmentKey

UPDATE #temp SET
    #temp.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_subdepartment_sales dss 
		INNER JOIN date_dim da ON da.date_key = dss.tlog_date_key
		INNER JOIN @stores s ON s.store_key = dss.store_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dss.subdepartment_key = @subdepartmentKey), 0),
    #temp.item_count = ISNULL((SELECT SUM(item_count) FROM daily_subdepartment_sales dss 
		INNER JOIN date_dim da ON da.date_key = dss.tlog_date_key
		INNER JOIN @stores s ON s.store_key = dss.store_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dss.subdepartment_key = @subdepartmentKey), 0)


-- find group for department
DECLARE @majorGrouping VARCHAR(255)
SELECT 
	@majorGrouping = d.major_grouping 
FROM 
	department_dim d 
INNER JOIN subdepartment_dim sd ON
	sd.department_key = d.department_key
WHERE 
	sd.subdepartment_key = @subdepartmentKey

-- get sales for group
SELECT
    ISNULL(SUM(sales_dollar_amount),0.00) AS sales_dollar_amount,
    0 AS customer_count,
    0 AS item_count
INTO #group_totals
FROM daily_group_sales dgs 
INNER JOIN @stores s ON
	s.store_key = dgs.store_key
INNER JOIN date_dim da ON
	da.date_key = dgs.tlog_date_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND dgs.major_grouping = @majorGrouping

-- get counts for group
UPDATE #group_totals SET
    #group_totals.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		INNER JOIN @stores s ON s.store_key = dgc.store_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping),0),
    #group_totals.item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		INNER JOIN @stores s ON s.store_key = dgc.store_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping), 0)

SET NOCOUNT OFF
SELECT 
	t.sales_dollar_amount,
	CASE 
		WHEN gt.sales_dollar_amount = 0 THEN 0
		ELSE t.sales_dollar_amount / gt.sales_dollar_amount * 100 
	END AS sales_dist,
	t.customer_count,
	CASE 
		WHEN gt.customer_count = 0 THEN 0
		ELSE CONVERT(NUMERIC(18,2), t.customer_count) / CONVERT(NUMERIC(18,2), gt.customer_count) * 100 
	END AS customer_dist,
	t.item_count,
	CASE
		WHEN gt.item_count = 0 THEN 0
		ELSE CONVERT(NUMERIC(18,2), t.item_count) / CONVERT(NUMERIC(18,2), gt.item_count) * 100 
	END AS item_dist,
	@startDate AS start_date_key,
	@endDate AS end_date_key
FROM
	#temp t 
CROSS JOIN #group_totals gt


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE         PROCEDURE [dbo].[GetSalesTotalCompanyByGroup]
	@salesWeek INT,
	@salesYear INT,
	@groupName VARCHAR(255), 
	@storeNumber INT = NULL,
	@sameStoresDateKey INT = NULL
AS

-- find the absolute_week for the passed @salesWeek and @salesYear
DECLARE @year INT	
DECLARE @week INT
DECLARE @absWeek INT
SELECT @absWeek = absolute_week FROM date_dim WHERE sales_week = @salesWeek AND sales_year = @salesyear

-- 104 weeks ago
SELECT @year = sales_year, @week = sales_week FROM date_dim WHERE absolute_week = @absWeek-52-52
EXEC GetSalesTotalCompanyByGroupYear @week, @year, @groupName, @storeNumber, @sameStoresDateKey

-- 52 weeks ago
SELECT @year = sales_year, @week = sales_week FROM date_dim WHERE absolute_week = @absWeek-52
EXEC GetSalesTotalCompanyByGroupYear @week, @year, @groupName, @storeNumber, @sameStoresDateKey

-- specified week
EXEC GetSalesTotalCompanyByGroupYear @salesWeek, @salesYear, @groupName, @storeNumber, @sameStoresDateKey


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE      PROCEDURE [dbo].[GetSalesTotalCompanyByGroupYear]
	@salesWeek INT,
	@salesYear INT,
	@groupName CHAR(10), 
	@storeNumber INT = NULL,
	@sameStoresDateKey INT = NULL
AS


DECLARE @stores TABLE (store_key INT)
IF @storeNumber IS NULL BEGIN
	IF @sameStoresDateKey IS NULL OR @sameStoresDateKey = 0 BEGIN
	    INSERT @stores SELECT store_key FROM store_dim
	END ELSE BEGIN
	    INSERT @stores SELECT store_key FROM store_dim WHERE opening_date_key  <= @sameStoresDateKey
	END
END ELSE BEGIN
    INSERT @stores SELECT @storeNumber
END


SET NOCOUNT ON 
SELECT
    da.date_key,
    RTRIM(da.day_of_week) + ' ' + RTRIM(da.date_month_text) as date_text,
    ISNULL(SUM(sales_dollar_amount),0) AS sales_dollar_amount,
     0 AS group_customer_count,
     0 AS group_item_count,
--      0 AS group2_customer_count,
--      0 AS group2_item_count,
     0 AS store_customer_count,
     0 AS store_item_count
INTO #temp
FROM daily_subdepartment_sales dss
INNER JOIN @stores s ON
    s.store_key = dss.store_key
INNER JOIN subdepartment_dim sd ON
    sd.subdepartment_key = dss.subdepartment_key
INNER JOIN department_dim d ON
    d.department_key = sd.department_key
    AND d.major_grouping = @groupName
RIGHT OUTER JOIN date_dim da ON
    da.date_key = dss.tlog_date_key
WHERE
    da.sales_week = @salesWeek
    and da.sales_year = @salesYear
GROUP BY
    da.date_key,
    RTRIM(da.day_of_week) + ' ' + RTRIM(da.date_month_text)

UPDATE #temp SET
    #temp.store_customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_total_store_counts dtsc INNER JOIN @stores s on dtsc.store_key = s.store_key WHERE dtsc.tlog_date_key = #temp.date_key),0),
    #temp.store_item_count = ISNULL((SELECT SUM(item_count) FROM daily_total_store_counts dtsc INNER JOIN @stores s on dtsc.store_key = s.store_key WHERE dtsc.tlog_date_key = #temp.date_key), 0)

-- UPDATE #temp SET
--     #temp.food_customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc INNER JOIN @stores s on dgc.store_key = s.store_key WHERE dgc.tlog_date_key = #temp.date_key AND dgc.major_grouping = 'Food'),0),
--     #temp.food_item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc INNER JOIN @stores s on dgc.store_key = s.store_key WHERE dgc.tlog_date_key = #temp.date_key AND dgc.major_grouping = 'Food'), 0)
-- 
-- UPDATE #temp SET
--     #temp.rx_customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc INNER JOIN @stores s on dgc.store_key = s.store_key WHERE dgc.tlog_date_key = #temp.date_key AND dgc.major_grouping = 'Rx'),0),
--     #temp.rx_item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc INNER JOIN @stores s on dgc.store_key = s.store_key WHERE dgc.tlog_date_key = #temp.date_key AND dgc.major_grouping = 'Rx'), 0)

UPDATE #temp SET
    #temp.group_customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc INNER JOIN @stores s on dgc.store_key = s.store_key WHERE dgc.tlog_date_key = #temp.date_key AND dgc.major_grouping = @groupName),0),
    #temp.group_item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc INNER JOIN @stores s on dgc.store_key = s.store_key WHERE dgc.tlog_date_key = #temp.date_key AND dgc.major_grouping = @groupName), 0)

SET NOCOUNT OFF
SELECT * FROM #temp ORDER BY date_key


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[GetSubdepartmentSalesByDateRangeRollup]
	@startDate INT,
	@endDate INT,
	@subdepartmentKey SMALLINT,
	@storeNumber INT = NULL,
	@sameStoresDateKey INT = NULL
AS

-- figure what stores to report on
DECLARE @stores TABLE (store_key INT)
IF @storeNumber IS NULL BEGIN
	IF @sameStoresDateKey = NULL OR @sameStoresDateKey = 0 BEGIN
	    INSERT @stores SELECT store_key FROM store_dim
	END ELSE BEGIN
	    INSERT @stores SELECT store_key FROM store_dim WHERE opening_date_key <= @sameStoresDateKey
	END
END ELSE BEGIN
    INSERT @stores SELECT @storeNumber
END

-- get qtd values for subdepartment
SET NOCOUNT ON 
SELECT
    ISNULL(SUM(sales_dollar_amount),0.00) AS sales_dollar_amount,
    0 AS customer_count,
    0 AS item_count,
	@startDate AS startDate,
	@endDate AS endDate
INTO #temp
FROM daily_subdepartment_sales dss
INNER JOIN @stores s ON
	s.store_key = dss.store_key
INNER JOIN date_dim da ON
	da.date_key = dss.tlog_date_key
INNER JOIN subdepartment_dim sd ON
	sd.subdepartment_key = dss.subdepartment_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND sd.subdepartment_key = @subdepartmentKey

UPDATE #temp SET
    #temp.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_subdepartment_sales dss 
		INNER JOIN date_dim da ON da.date_key = dss.tlog_date_key
		INNER JOIN @stores s ON s.store_key = dss.store_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dss.subdepartment_key = @subdepartmentKey), 0),
    #temp.item_count = ISNULL((SELECT SUM(item_count) FROM daily_subdepartment_sales dss 
		INNER JOIN date_dim da ON da.date_key = dss.tlog_date_key
		INNER JOIN @stores s ON s.store_key = dss.store_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dss.subdepartment_key = @subdepartmentKey), 0)


-- find group for department
DECLARE @majorGrouping VARCHAR(255)
SELECT 
	@majorGrouping = d.major_grouping 
FROM 
	department_dim d 
INNER JOIN subdepartment_dim sd ON
	sd.department_key = d.department_key
WHERE 
	sd.subdepartment_key = @subdepartmentKey

-- get sales for group
SELECT
    ISNULL(SUM(sales_dollar_amount),0.00) AS sales_dollar_amount,
    0 AS customer_count,
    0 AS item_count
INTO #group_totals
FROM daily_group_sales dgs 
INNER JOIN @stores s ON
	s.store_key = dgs.store_key
INNER JOIN date_dim da ON
	da.date_key = dgs.tlog_date_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND dgs.major_grouping = @majorGrouping

-- get counts for group
UPDATE #group_totals SET
    #group_totals.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		INNER JOIN @stores s ON s.store_key = dgc.store_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping),0),
    #group_totals.item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		INNER JOIN @stores s ON s.store_key = dgc.store_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping), 0)

SET NOCOUNT OFF
SELECT 
	t.sales_dollar_amount,
	CASE 
		WHEN gt.sales_dollar_amount = 0 THEN 0
		ELSE t.sales_dollar_amount / gt.sales_dollar_amount * 100 
	END AS sales_dist,
	t.customer_count,
	CASE 
		WHEN gt.customer_count = 0 THEN 0
		ELSE CONVERT(NUMERIC(18,2), t.customer_count) / CONVERT(NUMERIC(18,2), gt.customer_count) * 100 
	END AS customer_dist,
	t.item_count,
	CASE
		WHEN gt.item_count = 0 THEN 0
		ELSE CONVERT(NUMERIC(18,2), t.item_count) / CONVERT(NUMERIC(18,2), gt.item_count) * 100 
	END AS item_dist,
	@startDate AS start_date_key,
	@endDate AS end_date_key
FROM
	#temp t 
CROSS JOIN #group_totals gt


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    PROCEDURE [dbo].[GetWtdSalesTotalCompanyByGroup]
	@salesWeek INT,
	@salesYear INT,
	@daysToInclude INT = 7,
	@groupName CHAR(10), 
	@storeNumber INT = NULL,
	@sameStoresDateKey INT = NULL
AS

SET NOCOUNT ON

-- this allow for totaling some days of a week, for week-to-date (WTD) totals
IF @daysToInclude IS NULL BEGIN
	SELECT @daysToInclude = 7
END

DECLARE @maxDateKey INT
SELECT @maxDateKey = date_key FROM date_dim 
WHERE 
	sales_year = @salesYear 
	AND sales_week = @salesWeek
	AND day_in_sales_week = @daysToInclude

-- one store or all stores?
DECLARE @stores TABLE (store_key INT)
IF @storeNumber IS NULL BEGIN
	IF @sameStoresDateKey IS NULL OR @sameStoresDateKey = 0 BEGIN
	    INSERT @stores SELECT store_key FROM store_dim
	END ELSE BEGIN
	    INSERT @stores SELECT store_key FROM store_dim WHERE opening_date_key <= @sameStoresDateKey
	END
	
END ELSE BEGIN
    INSERT @stores SELECT @storeNumber
END

SELECT
    ISNULL(SUM(sales_dollar_amount),0) AS sales_dollar_amount,
    0 AS customer_count,
    0 AS item_count,
    CONVERT(DECIMAL(18,4),0) AS avg_item_price,
    CONVERT(DECIMAL(18,4),0) AS avg_customer_sale
INTO 
	#temp    
FROM 
	daily_department_sales dds
INNER JOIN @stores s ON
    s.store_key = dds.store_key
INNER JOIN department_dim d ON
    d.department_key = dds.department_key
    AND 
		((d.major_grouping = @groupName) OR (@groupName IS NULL))
RIGHT OUTER JOIN date_dim da ON
    da.date_key = dds.tlog_date_key
WHERE
    da.sales_week = @salesWeek
    AND da.sales_year = @salesYear
    AND dds.department_key <> 0
    AND dds.tlog_date_key <= @maxDateKey

-- pull in customer & item counts
IF @groupName IS NOT NULL BEGIN
	-- get counts at the group level, like 'Food', 'Rx' or 'Misc'
	UPDATE #temp SET
	    #temp.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc INNER JOIN @stores s on dgc.store_key = s.store_key INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key WHERE da.sales_year = @salesYear AND da.sales_week = @salesWeek AND dgc.major_grouping = @groupName AND dgc.tlog_date_key <= @maxDateKey),0),
	    #temp.item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc INNER JOIN @stores s on dgc.store_key = s.store_key INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key WHERE da.sales_year = @salesYear AND da.sales_week = @salesWeek AND dgc.major_grouping = @groupName AND dgc.tlog_date_key <= @maxDateKey), 0)
END ELSE BEGIN
	-- get counts at the total store level, like 'Food', 'Rx' or 'Misc'
	UPDATE #temp SET
	    #temp.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_total_store_counts dtsc INNER JOIN @stores s on dtsc.store_key = s.store_key INNER JOIN date_dim da ON da.date_key = dtsc.tlog_date_key WHERE da.sales_year = @salesYear AND da.sales_week = @salesWeek AND dtsc.tlog_date_key <= @maxDateKey),0),
	    #temp.item_count = ISNULL((SELECT SUM(item_count) FROM daily_total_store_counts dtsc INNER JOIN @stores s on dtsc.store_key = s.store_key INNER JOIN date_dim da ON da.date_key = dtsc.tlog_date_key WHERE da.sales_year = @salesYear AND da.sales_week = @salesWeek AND dtsc.tlog_date_key <= @maxDateKey), 0)
END

-- calculate avg_item_price and avg_customer_sale
UPDATE #temp SET avg_item_price = sales_dollar_amount / item_count WHERE item_count <> 0
UPDATE #temp SET avg_customer_sale = sales_dollar_amount / customer_count WHERE customer_count <> 0

SET NOCOUNT OFF

-- now return the data
SELECT 
	sales_dollar_amount,
	customer_count,
	item_count,
	avg_item_price,
	avg_customer_sale
FROM 
	#temp


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[GetWtdSalesTotalCompanyByGroupMulti]
    @salesWeek INT,
    @salesYear INT,
    @dayOfWeekNumMax INT = 7,
    @groupName CHAR(10),
    @storeNumber INT = NULL,
	@sameStoresDateKey INT = NULL
AS

-- find the absolute_week for the passed @salesWeek and @salesYear
DECLARE @year INT
DECLARE @week INT
DECLARE @absWeek INT
SELECT @absWeek = absolute_week FROM date_dim WHERE sales_week = @salesWeek AND sales_year = @salesyear

-- 104 weeks ago
SELECT @year = sales_year, @week = sales_week FROM date_dim WHERE absolute_week = @absWeek-52-52
EXEC GetWtdSalesTotalCompanyByGroup @week, @year, @dayOfWeekNumMax, @groupName, @storeNumber, @sameStoresDateKey

-- 52 weeks ago
SELECT @year = sales_year, @week = sales_week FROM date_dim WHERE absolute_week = @absWeek-52
EXEC GetWtdSalesTotalCompanyByGroup @week, @year, @dayOfWeekNumMax, @groupName, @storeNumber, @sameStoresDateKey

-- specified week
EXEC GetWtdSalesTotalCompanyByGroup @salesWeek, @salesYear, @dayOfWeekNumMax, @groupName, @storeNumber, @sameStoresDateKey


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    PROCEDURE [dbo].[GetYtdDates] 
	@salesWeek INT, 
	@salesYear INT, 
	@dayOfWeekNumMax INT , 
	@offset INT = 0,
	@startDate INT OUTPUT,
	@endDate INT OUTPUT
AS
	
SET NOCOUNT ON

DECLARE @absWeek INT 
DECLARE @absDay INT 
DECLARE @cutoffDate DATETIME 
DECLARE @firstDateInYear DATETIME 
DECLARE @dayInYear INT 

-- find absolute_week for @salesWeek, @salesYear
SELECT 
	@absWeek = absolute_week, 
	@absDay = absolute_day 
FROM 
	date_dim 
WHERE 
	sales_week = 1 
	AND day_in_sales_week = 1 
	AND sales_year = @salesyear

IF @absWeek IS NULL BEGIN
	RAISERROR('''absolute_week'' not found for Year: %d Week: %d', 16, 1, @salesYear, @salesWeek)
	RETURN
END


DECLARE @tempWeek INT
SET @tempWeek = @salesWeek

-- if week 52 of a 53-week year is requested, bump out the end date 
-- to include the 53rd week
IF @salesWeek = 52 BEGIN
	DECLARE @maxWeekInYear INT
	SELECT @maxWeekInYear = MAX(sales_week) FROM date_dim WHERE sales_year = @salesYear
	IF @maxWeekInYear > @salesWeek BEGIN
		SET @tempWeek = @maxWeekInYear
	END
END 

-- figure out the cutoff date, taking care not to include a full week if @dayOfWeekNumMax is < 7
SELECT @cutoffDate = (SELECT TOP 1 calendar_date FROM date_dim WHERE sales_year = @salesYear AND sales_week = @tempWeek AND day_in_sales_week <= @dayOfWeekNumMax ORDER BY date_key DESC)

-- find the first day the year
select @firstDateInYear = (select top 1 calendar_date from date_dim WHERE sales_year = @salesYear ORDER BY date_key)

-- calculate how many days of sales to include
SELECT @dayInYear = COUNT(*) FROM date_dim WHERE calendar_date between @firstDateInYear AND @cutoffDate

-- calculate startdate and enddate
SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek + @offset AND day_in_sales_week = 1
SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInYear-1


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    PROCEDURE [dbo].[GetYtdSalesTotalCompanyByGroup]
	@salesYear INT,
	@dayInFiscalYearMax INT,
	@groupName CHAR(10), 
	@storeNumber INT = NULL
AS


SET NOCOUNT ON 

DECLARE @stores TABLE (store_key INT)
IF @storeNumber IS NULL BEGIN
    INSERT @stores SELECT store_key FROM store_dim
END ELSE BEGIN
    INSERT @stores SELECT @storeNumber
END


DECLARE @startDate INT
SET @startDate = (
	SELECT 
		date_key 
	FROM 
		date_dim 
	WHERE 
		sales_year = @salesYear 
		AND day_in_sales_year = 1
)

DECLARE @endDate INT
SET @endDate = (
	SELECT TOP 1 
		date_key 
	FROM 
		date_dim 
	WHERE
		sales_year = @salesYear
		AND day_in_sales_year <= @dayInFiscalYearMax
	ORDER BY
		date_key DESC
)


SELECT
    ISNULL(SUM(sales_dollar_amount),0) AS sales_dollar_amount,
     0 AS food_customer_count,
     0 AS food_item_count,
     0 AS rx_customer_count,
     0 AS rx_item_count,
     0 AS misc_customer_count,
	 0 AS misc_item_count,
     0 AS store_customer_count,
     0 AS store_item_count,
	 @startDate AS start_date,
	 @endDate AS end_date
INTO 
	#temp
FROM 
	daily_group_sales dgs 
INNER JOIN @stores s ON
	s.store_key = dgs.store_key
INNER JOIN date_dim da ON
	da.date_key = dgs.tlog_date_key
WHERE
 	da.date_key BETWEEN @startDate AND @endDate
	AND dgs.major_grouping = @groupName

UPDATE #temp SET
    #temp.store_customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_total_store_counts dtsc 
		INNER JOIN @stores s on dtsc.store_key = s.store_key 
		INNER JOIN date_dim da ON da.date_key = dtsc.tlog_date_key
		WHERE da.date_key BETWEEN @startDate AND @endDate),0),
    #temp.store_item_count = ISNULL((SELECT SUM(item_count) FROM daily_total_store_counts dtsc 
		INNER JOIN @stores s on dtsc.store_key = s.store_key 
		INNER JOIN date_dim da ON da.date_key = dtsc.tlog_date_key
		WHERE da.date_key BETWEEN @startDate AND @endDate), 0)

UPDATE #temp SET
    #temp.food_customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc 
		INNER JOIN @stores s on dgc.store_key = s.store_key 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = 'Food'),0),
    #temp.food_item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
		INNER JOIN @stores s on dgc.store_key = s.store_key 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = 'Food'), 0)

UPDATE #temp SET
    #temp.rx_customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc 
		INNER JOIN @stores s on dgc.store_key = s.store_key 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = 'Rx'),0),
    #temp.rx_item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		INNER JOIN @stores s on dgc.store_key = s.store_key 
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = 'Rx'), 0)

UPDATE #temp SET
    #temp.misc_customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc 
		INNER JOIN @stores s on dgc.store_key = s.store_key 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = 'Misc'),0),
    #temp.misc_item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		INNER JOIN @stores s on dgc.store_key = s.store_key 
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = 'Misc'), 0)

SET NOCOUNT OFF
SELECT * FROM #temp


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE      PROCEDURE [dbo].[GetYtdSalesTotalCompanyByGroupMulti]
	@salesWeek INT,
	@salesYear INT,
	@dayOfWeekNumMax INT,
	@groupName VARCHAR(255), 
	@storeNumber INT = NULL,
	@sameStoresDateKey INT = NULL
AS


DECLARE @startDate INT
DECLARE @endDate INT

-- for 1 & 2 years ago, don't use the fiscal calendar for those years.  
-- instead, take '@dayInQuarter' days, starting from the 52 & 104 weeks, 
-- backing up from @salesWeek and @salesYear

-- 104 weeks ago
EXEC GetYtdDates @salesWeek, @salesYear, @dayOfWeekNumMax, -104, @startDate OUTPUT, @endDate OUTPUT
EXEC GetGroupSalesByDateRange @startDate, @endDate, @groupName, @storeNumber, @sameStoresDateKey

-- 52 weeks ago
EXEC GetYtdDates @salesWeek, @salesYear, @dayOfWeekNumMax, -52, @startDate OUTPUT, @endDate OUTPUT
EXEC GetGroupSalesByDateRange @startDate, @endDate, @groupName, @storeNumber, @sameStoresDateKey

-- current period
EXEC GetYtdDates @salesWeek, @salesYear, @dayOfWeekNumMax, 0, @startDate OUTPUT, @endDate OUTPUT
EXEC GetGroupSalesByDateRange @startDate, @endDate, @groupName, @storeNumber, @sameStoresDateKey


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE       PROCEDURE [dbo].[GetYtdTotalsByDepartment]
	@salesWeek INT,
	@salesYear INT,
	@dayOfWeekNumMax INT,
	@departmentKey SMALLINT,
	@storeNumber INT = NULL,
	@sameStoresDateKey INT = NULL
AS

DECLARE @startDate INT
DECLARE @endDate INT
EXEC GetYtdDates @salesWeek, @salesYear, @dayOfWeekNumMax, 0, @startDate OUTPUT, @endDate OUTPUT

-- figure what stores to report on
DECLARE @stores TABLE (store_key INT)
IF @storeNumber IS NULL BEGIN
	IF @sameStoresDateKey = NULL OR @sameStoresDateKey = 0 BEGIN
	    INSERT @stores SELECT store_key FROM store_dim
	END ELSE BEGIN
	    INSERT @stores SELECT store_key FROM store_dim WHERE opening_date_key <= @sameStoresDateKey
	END
END ELSE BEGIN
    INSERT @stores SELECT @storeNumber
END



SET NOCOUNT ON 
SELECT
	dss.store_key,
    ISNULL(SUM(sales_dollar_amount),0) AS sales_dollar_amount,
	0 AS sales_dist,
    0 AS customer_count,
	0 AS customer_dist,
    0 AS item_count,
	0 AS item_dist,
    0 AS group_sales_dollar_amount,
    0 AS group_customer_count,
    0 AS group_item_count,
	@startDate AS startDate,
	@endDate AS endDate
INTO #temp
FROM daily_subdepartment_sales dss 
INNER JOIN @stores s ON
	s.store_key = dss.store_key
INNER JOIN date_dim da ON
	da.date_key = dss.tlog_date_key
INNER JOIN subdepartment_dim sd ON
	sd.subdepartment_key = dss.subdepartment_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND sd.department_key = @departmentKey
GROUP BY
	dss.store_key

-- get counts for the department
UPDATE #temp SET
    #temp.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_department_sales dds 
		INNER JOIN date_dim da ON da.date_key = dds.tlog_date_key
		WHERE dds.store_key = #temp.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dds.department_key = @departmentKey),0),
    #temp.item_count = ISNULL((SELECT SUM(item_count) FROM daily_department_sales dds 
		INNER JOIN date_dim da ON da.date_key = dds.tlog_date_key
		WHERE dds.store_key = #temp.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dds.department_key = @departmentKey), 0)


-- find group for department
DECLARE @majorGrouping VARCHAR(255)
SELECT @majorGrouping = d.major_grouping FROM department_dim d WHERE department_key = @departmentKey

-- get sales for group
SELECT
	dgs.store_key,
    ISNULL(SUM(sales_dollar_amount),0.00) AS sales_dollar_amount,
    0 AS customer_count,
    0 AS item_count
INTO #group_totals
FROM daily_group_sales dgs 
INNER JOIN @stores s ON
	s.store_key = dgs.store_key
INNER JOIN date_dim da ON
	da.date_key = dgs.tlog_date_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND dgs.major_grouping = @majorGrouping
GROUP BY
	dgs.store_key

-- get counts for group
UPDATE #group_totals SET
    #group_totals.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE dgc.store_key = #group_totals.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping),0),
    #group_totals.item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE dgc.store_key = #group_totals.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping), 0)
	
SET NOCOUNT OFF
SELECT 
	t.store_key,
	t.sales_dollar_amount,
	CASE
		WHEN gt.sales_dollar_amount = 0 THEN 0
		ELSE t.sales_dollar_amount / gt.sales_dollar_amount * 100 
	END AS sales_dist,
	t.customer_count,
	CASE 
		WHEN gt.customer_count = 0 THEN 0 
		ELSE CONVERT(NUMERIC(18,2), t.customer_count) / CONVERT(NUMERIC(18,2), gt.customer_count) * 100 
	END AS customer_dist,
	t.item_count,
	CASE 
		WHEN gt.item_count = 0 THEN 0
		ELSE CONVERT(NUMERIC(18,2), t.item_count) / CONVERT(NUMERIC(18,2), gt.item_count) * 100 
	END AS item_dist,
	@startDate AS start_date_key,
	@endDate AS end_date_key
FROM
	#temp t 
INNER JOIN #group_totals gt ON
	gt.store_key = t.store_key

SELECT
	SUM(t.sales_dollar_amount) AS sales_dollar_amount,
	CASE
		WHEN SUM(gt.sales_dollar_amount) = 0 THEN 0
		ELSE SUM(t.sales_dollar_amount) / SUM(gt.sales_dollar_amount) * 100 
	END AS sales_dist,
	SUM(t.customer_count) AS customer_count,
	CASE
		WHEN SUM(gt.customer_count) = 0 THEN 0
		ELSE (CONVERT(NUMERIC(18,2), SUM(t.customer_count)) / CONVERT(NUMERIC(18,2), SUM(gt.customer_count))) * 100 
	END AS customer_dist,
	SUM(t.item_count) AS item_count,
	CASE
		WHEN SUM(gt.item_count) = 0 THEN 0
		ELSE (CONVERT(NUMERIC(18,2), SUM(t.item_count)) / CONVERT(NUMERIC(18,2), SUM(gt.item_count))) * 100 
	END AS item_dist
FROM
	#temp t
INNER JOIN #group_totals gt ON
	gt.store_key = t.store_key


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROCEDURE [dbo].[GetYtdTotalsByDepartmentMulti]
	@salesWeek INT,
	@salesYear INT,
	@dayOfWeekNumMax INT,
	@departmentKey SMALLINT, 
	@storeNumber INT = NULL,
	@sameStoresDateKey INT = NULL
AS



-- for 1 & 2 years ago, don't use the fiscal calendar for those years.  
-- instead, take '@dayInQuarter' days, starting from the 52 & 104 weeks, 
-- backing up from @salesWeek and @salesYear
DECLARE @startDate INT
DECLARE @endDate INT

-- 104 weeks ago
EXEC GetYtdDates @salesWeek, @salesYear, @dayOfWeekNumMax, -104, @startDate OUTPUT, @endDate OUTPUT
EXEC GetDepartmentSalesByDateRangeRollup @startDate, @endDate, @departmentKey, @storeNumber, @sameStoresDateKey

-- 52 weeks ago
EXEC GetYtdDates @salesWeek, @salesYear, @dayOfWeekNumMax, -52, @startDate OUTPUT, @endDate OUTPUT
EXEC GetDepartmentSalesByDateRangeRollup @startDate, @endDate, @departmentKey, @storeNumber, @sameStoresDateKey

-- current period
EXEC GetYtdDates @salesWeek, @salesYear, @dayOfWeekNumMax, 0, @startDate OUTPUT, @endDate OUTPUT
EXEC GetDepartmentSalesByDateRangeRollup @startDate, @endDate, @departmentKey, @storeNumber, @sameStoresDateKey


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[GetYtdTotalsByDepartmentRollup]
	@salesYear INT,
	@dayInFiscalYearMax INT,
	@departmentKey SMALLINT, 
	@storeNumber INT = NULL
AS


SET NOCOUNT ON 

DECLARE @stores TABLE (store_key INT)
IF @storeNumber IS NULL BEGIN
    INSERT @stores SELECT store_key FROM store_dim
END ELSE BEGIN
    INSERT @stores SELECT @storeNumber
END


DECLARE @startDate INT
SET @startDate = (
	SELECT 
		date_key 
	FROM 
		date_dim 
	WHERE 
		sales_year = @salesYear 
		AND day_in_sales_year = 1
)

DECLARE @endDate INT
SET @endDate = (
	SELECT TOP 1 
		date_key 
	FROM 
		date_dim 
	WHERE
		sales_year = @salesYear
		AND day_in_sales_year <= @dayInFiscalYearMax
	ORDER BY
		date_key DESC
)

-- get qtd values for department
SET NOCOUNT ON 
SELECT
    ISNULL(SUM(sales_dollar_amount),0.00) AS sales_dollar_amount,
    0 AS customer_count,
    0 AS item_count,
	@startDate AS startDate,
	@endDate AS endDate
INTO #temp
FROM daily_subdepartment_sales dss
INNER JOIN @stores s ON
	s.store_key = dss.store_key
INNER JOIN date_dim da ON
	da.date_key = dss.tlog_date_key
INNER JOIN subdepartment_dim sd ON
	sd.subdepartment_key = dss.subdepartment_key
INNER JOIN department_dim dd ON
	dd.department_key = sd.department_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND dd.department_key = @departmentKey

UPDATE #temp SET
    #temp.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_department_sales dds
		INNER JOIN date_dim da ON da.date_key = dds.tlog_date_key
		INNER JOIN @stores s ON s.store_key = dds.store_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dds.department_key = @departmentKey), 0),
    #temp.item_count = ISNULL((SELECT SUM(item_count) FROM daily_department_sales dds 
		INNER JOIN date_dim da ON da.date_key = dds.tlog_date_key
		INNER JOIN @stores s ON s.store_key = dds.store_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dds.department_key = @departmentKey), 0)


-- find group for department
DECLARE @majorGrouping VARCHAR(255)
SELECT 
	@majorGrouping = d.major_grouping 
FROM 
	department_dim d 
WHERE 
	d.department_key = @departmentKey

-- get sales for group
SELECT
    ISNULL(SUM(sales_dollar_amount),0.00) AS sales_dollar_amount,
    0 AS customer_count,
    0 AS item_count
INTO #group_totals
FROM daily_group_sales dgs 
INNER JOIN @stores s ON
	s.store_key = dgs.store_key
INNER JOIN date_dim da ON
	da.date_key = dgs.tlog_date_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND dgs.major_grouping = @majorGrouping

-- get counts for group
UPDATE #group_totals SET
    #group_totals.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		INNER JOIN @stores s ON s.store_key = dgc.store_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping),0),
    #group_totals.item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		INNER JOIN @stores s ON s.store_key = dgc.store_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping), 0)

SET NOCOUNT OFF
SELECT 
	t.sales_dollar_amount,
	CASE 
		WHEN gt.sales_dollar_amount = 0 THEN 0
		ELSE t.sales_dollar_amount / gt.sales_dollar_amount * 100 
	END AS sales_dist,
	t.customer_count,
	CASE 
		WHEN gt.customer_count = 0 THEN 0
		ELSE CONVERT(NUMERIC(18,2), t.customer_count) / CONVERT(NUMERIC(18,2), gt.customer_count) * 100 
	END AS customer_dist,
	t.item_count,
	CASE
		WHEN gt.item_count = 0 THEN 0
		ELSE CONVERT(NUMERIC(18,2), t.item_count) / CONVERT(NUMERIC(18,2), gt.item_count) * 100 
	END AS item_dist,
	@startDate AS start_date_key,
	@endDate AS end_date_key,
	@dayInFiscalYearMax AS num_days
FROM
	#temp t 
CROSS JOIN #group_totals gt


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE      PROCEDURE [dbo].[GetYtdTotalsByGroup]
	@salesWeek INT,
	@salesYear INT,
	@dayOfWeekNumMax INT,
	@majorGrouping VARCHAR(255),
	@storeNumber INT = NULL,
	@sameStoresDateKey INT = NULL
AS



DECLARE @startDate INT
DECLARE @endDate INT
EXEC GetYtdDates @salesWeek, @salesYear, @dayOfWeekNumMax, 0, @startDate OUTPUT, @endDate OUTPUT


-- figure what stores to report on
DECLARE @stores TABLE (store_key INT)
IF @storeNumber IS NULL BEGIN
	IF @sameStoresDateKey = NULL OR @sameStoresDateKey = 0 BEGIN
	    INSERT @stores SELECT store_key FROM store_dim
	END ELSE BEGIN
	    INSERT @stores SELECT store_key FROM store_dim WHERE opening_date_key <= @sameStoresDateKey
	END
END ELSE BEGIN
    INSERT @stores SELECT @storeNumber
END


SET NOCOUNT ON 
SELECT
	dgs.store_key,
    ISNULL(SUM(sales_dollar_amount),0) AS sales_dollar_amount,
	100 AS sales_dist,
    0 AS customer_count,
	100 AS customer_dist,
    0 AS item_count,
	100 AS  item_dist,
	@startDate AS start_date_key,
	@endDate AS end_date_key
INTO #temp
FROM daily_group_sales dgs 
INNER JOIN @stores s ON
	s.store_key = dgs.store_key
INNER JOIN date_dim da ON
	da.date_key = dgs.tlog_date_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND dgs.major_grouping = @majorGrouping
GROUP BY
	dgs.store_key

UPDATE #temp SET
    #temp.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE dgc.store_key = #temp.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping),0),
    #temp.item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE dgc.store_key = #temp.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping), 0)


SET NOCOUNT OFF

-- 1 record per store
SELECT * FROM #temp

-- totals
SELECT
	SUM(sales_dollar_amount) AS sales_dollar_amount,
	100.00 AS sales_dist,
	SUM(customer_count) AS customer_count,
	100.00 AS customer_dist,
	SUM(item_count) AS item_count,
	100.00 as item_dist
FROM
	#temp


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROCEDURE [dbo].[GetYtdTotalsBySubdepartment]
	@salesWeek INT,
	@salesYear INT,
	@dayOfWeekNumMax INT,
	@subdepartmentKey SMALLINT,
	@storeNumber INT = NULL,
	@sameStoresDateKey INT = NULL
AS



DECLARE @startDate INT
DECLARE @endDate INT
EXEC GetYtdDates @salesWeek, @salesYear, @dayOfWeekNumMax, 0, @startDate OUTPUT, @endDate OUTPUT

-- figure what stores to report on
DECLARE @stores TABLE (store_key INT)
IF @storeNumber IS NULL BEGIN
	IF @sameStoresDateKey = NULL OR @sameStoresDateKey = 0 BEGIN
	    INSERT @stores SELECT store_key FROM store_dim
	END ELSE BEGIN
	    INSERT @stores SELECT store_key FROM store_dim WHERE opening_date_key <= @sameStoresDateKey
	END
END ELSE BEGIN
    INSERT @stores SELECT @storeNumber
END

SET NOCOUNT ON 
SELECT
	dss.store_key,
    ISNULL(SUM(sales_dollar_amount),0) AS sales_dollar_amount,
	0 AS sales_dist,
    0 AS customer_count,
	0 AS customer_dist,
    0 AS item_count,
	0 AS item_dist,
    0 AS group_sales_dollar_amount,
    0 AS group_customer_count,
    0 AS group_item_count,
	@startDate AS startDate,
	@endDate AS endDate
INTO #temp
FROM daily_subdepartment_sales dss 
INNER JOIN @stores s ON
	s.store_key = dss.store_key
INNER JOIN date_dim da ON
	da.date_key = dss.tlog_date_key
INNER JOIN subdepartment_dim sd ON
	sd.subdepartment_key = dss.subdepartment_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND sd.subdepartment_key = @subdepartmentKey
GROUP BY
	dss.store_key

-- get counts for the subdepartment
UPDATE #temp SET
    #temp.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_subdepartment_sales dss 
		INNER JOIN date_dim da ON da.date_key = dss.tlog_date_key
		WHERE dss.store_key = #temp.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dss.subdepartment_key = @subdepartmentKey),0),
    #temp.item_count = ISNULL((SELECT SUM(item_count) FROM daily_subdepartment_sales dss
		INNER JOIN date_dim da ON da.date_key = dss.tlog_date_key
		WHERE dss.store_key = #temp.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dss.subdepartment_key = @subdepartmentKey), 0)


-- find group for department
DECLARE @majorGrouping VARCHAR(255)
SELECT 
	@majorGrouping = d.major_grouping 
FROM 
	department_dim d 
INNER JOIN subdepartment_dim sd ON
	sd.department_key = d.department_key
WHERE 
	sd.subdepartment_key = @subdepartmentKey

-- get sales for group
SELECT
	dgs.store_key,
    ISNULL(SUM(sales_dollar_amount),0.00) AS sales_dollar_amount,
    0 AS customer_count,
    0 AS item_count
INTO #group_totals
FROM daily_group_sales dgs 
INNER JOIN @stores s ON
	s.store_key = dgs.store_key
INNER JOIN date_dim da ON
	da.date_key = dgs.tlog_date_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND dgs.major_grouping = @majorGrouping
GROUP BY
	dgs.store_key

-- get counts for group
UPDATE #group_totals SET
    #group_totals.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE dgc.store_key = #group_totals.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping),0),
    #group_totals.item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		WHERE dgc.store_key = #group_totals.store_key AND da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping), 0)
	
SET NOCOUNT OFF
SELECT 
	t.store_key,
	t.sales_dollar_amount,
	CASE
		WHEN gt.sales_dollar_amount = 0 THEN 0
		ELSE t.sales_dollar_amount / gt.sales_dollar_amount * 100 
	END AS sales_dist,
	t.customer_count,
	CASE
		WHEN gt.customer_count = 0 THEN 0
		ELSE (CONVERT(NUMERIC(18,2), t.customer_count) / CONVERT(NUMERIC(18,2), gt.customer_count)) * 100 
	END AS customer_dist,
	t.item_count,
	CASE
		WHEN gt.item_count = 0 THEN 0
		ELSE (CONVERT(NUMERIC(18,2), t.item_count) / CONVERT(NUMERIC(18,2), gt.item_count)) * 100 
	END AS item_dist,
	@startDate AS start_date_key,
	@endDate AS end_date_key
FROM
	#temp t 
INNER JOIN #group_totals gt ON
	gt.store_key = t.store_key


SELECT
	SUM(t.sales_dollar_amount) AS sales_dollar_amount,
	CASE
		WHEN SUM(gt.sales_dollar_amount) = 0 THEN 0 
		ELSE SUM(t.sales_dollar_amount) / SUM(gt.sales_dollar_amount) * 100 
	END AS sales_dist,
	SUM(t.customer_count) AS customer_count,
	CASE
		WHEN SUM(gt.customer_count) = 0 THEN 0
		ELSE (CONVERT(NUMERIC(18,2), SUM(t.customer_count)) / CONVERT(NUMERIC(18,2), SUM(gt.customer_count))) * 100 
	END AS customer_dist,
	SUM(t.item_count) AS item_count,
	CASE
		WHEN SUM(gt.item_count) = 0 THEN 0
		ELSE (CONVERT(NUMERIC(18,2), SUM(t.item_count)) / CONVERT(NUMERIC(18,2), SUM(gt.item_count))) * 100 
	END AS item_dist
FROM
	#temp t
INNER JOIN #group_totals gt ON
	gt.store_key = t.store_key


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE      PROCEDURE [dbo].[GetYtdTotalsBySubdepartmentMulti]
	@salesWeek INT,
	@salesYear INT,
	@dayOfWeekNumMax INT,
	@subdepartmentKey SMALLINT, 
	@storeNumber INT = NULL,
	@sameStoresDateKey INT = NULL
AS



-- for 1 & 2 years ago, don't use the fiscal calendar for those years.  
-- instead, take '@dayInQuarter' days, starting from the 52 & 104 weeks, 
-- backing up from @salesWeek and @salesYear
DECLARE @startDate INT
DECLARE @endDate INT

-- 104 weeks ago
EXEC GetYtdDates @salesWeek, @salesYear, @dayOfWeekNumMax, -104, @startDate OUTPUT, @endDate OUTPUT
EXEC GetSubdepartmentSalesByDateRangeRollup @startDate, @endDate, @subdepartmentKey, @storeNumber, @sameStoresDateKey

-- 52 weeks ago
EXEC GetYtdDates @salesWeek, @salesYear, @dayOfWeekNumMax, -52, @startDate OUTPUT, @endDate OUTPUT
EXEC GetSubdepartmentSalesByDateRangeRollup @startDate, @endDate, @subdepartmentKey, @storeNumber, @sameStoresDateKey

-- current period
EXEC GetYtdDates @salesWeek, @salesYear, @dayOfWeekNumMax, 0, @startDate OUTPUT, @endDate OUTPUT
EXEC GetSubdepartmentSalesByDateRangeRollup @startDate, @endDate, @subdepartmentKey, @storeNumber, @sameStoresDateKey


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[GetYtdTotalsBySubdepartmentRollup]
	@salesYear INT,
	@dayInFiscalYearMax INT,
	@subdepartmentKey SMALLINT, 
	@storeNumber INT = NULL
AS


SET NOCOUNT ON 

DECLARE @stores TABLE (store_key INT)
IF @storeNumber IS NULL BEGIN
    INSERT @stores SELECT store_key FROM store_dim
END ELSE BEGIN
    INSERT @stores SELECT @storeNumber
END


DECLARE @startDate INT
SET @startDate = (
	SELECT 
		date_key 
	FROM 
		date_dim 
	WHERE 
		sales_year = @salesYear 
		AND day_in_sales_year = 1
)

DECLARE @endDate INT
SET @endDate = (
	SELECT TOP 1 
		date_key 
	FROM 
		date_dim 
	WHERE
		sales_year = @salesYear
		AND day_in_sales_year <= @dayInFiscalYearMax
	ORDER BY
		date_key DESC
)
-- get qtd values for subdepartment
SET NOCOUNT ON 
SELECT
    ISNULL(SUM(sales_dollar_amount),0.00) AS sales_dollar_amount,
    0 AS customer_count,
    0 AS item_count,
	@startDate AS startDate,
	@endDate AS endDate
INTO #temp
FROM daily_subdepartment_sales dss
INNER JOIN @stores s ON
	s.store_key = dss.store_key
INNER JOIN date_dim da ON
	da.date_key = dss.tlog_date_key
INNER JOIN subdepartment_dim sd ON
	sd.subdepartment_key = dss.subdepartment_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND sd.subdepartment_key = @subdepartmentKey

UPDATE #temp SET
    #temp.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_subdepartment_sales dss 
		INNER JOIN date_dim da ON da.date_key = dss.tlog_date_key
		INNER JOIN @stores s ON s.store_key = dss.store_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dss.subdepartment_key = @subdepartmentKey), 0),
    #temp.item_count = ISNULL((SELECT SUM(item_count) FROM daily_subdepartment_sales dss 
		INNER JOIN date_dim da ON da.date_key = dss.tlog_date_key
		INNER JOIN @stores s ON s.store_key = dss.store_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dss.subdepartment_key = @subdepartmentKey), 0)


-- find group for department
DECLARE @majorGrouping VARCHAR(255)
SELECT 
	@majorGrouping = d.major_grouping 
FROM 
	department_dim d 
INNER JOIN subdepartment_dim sd ON
	sd.department_key = d.department_key
WHERE 
	sd.subdepartment_key = @subdepartmentKey

-- get sales for group
SELECT
    ISNULL(SUM(sales_dollar_amount),0.00) AS sales_dollar_amount,
    0 AS customer_count,
    0 AS item_count
INTO #group_totals
FROM daily_group_sales dgs 
INNER JOIN @stores s ON
	s.store_key = dgs.store_key
INNER JOIN date_dim da ON
	da.date_key = dgs.tlog_date_key
WHERE
	da.date_key BETWEEN @startDate AND @endDate
	AND dgs.major_grouping = @majorGrouping

-- get counts for group
UPDATE #group_totals SET
    #group_totals.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		INNER JOIN @stores s ON s.store_key = dgc.store_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping),0),
    #group_totals.item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
		INNER JOIN date_dim da ON da.date_key = dgc.tlog_date_key
		INNER JOIN @stores s ON s.store_key = dgc.store_key
		WHERE da.date_key BETWEEN @startDate AND @endDate AND dgc.major_grouping = @majorGrouping), 0)

SET NOCOUNT OFF
SELECT 
	t.sales_dollar_amount,
	CASE 
		WHEN gt.sales_dollar_amount = 0 THEN 0
		ELSE t.sales_dollar_amount / gt.sales_dollar_amount * 100 
	END AS sales_dist,
	t.customer_count,
	CASE 
		WHEN gt.customer_count = 0 THEN 0
		ELSE CONVERT(NUMERIC(18,2), t.customer_count) / CONVERT(NUMERIC(18,2), gt.customer_count) * 100 
	END AS customer_dist,
	t.item_count,
	CASE
		WHEN gt.item_count = 0 THEN 0
		ELSE CONVERT(NUMERIC(18,2), t.item_count) / CONVERT(NUMERIC(18,2), gt.item_count) * 100 
	END AS item_dist,
	@startDate AS start_date_key,
	@endDate AS end_date_key
FROM
	#temp t 
CROSS JOIN #group_totals gt


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
	p.department_key AS DepartmentId,
	RTRIM(LTRIM(p.department_name)) AS DepartmentName,
	bi.Upc,
	RTRIM(LTRIM(p.brand_name)) AS BrandName,
	RTRIM(LTRIM(p.item_description)) AS BrandItemDescription,
	p.product_size AS ProductSize,
	p.unit_of_measure AS ProductUom,
	CONVERT(NUMERIC(18,3), ISNULL(bi.Qty, 0)) as Qty,
	
	RegPriceAmt,
	RegPriceMult,
	CONVERT(NUMERIC(18,3), RegPriceAmt / RegPriceMult) as RegularUnitPrice,
	CONVERT(NUMERIC(18,3), RegPriceAmt / RegPriceMult * Qty) AS RegularUnitPriceExt,
	
	SalePriceAmt,
	SalePriceMult,
	CONVERT(NUMERIC(18,3), SalePriceAmt / SalePriceMult) AS PromotedUnitPrice,
	CONVERT(NUMERIC(18,3), SalePriceAmt / SalePriceMult * Qty) AS PromotedUnitPriceExt,
	
	CONVERT(NUMERIC(18,3), RegUnitCost) AS RegularUnitCost,
	CONVERT(NUMERIC(18,3), RegUnitCost * Qty) AS RegularUnitCostExt,
	
	CONVERT(NUMERIC(18,3), SaleUnitCost) AS PromotedUnitCost,
	CONVERT(NUMERIC(18,3), SaleUnitCost * Qty) AS PromotedUnitCostExt
	
FROM
	BatchItem bi
INNER JOIN Batch b ON
	b.batchid = bi.batchid
	AND b.storeid = bi.storeid
LEFT OUTER JOIN product_dim p ON
	p.upc = bi.upc
WHERE
	bi.BatchId = @batchId
	AND bi.StoreId = @storeId


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE           PROCEDURE [dbo].[InventorySelectDepartmentSummaryByBatchType]
	@week INT,
	@year INT,
	@storeKey INT,
	@batchDescription VARCHAR(255),
	@balancingBatchDescr VARCHAR(255) = NULL,
	@dateOffset INT = 0,
	@endWeek INT = NULL,
	@endYear INT = NULL
AS

DECLARE @stores TABLE (
	store_key INT NOT NULL
)

IF @endWeek IS NULL SET @endWeek = @week
IF @endYear IS NULL SET @endYear = @year

DECLARE @startDateKey INT
DECLARE @endDateKey INT

SELECT @startDateKey = MIN(da.date_key) FROM date_dim AS da WHERE da.sales_week = @week AND da.sales_year = @year
SELECT @endDateKey = MAX(da.date_key) FROM date_dim AS da WHERE da.sales_week = @endWeek AND da.sales_year = @endYear

IF @storeKey IS NOT NULL BEGIN
	INSERT INTO @stores VALUES (@storeKey)
END ELSE BEGIN
	INSERT INTO @stores SELECT store_key FROM store_dim
END

-- get the raw inventory data for the dates we are dealing with
SELECT 
	s.store_key
	,da.date_key
	,p.product_key
	,ISNULL(SUM(ibi.Qty), 0) as quantity
	,MIN(CASE WHEN ibi.RegPriceMult > 1 
		THEN ibi.RegPriceAmt / ibi.RegPriceMult
		ELSE ibi.RegPriceAmt
	END) AS unit_price
 	,MIN(ibi.SaleUnitCost) AS unit_cost
INTO 
	#temp_inv
FROM
	BatchItem ibi
INNER JOIN Batch ib ON
	ib.BatchId = ibi.BatchId
	AND ib.StoreId = ibi.StoreId
	AND ib.ShortDescription = @batchDescription
INNER JOIN @stores s ON
	s.store_key = ib.storeid
INNER JOIN date_dim da ON
	da.calendar_date = CONVERT(VARCHAR, DATEADD(dd, @DateOffset, ib.ClosedDateTime), 101)
	AND da.date_key BETWEEN @startDateKey AND @endDateKey
INNER JOIN product_dim p ON
	p.upc = ibi.upc
GROUP BY
	s.store_key
	,da.date_key
	,p.product_key

-- now get the 'Opposing' data, and flip the qty to negative
IF @balancingBatchDescr IS NOT NULL BEGIN
	INSERT INTO 
		#temp_inv
	SELECT 
		s.store_key
		,da.date_key
		,p.product_key
		,ISNULL(SUM(ibi.Qty) * -1, 0) as quantity
	 	,MIN(CASE WHEN ibi.RegPriceMult > 1 
		THEN ibi.RegPriceAmt / ibi.RegPriceMult
		ELSE ibi.RegPriceAmt
	END) AS unit_price
 	,MIN(ibi.SaleUnitCost) AS unit_cost
	FROM
		BatchItem ibi
	INNER JOIN Batch ib ON
		ib.BatchId = ibi.BatchId
		AND ib.StoreId = ibi.StoreId
		AND ib.ShortDescription = @balancingBatchDescr
	INNER JOIN @stores s ON
		s.store_key = ib.storeid
	INNER JOIN date_dim da ON
		da.calendar_date = CONVERT(VARCHAR, DATEADD(dd, @DateOffset, ib.ClosedDateTime), 101)
		AND da.date_key BETWEEN @startDateKey AND @endDateKey
	INNER JOIN product_dim p ON
		p.upc = ibi.upc
	GROUP BY
		s.store_key
		,da.date_key
		,p.product_key
END

-- get a list of the subdepts we are dealing with
SELECT DISTINCT 
	subdepartment_key
INTO 
	#temp_subdepts
FROM 
	product_dim p
INNER JOIN #temp_inv t ON
	t.product_key = p.product_key

-- get a lit of all departments we are dealing with
SELECT DISTINCT
	department_key
INTO
	#temp_depts
FROM
	#temp_subdepts
INNER JOIN subdepartment_dim sd ON
	sd.subdepartment_key = #temp_subdepts.subdepartment_key

-- add the subdepartments back to #temp_subdepts that are not already there
INSERT INTO #temp_subdepts SELECT
	sd.subdepartment_key
FROM
	subdepartment_dim sd
WHERE
	sd.department_key IN (SELECT DISTINCT department_key FROM #temp_depts)
	AND sd.subdepartment_key NOT IN (SELECT subdepartment_key FROM #temp_subdepts)

-- get a matrix of all dates & departments & subdepartments
SELECT 
	da.date_key,
	tsd.subdepartment_key
INTO
	#temp_dates
FROM
	date_dim da
CROSS JOIN 
	#temp_subdepts tsd
WHERE
	da.date_key BETWEEN @startDateKey AND @endDateKey

SELECT
	s.store_key
	,td.date_key
	,da.sales_week
	,da.sales_year
	,sd.department_key
	,sd.subdepartment_key
	,CONVERT(DECIMAL(19,4), 0) AS quantity
	,CONVERT(DECIMAL(19,4), 0) AS value_at_retail
	,CONVERT(DECIMAL(19,4), 0) AS value_at_cost
	,CONVERT(DECIMAL(19,4), 0) AS subdept_sales
	,RIGHT('00' + CONVERT(VARCHAR, sd.subdepartment_key),2) + '-' + LTRIM(RTRIM(sd.subdepartment_name)) AS subdepartment_name
	,RIGHT('00' + CONVERT(VARCHAR, d.department_key),2) + '-' + LTRIM(RTRIM(d.department_name)) AS department_name
	,da.calendar_date
	,CONVERT(DECIMAL(19,4), 0) AS food_sales
	,CONVERT(DECIMAL(19,4), 0) AS dept_sales
INTO
	#temp_final
FROM
	#temp_dates td
INNER JOIN subdepartment_dim sd ON
	sd.subdepartment_key = td.subdepartment_key
INNER JOIN department_dim d ON
	d.department_key = sd.department_key	
INNER JOIN date_dim da ON
	da.date_key = td.date_key
CROSS JOIN @stores s

-- roll up value_at_retail & value_at_cost to subdepartments
SELECT
	store_key,
	date_key,
	subdepartment_key,
	SUM(unit_price * quantity) AS value_at_retail,
	SUM(unit_cost * quantity) AS value_at_cost
INTO
	#temp_values
FROM
	#temp_inv ti
INNER JOIN product_dim p ON
	p.product_key = ti.product_key
GROUP BY
	ti.store_key	
	,ti.date_key
	,p.subdepartment_key

UPDATE tf SET
	tf.value_at_retail = tv.value_at_retail,
	tf.value_at_cost = tv.value_at_cost
FROM
	#temp_final tf
INNER JOIN #temp_values tv ON
	tv.date_key = tf.date_key
	AND tv.store_key = tf.store_key
	AND tv.subdepartment_key = tf.subdepartment_key

-- pull in total subdepartment sales
UPDATE tf SET
	quantity = ISNULL((SELECT SUM(quantity) FROM #temp_inv ti INNER JOIN product_dim p ON p.product_key = ti.product_key WHERE ti.store_key = tf.store_key AND ti.date_key = tf.date_key AND p.subdepartment_key = tf.subdepartment_key), 0)
	,subdept_sales = (SELECT SUM(sales_dollar_amount) FROM daily_subdepartment_sales dss WHERE dss.subdepartment_key = tf.subdepartment_key AND dss.tlog_date_key = tf.date_key and dss.store_key = tf.store_key)
FROM
	#temp_final tf


-- all set!		
SELECT 
	tf.* 
	,sd.short_name
FROM 
	#temp_final tf
INNER JOIN store_dim sd ON
	sd.store_key = tf.store_key
ORDER BY
	date_key,
	department_key,
	subdepartment_key


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE      PROCEDURE [dbo].[InventorySelectTransactionsByDateSubDept]
	@transactionDate DATETIME,
	@subdepartmentKey SMALLINT,
	@storeKey INT,
	@dateOffset INT = 0,
	@shortDescription VARCHAR(255) = NULL,
	@balancingBatchDescr VARCHAR(255) = NULL
AS

SELECT
	ib.ShortDescription
	,ibi.Upc
	,p.brand_name AS [Brand Name]
	,p.item_description AS [Description]
	,p.product_size AS [Size]
	,p.unit_of_measure AS [UOM]
	,ibi.Qty AS [Quantity]
FROM
	BatchItem ibi
INNER JOIN Batch ib ON
	ib.BatchId = ibi.BatchId
	AND ib.StoreId = ibi.StoreId
	AND ib.ShortDescription = @shortDescription
	AND ib.StoreId = @storeKey
INNER JOIN product_dim p ON
	p.upc = ibi.upc
	AND p.subdepartment_key = @subdepartmentKey
INNER JOIN date_dim da ON
	da.calendar_date = CONVERT(VARCHAR, ib.ClosedDateTime, 101)
WHERE
	CONVERT(DATETIME, CONVERT(VARCHAR, ib.ClosedDateTime, 101)) = DATEADD(dd, @dateOffset, @transactionDate)

UNION ALL

SELECT
	ib.ShortDescription
	,ibi.Upc
	,p.brand_name AS [Brand Name]
	,p.item_description AS [Description]
	,p.product_size AS [Size]
	,p.unit_of_measure AS [UOM]
	,ibi.Qty * -1 AS [Quantity]
FROM
	BatchItem ibi
INNER JOIN Batch ib ON
	ib.BatchId = ibi.BatchId
	AND ib.StoreId = ibi.StoreId
	AND ib.ShortDescription = @balancingBatchDescr
	AND ib.StoreId = @storeKey
INNER JOIN product_dim p ON
	p.upc = ibi.upc
	AND p.subdepartment_key = @subdepartmentKey
INNER JOIN date_dim da ON
	da.calendar_date = CONVERT(VARCHAR, ib.ClosedDateTime, 101)
WHERE
	CONVERT(DATETIME, CONVERT(VARCHAR, ib.ClosedDateTime, 101)) = DATEADD(dd, @dateOffset, @transactionDate)

-- union the 'opposing' batch type transactions too


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
SET @locName = 'Cheese - Chunk'
SET @locName = 'Eggs'
SET @locName = 'Brooms'
SET @locName = 'Dog Food - Bagged'
ItemLocationInquiry 'Brooms'
*/

CREATE PROCEDURE [dbo].[ItemLocationInquiry]
	@locName VARCHAR(50)
AS

DECLARE @keys TABLE (
	product_key INT NOT NULL
)

DECLARE @numSets INT
SELECT @numSets = COUNT(location_name) FROM location WHERE location_name = @locName

INSERT INTO @keys (product_key) SELECT DISTINCT
	li.product_key
FROM
	location l 
INNER JOIN location_item li ON
	li.location_key = l.location_key
	AND li.store_key = l.store_key
WHERE
	location_name = @locName

SELECT 
	k.product_key
	,p.upc
	,p.brand_name
	,p.item_description
	,p.product_size
	,p.unit_of_measure
	,l.location_name
	,l.location_key
	,s.store_key
	,s.short_name
	,0 AS rec_count
INTO 
	#temp
FROM 
	@keys k
INNER JOIN product_dim p ON
	p.product_key = k.product_key
INNER JOIN location_item li ON
	li.product_key = p.product_key
INNER JOIN location l ON
	l.location_key = li.location_key
	AND l.store_key = li.store_key
INNER JOIN store_dim s ON
	s.store_key = li.store_key


DECLARE @keys2 TABLE (
	product_key INT NOT NULL ,
	location_name VARCHAR(50) NOT NULL ,
	rec_count INT NOT NULL
)
INSERT INTO @keys2 SELECT
	k.product_key
	,l.location_name
	,COUNT(li.product_key) as rec_count
FROM
	@keys k
INNER JOIN location_item li ON
	li.product_key = k.product_key
INNER JOIN location l ON
	l.location_key = li.location_key
	AND l.store_key = li.store_key
GROUP BY 
	k.product_key
	,l.location_name


UPDATE t SET
	rec_count = k2.rec_count
FROM
	#temp t
INNER JOIN @keys2 k2 ON
	k2.product_key = t.product_key
	AND k2.location_name = t.location_name

SELECT * FROM #temp


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ItemMovement_SelectTabularSummaryByUpcStore]
	@upc CHAR(13),
	@today DATETIME,
	@storeKey INT
AS


DECLARE @qtyToday DECIMAL(9,2)
DECLARE @qtyToday2 DECIMAL(9,2)
DECLARE @qtyYesterday DECIMAL(9,2)
DECLARE @qtyYesterday2 DECIMAL(9,2)
DECLARE @qtyWeekToDate DECIMAL(9,2)
DECLARE @qtyWeekToDate2 DECIMAL(9,2)
DECLARE @qtyPeriodToDate DECIMAL(9,2)
DECLARE @qtyPeriodToDate2 DECIMAL(9,2)
DECLARE @qtyYearToDate DECIMAL(9,2)
DECLARE @qtyYearToDate2 DECIMAL(9,2)

DECLARE @minDate INT
DECLARE @maxDate INT
DECLARE @weekStartDate DATETIME
DECLARE @weekEndDate DATETIME
DECLARE @salesWeek INT
DECLARE @salesYear INT
DECLARE @todayDateKey INT

SELECT @todayDateKey = dbo.fn_DateToDateKey(@today)
SELECT @salesWeek = sales_week, @salesYear = sales_year FROM date_dim WHERE date_key = dbo.fn_DateToDateKey(@today)
SELECT @weekStartDate = calendar_date FROM date_dim WHERE sales_week = @salesWeek AND sales_year = @salesYear AND day_in_sales_week = 1
SELECT @weekEndDate = calendar_date FROM date_dim WHERE sales_week = @salesWeek AND sales_year = @salesYear AND day_in_sales_week = 7

DECLARE @productKey INT
SELECT @productKey = product_key FROM product_dim WHERE upc=@upc

-- today
SET @minDate = dbo.fn_DateToDateKey(@today)
SET @maxDate = @minDate
-- 'today' value comes from instore realtime sales
-- TODO: EXEC Get_item_movement_by_date_range @productKey, @storeKey, @minDate, @maxDate, @qtyToday OUTPUT 

-- year ago today
SELECT @minDate = date_key from date_dim where calendar_date = dateadd(WW, -52, @today)
SET @maxDate =@minDate
EXEC Get_item_movement_by_date_range @productKey, @storeKey, @minDate, @maxDate, @qtyToday2 OUTPUT 

-- yesterday
SET @minDate = dbo.fn_DateToDateKey(DATEADD(dd, -1, @today))
SET @maxDate = @minDate
EXEC Get_item_movement_by_date_range @productKey, @storeKey, @minDate, @maxDate, @qtyYesterday OUTPUT 

-- yesterday year ago
SELECT @minDate = date_key from date_dim where calendar_date = dateadd(WW, -52, DATEADD(dd, -1, @today))
SET @maxDate =@minDate
EXEC Get_item_movement_by_date_range @productKey, @storeKey, @minDate, @maxDate, @qtyYesterday2 OUTPUT 

-- week to date
SELECT @minDate = MIN(date_key), @maxDate = MAX(date_key) FROM date_dim WHERE sales_week = @salesWeek AND sales_year = @salesYear
EXEC Get_item_movement_by_date_range @productKey, @storeKey, @minDate, @maxDate, @qtyWeekToDate OUTPUT  

-- week to date year ago
SELECT @minDate = dbo.fn_DateToDateKey(DATEADD(ww, -52, calendar_date)) FROM date_dim WHERE date_key = @minDate
DECLARE @salesYear2 INT
DECLARE @salesWeek2 INT
SELECT @salesYear2 = sales_year, @salesWeek2 = sales_week FROM date_dim WHERE date_key = @minDate
SELECT @maxDate = MAX(date_key) FROM date_dim WHERE sales_year = @salesYear2 and sales_week = @salesWeek2
EXEC Get_item_movement_by_date_range @productKey, @storeKey, @minDate, @maxDate, @qtyWeekToDate2 OUTPUT  

-- 13 weeks
SELECT @minDate = dbo.fn_DateToDateKey(DATEADD(ww, -12, @weekStartDate))
SELECT @maxDate = @todaydateKey
EXEC Get_item_movement_by_date_range @productKey, @storeKey, @minDate, @maxDate, @qtyPeriodToDate OUTPUT  

-- 13 weeks year ago
SELECT @minDate = dbo.fn_DateToDateKey(DATEADD(ww, -64, @weekStartDate))
SELECT @maxDate = dbo.fn_DateToDateKey(DATEADD(ww, -52, @today))
EXEC Get_item_movement_by_date_range @productKey, @storeKey, @minDate, @maxDate, @qtyPeriodToDate2 OUTPUT  

-- year to date, this year
SELECT @minDate = CONVERT(INT,convert(varchar, @salesYear) + '0101')
SELECT @maxDate = dbo.fn_DateToDateKey(@today)
EXEC Get_item_movement_by_date_range @productKey, @storeKey, @minDate, @maxDate, @qtyYearToDate OUTPUT -- 

-- year to date, last year
SELECT @minDate = CONVERT(INT,convert(varchar, @salesYear-1) + '0101')
SELECT @maxDate = dbo.fn_DateToDateKey(DATEADD(ww, -52, @today))
EXEC Get_item_movement_by_date_range @productKey, @storeKey, @minDate, @maxDate, @qtyYearToDate2 OUTPUT --  

-- -- 52wks
-- SELECT @minDate = dbo.fn_DateToDateKey(DATEADD(ww, -52, @weekStartDate))
-- SELECT @maxDate = @todayDateKey
-- EXEC Get_item_movement_by_date_range @productKey, @storeKey, @minDate, @maxDate, @qtyYearToDate OUTPUT  
-- 
-- -- 104week
-- SELECT @minDate = dbo.fn_DateToDateKey(DATEADD(ww, -104, @weekStartDate))
-- SELECT @maxDate = dbo.fn_DateToDateKey(DATEADD(ww, -52, @weekStartDate))
-- EXEC Get_item_movement_by_date_range @productKey, @storeKey, @minDate, @maxDate, @qtyYearToDate2 OUTPUT  

DECLARE @firstSaleDateKey INT
SELECT 
	@firstSaleDateKey = MIN(trans_date_key) 
FROM 
	daily_sales_fact WITH (NOLOCK)
WHERE
	product_key = @productKey
	AND store_key = @storeKey

DECLARE @firstSaleDate DATETIME
SELECT
	@firstSaleDate = calendar_date
FROM
	date_dim
WHERE
	date_key = @firstSaleDateKey

SELECT 'Today', @qtyToday AS ThisYear, @qtyToday2 AS LastYear, 1 AS sort_key
UNION SELECT 'Yesterday', @qtyYesterday AS ThisYear, @qtyYesterday AS LastYear, 2 AS sort_key
UNION SELECT 'Week-To-Date', @qtyWeekToDate AS ThisYear, @qtyWeekToDate2 AS LastYear, 3 AS sort_key
UNION SELECT 'Period-To-Date', @qtyPeriodToDate AS ThisYear, @qtyPeriodToDate2 AS LastYear, 4 AS sort_key
UNION SELECT 'Year-To-Date', @qtyYearToDate AS ThisYear, @qtyYearToDate2 AS LastYear, 5 AS sort_key
ORDER BY
	sort_key

SELECT @firstSaleDate AS firstsaledate


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE      PROCEDURE [dbo].[ItemSales_SelectByUpcRollupByYear]
	@upc CHAR(13)
	,@storeKey SMALLINT = NULL
	,@howManyYears INT = 99
AS

DECLARE @currYear INT
SELECT @currYear = calendar_year FROM date_dim WHERE date_key = dbo.fn_DateToDateKey(GETDATE())
DECLARE @minYear INT
SELECT @minYear = @currYear - @howManyYears + 1

DECLARE @minDate INT
DECLARE @maxDate INT
SELECT @minDate = MIN(date_key) FROM date_dim WHERE calendar_year = @minYear
IF @minDate IS NULL BEGIN
	SELECT @minDate = MIN(date_key) FROM date_dim
END

SELECT @maxDate = dbo.fn_DateToDateKey(GETDATE())

DECLARE @stores TABLE (
	store_key INT
)

IF @storeKey IS NULL BEGIN
	INSERT INTO @stores SELECT store_key FROM store_dim AS sd
END ELSE BEGIN
	INSERT INTO @stores SELECT @storeKey
END
	

SELECT 
	da.calendar_year
	,ds.store_key
	,SUM(ds.sales_quantity) AS sales_quantity
	,SUM(ds.sales_dollar_amount) AS sales_dollar_amount
	,SUM(ds.cost_dollar_amount) AS cost_dollar_amount
	,SUM(ds.markdown_dollar_amount) AS markdown_dollar_amount
FROM
	daily_sales_fact ds WITH (NOLOCK)
INNER JOIN date_dim da WITH (NOLOCK) ON
	da.date_key = ds.trans_date_key
INNER JOIN product_dim p WITH (NOLOCK) ON
	p.product_key = ds.product_key
	AND p.upc = @upc
INNER JOIN @stores s ON
	s.store_key = ds.store_key
WHERE
	da.calendar_year >= @minYear
	AND ds.trans_date_key BETWEEN @minDate AND @maxDate
GROUP BY
	da.calendar_year
	,ds.store_key


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ItemSales_SelectByUpcStoreDateRange]
	@upc CHAR(13)
	,@storeKey SMALLINT
	,@startDateKey INT
	,@endDateKey INT
AS

DECLARE @stores TABLE (store_key INT PRIMARY KEY)
IF @storeKey IS NULL BEGIN
    INSERT @stores SELECT store_key FROM store_dim
END ELSE BEGIN
    INSERT @stores SELECT @storeKey
END

DECLARE @sales TABLE (
	trans_date_key INT NOT NULL,
	store_key INT NOT NULL,
	sales_quantity DECIMAL(9,2),
	sales_dollar_amount DECIMAL(9,2),
	cost_dollar_amount DECIMAL(9,2),
	gm_dollars DECIMAL(9,2),
	PRIMARY KEY (trans_date_key, store_key)
)

INSERT INTO @sales SELECT 
	ds.trans_date_key
	,ds.store_key
	,SUM(ds.sales_quantity) AS sales_quantity
	,SUM(ds.sales_dollar_amount) AS sales_dollar_amount
	,SUM(ds.cost_dollar_amount) AS cost_dollar_amount
	,SUM(ds.sales_dollar_amount - ds.cost_dollar_amount) AS gm_dollars
FROM
	product_dim p WITH (NOLOCK)
INNER JOIN 	daily_sales_fact ds WITH (NOLOCK) ON
	p.product_key = ds.product_key
	AND ds.trans_date_key between @startDateKey and @endDateKey
INNER JOIN @stores s ON
	s.store_key = ds.store_key
WHERE
	p.upc = @upc
GROUP BY
	ds.trans_date_key 
	,ds.store_key

DECLARE @dates TABLE (
	store_key INT NOT NULL,
	date_key INT NOT NULL,
	sales_year INT NOT NULL,
	sales_week INT NOT NULL,
	calendar_date DATE NOT NULL,
	day_of_week  VARCHAR(20) NOT NULL
)

INSERT INTO @dates SELECT
	s.store_key
	,da.date_key
	,da.sales_year
	,da.sales_week
	,da.calendar_date
	,RTRIM(LTRIM(da.day_of_week)) AS day_of_week
FROM
	[date_dim] da WITH (NOLOCK)
CROSS JOIN 
	@stores s
WHERE
	da.date_key between @startDateKey and @endDateKey

SELECT
	d.sales_year
	,d.sales_week
	,d.day_of_week
	,d.calendar_date
	,s.sales_quantity
	,s.sales_dollar_amount
	,s.cost_dollar_amount
	,s.gm_dollars
	,CASE 
		WHEN s.sales_dollar_amount = 0 THEN 0
		ELSE (s.sales_dollar_amount - s.cost_dollar_amount) / s.sales_dollar_amount * 100
	END AS gm_percent
	,CASE
		WHEN s.sales_quantity = 0 THEN 0 
		ELSE CONVERT(DECIMAL(9,2), s.sales_dollar_amount / s.sales_quantity) 
	END AS avg_price
	,d.store_key
FROM 
	@dates d
LEFT OUTER JOIN @sales s ON
	s.trans_date_key = d.date_key
	AND s.store_key = d.store_key
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ItemSales_SelectByUpcStoreNumberOfWeeksRollupByWeek]
	@upc CHAR(13)
	,@storeKey SMALLINT
	,@howManyWeeks INT
AS

DECLARE @currYear INT
DECLARE @currWeek INT
DECLARE @absWeek INT
SELECT @currYear = sales_year, @currWeek = sales_week, @absWeek = absolute_week FROM date_dim WHERE date_key = dbo.fn_DateToDateKey(GETDATE())

DECLARE @minAbsWeek INT
SET @minAbsWeek = @absWeek - @howManyWeeks + 1

DECLARE @minDate INT
DECLARE @maxDate INT
SELECT @minDate = MIN(date_key) FROM date_dim WHERE absolute_week = @minAbsWeek
SELECT @maxDate = dbo.fn_DateToDateKey(GETDATE())

SELECT 
	da.sales_year
	,da.sales_week
	,ds.store_key
	,SUM(ds.sales_quantity) AS sales_quantity
	,SUM(ds.sales_dollar_amount) AS sales_dollar_amount
	,SUM(ds.cost_dollar_amount) AS cost_dollar_amount
	,SUM(ds.markdown_dollar_amount) AS markdown_dollar_amount
INTO
	#temp
FROM
	daily_sales_fact ds WITH (NOLOCK)
INNER JOIN date_dim da WITH (NOLOCK) ON
	da.date_key = ds.trans_date_key
INNER JOIN product_dim p WITH (NOLOCK) ON
	p.product_key = ds.product_key
	AND p.upc = @upc
WHERE
	store_key = @storeKey
	AND da.absolute_week >= @minAbsWeek
	AND ds.trans_date_key BETWEEN @minDate AND @maxDate
GROUP BY
	da.sales_year
	,da.sales_week
	,ds.store_key

SELECT
	da.sales_year
	,da.sales_week
	,da.calendar_date AS week_start_date
	,t.store_key
	,t.sales_quantity
	,t.sales_dollar_amount
	,t.cost_dollar_amount
	,t.markdown_dollar_amount
FROM
	#temp t
RIGHT OUTER JOIN date_dim da ON
	t.sales_year = da.sales_year
	AND t.sales_week = da.sales_week
WHERE
	da.absolute_week >= @minAbsWeek
	AND da.day_in_sales_week = 1	
	AND da.absolute_week <= @absWeek
	AND da.sales_year <= @currYear
ORDER BY
	da.sales_year
	,da.sales_week


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[KeySequence_GetNext] 
        @keyType char(20),
        @nextNumber int OUTPUT
AS

DECLARE @num INT

SELECT 
    @num = NextNumber 
FROM 
    dw_key_sequence 
WHERE 
    KeyType=@keyType


IF @num IS NULL BEGIN
   INSERT INTO dw_key_sequence(KeyType, NextNumber) VALUES (@keyType, 2)
   SELECT @nextNumber = 1
END ELSE BEGIN
   UPDATE dw_key_sequence SET NextNumber = @num+1
   SELECT @nextNumber = @num
END


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[MaintApplyItemLocationChanges]
	@SessionKey VARCHAR(100)
AS

DECLARE @timeStr VARCHAR(440)
DECLARE @saveRowCount INT

SELECT @timeStr = CONVERT(VARCHAR, GETDATE(), 109)
RAISERROR('[%s] find store_key ', 10, 1, @timeStr) WITH NOWAIT
DECLARE @storeKey INT
SELECT @storeKey = MIN(store_key) FROM maint_staging_location_group WHERE SessionKey = @sessionKey

SELECT @timeStr = CONVERT(VARCHAR, GETDATE(), 109)
RAISERROR('[%s] clear location_item ', 10, 1, @timeStr) WITH NOWAIT
DELETE FROM location_item WHERE store_key = @storeKey
SELECT @timeStr = CONVERT(VARCHAR, GETDATE(), 109)
RAISERROR('[%s] clear location ', 10, 1, @timeStr) WITH NOWAIT
DELETE FROM location WHERE store_key = @storeKey
SELECT @timeStr = CONVERT(VARCHAR, GETDATE(), 109)
RAISERROR('[%s] clear location_group ', 10, 1, @timeStr) WITH NOWAIT
DELETE FROM location_group WHERE store_key = @storeKey

SELECT @timeStr = CONVERT(VARCHAR, GETDATE(), 109)
RAISERROR('[%s] insert location_group ', 10, 1, @timeStr) WITH NOWAIT
INSERT INTO location_group (
	store_key
	,location_group_key
	,location_group_name
	,sort_key
) SELECT 
	store_key
	,location_group_key
	,location_group_name
	,sort_key
FROM maint_staging_location_group WHERE SessionKey = @SessionKey
SET @saveRowCount = @@ROWCOUNT
SELECT @timeStr = CONVERT(VARCHAR, GETDATE(), 109)
RAISERROR('[%s] %d location_group inserts ', 10, 1, @timeStr, @saveRowCount) WITH NOWAIT

SELECT @timeStr = CONVERT(VARCHAR, GETDATE(), 109)
RAISERROR('[%s] insert location ', 10, 1, @timeStr) WITH NOWAIT
INSERT INTO location (
	store_key
	,location_key
	,location_name
	,location_group_key
	,sort_key
) SELECT 
	store_key
	,location_key
	,location_name
	,location_group_key
	,sort_key
FROM maint_staging_location WHERE SessionKey = @SessionKey
SET @saveRowCount = @@ROWCOUNT
SELECT @timeStr = CONVERT(VARCHAR, GETDATE(), 109)
RAISERROR('[%s] %d location inserts ', 10, 1, @timeStr, @saveRowCount) WITH NOWAIT

SELECT @timeStr = CONVERT(VARCHAR, GETDATE(), 109)
RAISERROR('[%s] insert location_item ', 10, 1, @timeStr) WITH NOWAIT
INSERT INTO location_item (
	store_key
	,location_key
	,product_key
	,seq
) SELECT 
	s.store_key
	,s.location_key
	,p.product_key
	,s.seq1
FROM 
	maint_staging_location_item s
INNER JOIN product_dim p ON
	p.upc = s.upc
WHERE 
	s.SessionKey = @SessionKey
SET @saveRowCount = @@ROWCOUNT
SELECT @timeStr = CONVERT(VARCHAR, GETDATE(), 109)
RAISERROR('[%s] %d location_item inserts ', 10, 1, @timeStr, @saveRowCount) WITH NOWAIT


SET QUOTED_IDENTIFIER ON


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[MessageLogInsert]
	@source VARCHAR(1024),
	@isError bit,
	@message VARCHAR(1024),
	@exceptionText VARCHAR(4096) = NULL
AS

INSERT INTO s3_message_log (
	log_time,	source,
	is_error,
	message,
	exception_text
) VALUES (
	GETDATE(),
	@source,
	@isError,
	@message,
	@exceptionText
)


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[MessageLogProcessByRequestId]
	@requestId CHAR(50)
AS

INSERT INTO s3_message_log
	(log_time, source, store_id, is_error, message, exception_text)
SELECT 
	GETDATE(),
	source,
	StoreId,
	is_error,
	message,
	exception_text
FROM
	maint_staging_message_log
WHERE
	RequestId = @requestId


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[PriceAuditProcessByRequestId]
	@requestId CHAR(50)
AS

DECLARE @error INT
BEGIN TRANSACTION

-- push data into fact table
INSERT INTO price_audit_detail_fact (
	store_key
	,audit_date_key
	,upc
	,system_price
	,marked_price
	,price_not_marked
	,wrong_price_marked
	,not_on_file
	,notes
	,upload_date_key
	,location_not_assigned
	,wrong_location_assigned
)
SELECT 
	storeid AS store_key
	,dbo.fn_DateToDateKey(AuditDate) AS audit_date_key
	,upc
	,SystemPrice AS system_price
	,MarkedPrice AS marked_price
	,PriceNotMarked AS price_not_marked
	,WrongPriceMarked AS wrong_price_marked
	,NotOnFile AS not_on_file
	,Notes
	,UploadDate AS upload_date_key
	,LocationNotAssigned
	,WrongLocationAssigned
FROM
	price_audit_detail_staging
WHERE
	RequestId = @requestId

SET @error = @@ERROR
IF @error <> 0 BEGIN
	ROLLBACK TRANSACTION
	RETURN
END


-- clear data from staging table
DELETE FROM price_audit_detail_staging WHERE RequestId = @requestId	
SET @error = @@ERROR
IF @error <> 0 BEGIN
	ROLLBACK TRANSACTION
	RETURN
END

-- all good, commit
COMMIT TRANSACTION


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procAuditSalesAdjustmentSelectRecent] AS

SELECT TOP 500
	da.calendar_date AS [Sales Date],
	sd.subdepartment_key AS [Subdepartment],
	sd.subdepartment_name AS [Subdepartment Name],
	s.short_name AS [Store],
	old_sales_dollar_amount AS [Old Value],
	new_sales_dollar_amount AS [New Value],
	audit_date AS [Date of Change],
	audit_user AS [User]
FROM
	audit_sales_adjustment a
INNER JOIN subdepartment_dim sd ON
	sd.subdepartment_key = a.subdepartment_key
INNER JOIN store_dim s ON
	s.store_key = a.store_key
INNER JOIN date_dim da ON
	da.date_key = a.tlog_date_key
ORDER BY
	row_key DESC


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC Product_SelectMovementByDateRange '0001121300750', 307, 20090504, 20090510
CREATE PROCEDURE [dbo].[Product_SelectMovementByDateRange] 
	@upc char(13)
	,@storeKey SMALLINT
	,@startDateKey INT
    ,@endDateKey INT
AS

SET NOCOUNT ON

DECLARE @output TABLE (
	date_key INT
	,calendar_date DATETIME
	,day_of_week VARCHAR(15)
	,sales_quantity DECIMAL(9,2)
	,sales_dollar_amount DECIMAL(9,2)
	,avg_price DECIMAL(9,2)
)

INSERT INTO @output SELECT
	date_key
	,calendar_date
	,day_of_week
	,0.00
	,0.00
	,0.00
FROM
	date_dim AS dd
WHERE
	dd.date_key BETWEEN @startDateKey AND @endDateKey

SELECT
	dsf.trans_date_key
	,SUM(sales_quantity) AS sales_quantity	
	,SUM(sales_dollar_amount) AS sales_dollar_amount
INTO 
	#temp
FROM
	daily_sales_fact dsf
WHERE
	store_key = @storeKey
	AND trans_date_key BETWEEN @startDateKey AND @endDateKey
GROUP BY
	dsf.trans_date_key

UPDATE o SET
	o.sales_quantity = t.sales_quantity	
	,o.sales_dollar_amount = T.sales_dollar_amount
	,o.avg_price = T.sales_dollar_amount / T.sales_quantity
FROM
	@output o
INNER JOIN #temp t ON
	t.trans_date_key = o.date_key

SET NOCOUNT OFF
SELECT * FROM @output AS o


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC Product_SelectPromotedMovementByUpc '0007110000577', 258, 1000, 100
CREATE  PROCEDURE [dbo].[Product_SelectPromotedMovementByUpc]
	@upc CHAR(13)
	,@storeKey INT
	,@daysToLookBack INT = 730
	,@maxRowsToReturn INT = 99
AS

DECLARE @maxDaysBackToLook INT
SET @maxDaysBackToLook = @daysToLookBack
DECLARE @maxRangeToReturn INT
SET @maxRangeToReturn = @maxRowsToReturn
DECLARE @innerStoreKey INT
SET @innerStoreKey = @storeKey

DECLARE @output TABLE (
	rangeNum INT
	,startDate DATETIME
	,endDate DATETIME
	,numOfDays INT
	,salesQty DECIMAL(9,2)
	,salesDollarAmount DECIMAL(9,2)
	,costDollarAmount DECIMAL(9,2)
	,markdownDollarAmount DECIMAL(9,2)
	,bucketName VARCHAR(25)
	,avgPrice DECIMAL(9,2)
	,avgDailyUnitsSold DECIMAL(9,2)
)	

-- backup 18 months from today (31 days/month * 18)
SET NOCOUNT ON
DECLARE @minDateKey INT
DECLARE @todayAbsDateKey INT
SELECT @todayAbsDateKey = absolute_day FROM date_dim WHERE date_key = dbo.fn_DateToDateKey(GETDATE())
SELECT @minDateKey = dd.date_key FROM date_dim AS dd WHERE absolute_day = @todayAbsDateKey - @maxDaysBackToLook

DECLARE curSales CURSOR FOR SELECT
		da.absolute_day
		,da.day_of_week
		,da.calendar_date
		,dsf.trans_date_key
		,dsf.sales_quantity
		,dsf.sales_dollar_amount
		,dsf.cost_dollar_amount
		,dsf.markdown_dollar_amount 
		,pbd.bucket_name
	FROM 
		daily_sales_fact dsf
	INNER JOIN product_dim AS p ON
		p.product_key = dsf.product_key
		AND p.upc = @upc
	INNER JOIN pricing_bucket_dim AS pbd ON
		pbd.pricing_bucket_key = dsf.pricing_bucket_key
		AND pbd.is_promoted = 1
	INNER JOIN date_dim da ON
		da.date_key = dsf.trans_date_key
		AND	dsf.trans_date_key >= @minDateKey
	WHERE		
		dsf.store_key = @innerStoreKey
	ORDER BY 
		dsf.trans_date_key DESC

DECLARE @absDay INT
DECLARE @dayofWeek CHAR(15)
DECLARE @calDate DATETIME
DECLARE @transDateKey INT
DECLARE @salesQty DECIMAL(9,2)
DECLARE @salesDollarAmt DECIMAL(9,2)
DECLARE @costDollarAmt DECIMAL(9,2)
DECLARE @markdownDollarAmt DECIMAL(9,2)
DECLARE @bucketName VARCHAR(25)

DECLARE @totSalesQty DECIMAL(9,2)
DECLARE @totSalesDollarAmt DECIMAL(9,2)
DECLARE @totCostDollarAmt DECIMAL(9,2)
DECLARE @totMarkdownDollarAmt DECIMAL(9,2)

DECLARE @rangeNum INT
DECLARE @rangeStartAbsDateKey INT
DECLARE @rangeEndAbsDateKey INT
DECLARE @rangeStartDate DATETIME
DECLARE @rangeEndDate DATETIME
DECLARE @numOfDays INT

DECLARE @priorAbsDay INT
DECLARE @priorBucketName VARCHAR(25)
OPEN curSales

FETCH NEXT FROM curSales INTO @absDay, @dayofWeek, @calDate, @transDateKey, @salesQty, @salesDollarAmt, @costDollarAmt, @markdownDollarAmt, @bucketName
SET @rangeNum = 1
SET @priorAbsDay = @absDay + 1
SET @priorBucketName = @bucketName
SET @rangeEndAbsDateKey = @absDay
SET @rangeEndDate = @calDate
SET @numOfDays = 0
SET @totSalesQty = 0
SET @totSalesDollarAmt = 0
SET @totCostDollarAmt = 0
SET @totMarkdownDollarAmt = 0
WHILE @@FETCH_STATUS = 0 BEGIN
	IF @absDay <> @priorAbsDay - 1 BEGIN
		-- there was a gap in the sequence insert into @output now
		INSERT INTO @output
        (
			rangeNum
			,startDate
	        ,endDate
	        ,numOfDays
	        ,salesQty
	        ,salesDollarAmount
	        ,costDollarAmount
	        ,markdownDollarAmount
			,bucketName
			,avgPrice
			,avgDailyUnitsSold
        ) VALUES (
			@rangeNum
			,@rangeStartDate
			,@rangeEndDate
			,@numOfDays
			,@totSalesQty
			,@totSalesDollarAmt
			,@totCostDollarAmt
			,@totMarkdownDollarAmt
			,@priorBucketName
			,CASE 
				WHEN @totSalesQty = 0 THEN 0
				ELSE @totSalesDollarAmt / @totSalesQty
			END
			,@totSalesQty / @numOfDays
		)
		
		SET @rangeEndAbsDateKey = @absDay
		SET @rangeEndDate = @calDate
		SET @numOfDays = 0
		SET @totSalesQty = 0
		SET @totSalesDollarAmt = 0
		SET @totCostDollarAmt = 0
		SET @totMarkdownDollarAmt = 0
		
		SET @rangeNum = @rangeNum + 1
		IF @rangeNum > @maxRangeToReturn 
			GOTO ALLDONE
	END

	SET @numOfDays = @numOfDays + 1
	SET @rangeStartAbsDateKey = @absDay
	SET @rangeStartDate = @calDate
	SET @totSalesQty = @totSalesQty + @salesQty
	SET @totSalesDollarAmt = @totSalesDollarAmt + @salesDollarAmt
	SET @totCostDollarAmt = @totCostDollarAmt + @costDollarAmt
	SET @totMarkdownDollarAmt = @totMarkdownDollarAmt + @markdownDollarAmt

	SET @priorAbsDay = @absDay
	SET @priorBucketName = @bucketName
	FETCH NEXT FROM curSales INTO @absDay, @dayofWeek, @calDate, @transDateKey, @salesQty, @salesDollarAmt, @costDollarAmt, @markdownDollarAmt, @bucketName
END

ALLDONE:

CLOSE curSales
DEALLOCATE curSales

SET NOCOUNT OFF
SELECT * FROM @output


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
EXEC ProductCostAdjustmentReport 20060921

SELECT * FROM raw_ProductCostAdjustment WHERE groupcode = 27
SELECT * FROM raw_ProductCostAdjustment WHERE groupcode = 43
UPDATE raw_ProductCostAdjustment SET BatchId = 229384 where groupcode = 9 and costadjustmenttype = 'BB'
UPDATE raw_ProductCostAdjustment SET BatchId = 229227 where groupcode = 10 and costadjustmenttype = 'BB'

SELECT * FROM raw_ProductCostAdjustment WHERE groupcode = 9
SELECT * FROM raw_ProductCostAdjustment WHERE groupcode = 10

*/

CREATE    PROCEDURE [dbo].[ProductCostAdjustmentReport]
	@endDateKey INT
AS


SELECT 
	GroupCode 
	,CostAdjustmentType
	,StartDate
	,EndDate
	,Amount
	,InflationFactor
	,BatchId
	,COUNT(*) AS num_recs
INTO
	#groupCodes
FROM 
	raw_ProductCostAdjustment pca 
WHERE 
	dbo.fn_DateToDateKey(pca.EndDate) = @endDateKey
GROUP BY
	GroupCode 
	,CostAdjustmentType
	,StartDate
	,EndDate
	,Amount
	,InflationFactor
	,BatchId

SELECT
	GroupCode	
	,CostAdjustmentType
	,Upc
INTO
	#items
FROM 
	raw_ProductCostAdjustment pca 
WHERE 
	dbo.fn_DateToDateKey(pca.EndDate) = @endDateKey
	
-- SELECT 
-- 	GroupCode
-- 	,CostAdjustmentType
-- 	,COUNT(*)
-- FROM
-- 	#groupCodes
-- GROUP BY
-- 	GroupCode
-- 	,CostAdjustmentType
-- HAVING
-- 	COUNT(*) > 1
	
-- SELECT * FROM #groupCodes

SELECT
	g.GroupCode
	,g.CostAdjustmentType
	,ds.store_key
	,p.product_key
	,SUM(sales_quantity) AS t_sales_quantity
INTO
	#results	
FROM
	#groupCodes g
INNER JOIN #items i ON
	i.CostAdjustmentType = g.CostAdjustmentType
	AND i.GroupCode = g.GroupCode
INNER JOIN dbo.product_dim p WITH (NOLOCK) ON
	p.upc = i.Upc	
INNER JOIN daily_sales_fact ds WITH (NOLOCK) ON
	ds.product_key = p.product_key
	AND ds.trans_date_key BETWEEN dbo.fn_DateToDateKey(g.StartDate) AND dbo.fn_DateToDateKey(g.EndDate)
GROUP BY
	g.GroupCode
	,g.CostAdjustmentType
	,ds.store_key
	,p.product_key

SELECT 
	g.GroupCode
	,g.CostAdjustmentType
	,g.StartDate
	,g.EndDate
	,g.Amount
	,g.InflationFactor
	,g.BatchId
--	,g.CostAdjustmentType + '.' + CAST(g.GroupCode AS VARCHAR(20)) + ' [' + CAST(g.Amount AS VARCHAR(10)) + '] ' + CONVERT(VARCHAR, g.StartDate, 101) + ' - ' + CONVERT(VARCHAR, g.EndDate, 101) AS group_info
	,g.CostAdjustmentType + '.' + CAST(g.GroupCode AS VARCHAR(20)) AS group_info
	,s.store_key
	,s.short_name
	,p.upc
	,p.item_description
	,p.brand_name
	,p.product_size
	,p.unit_of_measure
	,p.upc + ' ' + RTRIM(LTRIM(p.brand_name)) + ' ' + RTRIM(LTRIM(p.item_description)) AS item_info
	,ROUND(r.t_sales_quantity + (r.t_sales_quantity * g.InflationFactor), 0) AS t_sales_quantity
FROM 
	#results r
INNER JOIN #groupCodes g ON
	g.GroupCode = r.GroupCode
	AND g.CostAdjustmentTYpe = r.CostAdjustmentType
INNER JOIN store_dim s ON
	s.store_key = r.store_key
INNER JOIN product_dim p ON
	p.product_key = r.product_key
-- WHERE
-- 	BatchId IS NOT NULL


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    PROCEDURE [dbo].[s3_adjustment_get_item_sales]
	@upc CHAR(13),
	@date INT,
	@store SMALLINT
AS

SET NOCOUNT ON

DECLARE @tlogFileKey INT
SELECT @tlogFileKey = tlog_File_key FROM tlog_history WHERE tlog_date_key = @date and store_key = @store
IF @tlogFileKey IS NULL BEGIN
	SELECT @tlogFileKey = 0
END

DECLARE @productKey INT
SELECT @productKey = product_key FROM product_dim WHERE upc = @upc

SET NOCOUNT OFF
-- IF @tlogFileKey = 0 BEGIN
-- 	SELECT 
-- 		sales.sales_dollar_amount,
-- 		sales.trans_date_key,
-- 		dd.calendar_date
-- 	FROM 
-- 		daily_sales_fact sales
-- 	INNER JOIN date_dim AS dd ON
-- 		dd.date_key = sales.trans_date_key
-- 	WHERE
-- 		sales.product_key = @productKey
-- 		and sales.tlog_file_key = @tlogFileKey
-- 		and sales.store_key = @store
-- 		and sales.trans_date_key = @date
-- END ELSE BEGIN
	SELECT 
		sales.sales_dollar_amount,
		sales.trans_date_key,
		dd.calendar_date
	FROM 
		daily_sales_fact sales
	INNER JOIN date_dim AS dd ON
		dd.date_key = sales.trans_date_key
	WHERE
		sales.product_key = @productKey
		and sales.tlog_file_key = @tlogFileKey
		and sales.store_key = @store
		AND @tlogFileKey <> 0
-- END


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROCEDURE [dbo].[s3_dw_FixDepositReturns] AS



DECLARE @oldProductKey INT
SELECT @oldProductKey = product_key FROM product_dim WHERE upc = '0000000000088'
DECLARE @newProductKey INT
SELECT @newProductKey = product_key FROM product_dim WHERE upc = '0000000000099'

update daily_sales_fact_staging2 set
	product_key = @newProductKey
WHERE
	product_key = @oldProductKey
        -- changed on 8/17/2005 to handle the case (rare) where
	-- sales_quantity=0 but sales_dollar_amount is < 0
	-- AND sales_quantity < 0 
	-- AND sales_dollar_amount < 0

-- remove the dupes
SELECT
    trans_date_key,
    product_key,
    store_key,
    tlog_file_key,
    sum(sales_quantity) as sales_quantity,
    sum(sales_dollar_amount) as sales_dollar_amount,
    sum(cost_dollar_amount) as cost_dollar_amount
INTO
    #hold
FROM 
    daily_sales_fact_staging2	
WHERE
    product_key = @newProductKey
GROUP BY
    trans_date_key,
    product_key,
    store_key,
    tlog_file_key

DELETE FROM daily_sales_fact_staging2 WHERE product_key = @newProductKey
INSERT daily_sales_fact_staging2 SELECT * FROM #hold


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[s3_dw_get_3weeks_dates_separate]
    @salesWeek INT,
    @salesYear INT
AS

SET NOCOUNT ON
DECLARE @year INT
DECLARE @week INT
DECLARE @absWeek INT
SELECT @absWeek = absolute_week FROM date_dim WHERE sales_week = @salesWeek AND sales_year = @salesyear

SET NOCOUNT OFF
SELECT
	calendar_date,
	calendar_year,
	date_month_text
FROM date_dim da
WHERE
    da.absolute_week = @absWeek


SELECT
	calendar_date,
	calendar_year,
	date_month_text
FROM date_dim da
WHERE
    da.absolute_week = @absWeek-52


SELECT
	calendar_date,
	calendar_year,
	date_month_text
FROM date_dim da
WHERE
    da.absolute_week = @absWeek-52-52


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[s3_dw_get_3year_calendar_events_separate]
    @salesWeek INT,
    @salesYear INT
AS

SET NOCOUNT ON
DECLARE @year INT
DECLARE @week INT
DECLARE @absWeek INT
SELECT @absWeek = absolute_week FROM date_dim WHERE sales_week = @salesWeek AND sales_year = @salesyear

-- DECLARE @weeks TABLE (absolute_week INT)
-- INSERT @weeks SELECT @absWeek
-- INSERT @weeks SELECT @absWeek-52
-- INSERT @weeks SELECT @absWeek-52-52

SET NOCOUNT OFF
SELECT
    effective_date_key,
    expiration_date_key,
    event_description,
    s.store_key,
	s.short_name,
	da.day_of_week
FROM
    event_calendar_dim ec
INNER JOIN date_dim da ON
    da.date_key = ec.effective_date_key
LEFT OUTER JOIN store_dim s ON
	s.store_key = ec.store_key
WHERE
    da.absolute_week = @absWeek
SELECT
    effective_date_key,
    expiration_date_key,
    event_description,
    s.store_key,
	s.short_name,
	da.day_of_week
FROM
    event_calendar_dim ec
INNER JOIN date_dim da ON
    da.date_key = ec.effective_date_key
LEFT OUTER JOIN store_dim s ON
	s.store_key = ec.store_key
WHERE
    da.absolute_week = @absWeek-52
SELECT
    effective_date_key,
    expiration_date_key,
    event_description,
    s.store_key,
	s.short_name,
	da.day_of_week
FROM
    event_calendar_dim ec
INNER JOIN date_dim da ON
    da.date_key = ec.effective_date_key
LEFT OUTER JOIN store_dim s ON
	s.store_key = ec.store_key
WHERE
    da.absolute_week = @absWeek-52-52


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[s3_dw_get_calendar_events]
    @salesWeek INT,
    @salesYear INT
AS

SET NOCOUNT ON
DECLARE @year INT
DECLARE @week INT
DECLARE @absWeek INT
SELECT @absWeek = absolute_week FROM date_dim WHERE sales_week = @salesWeek AND sales_year = @salesyear

DECLARE @weeks TABLE (absolute_week INT)
INSERT @weeks SELECT @absWeek
INSERT @weeks SELECT @absWeek-52
INSERT @weeks SELECT @absWeek-52-52

SET NOCOUNT OFF

SELECT
    effective_date_key,
    expiration_date_key,
    event_description,
    store_key
FROM
    event_calendar_dim ec
INNER JOIN date_dim da ON
    da.date_key = ec.effective_date_key
INNER JOIN @weeks weeks ON
    weeks.absolute_week = da.absolute_week
WHERE
	ec.show_on_sales_screens = 1


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[s3_dw_get_dates_for_3weeks] 
    @salesWeek INT,
    @salesYear INT
AS

SET NOCOUNT ON
DECLARE @year INT
DECLARE @week INT
DECLARE @absWeek INT
SELECT @absWeek = absolute_week FROM date_dim WHERE sales_week = @salesWeek AND sales_year = @salesyear
SET NOCOUNT OFF

-- 104 weeks ago
SELECT date_key, day_of_week, date_month_text, calendar_year, calendar_date FROM date_dim WHERE absolute_week = @absWeek-52-52 ORDER BY date_key

-- 52 weeks ago
SELECT date_key, day_of_week, date_month_text, calendar_year, calendar_date FROM date_dim WHERE absolute_week = @absWeek-52 ORDER BY date_key

-- specified week
SELECT date_key, day_of_week, date_month_text, calendar_year, calendar_date FROM date_dim WHERE absolute_week = @absWeek ORDER BY date_key


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE      PROCEDURE [dbo].[s3_dw_item_sales_by_week]
	@upc CHAR(13),
	@storeKey INT,
	@weeks INT = 13,
	@firstSaleDate DATETIME OUTPUT,
	@lastSaleDate DATETIME OUTPUT
AS

SET NOCOUNT ON

DECLARE @productKey INT
SELECT 
	@productKey = p.product_key 
FROM 
	product_dim p 
WHERE 
	p.upc=@upc

DECLARE @startDateKey INT
DECLARE @firstWeek INT
SELECT @firstWeek = absolute_week FROM date_dim WHERE date_key = dbo.fn_DateToDateKey(GETDATE())
SELECT @firstWeek = @firstWeek - @weeks

SELECT TOP 1
	@startDateKey = date_key 
FROM 
	date_dim
WHERE
	absolute_week = @firstWeek
ORDER BY
	date_key

-- if the calculated start week is prior to the earliest data
-- in date_dim, start at the first week available in date_dim
IF @startDateKey IS NULL BEGIN
	SELECT TOP 1
		@startDateKey = date_key 
	FROM 
		date_dim
	WHERE
		absolute_week = 1
	ORDER BY
		date_key
END

-- find the product key
SELECT @productKey = p.product_key FROM product_dim p WHERE p.upc = @upc
DECLARE @temp TABLE (
	absolute_week INT NOT NULL,
	sales_quantity DECIMAL(18,4),
	sales_quantity_in_cases DECIMAL(18,4),
	sales_dollar_amount DECIMAL(18,4),
	cost_dollar_amount DECIMAL(18,4),
	gross DECIMAL(18,4),
	week_start_date DATETIME
)

;WITH cte AS (
	SELECT 
		product_key
		,store_key
		,MAX(date_key) AS date_key
	FROM
		prod_store_dim_history psdh
	GROUP BY 
		product_key
		,store_key
)
INSERT @temp SELECT
	da.absolute_week,
	SUM(s.sales_quantity),
	SUM(s.sales_quantity / psdh.case_pack),
	SUM(s.sales_dollar_amount),
	SUM(s.cost_dollar_amount),
	NULL,
	NULL
from
	daily_sales_fact s WITH (NOLOCK)
INNER JOIN date_dim da WITH (NOLOCK) ON
	da.date_key = s.trans_date_key
INNER JOIN cte ON
	cte.product_key = @productKey
	AND cte.store_key = @storeKey
INNER JOIN prod_store_dim_history psdh ON
	psdh.date_key = cte.date_key
	AND psdh.product_key = cte.product_key
	AND psdh.store_key = cte.store_key
where
	s.trans_date_key > @startDateKey
	AND s.product_key = @productKey
	AND s.store_key = @storeKey
group by
	da.absolute_week
order by 
	absolute_week desc

UPDATE t SET
	t.gross	= CAST((sales_dollar_amount - cost_dollar_amount) / sales_dollar_amount * 100 AS DECIMAL(18,4))
FROM
	@temp t
WHERE 
	sales_dollar_amount <> 0

UPDATE t SET
	t.gross = 0 
FROM 
	@temp t
WHERE
	t.gross IS NULL

UPDATE t SET 
	t.week_start_date = da.calendar_date
FROM 
	@temp t
INNER JOIN date_dim da ON
	da.absolute_week = t.absolute_week
WHERE
	da.day_in_sales_week = 1

-- final output
SET NOCOUNT OFF
SELECT 
	week_start_date as [Date],
	CONVERT(VARCHAR, week_start_date, 101) as [DateText],
	sales_quantity as [Quantity],
	sales_quantity_in_cases AS [Cases],
	sales_dollar_amount as [Sales],
	cost_dollar_amount as [Cost],
	gross as [Gross] 
FROM 
	@temp
ORDER BY
	week_start_date 

-- return first sale date as return value
DECLARE @firstSaleDateKey INT
SELECT @firstSaleDateKey = MIN(trans_date_key) FROM daily_sales_fact WHERE product_key = @productKey AND store_key = @storeKey
SELECT @firstSaleDate = calendar_date FROM date_dim WHERE date_key = @firstSaleDateKey

DECLARE @lastSaleDateKey INT
SELECT @lastSaleDateKey = MAX(trans_date_key) FROM daily_sales_fact WHERE product_key = @productKey AND store_key = @storeKey
SELECT @lastSaleDate = calendar_date FROM date_dim WHERE date_key = @lastSaleDateKey


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE        PROCEDURE [dbo].[s3_dw_item_set_sales2]
	@startDateKey INT
	,@endDateKey INT
	,@minSalesQuantity DECIMAL(19,2) = NULL
	,@maxSalesQuantity DECIMAL(19,2) = NULL
	,@excludePosValidNoItems BIT = 0
	,@rankLimit INT = 0
AS

SET NOCOUNT ON 

DECLARE @innerStartDateKey INT
DECLARE @innerEndDateKey INT
SET @innerStartDateKey = @startDateKey
SEt @innerEndDateKey = @endDateKey
DECLARE @timeStr VARCHAR(1024)

CREATE TABLE #tempSales (
	product_key INT,
	store_key INT,
	sales_quantity DECIMAL(19,2),
	sales_dollar_amount DECIMAL(19,2),
	cost_dollar_amount DECIMAL(19,2),
	sales_dollar_amount_regular_retail DECIMAL(19,2),
	markdown_dollar_amount DECIMAL(19,2)
)


--SELECT 'getting sales', GETDATE()
SET @timeStr = CONVERT(VARCHAR, GETDATE(), 21)
RAISERROR('[%s] getting sales',10,1, @timeStr) WITH NOWAIT
INSERT INTO #tempSales SELECT
	tis.product_key,
	tis.store_key,
	SUM(ds.sales_quantity) as sales_quantity,
	SUM(ds.sales_dollar_amount) as sales_dollar_amount,
	SUM(ds.cost_dollar_amount) as cost_dollar_amount,
	SUM(ds.sales_quantity * ds.regular_retail_unit_price) AS sales_dollar_amount_regular_retail,
	SUM(ds.markdown_dollar_amount) AS markdown_dollar_amount
FROM  
	#temp_item_store tis
INNER JOIN daily_sales_fact ds WITH (NOLOCK) ON
	tis.product_key = ds.product_key
	AND tis.store_key = ds.store_key
WHERE
	ds.trans_date_key between @innerStartDateKey and @innerEndDateKey
GROUP BY
	tis.product_key,
	tis.store_key

CREATE CLUSTERED INDEX PK_tempSales ON #tempSales(product_key, store_key)

-- @tempSalesFinal includes all items, even zero movers
CREATE TABLE #tempSalesFinal (
	product_key INT,
	store_key INT,
	sku VARCHAR(13),
	sales_quantity DECIMAL(19,2),
	sales_dollar_amount DECIMAL(19,2),
	cost_dollar_amount DECIMAL(19,2),
	sales_dollar_amount_regular_retail DECIMAL(19,2),
	markdown_dollar_amount DECIMAL(19,2)
)

--SELECT 'getting sales final', GETDATE()
SET @timeStr = CONVERT(VARCHAR, GETDATE(), 21)
RAISERROR('[%s] insert tempSalesFinal',10,1, @timeStr) WITH NOWAIT
SELECT DISTINCT store_key INTO #temp_stores FROM #temp_item_store
INSERT #tempSalesFinal SELECT 
	tis.product_key,
	tis.store_key,
	tis.sku,
	0,
	0,
	0,
	0,
	0
FROM 
	#temp_item_store tis

CREATE CLUSTERED INDEX PK_tempSalesFinal ON #tempSalesFinal(product_key, store_key)

SET @timeStr = CONVERT(VARCHAR, GETDATE(), 21)
RAISERROR('[%s] update tempSalesFinal',10,1, @timeStr) WITH NOWAIT
UPDATE tsf SET
	tsf.sales_quantity = ts.sales_quantity,
	tsf.sales_dollar_amount = ts.sales_dollar_amount,
	tsf.cost_dollar_amount = ts.cost_dollar_amount,
	tsf.sales_dollar_amount_regular_retail = ts.sales_dollar_amount_regular_retail,
	tsf.markdown_dollar_amount = ts.markdown_dollar_amount
FROM #tempSalesFinal tsf
INNER JOIN #tempSales ts ON
	ts.store_key = tsf.store_key
	AND ts.product_key = tsf.product_key

-- min/max comparisons are for all stores in aggregate
DECLARE @qtyMovers TABLE(
	product_key INT NOT NULL
	,sales_quantity DECIMAL(19,2)
)

INSERT INTO @qtyMovers (
	product_key
	,sales_quantity
) SELECT 
	tsf.product_key
	,SUM(tsf.sales_quantity) 
FROM 
	#tempSalesFinal tsf 
GROUP BY 
	tsf.product_key

IF @minSalesQuantity IS NOT NULL BEGIN
	DELETE 
		tsf 
	FROM 
		#tempSalesFinal tsf
	INNER JOIN @qtyMovers q ON
		q.product_key = tsf.product_key
		AND q.sales_quantity < @minSalesQuantity
	WHERE 
		tsf.sales_quantity >= 0
END
IF @maxSalesQuantity IS NOT NULL BEGIN
	DELETE 
		tsf
	FROM 
		#tempSalesFinal tsf
	INNER JOIN @qtyMovers q ON
		q.product_key = tsf.product_key
		AND q.sales_quantity > @maxSalesQuantity
END

-- calculate rank
DECLARE @rankTable TABLE (
	product_key INT NOT NULL,
	sales_quantity DECIMAL(19,2),
	sales_quantity_rank INT IDENTITY(1,1)
	PRIMARY KEY CLUSTERED (product_key)
)
INSERT INTO @rankTable (product_key, sales_quantity) SELECT
	tsf.product_key
	,SUM(tsf.sales_quantity)
FROM
	#tempSalesFinal tsf
GROUP BY 
	tsf.product_key
ORDER BY 
	SUM(tsf.sales_quantity) DESC
	,SUM(sales_dollar_amount) DESC

-- if @rankLimit <> 0, remove rows from @rankTable to only 
-- requested ranks are returned: 
-- @rankLimit > 0 return top 'N'
-- @rankLimit < 0 retun bottom 'N'
IF @rankLimit > 0 BEGIN
	DELETE FROM @rankTable WHERE sales_quantity_rank > @rankLimit
END
IF @rankLimit < 0 BEGIN
	DECLARE @maxRank INT
	SELECT @maxRank = MAX(sales_quantity_rank) FROM @rankTable
	DELETE FROM @rankTable WHERE sales_quantity_rank <= @maxRank + @rankLimit
END

-- get totals by store ahead of time so that % of totals
-- can easily be calculated in SQL ahead of time
SET @timeStr = CONVERT(VARCHAR, GETDATE(), 21)
RAISERROR('[%s] populate storeTotals',10,1, @timeStr) WITH NOWAIT
DECLARE @storeTotals TABLE (
	store_key INT,
	sales_quantity_total DECIMAL(19,2),
	sales_dollar_amount_total DECIMAL(19,2)
)
INSERT @storeTotals SELECT
	store_key,
	SUM(sales_quantity),
	SUM(sales_dollar_amount)
FROM 
	#tempSalesFinal
GROUP BY 
	store_key


SET NOCOUNT OFF

SET @timeStr = CONVERT(VARCHAR, GETDATE(), 21)
RAISERROR('[%s] final select',10,1, @timeStr) WITH NOWAIT
SELECT 
	tsf.store_key,
	sd.short_name,
	p.upc,
	RTRIM(LTRIM(p.brand_name)) AS brand_name,
	RTRIM(LTRIM(p.item_description)) AS item_description,
	p.product_size,
	p.unit_of_measure,
	p.subdepartment_key,
	RTRIM(LTRIM(p.subdepartment_name)) AS subdepartment_name,
	p.department_key,
	RTRIM(LTRIM(p.department_name)) AS department_name,
	da1.calendar_date AS create_date,
	da2.calendar_date AS delete_date,
	ISNULL(tsf.sales_quantity,0) AS sales_quantity,
	r.sales_quantity_rank,
	CASE
		WHEN t.sales_quantity_total <> 0 THEN
			ISNULL(CAST(tsf.sales_quantity / t.sales_quantity_total * 100 AS DECIMAL(19,2)),0) 
		ELSE 0
	END AS sales_quantity_pct_total,
	ISNULL(tsf.sales_dollar_amount,0) AS sales_dollar_amount,
	ISNULL(
		CAST(
			CASE
				WHEN t.sales_dollar_amount_total <> 0 THEN
					tsf.sales_dollar_amount / t.sales_dollar_amount_total * 100
				ELSE 0
			END
			AS DECIMAL(19,2)),
		0) AS sales_dollar_pct_total,    
	ISNULL(tsf.cost_dollar_amount,0) AS cost_dollar_amount,
	CASE
		WHEN tsf.sales_quantity > 0 THEN
			CAST(tsf.sales_dollar_amount / tsf.sales_quantity AS DECIMAL(19,2))
		ELSE 0
	END AS unit_price,
	CASE
		WHEN tsf.sales_quantity > 0 THEN
			CAST(tsf.cost_dollar_amount / tsf.sales_quantity AS DECIMAL(19,2))
		ELSE 0
	END AS unit_cost, 
	CASE
		WHEN sales_dollar_amount > 0 THEN
			CAST((sales_dollar_amount - cost_dollar_amount) / sales_dollar_amount * 100 AS DECIMAL(19,2)) 
		ELSE 0
	END AS gross
	,sp.sku
	,ps.pos_valid_flag AS PosValid
	,tsf.sales_dollar_amount_regular_retail
	,tsf.markdown_dollar_amount
	,ps.normal_unit_price AS today_normal_unit_price
	,sp.base_unit_cost AS today_base_unit_cost
	,p.product_status_desc
FROM 
	#tempSalesFinal tsf WITH (NOLOCK)
INNER JOIN product_dim p WITH (NOLOCK) ON
	p.product_key = tsf.product_key
INNER JOIN @storeTotals t ON
	t.store_key = tsf.store_key
INNER JOIN store_dim sd WITH (NOLOCK) ON
	sd.store_key = tsf.store_key
INNER JOIN product_store_dim ps WITH (NOLOCK) ON
	ps.product_key = tsf.product_key
	AND ps.store_key = tsf.store_key
	AND (@excludePosValidNoItems = 0 OR ps.pos_valid_flag = 1)
INNER JOIN supplier_dim supp WITH (NOLOCK) ON
	supp.supplier_key = ps.primary_vendor_key
INNER JOIN supplier_product_dim sp WITH (NOLOCK) ON
	sp.product_key = ps.product_key
	AND sp.supplier_key = supp.supplier_key
	AND sp.supplier_zone_id = ps.supplier_zone_id
INNER JOIN date_dim da1 ON
	da1.date_key = p.create_date_key
INNER JOIN date_dim da2 ON
	da2.date_key = p.delete_date_key
INNER JOIN @rankTable r ON
	r.product_key = tsf.product_key
ORDER BY
	p.upc
	,tsf.store_key
	
SET @timeStr = CONVERT(VARCHAR, GETDATE(), 21)
RAISERROR('[%s] done',10,1, @timeStr) WITH NOWAIT
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE      PROCEDURE [dbo].[s3_dw_sales_adjustment]
    @newSales MONEY ,
    @upc CHAR(13),
    @subdepartmentKey INT ,
    @storeKey INT ,
    @tlogDateKey INT ,
    @transDateKey INT
AS

-- find the default markup for this department
DECLARE @defaultMarkup NUMERIC(9,3)
SELECT @defaultMarkup = ISNULL(default_markup,0) FROM subdepartment_dim WHERE subdepartment_key = @subdepartmentKey
IF @defaultMarkup IS NULL BEGIN
	RAISERROR('The default markup is undefined for department %d', 16, 1, @subdepartmentkey)
	RETURN
END

-- find the product_key to adjust
DECLARE @productKey INT
SELECT
    @productKey = prod.product_key
FROM
    product_dim prod
WHERe
    prod.upc = @upc
IF @defaultMarkup IS NULL BEGIN
	RAISERROR('Could not find product_key for UPC %s', 16, 1, @upc)
	RETURN
END

-- find the tlog_file_key to adjust
-- if not found, use 0
DECLARE @tlogFileKey INT
SELECT 
    @tlogFileKey = th.tlog_file_key
FROM
    tlog_history th 
WHERE
    th.tlog_date_key = @tlogDateKey
    AND th.store_key = @storeKey
IF @tlogFileKey IS NULL BEGIN
  SELECT @tlogFileKey = 0
END

-- save the old sales for audit purposes
DECLARE @oldSales NUMERIC(9,2)
SELECT 
    @oldSales = sales_dollar_amount
FROM 
	daily_sales_fact sales
WHERE
    sales.trans_date_key = @transDateKey
    AND sales.tlog_file_key = @tlogFileKey
    AND sales.store_key = @storeKey
    AND sales.product_key = @productKey

-- item level sales
IF (@oldSales IS NOT NULL) BEGIN

    UPDATE sales SET
         sales.sales_dollar_amount = @newSales,
         sales.cost_dollar_amount = @newSales - (@newSales * (@defaultMarkup/100))
    FROM 
		daily_sales_fact sales
    WHERE
        sales.trans_date_key = @transDateKey
        AND sales.tlog_file_key = @tlogFileKey
        AND sales.store_key = @storeKey
        AND sales.product_key = @productKey

END ELSE BEGIN

    INSERT INTO daily_sales_fact (
        trans_date_key,
        product_key,
        store_key,
        tlog_file_key,
        sales_quantity,
        sales_dollar_amount,
        cost_dollar_amount,
        assumed_cost_flag,
		pricing_bucket_key,
		regular_retail_unit_price,
		base_unit_cost,
		promoted_unit_cost,
		markdown_dollar_amount
    ) VALUES (
        @tlogDateKey,
        @productKey,
        @storeKey,
        @tlogFileKey,
        1,
        @newSales,
        @newSales - (@newSales * (@defaultMarkup/100)),
        1,
		0,
		0,
		0,
		0,
		0
    )
END

-- subdepartment rollup
DECLARE @total NUMERIC(9,2)
SELECT 
     @total = SUM(sales_dollar_amount)
FROM
    daily_sales_fact sales
INNER JOIN product_dim prod ON
    prod.product_key = sales.product_key
INNER JOIN subdepartment_dim subdept ON
    subdept.subdepartment_key = prod.subdepartment_key
WHERE
    store_key = @storeKey
    AND subdept.subdepartment_key = @subdepartmentKey
    AND tlog_file_key = @tlogFileKey
    AND trans_date_key = @transDateKey

IF EXISTS(SELECT * FROM daily_subdepartment_sales WHERE store_key = @storeKey AND tlog_date_key = @tlogDateKey AND subdepartment_key = @subdepartmentKey) BEGIN
    UPDATE daily_subdepartment_sales SET
        sales_dollar_amount = @total,
        cost_dollar_amount = @total * (@defaultMarkup/100)
    WHERE
        store_key = @storeKey
        AND tlog_date_key = @tlogDateKey
        AND subdepartment_key = @subdepartmentKey
END ELSE BEGIN
    INSERT INTO daily_subdepartment_sales (
        tlog_date_key,
        store_key,
        subdepartment_key,
        tlog_file_key,
        sales_dollar_amount,
        cost_dollar_amount,
        customer_count,
        item_count
    ) VALUES (
        @tlogDateKey,
        @storeKey,
        @subdepartmentKey,
        @tlogFileKey,
        @total,
        @total * (@defaultMarkup/100),
        1,
        1
    )
END

-- department rollup - find the department for the specified subdepartment
DECLARE @departmentKey INT
SELECT @departmentKey = department_key FROM subdepartment_dim WHERE subdepartment_key = @subdepartmentKey

    -- calc total sales for the department
    SELECT 
         @total = SUM(sales_dollar_amount)
    FROM
        daily_subdepartment_sales sales
    INNER JOIN subdepartment_dim subdept ON
        subdept.subdepartment_key = sales.subdepartment_key
    WHERE
        store_key = @storeKey
        AND subdept.department_key = @departmentKey
        AND tlog_date_key = @tlogDateKey

    -- now update sales/cost for the department
    IF EXISTS(SELECT * FROM daily_department_sales WHERE tlog_date_key = @tlogDateKey AND store_key = @storeKey AND department_key = @departmentKey) BEGIN
        UPDATE daily_department_sales SET
            sales_dollar_amount = @total,
            cost_dollar_amount = @total * (@defaultMarkup/100)
        WHERE
            tlog_date_key = @tlogDateKey
            AND store_key = @storeKey
            AND department_key = @departmentKey
    END ELSE BEGIN
        INSERT INTO daily_department_sales (
            tlog_date_key,
            store_key,
            department_key,
            tlog_file_key,
            sales_dollar_amount,
            cost_dollar_amount,
            customer_count,
            item_count
        ) VALUES (
            @tlogDateKey,
            @storeKey,
            @departmentKey,
            @tlogFileKey,
            @total,
            @total * (@defaultMarkup/100),
            1,
            1
        )
    END

	-- update sales for the group
	DECLARE @majorGrouping VARCHAR(255)
	SELECT @majorGrouping = major_grouping FROM department_dim d WHERE d.department_key = @departmentKey
	SELECT
		da.date_key,
		dss.store_key,
		d.major_grouping,
		dss.tlog_file_key,
		SUM(dss.sales_dollar_amount) as sales_dollar_amount
	INTO 
		#temp_group_sales
	FROM dbo.daily_subdepartment_sales dss
	INNER JOIN dbo.subdepartment_dim sd ON
	    sd.subdepartment_key = dss.subdepartment_key
	INNER JOIN dbo.department_dim d ON
	    d.department_key = sd.department_key
		AND d.major_grouping = @majorGrouping
	INNER JOIN dbo.date_dim da ON
	    da.date_key = dss.tlog_date_key
	WHERE
		dss.tlog_file_key = @tlogFileKey
	GROUP BY
		da.date_key,
		dss.store_key,
		d.major_grouping,
		dss.tlog_file_key

	UPDATE g SET
		g.sales_dollar_amount = t.sales_dollar_amount
	FROM
		#temp_group_sales t
	INNER JOIN daily_group_sales g ON
		g.tlog_date_key = t.date_key
		AND g.store_key = t.store_key
		AND g.major_grouping = t.major_grouping
		AND g.tlog_file_key  = t.tlog_file_key

-- write audit trail
INSERT INTO audit_sales_adjustment (
    tlog_date_key,
    subdepartment_key, 
    store_key, 
    new_sales_dollar_amount, 
    old_sales_dollar_amount, 
    audit_date, 
    audit_user )    
VALUES (
    @tlogDateKey,
	@subdepartmentKey,
	@storeKey,
	@newSales,
	ISNULL(@oldSales,0),
	GETDATE(),
    SUSER_SNAME()
)


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[s3_dw_save_weather_data]
	@dateKey INT,
	@airportCode VARCHAR(10),
	@meanTemperature VARCHAR(50),
	@minTemperature VARCHAR(50),
	@maxTemperature VARCHAR(50),
	@precipitation VARCHAR(50),
	@snowfall VARCHAR(50),
	@events VARCHAR(50)

AS

-- determine which stores are assigned to this airport code
SELECT DISTINCT 
	store_key 
INTO 
	#temp
FROM
	store_dim
WHERE
	weather_airport_code = @airportCode

-- delete any existing data
DELETE weather_history WHERE
	date_key = @dateKey
	AND weather_airport_code = @airportCode
	AND store_key IN (SELECT DISTINCT store_key FROM #temp)
	
-- insert the new data
INSERT weather_history SELECT
	t.store_key,
	@dateKey,
	@airportCode,
	@meanTemperature,
	@minTemperature,
	@maxTemperature,
	@precipitation,
	@snowfall,
	@events
FROM #temp t


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[s3_dw_validate_sales]
    @reportDate DATETIME = NULL
AS

DECLARE @tlogDateKey INT

IF @reportDate IS NULL BEGIN
    DECLARE @yesterday DATETIME
    SELECT @yesterday = CONVERT(VARCHAR, GETDATE(), 101)
    SELECT @yesterday = DATEADD(dd, -1, @yesterday)
    SELECT @tlogDateKey = dbo.fn_DateToDateKey(@yesterday)
END ELSE BEGIN
    SELECT @tlogDateKey = dbo.fn_DateToDateKey(@reportDate)
END

DECLARE @temp TABLE (
    department_key int,
    department_name varchar(50),
    subdepartment_key int,
    subdepartment_name varchar(50),
    store_key int,
    tlog_date_key int,
    sales money,
    pos_sales money
)

SET NOCOUNT ON

INSERT @temp SELECT        
    p.department_key,
    p.department_name,
    p.subdepartment_key,
    p.subdepartment_name,
    s.store_key, 
    th.tlog_date_key,
    SUM(s.sales_dollar_amount) AS sales,
    0 as pos_sales
FROM            
    daily_sales_fact s 
INNER JOIN product_dim p ON 
    p.product_key = s.product_key
INNER JOIN tlog_history th ON
    th.tlog_file_key = s.tlog_file_key
INNER JOIN date_dim d ON 
    -- use this to query on logical tlog date (i.e. store-close to store-close)
    d.date_key = th.tlog_date_key

    --   use this to query on actualy transaction ring date   
    -- d.date_key = s.trans_date_key 
WHERE        
    -- use this to query on logical tlog date (i.e. store-close to store-close)
    (th.tlog_date_key = @tlogDateKey)

    -- use this to query on actualy transaction ring date   
    -- (s.trans_date_key = @effDateKey)
    AND p.department_key <> 7
    AND p.subdepartment_key NOT IN (88, 89)
    AND p.product_type_code NOT IN ('5', '6', '7', '8', '9')
-- this is to match other rollup sprocs 2005-03-21
--    AND p.product_type_code NOT IN ('4', '5', '6', '7', '8', '9')
GROUP BY 
    p.department_key,
    p.department_name, 
    p.subdepartment_key,
    p.subdepartment_name, 
    s.store_key, 
    th.tlog_date_key


SET NOCOUNT OFF
SELECT
    dd.calendar_date,
    t.store_key,
    t.department_key,
    t.department_name,
    t.subdepartment_key,
    t.subdepartment_name,
    t.sales,
    ISNULL(p.amt_sales - p.amt_cancel - p.amt_refund - p.amt_store_coupons, 0) as pos_sales,
    t.sales - ISNULL(p.amt_sales - p.amt_cancel - p.amt_refund - p.amt_store_coupons, 0) AS delta,
    CASE 
        WHEN p.amt_sales - p.amt_cancel - p.amt_refund - p.amt_store_coupons = t.sales  THEN ''
        ELSE '** ERROR **'
    END AS delta_msg
FROM
    @temp t
LEFT OUTER JOIN pos_subdepartment_totals p ON
    p.store_key = t.store_key
    AND p.tlog_date_key = t.tlog_date_key
    ANd p.subdepartment_key = t.subdepartment_key
INNER JOIN date_dim dd ON
    dd.date_key = t.tlog_date_key
WHERE
    t.sales - ISNULL(p.amt_sales - p.amt_cancel - p.amt_refund - p.amt_store_coupons, 0) <> 0
ORDER BY 
    t.store_key, 
    t.department_key,
    t.subdepartment_key


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE       PROCEDURE [dbo].[s3_dw_wtd_qtd_ytd_subdepartment] 
	@year INT
	,@week INT
	,@group VARCHAR(255)
	,@storeKey INT = NULL
AS

SET NOCOUNT ON

DECLARE @wkBeginDateKey INT
DECLARE @wkEndDateKey INT
SELECT
	@wkBeginDateKey = MIN(date_key),
	@wkEndDateKey = MAX(date_key)
FROM
	date_dim
WHERE
	sales_year = @year
	and sales_week = @week

-- get stores to report on
DECLARE @stores TABLE (
	store_key INT
)
IF @storeKey IS NOT NULL BEGIN
	INSERT INTO @stores values (@storeKey)
END ELSE BEGIN
	INSERT INTO @stores SELECT store_key FROM store_dim
END

--
-- week to date
--
DECLARE @tempWeek TABLE (
	sort_key int,
	department_key int,
	subdepartment_key int,
	store_key int,
	short_name varchar(255),
	wk_sales_dollar_amount money,
	wk_item_count int,
	wk_customer_count int,
	wk_avg_cust_sale money,
	wk_avg_cust_items money,
	wk_avg_item_price money,
	wk_dist money
)


INSERT @tempWeek SELECT
	dd.sort_key,
	dd.department_key,
	sds.subdepartment_key,
	sds.store_key,
	store.short_name,
	SUM(sds.sales_dollar_amount) wk_sales_dollar_amount,
	SUM(sds.item_count) AS wk_item_count,
	SUM(sds.customer_count) AS wk_customer_count,
	CASE
		WHEN SUM(sds.customer_count) <> 0 THEN SUM(sds.sales_dollar_amount) / SUM(sds.customer_count)
		ELSE 0
	END AS wk_avg_cust_sale,
	CASE
		WHEN SUM(sds.customer_count) <> 0 THEN SUM(sds.item_count) / CONVERT(MONEY,SUM(sds.customer_count))
		ELSE 0
	END AS wk_avg_cust_items,
	CASE
		WHEN SUM(sds.item_count) <> 0 THEN SUM(sds.sales_dollar_amount) / SUM(sds.item_count)
		ELSE 0
	END AS wk_avg_item_price,
	0 as wk_dist
FROM
	daily_subdepartment_sales sds
INNER JOIN subdepartment_dim sd ON
	sd.subdepartment_key = sds.subdepartment_key
INNER JOIN department_dim dd ON
	dd.department_key = sd.department_key 
INNER JOIN date_dim da ON
	da.date_key = sds.tlog_date_key
INNER JOIN store_dim store ON
	store.store_key = sds.store_key
INNER JOIN @stores s ON
	s.store_key = store.store_key
WHERE
	da.sales_year = @year
	and da.sales_week = @week
	and dd.major_grouping = @group
GROUP BY
	dd.sort_key,
	dd.department_key,
	sds.subdepartment_key,
	sds.store_key,
	store.short_name

DECLARE @totals TABLE (
	store_key INT,
	total MONEY
)
INSERT @totals SELECT
	store_key,
	SUM(wk_sales_dollar_amount)
FROM
	@tempWeek
GROUP BY
	store_key

UPDATE tw SET 
	wk_dist = wk_sales_dollar_amount / totals.total * 100
FROM
	@tempWeek tw
INNER JOIN @totals totals ON
	totals.store_key = tw.store_key


--
-- quarter to date
--
DECLARE @currQtr VARCHAR(3)
DECLARE @qtrBeginDateKey INT
DECLARE @qtrEndDateKey INT
SELECT @currQtr = sales_quarter FROM date_dim da1 WHERE da1.sales_year = @year and sales_week = @week
-- SELECT
-- 	@qtrBeginDateKey = MIN(date_key),
-- 	@qtrEndDateKey = MAX(date_key)
-- FROM
-- 	date_dim
-- WHERE
-- 	sales_year = @year
-- 	and sales_quarter = @currQtr

DECLARE @tempQtr TABLE (
	sort_key int,
	department_key int,
	subdepartment_key int,
	store_key int,
	short_name varchar(255),
	qtr_sales_dollar_amount money,
	qtr_item_count int,
	qtr_customer_count int,
	qtr_avg_cust_sale money,
	qtr_avg_cust_items money,
	qtr_avg_item_price money,
	qtr_dist money
)

INSERT @tempQtr SELECT
	dd.sort_key,
	dd.department_key,
	sds.subdepartment_key,
	sds.store_key,
	store.short_name,
	SUM(sds.sales_dollar_amount) qtr_sales_dollar_amount,
	SUM(sds.item_count) AS qtr_item_count,
	SUM(sds.customer_count) AS qtr_customer_count,
	CASE
		WHEN SUM(sds.customer_count) <> 0 THEN SUM(sds.sales_dollar_amount) / SUM(sds.customer_count)
		ELSE 0
	END AS qtr_avg_cust_sale,
	CASE
		WHEN SUM(sds.customer_count) <> 0 THEN SUM(sds.item_count) / CONVERT(MONEY, SUM(sds.customer_count))
		ELSE 0
	END AS qtr_avg_cust_items,
	CASE
		WHEN SUM(sds.item_count) <> 0 THEN SUM(sds.sales_dollar_amount) / SUM(sds.item_count)
		ELSE 0
	END AS qtr_avg_item_price,
	0 AS qtr_dist
FROM
	daily_subdepartment_sales sds
INNER JOIN subdepartment_dim sd ON
	sd.subdepartment_key = sds.subdepartment_key
INNER JOIN department_dim dd ON
	dd.department_key = sd.department_key 
INNER JOIN date_dim da ON
	da.date_key = sds.tlog_date_key
INNER JOIN store_dim store ON
	store.store_key = sds.store_key
INNER JOIN @stores s ON
	s.store_key = store.store_key
WHERE
	da.sales_year = @year
	and da.sales_quarter = @currQtr
	and dd.major_grouping = @group
	and sds.tlog_date_key <= @wkEndDateKey
GROUP BY
	dd.sort_key,
	dd.department_key,
	sds.subdepartment_key,
	sds.store_key,
	store.short_name

DELETE FROM @totals
INSERT @totals SELECT
	store_key,
	SUM(qtr_sales_dollar_amount)
FROM
	@tempQtr
GROUP BY
	store_key

UPDATE tq SET 
	qtr_dist = qtr_sales_dollar_amount / totals.total * 100
FROM
	@tempQtr tq
INNER JOIN @totals totals ON
	totals.store_key = tq.store_key


--
-- year to date
--
DECLARE @tempYr TABLE (
	sort_key int,
	department_key int,
	subdepartment_key int,
	store_key int,
	short_name varchar(255),
	yr_sales_dollar_amount money,
	yr_item_count int,
	yr_customer_count int,
	yr_avg_cust_sale money,
	yr_avg_cust_items money,
	yr_avg_item_price money,
	yr_dist money
)
INSERT @tempYr SELECT
	dd.sort_key,
	dd.department_key,
	sds.subdepartment_key,
	sds.store_key,
	store.short_name,
	SUM(sds.sales_dollar_amount) yr_sales_dollar_amount,
	SUM(sds.item_count) AS yr_item_count,
	SUM(sds.customer_count) AS yr_customer_count,
	CASE
		WHEN SUM(sds.customer_count) <> 0 THEN SUM(sds.sales_dollar_amount) / SUM(sds.customer_count)
		ELSE 0
	END AS yr_avg_cust_sale,
	CASE
		WHEN SUM(sds.customer_count) <> 0 THEN SUM(sds.item_count) / CONVERT(MONEY,SUM(sds.customer_count))
		ELSE 0
	END AS yr_avg_cust_items,
	CASE
		WHEN SUM(sds.item_count) <> 0 THEN SUM(sds.sales_dollar_amount) / SUM(sds.item_count)
		ELSE 0
	END AS yr_avg_item_price,
	0 AS yr_dist
FROM
	daily_subdepartment_sales sds
INNER JOIN subdepartment_dim sd ON
	sd.subdepartment_key = sds.subdepartment_key
INNER JOIN department_dim dd ON
	dd.department_key = sd.department_key 
INNER JOIN date_dim da ON
	da.date_key = sds.tlog_date_key
INNER JOIN store_dim store ON
	store.store_key = sds.store_key
INNER JOIN @stores s ON
	s.store_key = store.store_key
WHERE
	da.sales_year = @year
	and dd.major_grouping = @group
	and sds.tlog_date_key <= @wkEndDateKey
GROUP BY
	dd.sort_key,
	dd.department_key,
	sds.subdepartment_key,
	sds.store_key,
	store.short_name

DELETE FROM @totals
INSERT @totals SELECT
	store_key,
	SUM(yr_sales_dollar_amount)
FROM
	@tempYr
GROUP BY
	store_key

UPDATE ty SET 
	yr_dist = yr_sales_dollar_amount / totals.total * 100
FROM
	@tempYr ty
INNER JOIN @totals totals ON
	totals.store_key = ty.store_key


SET NOCOUNT OFF
SELECT
	d.department_name,
	sd.subdepartment_name,
	CONVERT(VARCHAR,d.department_key) + ' ' + LTRIM(RTRIM(d.department_name)) as department_key_name,
	CONVERT(VARCHAR,sd.subdepartment_key) + ' ' + LTRIM(RTRIM(sd.subdepartment_name)) as subdepartment_key_name,
	tw.*,
	tq.*,
	ty.*
FROM
	@tempWeek tw
INNER JOIN @tempQtr tq ON
	tq.subdepartment_key = tw.subdepartment_key
	AND tq.store_key = tw.store_key
INNER JOIN @tempYr ty ON
	ty.subdepartment_key = tw.subdepartment_key
	AND ty.store_key = tw.store_key
INNER JOIN subdepartment_dim sd ON
	sd.subdepartment_key = tw.subdepartment_key
INNER JOIN department_dim d ON
	d.department_key = tw.department_key
ORDER BY
	tw.sort_key,
	tw.subdepartment_key,
	tw.store_key


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[s3_ItemMovementByDateRange] 
	@upc char(13), 
	@startDate DATETIME = NULL,
    @endDate DATETIME = NULL
AS

DECLARE @startDateInt int
DECLARE @endDateInt int

SELECT @startDateInt = dbo.fn_DateToDateKey(@startDate)

IF (@endDate IS NULL) BEGIN
    SELECT @endDateInt = @startDateInt + 31
END ELSE BEGIN
    SELECT @endDateInt = dbo.fn_DateToDateKey(@endDate)
END



SELECT 
    dd.calendar_date, 
    stores.store_id, 
    p.upc, 
    p.brand_name, 
    p.item_description, 
    p.department_key, 
    p.department_name, 
    s.sales_quantity, 
    s.sales_dollar_amount 
FROM daily_sales_fact s 
INNER JOIN date_dim dd ON 
    dd.date_key = s.trans_date_key 
LEFT OUTER JOIN store_dim stores ON 
    stores.store_key = s.store_key 
INNER JOIN product_dim p ON 
    p.product_key = s.product_key 
WHERE 
    p.upc=@upc 
    AND s.trans_date_key >= @startDateInt
    AND s.trans_date_key <= @endDateInt
ORDER BY 
    s.trans_date_key, 
    s.store_key


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROCEDURE [dbo].[s3_rpt_DepartmentSalesByDayByStore] 
    @effDate DATETIME
AS

DECLARE @effDateKey INT
SELECT @effDateKey = dbo.fn_DateToDateKey(@effDate)


SELECT        
    p.department_key,
    p.department_name, 
    p.subdepartment_key,
    p.subdepartment_name,
    s.store_key, 
    d.calendar_date, 
    SUM(s.sales_dollar_amount) AS sales
FROM            
    daily_sales_fact s 
INNER JOIN product_dim p ON 
    p.product_key = s.product_key
INNER JOIN tlog_history th ON
    th.tlog_file_key = s.tlog_file_key
INNER JOIN date_dim d ON 
-- use this to query on logical tlog date (i.e. store-close to store-close)
    d.date_key = th.tlog_date_key
--   use this to query on actualy transaction ring date   d.date_key = s.trans_date_key 
WHERE        
-- use this to query on logical tlog date (i.e. store-close to store-close)
    (th.tlog_date_key = @effDateKey)
-- use this to query on actualy transaction ring date   (s.trans_date_key = @effDateKey)
    AND p.department_key <> 7
    AND p.product_type_code NOT IN ('4', '5', '6', '7', '8', '9')
GROUP BY 
    p.department_key,
    p.department_name,
    p.subdepartment_key,
    p.subdepartment_name, 
    s.store_key, 
    d.calendar_date
ORDER BY 
    p.department_key, 
    p.subdepartment_key,
    s.store_key


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE       PROCEDURE [dbo].[s3_rpt_DepartmentSalesByHourByStore]
    @startDate DATETIME,
    @stopDate DATETIME
AS

DECLARE @startDateKey INT
SELECT @startDateKey = dbo.fn_DateToDateKey(@startDate)
DECLARE @stopDateKey INT
SELECT @stopDateKey = dbo.fn_DateToDateKey(@stopDate)


SELECT 
    store_key,
    department_key,
    t.hour_of_day,
    CASE 
        when t.hour_of_day = 22 then 0
        when t.hour_of_day = 23 then 1
        when t.hour_of_day = 0 then 2
        when t.hour_of_day = 1 then 3
        when t.hour_of_day = 2 then 4
        when t.hour_of_day = 3 then 5
        when t.hour_of_day = 4 then 6
        when t.hour_of_day = 5 then 7
        when t.hour_of_day = 6 then 8
        when t.hour_of_day = 7 then 9
        when t.hour_of_day = 8 then 10
    END AS sort_hour,
    SUM(sales_dollar_amount) AS sales_dollar_amount
FROM hourly_department_sales_fact s
INNER join time_dim t on
    t.time_key = s.trans_time_key
WHERE
    /*(t.hour_of_day between 22 and 24) OR */(t.hour_of_day between 0 and 5)
    AND s.trans_date_key between @startDateKey AND @stopDateKey
--    AND s.department_key <> 7

GROUP BY
    s.store_key,
    s.department_key,
    t.hour_of_day


-- 
-- SELECT        
--     p.department_key,
--     p.department_name, 
--     p.subdepartment_key,
--     p.subdepartment_name,
--     s.store_key, 
--     d.calendar_date, 
--     SUM(s.sales_dollar_amount) AS sales
-- FROM            
--     daily_sales_fact s 
-- INNER JOIN product_dim p ON 
--     p.product_key = s.product_key
-- INNER JOIN tlog_history th ON
--     th.tlog_file_key = s.tlog_file_key
-- INNER JOIN date_dim d ON 
-- -- use this to query on logical tlog date (i.e. store-close to store-close)
--     d.date_key = th.tlog_date_key
-- --   use this to query on actualy transaction ring date   d.date_key = s.trans_date_key 
-- WHERE        
-- -- use this to query on logical tlog date (i.e. store-close to store-close)
--     (th.tlog_date_key = @effDateKey)
-- -- use this to query on actualy transaction ring date   (s.trans_date_key = @effDateKey)
--     AND p.department_key <> 7
--     AND p.product_type_code NOT IN ('4', '5', '6', '7', '8', '9')
-- GROUP BY 
--     p.department_key,
--     p.department_name,
--     p.subdepartment_key,
--     p.subdepartment_name, 
--     s.store_key, 
--     d.calendar_date
-- ORDER BY 
--     p.department_key, 
--     p.subdepartment_key,
--     s.store_key


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[s3_rpt_ItemsSoldNotInDatabase]

@startDate DATETIME,
@stopDate DATETIME

AS

DECLARE @startDateKey INT
DECLARE @stopDateKey INT

SELECT @startDateKey = dbo.fn_DateToDateKey(@startDate)
SELECT @stopDateKey = dbo.fn_DateToDateKey(@stopDate)

SELECT        
	d.calendar_date,
	h.store_key, 
	upc,
	sales_quantity,
	sales_dollar_amount 
FROM
	item_not_in_db_history h
INNER JOIN tlog_history th ON
	th.tlog_file_key = h.tlog_file_key
INNER JOIN date_dim d ON
	d.date_key = th.tlog_date_key
WHERE
	th.tlog_date_key BETWEEN @startDateKey AND @stopDateKey
	AND upc NOT LIKE '005%'
	AND upc NOT LIKE '09%'


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[s3_rpt_SellingDepartmentComparison] 
    @startDate DATETIME,
    @stopDate DATETIME
AS

DECLARE @startDateKey INT
DECLARE @stopDateKey INT

SELECT @startDateKey = dbo.fn_DateToDateKey(@startDate)
SELECT @stopDateKey = dbo.fn_DateToDateKey(@stopDate)

select 
    dd.calendar_date,
    h.store_key,
    p.product_type_code,
    p.product_type_desc,
    h.upc,
    p.brand_name,
    p.item_description,
    h.occurrence_count,
    h.pos_department,
    sd1.subdepartment_name as pos_subdepartment_name,
    h.host_department,
    sd2.subdepartment_name as host_subdepartment_name
FROM 
    item_selling_dept_history h
INNER JOIN product_dim p ON
    p.upc = h.upc 
INNER JOIN tlog_history th ON
    th.tlog_date_key BETWEEN @startDateKey AND @stopDateKey
    AND h.tlog_file_key = th.tlog_file_key
INNER JOIN date_dim dd ON
    dd.date_key = th.tlog_date_key
INNER JOIN subdepartment_dim sd1 ON
    sd1.subdepartment_key = h.pos_department
INNER JOIN subdepartment_dim sd2 ON
    sd2.subdepartment_key = h.host_department

WHERE 
    pos_department <> host_department 
    and host_department <> -1    
    and p.product_type_code <> '1'
ORDER BY
    th.tlog_date_key,
    h.store_key,
    h.upc


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SelectOpeningStoresByOpeningDate]
AS

SELECT DISTINCT
	opening_date_key
INTO 
	#temp
FROM
	store_dim

SELECT
	da.calendar_date
	,t.opening_date_key
	,(SELECT COUNT(store_key) FROM store_dim s WHERE s.opening_date_key <= t.opening_date_key) AS num_stores
FROM
	#temp t
INNER JOIN date_dim da ON
	da.date_key = t.opening_date_key
ORDER BY
	da.date_key desc


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROCEDURE [dbo].[SelectStoreBreakdownByDepartment]
    @departmentKey INT,
    @salesYear INT,
    @salesWeek INT,
	@sameStoresDateKey INT = NULL
AS


SET NOCOUNT ON
DECLARE @depts TABLE (department_key INT)
IF @departmentKey = -1 BEGIN
    INSERT @depts SELECT department_key FROM department_dim WHERE major_grouping = 'Food' AND is_active = 1
END ELSE BEGIN
    INSERT @depts SELECT @departmentKey
END

DECLARE @stores TABLE (store_key INT)
IF @sameStoresDateKey = NULL OR @sameStoresDateKey = 0 BEGIN
    INSERT @stores SELECT store_key FROM store_dim
END ELSE BEGIN
    INSERT @stores SELECT store_key FROM store_dim WHERE opening_date_key <= @sameStoresDateKey
END

-- figure out what group we're working with (food, rx, misc)
DECLARE @majorGrouping VARCHAR(255)
IF @departmentKey <> -1 BEGIN
	SELECT 
	    @majorGrouping = major_grouping 
	FROM 
	    department_dim d 
	WHERE 
	    d.department_key = @departmentKey
END ELSE BEGIN
	SELECT @majorGrouping = 'Food'
END

SET NOCOUNT OFF

SELECT
    RTRIM(LTRIM(da.date_month_text)) as column_name
	,RTRIM(LTRIM(da.day_of_week)) as day_of_week
    ,day_in_sales_week
    ,s.store_key
	,s.department_key
    ,sales_dollar_amount
    ,item_count
    ,customer_count
    ,CONVERT(NUMERIC(18,4), CASE 
        WHEN item_count = 0 THEN 0
        ELSE sales_dollar_amount / item_count
    END) AS avg_item_price
    ,CONVERT(NUMERIC(18,4), CASE
        WHEN customer_count=0 THEN 0
        ELSE sales_dollar_amount / customer_count
    END) AS avg_customer_sale
FROM
    daily_department_sales s
INNER JOIN @depts depts ON
    depts.department_key = s.department_key
INNER JOIN date_dim da ON
    da.date_key = s.tlog_date_key
INNER JOIN department_dim d ON
    d.department_key = depts.department_key
    AND d.is_active = 1
INNER JOIN @stores st ON
	st.store_key = s.store_key
WHERE
    da.sales_year = @salesYear
    AND da.sales_week = @salesWeek
ORDER BY 
    da.date_key,
    s.store_key

    
-- also return total store sales in same format - used
-- to compute distribution 
SET NOCOUNT ON
SELECT
    RTRIM(LTRIM(da.date_month_text)) as column_name
	,RTRIM(LTRIM(da.day_of_week)) AS day_of_week
	,day_in_sales_week
    ,da.date_key
    ,s.store_key
    ,sum(sales_dollar_amount) as sales_dollar_amount
    ,0 as item_count
    ,0 as customer_count
    ,CONVERT(NUMERIC(18,4),0) as avg_item_price
    ,CONVERT(NUMERIC(18,4),0) as avg_customer_sale
INTO 
	#temp
FROM
    daily_subdepartment_sales s
INNER JOIN date_dim da ON
    da.date_key = s.tlog_date_key
INNER JOIN subdepartment_dim sd ON
    sd.subdepartment_key = s.subdepartment_key
INNER JOIN department_dim d ON
    d.department_key = sd.department_key
    AND d.is_active = 1
    AND d.major_grouping = @majorGrouping
INNER JOIN @stores st ON
	st.store_key = s.store_key
WHERE
    da.sales_year = @salesYear
    AND da.sales_week = @salesWeek
GROUP BY 
    RTRIM(LTRIM(da.date_month_text))
	,RTRIM(LTRIM(da.day_of_week))
	,day_in_sales_week
    ,da.date_key
    ,s.store_key

-- pull customer counts into #temp
-- pull item counts into #temp
UPDATE #temp SET
    #temp.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc
        WHERE 
            dgc.store_key = #temp.store_key 
            AND dgc.tlog_date_key = #temp.date_key
            AND dgc.major_grouping = @majorGrouping),0),
    #temp.item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
        WHERE 
            dgc.store_key = #temp.store_key 
            AND dgc.tlog_date_key = #temp.date_key
            AND dgc.major_grouping = @majorGrouping), 0)

-- compute $/item and $/cust
UPDATE #temp SET avg_item_price = sales_dollar_amount / item_count WHERE item_count <> 0
UPDATE #temp SET avg_customer_sale = sales_dollar_amount / customer_count WHERE customer_count <> 0


-- now return the data.
SET NOCOUNT OFF
SELECT * FROM #temp


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Stored procedure
CREATE PROCEDURE [dbo].[SelectStoreBreakdownByGroup]
    @majorGrouping VARCHAR(255),
    @salesYear INT,
    @salesWeek INT,
	@storeKey INT = NULL,
	@sameStoresDateKey INT = NULL

AS

SET NOCOUNT ON

DECLARE @stores TABLE (store_key INT)
IF @storeKey IS NOT NULL BEGIN
	INSERT INTO @stores SELECT @storeKey
END ELSE BEGIN
	IF @sameStoresDateKey = NULL OR @sameStoresDateKey = 0 BEGIN
	    INSERT @stores SELECT store_key FROM store_dim
	END ELSE BEGIN
	    INSERT @stores SELECT store_key FROM store_dim WHERE opening_date_key <= @sameStoresDateKey
	END
END


SET NOCOUNT OFF

SELECT
    RTRIM(LTRIM(da.date_month_text)) as column_name
	,RTRIM(LTRIM(da.day_of_week)) as day_of_week
	,da.day_in_sales_week
    ,s.store_key
    ,sales_dollar_amount
    ,c.item_count
    ,c.customer_count
    ,CASE 
        WHEN c.item_count = 0 THEN 0
        ELSE sales_dollar_amount / item_count
    END AS avg_item_price
    ,CASE
        WHEN c.customer_count=0 THEN 0
        ELSE sales_dollar_amount / customer_count
    END AS avg_customer_sale
FROM
    daily_group_sales s
INNER JOIN date_dim da ON
    da.date_key = s.tlog_date_key
INNER JOIN daily_group_counts c ON
	c.store_key = s.store_key
	AND c.tlog_file_key = s.tlog_file_key
	AND c.major_grouping = @majorGrouping
INNER JOIN @stores stores ON
	stores.store_key = s.store_key
WHERE
    da.sales_year = @salesYear
    AND da.sales_week = @salesWeek
    AND s.major_grouping = @majorGrouping
ORDER BY 
    da.date_key,
    s.store_key

SELECT
    RTRIM(LTRIM(da.date_month_text)) as column_name
	,RTRIM(LTRIM(da.day_of_week)) as day_of_week
	,da.day_in_sales_week
    ,s.store_key
    ,da.date_key
    ,sales_dollar_amount
    ,c.item_count
    ,c.customer_count
    ,CASE 
        WHEN c.item_count = 0 THEN 0
        ELSE sales_dollar_amount / item_count
    END AS avg_item_price
    ,CASE
        WHEN c.customer_count=0 THEN 0
        ELSE sales_dollar_amount / customer_count
    END AS avg_customer_sale
FROM
    daily_group_sales s
INNER JOIN date_dim da ON
    da.date_key = s.tlog_date_key
INNER JOIN daily_group_counts c ON
	c.store_key = s.store_key
	AND c.tlog_file_key = s.tlog_file_key
	AND c.major_grouping = @majorGrouping
INNER JOIN @stores stores ON
	stores.store_key = s.store_key
WHERE
    da.sales_year = @salesYear
    AND da.sales_week = @salesWeek
    AND s.major_grouping = @majorGrouping
ORDER BY 
    da.date_key,
    s.store_key

SET NOCOUNT ON


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Stored procedure
CREATE    PROCEDURE [dbo].[SelectStoreBreakdownBySubdepartment]
    @subdepartmentKey INT,
    @salesYear INT,
    @salesWeek INT,
	@storeKey INT = NULL,
	@sameStoresDateKey INT = NULL
AS


SET NOCOUNT ON

DECLARE @stores TABLE (store_key INT)
IF @storeKey IS NOT NULL BEGIN
	INSERT INTO @stores SELECT @storeKey
END ELSE BEGIN
	IF @sameStoresDateKey = NULL OR @sameStoresDateKey = 0 BEGIN
	    INSERT @stores SELECT store_key FROM store_dim
	END ELSE BEGIN
	    INSERT @stores SELECT store_key FROM store_dim WHERE opening_date_key <= @sameStoresDateKey
	END
END

DECLARE @subdepts TABLE (subdepartment_key INT)
DECLARE @majorGrouping VARCHAR(255)
INSERT @subdepts SELECT @subdepartmentKey
select @majorGrouping = major_grouping from department_dim d inner join subdepartment_dim sd on sd.department_key = d.department_key where sd.subdepartment_key = @subdepartmentKey
SET NOCOUNT OFF

SELECT
    RTRIM(LTRIM(da.date_month_text)) as column_name
	,RTRIM(LTRIM(da.day_of_week)) as day_of_week
	,da.day_in_sales_week
    ,s.store_key
    ,sales_dollar_amount
    ,item_count
    ,customer_count
    ,CASE 
        WHEN item_count = 0 THEN 0
        ELSE sales_dollar_amount / item_count
    END AS avg_item_price
    ,CASE
        WHEN customer_count=0 THEN 0
        ELSE sales_dollar_amount / customer_count
    END AS avg_customer_sale
FROM
    daily_subdepartment_sales s
INNER JOIN @subdepts subdepts ON
    subdepts.subdepartment_key = s.subdepartment_key
INNER JOIN date_dim da ON
    da.date_key = s.tlog_date_key
INNER JOIN subdepartment_dim sd ON
    sd.subdepartment_key = subdepts.subdepartment_key
INNER JOIN department_dim d ON
    d.department_key = sd.department_key
    AND d.is_active = 1
INNER JOIN @stores stores ON
	stores.store_key = s.store_key
WHERE
    da.sales_year = @salesYear
    AND da.sales_week = @salesWeek
ORDER BY 
    da.date_key,
    s.store_key

SET NOCOUNT ON

-- also return total store sales in same format 
-- this is used for computing distribution 
SELECT
	RTRIM(LTRIM(da.date_month_text)) as column_name
	,RTRIM(da.day_of_week) AS day_of_week
	,day_in_sales_week
    ,da.date_key
    ,s.store_key
    ,sum(sales_dollar_amount) as sales_dollar_amount
    ,0 as item_count
    ,0 as customer_count
    ,CONVERT(NUMERIC(18,2),0) as avg_item_price
    ,CONVERT(NUMERIC(18,2),0) as avg_customer_sale
INTO #temp
FROM
    daily_subdepartment_sales s
INNER JOIN date_dim da ON
    da.date_key = s.tlog_date_key
INNER JOIN subdepartment_dim sd ON
    sd.subdepartment_key = s.subdepartment_key
INNER JOIN department_dim d ON
    d.department_key = sd.department_key
    AND d.is_active = 1
INNER JOIN @stores stores ON
	stores.store_key = s.store_key
WHERE
    da.sales_year = @salesYear
    AND da.sales_week = @salesWeek
GROUP BY 
    RTRIM(LTRIM(da.date_month_text))
	,RTRIM(da.day_of_week)
	,day_in_sales_week
    ,da.date_key
    ,s.store_key

-- pull customer counts into #temp
-- pull item counts into #temp
UPDATE #temp SET
    #temp.customer_count = ISNULL((SELECT SUM(customer_count) FROM daily_group_counts dgc
        WHERE 
            dgc.store_key = #temp.store_key 
            AND dgc.tlog_date_key = #temp.date_key
            AND dgc.major_grouping = @majorGrouping),0),
    #temp.item_count = ISNULL((SELECT SUM(item_count) FROM daily_group_counts dgc 
        WHERE 
            dgc.store_key = #temp.store_key 
            AND dgc.tlog_date_key = #temp.date_key
            AND dgc.major_grouping = @majorGrouping), 0)

UPDATE #temp SET avg_item_price = sales_dollar_amount / item_count WHERE item_count <> 0
UPDATE #temp SET avg_customer_sale = sales_dollar_amount / customer_count WHERE customer_count <> 0

SET NOCOUNT OFF

-- now return the data.
SELECT * FROM #temp


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[SelectSubdepartmentSalesWeekly]
    @salesWeek INT,
    @salesYear INT,
    @storeKey INT = NULL,
    @subdepartmentKey INT
AS

SET NOCOUNT ON

-- figure out the prior 52 week based on the dates 
DECLARE @endAbsoluteWeek INT
DECLARE @startAbsoluteWeek INT
SET @endAbsoluteWeek = (select TOP 1 absolute_week from date_dim where sales_year = @salesYear AND sales_week = @salesWeek)
SET @startAbsoluteWeek = @endAbsoluteWeek - 51

-- filter for 1 store or all stores
DECLARE @stores TABLE (store_key INT)
IF @storeKey IS NULL BEGIN
    INSERT @stores SELECT store_key FROM store_dim
END ELSE BEGIN
    INSERT @stores SELECT @storeKey
END

SELECT
	da.sales_year,
	da.sales_week,
    ISNULL(SUM(sales_dollar_amount),0) AS sales_dollar_amount,
    ISNULL(SUM(customer_count),0) AS customer_count,
    ISNULL(SUM(item_count),0) AS item_count,
    CONVERT(DECIMAL(18,2), 0) AS avg_item_price,
    CONVERT(DECIMAL(18,2), 0) AS avg_customer_sale,
	CONVERT(DECIMAL(18,2), 0) AS distro,
	CONVERT(DECIMAL(18,2), 0) AS group_sales_dollar_amount
INTO #temp
FROM date_dim da
LEFT OUTER JOIN daily_subdepartment_sales s ON
    da.date_key = s.tlog_date_key
    AND s.subdepartment_key = @subdepartmentKey
    AND s.store_key in (SELECT store_key FROM @stores)
WHERE
    da.absolute_week BETWEEN @startAbsoluteWeek AND @endAbsoluteWeek
GROUP BY
    da.sales_year,
	da.sales_week

-- compute averages
UPDATE #temp SET avg_item_price = sales_dollar_amount / item_count WHERE item_count <> 0
UPDATE #temp SET avg_customer_sale = sales_dollar_amount / customer_count WHERE customer_count <> 0

-- compute distro for group
DECLARE @majorGrouping VARCHAR(20)
SELECT 
	@majorGrouping = d.major_grouping 
FROM 
	subdepartment_dim sd
INNER JOIN department_dim d ON
	d.department_key = sd.department_key
WHERE 
	subdepartment_key = @subdepartmentKey

-- this gets weekly group sales total
SELECT 
	da.sales_year,
	da.sales_week,
	SUM(sales_dollar_amount) AS group_sales_dollar_amount
INTO #temp_group_sales
FROM date_dim da
LEFT OUTER JOIN daily_subdepartment_sales s ON
    da.date_key = s.tlog_date_key
    AND s.store_key in (SELECT store_key FROM @stores)
INNER JOIN subdepartment_dim sd ON
	sd.subdepartment_key = s.subdepartment_key
INNER JOIN department_dim d ON
	d.department_key = sd.department_key
WHERE
    da.absolute_week BETWEEN @startAbsoluteWeek AND @endAbsoluteWeek
	AND d.major_grouping = @majorGrouping
GROUP BY
	da.sales_year,
	da.sales_week

UPDATE t SET 
	distro = sales_dollar_amount / gs.group_sales_dollar_amount * 100,
	t.group_sales_dollar_amount = gs.group_sales_dollar_amount
FROM 
	#temp t
INNER JOIN #temp_group_sales gs ON
	gs.sales_year = t.sales_year
	AND gs.sales_week = t.sales_week
WHERE 
    gs.group_sales_dollar_amount <> 0

SET NOCOUNT OFF

SELECT 
	t.*,
	da.date_month_text,
	da.calendar_year	
FROM 
	#temp t
INNER JOIN date_dim da ON
	da.sales_year = t.sales_year
	AND da.sales_week = t.sales_week
	AND da.day_in_sales_week = 1
ORDER BY
	t.sales_year,
	t.sales_week


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SelectSubdepartmentSalesWeeklyMulti]
    @salesWeek INT,
    @salesYear INT,
    @storeKey INT = NULL,
    @subdepartmentKey INT
AS

-- find the absolute_week for the passed @salesWeek and @salesYear
DECLARE @year INT
DECLARE @week INT
DECLARE @absWeek INT
SELECT @absWeek = absolute_week FROM date_dim WHERE sales_week = @salesWeek AND sales_year = @salesyear

-- 104 weeks ago
SELECT @year = sales_year, @week = sales_week FROM date_dim WHERE absolute_week = @absWeek-52-52
EXEC SelectSubdepartmentSalesWeekly @week, @year, @storeKey, @subdepartmentKey

-- 52 weeks ago
SELECT @year = sales_year, @week = sales_week FROM date_dim WHERE absolute_week = @absWeek-52
EXEC SelectSubdepartmentSalesWeekly @week, @year, @storeKey, @subdepartmentKey

-- specified week
EXEC SelectSubdepartmentSalesWeekly @salesWeek, @salesYear, @storeKey, @subdepartmentKey


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









CREATE   PROCEDURE [dbo].[Tlog_ClearBeforeReload]
    @tlogFileKey INTEGER
AS

DELETE FROM daily_sales_fact WHERE tlog_file_key = @tlogFileKey
DELETE FROM item_not_in_db_history WHERE tlog_file_key = @tlogFileKey
DELETE FROM item_selling_dept_history WHERE tlog_file_key = @tlogFileKey
DELETE FROM hourly_department_sales_fact WHERE tlog_file_key = @tlogFileKey
DELETE FROM audit_not_on_file WHERE tlog_file_key = @tlogFileKey
DELETE FROM daily_subdepartment_sales WHERE tlog_file_key = @tlogFileKey
DELETE FROM daily_department_sales WHERE tlog_file_key = @tlogFileKey
DELETE FROM daily_total_store_counts WHERE tlog_file_key = @tlogFileKey
DELETE FROM daily_group_counts WHERE tlog_file_key = @tlogFileKey
DELETE FROM daily_group_sales WHERE tlog_file_key = @tlogFileKey
DELETE FROM daily_bucket_sales WHERE tlog_file_key = @tlogFileKey
DELETE FROM tlog_history WHERE tlog_file_key = @tlogFileKey
DELETE FROM iss45_member_promotion_fact WHERE tlog_file_key = @tlogFileKey


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Tlog_RollupBucket]
    @tlogFileKey INT,
    @tlogDateKey INT,
    @storeKey INT
AS

DECLARE @minDateKey INT
DECLARE @maxDateKey INT
SELECT
	@minDateKey = MIN(trans_date_key),
	@maxDateKey = MAX(trans_date_key) 
FROM
	daily_sales_fact WITH (NOLOCK)
WHERE
	tlog_file_key = @tlogFileKey

INSERT INTO daily_bucket_sales SELECT 
	th.tlog_date_key,
	s.store_key,
	p.subdepartment_key,
	s.pricing_bucket_key,
	s.tlog_file_key,
	sum(sales_dollar_amount) as sales_dollar_amount,
	sum(cost_dollar_amount) as cost_dollar_amount,
	sum(markdown_dollar_amount) as markdown_dollar_amount,
	sum(sales_quantity * regular_retail_unit_price) as sales_dollar_amount_at_regular_retail,
	SUM(CASE
			WHEN base_unit_cost = 0 THEN cost_dollar_amount
			ELSE sales_quantity * base_unit_cost
		END) as base_cost_dollar_amount
FROM
	daily_sales_fact s
INNER JOIN product_dim p WITH (NOLOCK) ON
	p.product_key = s.product_key
INNER JOIN tlog_history th WITH (NOLOCK) ON
	th.tlog_file_key = s.tlog_file_key
WHERE
	s.tlog_file_key = @tlogFileKey
	AND s.trans_date_key BETWEEN @minDateKey AND @maxDateKey
GROUP BY
	th.tlog_date_key,
	s.store_key,
	p.subdepartment_key,
	s.pricing_bucket_key,
	s.tlog_file_key


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Tlog_RollupDept]
    @tlogFileKey INT
    ,@tlogDateKey INT
    ,@storeKey INT
AS

DECLARE @minDateKey INT
DECLARE @maxDateKey INT
SELECT
	@minDateKey = MIN(trans_date_key),
	@maxDateKey = MAX(trans_date_key) 
FROM
	daily_sales_fact
WHERE
	tlog_file_key = @tlogFileKey

DELETE FROM temp_dept_rollup
INSERT INTO temp_dept_rollup SELECT 
    p.department_key,
    sum(ds.sales_dollar_amount) as sales_dollar_amount,
    sum(ds.cost_dollar_amount) as cost_dollar_amount,
    0 as customer_count,
    0 as item_count
FROM
    daily_sales_fact ds
INNER JOIN product_dim p ON
    ds.product_key = p.product_key
WHERE
    ds.tlog_file_key = @tlogFileKey
	AND ds.trans_date_key BETWEEN @minDateKey AND @maxDateKey
GROUP BY 
    p.department_key

UPDATE t SET 
    t.customer_count = cc.count_value
FROM temp_dept_rollup t
INNER JOIN temp_department_count cc ON
    cc.department_key = t.department_key
WHERE
    cc.count_type = 'C'

UPDATE t SET 
    t.item_count = ic.count_value
FROM temp_dept_rollup t
INNER JOIN temp_department_count ic ON
    ic.department_key = t.department_key
WHERE
    ic.count_type = 'I'

INSERT INTO daily_department_sales (
    tlog_date_key, 
    store_key, 
    department_key, 
    tlog_file_key,
    sales_dollar_amount, 
    cost_dollar_amount, 
    customer_count, 
    item_count)
SELECT 
    @tlogDateKey,
    @storeKey,
    t.department_key,
    @tlogFileKey,
    sales_dollar_amount, 
    cost_dollar_amount, 
    customer_count, 
    item_count
FROM
    temp_dept_rollup t


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[Tlog_RollupDeptGroup]
    @tlogFileKey INT
    ,@tlogDateKey INT
    ,@storeKey INT
AS

DECLARE @groups TABLE (
    major_grouping CHAR(10)
)
INSERT @groups SELECT DISTINCT major_grouping FROM temp_group_count

INSERT daily_group_counts SELECT
    @tlogDateKey AS tlog_date_key,
    @storeKey AS store_key,
    g.major_grouping,
    @tlogFileKey AS tlog_file_key,
    ISNULL(cc.count_value,0) AS customer_count,
    ISNULL(ci.count_value,0) AS item_count
FROM @groups g
LEFT OUTER JOIN temp_group_count cc ON
    cc.major_grouping = g.major_grouping
    AND cc.count_type = 'C'
LEFT OUTER JOIN temp_group_count ci ON
    ci.major_grouping = g.major_grouping
    AND ci.count_type = 'I'

INSERT INTO daily_group_sales SELECT
	da.date_key,
	dss.store_key,
	d.major_grouping,
	dss.tlog_file_key,
	SUM(dss.sales_dollar_amount) AS sales_dollar_amount
FROM dbo.daily_subdepartment_sales dss
INNER JOIN dbo.subdepartment_dim sd ON
    sd.subdepartment_key = dss.subdepartment_key
INNER JOIN dbo.department_dim d ON
    d.department_key = sd.department_key
INNER JOIN dbo.date_dim da ON
    da.date_key = dss.tlog_date_key
WHERE
	dss.tlog_file_key = @tlogFileKey
GROUP BY
	da.date_key,
	dss.store_key,
	d.major_grouping,
	dss.tlog_file_key


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Tlog_RollupSubdept]
    @tlogFileKey INT
    ,@tlogDateKey INT
    ,@storeKey INT
AS

DECLARE @minDateKey INT
DECLARE @maxDateKey INT
SELECT
	@minDateKey = MIN(trans_date_key),
	@maxDateKey = MAX(trans_date_key) 
FROM
	daily_sales_fact
WHERE
	tlog_file_key = @tlogFileKey

DELETE FROM temp_rollup
INSERT INTO temp_rollup SELECT 
    p.subdepartment_key,
    sum(ds.sales_dollar_amount) as sales_dollar_amount,
    sum(ds.cost_dollar_amount) as cost_dollar_amount,
    0 as customer_count,
    0 as item_count
from
    daily_sales_fact ds
INNER JOIN product_dim p ON
    ds.product_key = p.product_key
-- TODO: don't need for iss45, but IBM might need to exclude on product type    
WHERE
    ds.tlog_file_key = @tlogFileKey
	AND ds.trans_date_key BETWEEN @minDateKey AND @maxDateKey
GROUP BY 
    p.subdepartment_key

UPDATE t SET 
    t.customer_count = cc.count_value
FROM temp_rollup t
INNER JOIN temp_subdepartment_count cc ON
    cc.subdepartment_key = t.subdepartment_key
WHERE
    cc.count_type = 'C'

UPDATE t SET 
    t.item_count = ic.count_value
FROM temp_rollup t
INNER JOIN temp_subdepartment_count ic ON
    ic.subdepartment_key = t.subdepartment_key
WHERE
    ic.count_type = 'I'

INSERT INTO daily_subdepartment_sales (
    tlog_date_key, 
    store_key, 
    subdepartment_key, 
    tlog_file_key,
    sales_dollar_amount, 
    cost_dollar_amount, 
    customer_count, 
    item_count)
SELECT 
    @tlogDateKey,
    @storeKey,
    t.subdepartment_key,
    @tlogFileKey,
    sales_dollar_amount, 
    cost_dollar_amount, 
    customer_count, 
    item_count
FROM
    temp_rollup t


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Tlog_UpdateCosts]
    @tlogFileKey INT
	,@regRetailPriceBucket INT
AS

DECLARE @storeKey INT; SELECT @storeKey = store_key FROM tlog_history WHERE tlog_file_key = @tlogFileKey
DECLARE @tlogDateKey INT; SELECT @tlogDateKey = tlog_date_key FROM tlog_history WHERE tlog_file_key = @tlogFileKey
DECLARE @cutoffDate INT; SELECT @cutoffDate = date_key from date_dim where absolute_day = (SELECT absolute_day+1 FROM date_dim WHERE date_key = @tlogDateKey)

-- find min/max dates of transactions for this tlog
-- specifying these date ranges when querying daily_sales_fact will
-- help the sql query optimizer to speed things up becuase that
-- is the partitioning column
DECLARE @minDateKey INT
DECLARE @maxDateKey INT
SELECT 
	@minDateKey = MIN(trans_date_key),
	@maxDateKey = MAX(trans_date_key)
FROM
	daily_sales_fact
WHERE	
	tlog_file_key = @tlogFileKey

TRUNCATE TABLE tlog_temp_costs;
;WITH cte AS (
	SELECT
		date_key
		,product_key
		,store_key
		,lowest_unit_price
		,normal_unit_price
		,pricing_bucket_key
		,pri_supplier_key
		,base_unit_cost
		,ext_unit_cost
		,ROW_NUMBER() OVER (PARTITION BY CHECKSUM(product_key) ORDER BY date_key DESC) AS row_nmbr
	FROM
		prod_store_dim_history
	WHERE
		store_key = @storeKey
		AND date_key <= @cutoffDate
)
INSERT INTO tlog_temp_costs SELECT
    ds.tlog_file_key
    ,ds.store_key
    ,ds.trans_date_key
    ,ds.product_key
	,cte.pri_supplier_key 
	,cte.ext_unit_cost
	,cte.date_key				-- audit_date_key
	,0							-- psh_audit_id
	,cte.pricing_bucket_key
	,cte.normal_unit_price
	,cte.base_unit_cost
FROM
    daily_sales_fact ds
INNER JOIN tlog_history th ON
	th.tlog_file_key = ds.tlog_file_key
INNER JOIN date_dim da ON
	da.date_key = th.tlog_date_key
INNER JOIN date_dim da2 ON
	da2.absolute_day = da.absolute_day+1
INNER JOIN cte ON
	cte.product_key = ds.product_key
	AND cte.store_key = ds.store_key
	AND cte.date_key <= da2.date_key	
	AND cte.row_nmbr = 1
WHERE
    ds.tlog_file_key = @tlogFileKey
	AND ds.trans_date_key between @minDateKey and @maxDateKey

UPDATE ds set
	pricing_bucket_key = t.pricing_bucket_key
	,regular_retail_unit_price = ISNULL(CASE
		WHEN ds.sales_quantity = 0 THEN 0
		WHEN t.regular_retail_unit_price <> 0 THEN t.regular_retail_unit_price
		ELSE CONVERT(SMALLMONEY, ds.sales_dollar_amount / ds.sales_quantity)
	END, 0)
    ,cost_dollar_amount = ds.sales_quantity * t.extended_unit_cost
	,base_unit_cost = t.base_unit_cost
	,promoted_unit_cost = t.extended_unit_cost
FROM
    daily_sales_fact ds
INNER JOIN tlog_temp_costs t ON
    t.store_key = ds.store_key
    and t.product_key = ds.product_key
    and t.trans_date_key = ds.trans_date_key
    and t.tlog_file_key = ds.tlog_file_key
WHERE
    ds.tlog_file_key = @tlogFileKey
	AND ds.trans_date_key between @minDateKey and @maxDateKey

-- calculate markdown
UPDATE daily_sales_fact SET
	markdown_dollar_amount = CASE
		WHEN sales_dollar_amount < 0 THEN 0
		WHEN convert(decimal(9,2), (sales_quantity * regular_retail_unit_price)) - sales_dollar_amount < 0 THEN 0 
		ELSE convert(decimal(9,2), sales_quantity * regular_retail_unit_price)  - sales_dollar_amount	END
WHERE
    tlog_file_key = @tlogFileKey
	AND trans_date_key BETWEEN @minDateKey and @maxDateKey

-- trying to eliminate effects of rounding error
UPDATE daily_sales_fact SET
	markdown_dollar_amount = 0
WHERE
    tlog_file_key = @tlogFileKey
	AND trans_date_key between @minDateKey and @maxDateKey
	AND markdown_dollar_amount between 0.01 and  0.10 

-- calculate 'assumed costs' for items with no cost entered 
UPDATE ds SET
    cost_dollar_amount = (sales_quantity * regular_retail_unit_price) - ( (sales_quantity * regular_retail_unit_price) * (sd.default_markup / 100)),
    assumed_cost_flag = 1
FROM
    daily_sales_fact ds
INNER JOIN product_dim p ON
    p.product_key = ds.product_key
INNER JOIN subdepartment_dim sd ON
    sd.subdepartment_key = p.subdepartment_key
WHERE
    ds.tlog_file_key = @tlogFileKey
    AND ds.cost_dollar_amount = 0
	AND ds.trans_date_key between @minDateKey and @maxDateKey

-- change bucket to 'Reg Retail' for anything we couldn't find a bucket for
UPDATE ds SET
	pricing_bucket_key = @regRetailPriceBucket
FROM
    daily_sales_fact ds
WHERE
    ds.tlog_file_key = @tlogFileKey
    AND ds.pricing_bucket_key = 0
	AND ds.trans_date_key between @minDateKey and @maxDateKey


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--  EXEC WeeklySalesPercentChangeBySubDepartment 2007, 7, 1, 1, 1, 1, 20080101, 1207

CREATE        PROCEDURE [dbo].[WeeklySalesPercentChangeBySubDepartment]
	@salesYear INT
	,@salesWeek INT
	,@includeWtd BIT
	,@includePtd BIT
	,@includeQtd BIT
	,@includeYtd BIT
	,@sameStoresDateKey INT
	,@majorGrouping VARCHAR(255)
	,@storeKey INT = NULL
AS

SET NOCOUNT ON

CREATE TABLE #tempFinal (
	value_type VARCHAR(10) NOT NULL
	,value_sort SMALLINT NOT NULL
	,store_key SMALLINT NOT NULL
	,short_name VARCHAR(10) NOT NULL
	,store_group VARCHAR(25) NOT NULL
	,department_key INT NOT NULL
	,department_name VARCHAR(50) NOT NULL
	,subdepartment_key INT NOT NULL
	,subdepartment_name VARCHAR(50) NOT NULL
	,curr_sales DECIMAL(18,4) NOT NULL
	,prior_sales DECIMAL(18,4) NOT NULL
	,variance DECIMAL(18,4) NOT NULL
)

DECLARE @maxDayOfWeekNum INT
SELECT @maxDayOfWeekNum = MAX(day_in_sales_week) FROM date_dim WHERE 
	sales_year = @salesYear
	AND sales_week = @salesWeek
	AND date_key < dbo.fn_DateToDateKey(GETDATE())

-- get stores to report on
DECLARE @stores TABLE (
	store_key INT
	,short_name VARCHAR(10)
	,store_group VARCHAR(25)
)
IF @storeKey IS NOT NULL BEGIN
	INSERT INTO @stores SELECT store_key, short_name, store_group FROM store_dim WHERE store_key = @storeKey
END ELSE BEGIN
	INSERT INTO @stores SELECT store_key, short_name, store_group FROM store_dim WHERE opening_date_key <= @sameStoresDateKey
	INSERT INTO @stores values (9999, 'All Stores', 'All Stores')
END



IF @includeWtd = 1 BEGIN
	DECLARE @currAbsoluteWeek INT
	SELECT @currAbsoluteWeek = MIN(absolute_week) FROM date_dim WHERE sales_year = @salesYear AND sales_week = @salesWeek
	
	DECLARE @priorAbsoluteWeek INT
	DECLARE @priorYear INT
	DECLARE @priorWeek INT
	SELECT 
		@priorYear = sales_year
		,@priorWeek = sales_week
	FROM 
		date_dim da
	WHERE 
		absolute_week = @currAbsoluteWeek - 52
	
	SELECT
		sales.store_key
		,sales.subdepartment_key
		,SUM(sales.sales_dollar_amount) AS sales_dollar_amount
	INTO
		#currWtd
	FROM
		daily_subdepartment_sales sales
	INNER JOIN date_dim da ON
		da.date_key = sales.tlog_date_key
	INNER JOIN @stores s ON
		s.store_key = sales.store_key
	WHERE
		da.sales_year = @salesYear
		AND da.sales_week = @salesWeek
		AND da.day_in_sales_week <= @maxDayOfWeekNum
	GROUP BY
		sales.store_key
		,sales.subdepartment_key

	INSERT INTO #currWtd SELECT
		9999
		,subdepartment_key	
		,SUM(sales_dollar_amount)
	FROM
		#currWtd
 	GROUP BY 
		subdepartment_key

	SELECT
		sales.store_key
		,sales.subdepartment_key
		,SUM(sales.sales_dollar_amount) AS sales_dollar_amount
	INTO
		#priorWtd
	FROM
		daily_subdepartment_sales sales 
	INNER JOIN date_dim da ON
		da.date_key = sales.tlog_date_key
	INNER JOIN @stores s ON
		s.store_key = sales.store_key
	WHERE
		da.sales_year = @priorYear
		AND da.sales_week = @priorWeek
		AND da.day_in_sales_week <= @maxDayOfWeekNum
	GROUP BY
		sales.store_key
		,sales.subdepartment_key

	INSERT INTO #priorWtd SELECT
		9999
		,subdepartment_key	
		,SUM(sales_dollar_amount)
	FROM
		#priorWtd
	GROUP BY 
		subdepartment_key

	INSERT INTO #tempFinal SELECT
		'WTD' AS value_type
		,1 AS value_sort
		,c.store_key AS store_key
		,ISNULL(RTRIM(LTRIM(s.short_name)),'TOTAL') AS short_name
		,ISNULL(s.store_group, '') AS store_group
		,d.department_key
		,RTRIM(LTRIM(d.department_name)) AS department_name
		,sd.subdepartment_key
		,RTRIM(LTRIM(sd.subdepartment_name)) AS subdepartment_name
		,c.sales_dollar_amount AS curr_sales
		,ISNULL(p.sales_dollar_amount, 0.00) AS prior_sales
		,ISNULL(c.sales_dollar_amount - p.sales_dollar_amount,0.00) AS variance
	FROM
		#currWtd c
	LEFT OUTER JOIN #priorWtd p ON
		p.store_key = c.store_key
		AND p.subdepartment_key = c.subdepartment_key
	INNER JOIN subdepartment_dim sd ON
		sd.subdepartment_key = c.subdepartment_key
	INNER JOIN department_dim d ON
		d.department_key = sd.department_key
	INNER JOIN @stores s ON
		s.store_key = c.store_key
	WHERE
		d.major_grouping = @majorGrouping
END

DECLARE @startDate INT
DECLARE @endDate INT
DECLARE @quarter VARCHAR(10)
DECLARE @absWeek INT
DECLARE @absDay INT
DECLARE @cutoffDate DATETIME
DECLARE @firstDateInQuarter DATETIME
DECLARE @dayInQuarter INT
DECLARE @Period VARCHAR(10)
DECLARE @firstDateInPeriod DATETIME
DECLARE @dayInPeriod INT

IF @includePtd = 1 BEGIN

	EXEC GetPtdDates @salesWeek, @salesYear, @maxDayOfWeekNum, @Period OUTPUT, @absWeek OUTPUT, @absDay OUTPUT, @cutoffDate OUTPUT, @firstDateInPeriod OUTPUT, @dayInPeriod OUTPUT

	SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek AND day_in_sales_week = 1
	SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInPeriod-1
	SELECT
		sales.store_key
		,sales.subdepartment_key
		,SUM(sales.sales_dollar_amount) AS sales_dollar_amount
	INTO
		#currPtd
	FROM
		daily_subdepartment_sales sales
	INNER JOIN date_dim da ON
		da.date_key = sales.tlog_date_key
	INNER JOIN @stores s ON
		s.store_key = sales.store_key
	WHERE
		sales.tlog_date_key BETWEEN @startDate AND @endDate
	GROUP BY
		sales.store_key
		,sales.subdepartment_key

	INSERT INTO #currPtd SELECT
		9999
		,subdepartment_key	
		,SUM(sales_dollar_amount)
	FROM
		#currPtd
	GROUP BY 
		subdepartment_key

	-- 52 weeks ago
	SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek-52 AND day_in_sales_week = 1
	SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInPeriod-1
	SELECT
		sales.store_key
		,sales.subdepartment_key
		,SUM(sales.sales_dollar_amount) AS sales_dollar_amount
	INTO
		#priorPtd
	FROM
		daily_subdepartment_sales sales
	INNER JOIN date_dim da ON
		da.date_key = sales.tlog_date_key
	INNER JOIN @stores s ON
		s.store_key = sales.store_key
	WHERE
		sales.tlog_date_key BETWEEN @startDate AND @endDate
	GROUP BY
		sales.store_key
		,sales.subdepartment_key

	INSERT INTO #priorPtd SELECT
		9999
		,subdepartment_key	
		,SUM(sales_dollar_amount)
	FROM
		#priorPtd
	GROUP BY 
		subdepartment_key

	INSERT INTO #tempFinal SELECT
		'PTD' AS value_type
		,2
		,c.store_key AS store_key
		,ISNULL(RTRIM(LTRIM(s.short_name)),'TOTAL') AS short_name
		,ISNULL(s.store_group, '') AS store_group
		,d.department_key
		,RTRIM(LTRIM(d.department_name)) AS department_name
		,sd.subdepartment_key
		,RTRIM(LTRIM(sd.subdepartment_name)) AS subdepartment_name
		,c.sales_dollar_amount AS curr_sales
		,ISNULL(p.sales_dollar_amount, 0.00) AS prior_sales
		,ISNULL(c.sales_dollar_amount - p.sales_dollar_amount,0.00) AS variance
	FROM
		#currPtd c
	LEFT OUTER JOIN #priorPtd p ON
		p.store_key = c.store_key
		AND p.subdepartment_key = c.subdepartment_key
	INNER JOIN subdepartment_dim sd ON
		sd.subdepartment_key = c.subdepartment_key
	INNER JOIN department_dim d ON
		d.department_key = sd.department_key
	INNER JOIN @stores s ON
		s.store_key = c.store_key
	WHERE
		d.major_grouping = @majorGrouping
END


IF @includeQtd = 1 BEGIN
	EXEC GetQtdDates @salesWeek, @salesYear, @maxDayOfWeekNum, @quarter OUTPUT, @absWeek OUTPUT, @absDay OUTPUT, @cutoffDate OUTPUT, @firstDateInQuarter OUTPUT, @dayInQuarter OUTPUT

	-- current quarter
	SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek AND day_in_sales_week = 1
	SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInQuarter-1
	SELECT
		sales.store_key
		,sales.subdepartment_key
		,SUM(sales.sales_dollar_amount) AS sales_dollar_amount
	INTO
		#currQtd
	FROM
		daily_subdepartment_sales sales
	INNER JOIN date_dim da ON
		da.date_key = sales.tlog_date_key
	INNER JOIN @stores s ON
		s.store_key = sales.store_key
	WHERE
		sales.tlog_date_key BETWEEN @startDate AND @endDate
	GROUP BY
		sales.store_key
		,sales.subdepartment_key

	INSERT INTO #currQtd SELECT
		9999
		,subdepartment_key	
		,SUM(sales_dollar_amount)
	FROM
		#currQtd
	GROUP BY 
		subdepartment_key

	-- 52 weeks ago
	SELECT @startDate = date_key, @absDay = absolute_day FROM date_dim WHERE absolute_week = @absWeek-52 AND day_in_sales_week = 1
	SELECT @endDate = date_key FROM date_dim WHERE absolute_day = @absDay + @dayInQuarter-1
	SELECT
		sales.store_key
		,sales.subdepartment_key
		,SUM(sales.sales_dollar_amount) AS sales_dollar_amount
	INTO
		#priorQtd
	FROM
		daily_subdepartment_sales sales
	INNER JOIN date_dim da ON
		da.date_key = sales.tlog_date_key
	INNER JOIN @stores s ON
		s.store_key = sales.store_key
	WHERE
		sales.tlog_date_key BETWEEN @startDate AND @endDate
	GROUP BY
		sales.store_key
		,sales.subdepartment_key

	INSERT INTO #priorQtd SELECT
		9999
		,subdepartment_key	
		,SUM(sales_dollar_amount)
	FROM
		#priorQtd
	GROUP BY 
		subdepartment_key

	INSERT INTO #tempFinal SELECT
		'QTD' AS value_type
		,3
		,c.store_key AS store_key
		,ISNULL(RTRIM(LTRIM(s.short_name)),'TOTAL') AS short_name
		,ISNULL(s.store_group, '') AS store_group
		,d.department_key
		,RTRIM(LTRIM(d.department_name)) AS department_name
		,sd.subdepartment_key
		,RTRIM(LTRIM(sd.subdepartment_name)) AS subdepartment_name
		,c.sales_dollar_amount AS curr_sales
		,ISNULL(p.sales_dollar_amount, 0.00) AS prior_sales
		,ISNULL(c.sales_dollar_amount - p.sales_dollar_amount,0.00) AS variance
	FROM
		#currQtd c
	LEFT OUTER JOIN #priorQtd p ON
		p.store_key = c.store_key
		AND p.subdepartment_key = c.subdepartment_key
	INNER JOIN subdepartment_dim sd ON
		sd.subdepartment_key = c.subdepartment_key
	INNER JOIN department_dim d ON
		d.department_key = sd.department_key
	INNER JOIN @stores s ON
		s.store_key = c.store_key
	WHERE
		d.major_grouping = @majorGrouping
END



IF @includeYtd = 1 BEGIN
	EXEC GetYtdDates @salesWeek, @salesYear, @maxDayOfWeekNum, 0, @startDate OUTPUT, @endDate OUTPUT
	SELECT
		sales.store_key
		,sales.subdepartment_key
		,SUM(sales.sales_dollar_amount) AS sales_dollar_amount
	INTO
		#currYtd
	FROM
		daily_subdepartment_sales sales
	INNER JOIN date_dim da ON
		da.date_key = sales.tlog_date_key
	INNER JOIN @stores s ON
		s.store_key = sales.store_key
	WHERE
		sales.tlog_date_key BETWEEN @startDate AND @endDate
	GROUP BY
		sales.store_key
		,sales.subdepartment_key

	INSERT INTO #currYtd SELECT
		9999
		,subdepartment_key	
		,SUM(sales_dollar_amount)
	FROM
		#currYtd
	GROUP BY 
		subdepartment_key

	-- 52 weeks ago
	EXEC GetYtdDates @salesWeek, @salesYear, @maxDayOfWeekNum, -52, @startDate OUTPUT, @endDate OUTPUT
	SELECT
		sales.store_key
		,sales.subdepartment_key
		,SUM(sales.sales_dollar_amount) AS sales_dollar_amount
	INTO
		#priorYtd
	FROM
		daily_subdepartment_sales sales
	INNER JOIN date_dim da ON
		da.date_key = sales.tlog_date_key
	INNER JOIN @stores s ON
		s.store_key = sales.store_key
	WHERE
		sales.tlog_date_key BETWEEN @startDate AND @endDate
	GROUP BY
		sales.store_key
		,sales.subdepartment_key

	INSERT INTO #priorYtd SELECT
		9999
		,subdepartment_key	
		,SUM(sales_dollar_amount)
	FROM
		#priorYtd
	GROUP BY 
		subdepartment_key

	INSERT INTO #tempFinal SELECT
		'YTD' AS value_type
		,4
		,c.store_key AS store_key
		,ISNULL(RTRIM(LTRIM(s.short_name)),'TOTAL') AS short_name
		,ISNULL(s.store_group, '') AS store_group
		,d.department_key
		,RTRIM(LTRIM(d.department_name)) AS department_name
		,sd.subdepartment_key
		,RTRIM(LTRIM(sd.subdepartment_name)) AS subdepartment_name
		,c.sales_dollar_amount AS curr_sales
		,ISNULL(p.sales_dollar_amount, 0.00) AS prior_sales
		,ISNULL(c.sales_dollar_amount - p.sales_dollar_amount,0.00) AS variance
	FROM
		#currYtd c
	LEFT OUTER JOIN #priorYtd p ON
		p.store_key = c.store_key
		AND p.subdepartment_key = c.subdepartment_key
	INNER JOIN subdepartment_dim sd ON
		sd.subdepartment_key = c.subdepartment_key
	INNER JOIN department_dim d ON
		d.department_key = sd.department_key
	INNER JOIN @stores s ON
		s.store_key = c.store_key
	WHERE
		d.major_grouping = @majorGrouping
END


SELECT * FROM #tempFinal ORDER BY store_key

SET NOCOUNT OFF


GO
