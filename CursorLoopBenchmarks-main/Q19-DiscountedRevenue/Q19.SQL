-- Internal states
CREATE TYPE discount_revenue_accum AS
(
    revenue DECIMAL(15, 2),
    is_initialized BOOLEAN
);

-- Update function
CREATE OR REPLACE FUNCTION f_update(state discount_revenue_accum, extendedPrice decimal(15, 2),
                                                 discount decimal(15, 2))
    RETURNS discount_revenue_accum
    IMMUTABLE AS
$$
BEGIN
    IF NOT state.is_initialized THEN
        state.is_initialized := true;
        state.revenue := 0.0;
    END IF;
    state.revenue := state.revenue + (extendedPrice * (1 - discount));
    RETURN state;
END;
$$ LANGUAGE plpgsql;

-- Finalize function
CREATE OR REPLACE FUNCTION f_finalize(state discount_revenue_accum) RETURNS DECIMAL(15, 2)
    IMMUTABLE AS
$$
BEGIN
    RETURN state.revenue;
END;
$$ LANGUAGE plpgsql;

-- Aggregate
CREATE OR REPLACE AGGREGATE sum_discounted_price(extendedPrice decimal(15, 2), discount decimal(15, 2))
    (
    sfunc = f_update,
    stype = discount_revenue_accum,
    finalfunc = f_finalize,
    -- stype.revenue = 0.0,
    stype.is_initialized = false
    );

-- UDF, Wrapper
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
