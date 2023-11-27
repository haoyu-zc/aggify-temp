-- Internal states
CREATE TYPE min_cost_state AS (
    min_cost DECIMAL(15, 2),
    supp_name CHAR(25),
    is_initialized BOOLEAN
);

-- Update function
CREATE OR REPLACE FUNCTION f_update(
    current_cost DECIMAL(15, 2), 
    current_name CHAR(25), 
    pmin_cost DECIMAL(15, 2), 
)
RETURNS min_cost_state
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT state.is_initialized THEN
        state.min_cost := pmin_cost;
        state.is_initialized := true;
    END IF;
    IF current_cost < state.min_cost THEN
        state.min_cost := current_cost;
        state.supp_name := current_name;
    END IF;
    RETURN state;
END;
$$;

-- Finalize function
CREATE OR REPLACE FUNCTION f_finalize()
RETURNS CHAR(25)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN state.supp_name;
END;
$$;

-- Aggregate
CREATE AGGREGATE MinCostSuppAggregate ()
(
    BASETYPE = DECIMAL(15, 2),
    STYPE = min_cost_state,
    SFUNC = f_update,
    FINALFUNC = f_finalize
    -- stype.min_cost = 100000,
    stype.supp_name = '',
    stype.is_initialized = false
);

-- UDF, Wrapper
CREATE OR REPLACE FUNCTION MinCostSuppWithCustomAgg(pk BIGINT)
RETURNS CHAR(25)
LANGUAGE plpgsql AS $$
DECLARE
    key         bigint         := pk;
    val         CHAR(25);
    pmin_cost   DECIMAL(25, 2) := 100000;
BEGIN
    SELECT MinCostSuppAggregate(PS_SUPPLYCOST, S_NAME, pmin_cost)
    FROM (SELECT PS_SUPPLYCOST, S_NAME
                                     FROM partsupp,
                                          supplier
                                     WHERE PS_PARTKEY = key
                                       AND PS_SUPPKEY = S_SUPPKEY) S
    INTO val;
    RETURN val;
END;
$$;

-- UDF Call
SELECT P_PARTKEY, MinCostSuppWithCustomAgg(P_PARTKEY)
FROM part;
