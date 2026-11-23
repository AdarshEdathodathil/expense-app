const fs = require('fs');
const path = require('path');
const assert = require('assert');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { Timestamp } = require('firebase/firestore');

let env;

async function run() {
  env = await initializeTestEnvironment({
    projectId: 'expense-tracker-10f12',
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
    },
  });

  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.doc('households/h1').set({name: 'Test household', monthlyBudgetMinor: 6000000});
    await db.doc('households/h1/members/owner').set({role: 'owner', status: 'active'});
    await db.doc('households/h1/members/member').set({role: 'member', status: 'active'});
  });

  const owner = env.authenticatedContext('owner').firestore();
  const member = env.authenticatedContext('member').firestore();
  const removed = env.authenticatedContext('removed').firestore();
  const outsider = env.authenticatedContext('outsider').firestore();
  const creator = env.authenticatedContext('creator').firestore();
  const transaction = {
    householdId: 'h1', type: 'expense', amountMinor: 1000, currency: 'INR',
    category: 'Groceries', note: 'Test', createdBy: 'member', createdByName: 'Member',
    transactionDate: Timestamp.now(), createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(), deletedAt: null,
    needOrWant: 'need', isRecurring: false, repeatFrequency: null,
    monthlyType: null, numberOfPayments: null, recurrenceStartDate: null,
    recurrenceEndDate: null, recurrenceParentId: null, occurrenceDate: null,
  };

  await assertSucceeds(member.doc('households/h1/transactions/t1').set(transaction));
  await assertSucceeds(owner.doc('households/h1/transactions/t1').update({deletedAt: new Date()}));
  await assertFails(outsider.doc('households/h1/transactions/t2').set(transaction));
  await assertFails(outsider.doc('households/h1').get());
  await assertSucceeds(removed.doc('households/h1/members/removed').get());
  await assertFails(removed.doc('households/h1/members/member').get());
  await assertFails(removed.doc('households/h1').get());
  await assertSucceeds(member.doc('households/h1/budgets/2026-11').set({
    month: '2026-11', amountMinor: 5000000, updatedAt: Timestamp.now(),
  }));
  await assertFails(outsider.doc('households/h1/budgets/2026-11').get());
  await assertFails(member.doc('households/h1/budgets/2026-10').set({
    month: 'wrong-month', amountMinor: 5000000, updatedAt: Timestamp.now(),
  }));
  const setupBatch = creator.batch();
  setupBatch.set(creator.doc('households/h2'), {ownerId: 'creator'});
  setupBatch.set(creator.doc('households/h2/members/creator'), {
    userId: 'creator', role: 'owner', status: 'active',
  });
  setupBatch.set(creator.doc('households/h2/budgets/2026-11'), {
    month: '2026-11', amountMinor: 6000000, updatedAt: Timestamp.now(),
  });
  await assertSucceeds(setupBatch.commit());
  console.log('Firestore security rules passed.');
}

run().finally(() => env?.cleanup());
