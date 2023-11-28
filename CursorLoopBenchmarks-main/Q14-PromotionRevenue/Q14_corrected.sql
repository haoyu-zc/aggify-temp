-- Type your code here, or load an example.
CREATE OR REPLACE FUNCTION PromoRevenueWithCustomAgg(partkey INTEGER)
    RETURNS DECIMAL(25, 5)
    STABLE AS
$$
DECLARE
    pkey    INTEGER        := partkey;
    revenue DECIMAL(25, 5) := 0;
BEGIN
    if exists (SELECT L_EXTENDEDPRICE, L_DISCOUNT from lineitem
    WHERE L_PARTKEY = pkey) then
        revenue := (SELECT promo_revenue_agg(L_EXTENDEDPRICE, L_DISCOUNT, revenue)
        FROM (SELECT L_EXTENDEDPRICE, L_DISCOUNT from lineitem
        WHERE L_PARTKEY = pkey) tmp);
    end if;
    RETURN revenue;
END;
$$ LANGUAGE plpgsql;

-- Q:
SELECT P_PARTKEY, PromoRevenueWithCustomAgg(P_PARTKEY)
FROM part
WHERE P_TYPE LIKE 'PROMO%%';
