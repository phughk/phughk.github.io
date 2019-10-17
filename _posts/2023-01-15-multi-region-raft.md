---
layout: post
title: Perfect multi region raft
date: 2023-01-15 14:34:39+0100
comments: true
tags: [distributedsystems, theory, ramblings, database]
---

Everyone wants perfectly synchronised data available all over the planet.
These properties are possible but slow by ensuring that the data is dispersed worldwide.
Making that consistent requires coordination.

## Coordination
The coordination we mentioned is consensus.
For this article, assume we are using Raft, but that isn't important.

People don't usually spread consensus algorithms across regions for data-intensive applications.
The latency involved in acknowledging writes slows down the latency of operations and transactions.

![Diagram of raft running on multiple regions](/assets/diagrams/multi-region-raft-1.png "Diagram of raft running on multiple regions")

## Fast local writes with physical sharding
You can partition your data by region to circumvent this.
To do so, you could have multiple clusters of your database in your local regions.
We call this physical sharding.
These are separate database instances.

![Diagram of physical sharding](/assets/diagrams/multi-region-raft-2.png "Diagram of physical sharding")

Physical sharding is problematic, though, since you now have a physical separation of your clusters and need to think of routing and balancing.
You can access the correct cluster by using identifiable information from a request/user to tie the data to a region.
For example, user IDs can be pre-generated and assigned to regions asynchronously.
Then any request that comes in would have a known user ID and can be easily mapped to a region.

## Fast local writes and global reads with logical sharding
A distributed database that supports regions would allow for data partitioning and describing which replicas are part of the quorum for the local consensus algorithm and which are just read replicas (non-voting) for that partition.
Since this is Multi-Raft, each member is part of several Raft Consensus Groups but won't be a leader.
That way, clients don't need to route traffic themselves - they query their local cluster only, and clients should shard the data so that the regional distribution works for this scenario.

![Diagram of logical sharding](/assets/diagrams/multi-region-raft-3.png "Diagram of logical sharding")

Below is a diagram of what a single replica would look like with regards to the partitions it owns.

![Diagram of partitions on a replica with logical sharding](/assets/diagrams/multi-region-raft-4.png "Diagram of partitions on a replica with logical sharding")

The local cluster keeps track of synchronising the local writes that it owns for the region while at the same time doing replication from other regions where it cannot write directly.
Users benefit from simplicity and speed at the cost of operational convenience and partitioned data.
Cloud-managed DBaaS is the future for many organisations that prefer to focus on their core business rather than operational complexity.
