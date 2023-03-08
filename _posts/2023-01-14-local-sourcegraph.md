---
layout: post
title: Launching sourcegraph locally
date: 2023-01-14 20:25:57+0100
comments: true
---

I love sourcegraph as a product.
Being able to search code through various conditions and their negations is blissful.

In this post I will show you how to set up sourcegraph to point at a local repository, even though sourcegraph is designed to point at hosted repositories such as GitHub and GitLab.

## Installation

Fortunately, you can follow the [documentation](https://docs.sourcegraph.com/admin/external_service/src_serve_git), but here is a shortened version.

Install `src`, the [sourcegraph CLI tool](https://github.com/sourcegraph/src-cli#installation).

Change directory to where you want to browse from - `src` will search for all git repositories in that directory.
I have launched from a project directory.

```
➜  surrealdb git:(main) src serve-git
serve-git: 2023/01/14 20:16:13 listening on http://[::]:3434
serve-git: 2023/01/14 20:16:13 serving git repositories from /Users/hugh/Projects/surrealdb
```

## Launch sourcegraph

You can launch sourcegraph via docker
```
docker run --publish 7080:7080 \
--publish 127.0.0.1:3370:3370 \
--rm --volume ~/.sourcegraph/config:/etc/sourcegraph \
--volume ~/.sourcegraph/data:/var/opt/sourcegraph \
sourcegraph/server:3.29.0
```
This is the same command taken from the multitude of docs, posts, and youtube videos.
The version is likely to mismatch and be incorrect for today's date.

You need to have an account.

## Add the repository

In the right top of Sourcegraph, click you profile icon and select `Site Admin`.
From there, in the left panel select `Manage code hosts` which is under the `Repositories` section.
Click `Add code host`.

## Repository link

We now need to add the link to the `src serve-git` command, but this is on a different machine (host) as opposed to sourcegraph (docker).
That means localhost won't work.
Fortunately we can use a hostname available within docker containers to connect to the host - `host.docker.internal`
My "add repository" entry looks like the following

```json
{
  // url is the http url to 'src serve-git'.
  // url should be reachable by Sourcegraph.
  "url": "http://host.docker.internal:3434",

  // Do not change this. Sourcegraph uses this as a signal that url is 'src serve'.
  "repos": ["src-serve"]
}
```

And done!
You can now start searching from the main panel of Sourcegraph.

