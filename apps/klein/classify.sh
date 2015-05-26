#!/bin/sh

	# data directories
INDIR='../../data/klein/features/'
OUTDIR='../../data/klein/classify/'
TRAINDIR='../../data/klein/train/'

	# spread workload
IDS='[16, 17]'
IDS='11:20'
SEEDS='1:10'

matlab -nosplash -nodesktop -r "classify( '$INDIR', '$OUTDIR', $IDS, '$TRAINDIR', $SEEDS); exit();" &

wait
