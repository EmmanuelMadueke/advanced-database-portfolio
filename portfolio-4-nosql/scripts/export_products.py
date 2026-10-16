"""Export SQL catalogue facts without credentials; refuses to overwrite evidence.
Owner, author, maintainer: Emmanuel Madueke.
"""
import argparse
import json
import os
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('output', type=Path)
args = parser.parse_args()
if args.output.exists():
    raise SystemExit('Refusing to overwrite existing source export')
env = os.environ.copy()
env['PGOPTIONS'] = env.get('PGOPTIONS', '')+' -c default_transaction_read_only=on -c timezone=UTC'
r = subprocess.run([os.environ.get('PSQL_BIN','psql'),'-X','-qAt','-v','ON_ERROR_STOP=1',
 '-f',str(Path(__file__).with_suffix('.sql'))], env=env, text=True, capture_output=True, check=True)
data = json.loads(r.stdout)
args.output.parent.mkdir(parents=True, exist_ok=True)
with args.output.open('x') as f:
    json.dump(data,f,indent=2)
    f.write('\n')
print(f"Exported {len(data['products'])} products from {data['source_database']}")
