extends CanvasLayer

@onready var progress_bar: ProgressBar = %ProgressBar

func update_loading_progress(p_progress: float) -> void:
	progress_bar.value = p_progress * 100.0
