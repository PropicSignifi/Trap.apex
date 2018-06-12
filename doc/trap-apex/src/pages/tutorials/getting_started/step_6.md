---
title: "Find Specific Objects"
description: "Find Specific Objects"
buttonTitle: "Done"
parentId: "getting_started"
layout: "tutorial"
time: 90
weight: 6
---

## {$page.title}

Trap.apex makes it clear and convenient to do business logic only to some specific objects. For example, here is how we want to prevent changing the Case subject.

```javascript
bulkObj.newStream
    .filter(Trap.F.changed('Subject'))
    .subscribe(Trap.F.addError.apply('Cannot modify subject'));
```

With the power of R.apex, it is possible to compose complicated filter logic like:

```javascript
Func changed = (Func)R.anyPass.run(
    Trap.F.changed('Subject'),
    Trap.F.changed('OtherField')
);

bulkObj.newStream
    .filter(changed)
    .subscribe(...);
```
