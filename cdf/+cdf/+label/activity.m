function label_activity( run, cfg )
% activity labeling tool
%
% LABEL_ACTIVITY( run, cfg )
% 
% INPUT
% run : cue-distractor run (scalar object)
% cfg : framework configuration (scalar object)

		% safeguard
	if nargin < 1 || ~isscalar( run ) || ~isa( run, 'cdf.hRun' ) % cue-distractor run
		error( 'invalid argument: run' );
	end

	if nargin < 2 || ~isscalar( cfg ) || ~isa( cfg, 'cdf.hConfig' ) % framework configuration
		error( 'invalid argument: cfg' );
	end

		% init
	logger = xis.hLogger.instance(); % start logging
	logger.tab( 'activity labeling tool...' );

	style = xis.hStyle.instance(); % prepare interactive figure

	fig = style.figure( 'Visible', 'on' );
	figcol = get( fig, 'Color' );

	set( fig, 'WindowKeyPressFcn', {@fig_dispatch, 'keypress'} );
	set( fig, 'CloseRequestFcn', {@fig_dispatch, 'close'} );

		% helper functions
	function f = is_valid( trials )
		f = true( size( trials ) );
		for i = 1:numel( trials )
			if any( isnan( trials(i).range ) )
				f(i) = false;
			end
		end
	end

	function f = is_labeled( trials )
		f = true( size( trials ) );
		for i = 1:numel( trials )
			if isempty( trials(i).resplab.label ) || any( isnan( trials(i).resplab.range ) )
				f(i) = false;
			end
		end
	end

	function i = next_unlabeled( trials, i )
		inext = find( ~is_labeled( trials(i+1:end) ), 1 );
		if ~isempty( inext )
			i = i + inext;
		end
	end

	function i = snap( ts, t0, i, align )
		if align

			zc = sign( ts ); % find zero crossings
			zc(zc == 0) = 1;
			zc = abs( diff( zc ) / 2 );
			zc = find( zc == 1 );

			if isempty( zc )
				return;
			end

			is = dsp.sec2smp( i - t0, run.audiorate ) + 1; % choose nearest
			d = zc - is;
			d = d(find( abs( d ) == min( abs( d ) ), 1 )) + 1;
			i = dsp.smp2sec( is + d - 1, run.audiorate ) + t0;

		end
	end

	function ts = scale( ts, flog )
		if flog
			ts = mag2db( abs( ts ) + eps );
		end
	end

	function plot_activity( trial, yl )
		plot( (trial.resplab.range(1) * [1, 1] - trial.range(1)) * 1000, yl, ...
			'ButtonDownFcn', {@fig_dispatch, 'buttondown'}, ...
			'Color', style.color( 'signal', +1 ) );
		plot( (trial.resplab.range(2) * [1, 1] - trial.range(1)) * 1000, yl, ...
			'ButtonDownFcn', {@fig_dispatch, 'buttondown'}, ...
			'Color', style.color( 'signal', +1 ) );
	end

		% event dispatching
	function fig_dispatch( src, event, type )
		switch type

				% key presses
			case 'keypress'
				nmods = size( event.Modifier, 2 );

				switch event.Key

					case 'space' % browsing
						if nmods == 0
							itrial = next_unlabeled( trials, itrial );
							fig_update();
						end

					case 'pagedown'
						if nmods < 2 && itrial ~= ntrials
							step = 1;
							if strcmp( event.Modifier, 'shift' )
								step = 10;
							elseif strcmp( event.Modifier, 'control' )
								step = 100;
							end
							itrial = min( itrial + step, ntrials );
							fig_update();
						end
					case 'pageup'
						if nmods < 2 && itrial ~= 1
							step = 1;
							if strcmp( event.Modifier, 'shift' )
								step = 10;
							elseif strcmp( event.Modifier, 'control' )
								step = 100;
							end
							itrial = max( itrial - step, 1 );
							fig_update();
						end

					case 'home'
						if nmods == 0 && itrial ~= 1
							itrial = 1;
							fig_update();
						end
					case 'end'
						if nmods == 0 && itrial ~= ntrials
							itrial = ntrials;
							fig_update();
						end

					case 'return' % playback
						if nmods == 0
							soundsc( ovrts, run.audiorate );
						elseif nmods == 1 && strcmp( event.Modifier, 'shift' ) && fresp
							soundsc( respts, run.audiorate );
						end

					case 'd' % decibel scale
						if nmods == 0
							flog = ~flog;
							fig_update();
						end

					case 'k' % class setting
						if nmods == 0
							trial.resplab.label = 'ka';
							fig_update();
						end
					case 't'
						if nmods == 0
							trial.resplab.label = 'ta';
							fig_update();
						end

					case 'backspace' % clearing
						if nmods == 1 && strcmp( event.Modifier, 'control' ) % clear trial
							resplab.label = '';
							resplab.range = [NaN, NaN];
							fig_update();
						elseif nmods == 3 && any( strcmp( event.Modifier, 'shift' ) ) ... % clear run (valids only)
								&& any( strcmp( event.Modifier, 'control' ) )  && any( strcmp( event.Modifier, 'alt' ) )
							for i = 1:ntrials
								trials(i).resplab.label = '';
								trials(i).resplab.range = [NaN, NaN];
							end
							itrial = 1;
							fig_update();
						end

					case 'escape' % quit
						if nmods == 0
							fdone = true;
							fig_update();
						end
				end

				% button presses
			case 'buttondown'
				while ~strcmp( get( src, 'Type' ), 'axes' ) % get parent axis
					src = get( src, 'Parent' );
				end

				cp = trial.range(1) + get( src, 'CurrentPoint' ) / 1000; % activity setting
				switch get( fig, 'SelectionType' )
					case 'normal'
						if cp(1) >= trial.range(1) && cp(2) <= trial.range(2)
							resplab.range(1) = snap( ovrts, trial.range(1), cp(1), cfg.lab_activity_zcsnap(1) );
							fig_update();
						end
					case 'alt'
						if cp(1) >= trial.range(1) && cp(2) <= trial.range(2)
							resplab.range(2) = snap( ovrts, trial.range(1), cp(1), cfg.lab_activity_zcsnap(2) );
							fig_update();
						end
				end

				% figure closing
			case 'close'
				fdone = true;
				delete( fig );
		end
	end

	function fig_update()
		switch get( fig, 'Clipping' ) % flip (unused) clipping property
			case 'on'
				set( fig, 'Clipping', 'off' );
			case 'off'
				set( fig, 'Clipping', 'on' );
		end
	end

		% interaction loop
	trials = [run.trials]; % prepare valid trials
	itrials = 1:numel( trials );

	invalids = ~is_valid( trials );
	trials(invalids) = [];
	itrials(invalids) = [];

	ntrials = numel( trials );
	logger.log( 'valid trials: %d', ntrials );
	logger.log( 'unlabeled trials: %d', sum( ~is_labeled( trials ) ) );

	if ntrials == 0
		error( 'invalid value: ntrials' );
	end

	itrial = max( 1, next_unlabeled( trials, 0 ) );

	fdone = false; % init flags
	flog = false;

	while ~fdone

			% prepare data
		trial = trials(itrial);
		resplab = trial.resplab;

		ovrr = dsp.sec2smp( trial.range, run.audiorate ) + [1, 0]; % ranges

		respr = dsp.sec2smp( resplab.range, run.audiorate ) + [1, 0];
		fresp = ~any( isnan( respr ) );

		det1r = dsp.sec2smp( resplab.range(1) + cfg.lab_activity_det1, run.audiorate ) + [1, 0];
		det1r(det1r < 1) = 1;
		det1r(det1r > size( run.audiodata, 1 )) = size( run.audiodata, 1 );
		fdet1 = ~any( isnan( det1r ) );

		det2r = dsp.sec2smp( resplab.range(2) + cfg.lab_activity_det2, run.audiorate ) + [1, 0];
		det2r(det2r < 1) = 1;
		det2r(det2r > size( run.audiodata, 1 )) = size( run.audiodata, 1 );
		fdet2 = ~any( isnan( det2r ) );

		ovrts = run.audiodata(ovrr(1):ovrr(2), 1); % signals
		dc = mean( ovrts );
		ovrts = ovrts - dc;

		respts = [];
		if fresp
			respts = run.audiodata(respr(1):respr(2), 1) - dc;
		end

		det1ts = [];
		if fdet1
			det1ts = run.audiodata(det1r(1):det1r(2), 1) - dc;
		end

		det2ts = [];
		if fdet2
			det2ts = run.audiodata(det2r(1):det2r(2), 1) - dc;
		end

		if ~flog % axes
			yl = max( abs( ovrts ) ) * [-1, 1] * style.scale( 1/2 );
		else
			yl = [min( scale( ovrts, flog ) ), max( scale( ovrts, flog ) )];
			yl(2) = yl(1) + diff( yl ) * (1 + (style.scale( 1/2 ) - 1) / 2);
		end

			% plot
		clf( fig );

		set( fig, 'Color', figcol );
		if ~is_labeled( trial )
			set( fig, 'Color', style.color( 'signal', +2 ) );
		end

		hovr = subplot( 4, 2, [1, 2], 'ButtonDownFcn', {@fig_dispatch, 'buttondown'} ); % overview
		title( sprintf( 'LABEL_ACTIVITY (trial: #%d [%d/%d])', itrials(itrial), itrial, ntrials ) );
		xlabel( 'trial time in milliseconds' );
		ylabel( 'activity' );

		xlim( (trial.range - trial.range(1)) * 1000 );
		ylim( yl );

		plot_activity( trial, yl ); % activity

		stairs( ... % signal
			(dsp.smp2sec( (ovrr(1):ovrr(2)+1) - 1, run.audiorate ) - trial.range(1)) * 1000, ...
			scale( [ovrts; ovrts(end)], flog ), ...
			'ButtonDownFcn', {@fig_dispatch, 'buttondown'}, ...
			'Color', style.color( 'cold', -1 ) );

		hdet1 = NaN; % detail #1 (activity start)
		if fdet1
			hdet1 = subplot( 4, 2, [3, 5], 'ButtonDownFcn', {@fig_dispatch, 'buttondown'} );
			xlabel( 'trial time in milliseconds' );
			ylabel( 'start detail' );

			xlim( (resplab.range(1) + cfg.lab_activity_det1 - trial.range(1)) * 1000 );
			ylim( yl );

			plot_activity( trial, yl ); % activity

			stairs( ... % signal
				(dsp.smp2sec( (det1r(1):det1r(2)+1) - 1, run.audiorate ) - trial.range(1)) * 1000, ...
				scale( [det1ts; det1ts(end)], flog ), ...
				'ButtonDownFcn', {@fig_dispatch, 'buttondown'}, ...
				'Color', style.color( 'cold', -1 ) );
		end

		hdet2 = NaN; % detail #2 (activity stop)
		if fdet2
			hdet2 = subplot( 4, 2, [4, 6], 'ButtonDownFcn', {@fig_dispatch, 'buttondown'} );
			xlabel( 'trial time in milliseconds' );
			ylabel( 'stop detail' );

			xlim( (resplab.range(2) + cfg.lab_activity_det2 - trial.range(1)) * 1000 );
			ylim( yl );

			plot_activity( trial, yl ); % activity

			stairs( ... % signal
				(dsp.smp2sec( (det2r(1):det2r(2)+1) - 1, run.audiorate ) - trial.range(1)) * 1000, ...
				scale( [det2ts; det2ts(end)], flog ), ...
				'ButtonDownFcn', {@fig_dispatch, 'buttondown'}, ...
				'Color', style.color( 'cold', -1 ) );
		end

		cdf.audit.plot_info( trial, false ); % label info and commands
		cdf.label.plot_cmds( 'activity' );

			% wait for figure update
		waitfor( fig, 'Clipping' ); % wait for (unused) clipping property change

	end

		% logging
	logger.log( 'unlabeled trials: %d', sum( ~is_labeled( trials ) ) );

		% exit
	if ishandle( fig )
		delete( fig );
	end

	logger.untab(); % stop logging

end

