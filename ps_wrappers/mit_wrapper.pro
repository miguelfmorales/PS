pro mit_wrapper, folder_name, obs_name, n_obs=n_obs, rts = rts, refresh_dft = refresh_dft, refresh_ps = refresh_ps, $
    refresh_binning = refresh_binning, refresh_info = refresh_info, refresh_beam = refresh_beam, pol_inc = pol_inc, no_spec_window = no_spec_window, $
    spec_window_type = spec_window_type, sim = sim, freq_ch_range = freq_ch_range, individual_plots = individual_plots, $
    png = png, eps = eps, plot_slices = plot_slices, slice_type = slice_type, delta_uv_lambda = delta_uv_lambda, cut_image = cut_image, $
    kperp_linear_axis = kperp_linear_axis, kpar_linear_axis = kpar_linear_axis, set_data_ranges = set_data_ranges
    
  ;; The only required input is the datafile name (including the full path)
    
  if n_elements(n_obs) gt 0 then print,'n_obs='+number_formatter(n_obs) else print,'n_obs not defined!'
  
  if keyword_set(rts) then begin
    froot = '/data3/MWA/bpindor/RTS/dec_11/'
    
    ;     data_dir = froot + 'BdaggerV/'
    data_dir = froot + ['PSF0_0/','PSF0_1/']
    
    ;     weights_dir = froot + 'Bdagger1/'
    weights_dir = froot + ['PSF1_0/','PSF1_1/']
    
    ;     variance_dir = froot + 'BdaggerB/'
    variance_dir = froot + ['PSF2_0/','PSF2_1/']
    
    datafiles = [[file_search(data_dir[0] + '*.fits')],[file_search(data_dir[1] + '*.fits')]]
    weightfiles = [[file_search(weights_dir[0] + '*.fits')],[file_search(weights_dir[1] + '*.fits')]]
    variancefiles = [[file_search(variance_dir[0] + '*.fits')],[file_search(variance_dir[1] + '*.fits')]]
    
    datafile =  rts_fits2idlcube(datafiles, weightfiles, variancefiles, pol_inc, save_path = froot)
    
  endif else begin
  
    if n_elements(folder_name) eq 0 then folder_name = '/nfs/mwa-09/r1/djc/EoR2013/Aug23/fhd_apb_pipeline_paper_deep_1/Healpix/'
    
    ;; check for folder existence, otherwise look for common folder names to figure out full path. If none found, try '/nfs/mwa-09/r1/djc/EoR2013/Aug23/'
    start_path = '/nfs/mwa-09/r1/djc/'
    folder_test = file_test(folder_name, /directory)
    if folder_test eq 0 then begin
      pos_eor2013 = strpos(folder_name, 'EoR2013')
      if pos_eor2013 gt -1 then begin
        test_name = start_path + strmid(folder_name, pos_eor2013)
        folder_test = file_test(test_name, /directory)
        if folder_test eq 1 then folder_name = test_name
      endif
    endif
    if folder_test eq 0 then begin
      pos_aug23 = strpos(folder_name, 'Aug23')
      if pos_aug23 gt -1 then begin
        test_name = start_path + 'EoR2013/' + strmid(folder_name, pos_aug23)
        folder_test = file_test(test_name, /directory)
        if folder_test eq 1 then folder_name = test_name
      endif
    endif
    if folder_test eq 0 then begin
      pos_aug26 = strpos(folder_name, 'Aug26')
      if pos_aug26 gt -1 then begin
        test_name = start_path + 'EoR2013/' + strmid(folder_name, pos_aug26)
        folder_test = file_test(test_name, /directory)
        if folder_test eq 1 then folder_name = test_name
      endif
    endif
    if folder_test eq 0 then begin
      pos_week1 = strpos(folder_name, 'week1')
      if pos_week1 gt -1 then begin
        test_name = start_path + 'EoR2013/' + strmid(folder_name, pos_week1)
        folder_test = file_test(test_name, /directory)
        if folder_test eq 1 then folder_name = test_name
      endif
    endif
    if folder_test eq 0 then begin
      test_name = start_path + 'EoR2013/Aug23/' + folder_name
      folder_test = file_test(test_name, /directory)
      if folder_test eq 1 then folder_name = test_name
    endif
    if folder_test eq 0 then begin
      test_name = start_path + 'EoR2013/Aug26/' + folder_name
      folder_test = file_test(test_name, /directory)
      if folder_test eq 1 then folder_name = test_name
    endif
    if folder_test eq 0 then begin
      test_name = start_path + 'EoR2013/week1/' + folder_name
      folder_test = file_test(test_name, /directory)
      if folder_test eq 1 then folder_name = test_name
    endif
    
    if folder_test eq 0 then message, 'folder not found'
    
    
    if n_elements(obs_name) gt 0 then begin
      if size(obs_name,/type) eq 7 then begin
        obs_name_single = obs_name
      endif else begin
        obs_name = number_formatter(obs_name)
        obs_name_single = obs_name
      endelse
    endif else begin
      obs_name = ''
      obs_name_single = ''
    endelse
    
    ;; first look for integrated info files with names like Combined_obs_...
    info_file = file_search(folder_name + '/ps/Combined_obs_*' + obs_name + '*info*', count = n_infofile)
    if n_infofile gt 0 then begin
      if obs_name eq '' then begin
        if n_infofile gt 1 then print, 'More than 1 info files found, using first one'
        datafile = info_file[0]
        
        if stregex(datafile, '[0-9]+-[0-9]+', /boolean) then obs_name = stregex(datafile, '[0-9]+-[0-9]+', /extract) else begin
          start_pos = strpos(datafile, 'Combined_obs_') + strlen('Combined_obs_')
          end_pos = strpos(strmid(datafile, start_pos), '_cube')
          obs_name = strmid(datafile, start_pos, end_pos)
        endelse
      endif else begin
        if n_infofile gt 1 then message, 'More than one info file found with given obs_name'
        datafile = info_file[0]
        
        if stregex(datafile, '[0-9]+-[0-9]+', /boolean) then obs_name = stregex(datafile, '[0-9]+-[0-9]+', /extract) else begin
          start_pos = strpos(datafile, 'Combined_obs_') + strlen('Combined_obs_')
          end_pos = strpos(strmid(datafile, start_pos), '_cube')
          obs_name = strmid(datafile, start_pos, end_pos)
        endelse
      endelse
      integrated=1
      save_path = folder_name + '/ps/'
    endif else begin
      ;; then look for single obs info files
      info_file = file_search(folder_name + '/ps/*' + obs_name_single + '*info*', count = n_infofile)
      if n_infofile gt 0 then begin
        info_basename = file_basename(info_file)
        if obs_name eq '' then begin
          if n_infofile gt 1 then print, 'More than 1 info files found, using first one'
          datafile = info_file[0]
          
          if stregex(info_basename[0], '[0-9]+', /boolean) then obs_name = stregex(info_basename[0], '[0-9]+', /extract) else begin
            end_pos = strpos(info_basename[0], '_cube')
            obs_name = strmid(info_basename[0], 0, end_pos)
          endelse
        endif else begin
          if n_infofile gt 1 then message, 'More than one info file found with given obs_name'
          datafile = info_file[0]
          if stregex(info_basename[0], '[0-9]+', /boolean) then obs_name = stregex(info_basename[0], '[0-9]+', /extract) else begin
            end_pos = strpos(info_basename[0], '_cube')
            obs_name = strmid(info_basename[0], 0, end_pos)
          endelse
        endelse
        integrated=0
        
        save_path = folder_name + '/ps/'
      endif
    endelse
    
    if n_infofile eq 0 then begin
      ;; first look for integrated cube files with names like Combined_obs_...
      cube_files = file_search(folder_name + '/Healpix/Combined_obs_*' + obs_name + '*_cube*.sav', count = n_cubefiles)
      
      if n_cubefiles gt 0 then cube_files = cube_files[where(strmatch(cube_files,'*'+obs_name+'_[eo][vd]*_cube*.sav',/fold_case) eq 1, n_cubefiles)] ; get rid of ambiguous files
      
      if n_cubefiles gt 0 then begin
        cube_basename = file_basename(cube_files)
        pol_exist = stregex(cube_basename, '[xy][xy]', /boolean, /fold_case)
        if obs_name eq '' then begin
          obs_name_arr = strarr(n_cubefiles)
          for j=0, n_cubefiles-1 do begin
            start_pos = strpos(cube_basename[j], 'Combined_obs_') + strlen('Combined_obs_')
            end_pos_even = strpos(strmid(cube_basename[j], start_pos), '_even')
            end_pos_odd = strpos(strmid(cube_basename[j], start_pos), '_odd')
            end_pos_cube = strpos(strmid(cube_basename[j], start_pos), '_cube') ;; always > -1
            end_pos = end_pos_even > end_pos_odd
            wh_noend = where(end_pos eq -1, count_noend)
            if count_noend gt 0 then end_pos[wh_noend] = end_pos_cube[wh_noend]
            
            ;obs_name_arr = stregex(cube_basename, '[0-9]+-[0-9]+', /extract)
            obs_name_arr[j] = strmid(cube_basename[j], start_pos, end_pos)
          endfor
          
          wh_first = where(obs_name_arr eq obs_name_arr[0], count_first)
          if count_first lt n_elements(cube_basename) then $
            print, 'More than one obs_name found, using first obs_name (' + obs_name_arr[0] + ', ' + number_formatter(count_first) + ' files)'
          if max(pol_exist[wh_first]) gt 0 then begin
            if min(pol_exist[wh_first]) eq 0 then message, 'some files with first obs_name have pol identifiers and some do not'
            pols = stregex(cube_basename[wh_first], '[xy][xy]', /extract, /fold_case)
            
            pols_inc = pols[0]
            pol_num = intarr(count_first)
            for pol_i=0, count_first-1 do begin
              wh_pol = where(pols_inc eq pols[pol_i], count_pol)
              if count_pol eq 1 then pol_num[pol_i] = wh_pol[0] else begin
                pols_inc = [pols_inc, pols[pol_i]]
                pol_num[pol_i] = n_elements(pols_inc)-1
              endelse
            endfor
            
            for pol_i=0, n_elements(pols_inc) do begin
              wh_pol = where(pol_num eq pol_i, count_pol)
              if count_pol gt 2 then message, 'More than two cubes found with first obs_name and the same polarization'
            endfor
          endif else if count_first gt 2 then message, 'More than two cubes found with first obs_name'
          
          datafile = cube_files[wh_first]
          obs_name = obs_name_arr[0]
        endif else begin
          if max(pol_exist) gt 0 then begin
            if min(pol_exist) eq 0 then message, 'some files with given obs_name have pol identifiers and some do not'
            pols = stregex(cube_basename, '[xy][xy]', /extract, /fold_case)
            
            pols_inc = pols[0]
            pol_num = intarr(n_cubefiles)
            for pol_i=0, n_cubefiles-1 do begin
              wh_pol = where(pols_inc eq pols[pol_i], count_pol)
              if count_pol eq 1 then pol_num[pol_i] = wh_pol[0] else begin
                pols_inc = [pols_inc, pols[pol_i]]
                pol_num[pol_i] = n_elements(pols_inc)-1
              endelse
            endfor
            
            for pol_i=0, n_elements(pols_inc) do begin
              wh_pol = where(pol_num eq pol_i, count_pol)
              if count_pol gt 2 then message, 'More than two cubes found with given obs_name and the same polarization'
            endfor
          endif else if n_cubefiles gt 2 then message, 'More than two cubes found with given obs_name'
          
          datafile = cube_files
        endelse
        integrated=1
        ;; set the save_path to a 'ps' directory one level up from the datafile directory and create the directory if it doesn't exist
        save_path = file_dirname(file_dirname(datafile[0]), /mark_directory) + 'ps/'
        if not file_test(save_path, /directory) then file_mkdir, save_path
      endif else begin
        ;; then look for single obs cube files
        cube_files = file_search(folder_name + '/*' + obs_name_single + '*_cube*.sav', count = n_cubefiles)
        if n_cubefiles gt 0 then begin
          cube_basename = file_basename(cube_files)
          pol_exist = stregex(cube_basename, '[xy][xy]', /boolean, /fold_case)
          if obs_name eq '' then begin
            obs_name_arr = strarr(n_cubefiles)
            for j=0, n_cubefiles-1 do begin
              end_pos_even = strpos(strmid(cube_basename[j], 0), '_even')
              end_pos_odd = strpos(strmid(cube_basename[j], 0), '_odd')
              end_pos_cube = strpos(strmid(cube_basename[j], 0), '_cube') ;; always > -1
              end_pos = end_pos_even > end_pos_odd
              wh_noend = where(end_pos eq -1, count_noend)
              if count_noend gt 0 then end_pos[wh_noend] = end_pos_cube[wh_noend]
              
              obs_name_arr[j] = strmid(cube_basename[j], 0, end_pos)
            endfor
            
            wh_first = where(obs_name_arr eq obs_name_arr[0], count_first)
            if count_first lt n_elements(cube_files) then $
              print, 'More than one obs_name found, using first obs_name (' + obs_name_arr[0] + ', ' + number_formatter(count_first) + ' files)'
            if max(pol_exist[wh_first]) gt 0 then begin
              if min(pol_exist[wh_first]) eq 0 then message, 'some files with first obs_name have pol identifiers and some do not'
              pols = stregex(cube_basename[wh_first], '[xy][xy]', /extract, /fold_case)
              
              pols_inc = pols[0]
              pol_num = intarr(count_first)
              for pol_i=0, count_first-1 do begin
                wh_pol = where(pols_inc eq pols[pol_i], count_pol)
                if count_pol eq 1 then pol_num[pol_i] = wh_pol[0] else begin
                  pols_inc = [pols_inc, pols[pol_i]]
                  pol_num[pol_i] = n_elements(pols_inc)-1
                endelse
              endfor
              
              for pol_i=0, n_elements(pols_inc) do begin
                wh_pol = where(pol_num eq pol_i, count_pol)
                if count_pol gt 2 then message, 'More than two cubes found with first obs_name and the same polarization'
              endfor
            endif else if count_first gt 2 then message, 'More than two cubes found with first obs_name'
            obs_name = obs_name_arr[0]
            datafile = cube_files
          endif else begin
            if max(pol_exist) gt 0 then begin
              if min(pol_exist) eq 0 then message, 'some files with given obs_name have pol identifiers and some do not'
              pols = stregex(cube_basename, '[xy][xy]', /extract, /fold_case)
              
              pols_inc = pols[0]
              pol_num = intarr(n_cubefiles)
              for pol_i=0, n_cubefiles-1 do begin
                wh_pol = where(pols_inc eq pols[pol_i], count_pol)
                if count_pol eq 1 then pol_num[pol_i] = wh_pol[0] else begin
                  pols_inc = [pols_inc, pols[pol_i]]
                  pol_num[pol_i] = n_elements(pols_inc)-1
                endelse
              endfor
              
              for pol_i=0, n_elements(pols_inc) do begin
                wh_pol = where(pol_num eq pol_i, count_pol)
                if count_pol gt 2 then message, 'More than two cubes found with given obs_name and the same polarization'
              endfor
            endif else if n_cubefiles gt 2 then message, 'More than two cubes found with given obs_name'
            datafile = cube_files
          endelse
          integrated=0
          ;; set the save_path to a 'ps' directory in the datafile directory and create the directory if it doesn't exist
          save_path = file_dirname(datafile[0], /mark_directory) + 'ps/'
          if not file_test(save_path, /directory) then file_mkdir, save_path
        endif
      endelse
    endif
    
    if n_elements(datafile) eq 0 then message, 'No cube or info files found in folder ' + folder_name
    
    print,'datafile = '+datafile
    
    if n_elements(set_data_ranges) eq 0 then set_data_ranges = 1
    if keyword_set(set_data_ranges) then begin
      if keyword_set(integrated) then begin
        sigma_range = [2e5, 2e9]
        nev_range = [2e7, 2e10]
      endif else begin
        sigma_range = [1e4, 2e6]
        nev_range = [5e4, 2e7]
      endelse
      
      data_range = [1e4, 1e14]
      nnr_range = [1e-1, 1e1]
      snr_range = [1e-4, 1e6]
      
      noise_range = nev_range
    endif
    
    
  endelse
  
  ;; dft_fchunk applies only to Healpix datasets (it's ignored otherwise) and it specifies how many frequencies to process
  ;;   through the dft at once. This keyword allows for trade-offs between memory use and speed.
  ;; The optimum setting varies by computer and the speed is NOT a linear function of this parameter
  ;;   (it's not even monotonic) so some experimenting is required. The memory required is approximately linear --
  ;;   the higher this value the more memory required.
  ;; The default is 1 (to minimize memory use)
  ;; The maximum value of this parameter is the number of frequency slices in the cube
  ;;   (if its set too large it will be reduced to the maximum)
  
  dft_fchunk = 1
  
  
  ;; save_path specifies a location to save the power spectrum files.
  ;; This is also where the code looks for intermediate save files to avoid re-running code.
  ;; If this is parameter is not set, the files will be saved in the same directory as the datafile.
  
  
  ;; savefilebase specifies a base name to use for the save files
  
  ;; plot_path specifies a location to save plot files.
  ;; If this parameter is not set, the plots will be saved in the same directory as the datafile.
  
  ;; plot_filebase specifies a base name to use for the plot files
  
  
  ;; freq_ch_range specifies which frequency channels to include in the power spectrum.
  ;; Fewer number of channels makes the dfts faster
  
  ;; pol_inc specifies which polarizations to generate the power spectra for.
  ;; The default is ['xx,'yy']
  
  ;; cut_image keyword only applies to Healpix datasets. It allows for limiting the field of view in the
  ;; image plane by only using Healpix pixels inside a 30 degree diameter circle centered in the middle of the field.
  ;; Currently defaults to on. Set equal to 0 to turn it off, 1 to turn it on
  
  
  ;; There are 3 refresh flags to indicate that various stages should be re-calculated
  ;;   (rather than using previous save files if they exist).
  ;; If an early stage is recalculated, all subsequent stages will also be recalculated
  ;; The earliest stage is refresh_dft, which is only used for Healpix datasets (it's ignored otherwise)
  ;; The next stage is refresh_ps and the last stage is refresh_binning.
  ;; To set any of these flags, set them equal to 1 (true)
  
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
  ;; pub is a flag to make save plots as eps files rather than displaying to the screen
  
  fhd_data_plots, datafile, dft_fchunk=dft_fchunk, plot_path = plot_path, plot_filebase = plot_filebase, save_path = save_path, savefilebase = savefilebase, $
    pol_inc = pol_inc, rts = rts, $
    refresh_dft = refresh_dft, refresh_ps = refresh_ps, refresh_binning = refresh_binning, refresh_info = refresh_info, refresh_beam = refresh_beam, $
    freq_ch_range = freq_ch_range, no_spec_window = no_spec_window, spec_window_type = spec_window_type, $
    sim = sim, cut_image = cut_image, delta_uv_lambda = delta_uv_lambda, $
    log_kpar = log_kpar, log_kperp = log_kperp, kpar_bin = kpar_bin, kperp_bin = kperp_bin, log_k1d = log_k1d, $
    k1d_bin = k1d_bin, kperp_linear_axis = kperp_linear_axis, kpar_linear_axis = kpar_linear_axis, $
    data_range = data_range, sigma_range = sigma_range, nev_range = nev_range, snr_range = snr_range, noise_range = noise_range, nnr_range = nnr_range, $
    baseline_axis = baseline_axis, delay_axis = delay_axis, hinv = hinv, $
    plot_wedge_line = plot_wedge_line, individual_plots = individual_plot, png = png, eps = eps
    
  if not keyword_set(set_data_ranges) then begin
    print, 'data_range used: ', number_formatter(data_range, format = '(e7.1)')
    print, 'sigma_range used: ', number_formatter(sigma_range, format = '(e7.1)')
    print, 'nev_range used: ', number_formatter(nev_range, format = '(e7.1)')
    print, 'nnr_range used: ', number_formatter(nnr_range, format = '(e7.1)')
    print, 'snr_range used: ', number_formatter(snr_range, format = '(e7.1)')
    print, 'noise_range used: ', number_formatter(noise_range, format = '(e7.1)')
  endif
  
end
