#!/bin/bash

REPLICA='m101'

# Cleaning everything
echo "Cleaning old mongo processes and data."
sudo killall mongos > /dev/null 2>&1
sudo killall mongod > /dev/null 2>&1

# Sleep because it takes some time for killing old processes
sleep 3

sudo rm -R /data/ > /dev/null 2>&1

#Creating default folders
echo "Creating folders for data and log."
sudo mkdir -p /data/mongo/data/ /data/mongo/logs/

# Creating folders for replica set
sudo mkdir -p /data/mongo/data/$REPLICA-1/ /data/mongo/data/$REPLICA-2/ /data/mongo/data/$REPLICA-3/
sudo touch /data/mongo/logs/$REPLICA-1.log /data/mongo/logs/$REPLICA-2.log /data/mongo/logs/$REPLICA-3.log

# Setup owners
sudo chown -R mongodb:mongodb /data/mongo

echo "Starting processes."
sudo su -s /bin/bash -c "mongod --logpath /data/mongo/logs/$REPLICA-1.log --fork --dbpath /data/mongo/data/$REPLICA-1/ --port 27017 --replSet $REPLICA" mongodb
sudo su -s /bin/bash -c "mongod --logpath /data/mongo/logs/$REPLICA-2.log --fork --dbpath /data/mongo/data/$REPLICA-2/ --port 27018 --replSet $REPLICA" mongodb
sudo su -s /bin/bash -c "mongod --logpath /data/mongo/logs/$REPLICA-3.log --fork --dbpath /data/mongo/data/$REPLICA-3/ --port 27019 --replSet $REPLICA" mongodb

mongo --port 27017 << 'EOF'
config = {
	"_id": "m101",
	"members": [
		{"_id": 1, "host": "127.0.0.1:27017"},
		{"_id": 2, "host": "127.0.0.1:27018"},
		{"_id": 3, "host": "127.0.0.1:27019"},
	]
};
rs.initiate(config);
EOF
