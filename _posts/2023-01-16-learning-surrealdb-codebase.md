---
layout: post
title: learning-surrealdb-codebase
date: 2023-01-16 17:47:00+0100
comments: true
---

Time to put my words where my mouth is and follow my [own advice](link).
In this post we will learn the SurrealDB codebase.
I will walk you through my thought process as I am navigating it the first time and how I am managing this influx of information.

# Clone and first look

I will assume you have cloned the repo locally and also have a [local sourcegraph pointing to it](link) for convenience, though this isn't necessary.
Let's have a look at the parent directory.

```
CODE_OF_CONDUCT.md DOCKER.md          README.md          default.nix        img                shell.nix
CONTRIBUTING.md    Dockerfile         SECURITY.md        doc                lib                src
Cargo.lock         LICENSE            app                flake.lock         pkg                target
Cargo.toml         Makefile           build.rs           flake.nix          release.toml
```

I have already familiarised myself with the README.
I now want to see how this builds so I will have a look at the `Makefile`.
I have an advantage over here since I am already familiar with both `cargo` and `Makefile` files.
What I am trying to establish here is how much variation there can be in the builds and if there is anything surprising I should pick up on.
This boils down to intuition, so if you are new to a codebase and it isn't making sense - don't worry.
Sometimes these things are just details.

From the build we can see there are standard steps of tooling management, docs building, testing, and other lifecycle.
There are also different ways to run the program - this is very important information.
This tells me that while there is one codebase, there is more than one mode of operation.
We are actually looking at 2 programs - the client (`sql`) and the server (`serve`).
I also know from the `Cargo.toml` file, a build file used for Rust, that there are even more modes of operation based on the declared features.
So this repository is a good example of why you would want to have a look at the README and build files before jumping in :smile:.

# High level overview
Since we are approaching this project without a clear purpose, perhaps we can identify the main parts of the code.
I will do something sneaky here and list the directory by file size.

```
➜  surrealdb git:(main) du -d 1 -h
4.0K    ./app
968M    ./target
2.7M    ./img
4.0K    ./.cargo
 52K    ./.github
2.1M    ./lib
 12K    ./doc
 12M    ./.git
 60K    ./pkg
244K    ./src
986M    .
```

Ok, this wasn't particularly useful.
Target is the built binary including all the dependencies, so we can safely ignore that.
Everything with a `.` before it can be ignored as well since those are config.
We can eliminate `doc` and `img` from our interests as those are assets as well.
This leaves us with `app`, `lib`, `pkg`, and `src`.
Let's dig in.

# High level modules
`./app` only includes html so that is not relevant unless you are interested in the build.

`./lib` includes its own `Cargo.toml` and `src` directories, so I am taking a mental note that this is a separate build and lives it's own code development lifecycle.
The root directory simply triggers that build as a dependency.

`./deb` includes packaging information that I am not currently interested in so I stop looking at it.

`./src` is more interesting as it seems to include 3-letter modules.
This is likely where we will be doing a lot of digging around.

So from the above streamlining, we only have the `src` and `lib` directories (modules).

# First chart of functionality

I mentioned in my other article about learning codebases that I use Obsidian and yEd.
They are fantastic programs and I would recommend you use them as well, unless you have a different preference.

Lets start with the part modules,

(image of charted code 1)

Really nothing fancy.
We shouldn't be embarassed if our notes or charts look unimpressive at the start of our work.
We are putting down building blocks that we will use to navigate later.

Since we are having to choose between src and lib, I am going to first look into src.
The reasoning for this is that I am guessing the src directory will be higher level and depend on the lib module.
The higher level will give better insight into the flow of the program.

Let's jump into `main.rs` and understand the core steps.
It is very bare bones which I don't have strong opinions about.
I like having 20 lines describing main steps, but equally the `cli::init` is probably sufficient as we can be quite certain verything is handled there.
We can safely close the file and start exploring `cli` :smile:.
I don't even need to take note of this file as I can simply remember that `cli::init` is basically the only entry point that matters.

# CLI module
You can find `init` in the `src/cli` module using either grep or sourcegraph.
Sourcegraph has the added benefit that you get context and navigation at the click of the button.
Assume I am using sourcegraph from here on out.

We can see that `init` is declared in several places in the `src/cli` directory.
This tells me that the module has a hierarchy of initialisations and I should focus on `src/cli/mod.rs` to understand how this fits together.
And indeed - after declaring the available command line interface options, we see a handler towards the end of the function.
Now we can pick a feature to chase :).
As mentioned earlier there is a distinction between `sql` (client) and `start` (database).
I am choosing to follow into the `start` functionality.
This takes us to `src/cli/start.rs`.

## Database lifecycle
Amazing, now we have some lifecycle declared.
The first lines are more handling of CLI args and logging.
Afterwards we have very clearly labelled stages/responsibilities of the database.
The last command is `Ok(())` which is how you describe a successful result in Rust.
The question marks at the end of each line are a shorthand to return a failed Result - you could write this manually but it is tedious.
Additionally we see that the `init` function is `async` as are all the steps since they include `await`.
Since I am new to this language, I checked the documentation to see if my understanding lined up with reality.
I'm glad I did!
Turns out there are [slight nuances](https://tokio.rs/tokio/tutorial/async) in how Rust handles futures compared to other languages I am used to.

I am going to stop the writing here because the article is getting long and I am getting distracted (watch fasterthanlime youtube about rust performance!).
I will follow up with a deep dive into the database lifecycle and rust await model.

# Takeaways



# Main

