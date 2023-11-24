-- Internal states
CREATE TYPE promo_revenue_accum AS
(
    revenue DECIMAL(25, 5)
    is_initialized BOOLEAN
);

-- Update function
CREATE OR REPLACE FUNCTION f_update(
    state promo_revenue_accum,
    fetched_price DECIMAL(12, 2),
    fetched_discount DECIMAL(12, 2)
) RETURNS promo_revenue_accum
    IMMUTABLE AS
$$
BEGIN
    IF NOT state.is_initialized THEN
        state.is_initialized := true;
        state.revenue := 0.0;
    END IF;
    state.revenue := state.revenue + fetched_price * (1 - fetched_discount);
    RETURN state;
END;
$$ LANGUAGE plpgsql;

-- Update function
CREATE OR REPLACE FUNCTION f_finalize(state promo_revenue_accum) RETURNS DECIMAL(25, 5)
    IMMUTABLE AS
$$
BEGIN
    RETURN state.revenue;
END;
$$ LANGUAGE plpgsql;

-- Aggregate
-- CREATE OR REPLACE AGGREGATE promo_revenue_agg(
--     fetched_price DECIMAL(12, 2),
--     fetched_discount DECIMAL(12, 2),
--     ...
--     ) (
--     sfunc = f_update,
--     stype = promo_revenue_accum,
--     finalfunc = f_finalize,
--     -- stype.revenue = 0.0,
--     stype.is_initialized = false
--     );

    CREATE OR REPLACE AGGREGATE promo_revenue_agg(
    fetched_price DECIMAL(12, 2),
    fetched_discount DECIMAL(12, 2),
    ) (
    sfunc = f_update,
    stype = promo_revenue_accum,
    finalfunc = f_finalize,
    -- stype.revenue = 0.0,
    stype.is_initialized = false
    );

-- UDF, Wrapper
CREATE OR REPLACE FUNCTION PromoRevenueWithCustomAgg(partkey INTEGER)
    RETURNS DECIMAL(25, 5)
    STABLE AS
$$
DECLARE
    revenue DECIMAL(25, 5);
BEGIN
    SELECT promo_revenue_agg(L_EXTENDEDPRICE, L_DISCOUNT)
    INTO revenue
    FROM lineitem
    WHERE L_PARTKEY = partkey;

    RETURN revenue;
END;
$$ LANGUAGE plpgsql;

--UDF call
EXPLAIN ANALYZE
SELECT P_PARTKEY, PromoRevenueWithCustomAgg(P_PARTKEY)
FROM part
WHERE P_TYPE LIKE 'PROMO%%'; /* order is different without term: ORDER BY p_partkey */
