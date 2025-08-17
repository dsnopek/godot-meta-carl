extends Node

func _ready() -> void:
	var input_sample := CARLInputSample.new()
	var bytes := input_sample.serialize();
	print(bytes)

	var recorder := CARLRecorder.new();
	recorder.start_recording(3)
	print(recorder.is_recording())
	recorder.record_input_sample(input_sample);

	var recording: CARLRecording = recorder.finish_recording()
	print(recorder.is_recording())

	var err = ResourceSaver.save(recording, 'res://new_carl_recording.tres')
	print("Error: ", err)
