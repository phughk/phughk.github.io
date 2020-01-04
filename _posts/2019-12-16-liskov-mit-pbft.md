---
layout: post
title: Practical Byzantine Fault Tolerance (Liskov, 2001, MIT)
date: 2019-12-16 20:21:39+0100
comments: true
---
In search of good resources explaining Practical Byzantine Fault Tolerance I have stumbled across one and only Barbara Liskov's explanation of it at MIT in 2001.

{% include youtube.html id="Uj638eFIWg8"%}

Let's remind ourselves what Fault Tolerance actually is.
A fault tolerant system is one which when encountering a failure, is able to still function correctly.

You could think that this means "retrying requests" or something like that, and you would be right.
But what if the system is having to own data.
It is responsible to record and maintain it's data and cannot always retry writes or reads in the hope that things will go better.

So how does that get solved?
Fault tolerant systems are usually replicated to circumvent exactly this scenario that actions on the system are lost.
Liskov explains in the video that traditional fault tolerant systems are those that account for fail-stop errors.
Fail-stop errors can be identified by a system simply dissapearing unannounced from a network.
These systems usually have `2F + 1` members.
This odd equation is to prevent the system from splitting and diverging on data if.
If you have `F` failures, then you have `F + 1` nodes that haven't failed and that is a majority.

I wanted to spend this article explaining how Byzantine Fault Tolerance is achieved with `3F + 1` nodes.
Byzantine Faults are faults that arise from incorrect information.
It could be malicious or could be simple errors in the data or code.
The differentiator is that instead of dissapearing from the network, they respond with incorrect responses.

## General Mechanism

In fail-stop fault tolerance systems, a client sends a request to the leader.
The leader relays the client request to `2F + 1` replicas and waits for responses.
Once `F + 1` responses are received, a confirmation is sent back to the `F + 1` live nodes.
Finally data is confirmed committed once the clients confirm they have acknowledged this request is committed.

There is a big difference in Byzantine Failure tolerant systems.
Every element could be incorrect (excluding the client).
So it shouldn't be a surprise that the mechanism, while similar, is also a bit different.

## How does the Client know the system isn't lying to it

The first difference from standard algorithms is that the client needs to connect to all the replicas, broadcasting it's request to `3F + 1` nodes (backups included).
The client will know the correct response to it's request once it has received `F + 1` identical results.
This is because if we have `F` failures, we will never have `F + 1` incorrect responses.
Similarly, we don't need to wait for `2F + 1` results, because they should all be the same (based on the assumptions of the system).

## How the leader knows the replicas aren't lying

The leader is in charge of ultimately deciding if a message is committed or not.
It has a lot of responsibility for something that could be faked.
Since this is a primary-backup system, each state is represented with a view.
Each view has a leader, and not always the same one.

## How the replicas know the leader isn't lying

The leader always decides if things go forward or not.
Because of this dynamic, followers must have a way to validate that the leader isn't lying to them about 

## How do out-of-sync followers know the catchup data is correct

...



The example isn't totally true, if there is a failure on the one overlapping lead, then it doesnt work - all nodes must follow total ordering.

PBFT has 3 phases not 2. Also 3f+1 not 2f+1

Arguemtn that we want state machine replication instead of KV replication (client would do heavy work)

Client has protocol of their own = request to all replicas and wait for identical replies

!!! The replicas dont know which node is faulty and might replicate from it

Client never knows which node is faulty so must always make requests to many nodes (f+1 ?? )

Client has a view and view number and each view has a leader (primary)

Primary determins ordering of requests

Primary could be liar and the backups need to account for that and combat it with a view change

Quorum is 2f+1 in pbft, Quorum intersection is f+1 replicas => thats important to guarantee truth carried over non-faulty replica

Client encrypts to primary, and primary encrypts separately to backups

quorum certificate = an agreement between quorum
Messages arent applied until prpared certificate => that is sent to everyone once achieved
Need enough replicas to ack quorum cert before replicas commit

Protocol is async => head of line problem due to total ordering

Question by asian about what if not all replicas are caught up

Client message is encrypted and client based sequence number

