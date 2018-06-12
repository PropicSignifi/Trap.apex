---
title: "Bulk Objects"
description: "Bulk Objects"
layout: "guide"
icon: "code-file"
weight: 2
---

###### {$page.description}

<article id="1">

## Bulk Objects

Bulk objects help us manage the data in the trigger context.

Here is how we typically use the bulk objects.

```javascript
Trap.BulkObject bo = new Trap.BulkObject();
bo.newStream
    .filter(new CustomFilterFunc())
    .subscribe(Trap.F.updateField.apply('Subject', 'New subject'));

for(Case c : caseList) {
    bo.newStream.next(c);
}
```

We can see that we don't necessarily need to use bulk objects inside triggers - they can be used standalone.

Fundamentally a bulk object is a container with two streams(old stream and new stream) and one shared data, which
we will see later.

</article>

<article id="2">

## Data Streams

Bulk objects contain two streams:

- oldStream
This stream contains all the data from the old list in the trigger context.

- newStream
This stream contains all the data from the new list in the trigger context.

</article>
