function getvar_savefile, savefile, varname, pointer_return=pointer_return
  savefile_obj = obj_new('idl_savefile', savefile)
  savefile_obj->Restore, varname
  obj_destroy, savefile_obj

  IF Keyword_Set(pointer_return) THEN p=execute(varname+'=Ptr_new('+varname+')')
  q=execute('return,'+varname) 
end

