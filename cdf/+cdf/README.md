Framework configuration
-----------------------

##### Marker synchronization

- `hConfig.sync_range`
	- search range relative to expected marker position (seconds)
	- default: `[NaN, NaN]`, Klein: `[-0.125, 0.025]`
- `hConfig.sync_smooth`
	- waveform smoothing (seconds)
	- default: `NaN`, Klein: `0.002`
- `hConfig.sync_thresh`
	- Mahalanobis distance threshold (number of sigmas)
	- default: `NaN`, Klein: `3.0`

##### Voice activity detection

- `hConfig.vad_freqband` -- TODO
- `hConfig.vad_nfreqs` -- TODO
- `hConfig.vad_minlen` -- TODO
- `hConfig.vad_maxdist` -- TODO
- `hConfig.vad_maxgap` -- TODO
- `hConfig.vad_maxdet` -- TODO

##### Landmarks detection

- `hConfig.lmd_freqband` -- TODO
- `hConfig.lmd_nfreqs` -- TODO

Experimental run
----------------

Experimental trial
------------------

Subject response
----------------
