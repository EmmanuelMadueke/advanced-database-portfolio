"""Compare captures from the same dataset, including ordered-result equivalence.
Owner, author, maintainer: Emmanuel Madueke.
"""
import argparse
import json
from pathlib import Path
import statistics

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('before', type=Path)
parser.add_argument('after', type=Path)
args = parser.parse_args()
b = json.loads((args.before/'environment.json').read_text())
a = json.loads((args.after/'environment.json').read_text())
for field in ['exact_row_counts', 'settings', 'parameters', 'server',
              'status_distribution', 'paid_day_distribution', 'category_distribution']:
    if b[field] != a[field]:
        raise SystemExit(f'FAIL: changed experiment condition: {field}')
print('PASS: connection, settings, parameters, counts and distributions match')
base_indexes = {(x['tablename'], x['indexname']): x['indexdef'] for x in b['indexes']}
after_indexes = {(x['tablename'], x['indexname']): x['indexdef'] for x in a['indexes']}
if any(after_indexes.get(k) != v for k,v in base_indexes.items()):
    raise SystemExit('FAIL: an existing index was removed or modified')
print(f'PASS: all {len(base_indexes)} pre-existing index definitions retained')
print('query,before_median_ms,after_median_ms,change_percent,before_hits,after_hits')
for path in sorted(args.before.glob('[0-9][0-9]_*.json')):
    old = json.loads(path.read_text())
    new = json.loads((args.after/path.name).read_text())
    if (old['result_sha256'], old['result_rows']) != (new['result_sha256'], new['result_rows']):
        raise SystemExit(f'FAIL: result differs: {path.stem}')
    ot = statistics.median(p['Execution Time'] for p in old['measured_plans'])
    nt = statistics.median(p['Execution Time'] for p in new['measured_plans'])
    print(f"{path.stem},{ot:.3f},{nt:.3f},{100*(nt/ot-1):.2f},"
          f"{old['measured_plans'][0]['Plan'].get('Shared Hit Blocks',0)},"
          f"{new['measured_plans'][0]['Plan'].get('Shared Hit Blocks',0)}")
print('PASS: all five full ordered-result fingerprints and row counts match')
