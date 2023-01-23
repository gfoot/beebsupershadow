
with open("dnfs.rom", "rb") as fp:
	data = bytearray(fp.read())
	fp.close()

def patch(data, addr, oldbytes, newbytes):
	offset = addr - 0x8000
	assert len(oldbytes) == len(newbytes)
	assert list(data[offset:offset+len(newbytes)]) == list(oldbytes)
	data[offset:offset+len(newbytes)] = newbytes

# Patch the call to OSWORD EA (check Tube presence) and make it just set X to 0xff instead
patch(data, 0xb469, [0x20, 0xa6, 0xb9], [0xea, 0xa2, 0xff])   # nop : ldx #$ff

# Patch the "sta tube_host_r3_data" calls
for base in (0xad37, 0xadb0):
	patch(data, base, [0x8d, 0xe5, 0xfe], [0x20, 0xc0, 0x00])  # jsr shadow_data_byte

# Patch the "lda tube_host_r3_data" calls
for base in (0xad13, 0xadbd):
	patch(data, base, [0xad, 0xe5, 0xfe], [0x20, 0xc0, 0x00])  # jsr shadow_data_byte


with open("supdnfs.rom", "wb") as fp:
	fp.write(data)
	fp.close()


for i in range(1,len(data)-1):
	if data[i] == 0xe5 and data[i+1] == 0xfe:
		if data[i-1] == 0x8d:
			type = "write"
		elif data[i-1] == 0xad:
			type = "read"
		else:
			continue

		print("Possible additional Tube %s location: %04x" % (type, 0x8000+i-1))

