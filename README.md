# Interruption

This game is usually played with 2 or more players. But you need at least 1.

Before the game starts define for each player a type of commands, a type of
questions, and for each question of each player a type of answers.

Each round all players are asked to choose an action. When the round is over
one or more players will append their moves to a move list. The move list
begins empty prior to the first round. Players may review the move list to
make the choice, but they can't know what the other players have chosen during
the current round.

The possible action choices are:
- Issue a command at some time in the future
- Ask a question at some time in the future
- Resign at some time in the future
- Wait for someone else to make a move

Once all players have committed to an action the round is resolved with an
algorithm.

If all players chose to wait then the game ends in a deadlock.

Otherwise the action time of all choices (other than choices to wait) are
compared to find the minimum time. All choices with time greater than the
minimum are discarded, along with any choices to wait.

The remaining actions are appended as a move entry to the move list. If any
actions were to ask someone a question, then the target player must answer
and the answer is also recorded with the question in the entry. The entry also
contains the minimum time calculated earlier.

If any of the players chose to resign, then the game ends.

Otherwise the next round begins by repeating the action choices and choice
resolution process.
