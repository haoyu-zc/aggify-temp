CREATE OR REPLACE FUNCTION DiscountedRevenueWithNativeAgg()
    RETURNS decimal(15, 2)
    STABLE AS
$$
BEGIN
    RETURN (
        (SELECT SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT))
         FROM lineitem,
              part
         WHERE ((P_PARTKEY = L_PARTKEY AND P_BRAND = 'Brand#12'
             AND P_CONTAINER IN ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG')
             AND L_QUANTITY BETWEEN 1 AND 11
             AND P_SIZE BETWEEN 1 AND 5
             AND L_SHIPMODE IN ('AIR', 'AIR REG')
             AND L_SHIPINSTRUCT = 'DELIVER IN PERSON')
             OR (P_PARTKEY = L_PARTKEY AND P_BRAND = 'Brand#23'
                 AND P_CONTAINER IN ('MED BAG', 'MED BOX', 'MED PKG', 'MED PACK')
                 AND L_QUANTITY BETWEEN 10 AND 20
                 AND P_SIZE BETWEEN 1 AND 10
                 AND L_SHIPMODE IN ('AIR', 'AIR REG')
                 AND L_SHIPINSTRUCT = 'DELIVER IN PERSON')
             OR (P_PARTKEY = L_PARTKEY AND P_BRAND = 'Brand#34'
                 AND P_CONTAINER IN ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG')
                 AND L_QUANTITY BETWEEN 20 AND 30
                 AND P_SIZE BETWEEN 1 AND 15
                 AND L_SHIPMODE IN ('AIR', 'AIR REG')
                 AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'))));
END;
$$ LANGUAGE plpgsql;

--UDF call
EXPLAIN ANALYZE SELECT DiscountedRevenueWithNativeAgg() as dr;

EXPLAIN ANALYZE (SELECT SUM(L_EXTENDEDPRICE*(1-L_DISCOUNT))
         FROM lineitem,
              part
         WHERE ((P_PARTKEY = L_PARTKEY AND P_BRAND = 'Brand#12'
             AND P_CONTAINER IN ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG')
             AND L_QUANTITY BETWEEN 1 AND 11
             AND P_SIZE BETWEEN 1 AND 5
             AND L_SHIPMODE IN ('AIR', 'AIR REG')
             AND L_SHIPINSTRUCT = 'DELIVER IN PERSON')
             OR (P_PARTKEY = L_PARTKEY AND P_BRAND = 'Brand#23'
                 AND P_CONTAINER IN ('MED BAG', 'MED BOX', 'MED PKG', 'MED PACK')
                 AND L_QUANTITY BETWEEN 10 AND 20
                 AND P_SIZE BETWEEN 1 AND 10
                 AND L_SHIPMODE IN ('AIR', 'AIR REG')
                 AND L_SHIPINSTRUCT = 'DELIVER IN PERSON')
             OR (P_PARTKEY = L_PARTKEY AND P_BRAND = 'Brand#34'
                 AND P_CONTAINER IN ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG')
                 AND L_QUANTITY BETWEEN 20 AND 30
                 AND P_SIZE BETWEEN 1 AND 15
                 AND L_SHIPMODE IN ('AIR', 'AIR REG')
                 AND L_SHIPINSTRUCT = 'DELIVER IN PERSON')));
