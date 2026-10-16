"""Coordinate two persistent psql connections without timing-based sleeps.
Owner, author, maintainer: Emmanuel Madueke.
Requires a fresh database with scripts 01–04 and 01_commit_fixture.sql loaded.
"""
import json
import os
from pathlib import Path
from queue import Queue, Empty
import subprocess
from threading import Thread
import uuid

ROOT = Path(__file__).resolve().parents[1]

class Session:
    def __init__(self, name):
        self.name = name
        self.lines = Queue()
        self.proc = subprocess.Popen(
            [os.environ.get('PSQL_BIN', 'psql'), '-X', '-qAt', '-v', 'ON_ERROR_STOP=1'],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True, bufsize=1)
        def read():
            for line in self.proc.stdout:
                self.lines.put(line.rstrip('\n'))
            self.lines.put(None)
        Thread(target=read, daemon=True).start()
        self.run("SET statement_timeout='10s'; SET idle_in_transaction_session_timeout='60s';")

    def run(self, sql):
        marker = 'DONE_' + uuid.uuid4().hex
        self.proc.stdin.write(sql + '\n\\echo ' + marker + '\n')
        self.proc.stdin.flush()
        output = []
        while True:
            try:
                line = self.lines.get(timeout=15)
            except Empty:
                raise RuntimeError(f'{self.name}: timed out waiting for completion')
            if line is None:
                raise RuntimeError(f'{self.name}: psql exited: {output}')
            if line == marker:
                return output
            print(f'{self.name}: {line}', flush=True)
            output.append(line)

    def script(self, name):
        print(f'{self.name}: execute {name}', flush=True)
        return self.run((ROOT/'sql'/name).read_text())

    def observe(self):
        return json.loads(self.script('08_isolation_observation.sql')[0])

    def close(self):
        if self.proc.poll() is None:
            self.proc.stdin.close()  # EOF also rolls back any still-open transaction.
            try:
                self.proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.proc.terminate()
                self.proc.wait(timeout=5)

checks = 0
def check(label, condition):
    global checks
    if not condition:
        raise AssertionError(label)
    checks += 1
    print('PASS: ' + label, flush=True)

def state(row):
    return [row[k] for k in ['orders','items','payments','paid_orders','successes','revenue','shirt','jacket']]

sessions = []
try:
    a = Session('A'); sessions.append(a)
    b = Session('B'); sessions.append(b)
    a.run('SELECT version();')
    b.script('07_isolation_observer.sql')
    before = b.observe()
    check('starting fixture has no purchases and stock 10/5', state(before)==[0,0,0,0,0,0,10,5])
    a.script('06_isolation_writer.sql')
    own = a.observe()
    check('two distinct PostgreSQL sessions', own['pid'] != before['pid'])
    check('both transactions use READ COMMITTED and controlled writer role',
          all(x['isolation']=='read committed' and x['role']=='fashion_portfolio_writer' for x in [before,own]))
    check('A sees its own uncommitted purchase and deductions', state(own)==[1,2,1,1,1,49000,8,4])
    hidden = b.observe()
    check('B sees only original committed state while A stays open', state(hidden)==state(before))
    print('A: COMMIT (only after B completed the uncommitted-state observation)', flush=True)
    a.run('COMMIT;')
    visible = b.observe()
    check('same observer connection remains read-only',
          before['pid']==hidden['pid']==visible['pid'] and all(x['read_only']=='on' for x in [before,hidden,visible]))
    check('B next statement sees complete purchase after A commit', state(visible)==state(own))
    print('B: COMMIT (close the same observer transaction)', flush=True)
    b.run('COMMIT;')
    print(f'{checks} two-session isolation checks passed.', flush=True)
finally:
    for session in reversed(sessions):
        session.close()
