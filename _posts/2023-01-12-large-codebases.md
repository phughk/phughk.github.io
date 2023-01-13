---
layout: post
title: Navigating and learning codebases
date: 2023-01-12 22:57:13+0100
comments: true
---

Wouldn't it be amazing if we could just absorb entire codebases in one sitting?
This is very difficult to do in reality - we need to focus to understand what is happening line-by-line.
We need to remember each variable and function.
And then we need to remember how it fits together (code can be used in many places!).

Clearly, we cannot absorb entire codebases - this becomes increasingly complex with every file.
We must switch into knowledge-management mode in that case and apply a different strategy.

## Establishing first strategy
The way I approach learning a codebase is by trying to answer questions. Examples of such questions are
1. Where is the entry point?
1. Where is configuration handled?
1. Where is configuration used?
1. Where are numbers (ex. port numbers, timeouts, file sizes, buffer sizes...) being used?
1. How are files accessed?

There are really an infinite number of questions you can ask when first approaching a codebase.
And that is important!
Because in all likelihood you do not want to read all the unnecessary parts when you have a burning desire to answer some fundamental question you have.

## Establishing purpose
So why are you learning this codebase in particular?
1. Are you trying to **fix a bug** and this codebase is a dependency?
1. Are you trying to understand **how a library is used**?
1. Are you trying to understand **design patterns or architecture**?
1. Perhaps it is pure curiosity around how a complicated **topic** is implemented?

Now that you have your goal, you need ways of finding the answer.

## Re-establishing strategy based on purpose
You can now focus on the exploration and you have the following resources at your disposal
1. **README** - this should absolutely be your go-to. Perhaps the code you are looking at cannot be answered in this codebase. The README will include essential information.
1. **Parent files** - the main files tend to be near the top of the project hierarchy. They are worth having a quick glance over to understand, just to see what the top level looks like. Feel free to not put too much effort into that, there are more effective ways of navigating.
1. **Project structure** - most projects have complex structures, where modules (directories) are separated based on the application architecture and responsibilities. You can use this information both to find your relevant code, and also to understand how the software fits together.
1. **Grep** - do not underestimate standard search. There are many tools out there that deliberately aim to make this easier - it is a very effective method of finding relevant code.
1. **Tracing** - you can follow the breadcrumbs of invocations from the entry point of a program until you find the functions that are relevant. This is time consuming and error prone, but a good way to first learn a codebase if you have the time. Using a debugger is also a viable approach.

## Managing knowledge
Once you have found some candidates for the type of code you are looking for, you need to explore around the code for context.
What is calling this part of the code and what is this part depending on?
This is relevant because your assumptions about what you have found may be wrong.
Or they may be correct, but deprecated (old code living alongside a newer, more-valid implementation).
Either way, this is prone to being a rabbit hole - that is why at this stage i like to take note of things that I have found.
Here are a list of tools that I use probably in equal measure
- Pen and paper
- A note taking app such as [Obsidian](https://obsidian.md)
- A chart app such as [yEd](https://www.yworks.com/products/yed)
What I would write in these programs is basically file, function, line, and idea.
These are nothing but bookmarks, so you could equally use some sort of IDE equivalent, but I like having them written down 

## Takeaways
Ultimately, you do not want to read the entire codebase.
Instead, try to push forward with questions.
And when you are stuck - think to yourself, what questions you can ask to push things forward.
Think of what you don't know about the codebase, in case you are struggling to ask questions.
There is always something you won't know.
If you know everything then you have absorbed the codebase, and it is now ready for the next change :wink: .
