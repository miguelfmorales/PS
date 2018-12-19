pro ps_ratio_wrapper, folder_names_in, obs_names_in, ps_foldernames=ps_foldernames, $
    exact_obsnames = exact_obsnames,  cube_types = cube_types,  pols = pols, $
    all_pol_diff_ratio = all_pol_diff_ratio, freq_ch_range = freq_ch_range, $
    spec_window_types = spec_window_types, delta_uv_lambda = delta_uv_lambda, $
    full_image = full_image, ave_removal = ave_removal, diff_ratio = diff_ratio, $
    diff_range = diff_range, png = png, eps = eps, pdf = pdf, $
    data_range = data_range, $
    color_type = color_type, invert_colorbar = invert_colorbar, $
    kperp_linear_axis = kperp_linear_axis, $
    kpar_linear_axis = kpar_linear_axis, sim = sim, wt_cutoffs = wt_cutoffs, $
    wt_measures = wt_measures, window_num = window_num, $
    uvf_input = uvf_input, diff_save_path = diff_save_path, plot_path = diff_plot_path

  if n_elements(folder_names_in) gt 2 then message, 'only 1 or 2 folder_names allowed'
  if n_elements(folder_names_in) eq 0 then message, 'at least 1 folder name must be specified'
  if n_elements(obs_names_in) gt 2 then message, 'only 1 or 2 obs_names_in allowed'

  folder_names = get_folder(folder_names_in, loc_name = loc_name,  rts = rts, $
    dirty_folder = dirty_folder)

  obs_info = ps_filenames(folder_names, obs_names_in, dirty_folder = dirty_folder, $
    exact_obsnames = exact_obsnames, rts = rts, sim = sim,  uvf_input = uvf_input, $
    casa = casa, data_subdirs = data_subdirs, ps_foldernames = ps_foldernames, $
    save_paths = save_paths, plot_paths = plot_paths, refresh_info = refresh_info, $
    no_wtvar_rts = no_wtvar_rts)

  if n_elements(diff_plot_path) eq 0 then begin
    if n_elements(diff_save_path) gt 0 then begin
      diff_plot_path = diff_save_path + path_sep() + 'plots' + path_sep()
    endif
  endif

  wh_noinfo = where(obs_info.info_files eq '', count_noinfo)
  if count_noinfo gt 0 then message, 'Info files are not all present'

  if n_elements(data_range) eq 0 then begin
    if n_elements(color_type) gt 0 then begin
      if color_type eq 'linear' then begin
        data_range = [0, 1.2]
      endif
    endif
    if n_elements(data_range) eq 0 then begin
      data_range = [1e-3, 1e1]
    endif
  endif

  if n_elements(delta_uv_lambda) gt 1 then message, 'only 1 delta_uv_lambda allowed'

  if n_elements(max_uv_lambda) lt 2 and n_elements(full_image) lt 2 then begin

    uvf_options0 = create_uvf_options(delta_uv_lambda = delta_uv_lambda, $
      max_uv_lambda = max_uv_lambda, full_image = full_image)

  endif else begin
    case n_elements(max_uv_lambda) of
      0:
      1: begin
        mul0 = max_uv_lambda
        mul1 = max_uv_lambda
      end
      2: begin
        mul0 = max_u_lambda[0]
        mul1 = max_uv_lambda[1]
      end
      else: message, 'only 1 or 2 max_uv_lambda values allowed'
    endcase

    case n_elements(full_image) of
      0:
      1: begin
        fi0 = full_image
        fi1 = full_image
      end
      2: begin
        fi0 = full_image[0]
        fi1 = full_image[1]
      end
      else: message, 'only 1 or 2 full_image values allowed'
    endcase

    uvf_options0 = create_uvf_options(delta_uv_lambda = delta_uv_lambda, $
      max_uv_lambda = mul0, full_image = fi0)
    uvf_options1 = create_uvf_options(delta_uv_lambda = delta_uv_lambda, $
      max_uv_lambda = mul1, full_image = fi1)
  endelse

  if n_elements(ave_removal) lt 2 and n_elements(wt_cutoffs) lt 2 and $
    n_elements(wt_measures) lt 2 and n_elements(spec_window_types) lt 2 then begin

    ps_options = create_ps_options(ave_removal = ave_removal, wt_cutoffs = wt_cutoffs, $
      wt_measures = wt_measures, spec_window_type = spec_window_types)

  endif else begin
    case n_elements(ave_removal) of
      0:
      1: begin
        ar0 = ave_removal
        ar1 = ave_removal
      end
      2: begin
        ar0 = ave_removal[0]
        ar1 = ave_removal[1]
      end
      else: message, 'only 1 or 2 ave_removal values allowed'
    endcase

    case n_elements(wt_cutoffs) of
      0:
      1: begin
        wtc0 = wt_cutoffs
        wtc1 = wt_cutoffs
      end
      2: begin
        wtc0 = wt_cutoffs[0]
        wtc1 = wt_cutoffs[1]
      end
      else: message, 'only 1 or 2 wt_cutoffs allowed'
    endcase

    case n_elements(wt_measures) of
      0:
      1: begin
        wtm0 = wt_measures
        wtm1 = wt_measures
      end
      2: begin
        wtm0 = wt_measures[0]
        wtm1 = wt_measures[1]
      end
      else: message, 'only 1 or 2 wt_measures allowed'
    endcase

    case n_elements(spec_window_types) of
      0:
      1: begin
        spw0 = spec_window_types
        spw1 = spec_window_types
      end
      2: begin
        spw0 = spec_window_types[0]
        spw1 = spec_window_types[1]
      end
      else: message, 'only 1 or 2 spec_window_types allowed'
    endcase

    ps_options0 = create_ps_options(ave_removal = ar0, wt_cutoffs = wtc0, $
      wt_measures = wtm0, spec_window_type = spw0)

    ps_options1 = create_ps_options(ave_removal = ar1, wt_cutoffs = wtc1, $
      wt_measures = wtm1, spec_window_type = spw1)

    ps_options = [ps_options0, ps_options1]
  endelse

  plot_options = create_plot_options(plot_path = diff_plot_path, $
    png = png, eps = eps, pdf = pdf)

  plot_2d_options = create_plot_2d_options(kperp_linear_axis = kperp_linear_axis, $
    kpar_linear_axis = kpar_linear_axis, data_range = data_range, color_type = color_type)

  ps_ratio_plots, folder_names, obs_info, cube_types, ps_foldernames=ps_foldernames, $
    pols, all_pol_diff_ratio = all_pol_diff_ratio, freq_ch_range = freq_ch_range, $
    uvf_options0 = uvf_options0, uvf_options1 = uvf_options1, ps_options = ps_options, $
    plot_options = plot_options, plot_2d_options = plot_2d_options, $
    save_path = diff_save_path, plot_filebase = plot_filebase, $
    diff_ratio = diff_ratio, diff_range = diff_range, invert_colorbar = invert_colorbar, $
    quiet = quiet, window_num = window_num
end
