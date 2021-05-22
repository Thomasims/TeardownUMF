#include "core/detouring.lua"
#include "core/hook.lua"
#include "core/util.lua"
#include "core/console_backend.lua"
#include "core/meta.lua"
#include "core/timer.lua"
#include "core/default_hooks.lua"
#include "core/added_hooks.lua"
#include "core/xml.lua"

GLOBAL_CHANNEL = util.shared_channel( "game.umf_global_channel", 128 )
UpdateQuickloadPatch()
