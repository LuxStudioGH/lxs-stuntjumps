fx_version 'cerulean'
game 'gta5'

author 'LuxStudio'
description 'This script brings the classic GTA stunt jump experience to your FiveM server with a competitive side!. Players can find stunt jumps, compete for the fastest times and highest air, and climb the global leaderboards.'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config/cfg_main.lua',
    'config/cfg_rewards.lua',
    'locales/*.lua' 
}

server_scripts {
	'@mysql-async/lib/MySQL.lua',
    'server/sv_perms.lua',
    'server/sv_editor.lua',
    'server/sv_*.lua'
}

client_scripts {
    'client/cl_main.lua',
    'client/cl_editor.lua',
    'client/cl_*.lua' 
}

ui_page 'html/index.html'

files {
    'jumps.json',
    'html/index.html',
    'html/script.js'
}