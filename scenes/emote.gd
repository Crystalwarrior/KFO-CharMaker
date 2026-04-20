extends Resource
class_name Emote

@export var display_name: String
@export var pre: String
@export var idle: String

enum EmoteMod {
	IDLE = 0,
	PREANIM = 1,
	ZOOM = 5,
	ZOOM_PREANIM = 6
}
@export var emote_mod: EmoteMod = EmoteMod.IDLE

enum DeskMod {
	ALWAYS_HIDE = 0,
	ALWAYS_SHOW = 1,
	HIDE_DURING_PRE = 2,
	HIDE_DURING_IDLE = 3,
	HIDE_DURING_PRE_AND_CENTER = 4,
	HIDE_DURING_IDLE_AND_CENTER = 5,
}
@export var desk_mod: DeskMod = DeskMod.ALWAYS_SHOW

func _init(p_display_name, p_pre, p_idle, p_emote_mod, p_desk_mod = DeskMod.ALWAYS_SHOW):
	display_name = p_display_name
	pre = p_pre
	idle = p_idle
	emote_mod = int(p_emote_mod) as Emote.EmoteMod
	desk_mod = int(p_desk_mod) as Emote.DeskMod
