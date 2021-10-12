WITH sbc_weekly
AS (
	WITH storesales AS (
			SELECT *
			FROM "SNOWFLAKE_SAMPLE_DATA"."TPCDS_SF10TCL"."STORE_SALES"
			),
		items AS (
			SELECT *
			FROM "SNOWFLAKE_SAMPLE_DATA"."TPCDS_SF10TCL"."ITEM"
			),
		datedim AS (
			SELECT *
			FROM "SNOWFLAKE_SAMPLE_DATA"."TPCDS_SF10TCL"."DATE_DIM"
			)
	SELECT a.SS_TICKET_NUMBER AS sale,
		b.I_CATEGORY AS category,
		c.D_WEEK_SEQ AS weekid
	FROM storesales a
	INNER JOIN items b ON a.SS_ITEM_SK = b.I_ITEM_SK
	INNER JOIN datedim c ON a.SS_SOLD_DATE_SK = c.D_DATE_SK
	)
    
SELECT category,
	weekid,
	count(sale) AS salecount
FROM sbc_weekly
GROUP BY category,
	weekid
