#include "umf/core/detouring.lua"
#include "umf/core/hook.lua"
#include "umf/core/util.lua"
#include "umf/core/console_backend.lua"
#include "umf/core/meta.lua"
#include "umf/core/timer.lua"
#include "umf/core/default_hooks.lua"
#include "umf/core/added_hooks.lua"

GLOBAL_CHANNEL = util.shared_channel("game.umf_global_channel", 128)
UpdateQuickloadPatch()
