---
title: "Trigger Controller"
description: "Trigger Controller"
layout: "guide"
icon: "cloud"
weight: 4
---

###### {$page.description}

<article id="1">

## Trigger Controller

Any instance of `Trap` works as a trigger controller.

Basically, we use trigger controllers to find trigger handlers.

```javascript
TriggerHandler handler = Trap.getInstance().find('Case');
```

This, by default, will find the trigger handler named `CaseTrigger`. If the trigger controller fails
to find an existing instance of `CaseTrigger`, it will create one and store it. Otherwise it will load
the existing one.

We can alter the default naming convention like this:

```javascript
TriggerHandler handler = Trap.getInstance('Handler').find('Case');
```

In this way, the trigger controller will look for `CaseHandler` instead of the default `CaseTrigger`.

Methods are like:

| Method | Description |
| ------ | ----------- |
| Trap.TriggerHandler find(String) | Find the trigger handler |
| void start() | Start the trigger controller with default values from real trigger context |
| void start(Trap.Event, List&lt;SObject&gt;, List&lt;SObject&gt;) | Start the trigger controller with given values |

</article>

<article id="2">

## How Triggers Handlers are Controlled

Every trigger handler created in this way is in fact associated with the trigger controller, and is hence
managed by this trigger controller.

Trigger handlers created in the integration style are therefore not managed by trigger controllers.

</article>

<article id="3">

## Trigger Enablement

Trap.apex actually has a hierarchy to control trigger handler enabled status.

The hierarchy goes from top to bottom is:

- Global Enablement
We can disable/enable the triggers globally. This setting will be overridden by specific trigger enablement and activeness, though.

- Trigger Enablement
Each trigger handler can be disabled/enabled when they are enabled globally.

- Trigger Activeness
Trigger handlers can work only when they are active and enabled. See `isActive()` method on trigger handler.

Methods are like:

| Method | Description |
| ------ | ----------- |
| Boolean isEnabled(String) | Check if the trigger is enabled |
| Trap setEnabled(String, Boolean) | Set the trigger enablement |
| Trap enable(String) | Enable the trigger |
| Trap disable(String) | Disable the trigger |
| Trap enableAll() | Enable globally |
| Trap disableAll() | Disable globally |

Example:

```javascript
Trap.getInstance()
    .enable('Case');
```

</article>

<article id="4">

## Trigger Max ReEntry

In Trap.apex, we can set max re-entry to control how many times a trigger handler can be re-entered.

```javascript
Trap.getInstance()
    .setMaxReEntry('Case', 3);
```

Methods are like:

| Method | Description |
| ------ | ----------- |
| Trap setMaxReEntry(String, Integer) | Set the max re-entry |
| Integer getMaxReEntry(String) | Get the max re-entry |

</article>

<article id="5">

## Trigger New Transaction

We can event set the trigger handler to use new transactions, so that the failure will only
rollback within the trigger.

```javascript
Trap.getInstance()
    .setUsingNewTransaction('Case', true);
```

Methods are like:

| Method | Description |
| ------ | ----------- |
| Trap setUsingNewTransaction(String, Boolean) | Set whether to use new transaction |
| Boolean isUsingNewTransaction(String) | Check if using new transaction |

</article>
