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
public with sharing class CaseTrigger extends Trap.TriggerHandler {
    public static Func beforeInsertFunc;
    public static Func beforeUpdateFunc;
    public static Func beforeDeleteFunc;
    public static Func afterInsertFunc;
    public static Func afterUpdateFunc;
    public static Func afterDeleteFunc;
    public static Func afterUndeleteFunc;
    public static Func allFunc;

    public static Func dataFunc;
    public static Func verifyFunc = R.identity;

    public static Boolean isActive = true;

    public override void setUpBeforeInsert(Trap.BulkObject bulkObj) {
        bulkObj.newStream
            .tap(bulkObj.data('data', dataFunc))
            .tap(verifyFunc.apply(bulkObj))
            .tap(R.debug.apply('before insert'))
            .subscribe(CaseTrigger.beforeInsertFunc);
    }

    public override void setUpBeforeUpdate(Trap.BulkObject bulkObj) {
        bulkObj.newStream
            .tap(R.debug.apply('before update'))
            .subscribe(CaseTrigger.beforeUpdateFunc);
    }

    public override void setUpBeforeDelete(Trap.BulkObject bulkObj) {
        bulkObj.oldStream
            .tap(R.debug.apply('before delete'))
            .subscribe(CaseTrigger.beforeDeleteFunc);
    }

    public override void setUpAfterInsert(Trap.BulkObject bulkObj) {
        bulkObj.newStream
            .tap(R.debug.apply('after insert'))
            .subscribe(CaseTrigger.afterInsertFunc);
    }

    public override void setUpAfterUpdate(Trap.BulkObject bulkObj) {
        bulkObj.newStream
            .tap(R.debug.apply('after update'))
            .subscribe(CaseTrigger.afterUpdateFunc);
    }

    public override void setUpAfterDelete(Trap.BulkObject bulkObj) {
        bulkObj.oldStream
            .tap(R.debug.apply('after delete'))
            .subscribe(CaseTrigger.afterDeleteFunc);
    }

    public override void setUpAfterUndelete(Trap.BulkObject bulkObj) {
        bulkObj.newStream
            .tap(R.debug.apply('after undelete'))
            .subscribe(CaseTrigger.afterUndeleteFunc);
    }

    public override void setUp(Trap.BulkObject bulkObj) {
        bulkObj.newStream
            .filter(Trap.F.isBeforeInsert)
            .tap(R.debug.apply('all filtered by before insert'))
            .subscribe(CaseTrigger.allFunc);
    }

    public override Boolean isActive() {
        return CaseTrigger.isActive;
    }
}
