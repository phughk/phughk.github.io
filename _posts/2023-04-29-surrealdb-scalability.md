---
layout: post
title: SurrealDB Scalability
date: 2023-04-29 13:09:55+0100
comments: true
tags: [surrealdb, distributedsystems, database]
---

## What is SurrealDB, technically
SurrealDB is a multi-paradigm database that allows you to perform document, graph, temporal, spatial, and text operations within an ACID environment.

The SurrealDB service is a compute layer that processes queries and operates on a storage layer.
As of writing, our storage layer is predominantly RocksDB.

RocksDB is a key-value store from Facebook.
RocksDB was forked from Google's LevelDB LSM tree and optimised further to reduce write amplification (improve SSD lifetime), space amplification (the less we write, the better), and compute utilisation (performance).
RocksDB is an industry-standard engine renowned for being very performant, robust, and generally reliable.
It is used heavily in many prominent organisations and products.

## How does SurrealDB achieve scalability
The future of databases, particularly in the cloud, involves separating the storage from compute layers.
We don't want to force this decision on users - you can always opt out of modularity by running in embedded mode.
But by having storage and compute scale independently, you are moving closer to the "pay for what you use" paradigm.
We want to save you unnecessary queries if you have 5 petabytes of storage but only a single query per minute.
Similarly, if you would like to process many thousands of queries a second but only have a gigabyte of data: you could then scale the compute layer while keeping the storage layer relatively small.

![Diagram of layers in a SurrealDB clustered deployment](/assets/diagrams/surrealdb-layer-scaling.svg "Diagram of layers in a SurrealDB clustered deployment")

## How does the storage layer scale
The scalable storage layer we are targeting is TiKV from Pingcap.
Deploying a TiKV cluster involves deploying two types of services: TiKV instances and PD instances.
TiKV nodes are the primary service that holds the data.
The TiKV node records its data in RocksDB, so we have predictable performance equivalence compared to single-node instances.
Aside from TiKV instances, there are also instances called Placement Drivers (PD).
PD services track where data is in your TiKV cluster.
So the SurrealDB compute engine will connect to a PD instance, request access to specific keys and ranges, and the placement driver will redirect the requests to the correct TiKV instances.

## How does the compute layer scale
The compute layer is stateless.
Any messaging between nodes that may happen can be fallible; therefore, adding and removing instances does not require coordination.
Scaling is as simple as deploying or destroying SurrealDB instances without needing health checks or coordination (aside from the storage layer).

## Yes, but is it webscale?
With the rise of Big Data, scalability has become a hot topic.

<div class="embed-responsive">
  <iframe width="560" height="315" src="https://www.youtube.com/embed/b2F-DItXtZs" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>

It is a complex and interesting problem!

More importantly, everyone knows they have this problem and are eager to understand it better so they can reason about the system and have the confidence it works as they expect it to.
The "Mongo DB Is Web Scale" video does not discuss why this is such a complex topic, so I will do so in this article.

# Size of data
The most obvious question about scalability is how much data can be processed.
With TiKV, storage scales horizontally.
TiKV splits storage into ranges that become partitions.
The TiKV cluster automatically distributes the partitions across TiKV replicas.
The optimisations for this distribution are based on usage patterns determined by the Placement Drivers.
It is fair to say that this model for scaling data gives very predictable behaviour.
PD keeps partitions small, meaning TiKV can easily handle conflicting transactions during high traffic.
Distributed locks are also minimal since the partition balancing optimises to reduce this.

# Data access patterns and performant queries
A common issue when using an OLTP database is how you manage the data.
Users will develop a schema that matches their application's domain.
Such schemas without modifications are problematic because even though they may perfectly fit the domain concepts ("user", "post"), they may not match the application usage ("recommended users", "top posts", "recent user posts").
Users fall into the trap of writing queries that filter data within the primary source-of-truth table ("SELECT ... FROM user WHERE user.connections CONTAINS {thisUser.ID} AND...").

Instead, users should offload this computation into a separate table.
![Secondary table](/assets/diagrams/secondary-tables.svg "Secondary table")

Offloading to a secondary table is very similar to what a secondary index does.

A secondary index is just a mapping of index constraints to a primary key entry.
We call this concept a secondary index because the primary index stores your table data by the primary key (the document ID).
There is no difference between the term "secondary index" and "index".
Still, using a secondary table is more flexible as it can include only the necessary information (reducing the amount of data being read or garbage collected) or include information not available in the primary data (such as information already retrieved from joins).

![Primary index, secondary index, secondary table](/assets/diagrams/primary-index-secondary.svg "Primary index, secondary index, secondary table")


A query planner is a piece of code in the database that will look at a user query and decide how to translate that into reads and writes.
As of this writing, SurrealDB does not have a query planner in 1.0.0-beta-10.
A query planner can pick indexes, simplify predicates (ex "... WHERE colour="red" can be removed if there are no red colours), or re-order operations.

A query planner is handy when you don't want to consider indexes.
Fortunately, SurrealDB provides complex IDs - you can already mimic indexes in an accessible way.

Complex IDs do not seem like a big deal, but they are a fantastic way of getting predictable performance from queries if you have a deliberate access pattern in mind.
Often, slowdowns can be attributed to a query planner making an incorrect decision.

For example, if the query planner estimates that many entries match a predicate (colour = Red), it may use a full table scan instead of an index.
Then you would have to tinker and reason about how to resolve this.
In SurrealQL, you can enforce this and achieve predictable performance.

```
➜  ~ surreal sql --conn memory --ns test --db test
test/test> create user:one content {name: 'Mx One', favourite_colour: 'Red'};
create user:hugh content {name: 'Hugh', favourite_colour: 'Blue'};
create user:other content {name: 'Someone Else', favourite_colour: 'Red'};

create user_colour:['Red', user:one] content {user: user:one};
create user_colour:['Red', user:other] content {user: user:other};
create user_colour:['Blue', user:hugh] content {user: user:hugh};
{ favourite_colour: 'Red', id: user:one, name: 'Mx One' }
test/test> select * from user_colour:['Red', NONE]..
[{ id: user_colour:['Red', user:one], user: user:one }, { id: user_colour:['Red', user:other], user: user:other }]
```

As with any database, using indexes introduces a tradeoff.
You are increasing the Create and Update latency to improve read speed in other queries.
A benefit of having secondary tables is that you can delay that computation or batch the updates to it.

# Data locality
When users want data locality, they tend to have one of two things in mind: region affinity or edge storage.

We want to store data in a region where users will likely access it.
We call this region affinity.
For example, you would like to keep your European users in your European region.
Region affinity is possible in SurrealDB with TiKV.
Even though TiKV balances partitions automatically, it will be possible with SurrealDB Cloud to allocate partitions to preferred regions.

![Region Affinity](/assets/diagrams/Region-Affinity.svg "Region Affinity")

Edge storage is slightly different.
The idea behind edge storage is to hold data locally on the client instead of in a data centre.
Edge is problematic because it means this data is far from the rest of your data centre.
That means it would introduce a lot of latency and dependency on its availability in an ACID OLTP system.
Due to the way SurrealDB works for 1.0, edge storage is currently unsupported.

![Edge](/assets/diagrams/Edge.svg "Edge")

# Fault tolerance
When a system is fault-tolerant, it can handle network failures, hard drive failures, client failures, internal errors, etc.
Any failure can be handled except Byzantine Failures when a cluster member provides false information.

The multi-raft consensus algorithm in TiKV provides distributed fault tolerance.
This algorithm means that to tolerate n failures (where n can be a computer, rack, network, or data centre/region failure), you need 2n+1 copies of it.

For example, to tolerate two datacentres going down, you must be deployed in `2n + 1 = 2 * (2 datacentres) + 1 = 5` datacentres.

Single-node fault tolerance (such as power going out, or transactions being terminated mid-way) is handled with the write-ahead log.
The idea is that when we commit a transaction, RocksDB first writes to the write-ahead log file before a response is sent back to the client, confirming it was successful.
If something fails, it can be replayed by reading the latest correct snapshot of the database memory and applying un-flushed transactions from the write-ahead log.

## Conclusion
As you can see, SurrealDB is already performant and ready for production usage.
We intend to improve all the functionality, but the capabilities are already available today.
Explaining the details behind this will reassure you that it is a viable system for production usage.
We would love to hear from you if you still have reservations about scalability or reliability!

## Massive thank you to the Discord community
We decide what we need to focus on based on user feedback.
This post is primarily driven by users sharing their concerns and experience using the database.
We want to give a massive thank you to these people for sharing their perspectives!

- amaster507#1406
- nerdo#4825
- emmagamma#5637
- BitShift#1597

The list is incomplete, as many others have also contributed - we are grateful to you even if you missed the above list!

We are aware that many members only engage a little in the community as well - this is evident from our surveys.
We would appreciate hearing your voices!

You can join the Community Discord [here](https://discord.gg/surrealdb).
