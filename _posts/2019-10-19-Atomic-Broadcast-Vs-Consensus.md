---
layout: post
title: Atomic Broadcast Vs Consensus Algorithms
date: 2019-10-19 10:02:24+0100
comments: true
---

When distributed systems need to agree that something was recorded, designers can turn to using a consensus algorithm or using atomic broadcast.

This is usually an architecture detail that is overlooked by engineers, mostly because it is incorrectly thought to be the same.

### What is Atomic Broadcast

Atomic Broadcast algorithms are a way of communicating with other programs in a system that something has happened.
Their key property is that either this event happens on all of the programs or on none of them.
There are other details that I am skipping, but that is the gist of it.

### What are Consensus Algorithms

Consensus algorithms also try to establish that messages have been received, but more reliably.
Consensus algorithms account for past events, which matter if the event is an update to a previous value.
The way consensus is usually achieved in these algorithms is by only allowing the latest broadcast to be acknowledged by programs that have the latest events.
If there aren't enough programs that have the latest events, then quorum (the minimum allowed number of replications) cannot be met and messages cannot be broadcast.
The system must then wait until the expected number of programs have replicated events before continued events can be recorded.

### Takeway

While Atomic Broadcast algorithms can strive for partial ordering ("C happens after A"), they cannot guarantee that all messages are on all programs (no knowledge of B).
In systems where there is eventual consistency and a reliance on atomic broadcast, even this total ordering can become false since missed messages are re-delivered.
It varies between systems how delayed messages are handled.
This is why message brokers, like Kafka, can use Atomic Broadcast.
Message brokers don't need to guarantee that all messages were received by every program, just that they were received reasonably reliably.
Most databases on the other hand really should rely on stronger replication guarantees.

