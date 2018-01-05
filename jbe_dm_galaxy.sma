#include <amxmodx>
#include <engine>
#include <reapi>
#include <hamsandwich>
#include <jbe_core>

new g_iDayModeCatchUp, HamHook:g_iHamHookForwards[13];
new const g_szHamHookEntityBlock[][] = {
	"func_vehicle", // Управляемая машина
	"func_tracktrain", // Управляемый поезд
	"func_tank", // Управляемая пушка
	"game_player_hurt", // При активации наносит игроку повреждения
	"func_recharge", // Увеличение запаса бронижелета
	"func_healthcharger", // Увеличение процентов здоровья
	"game_player_equip", // Выдаёт оружие
	"player_weaponstrip", // Забирает всё оружие
	"trigger_hurt", // Наносит игроку повреждения
	"trigger_gravity", // Устанавливает игроку силу гравитации
	"armoury_entity", // Объект лежащий на карте, оружия, броня или гранаты
	"weaponbox", // Оружие выброшенное игроком
	"weapon_shield" // Щит
};

/* -> Переменные и массивы для рендеринга -> */
enum _:DATA_RENDERING { RENDER_STATUS, RENDER_FX, RENDER_RED, RENDER_GREEN, RENDER_BLUE, RENDER_MODE, RENDER_AMT };
new g_eUserRendering[MAX_PLAYERS + 1][DATA_RENDERING];
new HookChain:g_PlayerKilledHook;

public plugin_precache() precache_generic("sound/egoist/jb/days_mode/galaxy/galaxy_ae_100317.mp3");

public plugin_init() {
	register_plugin("[JBE_DM] GALAXY", "1.0", "BANTYP");
	new i;
	for(i = 0; i <= 7; i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Use, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", 0));
	for(i = 8; i <= 12; i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Touch, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", 0));
	DisableHookChain(g_PlayerKilledHook = RegisterHookChain(RG_CBasePlayer_Killed, "Player_Killed_Post", true));
		
	g_iDayModeCatchUp = jbe_register_day_mode("JBE_DAY_MODE_GALAXY", 0, 180);
}

public HamHook_EntityBlock() return HAM_SUPERCEDE;

public Player_Killed_Post(iVictim, iKiller) {
	if(get_entvar(iVictim, var_renderfx) != kRenderFxNone || get_entvar(iVictim, var_rendermode) != kRenderNormal) {
		rg_set_user_rendering(iVictim, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
		g_eUserRendering[iVictim][RENDER_STATUS] = false;
	}
}

public jbe_day_mode_start(iDayMode, iAdmin) {
	if(iDayMode == g_iDayModeCatchUp) {
		for(new i = 1; i <= MaxClients; i++) {
			if(!is_user_alive(i)) continue;
			rg_remove_all_items(i, false);
			rg_give_item(i, "weapon_scout", GT_APPEND);
			rg_set_user_bpammo(i, WEAPON_SCOUT, 9999);
			rg_set_user_gravity(i, 0.125);
			rg_set_user_rendering(i, kRenderFxGlowShell, random_num(0, 255), random_num(0, 255), random_num(0, 255), kRenderNormal, 0);
			rg_get_user_rendering(i, g_eUserRendering[i][RENDER_FX], g_eUserRendering[i][RENDER_RED], g_eUserRendering[i][RENDER_GREEN], g_eUserRendering[i][RENDER_BLUE], g_eUserRendering[i][RENDER_MODE], g_eUserRendering[i][RENDER_AMT]);
			g_eUserRendering[i][RENDER_STATUS] = true;
			if(jbe_get_user_team(i) == 2) rg_set_user_health(i, 500.0);	
		}
		for(new i; i < sizeof(g_iHamHookForwards); i++) EnableHamForward(g_iHamHookForwards[i]);
		EnableHookChain(g_PlayerKilledHook);
		set_lights("c");
		client_cmd(0, "mp3 play sound/egoist/jb/days_mode/galaxy/galaxy_ae_100317.mp3");
	}
}

public jbe_day_mode_ended(iDayMode, iWinTeam) {
	if(iDayMode == g_iDayModeCatchUp) {
		client_cmd(0, "mp3 stop");
		set_lights("#OFF");
		new i;
		for(i = 0; i < sizeof(g_iHamHookForwards); i++) DisableHamForward(g_iHamHookForwards[i]);
		DisableHookChain(g_PlayerKilledHook);
		for(i = 1; i <= MaxClients; i++) {
			if(is_user_alive(i) && jbe_get_user_team(i) == 1) {
				if(iWinTeam) rg_remove_all_items(i, false);
				else ExecuteHamB(Ham_Killed, i, i, 0);
				if(get_entvar(i, var_renderfx) != kRenderFxNone || get_entvar(i, var_rendermode) != kRenderNormal) {
					rg_set_user_rendering(i, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
					g_eUserRendering[i][RENDER_STATUS] = false;
				}
			}
		}
	}
}

stock rg_set_user_health(const player, Float:health) {
	set_entvar(player, var_health, Float:health);
}

stock rg_get_user_rendering(index, &fx, &r, &g, &b, &render, &renderamt) {
	new Float:RenderColor[3];
	RenderColor[0] = float(r);
	RenderColor[1] = float(g);
	RenderColor[2] = float(b);

	fx = get_entvar(index, var_renderfx);
	get_entvar(index, var_rendercolor, RenderColor);
	render = get_entvar(index, var_rendermode);
	renderamt = get_entvar(index, var_renderamt);
}

stock rg_set_user_rendering(index, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16) {
	new Float:RenderColor[3];
	RenderColor[0] = float(r);
	RenderColor[1] = float(g);
	RenderColor[2] = float(b);
  
	set_entvar(index, var_renderfx, fx);
	set_entvar(index, var_rendercolor, RenderColor);
	set_entvar(index, var_rendermode, render);
	set_entvar(index, var_renderamt, float(amount));
}

stock rg_set_user_gravity(const player, Float:gravity = 1.0) {
	set_entvar(player, var_gravity, Float:gravity);
}