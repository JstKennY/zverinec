#include <amxmodx>
#include <engine>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <jbe_core>

#pragma semicolon 1
#define jbe_is_user_valid(%0) 			(%0 && %0 <= MaxClients)
#define MsgId_ScreenFade 98
#define TASK_AMBIENCE_SOUND 124567
//Проверка.
new g_iDayModeMyasorubka, bool:g_bDayModeStatus, g_TimeGoShturm, g_iHudShow, HamHook:g_iHamHookForwards[13];
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

public plugin_precache() {
	precache_generic("sound/jb_engine/days_mode/myasorubka/myasorubka_ae_050118.mp3");
	precache_model("models/player/maniac_ae/maniac_ae.mdl");
}

public plugin_init() {
	register_plugin("[JBE DM] Myasorubka", "0.0.1", "Minni Mouse");
	new i;
	for(i = 0; i <= 7; i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Use, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", false));
	for(i = 8; i <= 12; i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Touch, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", false));
	register_clcmd("drop", "ClCmd_Drop");
	g_iDayModeMyasorubka = jbe_register_day_mode("JBE_DAY_MODE_MYASORUBKA", 0, 180);
	g_iHudShow = CreateHudSyncObj();
}

public HamHook_EntityBlock() return HAM_SUPERCEDE;

public ClCmd_Drop() {
	if(g_bDayModeStatus) return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE;
}

public jbe_day_mode_start(iDayMode, iAdmin) {
	if(iDayMode == g_iDayModeMyasorubka) {
		for(new i = 1; i <= MaxClients; i++) {
			if(!is_user_alive(i)) continue;
			switch(jbe_get_user_team(i)) {
				case 1: {
					rg_remove_all_items(i, false);
					rg_give_item(i, "weapon_knife", GT_REPLACE);
					rg_set_user_health(i, 1000.0);
					rg_set_user_freeze(i, true);
					rg_set_user_takedamage(i, true);
					jbe_set_user_model(i, "maniac_ae");
					static iszViewModel, iszWeaponModel;
					if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, "models/egoist/jb/shop/v_chainsaw.mdl"))) set_pev_string(i, pev_viewmodel2, iszViewModel);
					if(iszWeaponModel || (iszWeaponModel = engfunc(EngFunc_AllocString, "models/egoist/jb/shop/p_chainsaw.mdl"))) set_pev_string(i, pev_weaponmodel2, iszWeaponModel);
					set_member(i, m_flNextAttack, 1.5);
					UTIL_ScreenFade(i, 0, 0, 4, 0, 0, 0, 255);
				}
				case 2: {
					rg_remove_all_items(i, false);
					rg_give_item(i, "weapon_m249", GT_REPLACE);
					rg_set_user_bpammo(i, WEAPON_M249, 2000);
					rg_set_user_health(i, 50.0);
					rg_set_user_gravity(i, 0.7);
				}
			}
		}
		for(new i; i < sizeof(g_iHamHookForwards); i++) EnableHamForward(g_iHamHookForwards[i]);
		set_lights("d"), g_TimeGoShturm = 11;
		jbe_dm_ambience_sound_task(), freezetimeron();
		g_bDayModeStatus = true;
	}
}
public freezetimeron() {
	set_task(1.0, "start_game", 46377, _, _, "a", g_TimeGoShturm);
	Set_Fog(true);
}

public jbe_dm_ambience_sound_task() {
	client_cmd(0, "mp3 play sound/egoist/jb/days_mode/myasorubka/myasorubka_ae_050118.mp3");
	set_task(126.0, "jbe_dm_ambience_sound_task", TASK_AMBIENCE_SOUND);
}

public FakeMeta_EmitSound(id, iChannel, szSample[], Float:flVolume, Float:flAttn, iFlag, iPitch) {
	if(jbe_is_user_valid(id)) {
		if(szSample[8] == 'k' && szSample[9] == 'n' && szSample[10] == 'i' && szSample[11] == 'f' && szSample[12] == 'e') {
			switch(szSample[17]) {
				case 'l': {} // knife_deploy1.wav
				case 'w': rh_emit_sound2(id, 0, iChannel, "egoist/jb/shop/chainsaw_slash.wav", flVolume, flAttn, iFlag, iPitch); // knife_hitwall1.wav
				case 's': rh_emit_sound2(id, 0, iChannel, "egoist/jb/shop/chainsaw_slash.wav", flVolume, flAttn, iFlag, iPitch); // knife_slash(1-2).wav
				case 'b': rh_emit_sound2(id, 0, iChannel, "egoist/jb/shop/chainsaw_hit.wav", flVolume, flAttn, iFlag, iPitch); // knife_stab.wav
				default: rh_emit_sound2(id, 0, iChannel, "egoist/jb/shop/chainsaw_hit.wav", flVolume, flAttn, iFlag, iPitch); // knife_hit(1-4).wav
			}
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}

public start_game() {
	if(--g_TimeGoShturm) {
		set_hudmessage(160, 255, 50, -1.0, 0.16, 0, 0.0, 0.9, 0.1, 0.1, -1);
		ShowSyncHudMsg(0, g_iHudShow, "У охраны %d секунд, чтобы занять оборону!", g_TimeGoShturm);
	}
	else {
		remove_task(46377);
		for(new i = 1; i <= MaxClients; i++) {
			if(!is_user_alive(i)) continue;
			if(jbe_get_user_team(i) == 1) {
				UTIL_ScreenFade(i, 0, 0, 0, 0, 0, 0, 0, 1);
				rg_set_user_freeze(i, false);
				rg_set_user_takedamage(i, false);
			}
		}
		set_hudmessage(0, 40, 230, -1.0, 0.16, 0, 0.0, 0.9, 0.1, 0.1, -1);
		ShowSyncHudMsg(0, g_iHudShow, "Маньяки вышли на охоту!");
		set_lights("d");
	}
}

public jbe_day_mode_ended(iDayMode, iWinTeam) {
	if(iDayMode == g_iDayModeMyasorubka) {
		for(new i; i < sizeof(g_iHamHookForwards); i++) DisableHamForward(g_iHamHookForwards[i]);
		for(new i = 1; i <= MaxClients; i++) {
			if(is_user_alive(i)) {
				switch(jbe_get_user_team(i)) {
					case 1: {
						if(iWinTeam) rg_remove_all_items(i, false);
						else ExecuteHamB(Ham_Killed, i, i, 0);
					}
					case 2: rg_remove_all_items(i, false);
				}
			}
		}
		Set_Fog(false);
		set_lights("#OFF");
		remove_task(46377);
		remove_task(TASK_AMBIENCE_SOUND);
		client_cmd(0, "mp3 stop");
		g_bDayModeStatus = false;
	}
}

stock rg_set_user_health(const player, Float:health) set_entvar(player, var_health, Float:health);

stock rg_set_user_freeze(const player, bool:freeze = true) {
	if(freeze) set_entvar(player, var_flags, get_entvar(player, var_flags) | FL_FROZEN);
	else set_entvar(player, var_flags, get_entvar(player, var_flags) & ~FL_FROZEN);
}

stock rg_set_user_takedamage(const player, bool:take = true) {
	set_entvar(player, var_takedamage, take ? DAMAGE_NO : DAMAGE_AIM);
}

stock rg_set_user_gravity(const player, Float:gravity = 1.0) {
	set_entvar(player, var_gravity, Float:gravity);
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

stock Set_Fog(bool:fog = true) {
	switch(fog) {
		case true: {
			message_begin(MSG_ALL, get_user_msgid("Fog"), {0,0,0}, 0);
			write_byte(150); 	 	// Red
			write_byte(20); 		// Green
			write_byte(20); 		// Blue
			write_byte(10); 						// SD
			write_byte(41);  						// ED
			write_byte(95);  						// D1
			write_byte(59);  						// D2
			message_end();	
		}
		case false: {
			message_begin(MSG_ALL, get_user_msgid("Fog"), {0,0,0}, 0);
			write_byte(0);  // Red
			write_byte(0);  // Green
			write_byte(0);  // Blue
			write_byte(0); 	// SD
			write_byte(0);  // ED
			write_byte(0);  // D1
			write_byte(0);  // D2
			message_end();
		}
	}
}
