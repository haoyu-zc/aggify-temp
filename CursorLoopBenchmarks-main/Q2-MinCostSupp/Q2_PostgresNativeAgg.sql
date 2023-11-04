/* Postgres version of UDF using a native aggregate */
CREATE OR REPLACE FUNCTION MinCostSuppWithNativeAgg(pk bigint)
    RETURNS char(25)
    STABLE AS
$$
DECLARE
    key bigint := pk;
    val char(25);
BEGIN
    SELECT DISTINCT ON (ps_partkey) s_name, ps_partkey, ps_supplycost
    INTO val
    FROM partsupp ps,
         supplier s
    WHERE ps.PS_PARTKEY = key
      AND ps.PS_SUPPKEY = s.S_SUPPKEY
    ORDER BY ps_partkey, ps_supplycost;
    RETURN val;
END;
$$ LANGUAGE plpgsql;


/* UDF call */
EXPLAIN ANALYZE
SELECT P_PARTKEY, MinCostSuppWithNativeAgg(P_PARTKEY)
FROM part;

EXPLAIN ANALYZE SELECT p.P_PARTKEY,
       e.min_supp
FROM part p
         LEFT OUTER JOIN (SELECT DISTINCT ON (ps_partkey) ps_partkey, ps_supplycost, s_name as min_supp
                          FROM partsupp ps,
                               supplier s
                          WHERE ps.PS_SUPPKEY = s.S_SUPPKEY
                          ORDER BY ps_partkey, ps_supplycost) e ON p.p_partkey = e.PS_PARTKEY;