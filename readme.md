# MiniSignals

MiniSignals is a minimalistic signal system that is trying to be kind of like Django's signal system.
You `connect` procs with a signature of `proc(connection: DbConn, modelInstance: <YOUR TYPE>)` to triggerTimes determined by the `SignalType` enum and specific object types determined by you.
By associating them, pointers to the procs are stored in a HashSet.

Whenever you call the `triggerSignal` proc with an object of the type you used to connect the proc, it'll fetch the Hashset and execute all procs within it, passing it a database connection and an instance of the object for which the signal was triggered.
