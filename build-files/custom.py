# custom.py
target="template_release"
debug_symbols="no"
optimize="size_extra" # Godot >4.5 only. Otherwise, use optimize="size"
lto="full" # Much slower build times, smaller export size

disable_3d="yes"
# disable_advanced_gui="yes"

deprecated="no"  # Disables deprecated features
vulkan="no"      # Disables the Vulkan driver (used in Forward+/Mobile Renderers)
use_volk="no"    # Disables more Vulkan stuff
openxr="no"      # Disables Virtual Reality/Augmented Reality stuff
graphite="no"    # Disables SIL Graphite smart fonts support
minizip="yes"    # Enables ZIP archive support

# modules_enabled_by_default="no"     # Disables all modules so you can only enable what you need
# module_gdscript_enabled="yes"
# module_text_server_fb_enabled="yes" # Fallback text server; less features but works fine for English.
# module_freetype_enabled="yes"       # Needed alongside a text server for text to render correctly
# module_svg_enabled="yes"
# module_webp_enabled="yes"
# module_godot_physics_2d_enabled="yes"

# These next few options were introduced in Godot 4.5!
disable_navigation_2d="yes"
disable_navigation_3d="yes"
disable_xr="yes"
accesskit="no" # Disables the new accessibility features
