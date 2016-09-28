module Game

import Control.Isomorphism 
import Data.Fin
import Data.Vect

%hide World
%default total

||| A world, parameterized by a player type, is a family of
||| command and question types for each player. There is also
||| a family of answer types indexed by each question type.
interface World playerTy where
  Cmd : playerTy -> Type
  Que : playerTy -> Type
  Ans : (p : playerTy) -> Que p -> Type

||| The four actions to choose from.
data Action : {w : World pl} -> Type -> Type where
  Wait : Action t
  ResignAt : t -> Action t
  TellAt   : (p : pl) -> {w : World pl} -> t -> Cmd p -> Action t
  AskAt    : (p' : pl) -> {w : World pl} -> t -> Que p' -> Action t

||| The moves that can appear in the move list entries.
data Move : {w : World pl} -> pl -> Type where
  Resign : (p : pl) -> Move {w} p
  Tell : (p : pl) -> {w : World pl} -> Cmd p -> Move {w} p
  Ask : (p : pl) -> (p' : pl) -> {w : World pl} -> (q : Que p') -> Ans p' q -> Move {w} p

||| An entry is the move time and a collection of (player, move) pairs
Entry : {pl : Type} -> World pl -> Type -> Type
Entry {pl} w t = (t, (p : pl ** Move {pl} {w} p))

||| A finite prefix of the move list.
History : {pl : Type} -> World pl -> Type -> Type
History w t = List (Entry w t)

||| The full move list as a stream of entries.
Game : {pl : Type} -> World pl -> Type -> Type
Game w t = Stream (Entry w t)

||| A computer player consists of a (pure, total) function to pick actions
||| and to answer questions if necessary. Because of the rules, this game is
||| still turing complete.
record Strategy (pl : Type) (w : World pl) (t : Type) where
  constructor MkStrategy
  pickAction : History w t -> Action {pl} {w} t
  answerQuestion : (p : pl) -> History w t -> (q : Que p) -> Ans p q

||| A type is finite if it is bijective with Fin n for some n.
||| The player type is necessarily finite so we can compute the minimum time.
data Finite : Type -> Type where
  MkFinite : {t : Type} -> (n : Nat) -> Iso t (Fin n) -> Finite t

--- work in progress below

voidFin : Finite Void
voidFin = MkFinite {t=Void} 0 (isoSym finZeroBot)

finFin : Finite (Fin n)
finFin {n} = MkFinite n isoRefl

||| Fold over all the values of any finite type
finFold : {prf : Finite t} -> (t -> acc -> acc) -> acc -> acc
finFold {prf=(MkFinite Z     (MkIso _ from _ _))} f start = start
finFold {prf=(MkFinite (S n) (MkIso _ from _ _))} f start =
  let elements = map from (range {n=S n}) in
  foldr f start elements

||| Given a finite number of players and their strategies, generate the
||| stream of moves. May not terminate!
play : Finite pl -> (pl -> Strategy pl w t) -> Game w t
play prf str = ?haha -- see README

--This causes indefinite 100% cpu on type checking, but thats another story
{-
data OrdList : (t : Type) -> {rel : t -> t -> Type} -> t -> Type where
  Cell : (x : t) -> OrdList t x
  Cons : {rel : t -> t -> Type} -> (y : t) -> OrdList t x -> x `rel` y -> OrdList t y
-}

||| Dummy world for testing. 3 players
implementation [W] World (Fin 3) where
  Cmd n = Unit
  Que n = (Nat,Nat)
  Ans n (i,j) = Char

