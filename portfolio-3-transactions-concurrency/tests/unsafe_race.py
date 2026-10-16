"""Reproduce stale-read overselling in an isolated teaching schema.
Owner, author, maintainer: Emmanuel Madueke.
Run once after 09_unsafe_fixture.sql. Does not use retail checkout routines.
"""
import json
from isolation import Session

checks = 0
def check(label, condition):
    global checks
    if not condition:
        raise AssertionError(label)
    checks += 1
    print('PASS: ' + label, flush=True)

sessions = []
try:
    a = Session('A'); sessions.append(a)
    b = Session('B'); sessions.append(b)
    a.run('SELECT version();')
    initial = json.loads(a.script('12_unsafe_result.sql')[0])
    check('one available unit and no prior purchases', initial['stock']==1 and initial['purchases']==0)
    a.run("\\set buyer 'Buyer A'")
    b.run("\\set buyer 'Buyer B'")
    first = json.loads(a.script('10_unsafe_read.sql')[0])
    second = json.loads(b.script('10_unsafe_read.sql')[0])
    check('buyers use distinct sessions', first['pid'] != second['pid'])
    check('both transactions use READ COMMITTED', first['isolation']==second['isolation']=='read committed')
    check('both independently observed the same last unit', first['observed_stock']==second['observed_stock']==1)
    print('Schedule: both reads completed; A now writes and commits, then B uses its stale value.', flush=True)
    a.script('11_unsafe_accept.sql')
    b.script('11_unsafe_accept.sql')
    c = Session('Verifier'); sessions.append(c)
    result = json.loads(c.script('12_unsafe_result.sql')[0])
    check('verification uses a fresh connection', result['pid'] not in [first['pid'],second['pid']])
    check('both buyers committed one-unit purchases', result['purchases']==result['buyers']==result['units_sold']==2)
    check('nonnegative stock check passes despite overselling', result['stock']==0)
    check('conservation broken: stock plus sold units exceeds starting unit', result['stock']+result['units_sold']>1)
    print(f'{checks} unsafe-race checks passed: the intended defect was reproduced, not prevented.', flush=True)
finally:
    for session in reversed(sessions):
        session.close()
