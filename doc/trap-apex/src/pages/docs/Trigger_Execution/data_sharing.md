---
title: "Data Sharing"
description: "Data Sharing"
layout: "guide"
icon: "code-file"
weight: 4
---

###### {$page.description}

<article id="1">

## Data Sharing

Bulk objects help us manage the data shared inside. The basic idea is that you run a function,
get the data and store it in the bulk object. The process, for the same piece of data, will only
be triggered once. And then you can load the data from the bulk object in whatever way you like.

Below are methods to access the data:

| Method | Description |
| ------ | ----------- |
| Object getData(String) | Get the data |
| Trap.BulkObject setData(String, Object) | Set the data |
| Boolean containsData(String) | Check if the data is contained |

Example:

```javascript
// ...
List<Account> accounts = [ SELECT Id FROM Account WHERE Id IN = : ids ];
bulkObj.setData('Accounts', accounts);

// ...
accounts = (List<Account>)bulkObj.getData('Accounts');
```

</article>

<article id="2">

## Set Data in Trigger Streams

Trap.apex offers extra care when setting data in trigger streams.

We can set raw data directly into the bulk object.

```javascript
bulkObj.newStream
    .tap(bulkObj.data('data', 'test'));
```

Or set the computed data from the function.

```javascript
bulkObj.newStream
    .tap(bulkObj.data('accounts', new CustomGetAccountsFunc(), 'ids'));
```

Here the bulk object will first load data indexed by `ids` and send it to `CustomGetAccountsFunc`.
After that, it will set the computed value to `accounts`. The returned function from `bulkObj.data` is
passed to `tap` and the real execution is hence deferred to when the stream actually runs.

Similar methods are:

| Method | Description |
| ------ | ----------- |
| Func data(String, Object) | Set the raw data |
| Func data(String, Func, List&lt;String&gt;) | Set the data from the func and arg names |
| Func data(String, Func) | Set the data from the zero-arg func |
| Func data(String, Func, String) | Set the data from one arg func |
| Func data(String, Func, String, String) | Set the data from the two arg func |
| Func data(String, Func, String, String, String) | Set the data from the three arg func |

</article>

<article id="3">

## Get Data in Trigger Streams

Similarly, we have support when getting data in trigger streams.

Here is how we load the data directly.

```javascript
bulkObj.newStream
    .tap(bulkObj.data('accounts');
```

You can use it like this, but in fact this is rarely used, as it actually turns every SObject into
the data of account list.

The other way is by providing data to functions.

```javascript
bulkObj.newStream
    .filter(bulkObj.provide('accounts', new CustomFilterFunc()));
```

Here we first load the data indexed by `accounts`, and then send that as well as the current SObject
to our `CustomFilterFunc`, and wrap this logic as a returned function.

Similar methods are:

| Method | Description |
| ------ | ----------- |
| Func data(String) | Get the data |
| Func provide(List&lt;String&gt;, Func) | Provide args to the func |
| Func provide(String, Func) | Provide the arg to the func |
| Func provide(String, String, Func) | Provide the args to the func |
| Func provide(String, String, String, Func) | Provide the args to the func |

</article>
