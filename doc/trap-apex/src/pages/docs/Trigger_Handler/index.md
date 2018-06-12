---
title: "Trigger Handlers"
description: "Trigger Handlers"
layout: "guide"
icon: "flash"
weight: 1
---

###### {$page.description}

<article id="1">

## What is a Trigger Handler?

A trigger handler is an object that processes the trigger logic.

Following the trigger best practices, we separate the logic from triggers into trigger handlers.

First, we delegate the logic from within triggers to trigger handlers.

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

Here we get the instance of `Trap`, which is a trigger handler controller, and it will manage the lifecycle of trigger handlers
and delegate the trigger execution context to the trigger handler.

Then we create a trigger handler like this:

```javascript
public with sharing class CaseTrigger extends Trap.TriggerHandler {
    public override void setUpBeforeInsert(Trap.BulkObject bulkObj) {
        bulkObj.newStream
            .filter(new CustomFilterFunc())
            .subscribe(Trap.F.addError.apply('test error'));
    }
}
```

For details on the streams and bulk objects here, please check out 'Trigger Execution' section.

</article>

<article id="2">

## Trigger Context

One of the key concepts in Trap.apex is that we use separate trigger contexts from the standard Salesforce
trigger contexts. This means that we no longer have direct dependencies over Salesforce apex API, which
further enables us to do our unit test simply, as we have complete control of our data.

Normally we bootstrap Trap.apex like this:

```javascript
Trap.getInstance().start(); // Start the trap
```

And we can also explicitly set the trigger context data during the bootstrap.

```javascript
Trap.getInstance().start(Trap.Event.BeforeInsert, null, new List<SObject>{ new Case() });
```

So we can easily control the trigger event, old list and new list passed into the trigger context.

And we apply that into the unit testing.

```javascript
@isTest
private static void contextTest() {
    // test code

    Trap.getInstance().start(Trap.Event.BeforeInsert, null, new List<SObject>{ new Case() });

    // test code
}
```

What we need to bear in mind is that in our code, do not use code like `Trigger.Xxx`. Instead, use this:

```javascript
Trap.Context triggerContext = this.getTriggerContext();
Map<Id, SObject> newMap = triggerContext.newMap;
List<SObject> newList = triggerContext.newList;
```

Methods are below:

| Method | Description |
| ------ | ----------- |
| Trap.Context Trap.TriggerHandler.getTriggerContext() | Get the trigger context |
| Boolean Trap.TriggerHandler.isActive() | Check if the trigger handler is active |
| void Trap.TriggerHandler.run() | Run the trigger handler with default values from the real trigger context |
| void Trap.TriggerHandler.run(Trap.Event, List&lt;SObject&gt;, List&lt;SObject&gt;) | Run the trigger handler with the trigger event, old list and new list |

</article>

<article id="3">

## Trigger Event

Trap.apex categorizes trigger events into:

- BeforeInsert
- BeforeUpdate
- BeforeDelete
- AfterInsert
- AfterUpdate
- AfterDelete
- AfterUndelete
- All

All these events can be found in `Trap.Event`. `Trap.Event.All` is a special event used to
denote accepting all events, and normally users should not use this event.

</article>

<article id="4">

## Trigger Handler Styles

Trap.apex is designed to be able to run in multiple styles.

- Streamed Style
The streamed style adopts streams from Stream.apex to handle trigger logic and make codes
more reusable and declarative.

- Normal Style
The normal style is like many other trigger frameworks that provide trigger event handling methods
for you to override.

- Integration Style
The integration style enables you to use the streamed style inside an existing trigger framework.

</article>

<article id="5">

## Streamed Style

The streamed style is distinct by using streams.

```javascript
public with sharing class CaseTrigger extends Trap.TriggerHandler {
    public override void setUpBeforeInsert(Trap.BulkObject bulkObj) {
        bulkObj.newStream
            .filter(new CustomFilterFunc())
            .subscribe(Trap.F.addError.apply('test error'));
    }
}
```

Methods are below:

| Method | Description |
| ------ | ----------- |
| setUpBeforeInsert(Trap.BulkObject) | Set up before insert |
| setUpBeforeUpdate(Trap.BulkObject) | Set up before update |
| setUpBeforeDelete(Trap.BulkObject) | Set up before delete |
| setUpAfterInsert(Trap.BulkObject) | Set up after insert |
| setUpAfterUpdate(Trap.BulkObject) | Set up after update |
| setUpAfterDelete(Trap.BulkObject) | Set up after delete |
| setUpAfterUndelete(Trap.BulkObject) | Set up after undelete |
| setUp(Trap.BulkObject) | Set up all events |

We can use `setUp` to catch all events.

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

</article>

<article id="6">

## Normal Style

The normal style works just like other trigger frameworks.

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

Methods are below:

| Method | Description |
| ------ | ----------- |
| bulkBefore() | Called before the before events |
| buldAfter() | Called before the after events |
| beforeInsert(SObject) | Called on before insert |
| beforeUpdate(SObject, SObject) | Called on before update |
| beforeDelete(SObject) | Called on before delete |
| afterInsert(SObject) | Called on after insert |
| afterUpdate(SObject, SObject) | Called on after update |
| afterDelete(SObject) | Called on after delete |
| afterUndelete(SObject) | Called on after undelete |

</article>

<article id="7">

## Integration Style

The integration style enables you to use Trap.apex inside your existing trigger framework.

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

Methods are below:

| Method | Description |
| ------ | ----------- |
| Trap.BulkObject onBeforeInsert() | Get the before insert bulk object |
| Trap.BulkObject onBeforeUpdate() | Get the before update bulk object |
| Trap.BulkObject onBeforeDelete() | Get the before delete bulk object |
| Trap.BulkObject onAfterInsert() | Get the after insert bulk object |
| Trap.BulkObject onAfterUpdate() | Get the after update bulk object |
| Trap.BulkObject onAfterDelete() | Get the after delete bulk object |
| Trap.BulkObject onAfterUndelete() | Get the after undelete bulk object |
| Trap.BulkObject onEvent() | Get the bulk object for all events |

</article>
