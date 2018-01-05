#include <amxmodx>
#include <engine>
#include <hamsandwich>
#include <reapi>
#include <jbe_core>

#pragma semicolon 1

#define MsgId_ScreenFade 98
#define TASK_AMBIENCE_SOUND 124567
#define TASK_Go_Shturm 785684

new g_iDayModeShturm, bool:g_bDayModeStatus, g_TimeGoShturm, g_iHudShow, HamHook:g_iHamHookForwards[13];
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

new HookChain:g_PlayerKilledHook;

public plugin_precache() precache_generic("sound/jb_engine/days_mode/shturm/shturm_ae_040317.mp3");

public plugin_init() {
	register_plugin("[JBE_DM] Ghosts", "1.1", "Freedo.m");
	new i;
	for(i = 0; i <= 7; i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Use, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", false));
	for(i = 8; i <= 12; i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Touch, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", false));
	DisableHookChain(g_PlayerKilledHook = RegisterHookChain(RG_CBasePlayer_Killed, "Player_Killed_Post", true));
	register_clcmd("drop", "ClCmd_Drop");
	g_iDayModeShturm = jbe_register_day_mode("JBE_DAY_MODE_SHTURM", 0, 180);
	g_iHudShow = CreateHudSyncObj();
}

public HamHook_EntityBlock() return HAM_SUPERCEDE;
public Player_Killed_Post(iVictim) {
	if(jbe_get_user_team(iVictim) == 2) rg_set_user_rendering(iVictim, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
}

public ClCmd_Drop() {
	if(g_bDayModeStatus) return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE;
}

public jbe_day_mode_start(iDayMode, iAdmin) {
	if(iDayMode == g_iDayModeShturm) {
		for(new i = 1; i <= MaxClients; i++) {
			if(!is_user_alive(i)) continue;
			switch(jbe_get_user_team(i)) {
				case 1: {
					rg_remove_all_items(i, false);
					rg_give_item(i, "weapon_m4a1", GT_APPEND);
					rg_set_user_bpammo(i, WEAPON_M4A1, 200);
					rg_give_item(i, "weapon_ak47", GT_APPEND);
					rg_set_user_bpammo(i, WEAPON_AK47, 200);
					rg_give_item(i, "item_assaultsuit", GT_APPEND);
					rg_set_user_health(i, 120.0);
					rg_set_user_freeze(i, true);
					rg_set_user_takedamage(i, true);
					UTIL_ScreenFade(i, 0, 0, 4, 0, 0, 0, 255);
				}
				case 2: {
					rg_remove_all_items(i, false);
					rg_give_item(i, "weapon_m4a1", GT_APPEND);
					rg_set_user_bpammo(i, WEAPON_M4A1, 200);
					rg_give_item(i, "weapon_ak47", GT_APPEND);
					rg_set_user_bpammo(i, WEAPON_AK47, 200);
					rg_give_item(i, "item_assaultsuit", GT_APPEND);
					rg_set_user_health(i, 350.0);
					rg_set_user_maxspeed(i, 320.0);
				}
			}
		}
		for(new i; i < sizeof(g_iHamHookForwards); i++) EnableHamForward(g_iHamHookForwards[i]);
		EnableHookChain(g_PlayerKilledHook);
		set_lights("d"), g_TimeGoShturm = 23;
		jbe_dm_ambience_sound_task(), freezetimeron();
		g_bDayModeStatus = true;
	}
}
public freezetimeron() set_task(1.0, "jbe_go_shturm", TASK_Go_Shturm, _, _, "a",g_TimeGoShturm);

public jbe_dm_ambience_sound_task() {
	client_cmd(0, "mp3 play sound/egoist/jb/days_mode/shturm/shturm_ae_040317.mp3");
	set_task(126.0, "jbe_dm_ambience_sound_task", TASK_AMBIENCE_SOUND);
}

public jbe_go_shturm() {
	if(--g_TimeGoShturm) {
		set_hudmessage(160, 255, 50, -1.0, 0.16, 0, 0.0, 0.9, 0.1, 0.1, -1);
		ShowSyncHudMsg(0, g_iHudShow, "У охраны %d секунд, чтобы занять оборону!", g_TimeGoShturm);
	}
	else {
		remove_task(TASK_Go_Shturm);
		for(new i = 1; i <= MaxClients; i++) {
			if(!is_user_alive(i)) continue;
			if(jbe_get_user_team(i) == 1) {
				UTIL_ScreenFade(i, 0, 0, 0, 0, 0, 0, 0, 1);
				rg_set_user_freeze(i, false);
				rg_set_user_takedamage(i, false);
			}
		}
		set_hudmessage(0, 40, 230, -1.0, 0.16, 0, 0.0, 0.9, 0.1, 0.1, -1);
		ShowSyncHudMsg(0, g_iHudShow, "Заключенные идут на штурм!");
		set_lights("d");
	}
}

public jbe_day_mode_ended(iDayMode, iWinTeam) {
	if(iDayMode == g_iDayModeShturm) {
		for(new i; i < sizeof(g_iHamHookForwards); i++) DisableHamForward(g_iHamHookForwards[i]);
		DisableHookChain(g_PlayerKilledHook);
		for(new i = 1; i <= MaxClients; i++) {
			if(is_user_alive(i)) {
				switch(jbe_get_user_team(i)) {
					case 1: rg_remove_all_items(i, false);
					case 2: {
						if(iWinTeam) rg_remove_all_items(i, false);
						else ExecuteHamB(Ham_Killed, i, i, 0);
						rg_set_user_rendering(i, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
					}
				}
			}
		}
		set_lights("#OFF");
		remove_task(TASK_Go_Shturm);
		remove_task(TASK_AMBIENCE_SOUND);
		client_cmd(0, "mp3 stop");
		g_bDayModeStatus = false;
	}
}

stock rg_set_user_maxspeed(const player, Float:speed = -1.0) {
	if(speed != -1.0) set_entvar(player, var_maxspeed, Float:speed);
	else rg_reset_maxspeed(player);
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

stock rg_set_user_health(const player, Float:health) {
	set_entvar(player, var_health, Float:health);
}

stock rg_set_user_freeze(const player, bool:freeze = true) {
	if(freeze) set_entvar(player, var_flags, get_entvar(player, var_flags) | FL_FROZEN);
	else set_entvar(player, var_flags, get_entvar(player, var_flags) & ~FL_FROZEN);
}

stock rg_set_user_takedamage(const player, bool:take = true) {
	set_entvar(player, var_takedamage, take ? DAMAGE_NO : DAMAGE_AIM);
}

stock UTIL_ScreenFade(pPlayer, iDuration, iHoldTime, iFlags, iRed, iGreen, iBlue, iAlpha, iReliable = 0) {
	switch(pPlayer) {
		case 0: {
			message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, MsgId_ScreenFade);
			write_short(iDuration);
			write_short(iHoldTime);
			write_short(iFlags);
			write_byte(iRed);
			write_byte(iGreen);
			write_byte(iBlue);
			write_byte(iAlpha);
			message_end();
		}
		default: {
			message_begin(iReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, MsgId_ScreenFade, {0.0, 0.0, 0.0}, pPlayer);
			write_short(iDuration);
			write_short(iHoldTime);
			write_short(iFlags);
			write_byte(iRed);
			write_byte(iGreen);
			write_byte(iBlue);
			write_byte(iAlpha);
			message_end();
		}
	}
}