-- Owner, author, maintainer: Emmanuel Madueke
-- Session B: keep this transaction open across both observations.
\set ON_ERROR_STOP on
BEGIN ISOLATION LEVEL READ COMMITTED READ ONLY;
SET LOCAL ROLE fashion_portfolio_writer;
