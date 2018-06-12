---
title: "Data Sharing"
description: "Data Sharing"
buttonTitle: "Done"
parentId: "getting_started"
layout: "tutorial"
time: 90
weight: 7
---

## {$page.title}

You should not do data query inside a loop in the trigger. So is also true in Trap.apex. Bulk objects manage shared data for you, so that data can be accessed globally in the streams. Here is an example.

```javascript
bulkObj.newStream
    .tap(bulkObj.data('accounts', new GetAccountsFunc()))
    .subscribe(bulkObj.provide('accounts', new CustomFunc()));
```

We compute the account list from `GetAccountsFunc` and set it to the data in the bulk object. Then we provide the data to `CustomFunc` from the bulk object.

Here is how we compute the account list from `GetAccountsFunc`.

```javascript
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

```javascript
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
