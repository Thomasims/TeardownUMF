UMF_REQUIRE "hook.lua"
UMF_REQUIRE "hooks_base.lua"
UMF_REQUIRE "hooks_extra.lua"
UMF_REQUIRE "console_backend.lua"

GLOBAL_CHANNEL = util.shared_channel( "game.umf_global_channel", 128 )
