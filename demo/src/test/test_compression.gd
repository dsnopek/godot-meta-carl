extends Control

func _ready() -> void:

	var definition = load("res://src/test/carl_full_playback.tres")
	var data = definition.examples[0].recording.data

	print("Uncompressed: ", data.size())

	test_compression(data, FileAccess.COMPRESSION_FASTLZ)
	test_compression(data, FileAccess.COMPRESSION_DEFLATE)
	test_compression(data, FileAccess.COMPRESSION_ZSTD)
	test_compression(data, FileAccess.COMPRESSION_GZIP)
	#test_compression(data, FileAccess.COMPRESSION_BROTLI)


func test_compression(p_data: PackedByteArray, p_mode: int) -> void:
	var cstart := Time.get_ticks_usec()
	var cdata = p_data.compress(p_mode)
	var cdelta := Time.get_ticks_usec() - cstart

	var dstart := Time.get_ticks_usec()
	var ddata = cdata.decompress(p_data.size(), p_mode)
	var ddelta := Time.get_ticks_usec() - dstart

	assert(p_data == ddata)

	print("Mode: %s | Size: %s | Compression Time: %s | Decompression Time: %s" % [p_mode, cdata.size(), cdelta, ddelta])
