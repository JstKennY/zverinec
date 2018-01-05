#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <xs>

#define PLUGIN "[ZP]ExtraDualInfinity"
#define VERSION "1.0"
#define AUTHOR "Arwel"

#define CONFIG_CFG_FILE "weapons/dual_infinity.cfg"

#define weaponkey_value 	18318

#define CSW_INFINITY 		CSW_ELITE

new const g_weapon_entity[] = "weapon_elite"
new const g_weapon_event1[] = "events/elite_right.sc"
new const g_weapon_event2[] = "events/elite_left.sc"
new const g_weapon_weaponbox_model[] = "models/w_elite.mdl"

new const weapon_list_txt[] = "weapon_dual_infinity2"

new const weapon_list_sprites[][] = {	
	"sprites/egoist/jb/640hud42.spr",
	"sprites/egoist/jb/640hud43.spr",
	"sprites/egoist/jb/640hud7.spr"
}

new const ViewModel[] = "models/egoist/jb/weapon/v_infinity.mdl"
new const PlayerModel[] = "models/egoist/jb/weapon/p_infinity.mdl"
new const WorldModel[] = "models/egoist/jb/weapon/ujbl_w_weapons.mdl"

new const Sounds[][] = {
	"weapons/egoist/jb/infi-1.wav",
	"weapons/egoist/jb/infi_clipin.wav",
	"weapons/egoist/jb/infi_clipon.wav",
	"weapons/egoist/jb/infi_clipout.wav",
	"weapons/egoist/jb/infi_draw.wav"
}

new Blood[2]

new g_orig_event_dinfinity

new g_HasInfinity[33], g_player_weapon_ammo[33], Float:cl_pushangle[33][3],  g_shoot_anim[33], g_hitgroup[33]
new g_mode[33], g_anim_mode[33]

new pcvar_item_name, pcvar_clipammo, pcvar_bpammo, pcvar_time_fire_normal, pcvar_time_fire_fast

new pcvar_normal_damage_head, pcvar_normal_damage_chest, pcvar_normal_damage_stomach, pcvar_normal_damage_arms, pcvar_normal_damage_legs
new pcvar_fast_damage_head, pcvar_fast_damage_chest, pcvar_fast_damage_stomach, pcvar_fast_damage_arms, pcvar_fast_damage_legs

new Float:cvar_time_fire_normal, Float:cvar_time_fire_fast

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd(weapon_list_txt, "Redirect")
	
	pcvar_item_name=register_cvar("dinfinity_item_name", "Dual Infinity")
	pcvar_bpammo=register_cvar("dinfinity_bpammo", "100")
	pcvar_clipammo=register_cvar("dinfinity_clipammo", "40")
	pcvar_time_fire_normal=register_cvar("dinfinity_fire_normal_period", "0.15")
	pcvar_time_fire_fast=register_cvar("dinfinity_fire_fast_period", "0.02")
	
	pcvar_normal_damage_head=register_cvar("dinfinity_normal_damage_head", "130")
	pcvar_normal_damage_chest=register_cvar("dinfinity_normal_damage_chest", "34")
	pcvar_normal_damage_stomach=register_cvar("dinfinity_normal_damage_stomach", "34")
	pcvar_normal_damage_arms=register_cvar("dinfinity_normal_damage_arms", "34")
	pcvar_normal_damage_legs=register_cvar("dinfinity_normal_damage_legs", "34")
	
	pcvar_fast_damage_head=register_cvar("dinfinity_fast_damage_head", "115")
	pcvar_fast_damage_chest=register_cvar("dinfinity_fast_damage_chest", "30")
	pcvar_fast_damage_stomach=register_cvar("dinfinity_fast_damage_stomach", "30")
	pcvar_fast_damage_arms=register_cvar("dinfinity_fast_damage_arms", "30")
	pcvar_fast_damage_legs=register_cvar("dinfinity_fast_damage_legs", "30")	
	
	ReadSettings()
	
	RegisterHam(Ham_Item_AddToPlayer, g_weapon_entity, "fwAddToPlayer", 1)
	RegisterHam(Ham_Item_Deploy, g_weapon_entity, "fwDeployPost", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, g_weapon_entity, "fwPrimaryAttack")
	RegisterHam(Ham_Weapon_Reload, g_weapon_entity, "fwReloadPre")
	RegisterHam(Ham_Item_PostFrame, g_weapon_entity, "fwItemPostFrame")
	//RegisterHam(Ham_TakeDamage, "player", "fwDamagePre")
	//RegisterHam(Ham_RemovePlayerItem, "player", "fwRemoveItem")
	
	//RegisterHookChain(RG_CBasePlayer_RemovePlayerItem, "Player_RemovePlayerItem", true)
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "Player_TakeDamage", true)
	RegisterHookChain(RG_CBasePlayer_TraceAttack, "Player_TraceAttack", true)
	/*RegisterHam(Ham_TraceAttack, "player", "fwTraceAttackPost", 1)
	RegisterHam(Ham_TraceAttack, "worldspawn", "fwTraceAttackPost", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "fwTraceAttackPost", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "fwTraceAttackPost", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "fwTraceAttackPost", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fwTraceAttackPost", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "fwTraceAttackPost", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "fwTraceAttackPost", 1)*/
	
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")  
	register_forward(FM_UpdateClientData, "fwUpdateClientDataPost", 1)
	register_forward(FM_CmdStart,  "fwCmdStart")
	register_forward(FM_SetModel, "fwSetModel")
	
	new item_name[64]
	
	get_pcvar_string(pcvar_item_name, item_name, charsmax(item_name))
}

public plugin_precache() {
	precache_model(ViewModel)
	precache_model(PlayerModel)
	precache_model(WorldModel)
	
	for(new i; i<=charsmax(Sounds); i++) precache_sound(Sounds[i])

	Blood[0] = precache_model("sprites/bloodspray.spr")
	Blood[1] = precache_model("sprites/blood.spr")	
	
	new tmp[128]
	formatex(tmp, charsmax(tmp), "sprites/egoist/jb/%s.txt", weapon_list_txt)
	precache_generic(tmp)
	
	for(new i; i <= charsmax(weapon_list_sprites); i++) precache_generic(weapon_list_sprites[i])
	
	register_forward(FM_PrecacheEvent, "fwPrecachePost", 1)
}

public ReadSettings() {
	new confdir[64], path[128]
	get_configsdir(confdir, charsmax(confdir))
	formatex(path, charsmax(path), "%s/%s", confdir, CONFIG_CFG_FILE)
	
	server_cmd("exec %s", path)
	server_exec()
	
	cvar_time_fire_normal = get_pcvar_float(pcvar_time_fire_normal)
	cvar_time_fire_fast = get_pcvar_float(pcvar_time_fire_fast)
}

public Redirect(id) client_cmd(id, g_weapon_entity);

public plugin_natives() register_native("ujbl_give_pistol", "give_infinity", 1);

public client_disconnected(id) g_HasInfinity[id] = false;

public give_infinity(id) {
	rg_drop_items_by_slot(id, PISTOL_SLOT)
	g_HasInfinity[id]=true
	
	new ent = rg_give_item(id, g_weapon_entity, GT_REPLACE)
	rg_set_user_bpammo(id, WEAPON_ELITE, get_pcvar_num(pcvar_bpammo))
	set_member(ent, m_Weapon_iClip, get_pcvar_num(pcvar_clipammo))
	//rg_set_user_ammo(ent, WEAPON_ELITE, get_pcvar_num(pcvar_clipammo))
	InfinitySprite(id)	
}

public fwPrecachePost(type, const name[]) {
	if(equal(g_weapon_event1, name) || equal(g_weapon_event2, name)) {
		g_orig_event_dinfinity=get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2) {
	if((eventid != g_orig_event_dinfinity)) return FMRES_IGNORED
	if(!is_valid_player(invoker)) return FMRES_IGNORED
	fm_playback_event(flags|FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fwUpdateClientDataPost(id, SendWeapons, CD_Handle) {
	if(!is_valid_player(id)) return FMRES_IGNORED
	if(get_user_weapon(id) != CSW_INFINITY) return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001)
	return FMRES_HANDLED
}

public fwCmdStart(id, uc_handle, seed) {
	if(!is_valid_player(id)) return
	if(get_user_weapon(id) != CSW_INFINITY) return
		
	static buttons; buttons = get_uc(uc_handle, UC_Buttons)
	if(!(buttons&IN_ATTACK2)) {
		g_mode[id]=0
		return
	}	
	
	static ent;
	ent = get_member(id, m_pActiveItem)	
	if((buttons&IN_ATTACK)) {
		set_member(ent, m_Weapon_flNextPrimaryAttack, cvar_time_fire_normal)
		g_mode[id]=0
		return	
	}	
	
	if(!pev_valid(ent) || get_member(ent, m_Weapon_fInReload) || get_member(ent, m_Weapon_flNextPrimaryAttack) > -0.1) return		
	g_mode[id] = 1
			
	if(get_member(ent, m_Weapon_iClip) != 0) ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)
}

public fwSetModel(ent, model[]) {
	if(!pev_valid(ent)) return FMRES_IGNORED;

	if(!equal(model, g_weapon_weaponbox_model)) return FMRES_IGNORED;

	static classname[33]
	get_entvar(ent, var_classname, classname, charsmax(classname))
		
	if(!equal(classname, "weaponbox")) return FMRES_IGNORED

	static owner;
	owner = get_entvar(ent, var_owner)

	static weap;
	weap = fm_find_ent_by_owner(-1, g_weapon_entity, ent)
	
	if(g_HasInfinity[owner] && pev_valid(weap)) {
		set_entvar(weap, var_impulse, weaponkey_value)
		g_HasInfinity[owner]=false
		
		fm_entity_set_model(ent, WorldModel)
		set_entvar(ent, var_body, 2)
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public fwAddToPlayer(ent, id) {
	if(pev_valid(ent)) {
		if(get_entvar(ent, var_impulse) == weaponkey_value) {
			g_HasInfinity[id] = true
			set_entvar(ent, var_impulse, 0)
			InfinitySprite(id)
			return HAM_HANDLED
		}
	}
	return HAM_IGNORED
}

public fwDeployPost(ent) {
	new id = get_member(ent, m_pPlayer)

	if(!is_valid_player(id)) return
	
	set_entvar(id, var_viewmodel, ViewModel)
	set_entvar(id, var_weaponmodel, PlayerModel)

	playanim(id, 15)

	set_member(ent, m_Weapon_flNextPrimaryAttack, 0.8)

	g_anim_mode[id] =! g_anim_mode[id]
}
	
public fwPrimaryAttack(ent) {
	new id = get_member(ent, m_pPlayer)
	if(!is_valid_player(id)) return
	
	get_entvar(id, var_punchangle, cl_pushangle[id])
	g_player_weapon_ammo[id] = get_member(ent, m_Weapon_iClip)
}

public Player_TraceAttack(ent, attacker, Float:damage, Float:dir[3], ptr, damage_type) {
	if(!is_valid_player(attacker)) return 
	if(get_user_weapon(attacker) != CSW_INFINITY) return 
			
	static Float:fEnd[3]
	get_tr2(ptr, TR_vecEndPos, fEnd)
	make_bullet_decals(attacker, fEnd)
	g_hitgroup[attacker] = get_tr2(ptr, TR_iHitgroup)
}

public fwReloadPre(ent) {
	new id = get_member(ent, m_pPlayer)
	if(!is_valid_player(id)) return HAM_IGNORED

	static bpammo;
	bpammo = rg_get_user_bpammo(id, WEAPON_ELITE)
	
	static clip;
	clip = get_member(ent, m_Weapon_iClip)
	
	if(bpammo > 0 && clip < get_pcvar_num(pcvar_clipammo)) {
		set_member(ent, m_Weapon_fInSpecialReload, 0)
		set_member(id, m_flNextAttack, 4.4)
		set_member(ent, m_flTimeWeaponIdle, 4.4)
		set_member(ent, m_Weapon_flNextPrimaryAttack, 4.4)
		set_member(ent, m_Weapon_flNextSecondaryAttack, 4.4)
		set_member(ent, m_Weapon_fInReload, 1)

		playanim(id, 14)
	}
	return HAM_SUPERCEDE
}

public fwItemPostFrame(ent) {
	new id = get_member(ent, m_pPlayer)
	
	if(!is_valid_player(id)) return
	 
	static bpammo; 
	bpammo = rg_get_user_bpammo(id, WEAPON_ELITE)
	static clip;
	clip = get_member(ent, m_Weapon_iClip)
	
	if(clip < g_player_weapon_ammo[id]) {
		g_player_weapon_ammo[id] = clip
	
		new Float:push[3]
		get_entvar(id, var_punchangle, push)
		
		xs_vec_sub(push, cl_pushangle[id], push)
		xs_vec_mul_scalar(push, 0.8, push)
		xs_vec_add(push, cl_pushangle[id], push)
	
		if(g_mode[id] == 0) {
			if(g_shoot_anim[id] == 0) playanim(id, 2)
			else playanim(id, 12)	
			
			set_member(ent, m_Weapon_flNextPrimaryAttack, cvar_time_fire_normal)
		}
		else {
			if(g_shoot_anim[id] == 0) {
				playanim(id, (g_anim_mode[id]) ? 18 : 16)
				
				push[0] += 1.0
				push[1] -= 1.5
			}
			else {
				playanim(id, (g_anim_mode[id]) ? 19:17)
				
				push[0] += 1.0
				push[1] += 1.5
			}
			
			set_member(ent, m_Weapon_flNextPrimaryAttack, cvar_time_fire_fast)
		}
		
		g_shoot_anim[id] =! g_shoot_anim[id]		
				
		set_entvar(id, var_punchangle, push)	
		emit_sound(id, CHAN_WEAPON, Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}
	
	if(get_member(ent, m_Weapon_fInReload) && get_member(id, m_flNextAttack) <= 0.0 ) {
		set_member(ent, m_Weapon_fInReload, 0)
		for(new i = clip; i < get_pcvar_num(pcvar_clipammo); i++) {
			if(bpammo == 0) break
			bpammo--
			clip++
		}	
		

		set_member(ent, m_Weapon_iClip, clip)
		//rg_set_user_ammo(ent, WEAPON_ELITE, clip)
		rg_set_user_bpammo(id, WEAPON_ELITE, bpammo)
	}
}

public Player_TakeDamage(id, weapon, attacker, Float:damage, bitsDamageType) {
	if(!is_valid_player(attacker)) return
	if(get_user_weapon(attacker) != CSW_INFINITY) return
	
	new Float:Damage
	switch(g_hitgroup[attacker]) {
		case HIT_HEAD: Damage = get_pcvar_float((g_mode[attacker]) ? pcvar_fast_damage_head : pcvar_normal_damage_head)
		case HIT_CHEST: Damage = get_pcvar_float((g_mode[attacker]) ? pcvar_fast_damage_chest : pcvar_normal_damage_chest)
		case HIT_STOMACH: Damage = get_pcvar_float((g_mode[attacker]) ? pcvar_fast_damage_stomach : pcvar_normal_damage_stomach)
		case HIT_LEFTARM: Damage = get_pcvar_float((g_mode[attacker]) ? pcvar_fast_damage_arms : pcvar_normal_damage_arms)
		case HIT_RIGHTARM: Damage = get_pcvar_float((g_mode[attacker]) ? pcvar_fast_damage_arms : pcvar_normal_damage_arms)
		case HIT_LEFTLEG: Damage = get_pcvar_float((g_mode[attacker]) ? pcvar_fast_damage_legs : pcvar_normal_damage_legs)
		case HIT_RIGHTLEG: Damage = get_pcvar_float((g_mode[attacker]) ? pcvar_fast_damage_legs : pcvar_normal_damage_legs)
	}

	SetHookChainArg(4, ATYPE_FLOAT, Damage)
}

/*public Player_RemovePlayerItem(id, ent) {
	if(!is_valid_player(id)) return
		
	new classname[62]
	get_entvar(ent, var_classname, classname, 61)
	
	if(!equal(classname, g_weapon_entity)) return
	DefaultSprite(id)	
}*/

public make_bullet_decals(id, Float:Origin[3]) {
	new target, body
	get_user_aiming(id, target, body, 999999)
	
	if(is_user_alive(target)) {
		new Float:fStart[3], Float:fEnd[3], Float:fRes[3], Float:fVel[3]
		get_entvar(id, var_origin, fStart)
			
		velocity_by_aim(id, 64, fVel)
			
		fStart[0] = Origin[0]
		fStart[1] = Origin[1]
		fStart[2] = Origin[2]
		fEnd[0] = fStart[0]+fVel[0]
		fEnd[1] = fStart[1]+fVel[1]
		fEnd[2] = fStart[2]+fVel[2]
	
		new res
		engfunc(EngFunc_TraceLine, fStart, fEnd, 0, target, res)
		get_tr2(res, TR_vecEndPos, fRes)
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
		write_byte(TE_BLOODSPRITE)
		write_coord(floatround(fStart[0])) 
		write_coord(floatround(fStart[1])) 
		write_coord(floatround(fStart[2])) 
		write_short(Blood[0])
		write_short(Blood[1])
		write_byte(70)
		write_byte(random_num(1,2))
		message_end()
	} 	
	else {
		new decal = 41
		if(target) {
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_DECAL)
			write_coord(floatround(Origin[0]))
			write_coord(floatround(Origin[1]))
			write_coord(floatround(Origin[2]))
			write_byte(decal)
			write_short(target)
			message_end()
		}
		else {	
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_WORLDDECAL)
			write_coord(floatround(Origin[0]))
			write_coord(floatround(Origin[1]))
			write_coord(floatround(Origin[2]))
			write_byte(decal)
			message_end()
		}
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		write_coord(floatround(Origin[0]))
		write_coord(floatround(Origin[1]))
		write_coord(floatround(Origin[2]))
		write_short(id)
		write_byte(decal)
		message_end()
	}
}

public InfinitySprite(id) {
	message_begin( MSG_ONE, get_user_msgid("WeaponList"), .player=id )
	write_string(weapon_list_txt) 
	write_byte(10)
	write_byte(120)
	write_byte(-1)
	write_byte(-1)
	write_byte(1)
	write_byte(1)
	write_byte(CSW_INFINITY)
	write_byte(0)
	message_end()
}

/*public DefaultSprite(id) {
	message_begin( MSG_ONE, get_user_msgid("WeaponList"), .player=id )
	write_string(g_weapon_entity) 
	write_byte(10)
	write_byte(120)
	write_byte(-1)
	write_byte(-1)
	write_byte(1)
	write_byte(1)
	write_byte(CSW_INFINITY)
	write_byte(0)
	message_end()
}*/

public is_valid_player(id) {	
	if(!is_user_alive(id)) return false
	if(!g_HasInfinity[id]) return false
	return true	
}

stock playanim(player,anim) {
	set_entvar(player, var_weaponanim, anim)
	
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, player)
	write_byte(anim)
	write_byte(get_entvar(player, var_body))
	message_end()
}

stock fm_playback_event(flags, invoker, eventindex, Float:delay, const Float:origin[3], const Float:angles[3], Float:fparam1, Float:fparam2, iparam1, iparam2, bparam1, bparam2) {
	return engfunc(EngFunc_PlaybackEvent, flags, invoker, eventindex, delay, origin, angles, fparam1, fparam2, iparam1, iparam2, bparam1, bparam2);
}

stock fm_find_ent_by_owner(index, const classname[], owner, jghgtype = 0) {
	new strtype[11] = "classname", ent = index;
	switch (jghgtype) {
		case 1: strtype = "target";
		case 2: strtype = "targetname";
	}

	while ((ent = engfunc(EngFunc_FindEntityByString, ent, strtype, classname)) && get_entvar(ent, var_owner) != owner) {}
	return ent;
}

stock fm_entity_set_model(index, const model[]) return engfunc(EngFunc_SetModel, index, model);