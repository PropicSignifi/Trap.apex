---
title: "Normal Trigger Event Handler"
description: "Normal Trigger Event Handler"
buttonTitle: "Done"
parentId: "getting_started"
layout: "tutorial"
time: 90
weight: 10
---

## {$page.title}

If you do not want to use the stream style Trap.apex, you can still use a downgraded style, which resembles the normal trigger event handlers.

```javascript
public with sharing class CaseTrigger extends Trap.TriggerHandler {
    public override void bulkBefore() {
        // Custom code
    }

    public override void beforeInsert(SObject newSO) {
        Trap.Context triggerContext = this.getTriggerContext();
        // Custom code
    }
}
```

See, put your code in `bulkBefore` to query data, and specific logic in the `beforeInsert`.
