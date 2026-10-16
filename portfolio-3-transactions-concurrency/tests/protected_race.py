"""Verify the existing checkout locks prevent last-unit overselling.
Owner, author, maintainer: Emmanuel Madueke.
Run once after 13_protected_fixture.sql in a fresh database.
"""
from concurrent.futures import ThreadPoolExecutor
import json
import time
from isolation import Session

checks = 0
def check(label, condition):
    global checks
    if not condition:
        raise AssertionError(label)
    checks += 1
    print('PASS: '+label, flush=True)

sessions = []
try:
    a = Session('A'); sessions.append(a)
    b = Session('B'); sessions.append(b)
    monitor = Session('Monitor'); sessions.append(monitor)
    a.run('SELECT version();')
    initial = json.loads(monitor.script('17_protected_result.sql')[0])
    check('fresh fixture: one shirt, no purchases', initial['stock']==1 and initial['orders']==initial['items']==initial['payments']==0)
    a.run("\\set email 'commit@example.test'")
    b.run("\\set email 'second@example.test'")
    first = json.loads(a.script('14_protected_prepare.sql')[0])
    second = json.loads(b.script('14_protected_prepare.sql')[0])
    check('distinct sessions and pending order identities', first['pid']!=second['pid'] and first['order_id']!=second['order_id'])
    check('both controlled READ COMMITTED buyers initially see one unit', all(x['stock']==1 and x['isolation']=='read committed' and x['role']=='fashion_portfolio_writer' for x in [first,second]))
    a.script('15_protected_winner.sql')
    with ThreadPoolExecutor(max_workers=1) as executor:
        waiting = executor.submit(b.script, '16_protected_loser.sql')
        deadline = time.monotonic()+5
        while True:
            row = json.loads(monitor.run(f"SELECT json_build_object('blockers',pg_blocking_pids({second['pid']}),'wait_type',wait_event_type,'wait_event',wait_event) FROM pg_stat_activity WHERE pid={second['pid']};")[0])
            if first['pid'] in row['blockers'] and row['wait_type']=='Lock':
                break
            if waiting.done() or time.monotonic()>deadline:
                raise AssertionError('B did not demonstrably wait on A')
            time.sleep(0.05)  # Poll actual lock state; elapsed time never authorises commit.
        check('database confirms B blocked by A on a lock', first['pid'] in row['blockers'])
        print('A: COMMIT after confirmed blocking', flush=True)
        a.run('COMMIT;')
        rejection = waiting.result(timeout=15)
    check('B rejected for stock depletion, then explicitly rolled back',
          any('insufficient stock or inactive variant' in s for s in rejection) and
          any('depleted-stock rejection P0001' in s for s in rejection))
    v = Session('Verifier'); sessions.append(v)
    result = json.loads(v.script('17_protected_result.sql')[0])
    check('fresh verifier connection', result['pid'] not in [first['pid'],second['pid']])
    check('only one paid order, line, unit, and successful payment persist',
          all(result[k]==1 for k in ['orders','paid_orders','items','units','payments','successes']) and result['reconciled'])
    check('loser has no retained order', result['loser_orders']==0)
    check('stock conserved and unrelated jacket unchanged', result['stock']==0 and result['stock']+result['units']==1 and result['jacket_stock']==5)
    print('A: retry finalisation of known committed order', flush=True)
    replay = a.run("BEGIN; SET LOCAL ROLE fashion_portfolio_writer; SELECT retail.finalise_order(:order_id,'P3-PROTECTED-A','card')=:payment_id; COMMIT;")
    check('known-order replay returns same payment', replay==['t'])
    after = json.loads(v.script('17_protected_result.sql')[0])
    check('replay leaves all verified purchase and stock values unchanged', after==result)
    print(f'{checks} protected-race checks passed.', flush=True)
finally:
    for session in reversed(sessions):
        session.close()
