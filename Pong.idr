module Pong

import Game
import Data.Vect

||| There is a machine and the player(s).
data Players = Player | Machine

||| Two heavy duty potentiometers
data Pot = Pot1 | Pot2

||| Players can insert coins and adjust the trajectory of either pot.
data PlayerCmd : Type where
  InsertCoin : PlayerCmd
  Control : Pot -> List Double -> PlayerCmd

||| The machine spontaneously emits sound effects.
data MachineCmd : Type where
  Sound : Int -> MachineCmd

||| You can look at the CRT screen at any time.
data MachineQue = Look

||| Idealized black and white image
Picture : Type
Picture = Double -> Double -> Bool

implementation [Pong] World' Players where
  Cmd Player       = PlayerCmd
  Cmd Machine      = MachineCmd
  Que Player       = Void
  Que Machine      = MachineQue
  Ans Player x     = void x
  Ans Machine Look = Picture

data SoundView : Type where
  DemoMode : SoundView
  ActiveMode : Double -> Int -> SoundView

||| Fold over history (of sound effects heh!) to calculate the time of
||| next sound effect, if any.
soundView : History Pong Double -> SoundView
soundView hist = ?soundView

R2 : Type
R2 = (Double,Double)

record GameView where
  constructor MkGameView
  ball : R2
  bat1y : Double
  bat2y : Double
  score1 : Nat
  score2 : Nat

||| Fold over history then interpolate to get positions and scores
gameView : History Pong Double -> Double -> GameView
gameView hist t = ?gameView

||| Display the objects as an image
render : GameView -> Picture
render _ x y = ?render

pong : Strategy Players Pong Double Machine
pong = MkStrategy decide answer where
  decide hist = case soundView hist of
    DemoMode => Wait -- demo mode has no sound
    ActiveMode t soundNum => TellAt {w=Pong} Machine t (Sound soundNum)
  answer hist t Look = render (gameView hist t)
