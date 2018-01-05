#include <amxmodx>
#include <reapi>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#define ENG_NULLENT			-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define dmp7a1_WEAPONKEY 	501
#define IsValidUser(%1) 	(1 <= %1 <= MaxClients)

#define dmp7a1_RELOAD_TIME 			3.5
#define dmp7a1_SHOOT_LEFT1			1
#define dmp7a1_SHOOT_LEFT2			2
#define dmp7a1_SHOOT_LEFTLAST		3
#define dmp7a1_SHOOT_RIGHT1			4
#define dmp7a1_SHOOT_RIGHT2			5
#define dmp7a1_SHOOT_RIGHTLAST		6
#define dmp7a1_RELOAD				7
#define dmp7a1_DRAW					8

#define UP_SCALE			-6.0    //�����
#define FORWARD_SCALE		8.5     //������
#define RIGHT_SCALE			5.0     //������
#define LEFT_SCALE			-5.0    //�����
#define TE_BOUNCE_SHELL		1

#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

new const Fire_Sounds[][] = { "weapons/egoist/jb/dmp7-1.wav" }

new dmp7a1_V_MODEL[64] = "models/egoist/jb/weapon/v_dmp7unicorn.mdl"
new dmp7a1_P_MODEL[64] = "models/egoist/jb/weapon/p_dmp7unicorn.mdl"
new dmp7a1_W_MODEL[64] = "models/egoist/jb/weapon/ujbl_w_weapons.mdl"

new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }

new const dmp7a1_name[] = "weapon_dmp7a1"

new const dmp7a1_spr[][] = { "sprites/egoist/jb/640hud21.spr", "sprites/egoist/jb/640hud7.spr" }

new cvar_dmg_dmp7a1, cvar_recoil_dmp7a1, cvar_clip_dmp7a1, cvar_spd_dmp7a1, cvar_dmp7a1_ammo
new g_orig_event_dmp7a1, g_IsInPrimaryAttack
new Float:cl_pushangle[MAX_PLAYERS + 1][3], m_iBlood[2]
new g_has_dmp7a1[33], g_clip_ammo[33], g_dmp7a1_TmpClip[33], oldweap[33]
new gmsgWeaponList
new g_iShellModel

new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
	"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
	"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
	"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
	"weapon_ak47", "weapon_knife", "weapon_p90" }

public plugin_init() {
	register_plugin("[ZP] Extra: Dual MP7A1", "2.0.0", "LARS-DAY[BR]EAKER & Minni Mouse")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_mac10", "fw_dmp7a1_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
	if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_mac10", "fw_dmp7a1_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_mac10", "fw_dmp7a1_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_mac10", "dmp7a1_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, "weapon_mac10", "dmp7a1_Reload")
	RegisterHam(Ham_Weapon_Reload, "weapon_mac10", "dmp7a1_Reload_Post", 1)
	//RegisterHam(Ham_TakeDamage, "player", "Player_TakeDamage")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	register_forward(FM_AddToFullPack, "PlayerAddToFullPack", 1)
	
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "Player_TakeDamage", true)
	RegisterHookChain(RG_CBasePlayer_TraceAttack, "Player_TraceAttack", true)
	/*RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack", 1)*/

	cvar_dmg_dmp7a1 = register_cvar("zp_dmp7a1_dmg", "1.0")
	cvar_recoil_dmp7a1 = register_cvar("zp_dmp7a1_recoil", "1.0")
	cvar_clip_dmp7a1 = register_cvar("zp_dmp7a1_clip", "80")
	cvar_spd_dmp7a1 = register_cvar("zp_dmp7a1_spd", "0.98")
	cvar_dmp7a1_ammo = register_cvar("zp_dmp7a1_ammo", "160")
	
	gmsgWeaponList = get_user_msgid("WeaponList")
	register_clcmd(dmp7a1_name, "command_dmp7a1")
}

public plugin_precache() {
	precache_model(dmp7a1_V_MODEL)
	precache_model(dmp7a1_P_MODEL)
	precache_model(dmp7a1_W_MODEL)
	for(new i = 0; i < sizeof Fire_Sounds; i++)
	precache_sound(Fire_Sounds[i])	
	precache_sound("weapons/egoist/jb/dmp7_drop.wav")
	precache_sound("weapons/egoist/jb/dmp7_draw.wav")
	precache_sound("weapons/egoist/jb/dmp7_foley2.wav")
	precache_sound("weapons/egoist/jb/dmp7_foley4.wav")
	g_iShellModel = precache_model("models/pshell.mdl")
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")

	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)

	new sFile[64]
	formatex(sFile, charsmax(sFile), "sprites/egoist/jb/%s.txt", dmp7a1_name)
	precache_generic(sFile)

	for(new i = 0; i < sizeof(dmp7a1_spr); i++) precache_generic(dmp7a1_spr[i])
	
}

public Player_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType) {
	if(!is_user_alive(iAttacker)) return

	new g_currentweapon = get_user_weapon(iAttacker)

	if(g_currentweapon != CSW_MAC10) return
	if(!g_has_dmp7a1[iAttacker]) return

	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
	
	if(iEnt) {
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_DECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		write_short(iEnt)
		message_end()
	}
	else {
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		message_end()
	}
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_GUNSHOTDECAL)
	write_coord_f(flEnd[0])
	write_coord_f(flEnd[1])
	write_coord_f(flEnd[2])
	write_short(iAttacker)
	write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
	message_end()
}

public command_dmp7a1(Player) {
	rg_internal_cmd(Player, "weapon_mac10")
	return PLUGIN_HANDLED
}

public plugin_natives() register_native("ujbl_give_weapon", "native_give_weapon_add", 1);

public native_give_weapon_add(id) give_dmp7a1(id);

public fwPrecacheEvent_Post(type, const name[]) {
	if(equal("events/mac10.sc", name)) {
		g_orig_event_dmp7a1 = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public client_connect(id) g_has_dmp7a1[id] = false;

public client_disconnected(id) g_has_dmp7a1[id] = false;

public fw_SetModel(entity, model[]) {
	if(!is_valid_ent(entity)) return FMRES_IGNORED
	
	static szClassName[33]
	entity_get_string(entity, EV_SZ_classname, szClassName, charsmax(szClassName))
		
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED
	
	static iOwner
	
	iOwner = entity_get_edict(entity, EV_ENT_owner)
	
	if(equal(model, "models/w_mac10.mdl")) {
		static iStoredAugID
		
		iStoredAugID = find_ent_by_owner(ENG_NULLENT, "weapon_mac10", entity)
	
		if(!is_valid_ent(iStoredAugID)) return FMRES_IGNORED
	
		if(g_has_dmp7a1[iOwner]) {
			entity_set_int(iStoredAugID, EV_INT_WEAPONKEY, dmp7a1_WEAPONKEY)
			
			g_has_dmp7a1[iOwner] = false
			
			entity_set_model(entity, dmp7a1_W_MODEL)
			set_entvar(entity, var_body, 3)
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public give_dmp7a1(id)
{
	rg_drop_items_by_slot(id, PRIMARY_WEAPON_SLOT)
	new iWep2 = rg_give_item(id, "weapon_mac10", GT_REPLACE)
	if(iWep2 > 0) {
		set_member(iWep2, m_Weapon_iClip, get_pcvar_num(cvar_clip_dmp7a1))
		rg_set_user_bpammo(id, WEAPON_MAC10, get_pcvar_num(cvar_dmp7a1_ammo))	
		UTIL_PlayWeaponAnimation(id, dmp7a1_DRAW)
		set_member(id, m_flNextAttack, 1.0)

		message_begin(MSG_ONE, gmsgWeaponList, _, id)
		write_string(dmp7a1_name)
		write_byte(6)
		write_byte(100)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(13)
		write_byte(CSW_MAC10)
		message_end()
	}
	g_has_dmp7a1[id] = true
}

public fw_dmp7a1_AddToPlayer(dmp7a1, id) {
	if(!is_valid_ent(dmp7a1) || !is_user_connected(id)) return HAM_IGNORED
	
	if(entity_get_int(dmp7a1, EV_INT_WEAPONKEY) == dmp7a1_WEAPONKEY) {
		g_has_dmp7a1[id] = true
		
		entity_set_int(dmp7a1, EV_INT_WEAPONKEY, 0)

		message_begin(MSG_ONE, gmsgWeaponList, _, id)
		write_string(dmp7a1_name)
		write_byte(6)
		write_byte(100)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(13)
		write_byte(CSW_MAC10)
		message_end()
		
		return HAM_HANDLED
	}
	else {
		message_begin(MSG_ONE, gmsgWeaponList, _, id)
		write_string("weapon_mac10")
		write_byte(6)
		write_byte(100)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(13)
		write_byte(CSW_MAC10)
		message_end()
	}
	return HAM_IGNORED
}

public fw_UseStationary_Post(entity, caller, activator, use_type) {
	if(use_type == 0 && is_user_connected(caller)) replace_weapon_models(caller, get_user_weapon(caller))
}

public fw_Item_Deploy_Post(weapon_ent) {
	static owner
	owner = get_member(weapon_ent, m_pPlayer)
	
	static weaponid
	weaponid = get_member(weapon_ent, m_iId)
	
	replace_weapon_models(owner, weaponid)
}

public CurrentWeapon(id) {
	replace_weapon_models(id, read_data(2))

	if(read_data(2) != CSW_MAC10 || !g_has_dmp7a1[id]) return

	static Float:iSpeed
	if(g_has_dmp7a1[id]) iSpeed = get_pcvar_float(cvar_spd_dmp7a1)

	static weapon[32], Ent
	get_weaponname(read_data(2), weapon, 31)
	Ent = find_ent_by_owner(ENG_NULLENT, "weapon_mac10", id)
	if(Ent) {
		static Float:Delay
		Delay = get_member(Ent, m_Weapon_flNextPrimaryAttack) * iSpeed
		if(Delay > 0.0) set_member(Ent, m_Weapon_flNextPrimaryAttack, Delay)
	}
}

replace_weapon_models(id, weaponid) {
	switch (weaponid) {
		case CSW_MAC10: {
			if(g_has_dmp7a1[id]) {
				set_entvar(id, var_viewmodel, dmp7a1_V_MODEL)
				set_entvar(id, var_weaponmodel, dmp7a1_P_MODEL)
				if(oldweap[id] != CSW_MAC10) {
					UTIL_PlayWeaponAnimation(id, dmp7a1_DRAW)
					set_member(id, m_flNextAttack, 1.0)

					message_begin(MSG_ONE, gmsgWeaponList, _, id)
					write_string(dmp7a1_name)
					write_byte(6)
					write_byte(100)
					write_byte(-1)
					write_byte(-1)
					write_byte(0)
					write_byte(13)
					write_byte(CSW_MAC10)
					message_end()
				}
			}
		}
	}
	oldweap[id] = weaponid
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle) {
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_MAC10 || !g_has_dmp7a1[Player])) return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_dmp7a1_PrimaryAttack(Weapon) {
	new Player = get_member(Weapon, m_pPlayer)
	if(!g_has_dmp7a1[Player]) return
	
	g_IsInPrimaryAttack = 1
	get_entvar(Player, var_punchangle, cl_pushangle[Player])
	
	g_clip_ammo[Player] = get_member(Weapon, m_Weapon_iClip)
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2) {
	if((eventid != g_orig_event_dmp7a1) || !g_IsInPrimaryAttack) return FMRES_IGNORED
	if(!(1 <= invoker <= MaxClients))
    return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_dmp7a1_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_member(Weapon, m_pPlayer)
	
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
	
	if(!is_user_alive(Player)) return

	if(g_has_dmp7a1[Player]) {
		if(!g_clip_ammo[Player]) return

		new Float:push[3]
		get_entvar(Player, var_punchangle, push)
		xs_vec_sub(push, cl_pushangle[Player], push)
		
		xs_vec_mul_scalar(push, get_pcvar_float(cvar_recoil_dmp7a1), push)
		xs_vec_add(push, cl_pushangle[Player], push)
		set_entvar(Player, var_punchangle, push)
		
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		new num
		num = random_num(1,2)
		if(num == 1) {
			UTIL_PlayWeaponAnimation(Player, szClip < 1 ? dmp7a1_SHOOT_LEFTLAST : random_num(dmp7a1_SHOOT_LEFT1, dmp7a1_SHOOT_LEFT2))	

			static Float:vVel[3], Float:vAngle[3], Float:vOrigin[3], Float:vViewOfs[3], 
			i, Float:vShellOrigin[3], Float:vShellVelocity[3], Float:vRight[3], 
			Float:vUp[3], Float:vForward[3]
			get_entvar(Player, var_velocity, vVel)
			get_entvar(Player, var_view_ofs, vViewOfs)
			get_entvar(Player, var_angles, vAngle)
			get_entvar(Player, var_origin, vOrigin)
			global_get(glb_v_right, vRight)
			global_get(glb_v_up, vUp)
			global_get(glb_v_forward, vForward)
			for(i = 0; i<3; i++) {
				vShellOrigin[i] = vOrigin[i] + vViewOfs[i] + vUp[i] * UP_SCALE + vForward[i] * FORWARD_SCALE + vRight[i] * RIGHT_SCALE
				vShellVelocity[i] = vVel[i] + vRight[i] * random_float(50.0, 70.0) + vUp[i] * random_float(100.0, 150.0) + vForward[i] * 25.0
			}
			CBaseWeapon__EjectBrass(vShellOrigin, vShellVelocity, -vAngle[1], g_iShellModel, TE_BOUNCE_SHELL)
		}
		if(num == 2)   {
			UTIL_PlayWeaponAnimation(Player, szClip < 1 ? dmp7a1_SHOOT_RIGHTLAST : random_num(dmp7a1_SHOOT_RIGHT1, dmp7a1_SHOOT_RIGHT2))

			static Float:vVel[3], Float:vAngle[3], Float:vOrigin[3], Float:vViewOfs[3], 
			i, Float:vShellOrigin[3], Float:vShellVelocity[3], Float:vRight[3], 
			Float:vUp[3], Float:vForward[3]
			get_entvar(Player, var_velocity, vVel)
			get_entvar(Player, var_view_ofs, vViewOfs)
			get_entvar(Player, var_angles, vAngle)
			get_entvar(Player, var_origin, vOrigin)
			global_get(glb_v_right, vRight)
			global_get(glb_v_up, vUp)
			global_get(glb_v_forward, vForward)
			for(i = 0; i<3; i++) {
				vShellOrigin[i] = vOrigin[i] + vViewOfs[i] + vUp[i] * UP_SCALE + vForward[i] * FORWARD_SCALE + vRight[i] * LEFT_SCALE
				vShellVelocity[i] = vVel[i] + vRight[i] * random_float(-50.0, -70.0) + vUp[i] * random_float(100.0, 150.0) + vForward[i] * 25.0
			}
			CBaseWeapon__EjectBrass(vShellOrigin, vShellVelocity, -vAngle[1], g_iShellModel, TE_BOUNCE_SHELL)
		}
	}
}

public PlayerAddToFullPack(ES_Handle, E, pEnt, pHost, bsHostFlags, pPlayer, pSet) {       
	if(pPlayer && get_user_weapon(pEnt) == CSW_MAC10 && g_has_dmp7a1[pEnt]) {
		static iAnim; iAnim = get_es(ES_Handle, ES_Sequence)
		switch(iAnim) {
			case 16: set_es(ES_Handle, ES_Sequence, iAnim += 6)
			case 17: set_es(ES_Handle, ES_Sequence, iAnim += random_num(6, 7))
			case 18, 19: set_es(ES_Handle, ES_Sequence, iAnim += 7)
			case 20: set_es(ES_Handle, ES_Sequence, iAnim += random_num(7, 8))
			case 21: set_es(ES_Handle, ES_Sequence, iAnim += 8)
		}
	}
	return FMRES_IGNORED
}

public Player_TakeDamage(victim, pevInflictor, pevAttacker, Float:flDamage, bitsDamageType) {
	if(victim != pevAttacker && is_user_connected(pevAttacker)) {
		if(get_user_weapon(pevAttacker) == CSW_MAC10) {
			if(g_has_dmp7a1[pevAttacker]) SetHookChainArg(4, ATYPE_FLOAT, flDamage * get_pcvar_float(cvar_dmg_dmp7a1))
		}
	}
}

public message_DeathMsg(msg_id, msg_dest, id) {
	static szTruncatedWeapon[33], iAttacker, iVictim
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
	
	if(!is_user_connected(iAttacker) || iAttacker == iVictim) return PLUGIN_CONTINUE
	
	if(equal(szTruncatedWeapon, "mac10") && get_user_weapon(iAttacker) == CSW_MAC10) {
		if(g_has_dmp7a1[iAttacker]) set_msg_arg_string(4, "dmp7a1")
	}
	return PLUGIN_CONTINUE
}

stock WeaponIdType:rg_get_user_active_weapon(const player, &pWeapon = NULLENT) {
	return ((pWeapon = get_member(player, m_pActiveItem)) > 0) ? get_member(pWeapon, m_iId) : WEAPON_NONE
}

stock UTIL_PlayWeaponAnimation(const Player, const Sequence) {
	set_entvar(Player, var_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(get_entvar(Player, var_body))
	message_end()
}

public dmp7a1_ItemPostFrame(weapon_entity) {
	new id = get_entvar(weapon_entity, var_owner)
	if(!is_user_connected(id))  return HAM_IGNORED
	if(!g_has_dmp7a1[id]) return HAM_IGNORED

	static iClipExtra
	iClipExtra = get_pcvar_num(cvar_clip_dmp7a1)
	new Float:flNextAttack = get_member(id, m_flNextAttack)
	new iBpAmmo = rg_get_user_bpammo(id, WEAPON_MAC10)
	new iClip = get_member(weapon_entity, m_Weapon_iClip)
	new fInReload = get_member(weapon_entity, m_Weapon_fInReload) 

	if(fInReload && flNextAttack <= 0.0 ) {
		new j = min(iClipExtra - iClip, iBpAmmo)
		set_member(weapon_entity, m_Weapon_iClip, iClip + j)
		rg_set_user_bpammo(id, WEAPON_MAC10, iBpAmmo-j)
		set_member(weapon_entity, m_Weapon_fInReload, 0)
		fInReload = 0
	}
	return HAM_IGNORED
}

public dmp7a1_Reload(weapon_entity) {
	new id = get_entvar(weapon_entity, var_owner)
	if(!is_user_connected(id)) return HAM_IGNORED
	if(!g_has_dmp7a1[id]) return HAM_IGNORED

	static iClipExtra
	if(g_has_dmp7a1[id]) iClipExtra = get_pcvar_num(cvar_clip_dmp7a1)

	g_dmp7a1_TmpClip[id] = -1

	new iBpAmmo = rg_get_user_bpammo(id, WEAPON_MAC10)
	new iClip = get_member(weapon_entity, m_Weapon_iClip)

	if(iBpAmmo <= 0) return HAM_SUPERCEDE
	if(iClip >= iClipExtra) return HAM_SUPERCEDE

	g_dmp7a1_TmpClip[id] = iClip
	return HAM_IGNORED
}

public dmp7a1_Reload_Post(weapon_entity)  {
	new id = get_entvar(weapon_entity, var_owner)
	if(!is_user_connected(id)) return HAM_IGNORED
	if(!g_has_dmp7a1[id]) return HAM_IGNORED
	if(g_dmp7a1_TmpClip[id] == -1) return HAM_IGNORED

	set_member(weapon_entity, m_Weapon_iClip, g_dmp7a1_TmpClip[id])
	set_member(weapon_entity, m_flTimeWeaponIdle, dmp7a1_RELOAD_TIME)
	set_member(id, m_flNextAttack, dmp7a1_RELOAD_TIME)
	set_member(weapon_entity, m_Weapon_fInReload, 1)
	UTIL_PlayWeaponAnimation(id, dmp7a1_RELOAD)

	return HAM_IGNORED
}

stock CBaseWeapon__EjectBrass(Float:vecOrigin[3], Float:vecVelocity[3], Float:rotation, model, soundtype) {
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0)
	write_byte(TE_MODEL)
	engfunc(EngFunc_WriteCoord, vecOrigin[0])
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2])
	engfunc(EngFunc_WriteCoord, vecVelocity[0])
	engfunc(EngFunc_WriteCoord, vecVelocity[1])
	engfunc(EngFunc_WriteCoord, vecVelocity[2])
	engfunc(EngFunc_WriteAngle, rotation)
	write_short(model)
	write_byte(soundtype)
	write_byte(25) // 2.5 seconds
	message_end()
}
