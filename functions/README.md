# Trace scheduled functions

`generateRecurringTransactions` runs once per day in `asia-south1` and creates
idempotent occurrence documents for recurring expenses. Deploying Cloud
Scheduler/Functions requires a Firebase project on the Blaze billing plan.
Install dependencies inside this directory, then run `npm run deploy` from it
only after billing and the production schedule have been approved.
