function convert( indir, outdir, ids )
% raw conversion
%
% CONVERT( indir, outdir, ids )
%
% INPUT
% indir : input directory (row char)
% outdir : output directory (row char)
% ids : subject identifiers (row numeric)

		% safeguard
	if nargin < 1 || ~isrow( indir ) || ~ischar( indir ) || exist( indir, 'dir' ) ~= 7
		error( 'invalid argument: indir' );
	end

	if nargin < 2 || ~isrow( outdir ) || ~ischar( outdir )
		error( 'invalid argument: outdir' );
	elseif exist( outdir, 'dir' ) ~= 7
		mkdir( outdir );
	end

	if nargin < 3 || ~isrow( ids ) || ~isnumeric( ids )
		error( 'invalid argument: ids' );
	end

		% initialize framework
	addpath( '../../cdf/' );

	stamp = datestr( now(), 'yymmdd-HHMMSS-FFF' );
	logfile = fullfile( outdir, sprintf( '%s.log', stamp ) );

	logger = xis.hLogger.instance( logfile );
	logger.tab( 'raw conversion...' );

		% proceed subjects
	for i = ids
		logger.tab( 'subject: %d', i );

			% read raw data
		run = cdf.hRun();

		audiofile = fullfile( indir, sprintf( 'participant_%d_1.wav', i ) );
		trialfile = fullfile( indir, sprintf( 'participant_%d.txt', i ) );
		labelfile = fullfile( indir, sprintf( 'participant_%d.xlsx', i ) );

		if exist( audiofile, 'file' ) ~= 2 || exist( trialfile, 'file' ) ~= 2 || exist( labelfile, 'file' ) ~= 2
			logger.untab( 'skipping...' );
			continue;
		end

		proc.read_audio( run, audiofile, false );
		proc.read_trials( run, trialfile );
		proc.read_labels( run, labelfile );

			% write cdf data
		run.audiodata = []; % do ot write redundant audio data

		cdffile = fullfile( outdir, sprintf( 'run_%d.mat', i ) );
		logger.log( 'write cdf data (''%s'')...', cdffile );
		save( cdffile, 'run' );

			% clean up
		delete( run );

		logger.untab();
	end

		% done
	logger.untab( 'done' );

end

