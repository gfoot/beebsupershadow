#! python

# Adds a file to a ROM that already contains RFS data

import crcmod
import sys

crc16func = crcmod.mkCrcFun(0x11021, initCrc=0, xorOut=0, rev=0)

def bytecrc(data):
	crc = crc16func(data)
	return bytes([(crc >> 8) & 0xff, crc & 0xff])

def int2bytes32(i):
	return bytes([i&0xff, (i>>8)&0xff, (i>>16)&0xff, (i>>24)&0xff])


if len(sys.argv) < 2:
	print("Usage: %s <romimage> <file_to_add...>" % sys.argv[0])
	sys.exit(1)

romfilename = sys.argv[1]

with open(romfilename, "r+b") as fp:
	d = fp.read()

	print("ROM image '%s': length=%04x" % (romfilename, len(d)))
	print("")

	alldatastartpos = len(d)-1

	outdata = bytearray()

	for datafilename in sys.argv[2:]:
		with open(datafilename, "rb") as dfp:
			data = dfp.read()
			dfp.close()

		beebfilename = datafilename[:10]
		
		loadaddr = 0
		execaddr = 0

		infdata = None
		try:
			with open(datafilename+".inf", "rb") as ifp:
				infdata = ifp.read()
				ifp.close()
		except FileNotFoundError:
			pass

		if infdata:
			infdata = infdata.split()

			beebfilename = infdata[0]
			if beebfilename.startswith(b"$."):
				beebfilename = beebfilename[2:]

			if len(infdata) > 1:
				loadaddr = int(infdata[1], base=16)
				execaddr = loadaddr
			if len(infdata) > 2:
				execaddr = int(infdata[2], base=16)

		datasize = len(data)
		blocks = (datasize + 255) // 256
		headers = 1 if blocks == 1 else 2

		datapos = 0

		headersize = len(beebfilename) + 21
		totalsize = headersize * headers + datasize + blocks*2 + blocks - headers

		startpos = len(outdata)
		eof = startpos + totalsize

		for block in range(blocks):
			if block == 0 or block == blocks-1:
				headerdata = bytearray()
				headerdata.extend(b'*')
				for c in beebfilename[:10]:
					headerdata.append(c)
				headerdata.append(0)
				headerdata.extend(int2bytes32(loadaddr))
				headerdata.extend(int2bytes32(execaddr))
				headerdata.append(block % 256)
				headerdata.append(block // 256)

				if block == blocks-1:
					headerdata.append(len(data[datapos:]))
					headerdata.append(0)
					headerdata.append(0x80)
				else:
					headerdata.append(0)
					headerdata.append(1)
					headerdata.append(0)

				headerdata.extend(int2bytes32(0x8000 + alldatastartpos + eof))

				headerdata.extend(bytecrc(headerdata[1:]))

				outdata.extend(headerdata)

			else:

				outdata.extend(b'#')

			datablock = data[datapos:datapos+256]
			outdata.extend(datablock)
			outdata.extend(bytecrc(datablock))

			datapos += 256

		#print(outdata)
		assert len(outdata) == eof


		print("  %04x  +%04x  +%x : %s" % (len(d)-1+startpos, len(data), totalsize-len(data), datafilename))

	d = bytearray(d[:len(d)-1]) + outdata + b'+'
	
#	sys.stdout.buffer.write(d)
	ofp = open("out.rom", "wb")
	ofp.write(d)
	ofp.close()


