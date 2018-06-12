---
title: "Take Only Trigger Execution"
description: "Take Only Trigger Execution"
buttonTitle: "Done"
parentId: "getting_started"
layout: "tutorial"
time: 90
weight: 13
---

## {$page.title}

If you have already used a trigger framework, you don't really need to switch to Trap.apex. Most trigger frameworks address the common concerns in developing triggers quite well, and it is not really necessary to do the switch, unless there is some feature you really want.

Trap.apex is designed for better integration with existing trigger frameworks. In essence, Trap.apex splits trigger handler management and trigger execution quite clearly. While many trigger frameworks focus a lot on trgger management, Trap.apex excels at its unique stream-based trigger execution powered by Funcs. It is easy for you to integrate only trigger execution from Trap.apex with your existing trigger frameworks.

```javascript
public with sharing class CaseTrigger extends Other.TriggerHandler {
    private Trap.TriggerHandler handler = new Trap.TriggerHandler();

    public CaseTrigger() {
        handler.onBeforeInsert().newStream
            .tap(R.debug.apply('before insert'))
            .subscribe(Trap.F.addError.apply('test error'));
    }

    public override void beforeInsert(SObject newSO) {
        handler.run();
    }
}
```

We set up the trigger execution logic in the constructor, and run the trigger handler in the specific trigger event handlers like this.
