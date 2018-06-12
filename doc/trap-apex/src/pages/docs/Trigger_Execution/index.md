---
title: "Trigger Execution"
description: "Trigger Execution"
layout: "guide"
icon: "code-file"
weight: 2
---

###### {$page.description}

<article id="1">

## Trigger Execution

What distinguishes Trap.apex from all the other trigger frameworks is that its trigger execution is based on
streams, a concept based on the functional reactive world.

To dive in, please check out [Stream.apex](https://github.com/Click-to-Cloud/Stream.apex).

</article>

<article id="2">

## Bulk Objects

The core of Trap.apex trigger execution is the bulk objects.

Bulk objects are objects that encapsulate data in the forms of streams.

</article>

<article id="3">

## Stream Functions

All `Func` objects can be used with streams, and therefore they can be used here.

Besides, Trap.apex provides some utility functions that make our life easier.

</article>

<article id="4">

## Data Sharing

It's important to load and store data in the trigger execution, to avoid doing query inside the loop.

Bulk objects have some nice features to support this.

</article>
