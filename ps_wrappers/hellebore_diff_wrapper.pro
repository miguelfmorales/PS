pro hellebore_diff_wrapper, folder_names, cube_types = cube_types, pols = pols, $
    png = png, eps = eps, $
    kperp_linear_axis = kperp_linear_axis, kpar_linear_axis = kpar_linear_axis
    
    
  if n_elements(folder_names) eq 0 then folder_names = base_path('data') + 'fhd_ps_data/128T_cubes/aug23_3hr_first/'
  
  if n_elements(cube_types) eq 0 then if n_elements(folder_names) eq 1 then cube_types = ['dirty', 'res'] else cube_types = 'res'
  if n_elements(pols) eq 0 then pols = 'xx'
  
  
  info_files = strarr(n_elements(folder_names))
  obs_names = strarr(n_elements(folder_names))
  fhd_types = strarr(n_elements(folder_names))
  
  for i=0, n_elements(folder_names)-1 do begin
    ;; check for folder existence, otherwise look for common folder names to figure out full path. If none found, try base_path('data') + 'fhd_ps_data/128T_cubes/'
    folder_test = file_test(folder_names[i], /directory)
    if folder_test eq 0 then begin
      pos_fhd_data = strpos(folder_names[i], 'fhd_ps_data')
      if pos_fhd_data gt -1 then begin
        test_name = base_path('data') + strmid(folder_names[i], pos_fhd_data)
        folder_test = file_test(test_name, /directory)
        if folder_test eq 1 then folder_names[i] = test_name
      endif
    endif
    if folder_test eq 0 then begin
      pos_fhd_128 = strpos(folder_names[i], '128T_cubes')
      if pos_fhd_128 gt -1 then begin
        test_name = base_path('data') + 'fhd_ps_data/' + strmid(folder_names[i], pos_fhd_128)
        folder_test = file_test(test_names[i], /directory)
        if folder_test eq 1 then folder_names[i] = test_name
      endif
    endif
    if folder_test eq 0 then begin
      test_name = base_path('data') + 'fhd_ps_data/128T_cubes/' + folder_names[i]
      folder_test = file_test(test_name, /directory)
      if folder_test eq 1 then folder_names[i] = test_name
    endif
    
    if folder_test eq 0 then message, 'folder not found'
    
    fhd_types[i] = file_basename(folder_names[i])
    
    info_file = file_search(folder_names[i] + '/Combined_obs_*_info*', count = n_infofile)
    if n_infofile gt 1 then message, 'More than 1 info files found.'
    if n_infofile eq 1 then begin
      info_files[i] = info_file
      
      obs_names[i] = stregex(info_file, '[0-9]+-[0-9]+', /extract)
      obs_range = long(strsplit(obs_names[i], '-', /extract))
    endif else begin
      info_files[i] = file_search(folder_names[i] + '/*info*', count = n_infofile)
      if n_infofile eq 0 then message, 'No info files found for folder: ' + folder_names[i]
      
      obs_name = stregex(info_file, '[0-9]+', /extract)
      obs_range = long(obs_name)
    endelse
    
    ;if n_elements(obs_range) eq 1 then integrated = 0 else if obs_range[1] - obs_range[0] gt 0 then integrated = 1 else integrated = 0
  endfor
  
  if n_elements(folder_names) eq 1 then plot_filebase = fhd_types[0] + '_' + cube_types[0] + '_' + pols[0] + $
    '_minus_' + cube_types[n_elements(cube_types)-1] + '_' + pols[n_elements(pols)-1] $
  else plot_filebase = fhd_types[0] + '_' + cube_types[0] + '_' + pols[0] + $
  '_minus_' + fhd_types[1] + cube_types[n_elements(cube_types)-1] + '_' + pols[n_elements(pols)-1]
  
  
;; save_path specifies a location to save the power spectrum files.
;; This is also where the code looks for intermediate save files to avoid re-running code.
;; If this is parameter is not set, the files will be saved in the same directory as the datafile.
  
std_savepath = base_path('data') + 'fhd_ps_data/'

if n_elements(save_path) gt 0 then begin
  pos = strpos(save_path, std_savepath)
  if pos ne -1 then save_path_ext = strmid(save_path, pos + strlen(std_savepath)) else save_path_ext = ''
endif else begin
  pos = strpos(file_dirname(info_file, /mark_directory), std_savepath)
  if pos ne -1 then save_path_ext = strmid(file_dirname(info_file, /mark_directory), pos + strlen(std_savepath)) $
  else save_path_ext = ''
endelse

;; savefilebase specifies a base name to use for the save files


;; plot_path specifies a location to save plot files.
;; If this parameter is not set, the plots will be saved in the same directory as the datafile.
plot_path = base_path('plots') + 'power_spectrum/fhd_data/' + save_path_ext

if not file_test(plot_path, /directory) then file_mkdir, plot_path

;; plot_filebase specifies a base name to use for the plot files


;; freq_ch_range specifies which frequency channels to include in the power spectrum.
;; Fewer number of channels makes the dfts faster

;; pol_inc specifies which polarizations to generate the power spectra for.

;; cut_image keyword only applies to Healpix datasets. It allows for limiting the field of view in the
;; image plane to match calculated k-modes (centered on image center).
;; Currently defaults to on. Set equal to 0 to turn it off, 1 to turn it on

;; There are 3 refresh flags to indicate that various stages should be re-calculated
;;   (rather than using previous save files if they exist).
;; If an early stage is recalculated, all subsequent stages will also be recalculated
;; The earliest stage is refresh_dft, which is only used for Healpix datasets (it's ignored otherwise)
;; The next stage is refresh_ps and the last stage is refresh_binning.
;; To set any of these flags, set them equal to 1 (true)

;; options for spectral windowing:
;; available window funtions are: ['Hann', 'Hamming', 'Blackman', 'Nutall', 'Blackman-Nutall', 'Blackman-Harris']
;; Default is to use Blackman-Harris, for no spectral windowing set no_spec_window = 1
;; To use another window type use the spec_window_type keyword, eg spec_window_type = 'hann'

;; options for binning:
;; log_kperp, log_kpar and log_k1d are flags: set to 1 (true) for logarithmic bins
;; kperp_bin, kpar_bin and k1d_bin take scalar values to control bin sizes.
;;   (The actual binsize for linear binning and the log binsize for log binning -- bins per decade = 1/binsize)


;; options for plotting:
;; kperp_linear_axis is a flag, set to 1 to use a linear kperp axis (default is log axis)
;; kpar_linear_axis is a flag, set to 1 to use a linear kpar axis (default is log axis)
;; data_range specifies the min & max value of the signal colorbar (values outside that range are clipped to those values)
;; sigma_range, nev_range, snr_range, noise_range, nnr_range control the other colorbar ranges
;; baseline_axis is a flag (defaulted to true) to mark baseline; length along top axis of 2d plots (set to 0 to turn off)
;; delay_axis is a flag (defaulted to true) to mark delay time along right axis of 2d plots (set to 0 to turn off)
;; hinv is a flag (defaulted to true) to use h^-1 Mpc rather than physical Mpc in plot units (set to 0 to turn off)
;; plot_wedge_line is a flag (defaulted to true) to plot a line marking the wedge (both horizon & FoV) (set to 0 to turn off)
;; grey_scale is a flag to use a black/white color scale rather than the default color scale
;; png & eps are flags to make save plots as png or eps files rather than displaying to the screen


ps_difference_plots, info_files, cube_types, pols, $
  plot_path = plot_path, plot_filebase = plot_filebase, save_path = save_path, savefilebase = savefilebase, $
  quiet = quiet, kperp_linear_axis = kperp_linear_axis, kpar_linear_axis = kpar_linear_axis, png = png, eps = eps
  
end