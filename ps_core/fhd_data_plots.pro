pro fhd_data_plots, datafile, rts = rts, pol_inc = pol_inc, image = image, $
    save_path = save_path, savefilebase = savefilebase, plot_path = plot_path, plot_filebase = plot_filebase, png = png, eps = eps, $
    refresh_dft = refresh_dft, dft_fchunk = dft_fchunk, refresh_ps = refresh_ps, refresh_binning = refresh_binning, $
    freq_ch_range = freq_ch_range, no_spec_window = no_spec_window, spec_window_type = spec_window_type, $
    cut_image = cut_image, dft_ian = dft_ian, noise_sim = noise_sim, std_power = std_power, no_kzero = no_kzero, $
    plot_slices = plot_slices, slice_type = slice_type, $
    data_range = data_range, sigma_range = sigma_range, nev_range = nev_range, $
    snr_range = snr_range, noise_range = noise_range, nnr_range = nnr_range, $
    log_kpar = log_kpar, log_kperp = log_kperp, kpar_bin = kpar_bin, kperp_bin = kperp_bin, log_k1d = log_k1d, $
    k1d_bin = k1d_bin, kperp_linear_axis = kperp_linear_axis, kpar_linear_axis = kpar_linear_axis, $
    baseline_axis = baseline_axis, delay_axis = delay_axis, hinv = hinv, plot_wedge_line = plot_wedge_line, $
    grey_scale = grey_scale, individual_plots = individual_plots
    
  nfiles = n_elements(datafile)
  if nfiles gt 2 then message, 'only 1 or 2 datafiles is supported'
  
  if keyword_set(noise_sim) then begin
    datafile=datafile[0]
    nfiles=1
  endif
  
  if keyword_set(refresh_dft) then refresh_ps = 1
  if keyword_set(refresh_ps) then refresh_binning = 1
  
  ;; default to including baseline axis & delay axis
  if n_elements(baseline_axis) eq 0 then baseline_axis = 1
  if n_elements(delay_axis) eq 0 then delay_axis = 1
  
  ;; default to hinv
  if n_elements(hinv) eq 0 then hinv = 1
  
  ;; default to plot wedge line
  if n_elements(plot_wedge_line) eq 0 then plot_wedge_line=1
  
  ;; default to blackman-harris spectral window
  if not keyword_set(no_spec_window) then begin
    if n_elements(spec_window_type) eq 0 then spec_window_type = 'Blackman-Harris'
  endif else undefine, spec_window_type
  
  ;; default to cutting in image space (down to 30 degree diameter circle)
  if n_elements(cut_image) eq 0 then cut_image = 1
  
  if keyword_set(png) or keyword_set(eps) then pub = 1 else pub = 0
  if pub eq 1 then begin
  
    if keyword_set(png) and keyword_set(eps) then begin
      print, 'both eps and png cannot be set, using png'
      eps = 0
    endif
    
    case 1 of
      png: begin
        plot_exten = '.png'
        delete_ps = 1
      end
      eps: begin
        plot_exten = '.eps'
        delete_ps = 0
      end
    endcase
  endif else plot_exten = ''
  
  if n_elements(freq_ch_range) ne 0 then begin
    if min(freq_ch_range) lt 0 or max(freq_ch_range) - min(freq_ch_range) lt 3 then message, 'invalid freq_ch_range'
    fch_tag = '_ch' + number_formatter(min(freq_ch_range)) + '-' + number_formatter(max(freq_ch_range))
  endif else fch_tag = ''
  
  fadd = fch_tag
  if keyword_set(std_power) then fadd = fadd + '_sp'
  
  fadd_2dbin = ''
  wt_fadd_2dbin = ''
  ;;if keyword_set(fill_holes) then fadd_2dbin = fadd_2dbin + '_nohole'
  if keyword_set(no_kzero) then begin
    fadd_2dbin = fadd_2dbin + '_nok0'
    wt_fadd_2dbin = wt_fadd_2dbin + '_nok0'
  endif
  if keyword_set(log_kpar) then begin
    fadd_2dbin = fadd_2dbin + '_logkpar'
    wt_fadd_2dbin = wt_fadd_2dbin + '_logkpar'
  endif
  if keyword_set(log_kperp) then begin
    fadd_2dbin = fadd_2dbin + '_logkperp'
    wt_fadd_2dbin = wt_fadd_2dbin + '_logkperp'
  endif
  
  fadd_1dbin = ''
  if keyword_set(log_k) then fadd_1dbin = fadd_1dbin + '_logk'
  
  
  
  if n_elements(savefilebase) gt 1 then message, 'savefilebase must be a scalar'
  
  time0 = systime(1)
  if keyword_set(rts) then file_struct_arr = rts_file_setup(datafile, pol_inc, savefilebase = savefilebase, save_path = save_path, $
    spec_window_type = spec_window_type) else file_struct_arr = fhd_file_setup(datafile, pol_inc, image = image, dft_ian = dft_ian, $
    savefilebase = savefilebase, save_path = save_path, freq_ch_range = freq_ch_range, spec_window_type = spec_window_type, noise_sim = noise_sim)
  time1 = systime(1)
  print, 'file setup time: ' + number_formatter(time1-time0)
    
  npol = n_elements(pol_inc)
  n_cubes = n_elements(file_struct_arr)
  ntype = n_cubes / npol
  if n_cubes ne ntype * npol then stop
  
  file_labels = file_struct_arr.file_label
  wt_file_labels = file_struct_arr.wt_file_label
  titles = strarr(n_cubes)
  for i=0, n_cubes-1 do titles[i] = strjoin(strsplit(file_labels[i], '_', /extract), ' ')
  
  weight_ind = intarr(n_cubes)
  for i=0, npol-1 do weight_ind[where(strpos(strlowcase(file_struct_arr.wt_file_label), strlowcase(pol_inc[i])) ge 0) ] = i
  weight_labels = strupcase(pol_inc[weight_ind])
  
  ;; need general_filebase for 1D plotfiles, make sure it doesn't have a full path
  general_filebase = file_struct_arr(0).general_filebase
  for i=0, n_cubes-1 do if file_struct_arr(i).general_filebase ne general_filebase then stop
  
  savefiles_2d = file_struct_arr.savefile_froot + file_struct_arr.savefilebase + fadd_2dbin + '_2dkpower.idlsave'
  test_save_2d = file_test(savefiles_2d) *  (1 - file_test(savefiles_2d, /zero_length))
  
  savefiles_1d = file_struct_arr.savefile_froot + file_struct_arr.savefilebase + fadd_1dbin + '_1dkpower.idlsave'
  test_save_1d = file_test(savefiles_1d) *  (1 - file_test(savefiles_1d, /zero_length))
  
  if keyword_set(refresh_binning) then begin
    test_save_2d = test_save_2d*0
    test_save_1d = test_save_1d*0
  endif
  
  if tag_exist(file_struct_arr[0], 'nside') ne 0 then healpix = 1 else healpix = 0
  
  n_freq = n_elements(file_struct_arr[0].frequencies)
  if n_elements(freq_ch_range) ne 0 then if max(freq_ch_range) gt n_freq-1 then message, 'invalid freq_ch_range'
  
  if healpix and n_elements(dft_fchunk) ne 0 then if dft_fchunk gt n_freq then begin
    print, 'dft_fchunk is larger than the number of frequency slices, setting it to the number of slices -- ' + $
      number_formatter(n_freq)
    dft_fchunk = n_freq
  endif
  
  
  for i=0, n_cubes-1 do begin
  
    ;; if binsizes are specified, check that binsize is right
    if (n_elements(kperp_bin) ne 0 or n_elements(kpar_bin) ne 0) and test_save_2d[i] gt 0 then begin
      if n_elements(kpar_bin) ne 0 then begin
        kpar_bin_file = getvar_savefile(savefiles_2d[i], kpar_bin)
        if abs(kpar_bin - kpar_bin_file) gt 0. then test_save_2d[i]=0
      endif
      if test_save_2d[i] gt 0 and n_elements(kpar_bin) ne 0 then begin
        kperp_bin_file = getvar_savefile(savefiles_2d[i], kperp_bin)
        if abs(kperp_bin - kperp_bin_file) gt 0. then test_save_2d[i]=0
      endif
    endif
    
    if n_elements(k1d_bin) ne 0 and test_save_1d[i] gt 0 then begin
      k_bin_file = getvar_savefile(savefiles_1d[i], k_bin)
      if abs(k_bin - k_bin_file) gt 0. then test_save_1d[i]=0
    endif
    
    test = test_save_2d[i] * test_save_1d[i]
    
    if test eq 0 then begin
    
      if healpix or keyword_set(image) then begin
        weight_refresh = intarr(n_cubes)
        if keyword_set(refresh_dft) then begin
          temp = weight_ind[uniq(weight_ind, sort(weight_ind))]
          for j=0, n_elements(temp)-1 do weight_refresh[(where(weight_ind eq temp[j]))[0]] = 1
        endif
        
        fhd_3dps, file_struct_arr[i], kcube_refresh = refresh_ps, dft_refresh_data = refresh_dft, $
          dft_refresh_weight = weight_refresh[i], dft_ian = dft_ian, cut_image = cut_image, image = image, $
          dft_fchunk = dft_fchunk, freq_ch_range = freq_ch_range, spec_window_type = spec_window_type, $
          noise_sim = noise_sim, std_power = std_power, no_kzero = no_kzero, $
          log_kpar = log_kpar, log_kperp = log_kperp, kpar_bin = kpar_bin, kperp_bin = kperp_bin, $
          /quiet
      endif else $
        fhd_3dps, file_struct_arr[i], kcube_refresh = refresh_ps, freq_ch_range = freq_ch_range, $
        spec_window_type = spec_window_type, $
        noise_sim = noise_sim, std_power = std_power, no_kzero = no_kzero, $
        log_kpar = log_kpar, log_kperp = log_kperp, kpar_bin = kpar_bin, kperp_bin = kperp_bin, /quiet
    endif
  endfor
  
  
  restore, savefiles_2d[0]
  ;;   baselines = get_baselines(/quiet, freq_mhz = 185)
  ;;   quick_histplot, baselines, title = spec_window_type, xstyle=1, ystyle = 8, xrange = [0, max(kperp_edges)*kperp_lambda_conv], $
  ;;                   position = [.1, .1, .9, .9], ytitle = 'number of baselines', xtitle = 'Baseline length ' + textoidl('(\lambda)')
  
  ;;   cgaxis, yaxis=1, /ylog, yrange = [1e6, 1e12] , ytitle = 'noise power', /save
  ;;   cgplot, kperp_edges[1:*]*kperp_lambda_conv, 1/sqrt(weights[*,24]), /overplot, color='blue'
  ;;   cgplot, kperp_edges[1:*]*kperp_lambda_conv, noise[*,24], /overplot, color='red'
  
  ;;   ;;cgplot, kperp_edges[1:*]*kperp_lambda_conv, total(noise,2)/(n_elements(kpar_edges)-1), /overplot, color='black', linestyle = 2
  ;;   al_legend, ['expected', 'observed'], textcolor=['blue','red'], /right, box=0
  ;; stop
  
  wh_good_kperp = where(total(power, 2) gt 0, count)
  if count eq 0 then stop
  ;;kperp_plot_range = [min(kperp_edges[wh_good_kperp]), max(kperp_edges[wh_good_kperp+1])]
  
  ;;kperp_plot_range = [6e-3, min([max(kperp_edges[wh_good_kperp+1]),1.1e-1])]
  ;;kperp_plot_range = [5./kperp_lambda_conv, min([max(kperp_edges[wh_good_kperp+1]),1.1e-1])]
  
  kperp_plot_range = [5./kperp_lambda_conv, min([file_struct_arr.kspan/2.,file_struct_arr.max_baseline_lambda])/kperp_lambda_conv]
  
  if keyword_set(hinv) then kperp_plot_range = kperp_plot_range / hubble_param
  
  if pub then begin
    if n_elements(plot_path) ne 0 then plotfile_path = plot_path $
    else if n_elements(save_path) ne 0 then plotfile_path = save_path else plotfile_path = file_struct_arr.savefile_froot
    
    plot_fadd = ''
    if keyword_set(grey_scale) then plot_fadd = plot_fadd + '_grey'
    
    if keyword_set(individual_plots) then begin
      if n_elements(plot_filebase) eq 0 then begin
        plotfile_base = plotfile_path + file_struct_arr.savefilebase + fadd
        plotfile_base_wt = plotfile_path + general_filebase + wt_file_labels[uniq(weight_ind, sort(weight_ind))] + fadd
        plotfiles_2d_wt = plotfile_base_wt + fadd_2dbin + '_2d' + plot_fadd + plot_exten
      endif else begin
        plotfile_base = plotfile_path + plot_filebase + file_struct_arr.file_label + fadd
        plotfile_base_wt = plotfile_path + plot_filebase + wt_file_labels[uniq(weight_ind, sort(weight_ind))] + fadd
        plotfiles_2d_wt = plotfile_base_wt + fadd_2dbin + '_2d' + plot_fadd + plot_exten
      endelse
    endif else if n_elements(plot_filebase) eq 0 then plotfile_base = plotfile_path + general_filebase + fadd else plotfile_base = plotfile_path + plot_filebase + fadd
    
    plotfiles_2d = plotfile_base + fadd_2dbin + '_2dkpower' + plot_fadd + plot_exten
    plotfiles_2d_error = plotfile_base + fadd_2dbin + '_2derror' + plot_fadd + plot_exten
    if keyword_set(pub) and keyword_set(individual_plots) then $
      plotfiles_2d_noise_expval = plotfile_base + fadd_2dbin + '_2dnoise_expval' + plot_fadd + plot_exten
    plotfiles_2d_noise = plotfile_base + fadd_2dbin + '_2dnoise' + plot_fadd + plot_exten
    plotfiles_2d_snr = plotfile_base + fadd_2dbin + '_2dsnr' + plot_fadd + plot_exten
    plotfiles_2d_nnr = plotfile_base + fadd_2dbin + '_2dnnr' + plot_fadd + plot_exten
    if n_elements(plot_filebase) eq 0 then plotfile_1d = plotfile_path + general_filebase + fadd + fadd_1dbin + '_1dkpower' + plot_exten else $
      plotfile_1d = plotfile_path + plot_filebase + fadd + fadd_1dbin + '_1dkpower' + plot_exten
  endif
  
  if keyword_set(plot_slices) then begin
    if n_elements(slice_type) eq 0 then slice_type = 'sumdiff'
    slice_type_enum = ['raw', 'divided', 'kspace', 'sumdiff']
    
    wh_slice_type = where(slice_type_enum eq slice_type, count_slice_type)
    if count_slice_type eq 0 then begin
      print, 'slice_type not recognized, using default'
      slice_type = 'sumdiff'
    endif
    
    if pub then begin
      if slice_type ne 'kspace' then begin
        uf_slice_plotfile = plotfile_base + '_' + slice_type + '_uf_plane' + plot_fadd + plot_exten
        vf_slice_plotfile = plotfile_base + '_' + slice_type + '_vf_plane' + plot_fadd + plot_exten
        uv_slice_plotfile = plotfile_base + '_' + slice_type + '_uv_plane' + plot_fadd + plot_exten
      endif else begin
        uf_slice_plotfile = plotfile_base + '_' + slice_type + '_xz_plane' + plot_fadd + plot_exten
        vf_slice_plotfile = plotfile_base + '_' + slice_type + '_yz_plane' + plot_fadd + plot_exten
        uv_slice_plotfile = plotfile_base + '_' + slice_type + '_xy_plane' + plot_fadd + plot_exten
      endelse
      
      case slice_type of
        'raw': begin
          uf_slice_savefile = file_struct_arr.uf_raw_savefile
          vf_slice_savefile = file_struct_arr.vf_raw_savefile
          uv_slice_savefile = file_struct_arr.uv_raw_savefile
          slice_titles = file_struct_arr.uvf_label
        end
        'divided': begin
          uf_slice_savefile = file_struct_arr.uf_savefile
          vf_slice_savefile = file_struct_arr.vf_savefile
          uv_slice_savefile = file_struct_arr.uv_savefile
          slice_titles = file_struct_arr.uvf_label
        end
        'sumdiff': begin
          uf_slice_savefile = [file_struct_arr.uf_sum_savefile, file_struct_arr.uf_diff_savefile]
          vf_slice_savefile = [file_struct_arr.vf_sum_savefile, file_struct_arr.vf_diff_savefile]
          uv_slice_savefile = [file_struct_arr.uv_sum_savefile, file_struct_arr.uv_diff_savefile]
          slice_titles = ['sum ' + file_struct_arr.file_label, 'diff ' + file_struct_arr.file_label]
        end
        'kspace': begin
          uf_slice_savefile = file_struct_arr.savefile_froot + file_struct_arr.savefilebase + '_xz_plane.idlsave'
          vf_slice_savefile = file_struct_arr.savefile_froot + file_struct_arr.savefilebase + '_yz_plane.idlsave'
          uv_slice_savefile = file_struct_arr.savefile_froot + file_struct_arr.savefilebase + '_xy_plane.idlsave'
          slice_titles = file_struct_arr.file_label
        end
      endcase
    endif else begin
      case slice_type of
        'raw': slice_titles = file_struct_arr.uvf_label
        'divided': slice_titles = file_struct_arr.uvf_label
        'sumdiff': slice_titles = ['sum ' + file_struct_arr.file_label, 'diff ' + file_struct_arr.file_label]
        'kspace': slice_titles = file_struct_arr.file_label
      endcase
    endelse
  endif
  
  if keyword_set(plot_wedge_line) then begin
    z0_freq = 1420.40 ;; MHz
    redshifts = z0_freq/file_struct_arr[0].frequencies - 1
    mean_redshift = mean(redshifts)
    
    cosmology_measures, mean_redshift, wedge_factor = wedge_factor
    ;; assume 20 degrees from pointing center to first null
    source_dist = 20d * !dpi / 180d
    fov_amp = wedge_factor * source_dist
    
    ;; calculate angular distance to horizon
    horizon_amp = wedge_factor * ((file_struct_arr[0].max_theta+90d) * !dpi / 180d)
    
    wedge_amp = [fov_amp, horizon_amp]
  endif else wedge_amp = 0d
  
  if keyword_set(pub) then font = 1 else font = -1
  
  if keyword_set(pub) and keyword_set(individual_plots) then begin
    for i=0, n_cubes-1 do kpower_2d_plots, savefiles_2d[i], png = png, eps = eps, plotfile = plotfiles_2d[i], $
      kperp_plot_range = kperp_plot_range, kpar_plot_range = kpar_plot_range, $
      data_range = data_range, title_prefix = titles[i], grey_scale = grey_scale, $
      plot_wedge_line = plot_wedge_line, hinv = hinv, $
      wedge_amp = wedge_amp, baseline_axis = baseline_axis, delay_axis = delay_axis, $
      kperp_linear_axis = kperp_linear_axis, kpar_linear_axis = kpar_linear_axis
      
    for i=0, npol -1 do kpower_2d_plots, savefiles_2d[i], /plot_sigma, png = png, eps = eps, plotfile = plotfiles_2d_error[i],$
      kperp_plot_range = kperp_plot_range, kpar_plot_range = kpar_plot_range, $
      data_range = sigma_range, title_prefix = pol_inc[i], $
      grey_scale = grey_scale, plot_wedge_line = plot_wedge_line, hinv = hinv, $
      wedge_amp = wedge_amp, baseline_axis = baseline_axis, delay_axis = delay_axis, $
      kperp_linear_axis = kperp_linear_axis, kpar_linear_axis = kpar_linear_axis
      
    for i=0, npol -1 do kpower_2d_plots, savefiles_2d[i], /plot_exp_noise, png = png, eps = eps, plotfile = plotfiles_2d_noise_expval[i],$
      kperp_plot_range = kperp_plot_range, kpar_plot_range = kpar_plot_range, $
      data_range = nev_range, title_prefix = pol_inc[i], $
      grey_scale = grey_scale, plot_wedge_line = plot_wedge_line, hinv = hinv, $
      wedge_amp = wedge_amp, baseline_axis = baseline_axis, delay_axis = delay_axis, $
      kperp_linear_axis = kperp_linear_axis, kpar_linear_axis = kpar_linear_axis
      
      
    for i=0, n_cubes-1 do kpower_2d_plots, savefiles_2d[i], png = png, eps = eps, /snr, plotfile = plotfiles_2d_snr[i], $
      kperp_plot_range = kperp_plot_range, kpar_plot_range = kpar_plot_range, $
      data_range = snr_range, title_prefix = titles[i], $
      grey_scale = grey_scale, plot_wedge_line = plot_wedge_line, hinv = hinv, $
      wedge_amp = wedge_amp, baseline_axis = baseline_axis, delay_axis = delay_axis, $
      kperp_linear_axis = kperp_linear_axis, kpar_linear_axis = kpar_linear_axis
      
    if nfiles eq 2 then begin
      for i=0, n_cubes-1 do kpower_2d_plots, savefiles_2d[i], png = png, eps = eps, /plot_noise, plotfile = plotfiles_2d_noise[i], $
        kperp_plot_range = kperp_plot_range, kpar_plot_range = kpar_plot_range, $
        data_range = noise_range, title_prefix = titles[i], $
        grey_scale = grey_scale, plot_wedge_line = plot_wedge_line, hinv = hinv, $
        wedge_amp = wedge_amp, baseline_axis = baseline_axis, delay_axis = delay_axis, $
        kperp_linear_axis = kperp_linear_axis, kpar_linear_axis = kpar_linear_axis
        
      for i=0, n_cubes-1 do kpower_2d_plots, savefiles_2d[i], png = png, eps = eps, /nnr, plotfile = plotfiles_2d_nnr[i], $
        kperp_plot_range = kperp_plot_range, kpar_plot_range = kpar_plot_range, $
        data_range = nnr_range, title_prefix = titles[i], $
        grey_scale = grey_scale, plot_wedge_line = plot_wedge_line, hinv = hinv, $
        wedge_amp = wedge_amp, baseline_axis = baseline_axis, delay_axis = delay_axis, $
        kperp_linear_axis = kperp_linear_axis, kpar_linear_axis = kpar_linear_axis
    endif
  endif else begin
  
    if keyword_set(kperp_linear_axis) then begin
      ;; aspect ratio doesn't work out for kperp_linear with multiple rows
      ncol = ntype*npol
      nrow = 1
    endif else begin
      ncol = ntype
      nrow = npol
    endelse
    start_multi_params = {ncol:ncol, nrow:nrow, ordering:'row'}
    
    window_num = 1
    for i=0, n_cubes-1 do begin
      if i gt 0 then  pos_use = positions[*,i]
      
      kpower_2d_plots, savefiles_2d[i], multi_pos = pos_use, start_multi_params = start_multi_params, png = png, eps = eps, $
        plotfile = plotfiles_2d, kperp_plot_range = kperp_plot_range, kpar_plot_range = kpar_plot_range, $
        data_range = data_range, title_prefix = titles[i], grey_scale = grey_scale, $
        plot_wedge_line = plot_wedge_line, hinv = hinv, $
        wedge_amp = wedge_amp, baseline_axis = baseline_axis, delay_axis = delay_axis, $
        kperp_linear_axis = kperp_linear_axis, kpar_linear_axis = kpar_linear_axis, window_num = window_num
        
      if i eq 0 then begin
        positions = pos_use
        undefine, start_multi_params
      endif
    endfor
    undefine, positions, pos_use
    if keyword_set(pub) then begin
      cgps_close, png = png, delete_ps = delete_ps
      wdelete, window_num
    endif
    
    if keyword_set(kperp_linear_axis) then begin
      ;; aspect ratio doesn't work out for kperp_linear with multiple rows
      ncol = 2*npol
      nrow = 1
    endif else begin
      ncol = 2
      nrow = npol
    endelse
    start_multi_params = {ncol:ncol, nrow:nrow, ordering:'row'}
    
    window_num = 2
    for i=0, npol*2-1 do begin
      if i gt 0 then pos_use = positions[*,i]
      
      pol_ind = i / 2
      
      if i mod 2 eq 0 then $
        kpower_2d_plots, savefiles_2d[pol_ind], multi_pos = pos_use, start_multi_params = start_multi_params, png = png, eps = eps, $
        plotfile = plotfiles_2d_error, /plot_sigma, data_range = sigma_range, $
        kperp_plot_range = kperp_plot_range, kpar_plot_range = kpar_plot_range, $
        title_prefix = pol_inc[pol_ind], grey_scale = grey_scale, $
        plot_wedge_line = plot_wedge_line, wedge_amp = wedge_amp, hinv = hinv, baseline_axis = baseline_axis, $
        delay_axis = delay_axis, kperp_linear_axis = kperp_linear_axis, kpar_linear_axis = kpar_linear_axis, $
        window_num = window_num $
      else kpower_2d_plots, savefiles_2d[pol_ind], multi_pos = pos_use, start_multi_params = start_multi_params, $
      png = png, eps = eps, /plot_exp_noise, kperp_plot_range = kperp_plot_range, kpar_plot_range = kpar_plot_range, $
      data_range = nev_range, title_prefix = pol_inc[pol_ind], $
      grey_scale = grey_scale, plot_wedge_line = plot_wedge_line, hinv = hinv, $
      wedge_amp = wedge_amp, baseline_axis = baseline_axis, delay_axis = delay_axis, $
      kperp_linear_axis = kperp_linear_axis, kpar_linear_axis = kpar_linear_axis
    if i eq 0 then begin
      positions = pos_use
      undefine, start_multi_params
    endif
  endfor
  undefine, positions, pos_use
  if keyword_set(pub) then begin
    cgps_close, png = png, delete_ps = delete_ps
    wdelete, window_num
  endif
  
  
  ;; now plot SNR -- no separate sigma plots
  if keyword_set(kperp_linear_axis) then begin
    ;; aspect ratio doesn't work out for kperp_linear with multiple rows
    ncol = ntype*npol
    nrow = 1
  endif else begin
    ncol = ntype
    nrow = npol
  endelse
  start_multi_params = {ncol:ncol, nrow:nrow, ordering:'row'}
  
  window_num = 3
  ;;snr_range = [1e0, 1e6]
  for i=0, n_cubes-1 do begin
    if i gt 0 then  pos_use = positions[*,i]
    
    kpower_2d_plots, savefiles_2d[i], /snr, multi_pos = pos_use, start_multi_params = start_multi_params, png = png, eps = eps, $
      plotfile = plotfiles_2d_snr, $
      kperp_plot_range = kperp_plot_range, kpar_plot_range = kpar_plot_range, data_range = snr_range, $
      title_prefix = titles[i], grey_scale = grey_scale, plot_wedge_line = plot_wedge_line, wedge_amp = wedge_amp, $
      hinv = hinv, baseline_axis = baseline_axis, delay_axis = delay_axis, kperp_linear_axis = kperp_linear_axis, $
      kpar_linear_axis = kpar_linear_axis, window_num = window_num
    if i eq 0 then begin
      positions = pos_use
      undefine, start_multi_params
    endif
  endfor
  undefine, positions, pos_use
  if keyword_set(pub) then begin
    cgps_close, png = png, delete_ps = delete_ps
    wdelete, window_num
  endif
  
  if nfiles eq 2 then begin
  
    window_num = 4
    start_multi_params = {ncol:ncol, nrow:nrow, ordering:'row'}
    
    ;;noise_range = [1e18, 1e22]
    for i=0, n_cubes-1 do begin
      if i gt 0 then  pos_use = positions[*,i]
      
      kpower_2d_plots, savefiles_2d[i], /plot_noise, multi_pos = pos_use, start_multi_params = start_multi_params, png = png, eps = eps, $
        plotfile = plotfiles_2d_noise, $
        kperp_plot_range = kperp_plot_range, kpar_plot_range = kpar_plot_range, data_range = noise_range, $
        title_prefix = titles[i], grey_scale = grey_scale, $
        plot_wedge_line = plot_wedge_line, wedge_amp = wedge_amp, hinv = hinv, $
        baseline_axis = baseline_axis, delay_axis = delay_axis, kperp_linear_axis = kperp_linear_axis, $
        kpar_linear_axis = kpar_linear_axis, window_num = window_num
      if i eq 0 then begin
        positions = pos_use
        undefine, start_multi_params
      endif
    endfor
    if keyword_set(pub) then begin
      cgps_close, png = png, delete_ps = delete_ps
      wdelete, window_num
    endif
    
    window_num = 5
    start_multi_params = {ncol:ncol, nrow:nrow, ordering:'row'}
    undefine, pos_use
    
    for i=0, n_cubes-1 do begin
      if i gt 0 then  pos_use = positions[*,i]
      
      kpower_2d_plots, savefiles_2d[i], /nnr, multi_pos = pos_use, start_multi_params = start_multi_params, png = png, eps = eps, $
        plotfile = plotfiles_2d_nnr, $
        kperp_plot_range = kperp_plot_range, kpar_plot_range = kpar_plot_range, data_range = nnr_range, $
        title_prefix = titles[i], $
        grey_scale = grey_scale, plot_wedge_line = plot_wedge_line, wedge_amp = wedge_amp, hinv = hinv, $
        baseline_axis = baseline_axis, delay_axis = delay_axis, kperp_linear_axis = kperp_linear_axis, $
        kpar_linear_axis = kpar_linear_axis, window_num = window_num
      if i eq 0 then begin
        positions = pos_use
        undefine, start_multi_params
      endif
    endfor
    if keyword_set(pub) then begin
      cgps_close, png = png, delete_ps = delete_ps
      wdelete, window_num
    endif
    
  endif
  
  if keyword_set(plot_slices) then begin
    nrow = npol
    
    if keyword_set(kperp_linear_axis) then begin
      ;; aspect ratio doesn't work out for kperp_linear with multiple rows
      if slice_type eq 'kspace' then ncol = ntype*npol else ncol = ntype*nfiles*npol
    endif else begin
      if slice_type eq 'kspace' then ncol=ntype else ncol = ntype*nfiles
     endelse
    start_multi_params = {ncol:ncol, nrow:nrow, ordering:'row'}
    
    if slice_type eq 'kspace' then ncol=ntype else ncol = ntype*nfiles
    
    window_num = 7
    start_multi_params = {ncol:ncol, nrow:nrow, ordering:'row'}
    undefine, pos_use
    
    for i=0, (nrow*ncol)-1 do begin
      if i gt 0 then  pos_use = positions[*,i]
      
      if slice_type eq 'kspace' then begin
        kpower_slice_plot, uf_slice_savefile[i], multi_pos = pos_use, start_multi_params = start_multi_params, png = png, eps = eps, $
          plotfile = uf_slice_plotfile, plot_xrange = kperp_plot_range, plot_yrange = kpar_plot_range, $
          title_prefix = slice_titles[i], $
          grey_scale = grey_scale, plot_wedge_line = plot_wedge_line, wedge_amp = wedge_amp, hinv = hinv, $
          baseline_axis = baseline_axis, delay_axis = delay_axis, linear_axes = kperp_linear_axis, $
          window_num = window_num
      endif else begin
      
        uvf_slice_plot, uf_slice_savefile[i], multi_pos = pos_use, start_multi_params = start_multi_params, png = png, eps = eps, $
          plotfile = uf_slice_plotfile, type = 'abs', title_prefix = slice_titles[i], $
          grey_scale = grey_scale, hinv = hinv, $
          baseline_axis = baseline_axis, window_num = window_num
      endelse
      
      if i eq 0 then begin
        positions = pos_use
        undefine, start_multi_params
      endif
    endfor
    if keyword_set(pub) then begin
      cgps_close, png = png, delete_ps = delete_ps
      wdelete, window_num
    endif
    
    window_num = 8
    start_multi_params = {ncol:ncol, nrow:nrow, ordering:'row'}
    undefine, pos_use
    
    for i=0, (nrow*ncol)-1 do begin
      if i gt 0 then  pos_use = positions[*,i]
      
      if slice_type eq 'kspace' then begin
        kpower_slice_plot, vf_slice_savefile[i], multi_pos = pos_use, start_multi_params = start_multi_params, png = png, eps = eps, $
          plotfile = vf_slice_plotfile, $
          plot_xrange = kperp_plot_range, plot_yrange = kpar_plot_range, $
          title_prefix = slice_titles[i], $
          grey_scale = grey_scale, plot_wedge_line = plot_wedge_line, wedge_amp = wedge_amp, hinv = hinv, $
          baseline_axis = baseline_axis, delay_axis = delay_axis, linear_axes = kperp_linear_axis, $
          window_num = window_num
      endif else begin
      
        uvf_slice_plot, vf_slice_savefile[i], multi_pos = pos_use, start_multi_params = start_multi_params, png = png, eps = eps, $
          plotfile = vf_slice_plotfile, type = 'abs', title_prefix = slice_titles[i], $
          grey_scale = grey_scale, hinv = hinv, $
          baseline_axis = baseline_axis, window_num = window_num
      endelse
      
      if i eq 0 then begin
        positions = pos_use
        undefine, start_multi_params
      endif
    endfor
    if keyword_set(pub) then begin
      cgps_close, png = png, delete_ps = delete_ps
      wdelete, window_num
    endif
    
    window_num = 9
    start_multi_params = {ncol:ncol, nrow:nrow, ordering:'row'}
    undefine, pos_use
    
    for i=0, (nrow*ncol)-1 do begin
      if i gt 0 then  pos_use = positions[*,i]
      
      if slice_type eq 'kspace' then begin
        kpower_slice_plot, uv_slice_savefile[i], multi_pos = pos_use, start_multi_params = start_multi_params, png = png, eps = eps, $
          plotfile = uv_slice_plotfile, $
          plot_xrange = kperp_plot_range, plot_yrange = kperp_plot_range, $
          title_prefix = slice_titles[i], $
          grey_scale = grey_scale, plot_wedge_line = plot_wedge_line, wedge_amp = wedge_amp, hinv = hinv, $
          baseline_axis = baseline_axis, delay_axis = delay_axis, linear_axes = kperp_linear_axis, $
          window_num = window_num
      endif else begin
      
        uvf_slice_plot, uv_slice_savefile[i], multi_pos = pos_use, start_multi_params = start_multi_params, png = png, eps = eps, $
          plotfile = uv_slice_plotfile, type = 'abs', title_prefix = slice_titles[i], $
          grey_scale = grey_scale, hinv = hinv, $
          baseline_axis = baseline_axis, window_num = window_num
      endelse
      
      if i eq 0 then begin
        positions = pos_use
        undefine, start_multi_params
      endif
    endfor
    if keyword_set(pub) then begin
      cgps_close, png = png, delete_ps = delete_ps
      wdelete, window_num
    endif
    
  endif
endelse

file_arr = savefiles_1d
kpower_1d_plots, file_arr, window_num = 6, colors = colors, names = titles, delta = delta, hinv = hinv, png = png, eps = eps, $
  plotfile = plotfile_1d
  
end