-- Type your code here, or load an example.
CREATE OR REPLACE FUNCTION DiscountedRevenueWithCustomAgg()
    RETURNS decimal(15, 2)
    STABLE AS
$$
DECLARE
    val decimal(15, 2) := 0;
BEGIN
    if exists (select L_EXTENDEDPRICE, L_DISCOUNT from
                lineitem,
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
                 AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'))) then
        val := (
            (SELECT sum_discounted_price(L_EXTENDEDPRICE, L_DISCOUNT, val)
            FROM 
            (select L_EXTENDEDPRICE, L_DISCOUNT from
                    lineitem,
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
                    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'))) tmp));
    end if;
    return val;
END;
$$ LANGUAGE plpgsql;

-- Q:
SELECT DiscountedRevenueWithCustomAgg() as dr;
