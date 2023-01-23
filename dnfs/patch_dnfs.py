
with open("dnfs.rom", "rb") as fp:
	data = bytearray(fp.read())
	fp.close()

def patch(data, addr, newbytes):
	offset = addr - 0x8000
	data[offset:offset+len(newbytes)] = newbytes

# Patch the call to OSWORD EA (check Tube presence) and make it just set X to 0xff instead
patch(data, 0xb469, [0xea, 0xa2, 0xff])   # nop : ldx #$ff

# Patch the "sta tube_host_r3_data" calls
for base in (0xad37, 0xadb0):
	patch(data, base, [0x20, 0xd2, 0x00])  # jsr shadow_data_write

# Patch the "lda tube_host_r3_data" calls
for base in (0xad13, 0xadbd):
	patch(data, base, [0x20, 0xd5, 0x00])  # jsr shadow_data_read


with open("supdnfs.rom", "wb") as fp:
	fp.write(data)
	fp.close()

