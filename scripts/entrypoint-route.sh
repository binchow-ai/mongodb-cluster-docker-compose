#!/bin/bash
  
# Wait for the config server replica set to elect a primary
echo "Waiting for config server replica set to elect a primary..."
until mongosh --host rs-config-server/mongo-config-01:27017,mongo-config-02:27017,mongo-config-03:27017 --eval 'rs.status().members.some(m => m.stateStr === "PRIMARY")' | grep -q 'true'; do
  sleep 5
done

# Wait for each shard's replica set to elect a primary
for shard in 1 2; do
  replica_set="rs-shard-0${shard}"
  host_prefix="shard-0${shard}-node"
  echo "Waiting for ${replica_set} to elect a primary..."
  until mongosh --host ${replica_set}/${host_prefix}-a:27017,${host_prefix}-b:27017,${host_prefix}-c:27017 --eval 'rs.status().members.some(m => m.stateStr === "PRIMARY")' | grep -q 'true'; do
    sleep 5
  done
done

# Start mongos in the background
echo "Starting mongos..."
mongos --config /etc/mongod.conf --configdb rs-config-server/mongo-config-01:27017,mongo-config-02:27017,mongo-config-03:27017 --bind_ip_all &

# Wait for mongos to become available
echo "Waiting for mongos to start..."
until mongosh --port 27017 --eval 'db.adminCommand({ping: 1})' &> /dev/null; do
  sleep 5
done

# Add the shards using the provided commands
echo "Adding shards..."
mongosh --port 27017 <<EOF
sh.addShard("rs-shard-01/shard-01-node-a:27017,shard-01-node-b:27017,shard-01-node-c:27017")
sh.addShard("rs-shard-02/shard-02-node-a:27017,shard-02-node-b:27017,shard-02-node-c:27017")
EOF

# Keep the mongos process running in the foreground
wait