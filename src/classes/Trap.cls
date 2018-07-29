/**
 * MIT License
 *
 * Copyright (c) 2018 Click to Cloud Pty Ltd
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 **/
/**
 * The controller for trigger handlers
 *
 * Example:
 * // in trigger
 * trigger CaseTrigger on Case (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
 *     Trap.getInstance().start();
 * }
 *
 * // in trigger handler
 *  public with sharing class CaseTrigger extends Trap.TriggerHandler {
 *
 *     public override void setUpBeforeInsert(Trap.BulkObject bulkObj) {
 *         bulkObj.newStream
 *             .tap(R.debug.apply('before insert'))
 *             .subscribe(Trap.F.addError.apply('test error'));
 *     }
 * }
 * */
public class Trap {
    /**
     * Exposed functions
     *
     * Example:
     * Trap.F.isBeforeInsert.run();
     *
     * */
    public static final Funcs F = new Funcs();

    // All Trap instances, differentiated by suffixes
    private static Map<String, Trap> INSTANCES = new Map<String, Trap>();

    // The default trigger handler suffix
    private static final String DEFAULT_SUFFIX = 'TRIGGER';

    // The global trigger context
    private static Context currentTriggerContext = null;

    // The trigger handler suffix for this controller
    private String suffix = DEFAULT_SUFFIX;

    // All instantiated trigger handlers
    private final Map<String, TriggerHandler> handlers = new Map<String, TriggerHandler>();

    // All instantiated trigger configs
    private final Map<String, TriggerConfig> configs = new Map<String, TriggerConfig>();

    // The recursion depth for the trigger handler events
    private Map<String, Integer> recursionDepth = new Map<String, Integer>();

    // The save point for the trigger handler events
    private Map<String, SavePoint> savePoints = new Map<String, SavePoint>();

    // The stack of trigger contexts
    private List<Context> triggerContexts = new List<Context>();

    // If all trigger handlers are disabled
    private Boolean disabled = false;

    /**
     * Get the default Trap instance
     *
     * @return Trap
     * */
    public static Trap getInstance() {
        return Trap.getInstance(null);
    }

    /**
     * Get the Trap instance with the given suffix of the trigger handlers
     *
     * @param suffix The suffix of the trigger handler
     * @return Trap
     * */
    public static Trap getInstance(String suffix) {
        suffix = String.isBlank(suffix) ? DEFAULT_SUFFIX : suffix.toUpperCase();
        Trap instance = instances.get(suffix);
        if(instance == null) {
            instance = new Trap(suffix);
            instances.put(suffix, instance);
        }

        return instance;
    }

    // Private constructor
    private Trap(String suffix) {
        this.suffix = suffix;
    }

    /**
     * Check if a trigger handler is enabled
     *
     * Example:
     * Trap.getInstance().isEnabled('Case');
     *
     * @param name The name of the trigger handler
     * @return Boolean
     * */
    public Boolean isEnabled(String name) {
        if(this.disabled) {
            return false;
        }

        TriggerConfig config = this.getTriggerConfig(name);
        return config.enabled;
    }

    /**
     * Enable the trigger handler
     *
     * Example:
     * Trap.getInstance().enable('Case');
     *
     * @param name The name of the trigger handler
     * @return Trap
     * */
    public Trap enable(String name) {
        return this.setEnabled(name, true);
    }

    /**
     * Disable the trigger handler
     *
     * Example:
     * Trap.getInstance().disable('Case');
     *
     * @param name The name of the trigger handler
     * @return Trap
     * */
    public Trap disable(String name) {
        return this.setEnabled(name, false);
    }

    /**
     * Set whether the trigger handler is enabled
     *
     * Example:
     * Trap.getInstance().setEnabled('Case', true);
     *
     * @param name The name of the trigger handler
     * @param enabled Whehter the trigger handler is enabled
     * @return Trap
     * */
    public Trap setEnabled(String name, Boolean enabled) {
        TriggerConfig config = this.getTriggerConfig(name);
        config.enabled = enabled;

        return this;
    }

    /**
     * Set the max re-entry of the trigger handler
     *
     * Example:
     * Trap.getInstance().setMaxReEntry('Case', 3);
     *
     * @param name The name of the trigger handler
     * @param count The max count of re-entry for this trigger handler event
     * @return Trap
     * */
    public Trap setMaxReEntry(String name, Integer count) {
        TriggerConfig config = this.getTriggerConfig(name);
        config.maxReEntry = count;

        return this;
    }

    /**
     * Get the max re-entry of the trigger handler
     *
     * Example:
     * Integer max = Trap.getInstance().getMaxReEntry('Case');
     *
     * @param name The name of the trigger handler
     * @return Integer
     * */
    public Integer getMaxReEntry(String name) {
        TriggerConfig config = this.getTriggerConfig(name);
        return config.maxReEntry;
    }

    /**
     * Set whether to use a new transaction in the trigger handler
     *
     * Example:
     * Trap.getInstance().setUsingNewTransaction('Case', true);
     *
     * @param name The name of the trigger handler
     * @param use Whether to use a new transaction in the trigger handler
     * @return Trap
     * */
    public Trap setUsingNewTransaction(String name, Boolean use) {
        TriggerConfig config = this.getTriggerConfig(name);
        config.usingNewTransaction = use;

        return this;
    }

    /**
     * Check whether to use a new transaction in the trigger handler
     *
     * Example:
     * Boolean usingNewTransaction = Trap.getInstance().isUsingNewTransaction('Case');
     *
     * @param name The name of the trigger handler
     * @return Boolean
     * */
    public Boolean isUsingNewTransaction(String name) {
        TriggerConfig config = this.getTriggerConfig(name);
        return config.usingNewTransaction;
    }

    /**
     * Disable all trigger handlers
     *
     * Example:
     * Trap.getInstance().disableAll();
     *
     * @return Trap
     * */
    public Trap disableAll() {
        this.disabled = true;

        return this;
    }

    /**
     * Enable all trigger handlers
     * Notice that this will enable all trigger handlers, but each one is still further controlled by its own enablement and active status
     *
     * Example:
     * Trap.getInstance().enableAll();
     *
     * @return Trap
     * */
    public Trap enableAll() {
        this.disabled = false;

        return this;
    }

    /**
     * Start the Trap controller
     * Note that this will use the default Salesforce trigger context to initiate the Trap
     *
     * Example:
     * Trap.getInstance().start();
     *
     * */
    public void start() {
        this.start(null, Trigger.old, Trigger.new);
    }

    /**
     * Start the Trap controller with the trigger event, old list and new list
     * Note that this is primarily used in unit tests, as the same trigger logic will be run in a separate context, completely independent from
     * Salesforce trigger context
     *
     * Example:
     * Trap.getInstance().start(Trap.Event.BeforeInsert, null, new List<SObject>{ new Case() });
     *
     * @param triggerEvent The trigger event to start the Trap instance
     * @param oldList The old values of the SObjects
     * @param newList The new values of the SObjects
     * */
    public void start(Trap.Event triggerEvent, List<SObject> oldList, List<SObject> newList) {
        String name = Trap.getCurrentSObjectTypeName(oldList, newList);
        TriggerHandler handler = this.find(name);
        if(handler != null) {
            handler.run(triggerEvent, oldList, newList);
        }
    }

    /**
     * Find the trigger handler by name
     * By default, this method will try to create the trigger handler if it is not found
     * Name conventions are used
     *
     * Example:
     * // We have a trigger handler named 'CaseTrigger'
     * Trap.getInstance().find('Case');
     *
     * @param name The name of the trigger handler
     * @return TriggerHandler
     * */
    public TriggerHandler find(String name) {
        name = normalizeName(name);

        if(!this.handlers.containsKey(name)) {
            Type triggerType = Type.forName(name);
            TriggerHandler handler = (TriggerHandler)triggerType.newInstance();
            handler.setController(this);
            handler.setName(name);
            this.handlers.put(name, handler);
        }

        return this.handlers.get(name);
    }

    // Create the trigger context
    private static Context createTriggerContext(Event triggerEvent, List<SObject> oldList, List<SObject> newList, TriggerHandler handler) {
        if(Trigger.isExecuting) {
            if(triggerEvent == null) {
                if(Trigger.isBefore && Trigger.isInsert) {
                    triggerEvent = Event.BeforeInsert;
                }
                else if(Trigger.isBefore && Trigger.isUpdate) {
                    triggerEvent = Event.BeforeUpdate;
                }
                else if(Trigger.isBefore && Trigger.isDelete) {
                    triggerEvent = Event.BeforeDelete;
                }
                else if(Trigger.isAfter && Trigger.isInsert) {
                    triggerEvent = Event.AfterInsert;
                }
                else if(Trigger.isAfter && Trigger.isUpdate) {
                    triggerEvent = Event.AfterUpdate;
                }
                else if(Trigger.isAfter && Trigger.isDelete) {
                    triggerEvent = Event.AfterDelete;
                }
                else if(Trigger.isAfter && Trigger.isUndelete) {
                    triggerEvent = Event.AfterUndelete;
                }
            }

            if(oldList == null) {
                oldList = Trigger.old;
            }

            if(newList == null) {
                newList = Trigger.new;
            }
        }

        Context triggerContext = new Context();

        triggerContext.isExecuting = true;
        triggerContext.triggerEvent = triggerEvent;
        triggerContext.oldList = oldList;
        triggerContext.newList = newList;

        if(oldList != null && !oldList.isEmpty()) {
            Map<Id, SObject> oldMap = new Map<Id, SObject>();
            for(SObject sObj : oldList) {
                oldMap.put((Id)sObj.get('Id'), sObj);
            }

            triggerContext.oldMap = oldMap;
        }
        else {
            triggerContext.oldMap = null;
        }

        if(newList != null && !newList.isEmpty()) {
            Map<Id, SObject> newMap = new Map<Id, SObject>();
            for(SObject sObj : newList) {
                newMap.put((Id)sObj.get('Id'), sObj);
            }

            triggerContext.newMap = newMap;
        }
        else {
            triggerContext.newMap = null;
        }

        triggerContext.triggerObject = Trap.getCurrentSObjectTypeName(triggerContext.oldList, triggerContext.newList);
        triggerContext.handler = handler;

        return triggerContext;
    }

    // Get current sobject by deduction
    private static String getCurrentSObjectTypeName(List<SObject> oldList, List<SObject> newList) {
        List<SObject> dataList = newList;
        if(dataList == null || dataList.isEmpty()) {
            dataList = oldList;
        }

        if(dataList != null) {
            if(dataList.getSObjectType() != null) {
                return dataList.getSObjectType().getDescribe().getName();
            }
            else if(!dataList.isEmpty()) {
                SObject sObj = dataList.get(0);
                return sObj.getSObjectType().getDescribe().getName();
            }
        }

        throw new TrapException('Cannot detect current trigger name');
    }

    // Get the trigger config
    private TriggerConfig getTriggerConfig(String name) {
        name = normalizeName(name);

        TriggerConfig config = this.configs.get(name);
        if(config == null) {
            config = new TriggerConfig();
            this.configs.put(name, config);
        }

        return config;
    }

    // Normalize the trigger handler name
    private String normalizeName(String name) {
        if(String.isBlank(name)) {
            return name;
        }

        name = name.toUpperCase();

        if(!name.endsWith(this.suffix)) {
            name = name + this.suffix;
        }

        return name;
    }

    /**
     * A bulk object represents a block of objects in the trigger to be processed
     * Each bulk object corresponds to one trigger event, and delegates operations to streams
     *
     * Example:
     * Trap.BulkObject bo = new Trap.BulkObject();
     * bo.newStream
     *     .filter(new CustomFilterFunc())
     *     .subscribe(Trap.F.updateField.apply('Subject', 'New subject'));
     *
     * for(Case c : caseList) {
     *     bo.newStream.next(c);
     * }
     * */
    public class BulkObject {
        // The stream for the new data
        public Stream.Subject newStream = new Stream.Subject();

        // The stream for the old data
        public Stream.Subject oldStream = new Stream.Subject();

        // Keep track of the global data used by the bulk object
        private Map<String, Object> data = new Map<String, Object>();

        /**
         * Get the global data by key
         *
         * Example:
         * List<Account> accounts = (List<Account>)bulkObj.getData('AccountList');
         *
         * @param key The key of the data
         * @return Object
         * */
        public Object getData(String key) {
            return this.data.get(key);
        }

        /**
         * Set the global data by key
         *
         * Example:
         * List<Account> accounts = [ SELECT Id FROM Account WHERE Id IN = : ids ];
         * bulkObj.setData('Accounts', accounts);
         *
         * @param key The key of the data
         * @param value The value
         * @return BulkObject
         * */
        public BulkObject setData(String key, Object value) {
            this.data.put(key, value);

            return this;
        }

        /**
         * Check if the bulk object contains the data by key
         *
         * Example:
         * Boolean contains = bulkObj.containsData('Accounts');
         *
         * @param key The key of the data
         * @return Boolean
         * */
        public Boolean containsData(String key) {
            return this.data.containsKey(key);
        }

        /**
         * Return a Func that gets the data by the key
         *
         * Example:
         * Func f = bulkObj.data('Accounts');
         * List<Account> accounts = (List<Account>)f.run();
         *
         * @param key The key of the data
         * @return Func
         * */
        public Func data(String key) {
            return Trap.F.data.apply(this, key);
        }

        /**
         * Return a Func that wraps the original Func with data from the bulk object
         *
         * Example:
         * bulkObj.newStream
         *     .filter(bulkObj.provide('accounts', new CustomFilterFunc()));
         * // Provide 'accounts' data to the CustomFilterFunc
         *
         * @param key The key of the data
         * @param f The wrapped function
         * @return Func
         * */
        public Func provide(String key, Func f) {
            return this.provide(new List<String>{ key }, f);
        }

        /**
         * Return a Func that wraps the original Func with data from the bulk object
         *
         * Example:
         * bulkObj.newStream
         *     .filter(bulkObj.provide('accounts', 'ids', new CustomFilterFunc()));
         * // Provide 'accounts' data to the CustomFilterFunc
         *
         * @param key1 The key of the first data
         * @param key2 The key of the second data
         * @param f The wrapped function
         * @return Func
         * */
        public Func provide(String key1, String key2, Func f) {
            return this.provide(new List<String>{ key1, key2 }, f);
        }

        /**
         * Return a Func that wraps the original Func with data from the bulk object
         *
         * Example:
         * bulkObj.newStream
         *     .filter(bulkObj.provide('accounts', 'ids', 'urls', new CustomFilterFunc()));
         * // Provide 'accounts' data to the CustomFilterFunc
         *
         * @param key1 The key of the first data
         * @param key2 The key of the second data
         * @param key3 The key of the third data
         * @param f The wrapped function
         * @return Func
         * */
        public Func provide(String key1, String key2, String key3, Func f) {
            return this.provide(new List<String>{ key1, key2, key3 }, f);
        }

        /**
         * Return a Func that wraps the original Func with data from the bulk object
         *
         * Example:
         * bulkObj.newStream
         *     .filter(bulkObj.provide(new List<String>{ 'accounts' }, new CustomFilterFunc()));
         * // Provide 'accounts' data to the CustomFilterFunc
         *
         * @param dataKeys The keys of the data
         * @param f The wrapped function
         * @return Func
         * */
        public Func provide(List<String> dataKeys, Func f) {
            return (Func)Trap.F.provide.run(this, dataKeys, f);
        }

        /**
         * Return a Func that sets the computed value from the func and data into the data of key
         *
         * Example:
         * bulkObj.newStream
         *     .tap(bulkObj.data('accounts', new CustomGetAccountsFunc(), new List<String>{ 'ids' }));
         *
         * @param key The key of the data
         * @param f The Func to compute the value
         * @param dataNames The names of the input data from the bulk object
         * @return Func
         * */
        public Func data(String key, Func f, List<String> dataNames) {
            return Trap.F.data.applyN(new List<Object>{ this, key, f, dataNames });
        }

        /**
         * Return a Func that sets the computed value from the func and data into the data of key
         *
         * Example:
         * bulkObj.newStream
         *     .tap(bulkObj.data('accounts', new CustomGetAccountsFunc());
         *
         * @param key The key of the data
         * @param f The Func to compute the value
         * @return Func
         * */
        public Func data(String key, Func f) {
            return this.data(key, f, new List<String>());
        }

        /**
         * Return a Func that sets the computed value from the func and data into the data of key
         *
         * Example:
         * bulkObj.newStream
         *     .tap(bulkObj.data('accounts', new CustomGetAccountsFunc(), 'ids'));
         *
         * @param key The key of the data
         * @param f The Func to compute the value
         * @param dataName1 The name of the first input data
         * @return Func
         * */
        public Func data(String key, Func f, String dataName1) {
            return this.data(key, f, new List<String>{ dataName1 });
        }

        /**
         * Return a Func that sets the computed value from the func and data into the data of key
         *
         * Example:
         * bulkObj.newStream
         *     .tap(bulkObj.data('accounts', new CustomGetAccountsFunc(), 'ids', 'urls'));
         *
         * @param key The key of the data
         * @param f The Func to compute the value
         * @param dataName1 The name of the first input data
         * @param dataName2 The name of the second input data
         * @return Func
         * */
        public Func data(String key, Func f, String dataName1, String dataName2) {
            return this.data(key, f, new List<String>{ dataName1, dataName2 });
        }

        /**
         * Return a Func that sets the computed value from the func and data into the data of key
         *
         * Example:
         * bulkObj.newStream
         *     .tap(bulkObj.data('accounts', new CustomGetAccountsFunc(), 'ids', 'urls', 'src'));
         *
         * @param key The key of the data
         * @param f The Func to compute the value
         * @param dataName1 The name of the first input data
         * @param dataName2 The name of the second input data
         * @param dataName3 The name of the third input data
         * @return Func
         * */
        public Func data(String key, Func f, String dataName1, String dataName2, String dataName3) {
            return this.data(key, f, new List<String>{ dataName1, dataName2, dataName3 });
        }

        /**
         * Return a Func that sets the value to the data of key
         *
         * Example:
         * bulkObj.newStream
         *     .tap(bulkObj.data('data', 'test'));
         *
         * @param key The key of the data
         * @param value The value of the data
         * @return Func
         * */
        public Func data(String key, Object value) {
            return this.data(key, R.constant.apply(value));
        }
    }

    /**
     * All possible trigger events
     * 'All' means matching all the trigger events, and is only used in the bulk object that
     * tries to match all the events
     * */
    public enum Event {
        BeforeInsert,
        BeforeUpdate,
        BeforeDelete,
        AfterInsert,
        AfterUpdate,
        AfterDelete,
        AfterUndelete,
        All
    }

    /**
     * The trigger context
     *
     * This context is a copy of Salesforce trigger context and offers read-only attributes
     * */
    public class Context {
        public Boolean isExecuting { get; private set; }
        public String triggerObject { get; private set; }
        public Event triggerEvent { get; private set; }
        public TriggerHandler handler { get; private set; }
        public List<SObject> oldList { get; private set; }
        public List<SObject> newList { get; private set; }
        public Map<Id, SObject> oldMap { get; private set; }
        public Map<Id, SObject> newMap { get; private set; }

        // Activate the context
        void activate() {
            Trap.currentTriggerContext = this;
            Trap controller = this.handler.getController();
            if(controller == null) {
                return;
            }
            String name = this.handler.getName();

            controller.triggerContexts.add(this);

            Integer maxDepth = controller.getMaxReEntry(name);
            Boolean usingNewTransaction = controller.isUsingNewTransaction(name);

            String recursionKey = this.triggerObject + '_' + this.triggerEvent;
            Integer depth = controller.recursionDepth.get(recursionKey);
            if(depth == null) {
                depth = 0;
            }

            if(maxDepth >= 0 && depth >= maxDepth) {
                throw new TrapException('Max re-entry limit of ' + maxDepth + ' is reached');
            }
            else {
                depth += 1;
                controller.recursionDepth.put(recursionKey, depth);
            }

            if(usingNewTransaction) {
                String spKey = recursionKey + '_' + depth;
                if(!controller.savePoints.containsKey(spKey)) {
                    SavePoint sp = Database.setSavePoint();
                    controller.savePoints.put(spKey, sp);
                }
                else {
                    throw new TrapException('Transaction already existed for ' + spKey);
                }
            }
        }

        // Handles error in the context
        void onError(Exception e) {
            Trap controller = this.handler.getController();
            if(controller == null) {
                return;
            }
            String name = this.handler.getName();

            Integer maxDepth = controller.getMaxReEntry(name);
            Boolean usingNewTransaction = controller.isUsingNewTransaction(name);

            String recursionKey = this.triggerObject + '_' + this.triggerEvent;
            Integer depth = controller.recursionDepth.get(recursionKey);

            if(usingNewTransaction) {
                String spKey = recursionKey + '_' + depth;
                SavePoint sp = controller.savePoints.get(spKey);
                if(sp != null) {
                    Database.rollback(sp);
                }
                else {
                    throw new TrapException('Expected transaction is not created');
                }
            }
            else {
                throw e;
            }
        }

        // Deactivate the context
        void deactivate() {
            Trap controller = this.handler.getController();
            if(controller == null) {
                Trap.currentTriggerContext = null;
                return;
            }
            String name = this.handler.getName();

            Integer maxDepth = controller.getMaxReEntry(name);
            Boolean usingNewTransaction = controller.isUsingNewTransaction(name);

            String recursionKey = this.triggerObject + '_' + this.triggerEvent;
            Integer depth = controller.recursionDepth.get(recursionKey);

            if(usingNewTransaction) {
                String spKey = recursionKey + '_' + depth;
                controller.savePoints.remove(spKey);
            }

            depth -= 1;
            controller.recursionDepth.put(recursionKey, depth);

            controller.triggerContexts.remove(controller.triggerContexts.size() - 1);

            if(!controller.triggerContexts.isEmpty()) {
                Trap.currentTriggerContext = controller.triggerContexts.get(controller.triggerContexts.size() - 1);
            }
            else {
                Trap.currentTriggerContext = null;
            }
        }
    }

    /**
     * Extend this class to provide your own trigger handler implementation
     *
     * Usage 1:
     * // Functional reactive stream style
     * public with sharing class CaseTrigger extends Trap.TriggerHandler {
     *     public override void setUpBeforeInsert(Trap.BulkObject bulkObj) {
     *         bulkObj.newStream
     *             .tap(R.debug.apply('before insert'))
     *             .subscribe(Trap.F.addError.apply('test error'));
     *     }
     * }
     *
     * Usage 2:
     * // Normal event handler style
     * public with sharing class CaseTrigger extends Trap.TriggerHandler {
     *     public override void bulkBefore() {
     *         // Custom code
     *     }
     *
     *     public override void beforeInsert(SObject newSO) {
     *         Trap.Context triggerContext = this.getTriggerContext();
     *         // Custom code
     *     }
     * }
     *
     * Usage 3:
     * // Integration style
     * public with sharing class CaseTrigger extends Other.TriggerHandler {
     *     private Trap.TriggerHandler handler = new Trap.TriggerHandler();
     *
     *     public CaseTrigger() {
     *         handler.onBeforeInsert().newStream
     *             .tap(R.debug.apply('before insert'))
     *             .subscribe(Trap.F.addError.apply('test error'));
     *     }
     *
     *     public override void beforeInsert(SObject newSO) {
     *         handler.run();
     *     }
     * }
     * */
    public virtual class TriggerHandler {
        // The Trap controller
        private Trap controller;

        // The name registered in the controller
        private String name;

        // The trigger context
        private Context triggerContext;

        // Bulk objects mapped by the trigger events
        private Map<Event, BulkObject> bulkObjects;

        /**
         * Create a default instance of the trigger handler
         * Usually used when you want to integrate the stream functions in other
         * trigger frameworks
         * */
        public TriggerHandler() {
            bulkObjects = new Map<Event, BulkObject>();

            BulkObject bulkBeforeInsert = new BulkObject();
            this.setUpBeforeInsert(bulkBeforeInsert);
            this.bulkObjects.put(Event.BeforeInsert, bulkBeforeInsert);

            BulkObject bulkBeforeUpdate = new BulkObject();
            this.setUpBeforeUpdate(bulkBeforeUpdate);
            this.bulkObjects.put(Event.BeforeUpdate, bulkBeforeUpdate);

            BulkObject bulkBeforeDelete = new BulkObject();
            this.setUpBeforeDelete(bulkBeforeDelete);
            this.bulkObjects.put(Event.BeforeDelete, bulkBeforeDelete);

            BulkObject bulkAfterInsert = new BulkObject();
            this.setUpAfterInsert(bulkAfterInsert);
            this.bulkObjects.put(Event.AfterInsert, bulkAfterInsert);

            BulkObject bulkAfterUpdate = new BulkObject();
            this.setUpAfterUpdate(bulkAfterUpdate);
            this.bulkObjects.put(Event.AfterUpdate, bulkAfterUpdate);

            BulkObject bulkAfterDelete = new BulkObject();
            this.setUpAfterDelete(bulkAfterDelete);
            this.bulkObjects.put(Event.AfterDelete, bulkAfterDelete);

            BulkObject bulkAfterUndelete = new BulkObject();
            this.setUpAfterUndelete(bulkAfterUndelete);
            this.bulkObjects.put(Event.AfterUndelete, bulkAfterUndelete);

            BulkObject bulkAll = new BulkObject();
            this.setUp(bulkAll);
            this.bulkObjects.put(Event.All, bulkAll);
        }

        // Set the Trap controller
        void setController(Trap controller) {
            this.controller = controller;
        }

        // Get the Trap controller
        Trap getController() {
            return this.controller;
        }

        // Set the registered name of this trigger handler
        void setName(String name) {
            this.name = name;
        }

        // Get the registered name of this trigger handler
        String getName() {
            return this.name;
        }

        /**
         * Get the trigger context
         *
         * Example:
         * Trap.Context context = handler.getTriggerContext();
         *
         * @return Context
         * */
        public Context getTriggerContext() {
            return this.triggerContext;
        }

        /**
         * Get the bulk object to process trigger events 'before insert'
         *
         * Example:
         * handler.onBeforeInsert().newStream
         *     .subscribe(...)
         *
         * @return BulkObject
         * */
        public BulkObject onBeforeInsert() {
            return this.bulkObjects.get(Event.BeforeInsert);
        }

        /**
         * Get the bulk object to process trigger events 'before update'
         *
         * Example:
         * handler.onBeforeUpdate().newStream
         *     .subscribe(...)
         *
         * @return BulkObject
         * */
        public BulkObject onBeforeUpdate() {
            return this.bulkObjects.get(Event.BeforeUpdate);
        }

        /**
         * Get the bulk object to process trigger events 'before delete'
         *
         * Example:
         * handler.onBeforeDelete().newStream
         *     .subscribe(...)
         *
         * @return BulkObject
         * */
        public BulkObject onBeforeDelete() {
            return this.bulkObjects.get(Event.BeforeDelete);
        }

        /**
         * Get the bulk object to process trigger events 'after insert'
         *
         * Example:
         * handler.onAfterInsert().newStream
         *     .subscribe(...)
         *
         * @return BulkObject
         * */
        public BulkObject onAfterInsert() {
            return this.bulkObjects.get(Event.AfterInsert);
        }

        /**
         * Get the bulk object to process trigger events 'after update'
         *
         * Example:
         * handler.onAfterUpdate().newStream
         *     .subscribe(...)
         *
         * @return BulkObject
         * */
        public BulkObject onAfterUpdate() {
            return this.bulkObjects.get(Event.AfterUpdate);
        }

        /**
         * Get the bulk object to process trigger events 'after delete'
         *
         * Example:
         * handler.onAfterDelete().newStream
         *     .subscribe(...)
         *
         * @return BulkObject
         * */
        public BulkObject onAfterDelete() {
            return this.bulkObjects.get(Event.AfterDelete);
        }

        /**
         * Get the bulk object to process trigger events 'after undelete'
         *
         * Example:
         * handler.onAfterUndelete().newStream
         *     .subscribe(...)
         *
         * @return BulkObject
         * */
        public BulkObject onAfterUndelete() {
            return this.bulkObjects.get(Event.AfterUndelete);
        }

        /**
         * Get the bulk object to process all trigger events
         *
         * Example:
         * handler.onEvent().newStream
         *     .filter(Trap.F.isBeforeInsert)
         *     .subscribe(...)
         *
         * @return BulkObject
         * */
        public BulkObject onEvent() {
            return this.bulkObjects.get(Event.All);
        }

        /**
         * Override this method to provide set up beforeInsert bulk object
         * @param bulkObj The bulk object
         * */
        protected virtual void setUpBeforeInsert(BulkObject bulkObj) {
        }

        /**
         * Override this method to provide set up beforeUpdate bulk object
         * @param bulkObj The bulk object
         * */
        protected virtual void setUpBeforeUpdate(BulkObject bulkObj) {
        }

        /**
         * Override this method to provide set up beforeDelete bulk object
         * @param bulkObj The bulk object
         * */
        protected virtual void setUpBeforeDelete(BulkObject bulkObj) {
        }

        /**
         * Override this method to provide set up afterInsert bulk object
         * @param bulkObj The bulk object
         * */
        protected virtual void setUpAfterInsert(BulkObject bulkObj) {
        }

        /**
         * Override this method to provide set up afterUpdate bulk object
         * @param bulkObj The bulk object
         * */
        protected virtual void setUpAfterUpdate(BulkObject bulkObj) {
        }

        /**
         * Override this method to provide set up afterDelete bulk object
         * @param bulkObj The bulk object
         * */
        protected virtual void setUpAfterDelete(BulkObject bulkObj) {
        }

        /**
         * Override this method to provide set up afterUndelete bulk object
         * @param bulkObj The bulk object
         * */
        protected virtual void setUpAfterUndelete(BulkObject bulkObj) {
        }

        /**
         * Override this method to provide set up catch-all bulk object
         * @param bulkObj The bulk object
         * */
        protected virtual void setUp(BulkObject bulkObj) {
        }

        /**
         * Override this method to run code before the 'beforeXxx'
         * */
        protected virtual void bulkBefore() {
        }

        /**
         * Override this method to run code before the 'afterXxx'
         * */
        protected virtual void bulkAfter() {
        }

        /**
         * Override this method to run code on beforeInsert event
         *
         * @param so The new SObject
         * */
        protected virtual void beforeInsert(SObject so) {
            handleSObjects(null, so);
        }

        /**
         * Override this method to run code on beforeUpdate event
         *
         * @param oldSO The old SObject
         * @param newSO The new SObject
         * */
        protected virtual void beforeUpdate(SObject oldSO, SObject newSO) {
            handleSObjects(oldSO, newSO);
        }

        /**
         * Override this method to run code on beforeDelete event
         *
         * @param so The old SObject
         * */
        protected virtual void beforeDelete(SObject so) {
            handleSObjects(so, null);
        }

        /**
         * Override this method to run code on afterInsert event
         *
         * @param so The new SObject
         * */
        protected virtual void afterInsert(SObject so) {
            handleSObjects(null, so);
        }

        /**
         * Override this method to run code on afterUpdate event
         *
         * @param oldSO The old SObject
         * @param newSO The new SObject
         * */
        protected virtual void afterUpdate(SObject oldSO, SObject newSO) {
            handleSObjects(oldSO, newSO);
        }

        /**
         * Override this method to run code on afterDelete event
         *
         * @param so The old SObject
         * */
        protected virtual void afterDelete(SObject so) {
            handleSObjects(so, null);
        }

        /**
         * Override this method to run code on afterUndelete event
         *
         * @param so The new SObject
         * */
        protected virtual void afterUndelete(SObject so) {
            handleSObjects(null, so);
        }

        /**
         * Override this method to indicate whether this trigger handler is active
         *
         * @return Boolean
         * */
        protected virtual Boolean isActive() {
            return true;
        }

        // Check if the trigger handler can run
        private Boolean canRun() {
            if(controller != null) {
                return controller.isEnabled(this.name) && this.isActive();
            }
            else {
                return true;
            }
        }

        /**
         * Run the trigger handler
         * This method is primarily used in Salesforce trigger context
         *
         * Example:
         * Trap.getInstance().find('Case').run();
         *
         * */
        public void run() {
            this.run(null, null, null);
        }

        /**
         * Run the trigger handler
         *
         * Example:
         * Trap.getInstance().find('Case').run(Trap.Event.BeforeInsert, null, new List<SObject>{ new Case() });
         *
         * @param triggerEvent The trigger event
         * @param oldList The old SObjects
         * @param newList The new SObjects
         * */
        public void run(Event triggerEvent, List<SObject> oldList, List<SObject> newList) {
            Context triggerContext = Trap.createTriggerContext(triggerEvent, oldList, newList, this);

            try {
                triggerContext.activate();

                this.doRun(triggerContext);
            }
            catch(Exception e) {
                triggerContext.onError(e);
            }
            finally {
                triggerContext.deactivate();
            }
        }

        // Run the trigger handler
        private void doRun(Context triggerContext) {
            if(!this.canRun()) {
                return;
            }

            this.triggerContext = triggerContext;

            Event currentEvent = triggerContext.triggerEvent;

            List<SObject> data = triggerContext.newList;
            if(data == null || data.isEmpty()) {
                data = triggerContext.oldList;
            }

            if(currentEvent == Event.BeforeInsert ||
                currentEvent == Event.BeforeUpdate ||
                currentEvent == Event.BeforeDelete) {
                this.bulkBefore();
            }
            else if(currentEvent == Event.AfterInsert ||
                currentEvent == Event.AfterUpdate ||
                currentEvent == Event.AfterDelete ||
                currentEvent == Event.AfterUndelete) {
                this.bulkAfter();
            }

            for(SObject so : data) {
                SObject oldSO = (SObject)Trap.F.getOld.run(so);
                SObject newSO = (SObject)Trap.F.getNew.run(so);

                if(currentEvent == Event.BeforeInsert) {
                    this.beforeInsert(newSO);
                }
                else if(currentEvent == Event.BeforeUpdate) {
                    this.beforeUpdate(oldSO, newSO);
                }
                else if(currentEvent == Event.BeforeDelete) {
                    this.beforeDelete(oldSO);
                }
                else if(currentEvent == Event.AfterInsert) {
                    this.afterInsert(newSO);
                }
                else if(currentEvent == Event.AfterUpdate) {
                    this.afterUpdate(oldSO, newSO);
                }
                else if(currentEvent == Event.AfterDelete) {
                    this.afterDelete(oldSO);
                }
                else if(currentEvent == Event.AfterUndelete) {
                    this.afterUndelete(newSO);
                }
            }

            complete();
        }

        // Handle the SObjects
        private void handleSObjects(SObject oldSO, SObject newSO) {
            Event currentEvent = this.triggerContext.triggerEvent;
            BulkObject bulkObj = this.bulkObjects.get(currentEvent);
            BulkObject bulkObjAll = this.bulkObjects.get(Event.All);

            if(newSO != null) {
                bulkObj.newStream.next(newSO);
                bulkObjAll.newStream.next(newSO);
            }

            if(oldSO != null) {
                bulkObj.oldStream.next(oldSO);
                bulkObjAll.oldStream.next(oldSO);
            }
        }

        // Complete
        private void complete() {
            Event currentEvent = this.triggerContext.triggerEvent;
            BulkObject bulkObj = this.bulkObjects.get(currentEvent);
            BulkObject bulkObjAll = this.bulkObjects.get(Event.All);

            bulkObj.newStream.complete();
            bulkObjAll.newStream.complete();

            bulkObj.oldStream.complete();
            bulkObjAll.oldStream.complete();
        }
    }

    // The trigger config object
    private class TriggerConfig {
        public Boolean enabled = true;
        public Integer maxReEntry = -1;
        public Boolean usingNewTransaction = false;
    }

    public class TrapException extends Exception {
    }

    // Exported functions
    public class Funcs {
        /**
         * Update the field of the SObject
         *
         * Example:
         * SObject newVal = (SObject)Trap.F.updateField.run('Subject', 'New subject', new Case());
         *
         * @param arg1 The name of the field
         * @param arg2 The update field name or Func
         * @param arg3 The SObject
         * @return Object(SObject)
         * */
        public Func updateField = new UpdateFieldFunc();

        /**
         * Add an error to the SObject
         *
         * Example:
         * SObject newVal = (SObject)Trap.F.addError.run('test error', new Case());
         *
         * @param arg1 The error, either String or Exception
         * @param arg2 The SObject
         * @return Object(SObject)
         * */
        public Func addError = new AddErrorFunc();

        /**
         * Validate the SObject
         *
         * Example:
         * SObject newVal = (SObject)Trap.F.validate.run(R.propSatisfies.apply('Subject', R.isNotNull), 'Should not be null', new Case());
         *
         * @param arg1 The pred Func to check if the SObject is valid
         * @param arg2 The field name
         * @param arg3 The SObject
         * @return Object(SObject)
         * */
        public Func validate = new ValidateFunc();

        /**
         * Get the new SObject
         * Note: only available in a trigger context
         *
         * Example:
         * SObject newVal = (SObject)Trap.F.getNew.run(val);
         *
         * @param arg The SObject
         * @return Object(SObject)
         * */
        public Func getNew = new GetNewFunc();

        /**
         * Get the old SObject
         * Note: only available in a trigger context
         *
         * Example:
         * SObject oldVal = (SObject)Trap.F.getOld.run(val);
         *
         * @param arg The SObject
         * @return Object(SObject)
         * */
        public Func getOld = new GetOldFunc();

        /**
         * Check if the sobject has changed according to the condition
         * Note: only available in a trigger context
         *
         * Example:
         * Boolean changed = (Boolean)Trap.F.changed.run('Subject', val);
         *
         * @param arg1 The field name or the Func to get a value
         * @param arg2 The SObject
         * @return Object(SObject)
         * */
        public Func changed = new ChangedFunc();

        /**
         * Get/set the data of the bulk object
         * Please see BulkObject#data method
         * */
        public Func data = new DataFunc();

        /**
         * Provide data from the bulk object as the arguments to the wrapped function
         * Please see BulkObject#provide method
         * */
        public Func provide = new ProvideFunc();

        /**
         * Check if the current trigger event is the given event
         *
         * Example:
         * Boolean result = (Boolean)Trap.F.isEvent.run(Trap.Event.BeforeInsert);
         *
         * @param arg The trigger event
         * @return Object(Boolean)
         * */
        public Func isEvent = new IsEventFunc();

        /**
         * Check if the current trigger event is beforeInsert
         *
         * Example:
         * Boolean result = (Boolean)Trap.F.isBeforeInsert.run();
         *
         * @return Object(Boolean)
         * */
        public Func isBeforeInsert = isEvent.apply(Event.BeforeInsert);

        /**
         * Check if the current trigger event is beforeUpdate
         *
         * Example:
         * Boolean result = (Boolean)Trap.F.isBeforeInsert.run();
         *
         * @return Object(Boolean)
         * */
        public Func isBeforeUpdate = isEvent.apply(Event.BeforeUpdate);

        /**
         * Check if the current trigger event is beforeDelete
         *
         * Example:
         * Boolean result = (Boolean)Trap.F.isBeforeInsert.run();
         *
         * @return Object(Boolean)
         * */
        public Func isBeforeDelete = isEvent.apply(Event.BeforeDelete);

        /**
         * Check if the current trigger event is afterInsert
         *
         * Example:
         * Boolean result = (Boolean)Trap.F.isBeforeInsert.run();
         *
         * @return Object(Boolean)
         * */
        public Func isAfterInsert = isEvent.apply(Event.AfterInsert);

        /**
         * Check if the current trigger event is afterUpdate
         *
         * Example:
         * Boolean result = (Boolean)Trap.F.isBeforeInsert.run();
         *
         * @return Object(Boolean)
         * */
        public Func isAfterUpdate = isEvent.apply(Event.AfterUpdate);

        /**
         * Check if the current trigger event is afterDelete
         *
         * Example:
         * Boolean result = (Boolean)Trap.F.isBeforeInsert.run();
         *
         * @return Object(Boolean)
         * */
        public Func isAfterDelete = isEvent.apply(Event.AfterDelete);

        /**
         * Check if the current trigger event is afterUndelete
         *
         * Example:
         * Boolean result = (Boolean)Trap.F.isBeforeInsert.run();
         *
         * @return Object(Boolean)
         * */
        public Func isAfterUndelete = isEvent.apply(Event.AfterUndelete);
    }

    private class ProvideFunc extends Func {
        public ProvideFunc() {
            super(3);
        }

        public override Object exec(Object arg1, Object arg2, Object arg3) {
            BulkObject bulkObj = (BulkObject)arg1;
            List<String> dataKeys = (List<String>)R.toStringList.run(arg2);
            Func f = (Func)R.toFunc.run(arg3);

            return new FuncProvide(bulkObj, dataKeys, f);
        }
    }

    private class FuncProvide extends Func {
        private BulkObject bulkObj;
        private List<String> dataKeys;
        private Func target;

        public FuncProvide(BulkObject bulkObj, List<String> dataKeys, Func target) {
            super(-1);

            this.bulkObj = bulkObj;
            this.dataKeys = dataKeys;
            this.target = target;
        }

        public override Object execN(List<Object> args) {
            List<Object> fArgs = new List<Object>();
            for(String key : this.dataKeys) {
                fArgs.add(this.bulkObj.getData(key));
            }

            fArgs.addAll(args);

            return this.target.runN(fArgs);
        }
    }

    private class IsEventFunc extends Func {
        public IsEventFunc() {
            super(1);
        }

        public override Object exec(Object arg) {
            Event triggerEvent = (Event)arg;

            return Trap.currentTriggerContext.triggerEvent == triggerEvent;
        }
    }

    private class DataFunc extends Func {
        public DataFunc() {
            super(-1);
        }

        public override Object execN(List<Object> args) {
            BulkObject bulkObj = (BulkObject)args.get(0);
            String name = (String)R.toString.run(args.get(1));

            if(Trap.currentTriggerContext != null && !Trap.currentTriggerContext.isExecuting) {
                return null;
            }

            if(args.size() > 2) {
                if(bulkObj.containsData(name)) {
                    return bulkObj.getData(name);
                }

                Func f = (Func)args.get(2);

                if(f == null) {
                    return bulkObj.getData(name);
                }

                List<Object> fArgs = new List<Object>();
                if(args.size() > 3) {
                    List<String> names = (List<String>)args.get(3);
                    for(String n : names) {
                        fArgs.add(bulkObj.getData(n));
                    }
                }

                if(Trap.currentTriggerContext != null) {
                    Map<Id, SObject> input = Trap.currentTriggerContext.newMap;
                    if(input == null || input.isEmpty()) {
                        input = Trap.currentTriggerContext.oldMap;
                    }
                    fArgs.add(input);
                }

                Object value = f.runN(fArgs);
                bulkObj.setData(name, value);

                return value;
            }
            else {
                return bulkObj.getData(name);
            }
        }
    }

    private class ChangedFunc extends Func {
        public ChangedFunc() {
            super(2);
        }

        public override Object exec(Object arg1, Object arg2) {
            Object target = arg2;
            Func f = null;

            if(arg1 instanceof String) {
                f = R.prop.apply(arg1);
            }
            else if(arg1 instanceof Func) {
                f = (Func)arg1;
            }

            if(f != null) {
                Object oldValue = Trap.F.getOld.run(target);
                Object newValue = Trap.F.getNew.run(target);

                return f.run(oldValue) != f.run(newValue);
            }

            return false;
        }
    }

    private class GetNewFunc extends Func {
        public GetNewFunc() {
            super(1);
        }

        public override Object exec(Object arg) {
            SObject target = (SObject)arg;

            if(Trap.currentTriggerContext.isExecuting && Trap.currentTriggerContext.newList != null) {
                Id id = (Id)target.get('Id');
                return id == null ? target : Trap.currentTriggerContext.newMap.get(id);
            }

            return null;
        }
    }

    private class GetOldFunc extends Func {
        public GetOldFunc() {
            super(1);
        }

        public override Object exec(Object arg) {
            SObject target = (SObject)arg;

            if(Trap.currentTriggerContext.isExecuting && Trap.currentTriggerContext.oldList != null) {
                Id id = (Id)target.get('Id');
                return id == null ? null : Trap.currentTriggerContext.oldMap.get(id);
            }

            return null;
        }
    }

    private class ValidateFunc extends Func {
        public ValidateFunc() {
            super(3);
        }

        public override Object exec(Object arg1, Object arg2, Object arg3) {
            Func pred = (Func)arg1;
            Object error = arg2;
            Object target = arg3;

            Boolean pass = (Boolean)pred.run(target);
            if(!pass) {
                target = Trap.F.addError.run(error, target);
            }

            return target;
        }
    }

    private class AddErrorFunc extends Func {
        public AddErrorFunc() {
            super(2);
        }

        public override Object exec(Object arg1, Object arg2) {
            SObject target = (SObject)arg2;

            if(arg1 instanceof String) {
                target.addError((String)arg1);
            }
            else if(arg1 instanceof Exception) {
                target.addError((Exception)arg1);
            }

            return target;
        }
    }

    private class UpdateFieldFunc extends Func {
        public UpdateFieldFunc() {
            super(3);
        }

        public override Object exec(Object arg1, Object arg2, Object arg3) {
            String field = (String)R.toString.run(arg1);
            SObject target = (SObject)R.toSObject.run(arg3);

            if(arg2 instanceof Func) {
                Func updateFn = (Func)arg2;

                Object oldValue = target.get(field);
                Object newValue = updateFn.run(oldValue);

                target.put(field, newValue);
            }
            else {
                Object value = arg2;

                target.put(field, value);
            }

            return target;
        }
    }
}
