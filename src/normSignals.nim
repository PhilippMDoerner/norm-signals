import std/[tables, sets, hashes, db_sqlite, typetraits, logging, strformat]

var LOGGER = newConsoleLogger(lvlInfo)

type SignalType* = enum
  ## Denotes possible trigger points for signals, meaning the system will look
  ## for to execute appropriate signal procs after or before a create/delete/update action 
  stPreCreate
  stPostCreate
  stPreDelete
  stPostDelete
  stPreUpdate
  stPostUpdate


type SignalProcStore = object
  ## Stores pointers to all Signal procs. A Signal proc is a proc that is 
  ## executed before or after a create/update/delete action happens. They 
  ## are associated with a specific object type and 
  ## when they should trigger (determined by SignalType). SignalProcs 
  ## always have the signature: 
  ## proc(connection: DbConn, modelInstance: <YOUR OBJECT TYPE>).
  procs: Table[string, Table[SignalType, HashSet[pointer]]]

var STORE {.global.}: SignalProcStore
proc hasTableKind(tableKind: string): bool = STORE.procs.hasKey(tableKind)
proc hasSignal(signalType: SignalType, tableKind: string): bool =
  result = hasTableKind(tableKind) and STORE.procs[tableKind].hasKey(signalType)


proc connect*[T: object](signalType: SignalType, model: typedesc[T], signalProc: pointer) =
  ## Associates the given proc with the given object type and signaltype. The signalProc is triggered
  ## whenever `triggerSignal` is called with the corresponding signalType and object type.
  const tableKind: string = name(T)

  if not hasTableKind(tableKind):
    STORE.procs[tableKind] = initTable[SignalType, HashSet[pointer]]()
  
  if not hasSignal(signalType, tableKind):
    STORE.procs[tableKind][signalType] = initHashSet[pointer]()

  STORE.procs[tableKind][signalType].incl(signalProc)

  let myLen = STORE.procs[tableKind][signalType].len()
  LOGGER.log(lvlInfo, fmt "SIGNALSYSTEM: Connected {signalType} signal to model {name(T)} - There is/are now {myLen} {signalType} signal(s)")


proc triggerSignal*[T: object](signalType: SignalType, connection: DbConn, modelInstance: T) =
  ## Triggers all stored signal procs for the given modelInstance and the given signalType
  let tableKind: string = name(modelInstance.type)
  if not hasSignal(signalType, tableKind): return

  let signalProcPointers: HashSet[pointer] = STORE.procs[tableKind][signalType]
  for procPointer in signalProcPointers.items:
    type TempProc = proc (connection: DbConn, modelInstance: T) {.nimcall.}
    let signalProc = cast[TempProc](procPointer)
    signalProc(connection, modelInstance)