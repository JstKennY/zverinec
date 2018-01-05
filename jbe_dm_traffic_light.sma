#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <jbe_core>

#define TASK_COLOR_CHANGE 			125125
#define MP3_SOUND 					"sound/egoist/jb/days_mode/ujbl_dm_traffic/ujbl_dm_traffic.mp3"

new g_iGameID, g_iTimer, g_iSyncHud, bool: g_bGameStart, g_iColor;
new const g_szColor[3][] = { "Красный", "Жёлтый", "Зелёный" };
new const g_IdColor[2][3] = { 
	{255, 255, 0},		// x
	{0, 255, 128}		// y
};

new HamHook:g_iHamHookForwards[13];

new const g_szHamHookEntityBlock[][] = {
	"func_vehicle", "func_tracktrain", "func_tank", "game_player_hurt", "func_recharge", "func_healthcharger", 
	"game_player_equip", "player_weaponstrip", "trigger_hurt", "trigger_gravity", "armoury_entity", "weaponbox",
	"weapon_shield"
};

public plugin_precache() precache_generic(MP3_SOUND); 

public plugin_init() {
	register_plugin("[JBE_DM] Traffic light", "1.1", "ToJI9IHGaa");
		
	new i;
	for(i = 0; i <= 7; i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Use, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", false));
	for(i = 8; i <= 12; i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Touch, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", false));
	
	register_clcmd("drop", "ClCmd_Drop");
	g_iGameID = jbe_register_day_mode("JBE_DAY_MODE_TRAFFIC_LIGHT", 0, 180);

	register_menucmd(register_menuid("Show_TrafficLightMenu"), (1<<0|1<<1|1<<2), "Handle_TrafficLightMenu");

	g_iSyncHud = CreateHudSyncObj();
}

public ClCmd_Drop() {
	if(g_bGameStart) return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE;
}

public HamHook_EntityBlock() return HAM_SUPERCEDE;

public jbe_day_mode_start(iDayMode, iWinTeam) {
	if(iDayMode == g_iGameID) {
		g_bGameStart = true;
		g_iTimer = 6;
		set_task(1.0, "ChangeTLColor", TASK_COLOR_CHANGE, _, _, "a", g_iTimer);
		for(new i; i < sizeof(g_iHamHookForwards); i++) EnableHamForward(g_iHamHookForwards[i]);
		client_cmd(0, "mp3 play %s", MP3_SOUND);
		for(new id = 1; id <= MaxClients; id++) {
			if(is_user_connected(id) && is_user_alive(id)) {
				rg_remove_all_items(id, false);
				if(jbe_get_user_team(id) == 2) {
					rg_set_user_takedamage(id, true);
					rg_give_item(id, "weapon_awp", GT_APPEND);
					rg_set_user_bpammo(id, WEAPON_AWP, 999);
					rg_give_item(id, "weapon_deagle", GT_APPEND);
					rg_set_user_bpammo(id, WEAPON_DEAGLE, 999);
				}
				rg_set_user_gravity(id, 0.6);
				rg_set_user_maxspeed(id, 400.0);
			}
		}
	}
}

public ChangeTLColor() {
	if(--g_iTimer) {
		if(!g_bGameStart) {
			if(task_exists(TASK_COLOR_CHANGE)) remove_task(TASK_COLOR_CHANGE);
			return;
		}
		set_hudmessage(102, 69, 0, -1.0, 0.16, 0, 0.0, 0.9, 0.1, 0.1, -1);
		ShowSyncHudMsg(0, g_iSyncHud, "Смена цвета через: %d", g_iTimer);
	}
	else {
		if(!g_bGameStart) return;
		g_iColor = random_num(0, 2);
		for(new id = 1; id <= MaxClients; id++) {
			if(!is_user_connected(id) || !is_user_alive(id)) continue;
			switch(jbe_get_user_team(id)) {
				case 1: {
					rg_set_user_takedamage(id, true);
					rg_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 0);
					Show_TrafficLightMenu(id);
				}
				case 2: {
					rg_set_user_rendering(id, kRenderFxGlowShell, g_IdColor[0][g_iColor], g_IdColor[1][g_iColor], 0, kRenderNormal, 0);
					client_print_color(id, print_team_blue, "^1[^4INFO^1] Цвет который убивать нельзя: ^4%s", g_szColor[g_iColor]);
				}
			}
		}
		g_iTimer = 11;
		set_task(1.0, "ChangeTLColor", TASK_COLOR_CHANGE, _, _, "a", g_iTimer);
		client_cmd(0, "spk items/nvg_off.wav");
	}
}

public Show_TrafficLightMenu(id) {
	jbe_informer_offset_up(id);
	new szMenu[512], iKeys = (1<<0|1<<1|1<<2), iLen = formatex(szMenu, charsmax(szMenu), "\d[\r!\d]\w Выбирай цвет \rсветофора\w!!^n\d[\r!\d]\w У Вас есть \r5 секунд.^n^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[1]\r ~\w Красный^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[2]\r ~\w Жёлтый^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[3]\r ~\w Зелённый^n");
	show_menu(id, iKeys, szMenu, 5, "Show_TrafficLightMenu");
}

public Handle_TrafficLightMenu(id, iKey) {
	rg_set_user_rendering(id, kRenderFxGlowShell, g_IdColor[0][iKey], g_IdColor[1][iKey], 0, kRenderNormal, 0);
	if(g_iColor == iKey) rg_set_user_takedamage(id, false);
	client_print_color(id, print_team_blue, "^1[^4INFO^1] Вы выбрали цвет: ^4%s", g_szColor[iKey]);
	return PLUGIN_HANDLED;
}

public jbe_day_mode_ended(iDayMode, iWinTeam) {
	if(iDayMode == g_iGameID) {
		for(new i = 0; i < sizeof(g_iHamHookForwards); i++) DisableHamForward(g_iHamHookForwards[i]);
		for(new id = 1; id <= MaxClients; id++) {
			if(is_user_alive(id) && is_user_connected(id) && jbe_get_user_team(id) == 2) ExecuteHamB(Ham_Killed, id, id, 0);
		}
		g_bGameStart = false;
		client_cmd(0, "mp3 stop");
	}
}

stock rg_set_user_takedamage(const player, bool:take = true) {
	set_entvar(player, var_takedamage, take ? DAMAGE_NO : DAMAGE_AIM);
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

stock rg_set_user_maxspeed(const player, Float:speed = -1.0) {
	if(speed != -1.0) set_entvar(player, var_maxspeed, Float:speed);
	else rg_reset_maxspeed(player);
}