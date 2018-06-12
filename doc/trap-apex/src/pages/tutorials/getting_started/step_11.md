---
title: "Trigger Context"
description: "Trigger Context"
buttonTitle: "Done"
parentId: "getting_started"
layout: "tutorial"
time: 90
weight: 11
---

## {$page.title}

It is worthy mentioning that Trap.apex uses its own trigger context, independently from Salesforce trigger context. This brings the benefit that you can test your genuine trigger code completely ignorant of the real trigger context.

Most of the time, trigger contexts are invisible to you and you do not need to notice them. However, bear it in mind that you **SHOULD NOT** use anything like `Trigger.xxx` from Salesforce trigger context.

Use Trap.apex trigger context instead.

```javascript
Trap.Context triggerContext = this.getTriggerContext();
Map<Id, SObject> newMap = triggerContext.newMap;
List<SObject> newList = triggerContext.newList;
```
