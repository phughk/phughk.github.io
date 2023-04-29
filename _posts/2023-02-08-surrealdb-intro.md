---
layout: post
title: Introduction to SurrealDB
date: 2023-02-08 15:18:42+0100
comments: true
tags: [surrealdb, software, database]
---

Read the original article on the [SurrealDB Blog](https://surrealdb.com/blog/a-quick-introduction-to-surrealdb).

### What is the product?

If you are reading this, you may be wondering how to get started with this fantastic product you just discovered, SurrealDB. It's a database that does many routine things, so you can focus on what matters to you - processing your data.

In this blog post, I will describe how to get set up and use the client while explaining some of the elementary concepts behind SurrealDB.

### Quick Install of SurrealDB

Initially, I wanted to do this tutorial using a fresh install of [Alpine Linux 1.13.1](https://www.alpinelinux.org/downloads/). This is tricky because Alpine uses musl instead of GNU libc bindings. So this tutorial is using [Ubuntu Desktop 22.04.01](https://ubuntu.com/download/desktop) instead. Which distribution exactly doesn't matter - I am doing this to demonstrate that there are no dependencies.

We can then follow the [instructions to install SurrealDB](https://surrealdb.com/install).

```sh
curl -sSf https://install.surrealdb.com | sh
```

And finally, we can start the server and client. I am running the database in the top panel of `tmux` and the client in the bottom panel.

![Screenshot of tmux terminal where SurrealDB is launched in top panel and surreal REPL is in the bottom panel](/assets/screenshots/surrealdb-intro-1.png)

With that setup, we are ready to go!

### Namespaces and Databases

If you are anything like me, your first use of the database looked like this.

```sql
INSERT INTO person [{name:'Hugh'}, {name:'Rushmore'}];
```
```json
[{"time":"7.608µs","status":"ERR","detail":"Specify a namespace to use"}]
```

We have yet to declare which namespace and database we are using. You could solve this problem by inlining your statements.

```sql
USE NAMESPACE test; USE DATABASE testdb; INSERT INTO person [{name:'Hugh'}, {name:'Rushmore'}];
```
```json
[{"time":"5.448µs","status":"OK","result":null},{"time":"1.855µs","status":"OK","result":null},{"time":"31.966464ms","status":"OK","result":[{"id":"person:7fsqx0q0iyeoltyjsr7c","name":"Hugh"},{"id":"person:2fdjz6j6luih4bn44u9c","name":"Rushmore"}]}]
```

This is quite inconvenient to do for every query, though. Instead, we are going to reconnect while specifying our database and namespace.

```sh
hugh@hugh-VirtualBox:~$ surreal sql --conn http://0.0.0.0:8000 -u root -p root --ns testns --db testdb
```
```sql
INSERT INTO person [{name:'Hugh'}, {name:'Rushmore'}];
```
```json
[{"time":"109.351µs","status":"OK","result":[{"id":"person:adfy4qj5254b8l4po7bp","name":"Hugh"},{"id":"person:g5wkfgggpfayj6j453hg","name":"Rushmore"}]}]
```

Much more convenient!

So what are these namespaces and databases?
In the simplest terms, they are ways of making sure that you do not get name collisions (who here has had a table called "requests" or "versions"?). But really, there is more to this separation.

At the highest level, we have namespaces. Namespaces are a way to separate areas of security concern. They are a way of giving blanket access to sets of databases. The databases will not be shared by 2 namespaces, so users with full access to separate namespaces will need to be provided special permissions for namespaces they do not have access to. This is a fundamental concept for multi-tenancy.

So if we have this separation at the top level with namespaces, what is the purpose of having databases? Again, this is tied to uniqueness collision and security. You can think of a database (storage, not the DBMS system called `surreal`) as a space where you want to enforce name uniqueness. So by having separate databases, you can avoid this uniqueness, as with our example above with tables called "requests" and "versions".

This may sound inconvenient, but the intention is to have a single SurrealDB cluster. If you want to develop a new app or service, create a new database (or namespace, if it's for a new client or project).

### Table vs Document

In the above example, we have already inserted 2 entries into a table called `person`. We can confirm that by doing a very familiar select query.

```sql
SELECT * FROM person;
```
```json
[{"time":"1.151239ms","status":"OK","result":[{"id":"person:adfy4qj5254b8l4po7bp","name":"Hugh"},{"id":"person:g5wkfgggpfayj6j453hg","name":"Rushmore"}]}]
```

Brill! We can see that the "id" fields were populated, and the ID includes the table name. But what if we want to use a custom ID that may be tied with a request ID, legacy system, username or other variables?

```sql
INSERT INTO person {id: 'tobie', name: 'Tobie'};
```
```json
[{"time":"90.142µs","status":"OK","result":[{"id":"person:tobie","name":"Tobie"}]}]
```
```sql
SELECT * FROM person;
```
```json
[{"time":"63.091µs","status":"OK","result":[{"id":"person:adfy4qj5254b8l4po7bp","name":"Hugh"},{"id":"person:g5wkfgggpfayj6j453hg","name":"Rushmore"},{"id":"person:tobie","name":"Tobie"}]}]
```

### Graph vs Link

So we have created a table (person) of documents (Hugh, Rushmore, Tobie). How are the documents different to relational tables?

```sql
INSERT INTO person {name: 'complex', shoes: ['red', 'green', {colour: 'blue', favourite: true}]};
```
```json
[{"time":"110.782µs","status":"OK","result":[{"id":"person:1vjjz8xi2pbau1zh07ob","name":"complex","shoes":["red","green",{"colour":"blue","favourite":true}]}]}]
```

Ok, so quite different! We have created a new column called "shoes" on-the-fly. The column contains an array for this entry. And not all the elements of the array are of the same type! We have "red" and "green" as string elements of the `shoes` column, but then an entire object for the "blue" colour. This is so different that calling these "columns" is a bit of a stretch. That is why we don't refer to entries in a document as columns, only as records.

```sql
SELECT id FROM person;
```
```json
[{"time":"1.21102ms","status":"OK","result":[{"id":"person:1vjjz8xi2pbau1zh07ob"},{"id":"person:adfy4qj5254b8l4po7bp"},{"id":"person:g5wkfgggpfayj6j453hg"},{"id":"person:tobie"}]}]
```
```sql
SELECT shoes FROM person;
```
```json
[{"time":"125.074µs","status":"OK","result":[{"shoes":["red","green",{"colour":"blue","favourite":true}]},{"shoes":null},{"shoes":null},{"shoes":null}]}]
```
```sql
SELECT shoes.colour FROM person;
```
```json
[{"time":"89.063µs","status":"OK","result":[{"shoes":{"colour":[null,null,"blue"]}},{"shoes":{"colour":null}},{"shoes":{"colour":null}},{"shoes":{"colour":null}}]}]
```

You may wonder why there is an unusual `[null,null,'blue']` in the results - those are the 3 values for the object: ID, favourite, and colour.

We can do some cool stuff with these nested records. We can create Record Links. Record Links are how you would use Foreign Keys in a relational database to point to either same-table entries, or even other-table entries? Unlike nested document records, these links point to entries in a table that may not belong to the linking document. That means all documents can include all other document entries if they are declared to do so. And they do not need to be updated - they are pointers. You can put the C++ book down now; you don't need to know this to use them ;). 

```sql
UPDATE person:tobie SET friends=[person:g5wkfgggpfayj6j453hg, person:adfy4qj5254b8l4po7bp];
```
```json
[{"time":"90.815µs","status":"OK","result":[{"friends":["person:g5wkfgggpfayj6j453hg","person:adfy4qj5254b8l4po7bp"],"id":"person:tobie","name":"Tobie"}]}]
```
```sql
SELECT friends.name FROM person:tobie;
```
```json
[{"time":"185.621µs","status":"OK","result":[{"friends":{"name":["Rushmore","Hugh"]}}]}]
```

Pretty neat.

Are these graphs, though? Well, not quite. These are just composable documents. We traverse one-way instead of bi-directionally. How would we link documents together as a graph?

```sql
RELATE person:tobie->works_with->person:g5wkfgggpfayj6j453hg SET last_updated = time::now();
RELATE person:tobie->works_with->person:adfy4qj5254b8l4po7bp SET last_updated = time::now();
```
```json
[{"time":"38.104611ms","status":"OK","result":[{"id":"works_with:fl9wgahk9pl4eqj33es7","in":"person:tobie","last_updated":"2023-02-06T18:33:41.131956605Z","out":"person:g5wkfgggpfayj6j453hg"}]},{"time":"88.334µs","status":"OK","result":[{"id":"works_with:zccalviq0oj6o36wylgy","in":"person:tobie","last_updated":"2023-02-06T18:33:41.156103917Z","out":"person:adfy4qj5254b8l4po7bp"}]}]
```
```sql
SELECT * FROM person WHERE ->works_with->person;
```
```json
[{"time":"1.31216ms","status":"OK","result":[{"friends":["person:g5wkfgggpfayj6j453hg","person:adfy4qj5254b8l4po7bp"],"id":"person:tobie","name":"Tobie"}]}]
```

We have identified the mega node!

### Take aways

In this tutorial, we have installed SurrealDB, launched it, connected to it, created data and explained how it fits together. Hopefully, now you are comfortable playing with it and can test it with your applications or dataset.
