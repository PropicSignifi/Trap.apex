---
title: "Trigger Controller"
description: "Trigger Controller"
buttonTitle: "Done"
parentId: "getting_started"
layout: "tutorial"
time: 90
weight: 9
---

## {$page.title}

Trap instance actually is a controller for the trigger handlers created by it. The code below shows the relationship:

```javascript
TriggerHandler handler = Trap.getInstance().find('Case');
```

Here the Trap controller creates the trigger handler for Case if it is not found, and returns it. Besides creating the trigger handlers, the trigger controller provides much more features.

```javascript
Trap.getInstance()
    .setEnabled('Case', true) // enable the CaseTrigger
    .setMaxReEntry('Case', 3) // re-entered for 3 times at most
    .setUsingNewTransaction('Case', true); // new transaction in trigger
```
