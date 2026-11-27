"""Export DCS World terrain data from the game install as standard GIS files."""

import os

# numpy's OpenBLAS commits buffers for one thread per CPU in every process it
# loads in, about 0.75 GB per process with 24 CPUs, and the export runs one
# worker process per CPU. Nothing here needs threaded linear algebra. This runs
# before numpy loads, in the main process and in each worker.
os.environ.setdefault("OPENBLAS_NUM_THREADS", "1")
