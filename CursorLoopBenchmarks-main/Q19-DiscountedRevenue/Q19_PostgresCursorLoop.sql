CREATE OR REPLACE FUNCTION DiscountedRevenue()
    RETURNS decimal(15, 2)
    STABLE AS
$$
DECLARE
    extendedPrice decimal(15, 2);
    discount      decimal(15, 2);
    val           decimal(15, 2) := 0;
BEGIN
    FOR extendedPrice, discount IN
        (SELECT L_EXTENDEDPRICE, L_DISCOUNT
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
                 AND L_SHIPINSTRUCT = 'DELIVER IN PERSON')))
        LOOP
            val := val + (extendedPrice * (1 - discount));
        END LOOP;
    RETURN val;
END;
$$ LANGUAGE plpgsql;


--UDF call
EXPLAIN ANALYZE SELECT DiscountedRevenue() as dr; 
