#include <amxmodx>
#include <engine>
#include <reapi>
#include <hamsandwich>
#include <jbe_core>

#pragma semicolon 1

#define MsgId_CurWeapon 66
#define MsgId_ScreenFade 98
#define TASK_TIME_HIDE 785689

new g_iDayModeHideAndSeek, bool:g_bDayModeStatus, g_iSyncTimeHide, g_iTimeHideCount, HamHook:g_iHamHookForwards[13];
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

public plugin_precache() precache_generic("sound/egoist/jb/days_mode/hideandseek/pryatki_ae_100317.mp3");

public plugin_init() {
	register_plugin("[JBE_DM] Hide And Seek", "1.1", "Freedo.m");
	new i;
	for(i = 0; i <= 7; i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Use, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", 0));
	for(i = 8; i <= 12; i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Touch, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", 0));
	register_impulse(100, "ClientImpulse100");
	g_iDayModeHideAndSeek = jbe_register_day_mode("JBE_DAY_MODE_HIDE_ADN_SEEK", 0, 180);
	g_iSyncTimeHide = CreateHudSyncObj();
}

public HamHook_EntityBlock() return HAM_SUPERCEDE;
public ClientImpulse100(id) if(g_bDayModeStatus) return;

public jbe_day_mode_start(iDayMode, iAdmin) {
	if(iDayMode == g_iDayModeHideAndSeek) {
		for(new i = 1; i <= MaxClients; i++) {
			if(!is_user_alive(i)) continue;
			switch(jbe_get_user_team(i)) {
				case 1: {
					rg_remove_all_items(i, false);
					rg_give_item(i, "weapon_knife", GT_APPEND);
				}
				case 2: {
					rg_remove_all_items(i, false);
					rg_give_item(i, "weapon_knife", GT_APPEND);
					rg_give_item(i, "weapon_ak47", GT_APPEND);
					rg_set_user_bpammo(i, WEAPON_AK47, 250);
					rg_give_item(i, "weapon_m4a1");
					rg_set_user_bpammo(i, WEAPON_M4A1, 250);
					set_member(i, m_flNextAttack, 30.0);
					rg_set_user_freeze(i, true);
					rg_set_user_takedamage(i, true);
					UTIL_ScreenFade(i, 0, 0, 4, 0, 0, 0, 255, 1);
				}
			}
		}
		client_cmd(0, "mp3 play sound/jb_engine/days_mode/hideandseek/pryatki_ae_100317.mp3");
		g_iTimeHideCount = 33;
		jbe_time_hide();
		set_task(1.0, "jbe_time_hide", TASK_TIME_HIDE, _, _, "a", g_iTimeHideCount);
		g_bDayModeStatus = true;
		for(new i; i < sizeof(g_iHamHookForwards); i++) EnableHamForward(g_iHamHookForwards[i]);
	}
}

public jbe_time_hide() {
	if(--g_iTimeHideCount) {
		set_hudmessage(102, 69, 0, -1.0, 0.16, 0, 0.0, 0.9, 0.1, 0.1, -1);
		ShowSyncHudMsg(0, g_iSyncTimeHide, "У заключённых %d секунд^nчтобы спрятаться!", g_iTimeHideCount);
	}
	else {
		for(new i = 1; i <= MaxClients; i++) {
			if(!is_user_alive(i)) continue;
			if(jbe_get_user_team(i) == 2) {
				UTIL_ScreenFade(i, 0, 0, 0, 0, 0, 0, 0, 1);
				rg_set_user_freeze(i, false);
			}
		}
		set_lights("b");
	}
}

public jbe_day_mode_ended(iDayMode, iWinTeam) {
	if(iDayMode == g_iDayModeHideAndSeek) {
		client_cmd(0, "mp3 stop");
		if(task_exists(TASK_TIME_HIDE)) remove_task(TASK_TIME_HIDE);
		g_bDayModeStatus = false;
		server_cmd("mp_flashlight 0");
		set_lights("#OFF");
		new i;
		for(i = 0; i < sizeof(g_iHamHookForwards); i++) DisableHamForward(g_iHamHookForwards[i]);
		for(i = 1; i <= MaxClients; i++) {
			if(is_user_alive(i) && jbe_get_user_team(i) == 2) {
				if(iWinTeam) rg_remove_all_items(i, false);
				else ExecuteHamB(Ham_Killed, i, i, 0);
			}
		}
	}
}

stock rg_set_user_takedamage(const player, bool:take = true) {
	set_entvar(player, var_takedamage, take ? DAMAGE_NO : DAMAGE_AIM);
}

stock rg_set_user_freeze(const player, bool:freeze = true) {
	if(freeze) set_entvar(player, var_flags, get_entvar(player, var_flags) | FL_FROZEN);
	else set_entvar(player, var_flags, get_entvar(player, var_flags) & ~FL_FROZEN);
}

stock UTIL_ScreenFade(id, iDuration, iHoldTime, iFlags, iRed, iGreen, iBlue, iAlpha, iReliable = 0) {
	message_begin(iReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, MsgId_ScreenFade, _, id);
	write_short(iDuration);
	write_short(iHoldTime);
	write_short(iFlags);
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iAlpha);
	message_end();
}