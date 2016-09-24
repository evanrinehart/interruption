I made a game-like model of a running program as two "players", and structured
the communication between them using dependent types (rather than deciding on a
single js-like type for messages).

There are two players, A and B. Either one can represent a program while the
other represents the computer or a human user.

The rules are, each player is asked to decide on a move to do in the future and
when. the decision is based on the history of moves so far, but not on the
other players planned move, which is hidden.

Each can plan to "tell" a command, "resign" which ends the game, or "ask" a
question which the other player has to answer.

Whoever decides the prior time has his move recorded (potentially getting an
answer to a question in the process). and both players must recalculate their
plan using the latest history.

The player who lost the race potentially changes his mind about what to do next.

Players can tie, and both actions are recorded.

Given a (computable, total) strategy for choosing your next moves and a way to
answer questions, and these rules, this generates a stream of moves that may
not terminate. the system is turing complete because you can implement a
universal turing machine as one of the players.

The idea is that each player acts like a freely running concurrent process who
acts independently of the other, but can be interrupted at any time.

But this is expressed totally in the abstract, the stream can be simulated as
fast or as slow as you want.

You can use this as a semantics of I/O, if two programs generate the same
stream in the same environment (other player) you could say they are equivalent
programs.

