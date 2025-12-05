@tool
extends Node
class_name BulkShaderOverride

# This node looks through the assigned parents' children
# and sets values on the shaders of the child nodes.

# REQ: Shader located in MaterialOverride (3D) or Material (2D)
# REQ: Shader uses specifically named properties

# NOTE: Mostly intended to help you easily preview multiple untimed shaders in the editor.


@export var fx_parents : Array[Node] = []
@export_range(0.0,1.0) var override_progress = 0.0 : 
	set(v):
		override_progress = v
		if live_updates: override_values()
@export var override_derive_progress : dpv = dpv.PROGRESS : 
	set(v):
		override_derive_progress = v
		if live_updates: override_values()
@export_range(0.0,8.0) var override_time_scale = 1.0 : 
	set(v):
		override_time_scale = v
		if live_updates: override_values()
@export_tool_button("Push Override","Edit") var ov = override_values

@export_group("Playback")
@export_tool_button("Play","Play") var pf = one_shot.bind(false)
@export_tool_button("Reverse","PlayBackwards") var pb = one_shot.bind(true)
@export_tool_button("Bounce","MirrorX") var bp = bounce
@export_tool_button("Showcase","Camera") var ps = showcase

@export_group("Options")
@export var live_updates := false

enum dpv {
	TIME,
	PROGRESS,
	LIFETIME
}

func override_values() -> void:
	for p in fx_parents:
		for c in p.get_children():
			if c is GeometryInstance3D:
				if c.material_override:
					c.material_override.set_shader_parameter("progress",override_progress)
					c.material_override.set_shader_parameter("derive_progress",override_derive_progress)
					c.material_override.set_shader_parameter("time_scale",override_time_scale)
			
			if c is CanvasItem:
				if c.material:
					c.material.set_shader_parameter("progress",override_progress)
					c.material.set_shader_parameter("derive_progress",override_derive_progress)
					c.material.set_shader_parameter("time_scale",override_time_scale)

func bounce() -> void:
	# Calls one_shot twice to make the effect "bounce"
	if ostw: return
	await one_shot()
	one_shot(true)

func showcase() -> void:
	# Plays one_shot twice at the current speed and then once at 0.2
	if ostw: return
	await one_shot()
	await one_shot()
	one_shot(false,0.2)

var ostw : Tween
func one_shot(reverse := false,speed_scale := 1.0) -> void:
	# Tweens progress to "play" the effect once using
	if ostw: 
		ostw.kill()
		ostw.finished.emit()
		await get_tree().process_frame
	var old_odp := override_derive_progress
	var old_lu := live_updates
	
	override_derive_progress = dpv.PROGRESS
	live_updates = true
	
	ostw = create_tween()
	var pvalue := Vector2(1.0,0.0) if reverse else Vector2(0.0,1.0)
	var duration : float = 1.0 / max(override_time_scale,0.001)
	duration /= max(speed_scale,0.001)
	ostw.tween_property(self,"override_progress",pvalue.y,duration).from(pvalue.x)
	await ostw.finished
	
	override_derive_progress = old_odp
	live_updates = old_lu
	ostw = null
