---
title: "Unit Test"
description: "Unit Test"
buttonTitle: "Done"
parentId: "getting_started"
layout: "tutorial"
time: 90
weight: 12
---

## {$page.title}

Unit testing with Trap.apex is easy. Here is how you do it in the unit test.

```javascript
@isTest
private static void contextTest() {
    // test code

    Trap.getInstance().start(Trap.Event.BeforeInsert, null, new List<SObject>{ new Case() });

    // test code
}
```

Pass the trigger event, old list and new list into the `Trap.start` or `TriggerHandler.run`, and the same code will be executed completely from the data you passed in, not from Salesforce trigger context.
