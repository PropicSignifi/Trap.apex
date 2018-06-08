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
@isTest
private class TrapTest {
    @isTest
    private static void findTest() {
        Trap.TriggerHandler handler = Trap.getInstance().find('Case');
        System.assert(handler != null);
    }

    @isTest
    private static void beforeInsertTest() {
        TraceFunc tf = new TraceFunc();
        CaseTrigger.beforeInsertFunc = tf;

        Case c = new Case();
        insert c;

        System.assertEquals(1, tf.getCount());
    }

    @isTest
    private static void beforeUpdateTest() {
        TraceFunc tf = new TraceFunc();
        CaseTrigger.beforeUpdateFunc = tf;

        Case c = new Case();
        insert c;

        c.Subject = 'test';
        update c;

        System.assertEquals(1, tf.getCount());
    }

    @isTest
    private static void beforeDeleteTest() {
        TraceFunc tf = new TraceFunc();
        CaseTrigger.beforeDeleteFunc = tf;

        Case c = new Case();
        insert c;

        delete c;

        System.assertEquals(1, tf.getCount());
    }

    @isTest
    private static void afterInsertTest() {
        TraceFunc tf = new TraceFunc();
        CaseTrigger.afterInsertFunc = tf;

        Case c = new Case();
        insert c;

        System.assertEquals(1, tf.getCount());
    }

    @isTest
    private static void afterUpdateTest() {
        TraceFunc tf = new TraceFunc();
        CaseTrigger.afterUpdateFunc = tf;

        Case c = new Case();
        insert c;

        c.Subject = 'test';
        update c;

        System.assertEquals(1, tf.getCount());
    }

    @isTest
    private static void afterDeleteTest() {
        TraceFunc tf = new TraceFunc();
        CaseTrigger.afterDeleteFunc = tf;

        Case c = new Case();
        insert c;

        delete c;

        System.assertEquals(1, tf.getCount());
    }

    @isTest
    private static void afterUndeleteTest() {
        TraceFunc tf = new TraceFunc();
        CaseTrigger.afterUndeleteFunc = tf;

        Case c = new Case();
        insert c;

        delete c;
        undelete c;

        System.assertEquals(1, tf.getCount());
    }

    @isTest
    private static void updateFieldTest() {
        CaseTrigger.beforeInsertFunc = Trap.F.updateField.apply('Subject', 'test');

        Case c = new Case();
        insert c;

        c = [ SELECT Id, Subject FROM CASE WHERE Id =: c.Id ];

        System.assertEquals('test', c.Subject);
    }

    @isTest
    private static void addErrorTest() {
        CaseTrigger.beforeInsertFunc = Trap.F.addError.apply('test error');

        try {
            Case c = new Case();
            insert c;

            System.assert(false);
        }
        catch(Exception e) {
            System.assert(true);
        }
    }

    @isTest
    private static void validateTest() {
        CaseTrigger.beforeInsertFunc = Trap.F.validate.apply(R.propSatisfies.apply('Subject', R.isNotNull), 'validation failed');

        try {
            Case c = new Case();
            insert c;

            System.assert(false);
        }
        catch(Exception e) {
            System.assert(true);
        }
    }

    @isTest
    private static void getNewTest() {
        CaseTrigger.beforeUpdateFunc = (Func)R.pipe.run(
            Trap.F.getNew,
            R.isNotNull,
            R.assert
        );

        Case c = new Case();
        insert c;

        c.Subject = 'new subject';
        update c;
    }

    @isTest
    private static void getOldTest() {
        CaseTrigger.beforeUpdateFunc = (Func)R.pipe.run(
            Trap.F.getOld,
            R.isNotNull,
            R.assert
        );

        Case c = new Case();
        insert c;

        c.Subject = 'new subject';
        update c;
    }

    @isTest
    private static void changedTest() {
        CaseTrigger.beforeUpdateFunc = (Func)R.ifElse.run(
            Trap.F.changed.apply('Subject'),
            R.assert.apply(true),
            R.assert.apply(false)
        );

        Case c = new Case();
        insert c;

        c.Subject = 'new subject';
        update c;
    }

    @isTest
    private static void dataTest() {
        CaseTrigger.dataFunc = R.constant.apply('test');
        CaseTrigger.verifyFunc = (Func)R.pipe.run(
            Trap.F.data.apply(R.placeholder, 'data'),
            R.assertEquals.apply('test')
        );

        Case c = new Case();
        insert c;
    }

    @isTest
    private static void enableTest() {
        Trap.getInstance().disable('Case');

        TraceFunc tf = new TraceFunc();
        CaseTrigger.beforeInsertFunc = tf;

        Case c = new Case();
        insert c;

        System.assertEquals(0, tf.getCount());
    }

    @isTest
    private static void enableAllTest() {
        Trap.getInstance().disableAll();

        TraceFunc tf = new TraceFunc();
        CaseTrigger.beforeInsertFunc = tf;

        Case c = new Case();
        insert c;

        System.assertEquals(0, tf.getCount());
    }

    @isTest
    private static void isActiveTest() {
        TraceFunc tf = new TraceFunc();
        CaseTrigger.beforeInsertFunc = tf;
        CaseTrigger.isActive = false;

        Case c = new Case();
        insert c;

        System.assertEquals(0, tf.getCount());
    }

    @isTest
    private static void contextTest() {
        TraceFunc tf = new TraceFunc();
        CaseTrigger.beforeInsertFunc = tf;

        Trap.getInstance().start(Trap.Event.BeforeInsert, null, new List<SObject>{ new Case() });

        System.assertEquals(1, tf.getCount());
    }

    @isTest
    private static void setUpAllTest() {
        TraceFunc tf = new TraceFunc();
        CaseTrigger.allFunc = tf;

        Case c = new Case();
        insert c;

        System.assertEquals(1, tf.getCount());
    }

    @isTest
    private static void recursionTest() {
        Trap.getInstance().setMaxReEntry('Case', 3);
        CaseTrigger.afterInsertFunc = new InsertCaseFunc();

        try {
            Trap.getInstance().start(Trap.Event.AfterInsert, null, new List<SObject>{ new Case() });
            System.assert(false);
        }
        catch(Trap.TrapException e) {
            System.assert(true);
        }
    }

    @isTest
    private static void newTransactionTest() {
        Trap.getInstance().setUsingNewTransaction('Case', true);

        TraceFunc tf = new TraceFunc();
        CaseTrigger.beforeInsertFunc = tf;

        Trap.getInstance().start(Trap.Event.BeforeInsert, null, new List<SObject>{ new Case() });

        System.assertEquals(1, tf.getCount());
    }

    @isTest
    private static void provideTest() {
        Trap.BulkObject bulkObj = new Trap.BulkObject();
        bulkObj.newStream
            .tap(bulkObj.data('data', R.constant.apply('test')))
            .subscribe(bulkObj.provide('data', R.assertEquals.apply('test')));

        bulkObj.newStream.next(1);
    }

    private class InsertCaseFunc extends Func {
        public InsertCaseFunc() {
            super(0);
        }

        public override Object exec() {
            Trap.getInstance().start(Trap.Event.AfterInsert, null, new List<SObject>{ new Case() });

            return null;
        }
    }

    private class TraceFunc extends Func {
        private Integer count = 0;

        public Integer getCount() {
            return this.count;
        }

        public override Object execN(List<Object> args) {
            this.count += 1;

            return null;
        }
    }
}
