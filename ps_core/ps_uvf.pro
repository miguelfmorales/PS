pro ps_uvf, file_struct, refresh_data = refresh_data, refresh_weight = refresh_weight, $
    refresh_beam = refresh_beam, dft_fchunk = dft_fchunk, freq_ch_range = freq_ch_range, freq_flags = freq_flags, $
    image_window_name = image_window_name, image_window_frac_size = image_window_frac_size, $
    delta_uv_lambda = delta_uv_lambda, max_uv_lambda = max_uv_lambda, no_dft_progress = no_dft_progress
    
  nfiles = n_elements(file_struct.datafile)
  
  for i=0, nfiles-1 do begin
    test_uvf = file_test(file_struct.uvf_savefile[i]) *  (1 - file_test(file_struct.uvf_savefile[i], /zero_length))
    
    test_wt_uvf = file_test(file_struct.uvf_weight_savefile[i]) * (1 - file_test(file_struct.uvf_weight_savefile[i], /zero_length))
    
    if tag_exist(file_struct, 'beam_savefile') then $
      test_beam = file_test(file_struct.beam_savefile[i]) * ( 1- file_test(file_struct.beam_savefile[i], /zero_length)) $
    else test_beam = 1
    
    test_radec_uvf = file_test(file_struct.radec_file) *  (1 - file_test(file_struct.radec_file, /zero_length))
    
    if test_uvf eq 1 and n_elements(freq_flags) ne 0 then begin
      old_freq_mask = getvar_savefile(file_struct.uvf_savefile[i], 'freq_mask')
      if total(abs(old_freq_mask - freq_mask)) ne 0 then test_uvf = 0
    endif
    
    if test_wt_uvf eq 1 and n_elements(freq_flags) ne 0 then begin
      old_freq_mask = getvar_savefile(file_struct.uvf_savefile[i], 'freq_mask')
      if total(abs(old_freq_mask - freq_mask)) ne 0 then test_uvf = 0
    endif
    
    
    if test_uvf eq 0 and not keyword_set(refresh_data) and (n_elements(freq_ch_range) ne 0 or n_elements(freq_flags) ne 0) then begin
      ;; if this is a limited freq. range cube, check for the full cube to avoid redoing the DFT
      full_uvf_file = file_struct.uvf_savefile[i]
      if n_elements(freq_ch_range) ne 0 then full_uvf_file = strjoin(strsplit(full_uvf_file, '_ch[0-9]+-[0-9]+', /regex, /extract))
      if n_elements(freq_flags) ne 0 then full_uvf_file = strjoin(strsplit(full_uvf_file, '_flag[a-z0-9]+', /regex, /extract))
      test_full_uvf = file_test(full_uvf_file) *  (1 - file_test(full_uvf_file, /zero_length))
      
      if test_full_uvf eq 1 then begin
        restore, full_uvf_file
        
        if n_elements(freq_flags) ne 0 then data_cube = data_cube * rebin(reform(freq_mask, 1, 1, n_elements(file_struct.frequencies)), size(data_cube, /dimension), /sample)
        if n_elements(freq_ch_range) ne 0 then data_cube = data_cube[*, *, min(freq_ch_range):max(freq_ch_range)]
        
        if n_elements(freq_flags) gt 0 then begin
          save, file = file_struct.uvf_savefile[i], kx_rad_vals, ky_rad_vals, data_cube, freq_mask, uvf_git_hash
        endif else begin
          save, file = file_struct.uvf_savefile[i], kx_rad_vals, ky_rad_vals, data_cube, uvf_git_hash
        endelse
        undefine, data_cube, uvf_git_hash
        
        test_uvf = 1
      endif ;; endifif full uvf exists
      
    endif ;; endif limited freq range & no matching uvf
    
    if test_wt_uvf eq 0 and not keyword_set(refresh_weight) and (n_elements(freq_ch_range) ne 0 or n_elements(freq_flags) ne 0) then begin
      ;; if this is a limited freq. range cube, check for the full cube to avoid redoing the DFT
      full_uvf_wt_file = file_struct.uvf_weight_savefile[i]
      if n_elements(freq_ch_range) ne 0 then full_uvf_wt_file = strjoin(strsplit(full_uvf_wt_file, '_ch[0-9]+-[0-9]+', /regex, /extract))
      if n_elements(freq_flags) ne 0 then full_uvf_wt_file = strjoin(strsplit(full_uvf_wt_file, '_flag[a-z0-9]+', /regex, /extract))
      test_full_wt_uvf = file_test(full_uvf_wt_file) *  (1 - file_test(full_uvf_wt_file, /zero_length))
      
      if test_full_wt_uvf eq 1 then begin
        restore, full_uvf_wt_file
        
        if n_elements(freq_flags) ne 0 then begin
          flag_arr = rebin(reform(freq_mask, 1, 1, n_elements(file_struct.frequencies)), size(weights_cube, /dimension), /sample)
          weights_cube = weights_cube * flag_arr
          variance_cube = variance_cube * flag_arr
        endif
        
        if n_elements(freq_ch_range) ne 0 then begin
          weights_cube = weights_cube[*, *, min(freq_ch_range):max(freq_ch_range)]
          variance_cube = variance_cube[*, *, min(freq_ch_range):max(freq_ch_range)]
        endif
        
        if n_elements(freq_flags) gt 0 then begin
          save, file = file_struct.uvf_weight_savefile[i], kx_rad_vals, ky_rad_vals, weights_cube, variance_cube, freq_mask, uvf_wt_git_hash
        endif else begin
          save, file = file_struct.uvf_weight_savefile[i], kx_rad_vals, ky_rad_vals, weights_cube, variance_cube, uvf_wt_git_hash
        endelse
        undefine, weights_cube, variance_cube, uvf_wt_git_hash
        
        test_wt_uvf = 1
      endif ;; endif full wt_uvf exists
      
    endif ;; endif limited freq range & no matching wt_uvf
    
    if test_uvf eq 0 or test_wt_uvf eq 0 or test_beam eq 0 or test_radec_uvf eq 0 or keyword_set(refresh_data) or keyword_set(refresh_weight) or keyword_set(refresh_beam) then begin
    
      if datavar eq '' then begin
        ;; working with a 'derived' cube (ie residual cube) that is constructed from uvf_savefiles
      
        test_input_uvf = intarr(2)
        test_input_uvf [0] =  file_test(input_uvf_files[i,0]) *  (1 - file_test(input_uvf_files[i,0], /zero_length))
        test_input_uvf [1] =  file_test(input_uvf_files[i,1]) *  (1 - file_test(input_uvf_files[i,1], /zero_length))
        
        if min(test_input_uvf) eq 1 and (n_elements(freq_ch_range) ne 0 or n_elements(freq_flags) ne 0) then begin
        
          for j=0, 1 do begin
            if test_input_uvf[j] eq 0 then begin
              ;; this is a limited freq. range cube, check for the full cube to avoid redoing the DFT
              full_uvf_file = input_uvf_files[i,j]
              if n_elements(freq_ch_range) ne 0 then full_uvf_file = strjoin(strsplit(full_uvf_file, '_ch[0-9]+-[0-9]+', /regex, /extract))
              if n_elements(freq_flags) ne 0 then full_uvf_file = strjoin(strsplit(full_uvf_file, '_flag[a-z0-9]+', /regex, /extract))
              test_full_uvf = file_test(full_uvf_file) *  (1 - file_test(full_uvf_file, /zero_length))
              
              if test_full_uvf eq 1 then begin
                restore, full_uvf_file
                
                if n_elements(freq_flags) ne 0 then data_cube = data_cube * rebin(reform(freq_mask, 1, 1, n_elements(file_struct.frequencies)), size(data_cube, /dimension), /sample)
                if n_elements(freq_ch_range) ne 0 then data_cube = data_cube[*, *, min(freq_ch_range):max(freq_ch_range)]
                
                if n_elements(freq_flags) gt 0 then begin
                  save, file = input_uvf_files[i,j], kx_rad_vals, ky_rad_vals, data_cube, freq_mask, uvf_git_hash
                endif else begin
                  save, file = input_uvf_files[i,j], kx_rad_vals, ky_rad_vals, data_cube, uvf_git_hash
                endelse
                undefine, data_cube, uvf_git_hash
                
                test_uvf = 1
                
              endif ;; endif test_full_uvf eq 1
            endif;; endif test_input_uvf[j] eq 1
          endfor;; end loop over 2 derived cubes
          
        endif else if min(test_input_uvf) eq 0 then message, 'derived cube but input_uvf cube files do not exist'
        
        dirty_cube = getvar_savefile(input_uvf_files[i,0], input_uvf_varname[i,0])
        kx_dirty = getvar_savefile(input_uvf_files[i,0], 'kx_rad_vals')
        ky_dirty = getvar_savefile(input_uvf_files[i,0], 'ky_rad_vals')
        
        model_cube = getvar_savefile(input_uvf_files[i,1], input_uvf_varname[i,1])
        kx_rad_vals = getvar_savefile(input_uvf_files[i,1], 'kx_rad_vals')
        ky_rad_vals = getvar_savefile(input_uvf_files[i,1], 'ky_rad_vals')
        
        if n_elements(freq_flags) ne 0 then begin
          dirty_freq_mask = getvar_savefile(input_uvf_files[i,0], 'freq_mask')
          model_freq_mask = getvar_savefile(input_uvf_files[i,1], 'freq_mask')
          if total(abs(dirty_freq_mask - freq_mask)) ne 0 then message, 'freq_mask of dirty file does not match current freq_mask'
          if total(abs(model_freq_mask - freq_mask)) ne 0 then message, 'freq_mask of model file does not match current freq_mask'
        endif
        
        if total(abs(kx_rad_vals - kx_dirty)) ne 0 then message, 'kx_rad_vals for dirty and model cubes must match'
        if total(abs(ky_rad_vals - ky_dirty)) ne 0 then message, 'kx_rad_vals for dirty and model cubes must match'
        undefine, kx_dirty, ky_dirty
        
        uvf_git_hash_dirty = getvar_savefile(input_uvf_files[i,0], 'uvf_git_hash')
        uvf_git_hash = getvar_savefile(input_uvf_files[i,1], 'uvf_git_hash')
        if uvf_git_hash_dirty ne uvf_git_hash then print, 'git hashes for dirty and model cubes does not match'
        
        data_cube = temporary(dirty_cube) - temporary(model_cube)
        
        if n_elements(freq_flags) gt 0 then begin
          save, file = file_struct.uvf_savefile[i], kx_rad_vals, ky_rad_vals, data_cube, freq_mask, uvf_git_hash
        endif else begin
          save, file = file_struct.uvf_savefile[i], kx_rad_vals, ky_rad_vals, data_cube, uvf_git_hash
        endelse
        undefine, data_cube, uvf_git_hash
        
      endif else begin ;; endif derived cube
      
        if healpix then begin
          pixel_nums = getvar_savefile(file_struct.pixelfile[0], file_struct.pixelvar[0])
        endif else begin
          data_size = getvar_savefile(file_struct.datafile[i], file_struct.datavar, /return_size)
          data_dims = data_size[1:data_size(0)]
        endelse
        
        pix_ft_struct = choose_pix_ft(file_struct, pixel_nums = pixel_nums, data_dims = data_dims, $
          image_window_name = image_window_name, image_window_frac_size = image_window_frac_size, $
          delta_uv_lambda = delta_uv_lambda, max_uv_lambda = max_uv_lambda)
          
        wh_close = pix_ft_struct.wh_close
        x_use = pix_ft_struct.x_use
        y_use = pix_ft_struct.y_use
        kx_rad_vals = pix_ft_struct.kx_rad_vals
        ky_rad_vals = pix_ft_struct.ky_rad_vals
        
        delta_kperp_rad = pix_ft_struct.delta_kperp_rad
        n_kperp = pix_ft_struct.n_kperp
        
        ;; get beam if needed
        if (test_beam eq 0 or keyword_set(refresh_beam)) and tag_exist(file_struct, 'beam_savefile') then begin
          arr = getvar_savefile(file_struct.beamfile[i], file_struct.beamvar)
          if n_elements(wh_close) ne n_elements(pixel_nums) then arr = arr[wh_close, *]
          if n_elements(freq_ch_range) ne 0 then arr = arr[*, min(freq_ch_range):max(freq_ch_range)]
          if n_elements(freq_flags) ne 0 then arr = arr * rebin(reform(freq_mask, 1, n_elements(file_struct.frequencies)), size(arr, /dimension), /sample)
          
          pixels = pixel_nums[wh_close]
          
          if max(arr) le 1.1 then begin
            ;; beam is peak normalized to 1
            temp = arr * rebin(reform(n_vis_freq[i, *], 1, n_freq), count_close, n_freq, /sample)
          endif else if max(arr) le file_struct.n_obs[i]*1.1 then begin
            ;; beam is peak normalized to 1 for each obs, then summed over obs so peak is ~ n_obs
            temp = (arr/file_struct.n_obs[i]) * rebin(reform(n_vis_freq[i, *], 1, n_freq), count_close, n_freq, /sample)
          endif else begin
            ;; beam is peak normalized to 1 then multiplied by n_vis_freq for each obs & summed
            temp = arr
          endelse
          
          avg_beam = total(temp, 2) / total(n_vis_freq[i, *])
          
          nside = file_struct.nside
          
          git, repo_path = ps_repository_dir(), result=beam_git_hash
          
          save, file=file_struct.beam_savefile[i], avg_beam, pixels, nside, beam_git_hash
          
        endif
        
        ;; do RA/Dec DFT.
        if test_radec_uvf eq 0 or keyword_set(refresh_data) then begin
        
          print, 'calculating DFT for ra/dec values'
          
          if n_elements(nside) eq 0 then nside = file_struct.nside
          if n_elements(pixels) eq 0 then pixels = pixel_nums[wh_close]
          
          ;; get ra/dec values for pixels we're using
          pix2vec_ring,nside,pixels,pix_coords
          vec2ang,pix_coords,pix_dec,pix_ra,/astro
          
          ;; may need to wrap ra values so they are contiguous
          pix_ra_hist = histogram(pix_ra, min=0, max = 359.999, binsize = 1, locations = locs, reverse_indices = pix_ra_ri)
          wh_hist_zero = where(pix_ra_hist eq 0, count_hist_zero)
          if count_hist_zero gt 0 then begin
            ;; doesn't cover full phase range
            ind_diffs = (wh_hist_zero-shift(wh_hist_zero,1))[1:*]
            wh_non_contig = where(ind_diffs ne 1, count_non_contig)
            if count_non_contig gt 0 then begin
              ;; more than one contiguous region. get region lengths so we can take the longest one
              region_lengths = intarr(count_non_contig+1)
              for region_i=0, count_non_contig do begin
                case region_i of
                  0: region_lengths[region_i] = wh_non_contig[region_i] + 1
                  count_non_contig: region_lengths[region_i] = count_hist_zero - (max(wh_non_contig) + 1)
                  else: region_lengths[region_i] = wh_non_contig[region_i] - wh_non_contig[region_i-1]
                endcase
              endfor
              max_region = (where(region_lengths eq max(region_lengths)))[0] ;; take the first longest one (in case 2 of same length)
              if max_region eq 0 then region_start = 0 else region_start = wh_non_contig[max_region-1] + 1
              if max_region eq count_non_contig then region_end = count_hist_zero - 1 else region_end = wh_non_contig[max_region]
              
              region_use = wh_hist_zero[region_start:region_end]
            endif else region_use = wh_hist_zero ;; only one contiguous region, use the whole thing
            
            ;; check to see if the contiguous region is against one edge. if so, no wrapping required!
            if min(region_use) ne 0 and max(region_use) ne 359 then begin
              pix_to_wrap = where(pix_ra gt locs[max(region_use)-1], count_pix_to_wrap)
              if count_pix_to_wrap eq 0 then message, 'something went wrong with figuring out which pixels to wrap'
              pix_ra_wrap = pix_ra
              pix_ra_wrap[pix_to_wrap] = pix_ra[pix_to_wrap] - 360.
              
              pix_ra = pix_ra_wrap
            endif
            
          endif
          
          transform_ra = discrete_ft_2D_fast(x_use, y_use, pix_ra, kx_rad_vals, ky_rad_vals, $
            timing = ft_time, fchunk = dft_fchunk, no_progress = no_dft_progress)
            
          transform_dec = discrete_ft_2D_fast(x_use, y_use, pix_dec, kx_rad_vals, ky_rad_vals, $
            timing = ft_time, fchunk = dft_fchunk, no_progress = no_dft_progress)
            
          ang_resolution = sqrt(3./!pi) * 3600./file_struct.nside * (1./60.) * (!pi/180.)
          pix_area_rad = ang_resolution^2. ;; by definition of ang. resolution in Healpix paper
          ra_k = [[conj(reverse(reverse(transform_ra, 2)))], [transform_ra[*,1:*]]] * pix_area_rad
          dec_k = [[conj(reverse(reverse(transform_dec, 2)))], [transform_dec[*,1:*]]] * pix_area_rad
          
          nshift = ceil(n_kperp/2.)
          ra_img = shift(fft(shift(ra_k, [nshift,nshift])), [nshift,nshift]) * (delta_kperp_rad * n_kperp/(2.*!dpi))^2.
          dec_img = shift(fft(shift(dec_k, [nshift,nshift])), [nshift,nshift]) * (delta_kperp_rad * n_kperp/(2.*!dpi))^2.
          
          if max(abs(imaginary(ra_img))) eq 0 then ra_img = real_part(ra_img)
          if max(abs(imaginary(dec_img))) eq 0 then dec_img = real_part(dec_img)
          
          uvf_git_hash = this_run_git_hash
          save, file = file_struct.radec_file, kx_rad_vals, ky_rad_vals, ra_k, dec_k, ra_img, dec_img, pix_ra, pix_dec, uvf_git_hash
          undefine, uvf_git_hash
          
        endif
        
        ;; Create an image space filter to reduce thrown power via the FFT on hard clips
        if n_elements(image_window_name) ne 0 then begin
          pix_window = image_window(x_use, y_use, image_window_name = image_window_name, fractional_size = image_window_frac_size)
          pix_window = rebin(pix_window, n_elements(wh_close), n_freq, /sample)
        endif else pix_window = fltarr(n_elements(wh_close), n_freq) + 1.
        
        
        if test_uvf eq 0 or keyword_set(refresh_data) then begin
        
          print, 'calculating DFT for ' + file_struct.datavar + ' in ' + file_struct.datafile[i]
          
          time0 = systime(1)
          arr = getvar_savefile(file_struct.datafile[i], file_struct.datavar)
          time1 = systime(1)
          
          if time1 - time0 gt 60 then print, 'Time to restore cube was ' + number_formatter((time1 - time0)/60.) + ' minutes'
          
          if size(arr,/type) eq 6 or size(arr,/type) eq 9 then $
            if max(abs(imaginary(arr))) eq 0 then arr = real_part(arr) else message, 'Data in Healpix cubes is complex.'
          if not healpix then arr = reform(arr, dims[0]*dims[1], n_freq)
          
          if n_elements(wh_close) ne n_elements(pixel_nums) then arr = arr[wh_close, *] * pix_window
          if n_elements(freq_ch_range) ne 0 then arr = arr[*, min(freq_ch_range):max(freq_ch_range)]
          if n_elements(freq_flags) ne 0 then arr = arr * rebin(reform(freq_mask, 1, n_elements(file_struct.frequencies)), size(arr, /dimension), /sample)
          
          transform = discrete_ft_2D_fast(x_use, y_use, arr, kx_rad_vals, ky_rad_vals, $
            timing = ft_time, fchunk = dft_fchunk, no_progress = no_dft_progress)
          data_cube = temporary(transform)
          undefine, arr
          
          uvf_git_hash = this_run_git_hash
          if n_elements(freq_flags) then begin
            save, file = file_struct.uvf_savefile[i], kx_rad_vals, ky_rad_vals, data_cube, freq_mask, uvf_git_hash
          endif else begin
            save, file = file_struct.uvf_savefile[i], kx_rad_vals, ky_rad_vals, data_cube, uvf_git_hash
          endelse
          undefine, data_cube, uvf_git_hash
        endif
        
        
        if test_wt_uvf eq 0 or keyword_set(refresh_weight) then begin
          print, 'calculating DFT for ' + file_struct.weightvar + ' in ' + file_struct.weightfile[i]
          
          time0 = systime(1)
          arr = getvar_savefile(file_struct.weightfile[i], file_struct.weightvar)
          time1 = systime(1)
          
          if time1 - time0 gt 60 then print, 'Time to restore cube was ' + number_formatter((time1 - time0)/60.) + ' minutes'
          
          if size(arr,/type) eq 6 or size(arr,/type) eq 9 then $
            if max(abs(imaginary(arr))) eq 0 then arr = real_part(arr) else message, 'Weights in Healpix cubes is complex.'
          if not healpix then arr = reform(arr, dims[0]*dims[1], n_freq)
          
          if n_elements(wh_close) ne n_elements(pixel_nums) then arr = arr[wh_close, *] * pix_window
          if n_elements(freq_ch_range) ne 0 then arr = arr[*, min(freq_ch_range):max(freq_ch_range)]
          if n_elements(freq_flags) ne 0 then arr = arr * rebin(reform(freq_mask, 1, n_elements(file_struct.frequencies)), size(arr, /dimension), /sample)
          
          transform = discrete_ft_2D_fast(x_use, y_use, arr, kx_rad_vals, ky_rad_vals, $
            timing = ft_time, fchunk = dft_fchunk, no_progress = no_dft_progress)
            
          weights_cube = temporary(transform)
          
          if not no_var then begin
            print, 'calculating DFT for ' + file_struct.variancevar + ' in ' + file_struct.variancefile[i]
            
            time0 = systime(1)
            arr = getvar_savefile(file_struct.variancefile[i], file_struct.variancevar)
            time1 = systime(1)
            
            if time1 - time0 gt 60 then print, 'Time to restore cube was ' + number_formatter((time1 - time0)/60.) + ' minutes'
            
            if size(arr,/type) eq 6 or size(arr,/type) eq 9 then $
              if max(abs(imaginary(arr))) eq 0 then arr = real_part(arr) else  message, 'Variances in Healpix cubes is complex.'
            if not healpix then arr = reform(arr, dims[0]*dims[1], n_freq)
            
            if n_elements(wh_close) ne n_elements(pixel_nums) then arr = arr[wh_close, *] * pix_window^2.
            if n_elements(freq_ch_range) ne 0 then arr = arr[*, min(freq_ch_range):max(freq_ch_range)]
            if n_elements(freq_flags) ne 0 then arr = arr * rebin(reform(freq_mask, 1, n_elements(file_struct.frequencies)), size(arr, /dimension), /sample)
            
            
            transform = discrete_ft_2D_fast(x_use, y_use, arr, kx_rad_vals, ky_rad_vals, $
              timing = ft_time, fchunk = dft_fchunk, no_progress = no_dft_progress)
              
            variance_cube = abs(temporary(transform)) ;; make variances real, positive definite (amplitude)
            undefine, arr
          endif
          
          uvf_wt_git_hash = this_run_git_hash
          
          if n_elements(freq_flags) then begin
            save, file = file_struct.uvf_weight_savefile[i], kx_rad_vals, ky_rad_vals, weights_cube, variance_cube, freq_mask, uvf_wt_git_hash
          endif else begin
            save, file = file_struct.uvf_weight_savefile[i], kx_rad_vals, ky_rad_vals, weights_cube, variance_cube, uvf_wt_git_hash
          endelse
          undefine, new_pix_vec, pix_window, weights_cube, variance_cube, uvf_wt_git_hash
        endif
      endelse
    endif
  endfor
  
end