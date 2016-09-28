module Blackjack

import Data.Fin
import Game 

||| There are two players.
data Players = Dealer | Player

||| A standard card type.
data Card : Type where
  MkCard : Fin 4 -> Fin 13 -> Card
  Joker1 : Card
  Joker2 : Card
  EatAtJoe's : Card

||| 5 things a player can do after the round starts.
data Play = Hit | Stand | DoubleDown | Split | Insurance
  
||| All things the player can do, though not all will be valid at all times.
data PlayerCmd : Type where
  Bet : Nat -> PlayerCmd
  Ready : PlayerCmd
  MakePlay : Play -> PlayerCmd

||| How to deal a card
data Face = FaceUp | FaceDown

||| All the things the dealer can do. His AI will not do anything invalid
||| unless there are bugs.
data DealerCmd : Type where
  Deal : Players -> Card -> Face -> DealerCmd
  HitDealer : Card -> DealerCmd
  HitPlayer : Card -> DealerCmd
  StandDealer : DealerCmd
  BustDealer : DealerCmd
  BustPlayer : DealerCmd
  Push : DealerCmd
  PayPlayer : Nat -> DealerCmd
  TakeMoney : DealerCmd
  Reshuffle : List Card -> DealerCmd
  Complain : String -> DealerCmd

||| You may ask the dealer this question at any time.
data DealerQue = WhatTimeIsIt

||| The blackjack "world", see README and Game.idr
implementation [Blackjack] World' Players where
  Cmd Dealer = DealerCmd
  Cmd Player = PlayerCmd
  Que Dealer = DealerQue
  Que Player = Void
  Ans Dealer WhatTimeIsIt = Maybe (Fin 24, Fin 60)
  Ans Player _ = Void

Deck : Type
Deck = List Card

||| When you look at the move list, you'll see the game is in a certain state.
data PlayState : Type where
  PlayersMove : PlayState
  TriedToPlayWithoutMinimumBet : (bet : Nat) -> PlayState
  PlayerReady : Deck -> PlayState
  Dealing : (step : Fin 4) -> Deck -> PlayState
  PlayerBlackjacked : (bet : Nat) -> PlayState
  WantsHit : Deck -> PlayState
  WantsStand : PlayState
  WantsInvalidPlay : PlayState
  IWillHit : Deck -> PlayState
  IWillStand : (myScore : Nat) -> (playerScore : Nat) -> (bet : Nat) -> PlayState
  IBusted : (bet : Nat) -> PlayState
  PlayerOver21 : PlayState
  DealerOver21 : PlayState
  PlayerBusted : PlayState

postulate
stateOf : History w t -> PlayState

maxT : Ord t => History w t -> t
maxT _ = ?hmm

act : Nat -> DealerCmd -> Action Dealer Nat
act t' = TellAt {w=Blackjack} Dealer t'

||| How the dealer works.
dealerStrategy : Strategy Players Blackjack Nat Dealer
dealerStrategy = MkStrategy decide answer where
  decide history =
    let tmax = maxT history in
    let t = tmax + 1 in
    case stateOf history of
      PlayersMove                        => Wait
      TriedToPlayWithoutMinimumBet bet   => act t (Complain "minimum $5")
      PlayerReady deck                   => act t (Reshuffle deck)
      Dealing FZ                (d::eck) => act t (Deal Player d FaceUp)
      Dealing (FS FZ)           (d::eck) => act t (Deal Player d FaceUp)
      Dealing (FS (FS FZ))      (d::eck) => act t (Deal Dealer d FaceDown)
      Dealing (FS (FS (FS FZ))) (d::eck) => act t (Deal Dealer d FaceUp)
      PlayerBlackjacked bet              => act t (PayPlayer bet)
      WantsHit (d::eck)                  => act t (Deal Player d FaceUp)
      WantsInvalidPlay                   => act t (Complain "you can't do that")
      IWillHit (d::eck)                  => act t (Deal Dealer d FaceUp)
      IWillStand dscore pscore bet       => act t
        (case compare dscore pscore of
          LT => PayPlayer bet
          EQ => Push
          GT => TakeMoney)
      PlayerOver21 => act t BustPlayer
      DealerOver21 => act t BustDealer
      IBusted bet  => act t (PayPlayer bet)
      PlayerBusted => act t TakeMoney
  answer _ WhatTimeIsIt = Nothing
