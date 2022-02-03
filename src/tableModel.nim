import std/[strutils, typetraits]
import norm/model

type SomeModel = ref object of Model

type TableModelKind* = enum
  someModel = name(SomeModel).toLower()

type TableModelVariant* = ref object
  case kind: TableModelKind
  of TableModelKind.someModel: someModel: SomeModel