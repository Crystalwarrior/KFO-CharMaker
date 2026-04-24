extends Resource

## Contains the Emote animation data necessary for the character
class_name Emote

## The modifier value controls pre-animations, sounds, and zooms.
enum EmoteMod {
	## Tells the client to not play the pre-animation or sound effect associated
	## with the emote
	IDLE = 0,
	## Plays the pre-animation and associated sound
	PREANIM = 1,
	## Zoom, in which the foreground desk or witness stand will not be
	## displayed. Additionally, the background is replaced by speed lines.
	ZOOM = 5,
	## Same as Zoom, except it turns on the PREANIM as well.
	ZOOM_PREANIM = 6,
}

## This option allows an emote to either force the desk/witness stand/overlay to
## be displayed, or force it to disappear. This takes precedence over all other
## factors affecting desk visibility.
enum DeskMod {
	## Forcibly hide the overlay while this emote is displayed.
	ALWAYS_HIDE = 0,
	## Forcibly show the overlay while this emote is displayed.
	ALWAYS_SHOW = 1,
	## Hides the overlay during pre-animation, shows it again
	## once the pre-animation is finished
	HIDE_DURING_PRE = 2,
	## Shows the overlay only during the pre-animation, and hides the overlay
	## when the pre-animation ends.
	HIDE_DURING_IDLE = 3,
	## Same as HIDE_DURING_PRE, except the pre-animation will ignore the current
	## character's X/Y Offsets and any the paired characters will be hidden for
	## its duration.
	HIDE_DURING_PRE_AND_CENTER = 4,
	## Same as HIDE_DURING_IDLE, except the pre-animation will ignore the
	## current character's X/Y Offsets and any the paired characters will be
	## hidden for its duration.
	HIDE_DURING_IDLE_AND_CENTER = 5,
}

## Displays in the dropdown menu and on the emote button itself if
## an emote icon for it could not be found.
@export var display_name: String
## the animation played before the character actually starts speaking.
## If there is none, a placeholder `-` is typically used.
@export var pre: String
## What path to use when searching for (a)idle and (b)talking animations
@export var idle: String
## The [EmoteMod] used by the character.
@export var emote_mod: EmoteMod = EmoteMod.IDLE
## The [DeskMod] used by the character.
@export var desk_mod: DeskMod = DeskMod.ALWAYS_SHOW
## The name of the sound effect to use
@export var sound_name: String
## The time to delay playing the sound effect, in 'ticks' (60ms per tick)
@export var sound_time: int = 0
## If the sound should be looping or not
@export var sound_loop: bool = false
## Emote's off button, shown when the emote not selected
@export var image_off: ImageTexture
## Emote's on button, shown when the emote is selected
@export var image_on: ImageTexture

func _init(
		p_display_name: String,
		p_pre: String,
		p_idle: String,
		p_emote_mod: String,
		p_desk_mod: String = "",
):
	display_name = p_display_name
	pre = p_pre
	idle = p_idle
	emote_mod = int(p_emote_mod) as EmoteMod
	if p_desk_mod.is_empty():
		desk_mod = DeskMod.ALWAYS_SHOW
	else:
		desk_mod = int(p_desk_mod) as DeskMod
