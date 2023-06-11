# How to Run
1) First you need to copy your private key for the VMs in the path /store/tools beacuse 
we need it to connect to the VMs from the scrpts

2) The clients and servers have to be provided a configuration file, one
for each shard and a timestamp server (for OCC). For example a 3 shard
configuration will have the following files:

shard0.config
```
f 1  
replica <server-private-ip-address-1>:<port>
replica <server-private-ip-address-2>:<port>
replica <server-private-ip-address-3>:<port>
```
shard1.config
```
f 1
replica <server-private-ip-address-4>:<port>
replica <server-private-ip-address-5>:<port>
replica <server-private-ip-address-6>:<port>
```
shard2.config
```
f 1
replica <server-private-ip-address-7>:<port>
replica <server-private-ip-address-8>:<port>
replica <server-private-ip-address-9>:<port>
```
shard.tss.config
```
f 1
replica <server-private-ip-address-10>:<port>
replica <server-private-ip-address-11>:<port>
replica <server-private-ip-address-12>:<port>
```

## Running Servers
To start the replicas, run the following command with the `server`
binary for any of the stores,

`./server -c <shard-config-$n> -i <replica-number> -m <mode> -f <preload-keys>`

For each shard, you need to run `2f+1` instances of `server`
corresponding to the address:port pointed by `replica-number`.
Make sure you run all replicas for all shards.


## Running Clients
To run any of the clients in the benchmark directory,

`./client -c <shard-config-prefix> -N <n_shards> -m <mode>`

