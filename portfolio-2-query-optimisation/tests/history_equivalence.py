"""Compare complete original/rewritten history output for varied scale-seed customers.
Owner, author, maintainer: Emmanuel Madueke.
"""
import os
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
env = os.environ.copy()
env['PGOPTIONS'] = env.get('PGOPTIONS', '') + ' -c default_transaction_read_only=on -c timezone=Africa/Lagos'
psql = os.environ.get('PSQL_BIN', 'psql')
for email in ['femi@example.test', 'ibrahim@example.test', 'ada@example.test',
              'ngozi@example.test', 'scale-0004@example.test', 'scale-0001@example.test', 'absent@example.test']:
    outputs = []
    for folder in ['sql', 'optimisation']:
        result = subprocess.run([psql, '-X', '-q', '--csv', '-v', 'ON_ERROR_STOP=1',
            '-v', f'customer_email={email}', '-f', str(root/folder/'03_customer_history.sql')],
            env=env, capture_output=True, text=True, check=True)
        outputs.append(result.stdout)
    if outputs[0] != outputs[1]:
        raise AssertionError(f'History differs for {email}')
    print(f'PASS: original and rewritten history agree for {email}')
print('7 history-equivalence cases passed, including retries, no attempts, pending payments, and an absent customer.')
