# Trap.apex
Trap.apex is a versatile functional reactive library to handle Salesforce triggers.

## Why Trap.apex?
Trap.apex takes its name from 'trigger the trap', which aims to become the delicate device that takes care of Salesforce triggers. Besides adopting the trigger best practices from the community, Trap.apex distinguishes itself from other trigger frameworks in its stream-based trigger execution and rich features.

## Dependencies
Trap.apex has a dependency over [R.apex](https://github.com/Click-to-Cloud/R.apex/) and [Stream.apex](https://github.com/Click-to-Cloud/Stream.apex/).

Please include them before including Trap.apex.

## Preliminary Knowledge
Trap.apex harnesses the power of Stream.apex to process business logic in a more declarative way. The more you are familiar with Stream.apex, the more power you can get out of Trap.apex.

## Getting Started

### Create Triggers
In this tutorial, we will create a trigger for `Case` objects. Here is how we create the trigger.

```java
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

### Trigger Handler
The next step is to create your trigger handler, which encapsulates logic separately from the trigger.

```java
public with sharing class CaseTrigger extends Trap.TriggerHandler {
    public override void setUpBeforeInsert(Trap.BulkObject bulkObj) {
        bulkObj.newStream
            .filter(new CustomFilterFunc())
            .subscribe(Trap.F.addError.apply('test error'));
    }
}
```

Compared with other trigger frameworks, it is similar that we have separate trigger events to process the business logic. Different is that we set up the streams in the bulk object to do the process. For more information, please check out [Stream.apex](https://github.com/Click-to-Cloud/Stream.apex/).

The trigger handler is located by naming convertion, adding 'Trigger' to the name of the SObject type. You can configure this behavior, though.

### Bulk Object
A bulk object represents a trunk of SObjects to be processed in the trigger. Bulk objects define the scope that you can work on the data. By default, they provide data as encapsulated streams, `newStream` for new SObjects and `oldStream` for old SObjects.

```java
bulkObj.oldStream
    .tap(R.debug.apply('Old objects: '))
    .subscribe(new CustomFunc());
```

You can access to the old/new SObject if you are already in one stream.

```java
bulkObj.newStream
    .filter((Func)R.pipe.run(
        Trap.F.getOld,
        new CustomFilterFunc()
    ))
    .subscribe(new CustomFunc());
```

### Find Specific Objects
Trap.apex makes it clear and convenient to do business logic only to some specific objects. For example, here is how we want to prevent changing the Case subject.

```java
bulkObj.newStream
    .filter(Trap.F.changed('Subject'))
    .subscribe(Trap.F.addError.apply('Cannot modify subject'));
```

With the power of R.apex, it is possible to compose complicated filter logic like:

```java
Func changed = (Func)R.anyPass.run(
    Trap.F.changed('Subject'),
    Trap.F.changed('OtherField')
);

bulkObj.newStream
    .filter(changed)
    .subscribe(...);
```

### Data Sharing
You should not do data query inside a loop in the trigger. So is also true in Trap.apex. Bulk objects manage shared data for you, so that data can be accessed globally in the streams. Here is an example.

```java
bulkObj.newStream
    .tap(bulkObj.data('accounts', new GetAccountsFunc()))
    .subscribe(bulkObj.provide('accounts', new CustomFunc()));
```

We compute the account list from `GetAccountsFunc` and set it to the data in the bulk object. Then we provide the data to `CustomFunc` from the bulk object.

Here is how we compute the account list from `GetAccountsFunc`.

```java
public class GetAccountsFunc extends Func {
    public GetAccountsFunc() {
        super(1);
    }

    public override Object exec(Object arg) {
        Map<Id, SObject> newMap = (Map<Id, SObject>)arg;
        return [ SELECT Id FROM Account WHERE Id IN :newMap.keySet() ];
    }
}
```

And we use the account list in our `CustomFunc`.

```java
public class CustomFunc extends Func {
    public CustomFunc() {
        super(2);
    }

    public override Object exec(Object arg1, Object arg2) {
        List<SObject> accountList = (List<SObject>)arg1;
        SObject sObj = (SObject)arg2;
        // Custom code
        return ...;
    }
}
```

Data set to the bulk object will only be set once, so that it will not cause extra execution for every item through the stream.

### Catch All Events
Sometimes we want to share the same logic when handling multiple events. This comes handy in Trap.apex.

```java
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

### Trigger Controller
`Trap` instance actually is a controller for the trigger handlers created by it. The code below shows the relationship:

```java
TriggerHandler handler = Trap.getInstance().find('Case');
```

Here the Trap controller creates the trigger handler for Case if it is not found, and returns it. Besides creating the trigger handlers, the trigger controller provides much more features.

```java
Trap.getInstance()
    .setEnabled('Case', true) // enable the CaseTrigger
    .setMaxReEntry('Case', 3) // re-entered for 3 times at most
    .setUsingNewTransaction('Case', true); // new transaction in trigger
```

### Normal Trigger Event Handler
If you do not want to use the stream style Trap.apex, you can still use a downgraded style, which resembles the normal trigger event handlers.

```java
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
See, put your  code in `bulkBefore` to query data, and specific logic in the `beforeInsert`

### Trigger Context
It is worthy mentioning that Trap.apex uses its own trigger context, independently from Salesforce trigger context. This brings the benefit that you can test your genuine trigger code completely ignorant of the real trigger context.

Most of the time, trigger contexts are invisible to you and you do not need to notice them. However, bear it in mind that you **SHOULD NOT** use anything like `Trigger.xxx` from Salesforce trigger context.

Use Trap.apex trigger context instead.

```java
Trap.Context triggerContext = this.getTriggerContext();
Map<Id, SObject> newMap = triggerContext.newMap;
List<SObject> newList = triggerContext.newList;
```

### Unit Test
Unit testing with Trap.apex is easy. Here is how you do it in the unit test.

```java
@isTest
private static void contextTest() {
    // test code

    Trap.getInstance().start(Trap.Event.BeforeInsert, null, new List<SObject>{ new Case() });

    // test code
}
```

Pass the trigger event, old list and new list into the `Trap.start` or `TriggerHandler.run`, and the same code will be executed completely from the data you passed in, not from Salesforce trigger context.

### Take Only Trigger Execution
If you have already used a trigger framework, you don't really need to switch to Trap.apex. Most trigger frameworks address the common concerns in developing triggers quite well, and it is not really necessary to do the switch, unless there is some feature you really want.

Trap.apex is designed for better integration with existing trigger frameworks. In essence, Trap.apex splits trigger handler management and trigger execution quite clearly. While many trigger frameworks focus a lot on trgger management, Trap.apex excels at its unique stream-based trigger execution powered by Funcs. It is easy for you to integrate only trigger execution from Trap.apex with your existing trigger frameworks.

```java
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
