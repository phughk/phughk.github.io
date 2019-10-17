---
layout: post
title: Stellar Consensus Protocol - Problems Solved and TL;DR
date: 2019-10-21 19:04:47+0100
comments: true
tags: [distributedsystems, theory]
---

This entire blog post is based on a recording I saw of a talk by [Tess Rinearson](https://twitter.com/_tessr).
I highly encourage others to watch it because it will be clearer to follow than my notes.

{% include youtube.html id="QV4P8iRales" %}

### Consensus Algorithms and their flaws

At first, Tess talks about what [consensus algorithms]({{ site.baseurl }}{% post_url 2019-10-19-Atomic-Broadcast-Vs-Consensus %}) are (such as Paxos and Raft), and how they work in general.
Then things move into our area of interest - Practical Byzantine Fault Tolerance.

Byzantine Failures are failures where programs can send false information.
It could be for mallicious purposes, but not necessarily - corrupted hard drives, incorrect software. and anything really, can factor into false information being transmitted.
Standard consensus algorithms used in run of the mill software make minimal checks for such failures, assuming that you aren't having your datacentres taken over.

In blockchain and the decentralised web, consensus needs to be achieved but we don't necessarily trust the actors.
The Practical Byzantine Fault Tolerance algorithm proposed by Castro and Liskov doesn't achieve this because it is susceptible to Sybil Attacks.
Sybil Attacks happen when a malicious actor is able take over a significant number of voters and disrupt the voting process by numbers.

### Improvements on the PBFT Algorithm

To circumvent Sybil Attacks, proof of work algorithms can be used.
That way voting can only be done by nodes with a hash corresponding to the correct longest chain of events.
Proof of work consensus algorithms aren't truly consistent, as some information can be lost if it was voted in before a larger chain became part of quorum.

The problem with proof of work algorithms is that they are compute intensive.
They consume a lot of power at scale and also are susceptible to hash rate attacks where more powerfull voters have more voting power.
Tess then presents a solution to not computing so many hashes which is "Proof of Stake", used by Ethereum.
Proof of Stake is where, as part of the voting process, the voters make resource (financial) deposits which they can lose if they are wrong.
This obviously assumes that the ledger has financial value, but it doesn't necessarily have to be monetary, as it could be storage.

Proof of Stake introduces a new problem that doesn't exist in the other classes of algorithms - how do you establish when a deposit has been lost?
Tendermint is a Proof of Stake algorithm that allows nodes to vote on proposed blocks in a way similar to PBFT.
The way it circumvents Sybil Attacks is by having voters hold deposits as collateral which it then deducts from when there is maliciousness detected.
In other words, Tendermint makes it expensive to attack the network.

Due to the deposit involved in entering elections, no longer is hash rate the dominating factor for voter power, but resources/cash used for deposits.
This still means that the "richest" members of a network have the most voting power (can take part in more elections).

Federated Consensus Algorithms, such as the Stellar Consensus Protocol (SCP), don't use Proof of Stake to determine membership.
Instead, Federated Consensus Algorithms uses trust networks.
Trust networks are established by individual members, but are spread in a gossip fashion across a network.
This significantly lowers the cost of elections since it doesn't rely on Proof of Work or Proof of Stake.
One would use Federate Algorithms where the network has at least some elements of trust.
