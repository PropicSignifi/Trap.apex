---
title: "Create Triggers"
description: "Create Triggers"
buttonTitle: "Done"
parentId: "getting_started"
layout: "tutorial"
time: 90
weight: 3
---

## {$page.title}

In this tutorial, we will create a trigger for Case objects. Here is how we create the trigger.

```javascript
trigger CaseTrigger on Case (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete
) {
    Trap.getInstance().start(); // Start the trap
}
```

In whatever trigger it is, you need only one line. Trap.apex takes care of the rest.
