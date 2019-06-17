

# timestamps in cassandra: https://datastax.github.io/python-driver/dates_and_times.html

# nonprepared statements in cassandra: https://datastax.github.io/python-driver/getting_started.html#passing-parameters-to-cql-queries

from cassandra.cluster import Cluster
from datetime import datetime
import time

cluster = Cluster()
session = cluster.connect()

session.execute("create keyspace if not exists keyspace_state_aa with replication = {'class':'SimpleStrategy', 'replication_factor':3};")
session.execute("use keyspace_state_aa;")

# Two tables, state and visits.
# Table state should have single row per user.
# Table visits should have multiple rows per user, ordered by timestamp.


# Ordering by timestamp desc means when we do "LIMIT n", we get the n most recent rows.
session.execute('create table model_state(user_id bigint, state text, primary key ((user_id))  );')
# session.execute('drop table model_state;')


state = "ABCD" * 3
for i in range(0, 4):
    session.execute('insert into model_state(user_id, state) values (%s, %s);', [i, state])

rows = session.execute('select * from model_state')
print(rows.current_rows.__len__())



# Ordering by timestamp desc means when we do "LIMIT n", we get the n rows with greatest time stamps (most recent).
session.execute('create table user_visits(user_id bigint, ts timestamp, features text, primary key ((user_id), ts))'
    + 'with clustering order by (ts desc);')
# session.execute('drop table user_visits;')

features = "WXYZ" * 3
for j in range(0, 2):
    ts = datetime.now()
    for i in range(0, 4):
        session.execute('insert into user_visits(user_id, ts, features) values (%s, %s, %s);', [i, ts, features])
    time.sleep(0.5)


rows = session.execute('select * from user_visits where user_id = %s;', [1])
for row in rows:
    print(row)
print()
rows = session.execute('select * from user_visits where user_id = %s limit 1;', [1])
for row in rows:
    print(row)

count = session.execute('select count(user_id) as stat from user_visits;')
print(count[0])


