---
layout: post
title: Why SurrealDB
date: 2023-01-15 18:49:53+0100
comments: true
tags: [surrealdb, ramblings, database]
---

Disclosure: These are my own thoughts, and don't reflect my employer. They are also written in gist and aren't a full or accurate depiction of reality.

## What, another database? We already have a database.
Well... quite.
And in all likelihood, it does one thing well - relational tables, graphs, documents etc.
And when you want to mix the paradigms (say documents with graphs), you will pick the best-in-class database that suits your needs for the other paradigm.
Now you have data duplication, and you need a single source of truth.
Your architecture is being adjusted and optimised to suit this flow of data.
You have yet to start your app, which is already a design and operation nightmare.

## Another way
You don't need to tie your architecture to a single paradigm if you don't think that is viable.
Picking a single paradigm means selecting an engine that is all-in for optimisations for that concept.
But at the end of the day, all databases are LSM trees, B trees, AVL trees and other data structures (yes, this is naive).
Even graph boils down to Index Free Adjacency to improve join performance - if you want faster joins, you can add it to your data structure.
And if you want to streamline your data structure, you can omit it from your data structure.

Query optimisation is another significant aspect to look out for and ties heavily to the implementation of the database and how it propagates data.
That aside, it is a level playing field and a pick-and-mix of optimisations and focus points.

So if everyone is making the same products in different configurations, what do you need?

## Performance
These days, all databases aim to give you the biggest bang for your buck.
In many cases, it is sufficient to have low millisecond performance rather than near-single-digit performance.

At any point, with increases in data, engineers face increased complexity in architecture.
Multi paradigm lends itself to not forcing you to design your application complexly.
Because your data is all in one place, you also gain performance from not coordinating three systems - your two databases and your application.
You save on network hops between clusters, network transport between your application and DB, aggregation and filtering within your application, re-seeking indexes in your secondary-paradigm database, and many other operations.

## Enter, SurrealDB
[SurrealDB](https://surrealdb.com/) is exciting.
It ties all your paradigms together in an unobtrusive way.
You can use the database in a way that is convenient to you.
The query language is very familiar as it resembles SQL.
The database is written in [Rust](https://www.rust-lang.org/), so you can compile it to [WebAssembly](https://webassembly.org/) and run it in your browser.
And most importantly - it was designed from the ground up to tackle the issue of coordinating many databases.
The scope includes services that handle authentication and authorisation, as security permissions are accessible via queries.
A lot of the selling points of SurrealDB are that they know what you will be using it for - [Change Data Capture](https://en.wikipedia.org/wiki/Change_data_capture), fast client-side analytics, eventual consistency, geo-location partitioning, and many other goals.
It is more than a database - it is leaning into the backend as a service territory.

Developers agree - SurrealDB has gained much traction in the community and is the fastest-growing in popularity per GitHub interactions.
As long as you can get your data quickly and without trouble and are tolerant of failures, the [convenience of use](https://surrealdb.com/why) is the next thing that matters.

