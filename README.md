### Overview
[![CI server](https://github.com/Owen-Foundation/DefenceTest/actions/workflows/server.yaml/badge.svg)](https://github.com/Owen-Foundation/DefenceTest/actions/workflows/server.yaml) [![CI worker posix](https://github.com/Owen-Foundation/DefenceTest/actions/workflows/worker_posix.yaml/badge.svg)](https://github.com/Owen-Foundation/DefenceTest/actions/workflows/worker_posix.yaml) [![CI worker msys2](https://github.com/Owen-Foundation/DefenceTest/actions/workflows/worker_msys2.yaml/badge.svg)](https://github.com/Owen-Foundation/DefenceTest/actions/workflows/worker_msys2.yaml) [![CI lint](https://github.com/Owen-Foundation/DefenceTest/actions/workflows/lint.yaml/badge.svg)](https://github.com/Owen-Foundation/DefenceTest/actions/workflows/lint.yaml)

DefenceTest is a distributed task queue for testing chess engines. The main instance
for testing the chess engine [Owen](https://github.com/Owen-Foundation/Owen) is at this web page https://github.com/Owen-Foundation/DefenceTest

Developers submit patches with new ideas and improvements, CPU contributors install a defencetest worker on their computers to play some chess games in the background to help the developers testing the patches.

The defencetest worker:
- Automatically connects to the server to download a chess opening book, the [fastchess](https://github.com/Disservin/fastchess) chess game manager sources and the chess engine sources (both for the current Owen and for the patch with the new idea). The sources will be compiled according to the type of the worker platform.
- Starts a batch of games using fastchess.
- Uploads the games results on the server.

The defencetest server:
- Manages the queue of the tests with customizable priorities.
- Computes several probabilistic values from the game results sent by the workers.
- Updates and publishes the results of ongoing tests.
- Knows how to stop tests when they are statistically significant and publishes the final tests results.

To get more information, such as the worker/server install and configuration instructions, visit the [DefenceTest Wiki](https://github.com/Owen-Foundation/DefenceTest/wiki).
