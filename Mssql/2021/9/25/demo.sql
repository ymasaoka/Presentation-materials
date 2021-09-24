-- デモデータ
USE AdventureWorksDW2019;
GO


-- 日付と数字の補助テーブルを作成
DROP TABLE IF EXISTS dbo.DateNums;
CREATE TABLE dbo.DateNums
 (n int NOT NULL PRIMARY KEY,
  d date NOT NULL UNIQUE);
GO
SET NOCOUNT ON;
DECLARE @max AS INT, @rc AS INT, @d AS DATE;
SET @max = 10000;
SET @rc = 1;
SET @d = '20100101'     -- 最初の日付
INSERT INTO dbo.DateNums VALUES(1, @d);
WHILE @rc * 2 <= @max
BEGIN
  INSERT INTO dbo.DateNums
  SELECT n + @rc, DATEADD(day, n + @rc - 1, @d)
  FROM dbo.DateNums;
  SET @rc = @rc * 2;
END
INSERT INTO dbo.DateNums
  SELECT n + @rc, DATEADD(day, n + @rc - 1, @d)
  FROM dbo.DateNums
  WHERE n + @rc <= @max;
GO
-- データを確認
SELECT * FROM dbo.DateNums
SET NOCOUNT OFF;
GO

-- 売り上げのデモ用テーブルを作成
DROP TABLE IF EXISTS dbo.Sales;
CREATE TABLE dbo.Sales
(
 Id int IDENTITY(1,1) PRIMARY KEY,
 ProductKey int,
 PName varchar(13),
 sn int NULL,
 en int NULL,
 SoldDate date,
 ExpirationDate date
);
GO

-- データを挿入
DECLARE @y AS int = 0;
WHILE @y < 3
BEGIN
INSERT INTO dbo.Sales
 (ProductKey, PName, SoldDate, ExpirationDate)
SELECT CustomerKey AS ProductKey,
 'Product ' + CAST(CustomerKey AS char(5)) AS PName,
 CAST(DATEADD(year, @y *3, OrderDate)
  AS date) AS SoldDate,
 CAST(DATEADD(day,
        CAST(CRYPT_GEN_RANDOM(1) AS int) % 30 + 1,
        DATEADD(year, @y *3, OrderDate))
  AS date) AS ExpirationDate
FROM dbo.FactInternetSales
UNION ALL
SELECT
 ResellerKey AS ProductKey,
 'Product ' + CAST(ResellerKey AS char(5)) AS PName,
 CAST(DATEADD(year, @y *3, OrderDate)
  AS date) AS SoldDate,
 CAST(DATEADD(day,
        CAST(CRYPT_GEN_RANDOM(1) AS int) % 30 + 1,
        DATEADD(year, @y *3, OrderDate))
  AS date) AS ExpirationDate
FROM dbo.FactResellerSales;
SET @y = @y + 1;
END;
GO
-- snとenを更新
UPDATE dbo.Sales
   SET sn = d.n
FROM dbo.Sales AS s
 INNER JOIN dbo.DateNums AS d
  ON s.SoldDate = d.d;
UPDATE dbo.Sales
   SET en = d.n
FROM dbo.Sales AS s
 INNER JOIN dbo.DateNums AS d
  ON s.ExpirationDate = d.d;
GO
-- 概要
SELECT *
FROM dbo.Sales;
GO


-- 履歴テーブルの設定を有効化
ALTER DATABASE AdventureWorksDW2019
 SET TEMPORAL_HISTORY_RETENTION ON;
GO


-- T1
DROP TABLE IF EXISTS dbo.T1;
CREATE TABLE dbo.T1
(
 Id INT NOT NULL PRIMARY KEY CLUSTERED,
 C1 INT,
 Vf DATETIME2 NOT NULL,
 Vt DATETIME2 NOT NULL
);
GO
-- T1 hist
DROP TABLE IF EXISTS dbo.T1_Hist;
CREATE TABLE dbo.T1_Hist
(
 Id INT NOT NULL,
 C1 INT,
 Vf DATETIME2 NOT NULL,
 Vt DATETIME2 NOT NULL
);
GO
CREATE CLUSTERED INDEX IX_CL_T1_Hist ON dbo.T1_Hist(Vt, Vf);
GO

-- テーブルにデータを入力
INSERT INTO dbo.T1_Hist(Id, C1, Vf, Vt) VALUES
(1,1,'20191101','20191106'),
(1,2,'20191106','20210202');
GO
INSERT INTO dbo.T1(Id, C1, Vf, Vt) VALUES
(1,3,'20210202','99991231 23:59:59.9999999');
GO
SELECT *
FROM dbo.T1;
SELECT *
FROM dbo.T1_Hist;
GO


-- テンポラルテーブルに変換
ALTER TABLE dbo.T1 ADD PERIOD FOR SYSTEM_TIME (Vf, Vt);
GO
ALTER TABLE dbo.T1 SET
(
SYSTEM_VERSIONING = ON
 (
  HISTORY_TABLE = dbo.T1_Hist,
  HISTORY_RETENTION_PERIOD = 3 MONTHS
 )
);
GO


-- いくつかの更新を実行
INSERT INTO dbo.T1 (Id, C1)
VALUES (2, 1), (3, 1);
WAITFOR DELAY '00:00:01';
UPDATE dbo.T1
   SET C1 = 2
 WHERE Id = 2;
WAITFOR DELAY '00:00:01';
DELETE FROM dbo.T1
WHERE id = 3;
GO
-- 2つのテーブルの内容を表示
SELECT *
FROM dbo.T1;
SELECT *
FROM dbo.T1_Hist;
GO


-- 期間列を非表示
ALTER TABLE dbo.T1 ALTER COLUMN Vf ADD HIDDEN;
ALTER TABLE dbo.T1 ALTER COLUMN Vt ADD HIDDEN;
GO
-- 2つのテーブルの内容を表示
SELECT *
FROM dbo.T1;
SELECT *
FROM dbo.T1_Hist;
GO


-- AS OF: 特定の時点でのテーブル状態を表示
SELECT Id, C1, Vf, Vt
FROM dbo.T1
 FOR SYSTEM_TIME
  AS OF '2021-02-05 10:30:10.6184612';

-- FROM..TO: 間隔中にアクティブだったすべてのバージョンのすべての行。間隔境界でアクティブだった行は含まれない。
DECLARE @Vf AS DATETIME2;
SET @Vf =
 (SELECT MAX(Vf) FROM dbo.T1_Hist);
SELECT @Vf;SELECT Id, C1, Vf, Vt
FROM dbo.T1
 FOR SYSTEM_TIME
  FROM '2019-11-06 00:00:00.0000000'
    TO '2021-02-05 10:30:10.6184612';

-- BETWEEN: 間隔中にアクティブだったすべてのバージョンのすべての行。間隔の上限でアクティブだった行が含まれる。
SELECT Id, C1, Vf, Vt
FROM dbo.T1
 FOR SYSTEM_TIME
  BETWEEN '2019-11-06 00:00:00.0000000'
      AND '2021-02-05 10:30:10.6184612';

-- CONTAINED IN: 上限と下限を含め、すべての行で期間内に開閉されたものを表示。期間内に何が変更されたかを示す。
DECLARE @Vf AS DATETIME2;
SET @Vf =
 (SELECT MAX(Vf) FROM dbo.T1_Hist);
SET @Vf = DATEADD(s, 3, @Vf);
-- SELECT @Vf;
SELECT Id, C1, Vf, Vt
FROM dbo.T1
 FOR SYSTEM_TIME
  CONTAINED IN
   ('2019-11-06 00:00:00.0000000',
    '2021-02-06 00:00:00.0000000');


-- 実行プラン再取得
SELECT Id, C1, Vf, Vt
FROM dbo.T1
 FOR SYSTEM_TIME ALL;


-- クリーンアップ
ALTER TABLE dbo.T1 SET (SYSTEM_VERSIONING = OFF);
DROP TABLE IF EXISTS dbo.T1;
DROP TABLE IF EXISTS dbo.T1_Hist;
GO
ALTER DATABASE AdventureWorksDW2019
 SET TEMPORAL_HISTORY_RETENTION OFF;
GO


-- 粒度の問題 - 粒度1のデモ
CREATE TABLE dbo.T1
(
 id INT NOT NULL CONSTRAINT PK_T1 PRIMARY KEY,
 c1 INT NOT NULL,
 vf DATETIME2(0) GENERATED ALWAYS AS ROW START NOT NULL,
 vt DATETIME2(0) GENERATED ALWAYS AS ROW END NOT NULL,
 PERIOD FOR SYSTEM_TIME (vf, vt)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.T1_Hist));
GO
-- 最初の行
INSERT INTO dbo.T1(id, c1)
VALUES(1, 1);
GO


BEGIN TRAN
UPDATE dbo.T1
   SET c1 = 2
 WHERE id=1;
COMMIT;
WAITFOR DELAY '00:00:00.1';
BEGIN TRAN
UPDATE dbo.T1
   SET c1 = 3
 WHERE id=1;
COMMIT;
GO
SELECT *
FROM dbo.T1
FOR SYSTEM_TIME ALL;
GO



SELECT *
FROM dbo.T1
UNION ALL
SELECT *
FROM dbo.T1_Hist;
GO


-- クリーンアップ
ALTER TABLE dbo.T1 SET (SYSTEM_VERSIONING = OFF);
DROP TABLE IF EXISTS dbo.T1;
DROP TABLE IF EXISTS dbo.T1_Hist;
GO


-- 包含制約がない例のデモ
USE tempdb;
GO
-- 顧客
CREATE TABLE dbo.CustomerHistory
(
 CId CHAR(3) NOT NULL,
 CName CHAR(5) NOT NULL,
 ValidFrom DATETIME2 NOT NULL,
 ValidTo DATETIME2 NOT NULL
);
CREATE CLUSTERED INDEX CIX_CustomerHistory ON dbo.CustomerHistory
(ValidTo ASC, ValidFrom ASC);
GO
CREATE TABLE dbo.Customer
(
 CId CHAR(3) PRIMARY KEY,
 CName CHAR(5) NOT NULL
);
GO
-- 注文
CREATE TABLE dbo.OrdersHistory
(
 OId CHAR(3) NOT NULL,
 CId CHAR(3) NOT NULL,
 Q INT NOT NULL,
 ValidFrom DATETIME2 NOT NULL,
 ValidTo DATETIME2 NOT NULL
);
CREATE CLUSTERED INDEX CIX_OrdersHistory ON dbo.OrdersHistory
(ValidTo ASC, ValidFrom ASC);
GO
CREATE TABLE dbo.Orders
(
 OId CHAR(3) NOT NULL PRIMARY KEY,
 CId CHAR(3) NOT NULL,
 Q INT NOT NULL
);
GO
ALTER TABLE dbo.Orders ADD CONSTRAINT FK_Orders_Customer
 FOREIGN KEY (CId) REFERENCES dbo.Customer(CID);
GO

-- デモデータの挿入
INSERT INTO dbo.CustomerHistory
 (CId, CName, ValidFrom, ValidTo)
VALUES
 ('111','AAA','20180101', '20180201'),
 ('111','BBB','20180201', '20180220');
INSERT INTO dbo.Customer
 (CId, CName)
VALUES
 ('111','CCC');
INSERT INTO dbo.OrdersHistory
 (OId, CId, Q, ValidFrom, ValidTo)
VALUES
 ('001','111',1000,'20180110','20180201'),
 ('001','111',2000,'20180201','20180203'),
 ('001','111',3000,'20180203','20180220');
INSERT INTO dbo.Orders
 (OId, CId, q)
VALUES
 ('001','111',4000);
GO
-- データの確認
SELECT * FROM dbo.Customer;
SELECT * FROM dbo.CustomerHistory;
SELECT * FROM dbo.Orders;
SELECT * FROM dbo.OrdersHistory;
GO


-- テンポラルテーブルの作成
-- 現在のテーブルを変更
ALTER TABLE dbo.Customer
 ADD ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL
  CONSTRAINT DFC_StartDate1 DEFAULT '20180220 00:00:00.0000000',
 ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL
  CONSTRAINT DFC_EndDate1 DEFAULT '99991231 23:59:59.9999999',
 PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo);
GO
ALTER TABLE dbo.Orders
 ADD ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL
  CONSTRAINT DFO_StartDate1 DEFAULT '20180220 00:00:00.0000000',
 ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL
  CONSTRAINT DFO_EndDate1 DEFAULT '99991231 23:59:59.9999999',
 PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo);
GO
-- システムバージョニングを有効化
ALTER TABLE dbo.Customer
 SET (SYSTEM_VERSIONING = ON
  (HISTORY_TABLE = dbo.CustomerHistory,
   DATA_CONSISTENCY_CHECK = ON));
GO
ALTER TABLE dbo.Orders
 SET (SYSTEM_VERSIONING = ON
  (HISTORY_TABLE = dbo.OrdersHistory,
   DATA_CONSISTENCY_CHECK = ON));
GO
-- 全データを確認
SELECT *
FROM dbo.Customer
 FOR SYSTEM_TIME ALL;
SELECT *
FROM dbo.Orders
 FOR SYSTEM_TIME ALL;
GO


-- ビューを作成
CREATE OR ALTER VIEW dbo.CustomerOrders
AS
SELECT C.CId, C.CName, O.OId, O.Q,
 c.ValidFrom AS CVF, c.ValidTo AS CVT,
 o.ValidFrom AS OVF, o.ValidTo AS OVT
FROM dbo.Customer AS c
 INNER JOIN dbo.Orders AS o
  ON c.CId = o.CId;
GO

-- 現在の状態
SELECT *
FROM dbo.CustomerOrders;
-- 特定の日付 - ソーステーブルに伝達
SELECT *
FROM dbo.CustomerOrders
 FOR SYSTEM_TIME AS OF '20180102';
SELECT *
FROM dbo.CustomerOrders
 FOR SYSTEM_TIME AS OF '20180131';
SELECT *
FROM dbo.CustomerOrders
 FOR SYSTEM_TIME AS OF '20180201';
SELECT *
FROM dbo.CustomerOrders
 FOR SYSTEM_TIME AS OF '20180203';
SELECT *
FROM dbo.CustomerOrders
 FOR SYSTEM_TIME AS OF '20180221';
GO


-- FOR SYSTEM_TIME ALL を使ってビューにクエリを実行
SELECT *
FROM dbo.CustomerOrders
 FOR SYSTEM_TIME ALL;


-- クリーンアップ
DROP VIEW IF EXISTS dbo.CustomerOrders;
ALTER TABLE dbo.Orders SET (SYSTEM_VERSIONING = OFF);
ALTER TABLE dbo.Orders DROP PERIOD FOR SYSTEM_TIME;
DROP TABLE IF EXISTS dbo.Orders;
DROP TABLE IF EXISTS dbo.OrdersHistory;
ALTER TABLE dbo.Customer SET (SYSTEM_VERSIONING = OFF);
ALTER TABLE dbo.Customer DROP PERIOD FOR SYSTEM_TIME;
DROP TABLE IF EXISTS dbo.Customer;
DROP TABLE IF EXISTS dbo.CustomerHistory;
GO


USE AdventureWorksDW2019;
GO
-- 間隔の境界にインデックスを作成
CREATE INDEX idx_sn
 ON dbo.Sales(sn) INCLUDE(en);
CREATE INDEX idx_en
 ON dbo.Sales(en) INCLUDE(sn);
GO

SET STATISTICS IO ON;
GO
-- データの最初付近
DECLARE
 @sn AS INT = 370,
 @en AS INT = 400;
SELECT Id, sn, en
FROM dbo.Sales
WHERE sn <= @en AND en >= @sn
OPTION (RECOMPILE);     -- 実行プランの再利用を防ぐ
GO
-- インデックスシーク idx_sn
-- 論理読み取り: 6
-- データの終了付近
DECLARE
 @sn AS INT = 3640,
 @en AS INT = 3670;
SELECT Id, sn, en
FROM dbo.Sales
WHERE sn <= @en AND en >= @sn
OPTION (RECOMPILE);     -- 実行プランの再利用を防ぐ
GO
-- インデックスシーク idx_en
-- 論理読み取り: 21


-- データの中央付近
DECLARE
 @sn AS INT = 1780,
 @en AS INT = 1810;
SELECT Id, sn, en
FROM dbo.Sales
WHERE sn <= @en AND en >= @sn
OPTION (RECOMPILE);     -- 実行プランの再利用を防ぐ
GO
-- インデックスシーク idx_sn
-- 論理読み取り: 299

-- データの中央付近
-- 間隔の最大長を30に設定
DECLARE
 @sn AS INT = 1780,
 @en AS INT = 1810;
SELECT Id, sn, en
FROM dbo.Sales
WHERE sn <= @en AND sn >= @sn - 30
  AND en >= @sn AND en <= @en + 30
OPTION (RECOMPILE);     -- 実行プランの再利用を防ぐ
GO
-- インデックスシーク idx_sn
-- 論理読み取り: 9

-- データの中央付近
-- 間隔の最大長を900に設定
DECLARE
 @sn AS INT = 1780,
 @en AS INT = 1810;
SELECT Id, sn, en
FROM dbo.Sales
WHERE sn <= @en AND sn >= @sn - 900
  AND en >= @sn AND en <= @en + 900
OPTION (RECOMPILE);     -- 実行プランの再利用を防ぐ
GO
-- インデックスシーク idx_sn
-- 論理読み取り: 250


-- インデックス付きビューの非圧縮フォーム
-- ビュー Intervals_Unpacked を作成
DROP VIEW IF EXISTS dbo.SalesU;
GO
CREATE VIEW dbo.SalesU
WITH SCHEMABINDING
AS
SELECT i.id, n.n
FROM dbo.Sales AS i
 INNER JOIN dbo.DateNums AS n
  ON n.n BETWEEN i.sn AND i.en;
GO
-- ビューにインデックスを付ける
CREATE UNIQUE CLUSTERED INDEX PK_SalesU
 ON dbo.SalesU(n, id);
GO


-- 重複する間隔 - データの中央付近
DECLARE
 @sn AS INT = 1780,
 @en AS INT = 1810;
SELECT id
FROM dbo.SalesU
WHERE n BETWEEN @sn AND @en
GROUP BY id
ORDER BY id
OPTION (RECOMPILE);     --実行プランの再利用を防ぐ
GO
-- クラスター化されたビューでのインデックスシーク
-- 論理読み取り: 43


-- スペースの使用料
EXEC sys.sp_spaceused 'dbo.Sales';
EXEC sys.sp_spaceused 'dbo.SalesU';
GO


-- データ確認
SELECT TOP 5 *
FROM dbo.vTimeSeries;

-- 3年間の月間売上全体を集計して、時系列データとして36行を取得
SELECT TimeIndex,
 SUM(Quantity*2) - 200 AS Quantity,
 DATEFROMPARTS(TimeIndex / 100, TimeIndex % 100, 1) AS DateIndex
FROM dbo.vTimeSeries
WHERE TimeIndex > 201012    -- 2010年12月以降
GROUP BY TimeIndex
ORDER BY TimeIndex;


-- 単純 - 最後の3つの値
WITH TSAggCTE AS
(
SELECT TimeIndex,
 SUM(Quantity*2) - 200 AS Quantity,
 DATEFROMPARTS(TimeIndex / 100, TimeIndex % 100, 1) AS DateIndex
FROM dbo.vTimeSeries
WHERE TimeIndex > 201012    -- December 2010 outlier, too small value
GROUP BY TimeIndex
)
SELECT TimeIndex,
 Quantity,
 AVG(Quantity)
 OVER (ORDER BY TimeIndex
       ROWS BETWEEN 2 PRECEDING
       AND CURRENT ROW) AS SMA,
 DateIndex
FROM TSAggCTE
ORDER BY TimeIndex;
GO


DECLARE  @A AS FLOAT;
SET @A = 0.7;
WITH TSAggCTE AS
(
SELECT TimeIndex,
 SUM(Quantity*2) - 200 AS Quantity,
 DATEFROMPARTS(TimeIndex / 100, TimeIndex % 100, 1) AS DateIndex
FROM dbo.vTimeSeries
WHERE TimeIndex > 201012    -- 2010年12月以降、小さすぎる値
GROUP BY TimeIndex
)
SELECT TimeIndex,
 Quantity,
 AVG(Quantity)
 OVER (ORDER BY TimeIndex
       ROWS BETWEEN 2 PRECEDING
       AND CURRENT ROW) AS SMA,
 @A * Quantity + (1 - @A) *
  ISNULL((LAG(Quantity)
          OVER (ORDER BY TimeIndex)), Quantity)  AS WMA,
 DateIndex
FROM TSAggCTE
ORDER BY TimeIndex;
GO


-- クリーンアップ
USE AdventureWorksDW2019;
DROP VIEW IF EXISTS dbo.SalesU;
DROP TABLE IF EXISTS dbo.Sales;
ALTER TABLE dbo.T1 SET (SYSTEM_VERSIONING = OFF);
DROP TABLE IF EXISTS dbo.T1;
DROP TABLE IF EXISTS dbo.T1_Hist;
GO
ALTER DATABASE AdventureWorksDW2017
 SET TEMPORAL_HISTORY_RETENTION ON;
GO
