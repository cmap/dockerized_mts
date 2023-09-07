#!/usr/bin/env bash
#setup environment
source activate prism

cd /cmap/merino/
python setup.py develop

#return to /
cd /

python /clue/bin/pivot.py "$@"

exit_code=$?
conda deactivate
exit $exit_code
