#include <amxmodx>
#include <reapi>
#include <hamsandwich>
#include <jbe_core>

#pragma semicolon 1

#define PLUGIN_NAME "[JBE] DOGONYALKI"
#define PLUGIN_VERSION "1.1"
#define PLUGIN_AUTHOR "BATYP"

#define GALAXY_AMBIENCE "sound/egoist/jb/days_mode/run/dogonylki_ae_040317.mp3"

#define MAX_ENTITIES_TOUCH 4
#define MAX_ENTITIES_USE 9
#define MsgId_ScreenFade 98
#define TASK_TIME_DOGONYLKI 785689

new const g_szUse[MAX_ENTITIES_USE][] = {
	"game_player_hurt", // При активации наносит игроку повреждения
	"func_recharge", // Увеличение запаса бронижелета
	"func_healthcharger", // Увеличение процентов здоровья
	"game_player_equip", // Выдаёт оружие
	"player_weaponstrip", // Забирает всё оружие
	"trigger_gravity", // Устанавливает игроку силу гравитации
	"armoury_entity", // Объект лежащий на карте, оружия, броня или гранаты
	"weaponbox", // Оружие выброшенное игроком
	"weapon_shield" // Щит
};

new const g_szTouch[MAX_ENTITIES_TOUCH][] = {
	"player_weaponstrip", // Управляемая машина
	"weaponbox", // Управляемый поезд
	"armoury_entity", // Управляемая пушка
	"weapon_shield" // Наносит игроку повреждения
};

new HamHook:g_iUse[MAX_ENTITIES_USE], HamHook:g_iTouch[MAX_ENTITIES_TOUCH];

new g_iDogonylki;
new g_iSyncDogonylkiHide, g_iTimeDogonylkiCount;

public plugin_precache() precache_generic(GALAXY_AMBIENCE);

public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	
	for(new i = 0; i < MAX_ENTITIES_USE; i++) DisableHamForward(g_iUse[i] = RegisterHam(Ham_Use, g_szUse[i], "CEntity__BLock_Pre", 0));
	for(new i = 0; i < MAX_ENTITIES_TOUCH; i++) DisableHamForward(g_iTouch[i] = RegisterHam(Ham_Touch, g_szTouch[i], "CEntity__BLock_Pre", 0));

	g_iDogonylki = jbe_register_day_mode("JBE_DAY_MODE_DOGONYLKI", 0, 180);	
	g_iSyncDogonylkiHide = CreateHudSyncObj();
}

public jbe_day_mode_start(iDayMode, iAdmin) {
	if(iDayMode == g_iDogonylki) {	
		for(new i = 1; i <= MaxClients; i++) {
			if(!is_user_alive(i)) continue;
				
			client_cmd(i, "mp3 play %s", GALAXY_AMBIENCE);
			switch(jbe_get_user_team(i)) {
				case 1: {
					rg_remove_all_items(i, false); 
					rg_give_item(i, "weapon_knife", GT_APPEND);
					rg_set_user_health(i, 50.0);
					rg_set_user_armor(i, 0, ARMOR_KEVLAR);
					rg_set_user_gravity(i, 0.3);
					rg_set_user_maxspeed(i, 385.0);
				}
				case 2: {
					rg_remove_all_items(i, false); 
					rg_give_item(i, "weapon_knife", GT_APPEND);
					rg_set_user_armor(i, 100, ARMOR_KEVLAR);
					rg_set_user_health(i, 100.0);
					rg_set_user_maxspeed(i, 400.0);
					rg_set_user_gravity(i, 0.3);
					rg_set_user_freeze(i, true);
					rg_set_user_takedamage(i, true);
					UTIL_ScreenFade(i, 0, 0, 4, 0, 0, 0, 255, 1);
				}
			}
		}
		g_iTimeDogonylkiCount = 7;
		jbe_time_dogonylki();
		set_task(1.0, "jbe_time_dogonylki", TASK_TIME_DOGONYLKI, _, _, "a", g_iTimeDogonylkiCount);
		for(new i = 0; i < MAX_ENTITIES_USE; i++) EnableHamForward(g_iUse[i]);
		for(new i = 0; i < MAX_ENTITIES_TOUCH; i++) EnableHamForward(g_iTouch[i]);
	}
}

public jbe_time_dogonylki() {
	if(--g_iTimeDogonylkiCount) {
		set_hudmessage(102, 69, 0, -1.0, 0.16, 0, 0.0, 0.9, 0.1, 0.1, -1);
		ShowSyncHudMsg(0, g_iSyncDogonylkiHide, "У заключенных: [%d]", g_iTimeDogonylkiCount);
	}
	else {
		for(new i = 1; i <= MaxClients; i++) {
			if(!is_user_alive(i)) continue;
			if(jbe_get_user_team(i) == 2) {
				UTIL_ScreenFade(i, 0, 0, 0, 0, 0, 0, 0, 1);
				rg_set_user_freeze(i, false);
			}
		}
	}
}

public jbe_day_mode_ended(iDayMode, iWinTeam) {
	if(iDayMode == g_iDogonylki) {
		client_cmd(0, "stopsound");
		if(task_exists(TASK_TIME_DOGONYLKI)) remove_task(TASK_TIME_DOGONYLKI);
		for(new i = 0; i < MAX_ENTITIES_USE; i++) DisableHamForward(g_iUse[i]);
		for(new i = 0; i < MAX_ENTITIES_TOUCH; i++) DisableHamForward(g_iTouch[i]);
		for(new i = 1; i <= MaxClients; i++) {
			if(is_user_alive(i)) {
				switch(jbe_get_user_team(i)) {
					case 1: rg_set_user_rendering(i, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
					case 2: {
						if(iWinTeam) rg_set_user_rendering(i, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
						else ExecuteHamB(Ham_Killed, i, i, 0);
					}
				}
			}
		}
	}
}

public CEntity__BLock_Pre() return HAM_SUPERCEDE;

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

stock rg_set_user_maxspeed(const player, Float:speed = -1.0) {
	if(speed != -1.0) set_entvar(player, var_maxspeed, Float:speed);
	else rg_reset_maxspeed(player);
}

stock rg_set_user_gravity(const player, Float:gravity = 1.0) {
	set_entvar(player, var_gravity, Float:gravity);
}

stock rg_set_user_health(const player, Float:health) {
	set_entvar(player, var_health, Float:health);
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

stock rg_set_user_freeze(const player, bool:freeze = true) {
	if(freeze) set_entvar(player, var_flags, get_entvar(player, var_flags) | FL_FROZEN);
	else set_entvar(player, var_flags, get_entvar(player, var_flags) & ~FL_FROZEN);
}

stock rg_set_user_takedamage(const player, bool:take = true) {
	set_entvar(player, var_takedamage, take ? DAMAGE_NO : DAMAGE_AIM);
}