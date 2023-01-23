
#if shadow_data_byte <> $c0
#echo ERROR: shadow_data_byte should be at $c0
#print shadow_data_byte
	jmp builderror
#endif


#if shadow_stubs_end > shadow_zpvars
#echo ERROR: Shadow stubs extend beyond shadow_zpvars
#print shadow_stubs_end
#print shadow_zpvars
	jmp builderror
#endif


#if normal_stubs_end > $40
#echo ERROR: Normal stubs extend beyond $40
#print normal_stubs_end
	jmp builderror
#endif


#if shadowos_top > $ffb9
#echo ERROR: Shadow OS extends beyond $ffb9
#print shadowos_top
	jmp builderror
#endif

#if lang_ws_end > $700
#echo ERROR: Normal routines in language workspace extend beyond $700
#print lang_ws_end
	jmp builderror
#endif
