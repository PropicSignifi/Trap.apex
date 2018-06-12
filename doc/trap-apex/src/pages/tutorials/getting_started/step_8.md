---
title: "Catch All Events"
description: "Catch All Events"
buttonTitle: "Done"
parentId: "getting_started"
layout: "tutorial"
time: 90
weight: 8
---

## {$page.title}

Sometimes we want to share the same logic when handling multiple events. This comes handy in Trap.apex.

```javascript
public with sharing class CaseTrigger extends Trap.TriggerHandler {
    public override void setUp(Trap.BulkObject bulkObj) {
        bulkObj.newStream
            .filter((Func)R.anyPass.run(
                Trap.F.isBeforeInsert,
                Trap.F.isBeforeUpdate
            ))
            .subscribe(Trap.F.addError.apply('Cannot do this'));
    }
}
```

Here we prevent any operations when the Case objects are being inserted/updated.
