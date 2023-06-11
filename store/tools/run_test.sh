#!/bin/bash
trap '{
  echo "\nKilling all clients.. Please wait..";
  for host in ${clients[@]}
  do
    ssh $host "killall -9 $client";
    ssh $host "killall -9 $client";
  done

  echo "\nKilling all replics.. Please wait..";
  for host in ${servers[@]}
  do
    ssh $host "killall -9 server";
  done
}' INT

# Paths to source code and logfiles.
srcdir="/home/ubuntu/tapir"
logdir="/home/ubuntu/tapir"

# Machines on which replicas are running. "172.31.57.84" "172.31.51.58" "172.31.63.15" "172.31.8.61" (the private ips of other replicas)
replicas=("172.31.5.240" "172.31.57.84" "172.31.51.58")

# Machines on which clients are running. "172.31.87.113" "172.31.86.190" (the private ips for other clients)
clients=("172.31.15.87")

client="benchClient"    # Which client (benchClient, retwisClient, etc)
store="strongstore"      # Which store (strongstore, weakstore, tapirstore)
mode="lock"            # Mode for storage system.
                        # for strongstore you have: lock , occ , span-lock , span-occ
                        # for weakstore you have: qw
                        # for tapir you have: txn-l , txn-s

nshard=2     # number of shards
nclient=1   # number of clients to run (per machine)
nkeys=100000   # number of keys to use
rtime=60     # duration to run

tlen=5       # transaction length
wper=30       # writes percentage
err=0        # error
skew=0       # skew
zalpha=0.75    # zipf alpha (-1 to disable zipf and enable uniform)

# Print out configuration being used.
echo "Configuration:"
echo "Shards: $nshard"
echo "Clients per host: $nclient"
echo "Threads per client: $nthread"
echo "Keys: $nkeys"
echo "Transaction Length: $tlen"
echo "Write Percentage: $wper"
echo "Error: $err"
echo "Skew: $skew"
echo "Zipf alpha: $zalpha"
echo "Skew: $skew"
echo "Client: $client"
echo "Store: $store"
echo "Mode: $mode"

# Generate keys to be used in the experiment.
echo "Generating random keys.."
python3 key_generator.py $nkeys > keys

# Start all replicas and timestamp servers
echo "Starting TimeStampServer replicas.."
$srcdir/store/tools/start_replica.sh tss $srcdir/store/tools/shard.tss.config \
  "$srcdir/timeserver/timeserver" $logdir

for ((i=0; i<$nshard; i++))
do
  echo "Starting shard$i replicas.."
  $srcdir/store/tools/start_replica.sh shard$i $srcdir/store/tools/shard$i.config \
    "$srcdir/store/$store/server -m $mode -f $srcdir/store/tools/keys -k $nkeys" $logdir
done


# Wait a bit for all replicas to start up
sleep 2

# Run the clients
echo "Running the client(s)"
count=0
for host in ${clients[@]}
do
  ssh -i myKey.pem $host "$srcdir/store/tools/start_client.sh \"$srcdir/store/benchmark/$client \
  -c $srcdir/store/tools/shard -N $nshard -f $srcdir/store/tools/keys \
  -d $rtime -l $tlen -w $wper -k $nkeys -m $mode -e $err -s $skew -z $zalpha\" \
  $count $nclient $logdir"

  let count=$count+$nclient
done

# Wait for all clients to exit
echo "Waiting for client(s) to exit"
for host in ${clients[@]}
do
  ssh -i myKey.pem $host "$srcdir/store/tools/wait_client.sh $client"
done

# Kill all replicas
echo "Cleaning up"
# $srcdir/store/tools/stop_replica.sh $srcdir/store/tools/shard.tss.config > /dev/null 2>&1
for ((i=0; i<$nshard; i++))
do
  $srcdir/store/tools/stop_replica.sh $srcdir/store/tools/shard$i.config > /dev/null 2>&1
done

# Process logs
echo "Processing logs"
cat $logdir/client.*.log | sort -g -k 3 > $logdir/client.log
rm -f $logdir/client.*.log

python3 $srcdir/store/tools/process_logs.py $logdir/client.log $rtime
