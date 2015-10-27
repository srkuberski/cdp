#!/bin/sh

	# arguments
INDIR="../../data/cdd/raw/"
OUTDIR="../../data/cdd/convert/"

IDS="setdiff( [1:40], 11 )" # 11: two recordings

LOGFILE="${OUTDIR}/${IDS}.log"

	# workload
MATLAB="matlab -nosplash -nodesktop -r"

$MATLAB "proc.convert( '$INDIR', '$OUTDIR', $IDS, '$LOGFILE' ); exit();" &

wait
