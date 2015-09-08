function label( indir, outdir, ids, trialstarts )
% label data
%
% LABEL( indir, outdir, ids, trialstarts=ones )
% 
% INPUT
% indir : input directory (row char)
% outdir : output directory (row char)
% ids : subject identifiers (row numeric)
% trialstarts : trial identifiers to start with (row numeric)

		% safeguard
	if nargin < 1 || ~isrow( indir ) || ~ischar( indir )
		error( 'invalid argument: indir' );
	end

	if nargin < 2 || ~isrow( outdir ) || ~ischar( outdir )
		error( 'invalid argument: outdir' );
	end

	if nargin < 3 || ~isrow( ids ) || ~isnumeric( ids )
		error( 'invalid argument: ids' );
	end

	if nargin < 4
		trialstarts = ones( numel( ids ), 1 );
	end
	if ~isrow( trialstarts ) || ~isnumeric( trialstarts ) || numel( trialstarts ) ~= numel( ids )
		error( 'invalid argument: trialstarts' );
	end

		% prepare directories
	if exist( indir, 'dir' ) ~= 7
		error( 'invalid argument: indir' );
	end

	if exist( outdir, 'dir' ) ~= 7
		mkdir( outdir );
	end

		% initialize framework
	addpath( '../../cdf/' );

	logger = xis.hLogger.instance( fullfile( outdir, sprintf( 'label_%d-%d.log', min( ids ), max( ids ) ) ) );
	logger.tab( 'label data...' );

	cfg = cdf.hConfig(); % formant config

	cfg.lab_freqband = [0, 2000];
	cfg.lab_nfreqs = 200;

		% proceed subject identifiers
	ci = 0;
	for i = ids
		ci = ci + 1;
		logger.tab( 'subject: %d', i );

			% read input data
		cdffile = fullfile( indir, sprintf( 'run_%d.mat', i ) );
		if exist( cdffile, 'file' ) ~= 2
			logger.untab( 'skipping...' );
			continue;
		end

		logger.log( 'read cdf data (''%s'')...', cdffile );
		load( cdffile, 'run' );

		read_audio( run, run.audiofile, true );

			% label data
		cdf.label( run, cfg, trialstarts(ci) );

			% write output data
		run.audiodata = []; % do not write redundant audio data

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

