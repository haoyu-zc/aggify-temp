/* bit of weirdness, seemed to require being wrapped in this to not get different value from cursor loop? */
CREATE TYPE discount_revenue_accum AS
(
    revenue DECIMAL(15, 2)
);

CREATE OR REPLACE FUNCTION calc_discounted_price(state discount_revenue_accum, extendedPrice decimal(15, 2),
                                                 discount decimal(15, 2))
    RETURNS discount_revenue_accum
    IMMUTABLE AS
$$
BEGIN
    state.revenue := state.revenue + (extendedPrice * (1 - discount));
    RETURN state;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION discount_revenue_finalfunc(state discount_revenue_accum) RETURNS DECIMAL(15, 2)
    IMMUTABLE AS
$$
BEGIN
    RETURN state.revenue;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION discount_revenue_mergefunc(state1 discount_revenue_accum, state2 discount_revenue_accum) RETURNS discount_revenue_accum
    IMMUTABLE AS
$$
DECLARE
    merged_revenue discount_revenue_accum;
BEGIN
    merged_revenue.revenue := state1.revenue + state2.revenue;
    return merged_revenue;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE AGGREGATE sum_discounted_price(extendedPrice decimal(15, 2), discount decimal(15, 2))
    (
    sfunc = calc_discounted_price,
    stype = discount_revenue_accum,
    finalfunc = discount_revenue_finalfunc,
    initcond = '(0.0)',
    combinefunc = discount_revenue_mergefunc,
    parallel = safe
    );

CREATE OR REPLACE FUNCTION DiscountedRevenueWithCustomAgg()
    RETURNS decimal(15, 2)
    STABLE AS
$$
BEGIN
    RETURN (
        (SELECT sum_discounted_price(L_EXTENDEDPRICE, L_DISCOUNT)
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
EXPLAIN ANALYZE SELECT DiscountedRevenueWithCustomAgg() as dr;

EXPLAIN ANALYZE (SELECT sum_discounted_price(L_EXTENDEDPRICE, L_DISCOUNT)
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
