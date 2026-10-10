"""Verify actual report files against known business outcomes on unscaled sample data.
Owner, author, maintainer: Emmanuel Madueke.
Uses standard-library CSV/subprocess and psql; no duplicated report SQL.
Connection is configured through PGHOST/PGPORT/PGDATABASE/PGUSER.
"""
import csv
import io
import os
from pathlib import Path
import subprocess
from decimal import Decimal
from datetime import date, timedelta

SQL = Path(__file__).resolve().parents[1] / 'sql'
PSQL = os.environ.get('PSQL_BIN', 'psql')
checks = 0

PERIOD = {}

def report(number, **parameters):
    timezone = parameters.pop('_timezone', 'Africa/Lagos')
    if 6 <= number <= 11:
        parameters = {**PERIOD, **parameters}
    files = list(SQL.glob(f'{number:02d}_*.sql'))
    assert len(files) == 1
    command = [PSQL, '-X', '-q', '--csv', '-v', 'ON_ERROR_STOP=1']
    for key, value in parameters.items():
        command.extend(['-v', f'{key}={value}'])
    command.extend(['-f', str(files[0])])
    env = os.environ.copy()
    env['PGOPTIONS'] = (env.get('PGOPTIONS', '') +
                        f' -c default_transaction_read_only=on -c timezone={timezone}').strip()
    result = subprocess.run(command, capture_output=True, text=True, env=env, check=True)
    return list(csv.DictReader(io.StringIO(result.stdout)))

def check(label, condition):
    global checks
    if not condition:
        raise AssertionError(label)
    checks += 1
    print(f'PASS: {label}')

def total(rows, key):
    return sum((Decimal(row[key]) for row in rows), Decimal(0))

# Infer the loaded seed year from the actual history; query-file defaults remain 2026.
seed_history = report(3)
assert len(seed_history) == 1, 'Run against the unscaled sample seed.'
seed_year = date.fromisoformat(seed_history[0]['created_at'][:10]).year
PERIOD.update(from_date=f'{seed_year}-01-01', until_date=f'{seed_year + 1}-01-01')

catalogue = report(1)
check('catalogue filters return the stocked black medium T-shirt',
      len(catalogue) == 1 and catalogue[0]['sku'] == 'TEE-BLK-M')
check('out-of-stock catalogue variant excluded',
      not report(1, size='L'))
check('inclusive catalogue price boundary',
      len(report(1, min_price='12000', max_price='12000')) == 1)
stock = report(2)
check('inventory has all 18 variants', len(stock) == 18)
check('low-stock filter identifies expected variants',
      {x['sku'] for x in report(2, stock_filter='low_stock')} == {'LIN-BLU-L', 'DRS-BLK-M'})
check('zero-stock filter identifies expected variants',
      {x['sku'] for x in report(2, stock_filter='out_of_stock')} == {'TEE-BLK-L', 'SNK-WHT-42'})
history = report(3)
check('failed then successful payment produces one history row',
      len(history) == 1 and history[0]['payment_attempts'] == '2'
      and history[0]['failed_attempts'] == '1'
      and Decimal(history[0]['total_amount']) == Decimal('22500'))
check('customer email is trimmed and case-normalised',
      report(3, customer_email=' FEMI@EXAMPLE.TEST ') == history)
check('unknown email returns empty history', not report(3, customer_email='absent@example.test'))
check('quoted input is treated as an email literal',
      not report(3, customer_email="x' OR '1'='1"))
open_orders = report(4)
check('open orders include seven awaiting payment/fulfilment/delivery',
      len(open_orders) == 7 and {x['order_status'] for x in open_orders} ==
      {'pending', 'paid', 'processing', 'dispatched'})
check('delivery report includes all six shipments', len(report(5)) == 6)
check('dispatched delivery filter returns two shipments',
      len(report(5, delivery_filter='dispatched')) == 2)
variants = report(6)
check('variant sales reconcile to 14 sold units and NGN 268000',
      total(variants, 'units_sold') == 14 and total(variants, 'revenue_ngn') == 268000)
check('pending-only dress variant excluded from best sellers',
      'DRS-BLK-M' not in {x['sku'] for x in variants})
products = report(7)
check('product sales cover eight products and reconcile',
      len(products) == 8 and total(products, 'revenue_ngn') == 268000)
check('sneaker product sales equal NGN 70000',
      next(x for x in products if x['current_product_name'] == 'Canvas Sneakers')['revenue_ngn'] == '70000.00')
categories = report(8)
check('category revenue matches independent expected amounts',
      {x['current_category']: Decimal(x['revenue_ngn']) for x in categories} ==
      {'Clothing': Decimal(136000), 'Footwear': Decimal(96000), 'Accessories': Decimal(36000)})
monthly = report(9)
check('monthly report includes all 12 calendar months and reconciles',
      len(monthly) == 12 and total(monthly, 'revenue_ngn') == 268000
      and total(monthly, 'paid_orders') == 8)
summary = report(10)[0]
check('summary gives eight paid orders, NGN 268000 and average NGN 33500',
      summary['paid_orders'] == '8' and Decimal(summary['revenue_ngn']) == 268000
      and Decimal(summary['average_order_ngn']) == 33500)
activity = report(11)
check('all 12 customers included, including four zero-spend customers',
      len(activity) == 12 and sum(Decimal(x['total_spend_ngn']) == 0 for x in activity) == 4
      and total(activity, 'total_spend_ngn') == 268000)
exceptions = report(12)
check('unresolved payment attempts exclude the successful retry customer',
      len(exceptions) == 3 and {x['email'] for x in exceptions} ==
      {'bisi@example.test', 'ife@example.test', 'ngozi@example.test'})
check('empty sales period returns zero summary',
      Decimal(report(10, from_date='2000-01-01', until_date='2001-01-01')[0]['revenue_ngn']) == 0)
check('empty calendar year still returns 12 zero months',
      len(report(9, from_date='2000-01-01', until_date='2001-01-01')) == 12
      and total(report(9, from_date='2000-01-01', until_date='2001-01-01'), 'paid_orders') == 0)
check('same start/end date is an empty half-open interval',
      report(10, from_date='2026-10-10', until_date='2026-10-10')[0]['paid_orders'] == '0'
      and not report(9, from_date='2026-10-10', until_date='2026-10-10'))
check('zero-sales categories retained for empty period',
      len(report(8, from_date='2000-01-01', until_date='2001-01-01')) == 3
      and total(report(8, from_date='2000-01-01', until_date='2001-01-01'), 'revenue_ngn') == 0)
paid_dates = [date.fromisoformat(x['last_paid_at'][:10]) for x in activity if x['last_paid_at']]
first_day, next_day = min(paid_dates), max(paid_dates) + timedelta(days=1)
check('date range starts inclusively on the first paid Lagos day',
      Decimal(report(10, from_date=str(first_day), until_date=str(next_day))[0]['revenue_ngn']) == 268000)
check('until_date excludes sales on that Lagos calendar day',
      report(10, from_date='1900-01-01', until_date=str(first_day))[0]['paid_orders'] == '0')
check('sales summary is invariant under UTC session timezone',
      report(10, _timezone='UTC') == report(10))
check('monthly grouping is invariant under UTC session timezone',
      report(9, _timezone='UTC') == monthly)
print(f'{checks} query-result checks passed. No application records were modified.')
