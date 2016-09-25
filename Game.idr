module Game

%hide World
%default total

data Player = PlA | PlB

record World where
  constructor MkWorld
  T : Type
  C : Player -> Type
  Q : Player -> Type
  A : (p : Player) -> Q p -> Type

data Action : Player -> World -> Type where
  Tell : {w : World} -> {p : Player} -> C w p -> Action p w
  Ask : {w : World} -> {p : Player} -> Q w p -> Action p w
  Resign : Action p w

data Move : World -> Type where
  Push : {w : World} -> (p : Player) -> C w p -> Move w
  Pull : {w : World} -> (p : Player) -> (q : Q w p) -> A w p q -> Move w
  EndGame : Player -> Move w

codata FullHistory : World -> Type where
  FNil : FullHistory w
  FOne : {w : World} -> T w -> Move w -> FullHistory w -> FullHistory w
  FTwo : {w : World} -> T w -> Move w -> Move w -> FullHistory w -> FullHistory w

data History : World -> Type where
  Nil : History w
  One : {w : World} -> T w -> Move w -> History w -> History w
  Two : {w : World} -> T w -> Move w -> Move w -> History w -> History w

record Game (w : World) where
  constructor MkGame
  strategyA : History w -> (T w, Action PlA w)
  strategyB : History w -> (T w, Action PlB w)
  answersA : History w -> (q : Q w PlB) -> A w PlB q
  answersB : History w -> (q : Q w PlA) -> A w PlA q
  
mutual
  go : Ord (T w) => Game w -> (T w, Action PlA w) -> (T w, Action PlB w) -> History w -> FullHistory w
  go g (t1,a1) (t2,a2) h = case compare t1 t2 of
    LT => make1Move g t1 PlA a1 h
    EQ => make2Moves g t1 a1 a2 h
    GT => make1Move g t2 PlB a2 h

  makeMove : Game w -> (p : Player) -> Action p w -> History w -> Move w
  makeMove g@(MkGame {w} strA strB ansA ansB) p a h = case a of
    Tell c => Push p c
    Ask q =>
      let answer = case p of
                        PlA => ansB h q
                        PlB => ansA h q in
      Pull p q answer
    Resign => EndGame p

  make1Move : Ord (T w) => Game w -> T w -> (p : Player) -> Action p w -> History w -> FullHistory w
  make1Move g@(MkGame {w} strA strB ansA ansB) t p a h =
    let m = makeMove g p a h in
    let h' = One t m h in
    case m of
      EndGame _ => FOne t m FNil
      _ =>
        let nextA = strA h' in
        let nextB = strB h' in
        FOne t m (go g nextA nextB h')

  make2Moves : Ord (T w) => Game w -> T w -> Action PlA w -> Action PlB w -> History w -> FullHistory w
  make2Moves g@(MkGame {w} strA strB ansA ansB) t a1 a2 h =
    let m1 = makeMove g PlA a1 h in
    let m2 = makeMove g PlB a2 h in
    let h' = Two t m1 m2 h in
    case (m1,m2) of
      (EndGame _, _) => FTwo t m1 m2 FNil
      (_, EndGame _) => FTwo t m1 m2 FNil
      _ =>
        let nextA = strA h' in
        let nextB = strB h' in
        FTwo t m1 m2 (go g nextA nextB h')

play : Ord (T w) => Game w -> FullHistory w
play g = go g (strategyA g Nil) (strategyB g Nil) Nil


