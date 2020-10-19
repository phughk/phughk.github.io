---
layout: post
title: Hydra 2020 Kleppmann, CRDTs
date: 2020-07-06 18:33:33+0100
comments: true
---

This post is a summary of Martin Kleppmann's talk at Hydra Conf 2020 titled "CRDTs: The Hard Parts".

# What are Conflict Free Replicated Data Types

The focus of the talk was on the collaboration software use case of CRDTs.
By collaboration, what is meant that there is data that is shared between several users who all have write access to it at the same time.
To elaborate, the examples used refer to text editing (like Google docs), but can be applicable to different scenarios (for example _Tree_ datastructures).

Under normal circumstances, writes are routed through a central server, which decides the order that changes occur in.
CRDTs challenge this behaviour by not having a central server.
Instead, CRDTs present a way of (automatically, algorithmically) merging changes so that the order in which they occur shouldn't matter.

The advantage of not routing traffic through a central server is that theoretically you get higher network throughput at the cost of consistency.

CRDTs are presented as an alternative to Operational Transformation, which is the class of algorithms backing Google Docs and Office Online.
Briefly, Operation Transformation is an algorithm that relies on clients telling the server the changes they want to make, and the server transforms those operations to be valid in relation to other changes.

The main property that CRDTs provide is convergance.
Convergence guarantee states _"Any 2 nodes that have seen the same set of operations (order irrelevant), they are in the same state"_

# The Hard Parts

It's relatively easy just to implement a CRDT.
The complexity comes with designing a CRDT that converges to sensible results (differs between use cases).

Martin distinguishes 4 types of flaws that can occur in naive implementations of CRDTs and how to tackle them.

## 1. Interleaving

Interleaving anomalies are most prevalent in text editors.
The problem occurs when 2 users are performing writes in the same position together.



## 2. Reordering List Items

## 3. Moving subtrees

## 4. Reducing Metadata Overhead