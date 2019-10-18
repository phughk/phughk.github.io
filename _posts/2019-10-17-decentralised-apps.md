---
layout: post
title:  "How would decentralised applications (dApps) work?"
date:   2019-10-17 22:21:00 +0100
categories: jekyll update
comments: true
---

I have been trying to understand more about Web3 and how the decentralised internet would work.

It's really exciting to learn about IPFS and everything that ProtocolLabs are doing.

Basically, IPFS is a Peer-to-Peer file sharing system but, unlike BitTorrent and Kazaa, it's structured as a filesystem.
There are many cool details about IPFS which I won't cover here.
The important takeway is that you could use IPFS to host your code (encrypted or not).

## How do users run this code?
Unfortunately IPFS itself doesn't provide a solution to that.
Hypothetically, another service could agree to request the source files, run them and then serve the results.

## How do you guarantee that the results are correct?
You take a safety-in-numbers approach.
You have many "servers" running the same code and all providing the result.
Then you establish rules such as "the more common result", or the result that came from at least half.
Maybe you would even need the exact same result from all servers.

Expecting the same result from all servers would probably be detrimental given the possibility of failure in distributed systems.
So you end up with a probabilistic system whether you like it or not.

Unless you use ["Fully Homomorphic Encryption"](https://en.wikipedia.org/wiki/Homomorphic_encryption#Fully_Homomorphic_Encryption), which I know nothing about.

## Is that really how dApps would work?
Possibly not.
One of the important ideas coming out of ProtocolLabs is that all your resources are really tagged with hashes of public keys.
This guarantees that when you request a resource, the resource you are requesting is approved by whomever named it.
This also means you are actually in control of all your data.
That means you do the computation.

Juan Benet actually presented how dApps would work from their perspective in his [talk at Full Stack Fest 2016](https://www.youtube.com/watch?v=jONZtXMu03w).

## What if you don't have enough computation?
There are solutions for large computation problems such as the [Golem Network](https://golem.network).
Think of it as a massive Jenkins farm or MapReduce (R.I.P.) jobs.

## What about decentralised Google search?
One of the reasons Google is successful is because the search results are meaningful as opposed to those of the competition at the time.
It is able to (pre-)calculate meaningful results by seeing [how influential a page is](https://en.wikipedia.org/wiki/PageRank) in relation to others.
This pre-calculation happens round the clock.

Considering how the dApps of IPFS rely on users doing the calculation, this poses quite a problem in that it's not immediately possible to achieve this unless the results are pooled by all users.

With regards to Golem - that would be a massive cost incurred by every individual, when just one such calculation may be needed.

There are a lot of ideas that I haven't yet encountered, but I will be writing more on the subject as I learn more about the different technologies perspectives.

I leave the above without any particular point, but please feel free to mail or tweet me your thoughts.
