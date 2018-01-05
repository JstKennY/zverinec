#include <amxmodx>
#include <xs>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <jbe_core>

#define PLUGIN		"[UJBL] Magic stick"
#define VERSION		"2.0.0"
#define AUTHOR 		"Opo4uMapy & Minni Mouse"

#define FIRERATE 	1.8
#define HITSD 		0.7
#define DAMAGE 		30.0
#define DAMAGE_MULTI 	2.0

#define CSW_WPN 	CSW_KNIFE
#define weapon		"weapon_knife"

new const snd_hit[][] = { "egoist/jb/days_mode/magic/magic_hit1.wav" }
new const snd_fire[][] = { "egoist/jb/days_mode/magic/chill.wav" }

new const MAGIC_MODEL[][] = { "models/egoist/jb/days_mode/magic/v_magic_stick.mdl", "models/egoist/jb/days_mode/magic/p_magic_stick.mdl" }

new Float:g_flLastFireTime[33], g_HasRifle[33]
new g_sprBeam, g_sprExp, g_sprBlood, sprite_ability

const ANIM_FIRE = 1
const ANIM_DRAW = 3
const WPNKEY = 2816

new g_iDayModeGG, HamHook:g_iHamHookForwards[13];

new const g_szHamHookEntityBlock[][] = {
	"func_vehicle", // ����������� ������
	"func_tracktrain", // ����������� �����
	"func_tank", // ����������� �����
	"game_player_hurt", // ��� ��������� ������� ������ �����������
	"func_recharge", // ���������� ������ �����������
	"func_healthcharger", // ���������� ��������� ��������
	"game_player_equip", // ����� ������
	"player_weaponstrip", // �������� �� ������
	"trigger_hurt", // ������� ������ �����������
	"trigger_gravity", // ������������� ������ ���� ����������
	"armoury_entity", // ������ ������� �� �����, ������, ����� ��� �������
	"weaponbox", // ������ ����������� �������
	"weapon_shield" // ���
};


public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)

	new i;
	for(i = 0; i <= 7; i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Use, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", 0));
	for(i = 8; i <= 12; i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Touch, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", 0));

	//Event
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_event("CurWeapon", "event_CurWeapon", "b", "1=1")

	//Fm (Forward)
	//register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	
	//Hamset_pdata_float
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon, "PrimaryAttack_Pre", 0)
	RegisterHookChain(RG_CBasePlayer_Killed, "Player_Killed_Post")
	//RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_Item_Deploy, weapon, "fw_Deploy_Post", 1)
	RegisterHam(Ham_Item_AddToPlayer, weapon, "fw_AddToPlayer")
	RegisterHam(Ham_Weapon_SecondaryAttack, weapon, "SecondaryAttack_Post", true)

	g_iDayModeGG = jbe_register_day_mode("JBE_DAY_MODE_GARRY_GUN", 0, 180);
}

public plugin_precache() {
	static i

	for(i = 0; i < sizeof MAGIC_MODEL; i++) precache_model(MAGIC_MODEL[i])

	g_sprBlood = precache_model("sprites/blood.spr")
	g_sprBeam = precache_model("sprites/lgtning.spr")
	g_sprExp = precache_model("sprites/deimosexp.spr")

	sprite_ability = precache_model("sprites/green.spr")
	
	engfunc(EngFunc_PrecacheGeneric, "sound/egoist/jb/days_mode/magic/magic.mp3");

	for(i = 0; i < sizeof snd_fire; i++) precache_sound(snd_fire[i])
	for(i = 0; i < sizeof snd_hit; i++) precache_sound(snd_hit[i])
}

public HamHook_EntityBlock() return HAM_SUPERCEDE;

public jbe_day_mode_start(iDayMode, iAdmin) {
	if(iDayMode == g_iDayModeGG) {
		new i;
		for(i = 0; i <= MaxClients; i++) {
			if(!is_user_alive(i)) continue
			if(jbe_get_user_team(i) == 1) {
				rg_remove_all_items(i, false)                 // strip
				rg_give_item(i, "weapon_knife", GT_REPLACE);          // strip
				set_member(i, m_bHasPrimary, false)                  // strip
				set_entvar(i, var_maxspeed, 220.0)
				set_entvar(i, var_health, 100.0)
				give_rifle(i)
				rg_give_item(i, "weapon_knife", GT_REPLACE); 
				rg_give_item(i, "item_kevlar", GT_REPLACE); 
			} 
			else if(jbe_get_user_team(i) == 2) {
				rg_remove_all_items(i, false)
				give_rifle(i)
				rg_give_item(i, "weapon_knife", GT_REPLACE); 
				rg_give_item(i, "item_kevlar", GT_REPLACE); 
				set_entvar(i, var_health, 300.0)
				set_entvar(i, var_maxspeed, 300.0)
			}
		}
		
		for(i = 0; i < sizeof(g_iHamHookForwards); i++) EnableHamForward(g_iHamHookForwards[i]);
		client_cmd(0, "mp3 play sound/egoist/jb/days_mode/magic/magic.mp3");
	}
}

public jbe_day_mode_ended(iDayMode, iWinTeam) {
	if(iDayMode == g_iDayModeGG) {
		new i;
		for(i = 0; i < sizeof(g_iHamHookForwards); i++) DisableHamForward(g_iHamHookForwards[i]);
		for(i = 1; i <= MaxClients; i++) {
			if(!is_user_alive(i)) return;
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
}

public event_CurWeapon(id) {
	if(!is_user_alive(id)) return;
	if(!g_HasRifle[id] || get_user_weapon(id) != CSW_WPN) return;
		
	set_entvar(id, var_viewmodel, "models/egoist/jb/days_mode/magic/v_magic_stick.mdl");
	set_entvar(id, var_weaponmodel, "models/egoist/jb/days_mode/magic/p_magic_stick.mdl");
}

public Player_Killed_Post(victim, attacker, shouldgib) {
	if(!is_user_connected(victim)) return HC_CONTINUE;
	g_HasRifle[victim] = false;

	return HC_CONTINUE;
}

public Event_NewRound() {
	for(new i = 1; i <= MaxClients; i++) {
		if(!is_user_connected(i)) continue;
		g_HasRifle[i] = false;
	}
}

public SecondaryAttack_Post(Weapon) return HAM_SUPERCEDE;

public give_rifle(id) {
	if(!is_user_alive(id)) return;

	g_HasRifle[id] = true;
	rg_give_item(id, "weapon_knife", GT_REPLACE);	
	if(get_user_weapon(id) == CSW_KNIFE) {
		set_entvar(id, var_viewmodel, "models/egoist/jb/days_mode/magic/v_magic_stick.mdl");
		set_entvar(id, var_weaponmodel, "models/egoist/jb/days_mode/magic/p_magic_stick.mdl");
		set_wpnanim(id, 3);
	}
}

public PrimaryAttack_Pre(id) {
	if(!is_user_alive(id)) return HAM_IGNORED;
	if(!g_HasRifle[id]) return HAM_IGNORED	;	
	if(get_user_weapon(id) != CSW_WPN) return HAM_IGNORED;
		
	static iButton;
	iButton = get_entvar(id, var_button);
	
	if(iButton & IN_ATTACK) {
		set_entvar(id, var_button, iButton & ~IN_ATTACK);
		
		static Float:flCurTime;
		flCurTime = get_gametime();
		
		if(flCurTime - g_flLastFireTime[id] < FIRERATE) return HAM_IGNORED;
			
		static iWpnID;
		iWpnID = get_member(id, m_pActiveItem);
		if(pev_valid(iWpnID) != 2) return HAM_IGNORED;
		
		set_member(iWpnID, m_Weapon_flNextPrimaryAttack, FIRERATE);
		set_member(iWpnID, m_Weapon_flNextSecondaryAttack, FIRERATE);
		set_member(iWpnID, m_Weapon_flTimeWeaponIdle, FIRERATE);

		g_flLastFireTime[id] = flCurTime;
		primary_attack(id);
		make_punch(id, 50);
		
		return HAM_IGNORED;
	}
	return HAM_IGNORED;
}

/*public fw_CmdStart(id, handle, seed)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED
	
	if(!g_HasRifle[id])
		return FMRES_IGNORED
			
	if(get_user_weapon(id) != CSW_WPN)
		return FMRES_IGNORED
		
	static iButton
	iButton = get_uc(handle, UC_Buttons)
	
	if(iButton & IN_ATTACK)
	{
		set_uc(handle, UC_Buttons, iButton & ~IN_ATTACK)
		
		static Float:flCurTime
		flCurTime = halflife_time()
		
		if(flCurTime - g_flLastFireTime[id] < FIRERATE)
			return FMRES_IGNORED
			
		static iWpnID
		iWpnID = get_pdata_cbase(id, 373, 5)
		if(pev_valid(iWpnID ) != 2) return FMRES_IGNORED
		
		set_pdata_float(iWpnID, 46, FIRERATE, 4)
		set_pdata_float(iWpnID, 47, FIRERATE, 4)
		set_pdata_float(iWpnID, 48, FIRERATE, 4)

		g_flLastFireTime[id] = flCurTime
		primary_attack(id)
		make_punch(id, 50)
		
		return FMRES_IGNORED
	}
	return FMRES_IGNORED
}*/

public fw_UpdateClientData_Post(id, sendweapons, handle) {
	if(!is_user_alive(id)) return FMRES_IGNORED
	if(!g_HasRifle[id]) return FMRES_IGNORED
	if(get_user_weapon(id) != CSW_WPN) return FMRES_IGNORED
		
	set_cd(handle, CD_flNextAttack, get_gametime() + 0.001)
	return FMRES_HANDLED
}

public fw_Deploy_Post(wpn) {
	static id;
	id = get_member(wpn, m_pPlayer);
	
	if(is_user_connected(id) && g_HasRifle[id]) {
		set_entvar(id, var_viewmodel, "models/egoist/jb/days_mode/magic/v_magic_stick.mdl");
		set_entvar(id, var_weaponmodel, "models/egoist/jb/days_mode/magic/p_magic_stick.mdl");
		//set_pev(id, pev_viewmodel2,  "models/v_palka.mdl")
		//set_pev(id, pev_weaponmodel2, "models/p_palka.mdl")
		set_wpnanim(id, 3);
	}
	return HAM_IGNORED
}

public fw_AddToPlayer(wpn, id) {
	if(is_user_connected(id) || get_entvar(wpn, var_impulse) != WPNKEY) return HAM_IGNORED;

	g_HasRifle[id] = true;
	get_entvar(wpn, var_impulse, 0);
	return HAM_IGNORED;
}

public primary_attack(id) {
	set_wpnanim(id, ANIM_FIRE)
	set_entvar(id, var_punchangle, Float:{ -1.5, 0.0, 0.0 })
	emit_sound(id, CHAN_WEAPON, snd_fire[random_num(0, sizeof snd_fire - 1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

	static iTarget, iBody, iEndOrigin[3]
	get_user_origin(id, iEndOrigin, 3)

	fire_effects(id, iEndOrigin)
	get_user_aiming(id, iTarget, iBody)

	new iEnt = rg_create_entity("info_target", false)
	
	static Float:flOrigin[3]
	IVecFVec(iEndOrigin, flOrigin)
	set_entvar(iEnt, var_origin, flOrigin)

	remove_entity(iEnt)
	
	if(is_user_alive(iTarget) && (jbe_get_user_team(iTarget) != jbe_get_user_team(id))) {
		if(HITSD > 0.0) {
			static Float:flVelocity[3]
			get_user_velocity(iTarget, flVelocity)
			xs_vec_mul_scalar(flVelocity, HITSD, flVelocity)
			set_user_velocity(iTarget, flVelocity)	

			new iHp = get_entvar(iTarget, var_health)
			new Float:iDamage, iBloodScale
			if(iBody == HIT_HEAD) {
				iDamage = DAMAGE
				iBloodScale = 10
			}
			else {
				iDamage = DAMAGE * DAMAGE_MULTI
				iBloodScale = 25
			}
			if(iHp > iDamage)  {
				make_blood(iTarget, iBloodScale)
				set_entvar(iTarget, var_health, iHp-iDamage)
				damage_effects(iTarget)
			}
			else if(iHp <= iDamage) {
				balls_effects(iTarget)
				ExecuteHamB(Ham_Killed, iTarget, id, 2)
			}
		}
	}
	else emit_sound(id, CHAN_WEAPON, snd_hit[random_num(0, sizeof snd_hit - 1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

public client_putinserver(id) g_HasRifle[id] = false;
public client_disconnected(id) g_HasRifle[id] = false;

stock fire_effects(id, iEndOrigin[3]) {
	UTIL_PlayWeaponAnimation(id, 5)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte (TE_BEAMENTPOINT)
	write_short(id | 0x1000)
	write_coord(iEndOrigin[0])      // ����� ����: x
	write_coord(iEndOrigin[1])      // ����� ����: y
	write_coord(iEndOrigin[2])      // ����� ����: z
	write_short(g_sprBeam)
	write_byte(0)
	write_byte(5)
	write_byte(1)
	write_byte(30)
	write_byte(40)
	write_byte(255)
	write_byte(0)
	write_byte(0)
	write_byte(1000)
	write_byte(0)
	message_end()
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(3)
	write_coord(iEndOrigin[0])
	write_coord(iEndOrigin[1])
	write_coord(iEndOrigin[2])
	write_short(g_sprExp)
	write_byte(10)
	write_byte(15)
	write_byte(4)
	message_end()
}

stock balls_effects(index) {
	static Float:flOrigin[3]
	get_entvar(index, var_origin, flOrigin)
	message_begin (MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( TE_SPRITETRAIL ) // Throws a shower of sprites or models
	engfunc(EngFunc_WriteCoord, flOrigin[ 0 ]) // start pos
	engfunc(EngFunc_WriteCoord, flOrigin[ 1 ])
	engfunc(EngFunc_WriteCoord, flOrigin[ 2 ] + 200.0)
	engfunc(EngFunc_WriteCoord, flOrigin[ 0 ]) // velocity
	engfunc(EngFunc_WriteCoord, flOrigin[ 1 ])
	engfunc(EngFunc_WriteCoord, flOrigin[ 2 ] + 20.0)
	write_short(sprite_ability) // spr
	write_byte(15) // (count)
	write_byte(random_num(27,30)) // (life in 0.1's)
	write_byte(2) // byte (scale in 0.1's)
	write_byte(random_num(30,70)) // (velocity along vector in 10's)
	write_byte(40) // (randomness of velocity in 10's)
	message_end()
}

stock damage_effects(id) {
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("Damage"), _, id)
	write_byte(0)
	write_byte(0)
	write_long(DMG_NERVEGAS)
	write_coord(0) 
	write_coord(0)
	write_coord(0)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), {0,0,0}, id)
	write_short(1<<13)
	write_short(1<<14)
	write_short(0x0000)
	write_byte(0)
	write_byte(255)
	write_byte(0)
	write_byte(100) 
	message_end()
		
	message_begin(MSG_ONE, get_user_msgid("ScreenShake"), {0,0,0}, id)
	write_short(0xFFFF)
	write_short(1<<13)
	write_short(0xFFFF) 
	message_end()

	static Float:flOrigin[3]
	get_entvar(id, var_origin, flOrigin)

	message_begin (MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_SPRITETRAIL) // Throws a shower of sprites or models
	engfunc(EngFunc_WriteCoord, flOrigin[0]) // start pos
	engfunc(EngFunc_WriteCoord, flOrigin[1])
	engfunc(EngFunc_WriteCoord, flOrigin[2] + 200.0)
	engfunc(EngFunc_WriteCoord, flOrigin[0]) // velocity
	engfunc(EngFunc_WriteCoord, flOrigin[1])
	engfunc(EngFunc_WriteCoord, flOrigin[2] + 20.0)
	write_short(sprite_ability) // spr
	write_byte(15) // (count)
	write_byte(random_num(27,30)) // (life in 0.1's)
	write_byte(2) // byte (scale in 0.1's)
	write_byte(random_num(30,70)) // (velocity along vector in 10's)
	write_byte(40) // (randomness of velocity in 10's)
	message_end()
}

stock make_blood(id, scale) {
	new Float:iVictimOrigin[3]
	get_entvar(id, var_origin, iVictimOrigin)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(115)
	write_coord(floatround(iVictimOrigin[0]+random_num(-20,20))) 
	write_coord(floatround(iVictimOrigin[1]+random_num(-20,20))) 
	write_coord(floatround(iVictimOrigin[2]+random_num(-20,20))) 
	write_short(g_sprBlood)
	write_short(g_sprBlood) 
	write_byte(248) 
	write_byte(scale) 
	message_end()
}

stock set_wpnanim(id, anim) {
	set_entvar(id, var_weaponanim, anim)
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(get_entvar(id, var_body))
	message_end()
}

stock UTIL_PlayWeaponAnimation(const Player, const Sequence) {
	set_entvar(Player, var_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(0)
	message_end()
}

stock make_punch(id, velamount) {
	static Float:flNewVelocity[3], Float:flCurrentVelocity[3]
	velocity_by_aim(id, -velamount, flNewVelocity)
	get_user_velocity(id, flCurrentVelocity)
	xs_vec_add(flNewVelocity, flCurrentVelocity, flNewVelocity)
	set_user_velocity(id, flNewVelocity)	
}

stock PlayerHp_Ga(hp) 
{
	new Count, Hp
	for(new id = 1; id <= get_maxplayers(); id++) {
		if (is_user_connected(id) && jbe_get_user_team(id) == 1 && !is_user_bot(id)) Count++
	}
	Hp = hp * Count
	return Hp
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