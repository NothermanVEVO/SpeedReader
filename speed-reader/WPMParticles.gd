extends CPUParticles2D

class_name WPMParticles

const _PLUS_TEXTURE : CompressedTexture2D = preload("res://assets/plus.png")
const _MINUS_TEXTURE : CompressedTexture2D = preload("res://assets/minus.png")
const _COLOR_RAMP : Gradient = preload("res://resources/wpm_particles_color_ramp.tres")

enum Types {PLUS, MINUS}

func _init(type : Types) -> void:
	if type == Types.PLUS:
		texture = _PLUS_TEXTURE
	else:
		texture = _MINUS_TEXTURE
	
	amount = 1
	one_shot = true
	emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	emission_sphere_radius = 40
	gravity.y *= -1
	scale_amount_min = 0.3
	scale_amount_max = 0.8
	color_ramp = _COLOR_RAMP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	finished.connect(_finished)

func _ready() -> void:
	emitting = true

func _finished() -> void:
	queue_free()
