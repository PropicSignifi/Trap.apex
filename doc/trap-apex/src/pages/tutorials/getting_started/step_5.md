---
title: "Bulk Object"
description: "Bulk Object"
buttonTitle: "Done"
parentId: "getting_started"
layout: "tutorial"
time: 90
weight: 5
---

## {$page.title}

A bulk object represents a trunk of SObjects to be processed in the trigger. Bulk objects define the scope that you can work on the data. By default, they provide data as encapsulated streams, `newStream` for new SObjects and `oldStream` for old SObjects.

```javascript
bulkObj.oldStream
    .tap(R.debug.apply('Old objects: '))
    .subscribe(new CustomFunc());
```

You can access to the old/new SObject if you are already in one stream.

```javascript
bulkObj.newStream
    .filter((Func)R.pipe.run(
        Trap.F.getOld,
        new CustomFilterFunc()
    ))
    .subscribe(new CustomFunc());
```
