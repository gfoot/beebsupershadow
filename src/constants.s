; Shadow-to-normal command codes

CMD_OSWORD = 0
CMD_BGET = 1
CMD_RDCH = 2
CMD_VDUCHR = 3
CMD_RESET = 4
CMD_INIT = 5
CMD_CALL = 6
CMD_OSWORD00 = 7

CMD_CLI = $ff
CMD_FILE = $fe
CMD_ARGS = $fd
CMD_GBPB = $fc
CMD_FIND = $fb
CMD_FSC = $fa



; Normal-to-shadow command codes

SCMD_INIT = 0
SCMD_CALL = 1
SCMD_ENTERLANG = 2


; Buffers for shadow-to-normal transfers
normal_inbuffer = $400

; Buffers for normal-to-shadow transfers
shadow_inbuffer = $300



osrdrm = $ffb9
vduchr = $ffbc
osevnt = $ffbf
gsinit = $ffc2
gsread = $ffc5
nvrdch = $ffc8
nvwrch = $ffcb
osfind = $ffce
osgbpb = $ffd1
osbput = $ffd4
osbget = $ffd7
osargs = $ffda
osfile = $ffdd
osrdch = $ffe0
osasci = $ffe3
osnewl = $ffe7
oswrch = $ffee
osword = $fff1
osbyte = $fff4
oscli = $fff7


userv = $0200
brkv = $0202
irq1v = $0204
irq2v = $0206
cliv = $0208
bytev = $020a
wordv = $020c
wrchv = $020e
rdchv = $0210
filev = $0212
argsv = $0214
bgetv = $0216
bputv = $0218
gbpbv = $021a
findv = $021c
fscv = $021e
evntv = $0220
uptv = $0222
netv = $0226
vduv = $0226
keyv = $0228
insv = $022a
remv = $022c
cnpv = $022e
ind1v = $0230
ind2v = $0232
ind3v = $0234


