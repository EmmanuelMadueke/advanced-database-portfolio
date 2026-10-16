-- Owner, author, maintainer: Emmanuel Madueke
-- Session B waits for A, then must reject depleted stock and roll back its new order.
\set ON_ERROR_STOP off
SELECT retail.finalise_order(:order_id,'P3-PROTECTED-B','card');
\set failure_state :SQLSTATE
\set ON_ERROR_STOP on
ROLLBACK;
SELECT :'failure_state'='P0001' AS expected_failure \gset
\if :expected_failure
 \echo PASS: depleted-stock rejection P0001; losing purchase rolled back.
\else
 \echo FAIL: unexpected result :failure_state
 \quit 1
\endif
