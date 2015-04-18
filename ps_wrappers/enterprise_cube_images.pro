pro enterprise_cube_images, folder_names, obs_names_in, data_subdirs=data_subdirs, cube_types = cube_types, $
    pols = pols, evenodd = evenodd, $
    rts = rts, sim = sim, casa = casa, png = png, eps = eps, pdf = pdf, slice_range = slice_range, $
    nvis_norm = nvis_norm, ratio = ratio, diff_ratio = diff_ratio, diff_frac = diff_frac, $
    log = log, data_range = data_range, color_profile = color_profile, sym_color = sym_color, window_num = window_num, plot_as_map = plot_as_map
    
  if n_elements(folder_names) gt 2 then message, 'No more than 2 folder_names can be supplied'
  if n_elements(evenodd) eq 0 then evenodd = 'even'
  if n_elements(evenodd) gt 2 then message, 'No more than 2 evenodd values can be supplied'
  if n_elements(obs_names_in) gt 2 then message, 'No more than 2 obs_names can be supplied'
  
  if keyword_set(rts) then begin
    ;    froot = '/data3/MWA/bpindor/RTS/dec_11/'
    ;
    ;    ;     data_dir = froot + 'BdaggerV/'
    ;    data_dir = froot + ['PSF0_0/','PSF0_1/']
    ;
    ;    ;     weights_dir = froot + 'Bdagger1/'
    ;    weights_dir = froot + ['PSF1_0/','PSF1_1/']
    ;
    ;    ;     variance_dir = froot + 'BdaggerB/'
    ;    variance_dir = froot + ['PSF2_0/','PSF2_1/']
    ;
    ;    datafiles = [[file_search(data_dir[0] + '*.fits')],[file_search(data_dir[1] + '*.fits')]]
    ;    weightfiles = [[file_search(weights_dir[0] + '*.fits')],[file_search(weights_dir[1] + '*.fits')]]
    ;    variancefiles = [[file_search(variance_dir[0] + '*.fits')],[file_search(variance_dir[1] + '*.fits')]]
  
  
  
    if n_elements(folder_name) eq 0 then folder_name = '/data3/MWA/bpindor/RTS/feb_9/'
    
    ;; check for folder existence, otherwise look for common folder names to figure out full path. If none found, try '/data3/MWA/bpindor/RTS/'
    start_path = '/data3/MWA/bpindor/RTS/'
    folder_test = file_test(folder_name, /directory)
    if folder_test eq 0 then begin
      pos_RTS = strpos(folder_name, 'RTS')
      if pos_RTS gt -1 then begin
        test_name = start_path + strmid(folder_name, pos_RTS)
        folder_test = file_test(test_name, /directory)
        if folder_test eq 1 then folder_name = test_name
      endif
    endif
    if folder_test eq 0 then begin
      test_name = start_path + folder_name
      folder_test = file_test(test_name, /directory)
      if folder_test eq 1 then folder_name = test_name
    endif
    
    if folder_test eq 0 then message, 'folder not found'
    
    if n_elements(ps_foldername) eq 0 then ps_foldername = 'ps/'
    save_path = folder_name + '/' + ps_foldername
    obs_info = ps_filenames(folder_name, obs_name, rts = rts, sim = sim, casa = casa, $
      save_paths = save_path, plot_path = save_path, refresh_info = refresh_info, no_wtvar_rts = no_wtvar_rts)
      
    if obs_info.info_files[0] ne '' then datafile = obs_info.info_files[0] else $
      if obs_info.cube_files.(0)[0] ne '' then datafile = obs_info.cube_files.(0) else $
      datafile = rts_fits2idlcube(obs_info.datafiles.(0), obs_info.weightfiles.(0), obs_info.variancefiles.(0), $
      pol_inc, save_path = obs_info.folder_names[0]+path_sep(), refresh = refresh_dft, no_wtvar = no_wtvar_rts)
      
    if keyword_set(refresh_rtscube) then datafile = rts_fits2idlcube(obs_info.datafiles.(0), obs_info.weightfiles.(0), obs_info.variancefiles.(0), $
      pol_inc, save_path = obs_info.folder_names[0]+path_sep(), /refresh, no_wtvar = no_wtvar_rts)
      
    if keyword_set(no_wtvar_rts) then stop
    
    note = obs_info.rts_types
    if not file_test(save_path, /directory) then file_mkdir, save_path
    
    plot_path = save_path + 'plots/'
    if not file_test(plot_path, /directory) then file_mkdir, plot_path
    
  endif else begin
  
    for i=0, n_elements(folder_names)-1 do begin
      ;; check for folder existence, otherwise look for common folder names to figure out full path.
      start_path = '/data4/MWA/'
      folder_test = file_test(folder_names[i], /directory)
      if folder_test eq 0 then begin
        pos_aug23 = strpos(folder_names[i], 'FHD_Aug23')
        if pos_aug23 gt -1 then begin
          test_name = start_path + strmid(folder_names[i], pos_aug23)
          folder_test = file_test(test_name, /directory)
          if folder_test eq 1 then folder_names[i] = test_name
        endif
      endif
      if folder_test eq 0 then begin
        test_name = start_path + 'FHD_Aug23/' + folder_names[i]
        folder_test = file_test(test_name, /directory)
        if folder_test eq 1 then folder_names[i] = test_name
      endif
      
      if folder_test eq 0 then message, 'folder not found'
    endfor
    
    save_paths = folder_names + '/ps/'
    if n_elements(data_subdirs) eq 0 then data_subdirs = 'Healpix/' else if n_elements(data_subdirs) gt 2 then message, 'No more than 2 data_subdirs can be supplied.'
    obs_info = ps_filenames(folder_names, obs_names_in, rts = rts, sim = sim, casa = casa, data_subdirs = data_subdirs, save_paths = save_paths, plot_paths = save_paths)
  endelse
  
  cube_images, folder_names, obs_info, nvis_norm = nvis_norm, pols = pols, cube_types = cube_types, evenodd = evenodd, rts = rts, $
    png = png, eps = eps, pdf = pdf, slice_range = slice_range, ratio = ratio, diff_ratio = diff_ratio, diff_frac = diff_frac, $
    log = log, data_range = data_range, color_profile = color_profile, sym_color = sym_color, $
    window_num = window_num, plot_as_map = plot_as_map
    
end
