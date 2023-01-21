; GSINIT and GSREAD would need reimplementing shadow-side, it's not appropriate to
; reflect them to normal mode

gsinithandler:
gsreadhandler:
    jmp unsupported



; More unsupported stuff at the moment

clihandler:
filehandler:
argshandler:
gbpbhandler:
findhandler:
fschandler:
    jmp unsupported

