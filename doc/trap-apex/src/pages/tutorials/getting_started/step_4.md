---
title: "Trigger Handler"
description: "Trigger Handler"
buttonTitle: "Done"
parentId: "getting_started"
layout: "tutorial"
time: 90
weight: 4
---

## {$page.title}

The next step is to create your trigger handler, which encapsulates logic separately from the trigger.

```javascript
public with sharing class CaseTrigger extends Trap.TriggerHandler {
    public override void setUpBeforeInsert(Trap.BulkObject bulkObj) {
        bulkObj.newStream
            .filter(new CustomFilterFunc())
            .subscribe(Trap.F.addError.apply('test error'));
    }
}
```

Compared with other trigger frameworks, it is similar that we have separate trigger events to process the business logic. Different is that we set up the streams in the bulk object to do the process. For more information, please check out [Stream.apex](https://github.com/Click-to-Cloud/Stream.apex).

The trigger handler is located by naming convertion, adding 'Trigger' to the name of the SObject type. You can configure this behavior, though.
