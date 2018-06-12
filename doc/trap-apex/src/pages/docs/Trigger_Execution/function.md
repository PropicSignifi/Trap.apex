---
title: "Functions"
description: "Functions"
layout: "guide"
icon: "code-file"
weight: 3
---

###### {$page.description}

<article id="1">

## updateField

Update the field value of the SObject, by giving a new value or an updating function.

```javascript
bulkObj.newStream
    .subscribe(Trap.F.updateField.apply('Subject', 'New subject'));
```

</article>

<article id="2">

## addError

Add an error to the SObject.

```javascript
bulkObj.newStream
    .subscribe(Trap.F.addError.apply('test error'));
```

</article>

<article id="3">

## validate

Do validation against the SObject.

```javascript
bulkObj.newStream
    .subscribe(Trap.F.validate.apply(R.propSatisfies.apply('Subject', R.isNotNull), 'Should not be null'));
```

</article>

<article id="4">

## getOld

Get the old value.

```javascript
bulkObj.newStream
    .filter((Func)R.pipe.run(
        Trap.F.getOld,
        new CustomFilterFunc()
    ))
    .subscribe(...);
```

</article>

<article id="5">

## getNew

Get the new value.

```javascript
bulkObj.oldStream
    .filter((Func)R.pipe.run(
        Trap.F.getNew,
        new CustomFilterFunc()
    ))
    .subscribe(...);
```

</article>

<article id="6">

## changed

Check if a field has changed value.

```javascript
bulkObj.newStream
    .filter(Trap.F.changed.apply('Subject'))
    .subscribe(...);
```

</article>

<article id="7">

## isEvent

Check current trigger event.

```javascript
bulkObj.newStream
    .filter(Trap.F.isEvent.apply(Trap.Event.BeforeInsert))
    .subscribe(...);
```

</article>

<article id="8">

## isBeforeInsert

Check if it is the before insert event.

```javascript
bulkObj.newStream
    .filter(Trap.F.isBeforeInsert)
    .subscribe(...);
```

</article>

<article id="9">

## isBeforeUpdate

Check if it is the before update event.

```javascript
bulkObj.newStream
    .filter(Trap.F.isBeforeUpdate)
    .subscribe(...);
```

</article>

<article id="10">

## isBeforeDelete

Check if it is the before delete event.

```javascript
bulkObj.newStream
    .filter(Trap.F.isBeforeDelete)
    .subscribe(...);
```

</article>

<article id="11">

## isAfterInsert

Check if it is the after insert event.

```javascript
bulkObj.newStream
    .filter(Trap.F.isAfterInsert)
    .subscribe(...);
```

</article>

<article id="12">

## isAfterUpdate

Check if it is the after update event.

```javascript
bulkObj.newStream
    .filter(Trap.F.isAfterUpdate)
    .subscribe(...);
```

</article>

<article id="13">

## isAfterDelete

Check if it is the after delete event.

```javascript
bulkObj.newStream
    .filter(Trap.F.isAfterDelete)
    .subscribe(...);
```

</article>

<article id="14">

## isAfterUndelete

Check if it is the after undelete event.

```javascript
bulkObj.newStream
    .filter(Trap.F.isAfterUndelete)
    .subscribe(...);
```

</article>
