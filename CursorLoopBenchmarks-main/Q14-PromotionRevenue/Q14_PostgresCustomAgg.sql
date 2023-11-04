CREATE TYPE promo_revenue_accum AS
(
    revenue DECIMAL(25, 5)
);

CREATE OR REPLACE FUNCTION promo_revenue_sfunc(
    state promo_revenue_accum,
    fetched_price DECIMAL(12, 2),
    fetched_discount DECIMAL(12, 2)
) RETURNS promo_revenue_accum
    IMMUTABLE AS
$$
BEGIN
    state.revenue := state.revenue + fetched_price * (1 - fetched_discount);
    RETURN state;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION promo_revenue_finalfunc(state promo_revenue_accum) RETURNS DECIMAL(25, 5)
    IMMUTABLE AS
$$
BEGIN
    RETURN state.revenue;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION promo_revenue_mergefunc(state1 promo_revenue_accum, state2 promo_revenue_accum)
    RETURNS promo_revenue_accum
    IMMUTABLE AS
$$
DECLARE
    merged_promo_revenue promo_revenue_accum;
BEGIN
    merged_promo_revenue.revenue := (state1.revenue + state2.revenue);
    return merged_promo_revenue;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE AGGREGATE promo_revenue_agg(
    fetched_price DECIMAL(12, 2),
    fetched_discount DECIMAL(12, 2)
    ) (
    sfunc = promo_revenue_sfunc,
    stype = promo_revenue_accum,
    finalfunc = promo_revenue_finalfunc,
    initcond = '(0.0)',
    combinefunc = promo_revenue_mergefunc,
    parallel = safe
    );

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

/* Inlined UDF */
EXPLAIN ANALYZE SELECT p.P_PARTKEY, e.revenue
FROM part p
         LEFT OUTER JOIN (SELECT l_partkey, promo_revenue_agg(l_extendedprice , l_discount) as revenue
                            FROM lineitem
                            GROUP BY l_partkey) e ON e.L_PARTKEY = p.p_partkey
WHERE p.P_TYPE LIKE 'PROMO%%';
