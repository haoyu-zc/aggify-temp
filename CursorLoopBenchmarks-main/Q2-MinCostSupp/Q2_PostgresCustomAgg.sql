CREATE TYPE mincostsupp_state AS
(
    min_cost      DECIMAL(15, 2),
    supplier_name CHAR(25)
);

CREATE OR REPLACE FUNCTION mincostsupp_statefunc(state mincostsupp_state, new_row mincostsupp_state)
    RETURNS mincostsupp_state
    IMMUTABLE STRICT
AS
$$
BEGIN
    IF new_row.min_cost < state.min_cost THEN
        state = new_row;
    END IF;
    RETURN state;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION mincostsupp_finalfunc(state mincostsupp_state)
    RETURNS CHAR(25)
    IMMUTABLE STRICT
AS
$$
BEGIN
    RETURN state.supplier_name;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION mincostsupp_mergefunc(state1 mincostsupp_state, state2 mincostsupp_state)
    RETURNS mincostsupp_state
    IMMUTABLE STRICT
AS
$$
BEGIN
    IF state1.min_cost < state2.min_cost THEN
        RETURN state1;
    END IF;
        RETURN state2;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE AGGREGATE MinCostSuppAgg(mincostsupp_state)
    (
    sfunc = mincostsupp_statefunc,
    stype = mincostsupp_state,
    finalfunc = mincostsupp_finalfunc,
    combinefunc = mincostsupp_mergefunc,
    parallel = safe
    );

/* Postgres version of UDF using aggregate */
CREATE OR REPLACE FUNCTION MinCostSuppWithCustomAgg(pk bigint)
    RETURNS char(25)
    STABLE
AS
$$
DECLARE
    key bigint := pk;
    val char(25);
BEGIN
    SELECT MinCostSuppAgg((PS_SUPPLYCOST, S_NAME)::mincostsupp_state)
    FROM (SELECT PS_SUPPLYCOST, S_NAME
          FROM partsupp,
               supplier
          WHERE PS_PARTKEY = key
            AND PS_SUPPKEY = S_SUPPKEY) AS foo
    INTO val;
    return val;
END;
$$ LANGUAGE plpgsql;

/* UDF call */
EXPLAIN ANALYZE
SELECT P_PARTKEY, MinCostSuppWithCustomAgg(P_PARTKEY)
FROM part;

EXPLAIN ANALYZE SELECT p.P_PARTKEY, e.min_supp
FROM part p
         LEFT OUTER JOIN (SELECT ps_partkey, MinCostSuppAgg((ps_supplycost, s_name)::mincostsupp_state) as min_supp
                          FROM partsupp,
                               supplier
                          WHERE ps_suppkey = s_suppkey
                          GROUP BY ps_partkey) e ON p.p_partkey = e.ps_partkey;
