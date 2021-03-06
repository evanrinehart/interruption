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

||| When you look at the move list, you'll see the game is in a certain "state".
data GameView : Type where
  PlayersMove : GameView
  TriedToPlayWithoutMinimumBet : (bet : Nat) -> GameView
  PlayerReady : Deck -> GameView
  Dealing : (step : Fin 4) -> Deck -> GameView
  PlayerBlackjacked : (bet : Nat) -> GameView
  WantsHit : Deck -> GameView
  WantsInvalidPlay : GameView
  IWillHit : Deck -> GameView
  IWillStand : (myScore : Nat) -> (playerScore : Nat) -> (bet : Nat) -> GameView
  PlayerOver21 : GameView
  DealerOver21 : GameView
  PlayerBusted : GameView
  IBusted : (bet : Nat) -> GameView

||| Fold over a history to get its current game view
gameView : History Blackjack Nat -> GameView
gameView hist = ?viewAlg

||| How the dealer works. Player's strategy is up to you!
dealerStrategy : Strategy Players Blackjack Nat Dealer
dealerStrategy = MkStrategy decide answer where
  act : Nat -> DealerCmd -> Action Dealer Nat
  act t' = TellAt {w=Blackjack} Dealer t'
  maxT : History w Nat -> Nat
  maxT hist = foldr max 0 (map fst hist)
  decide history =
    let tmax = maxT history in
    let t = tmax + 1 in
    case gameView history of
      PlayersMove                        => Wait
      TriedToPlayWithoutMinimumBet bet   => act t (Complain "minimum $5")
      PlayerReady deck                   => act t (Reshuffle deck)
      Dealing FZ                (d::eck) => act t (Deal Player d FaceUp)
      Dealing (FS FZ)           (d::eck) => act t (Deal Player d FaceUp)
      Dealing (FS (FS FZ))      (d::eck) => act t (Deal Dealer d FaceDown)
      Dealing (FS (FS (FS FZ))) (d::eck) => act t (Deal Dealer d FaceUp)
      Dealing _                 []       => ResignAt t
      Dealing (FS (FS (FS (FS FZ)))) _   impossible -- annoying
      PlayerBlackjacked bet              => act t (PayPlayer bet)
      WantsHit (d::eck)                  => act t (Deal Player d FaceUp)
      WantsHit []                        => ResignAt t
      WantsInvalidPlay                   => act t (Complain "you can't do that")
      IWillHit (d::eck)                  => act t (Deal Dealer d FaceUp)
      IWillHit []                        => ResignAt t
      IWillStand dscore pscore bet       => act t $ case compare dscore pscore of
        LT => PayPlayer bet
        EQ => Push
        GT => TakeMoney
      PlayerOver21 => act t BustPlayer
      DealerOver21 => act t BustDealer
      PlayerBusted => act t TakeMoney
      IBusted bet  => act t (PayPlayer bet)
  answer _ t WhatTimeIsIt = Nothing
