#!/bin/bash

SHARD1='shard1'
SHARD2='shard2'
SHARD3='shard3'

REPLICA='rs'

# Cleaning everything
echo "Cleaning old mongo processes and data."
sudo killall mongos > /dev/null 2>&1
sudo killall mongod > /dev/null 2>&1

# Sleep because it takes some time for killing old processes
sleep 3

sudo rm -R /data/ > /dev/null 2>&1

#Creating default folders
echo "Creating folders for data and log."
sudo mkdir -p /data/mongo/data/ /data/mongo/logs/ /data/mongo/config/

# Creating folders for replica set
sudo mkdir -p /data/mongo/data/"$SHARD1"/"$REPLICA"-1/ /data/mongo/data/"$SHARD1"/"$REPLICA"-2/ /data/mongo/data/"$SHARD1"/"$REPLICA"-3/
sudo mkdir -p /data/mongo/data/"$SHARD2"/"$REPLICA"-1/ /data/mongo/data/"$SHARD2"/"$REPLICA"-2/ /data/mongo/data/"$SHARD2"/"$REPLICA"-3/
sudo mkdir -p /data/mongo/data/"$SHARD3"/"$REPLICA"-1/ /data/mongo/data/"$SHARD3"/"$REPLICA"-2/ /data/mongo/data/"$SHARD3"/"$REPLICA"-3/

sudo mkdir -p /data/mongo/config/"$SHARD1"/ /data/mongo/config/"$SHARD2"/ /data/mongo/config/"$SHARD3"/

sudo touch /data/mongo/logs/"$SHARD1"_"$REPLICA"-1.log /data/mongo/logs/"$SHARD1"_"$REPLICA"-2.log /data/mongo/logs/"$SHARD1"_"$REPLICA"-3.log
sudo touch /data/mongo/logs/"$SHARD2"_"$REPLICA"-1.log /data/mongo/logs/"$SHARD2"_"$REPLICA"-2.log /data/mongo/logs/"$SHARD2"_"$REPLICA"-3.log
sudo touch /data/mongo/logs/"$SHARD3"_"$REPLICA"-1.log /data/mongo/logs/"$SHARD3"_"$REPLICA"-2.log /data/mongo/logs/"$SHARD3"_"$REPLICA"-3.log
sudo touch /data/mongo/logs/"$SHARD1"_config.log /data/mongo/logs/"$SHARD2"_config.log /data/mongo/logs/"$SHARD3"_config.log

# Setup owners
sudo chown -R mongodb:mongodb /data/mongo

# Starting first shard replica set.
echo "Starting $SHARD1 replica set."
sudo su -s /bin/bash -c "mongod --logpath /data/mongo/logs/"$SHARD1"_"$REPLICA"-1.log --fork --dbpath /data/mongo/data/$SHARD1/$REPLICA-1/ --port 37017 --replSet $SHARD1" mongodb
sudo su -s /bin/bash -c "mongod --logpath /data/mongo/logs/"$SHARD1"_"$REPLICA"-2.log --fork --dbpath /data/mongo/data/$SHARD1/$REPLICA-2/ --port 37018 --replSet $SHARD1" mongodb
sudo su -s /bin/bash -c "mongod --logpath /data/mongo/logs/"$SHARD1"_"$REPLICA"-3.log --fork --dbpath /data/mongo/data/$SHARD1/$REPLICA-3/ --port 37019 --replSet $SHARD1" mongodb

mongo --port 37017 <<EOF
config = {
	"_id": "$SHARD1",
	"members": [
		{"_id": 1, "host": "127.0.0.1:37017"},
		{"_id": 2, "host": "127.0.0.1:37018"},
		{"_id": 3, "host": "127.0.0.1:37019"},
	]
};
rs.initiate(config);
EOF

# Starting second shard replica set.
echo "Starting $SHARD2 replica set."
sudo su -s /bin/bash -c "mongod --logpath /data/mongo/logs/"$SHARD2"_"$REPLICA"-1.log --fork --dbpath /data/mongo/data/$SHARD2/$REPLICA-1/ --port 47017 --replSet $SHARD2" mongodb
sudo su -s /bin/bash -c "mongod --logpath /data/mongo/logs/"$SHARD2"_"$REPLICA"-2.log --fork --dbpath /data/mongo/data/$SHARD2/$REPLICA-2/ --port 47018 --replSet $SHARD2" mongodb
sudo su -s /bin/bash -c "mongod --logpath /data/mongo/logs/"$SHARD2"_"$REPLICA"-3.log --fork --dbpath /data/mongo/data/$SHARD2/$REPLICA-3/ --port 47019 --replSet $SHARD2" mongodb

mongo --port 47017 <<EOF
config = {
	"_id": "$SHARD2",
	"members": [
		{"_id": 1, "host": "127.0.0.1:47017"},
		{"_id": 2, "host": "127.0.0.1:47018"},
		{"_id": 3, "host": "127.0.0.1:47019"},
	]
};
rs.initiate(config);
EOF


# Starting third shard replica set.
echo "Starting $SHARD3 replica set."
sudo su -s /bin/bash -c "mongod --logpath /data/mongo/logs/"$SHARD3"_"$REPLICA"-1.log --fork --dbpath /data/mongo/data/$SHARD3/$REPLICA-1/ --port 57017 --replSet $SHARD3" mongodb
sudo su -s /bin/bash -c "mongod --logpath /data/mongo/logs/"$SHARD3"_"$REPLICA"-2.log --fork --dbpath /data/mongo/data/$SHARD3/$REPLICA-2/ --port 57018 --replSet $SHARD3" mongodb
sudo su -s /bin/bash -c "mongod --logpath /data/mongo/logs/"$SHARD3"_"$REPLICA"-3.log --fork --dbpath /data/mongo/data/$SHARD3/$REPLICA-3/ --port 57019 --replSet $SHARD3" mongodb

mongo --port 57017 <<EOF
config = {
	"_id": "$SHARD3",
	"members": [
		{"_id": 1, "host": "127.0.0.1:57017"},
		{"_id": 2, "host": "127.0.0.1:57018"},
		{"_id": 3, "host": "127.0.0.1:57019"},
	]
};
rs.initiate(config);
EOF

# Starting shards configuration replica
echo "Starting shards configuration replica set."
sudo su -s /bin/bash -c "mongod --logpath /data/mongo/logs/"$SHARD1"_config.log --fork --dbpath /data/mongo/config/$SHARD1/ --port 57041 --configsvr --smallfiles" mongodb
sudo su -s /bin/bash -c "mongod --logpath /data/mongo/logs/"$SHARD2"_config.log --fork --dbpath /data/mongo/config/$SHARD2/ --port 57042 --configsvr --smallfiles" mongodb
sudo su -s /bin/bash -c "mongod --logpath /data/mongo/logs/"$SHARD3"_config.log --fork --dbpath /data/mongo/config/$SHARD3/ --port 57043 --configsvr --smallfiles" mongodb

# Starting mongos router
echo "Starting mongos router."
sudo su -s /bin/bash -c "mongos --logpath /data/mongo/logs/mongos-1.log --configdb 127.0.0.1:57041,127.0.0.1:57042,127.0.0.1:57043 --fork" mongodb

echo "Waitin 5 seconds for replica fully started."
sleep 5

mongo <<EOF
db.adminCommand( { addshard: "$SHARD1/"+"127.0.0.1:37017" } )
db.adminCommand( { addshard: "$SHARD2/"+"127.0.0.1:47017" } )
db.adminCommand( { addshard: "$SHARD3/"+"127.0.0.1:57017" } )

db.adminCommand( { enableSharding: "test" } )
db.adminCommand( { shardCollection: "test.posts", key: { post_id: 1 } } )

EOF


