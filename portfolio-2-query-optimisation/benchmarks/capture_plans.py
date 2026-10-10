"""Capture reproducible SELECT-only EXPLAIN evidence and result fingerprints.
Owner, author, maintainer: Emmanuel Madueke.
Run after Portfolio 1 seed scripts 01–06. No optimisation indexes are created.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import statistics
import subprocess
import csv

ROOT = Path(__file__).resolve().parents[1]
SELECTED = [1, 3, 4, 6, 10]
PARAMETERS = {
    'category': 'Clothing', 'brand': 'Lagos Threads', 'audience': 'unisex',
    'size': 'M', 'colour': 'Black', 'min_price': '0', 'max_price': '20000',
    'customer_email': 'scale-0004@example.test',
    'from_date': '2026-01-01', 'until_date': '2027-01-01',
}
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output', type=Path, default=ROOT / 'evidence' / 'baseline')
parser.add_argument('--runs', type=int, default=5)
args = parser.parse_args()
if args.runs < 3:
    parser.error('Use at least three measured runs.')
if args.output.exists():
    parser.error('Choose a new output directory; existing evidence is not overwritten.')
args.output.mkdir(parents=True)
PSQL = os.environ.get('PSQL_BIN', 'psql')
ENV = os.environ.copy()
ENV['PGOPTIONS'] = (ENV.get('PGOPTIONS', '') +
    ' -c default_transaction_read_only=on -c timezone=Africa/Lagos -c statement_timeout=30000').strip()

def execute(sql, parameters=None):
    command = [PSQL, '-X', '-q', '-A', '-t', '-v', 'ON_ERROR_STOP=1']
    for k, v in (parameters or {}).items():
        command += ['-v', f'{k}={v}']
    process = subprocess.run(command, input=sql, text=True, capture_output=True, env=ENV, check=True)
    return process.stdout.strip()

def json_sql(sql):
    return json.loads(execute(sql))

metadata = {
    'captured_at_utc': datetime.now(timezone.utc).isoformat(),
    'protocol': {'warmup_runs_per_query': 1, 'measured_runs_per_query': args.runs,
                 'explain': 'ANALYZE, BUFFERS, TIMING OFF, FORMAT JSON',
                 'connection': 'new psql connection per run; connection time excluded from server timings',
                 'cache': 'not cleared; seed/ANALYZE and warm-up precede measurement',
                 'role': 'schema owner; read-only connections',
                 'parallel_activity': 'no deliberately concurrent workload; host noise uncontrolled'},
    'parameters': PARAMETERS,
    'server': json_sql("SELECT json_build_object('version',version(),'database',current_database(),"
        "'isolation',current_setting('transaction_isolation'),'timezone',current_setting('TimeZone'));")
}
metadata['settings'] = json_sql("SELECT coalesce(json_agg(x ORDER BY name),'[]'::json) FROM "
    "(SELECT name,setting,unit,source FROM pg_settings WHERE name IN "
    "('shared_buffers','work_mem','effective_cache_size','random_page_cost','seq_page_cost',"
    "'max_parallel_workers_per_gather','default_statistics_target','jit','track_io_timing',"
    "'enable_seqscan','enable_indexscan','enable_bitmapscan')) x;")
metadata['tables'] = json_sql("SELECT json_agg(x ORDER BY table_name) FROM ("
    "SELECT c.relname AS table_name,c.reltuples::bigint AS estimated_rows,c.relpages AS pages "
    "FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='retail' AND c.relkind='r') x;")
counts = {}
for item in metadata['tables']:
    table = item['table_name']
    counts[table] = int(execute(f'SELECT count(*) FROM retail.{table};'))
metadata['exact_row_counts'] = counts
if counts.get('orders') != 10012 or counts.get('product_variants') != 1218:
    raise RuntimeError('Expected sample plus default 10,000-order scale dataset.')
metadata['indexes'] = json_sql("SELECT json_agg(x ORDER BY tablename,indexname) FROM "
    "(SELECT tablename,indexname,indexdef FROM pg_indexes WHERE schemaname='retail') x;")
metadata['statistics'] = json_sql("SELECT json_agg(x ORDER BY relname) FROM "
    "(SELECT relname,last_analyze,last_autoanalyze,n_live_tup,n_dead_tup FROM pg_stat_user_tables WHERE schemaname='retail') x;")
metadata['status_distribution'] = json_sql("SELECT json_agg(x ORDER BY status) FROM "
    "(SELECT status,count(*) AS rows FROM retail.orders GROUP BY status) x;")
metadata['paid_day_distribution'] = json_sql("SELECT json_agg(x ORDER BY paid_day) FROM "
    "(SELECT (paid_at AT TIME ZONE 'Africa/Lagos')::date AS paid_day,count(*) AS rows "
    "FROM retail.orders WHERE paid_at IS NOT NULL GROUP BY 1) x;")
metadata['category_distribution'] = json_sql("SELECT json_agg(x ORDER BY category) FROM "
    "(SELECT c.name AS category,count(*) AS products FROM retail.products p "
    "JOIN retail.categories c USING(category_id) GROUP BY c.name) x;")
measurements = []
summaries = []
for number in SELECTED:
    path, = (ROOT/'sql').glob(f'{number:02d}_*.sql')
    source = path.read_text()
    start = re.search(r'(?m)^(SELECT|WITH)\b', source).start()
    prelude, statement = source[:start], source[start:].strip().rstrip(';')
    # The numbered report files contain one SELECT/WITH statement each.
    if ';' in statement:
        raise ValueError('Only single read-only report statements are supported.')
    result = json.loads(execute(prelude + '\nSELECT coalesce(json_agg(row_to_json(q)),\'[]\'::json) FROM (\n' +
        statement + '\n) q;', PARAMETERS))
    result_hash = hashlib.sha256(json.dumps(result, sort_keys=True, separators=(',', ':')).encode()).hexdigest()
    explained = prelude + '\nEXPLAIN (ANALYZE, BUFFERS, TIMING OFF, FORMAT JSON)\n' + statement + ';'
    warmup = json.loads(execute(explained, PARAMETERS))[0]
    plans = []
    for run in range(1, args.runs+1):
        plan = json.loads(execute(explained, PARAMETERS))[0]
        plans.append(plan)
        top = plan['Plan']
        measurements.append({'query': path.stem, 'run': run,
            'planning_ms': plan['Planning Time'], 'execution_ms': plan['Execution Time'],
            'returned_rows': top['Actual Rows'], 'shared_hit_blocks': top.get('Shared Hit Blocks', 0),
            'shared_read_blocks': top.get('Shared Read Blocks', 0),
            'temp_read_blocks': top.get('Temp Read Blocks', 0), 'temp_written_blocks': top.get('Temp Written Blocks', 0)})
    evidence = {'source_file': str(path.relative_to(ROOT)),
        'source_sha256': hashlib.sha256(source.encode()).hexdigest(),
        'parameters': PARAMETERS, 'result_rows': len(result), 'result_sha256': result_hash,
        'result_sample_first_five_rows': result[:5], 'warmup': warmup, 'measured_plans': plans}
    (args.output/(path.stem+'.json')).write_text(json.dumps(evidence, indent=2)+'\n')
    times = [p['Execution Time'] for p in plans]
    summaries.append({'query': path.stem, 'rows': len(result),
        'median_execution_ms': statistics.median(times), 'min_execution_ms': min(times), 'max_execution_ms': max(times)})
    print(f'{path.stem}: {len(result)} rows; median execution {statistics.median(times):.3f} ms ({args.runs} runs)')
metadata['summaries'] = summaries
(args.output/'environment.json').write_text(json.dumps(metadata, indent=2)+'\n')
with (args.output/'measurements.csv').open('w', newline='') as file:
    writer = csv.DictWriter(file, fieldnames=list(measurements[0]))
    writer.writeheader()
    writer.writerows(measurements)
print('Captured 1 warm-up and repeated measured plans per query; no optimisation indexes added.')
