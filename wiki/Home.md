# DefenceTest

Open distributed testing framework for the [Owen chess engine](https://github.com/Owen-Foundation/Owen).
Volunteers run workers that play test games on their own machines; the server
aggregates results into Elo and SPRT statistics. GPL-3.0.

- **Test server:** see the [Owen homepage](https://owen.hsrprojects.org) Testing section for the current host
- **Engine:** https://github.com/Owen-Foundation/Owen
- **Opening books:** https://github.com/Owen-Foundation/books
- **Support:** https://github.com/Owen-Foundation/DefenceTest/issues

## For volunteers

1. Create an account on the test server (`/signup`) — approved instantly after
   solving the slider-puzzle captcha.
2. Clone the framework: `git clone https://github.com/Owen-Foundation/DefenceTest.git`
3. You need Python 3.8+, a C++ compiler, `make` and `cmake`
   (Ubuntu: `sudo apt install build-essential cmake`;
   macOS: `xcode-select --install`; Windows: msys2/mingw-w64 or LLVM).
4. Run, with YOUR account and the server's host:
   `python worker/worker.py USERNAME PASSWORD --host <server-host> --port 443`
5. Leave it running. Games are fetched, played and submitted automatically —
   your name appears on Contributors (refreshed every 15 minutes). For 24/7
   runs see `worker/daemon/`.

Full command list: [[Commands]].

## For developers

See [[Creating my first test|Creating-my-first-test]]: open `/tests/run`,
fill base vs patch, pick the `owen200.epd` book, paste your `bench 6` node
counts as signatures, submit. Runs by approvers — and by anyone with 500+
contributed games — start immediately; first-time authors wait for one
manual approval.

## How results work

See [[DefenceTest mathematics|DefenceTest-mathematics]] for SPRT bounds,
Elo estimation and the pentanomial model.
