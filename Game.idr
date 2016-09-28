module Game

import Control.Isomorphism 
import Data.Fin
import Data.Vect

%hide World
%default total

interface World pl where
  Cmd : pl -> Type
  Que : pl -> Type
  Ans : (p : pl) -> Que p -> Type

implementation [W] World (Fin 3) where
  Cmd n = Unit
  Que n = (Nat,Nat)
  Ans n (i,j) = Char

data Action : {w : World pl} -> Type -> Type where
  Wait : Action t
  ResignAt : t -> Action t
  TellAt   : (p : pl) -> {w : World pl} -> t -> Cmd p -> Action t
  AskAt    : (p' : pl) -> {w : World pl} -> t -> Que p' -> Action t

data Move : {w : World pl} -> pl -> Type where
  Resign : (p : pl) -> Move {w} p
  Tell : (p : pl) -> {w : World pl} -> Cmd p -> Move {w} p
  Ask : (p : pl) -> (p' : pl) -> {w : World pl} -> (q : Que p') -> Ans p' q -> Move {w} p

Entry : {pl : Type} -> World pl -> Type -> Type
Entry {pl} w t = (t, (p : pl ** Move {pl} {w} p))

History : {pl : Type} -> World pl -> Type -> Type
History w t = List (Entry w t)

Game : {pl : Type} -> World pl -> Type -> Type
Game w t = Stream (Entry w t)

data Finite : Type -> Type where
  MkFinite : {t : Type} -> (n : Nat) -> Iso t (Fin n) -> Finite t

voidFin : Finite Void
voidFin = MkFinite {t=Void} 0 (the (Iso Void (Fin 0)) prf) where
  to : Void -> Fin 0
  to = void
  from : Fin 0 -> Void
  from = FinZElim
  fromTo : (y : Fin 0) -> to (from y) = y
  fromTo foo = FinZElim foo
  toFrom : (x : Void) -> from (to x) = x
  toFrom foo = void foo
  prf = MkIso to from fromTo toFrom

finFin : Finite (Fin n)
finFin {n} = MkFinite n isoRefl

finFold : {prf : Finite t} -> (t -> acc -> acc) -> acc -> acc
finFold {prf=(MkFinite Z     (MkIso _ from _ _))} f start = start
finFold {prf=(MkFinite (S n) (MkIso _ from _ _))} f start =
  let elements = map from (range {n=S n}) in
  foldr f start elements

record Strategy (pl : Type) (w : World pl) (t : Type) where
  constructor MkStrategy
  pickAction : History w t -> Action {pl} {w} t
  answerQuestion : (p : pl) -> History w t -> (q : Que p) -> Ans p q

play : Finite pl -> Strategy pl w t -> Game w t
play prf str = ?haha

{-
how to play. ask all players for an action. Ignore any "wait" actions. the rest
of the actions contain a timestamp. calculate the minimum, then take the
non-empty set of actions which equal that minimum. all such actions translate
into an element in the next entry, tells and resigns translate directly, and
asks must be answered by the appropriate player. if any of the winning actions
was "resign" then the game ends. otherwise play repeats by asking all players
for another action, including any players who lost the race (they might now
change their minds because of the new entry in the move list).

a chosen time must be greater than the greatest time in the move list.
-}

--This causes indefinite 100% cpu on type checking, but thats another story
{-
data OrdList : (t : Type) -> {rel : t -> t -> Type} -> t -> Type where
  Cell : (x : t) -> OrdList t x
  Cons : {rel : t -> t -> Type} -> (y : t) -> OrdList t x -> x `rel` y -> OrdList t y
-}
