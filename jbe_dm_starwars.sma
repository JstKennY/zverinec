#include <amxmodx>
#include <engine>
#include <reapi>
#include <fakemeta>
#include <hamsandwich>
#include <jbe_core>

#pragma semicolon 1

#define jbe_is_user_valid(%0) 			(%0 && %0 <= MaxClients)
#define TASK_AMBIENCE_SOUND 			124567

new g_iDayModeStarwars, bool:g_bDayModeStatus, g_iFakeMetaEmitSound, HamHook:g_iHamHookForwards[13];
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
	precache_generic("sound/egoist/jb/days_mode/starwars/star_ae_301116.mp3");
	precache_model("models/player/master_yoda_ae/master_yoda_ae.mdl");
	precache_model("models/player/darth_vader_ae/darth_vader_ae.mdl");
	precache_model("models/egoist/jb/days_mode/starwars/v_dual_laser.mdl");
	precache_model("models/egoist/jb/days_mode/starwars/p_dual_laser.mdl");
	precache_sound("egoist/jb/days_mode/starwars/laser_slash1.wav");
	precache_sound("egoist/jb/days_mode/starwars/laser_stab.wav");
}

new HookChain:g_PlayerKilledHook;

public plugin_init() {
	register_plugin("[JBE_DM] Starwars", "1.1", "DARLOK");
	new i;
	for(i = 0; i <= 7; i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Use, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", 0));
	for(i = 8; i <= 12; i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Touch, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", 0));
	DisableHookChain(g_PlayerKilledHook = RegisterHookChain(RG_CBasePlayer_Killed, "Player_Killed_Post", true));
	register_clcmd("drop", "ClCmd_Drop");
	g_iDayModeStarwars = jbe_register_day_mode("JBE_DAY_MODE_STARWARS", 0, 180);
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
	if(iDayMode == g_iDayModeStarwars) {
		for(new i = 1; i <= MaxClients; i++) {
			if(!is_user_alive(i)) continue;
			switch(jbe_get_user_team(i)) {
				case 1: {
					rg_remove_all_items(i, false);
					rg_set_user_health(i, 250.0);
					rg_set_user_gravity(i, 0.4);
					jbe_set_user_model(i, "master_yoda_ae");
					rg_give_item(i, "weapon_knife", GT_REPLACE);
					static iszViewModel, iszWeaponModel;
					if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, "models/egoist/jb/days_mode/starwars/v_dual_laser.mdl"))) set_pev_string(i, pev_viewmodel2, iszViewModel);
					if(iszWeaponModel || (iszWeaponModel = engfunc(EngFunc_AllocString, "models/egoist/jb/days_mode/starwars/p_dual_laser.mdl"))) set_pev_string(i, pev_weaponmodel2, iszWeaponModel);
				}
				case 2: {
					rg_remove_all_items(i, false);
					rg_set_user_health(i, 750.0);
					rg_set_user_gravity(i, 0.4);
					jbe_set_user_model(i, "darth_vader_ae");
					rg_give_item(i, "weapon_knife", GT_REPLACE);
					static iszViewModel, iszWeaponModel;
					if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, "models/egoist/jb/days_mode/starwars/v_dual_laser.mdl"))) set_pev_string(i, pev_viewmodel2, iszViewModel);
					if(iszWeaponModel || (iszWeaponModel = engfunc(EngFunc_AllocString, "models/egoist/jb/days_mode/starwars/p_dual_laser.mdl"))) set_pev_string(i, pev_weaponmodel2, iszWeaponModel);
				}
			}
		}
		set_lights("c");
		for(new i; i < sizeof(g_iHamHookForwards); i++) EnableHamForward(g_iHamHookForwards[i]);
		EnableHookChain(g_PlayerKilledHook);
		jbe_dm_ambience_sound_task();
		g_iFakeMetaEmitSound = register_forward(FM_EmitSound, "FakeMeta_EmitSound", 0);
		g_bDayModeStatus = true;
	}
}

public jbe_dm_ambience_sound_task() {
	client_cmd(0, "mp3 play sound/jb_engine/days_mode/starwars/star_ae_301116.mp3");
	set_task(126.0, "jbe_dm_ambience_sound_task", TASK_AMBIENCE_SOUND);
}

public FakeMeta_EmitSound(id, iChannel, szSample[], Float:flVolume, Float:flAttn, iFlag, iPitch) {
	if(jbe_is_user_valid(id)) {
		if(szSample[8] == 'k' && szSample[9] == 'n' && szSample[10] == 'i' && szSample[11] == 'f' && szSample[12] == 'e') {
			switch(szSample[17]) {
				case 'l': {} // knife_deploy1.wav
				case 'w': rh_emit_sound2(id, 0, iChannel, "egoist/jb/days_mode/starwars/laser_slash1.wav", flVolume, flAttn, iFlag, iPitch); // knife_hitwall1.wav
				case 's': rh_emit_sound2(id, 0, iChannel, "egoist/jb/days_mode/starwars/laser_slash1.wav", flVolume, flAttn, iFlag, iPitch); // knife_slash(1-2).wav
				case 'b': rh_emit_sound2(id, 0, iChannel, "egoist/jb/days_mode/starwars/laser_stab.wav", flVolume, flAttn, iFlag, iPitch); // knife_stab.wav
				default: rh_emit_sound2(id, 0, iChannel, "egoist/jb/days_mode/starwars/laser_hit1.wav", flVolume, flAttn, iFlag, iPitch); // knife_hit(1-4).wav
			}
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}

public jbe_day_mode_ended(iDayMode, iWinTeam) {
	if(iDayMode == g_iDayModeStarwars) {
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
		remove_task(TASK_AMBIENCE_SOUND);
		fog(false);
		client_cmd(0, "mp3 stop");
		unregister_forward(FM_EmitSound, g_iFakeMetaEmitSound, 0);
		g_bDayModeStatus = false;
	}
}

stock rg_set_user_health(const player, Float:health) {
	set_entvar(player, var_health, Float:health);
}

stock rg_set_user_gravity(const player, Float:gravity = 1.0) {
	set_entvar(player, var_gravity, Float:gravity);
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

public fog(bool:on)	 {
	if(on) {
		message_begin(MSG_ALL,get_user_msgid("Fog"),{0,0,0},0);
		write_byte(random_num(180,244));  // R
		write_byte(1);  // G
		write_byte(1);  // B
		write_byte(10); // SD
		write_byte(41);  // ED
		write_byte(95);   // D1
		write_byte(59);  // D2
		message_end();	
	}
	else {
		message_begin(MSG_ALL,get_user_msgid("Fog"),{0,0,0},0);
		write_byte(0);  // R
		write_byte(0);  // G
		write_byte(0);  // B
		write_byte(0); // SD
		write_byte(0);  // ED
		write_byte(0);   // D1
		write_byte(0);  // D2
		message_end();
	}
}