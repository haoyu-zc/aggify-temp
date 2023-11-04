CREATE OR REPLACE FUNCTION PromoRevenue(partkey INTEGER)
    RETURNS DECIMAL(25, 5)
    STABLE AS
$$
DECLARE
    pkey            INTEGER        := partkey;
    val             DECIMAL(25, 5) := 0;
    fetchedPrice    DECIMAL(12, 2);
    fetchedDiscount DECIMAL(12, 2);
BEGIN
    FOR fetchedPrice, fetchedDiscount IN (select L_EXTENDEDPRICE, L_DISCOUNT from lineitem where L_PARTKEY = pkey)
        LOOP
            val := val + fetchedPrice * (1 - fetchedDiscount);
        END LOOP;
    RETURN val;
END;
$$ LANGUAGE plpgsql;

/* UDF call */
EXPLAIN ANALYZE
SELECT P_PARTKEY, PromoRevenue(P_PARTKEY)
FROM part
WHERE P_TYPE LIKE 'PROMO%%';
