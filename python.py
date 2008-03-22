# Begin ~/.python.py

import sys, os, time

# Use interactive prompt and debugging.

try:
  import rlcompleter2
except ImportError: pass
else:
  rlcompleter2.setup ()
  del rlcompleter2

# End ~/.pythonrc.py
