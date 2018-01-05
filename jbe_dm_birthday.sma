#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <xs>
#include <jbe_core>

#pragma semicolon 1

#define MsgId_WeaponList 78
#define MsgId_ScreenFade 98

#define jbe_is_user_valid(%0) 		(%0 && %0 <= MaxClients)

new g_iDayModeBirthday, g_pCakeIndex, g_pDecalIndex[4], g_iFakeMetaSetModel, HamHook:g_iHamHookForwards[14];
new const g_szHamHookEntityBlock[][] = { "func_vehicle", "func_tracktrain", "func_tank", "game_player_hurt", "func_recharge", "func_healthcharger", 
	"game_player_equip", "player_weaponstrip", "trigger_hurt", "trigger_gravity", "armoury_entity", "weaponbox", "weapon_shield" };

public plugin_precache() {
	engfunc(EngFunc_PrecacheModel, "models/egoist/jb/days_mode/birthday/v_cake.mdl");
	engfunc(EngFunc_PrecacheModel, "models/egoist/jb/days_mode/birthday/p_cake.mdl");
	engfunc(EngFunc_PrecacheModel, "models/egoist/jb/days_mode/birthday/w_cake.mdl");
	g_pCakeIndex = engfunc(EngFunc_PrecacheModel, "sprites/egoist/jb/cake_explosion.spr");
	engfunc(EngFunc_PrecacheSound, "egoist/jb/days_mode/birthday/cake_explosion.wav");
	engfunc(EngFunc_PrecacheGeneric, "sound/egoist/jb/days_mode/birthday/birthday_ae_040317.mp3");
	engfunc(EngFunc_PrecacheGeneric, "sprites/egoist/jb/wpn_cake.spr");
	engfunc(EngFunc_PrecacheGeneric, "sprites/egoist/jb/jbe_dm_wpn_cake.txt");
	g_pDecalIndex[0] = engfunc(EngFunc_DecalIndex,"{blood1");
	g_pDecalIndex[1] = engfunc(EngFunc_DecalIndex,"{blood2");
	g_pDecalIndex[2] = engfunc(EngFunc_DecalIndex,"{blood3");
	g_pDecalIndex[3] = engfunc(EngFunc_DecalIndex,"{blood4");
}

public plugin_init() {
	register_plugin("[JBE_DM] Birthday", "1.2", "Freedo.m & Minni Mouse");
	new i;
	for(i = 0; i <= 7; i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Use, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", 0));
	for(i = 8; i <= 12; i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Touch, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", 0));
	DisableHamForward(g_iHamHookForwards[13] = RegisterHam(Ham_Touch, "grenade", "HamHook_Touch_Grenade_Post", 1));
	register_clcmd("sprites/egoist/jb/jbe_dm_wpn_cake", "ClCmd_WpnCake");
	g_iDayModeBirthday = jbe_register_day_mode("JBE_DAY_MODE_BIRTHDAY", 0, 187); 
}

public HamHook_EntityBlock() return HAM_SUPERCEDE;
public HamHook_Touch_Grenade_Post(iTouched, iToucher) {
	if(!pev_valid(iTouched)) return;
	new Float:vecOrigin[3];
	get_entvar(iTouched, var_origin, vecOrigin);
	if(pev_valid(iToucher) == 2) {
		new iOwner = get_entvar(iTouched, var_owner);
		if(jbe_is_user_valid(iToucher)) {
			if(jbe_get_user_team(iToucher) == 1) ExecuteHamB(Ham_TakeDamage, iToucher, iOwner, iOwner, 50.0, DMG_SONIC);
			UTIL_ScreenFade(iToucher, (1<<12), (1<<12), 0, 24, 10, 10, 250);
		}
		else ExecuteHamB(Ham_TakeDamage, iToucher, iOwner, iOwner, 50.0, DMG_SONIC);
	}
	else CREATE_WORLDDECAL(vecOrigin, g_pDecalIndex[random_num(0, 3)]);
	CREATE_SPRITE(vecOrigin, g_pCakeIndex, 15, 255);
	rh_emit_sound2(iTouched, 0, CHAN_AUTO, "egoist/jb/days_mode/birthday/cake_explosion.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	set_entvar(iTouched, var_flags, get_entvar(iTouched, var_flags) | FL_KILLME);
}

public ClCmd_WpnCake(id) {
	rg_internal_cmd(id, "weapon_smokegrenade");
	return PLUGIN_HANDLED;
}

public jbe_day_mode_start(iDayMode, iAdmin) {
	if(iDayMode == g_iDayModeBirthday) {
		for(new i = 1; i <= MaxClients; i++) {
			if(!is_user_alive(i)) continue;
			switch(jbe_get_user_team(i)) {
				case 1: {
					rg_remove_all_items(i, false);
					rg_give_item(i, "weapon_knife", GT_APPEND);
					set_entvar(i, var_gravity, 0.5);
				}
				case 2: {
					rg_remove_all_items(i, false);
					rg_give_item(i, "weapon_smokegrenade", GT_REPLACE);
					rg_set_user_bpammo(i, WEAPON_SMOKEGRENADE, 200);
					message_begin(MSG_ONE, MsgId_WeaponList, _, i);
					write_string("jbe_dm_wpn_cake");
					write_byte(13);
					write_byte(1);
					write_byte(-1);
					write_byte(-1);
					write_byte(3);
					write_byte(3);
					write_byte(9);
					write_byte(24);
					message_end();
					static iszViewModel, iszWeaponModel;
					if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, "models/egoist/jb/days_mode/birthday/v_cake.mdl"))) set_pev_string(i, pev_viewmodel2, iszViewModel);
					if(iszWeaponModel || (iszWeaponModel = engfunc(EngFunc_AllocString, "models/egoist/jb/days_mode/birthday/p_cake.mdl"))) set_pev_string(i, pev_weaponmodel2, iszWeaponModel);
				}
			}
		}
		client_cmd(0, "mp3 play sound/egoist/jb/days_mode/birthday/birthday_ae_040317.mp3");
		for(new i; i < sizeof(g_iHamHookForwards); i++) EnableHamForward(g_iHamHookForwards[i]);
		g_iFakeMetaSetModel = register_forward(FM_SetModel, "FakeMeta_SetModel_Post", 1);
	}
}

public FakeMeta_SetModel_Post(iEntity, const szModel[]) {
	if(szModel[7] == 'w' && szModel[8] == '_' && szModel[9] == 's' && szModel[10] == 'm') {
		engfunc(EngFunc_SetModel, iEntity, "models/egoist/jb/days_mode/birthday/w_cake.mdl");
		new Float:vecVelocity[3];
		get_entvar(iEntity, var_velocity, vecVelocity);
		xs_vec_mul_scalar(vecVelocity, 1.5, vecVelocity);
		set_entvar(iEntity, var_velocity, vecVelocity);
		engfunc(EngFunc_SetSize, iEntity, Float:{-5.0, -5.0, -5.0}, Float:{5.0, 5.0, 5.0});
	}
}

public jbe_day_mode_ended(iDayMode, iWinTeam) {
	if(iDayMode == g_iDayModeBirthday) {
		client_cmd(0, "mp3 stop");
		new i, iEntity, iOwner;
		for(i = 0; i < sizeof(g_iHamHookForwards); i++) DisableHamForward(g_iHamHookForwards[i]);
		unregister_forward(FM_SetModel, g_iFakeMetaSetModel, 1);
		for(i = 1; i <= MaxClients; i++) {
			if(is_user_alive(i) && jbe_get_user_team(i) == 2) {
				if(iWinTeam) rg_remove_all_items(i, false);
				else ExecuteHamB(Ham_Killed, i, i, 0);
			}
		}
		while((iEntity = engfunc(EngFunc_FindEntityByString, iEntity, "classname", "grenade"))) {
			if(!pev_valid(iEntity)) continue;
			iOwner = get_entvar(iEntity, var_owner);
			if(jbe_is_user_valid(iOwner)) set_entvar(iEntity, var_flags, get_entvar(iEntity, var_flags) | FL_KILLME);
		}
	}
}

stock CREATE_SPRITE(Float:vecOrigin[3], pSptite, iWidth, iBrightness) {
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(pSptite);
	write_byte(iWidth);
	write_byte(iBrightness);
	message_end();
}

stock CREATE_WORLDDECAL(Float:vecOrigin[3], pDecal) {
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_WORLDDECAL);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_byte(pDecal);
	message_end();
}

stock UTIL_ScreenFade(id, iDuration, iHoldTime, iFlags, iRed, iGreen, iBlue, iAlpha) {
	message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenFade, _, id);
	write_short(iDuration);
	write_short(iHoldTime);
	write_short(iFlags);
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iAlpha);
	message_end();
}