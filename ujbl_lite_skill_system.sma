#include <amxmodx>
#include <old_menu>
#include <reapi>
#include <hamsandwich>

native jbe_get_day_mode();
native jbe_get_status_duel();
native jbe_informer_offset_up(pId);
native jbe_get_user_lvl_rank(pId);

enum _: PERSON_SKILLS {
	HEALTH = 0,
	ARMOR,
	GRAVITY,
	SPEED
};

new g_iSkillsPerson[33][PERSON_SKILLS];
new g_iBonusLevel[33];
new const g_iSkillsNum[2][11] = {
	{0, 2, 5, 8, 12, 15, 20, 22, 25, 30, 40},
	{0, 3, 5, 10, 15, 20, 25, 30, 40, 45, 50}
};

new const Float:g_fSkillsNum[2][11] = {
	{0.0, 0.03, 0.05, 0.07, 0.1, 0.14, 0.18, 0.2, 0.24, 0.3, 0.35},
	{0.0, 1.0, 3.0, 5.0, 8.0, 10.0, 15.0, 20.0, 25.0, 30.0, 35.0}
};

new const g_iTextInMenu[4][] = { "Здоровье", "Бронь", "Гравитацию", "Скорость" };

public plugin_init() {
	register_plugin("[UJBL] Lite Skill System", "0.0.1", "ToJI9IHGaa");
	register_menucmd(register_menuid("Show_SkillsMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<9), "Handle_SkillsMenu");
	
	register_logevent("LogEvent_RestartGame", 2, "1=Game_Commencing", "1&Restart_Round_");
	
	RegisterHookChain(RG_CBasePlayer_Spawn, "Player_Spawn_Post", true);
	//RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "Player_ResetMaxSpeed_Post", true);
	RegisterHam(Ham_Item_PreFrame, "player", "Ham_PlayerItemPreFrame", true);
	//RegisterHam(Ham_Spawn, "player", "Ham_PlayerSpawn", true);
}

public Ham_PlayerItemPreFrame(id) {
	if(!is_user_alive(id) || jbe_get_day_mode() == 3 || jbe_get_status_duel() > 0) return HAM_IGNORED;
	rg_set_user_maxspeed(id, Float:rg_get_user_maxspeed(id) + g_fSkillsNum[1][g_iSkillsPerson[id][SPEED]]);
	return HAM_IGNORED;
}

public Player_Spawn_Post(id)  {
	if(jbe_get_day_mode() < 3 && jbe_get_status_duel() <= 0 && is_user_connected(id) && is_user_alive(id)) {
		rg_set_user_health(id, Float:rg_get_user_health(id) + g_iSkillsNum[0][g_iSkillsPerson[id][HEALTH]]);
		rg_set_user_armor(id, rg_get_user_armor(id) + g_iSkillsNum[1][g_iSkillsPerson[id][ARMOR]], ARMOR_KEVLAR);
		rg_set_user_maxspeed(id, Float:rg_get_user_maxspeed(id) + g_fSkillsNum[1][g_iSkillsPerson[id][SPEED]]);
		rg_set_user_gravity(id, 1.0 - g_fSkillsNum[0][g_iSkillsPerson[id][GRAVITY]]); 
	}
}

public client_putinserver(id) if(is_user_connected(id)) set_task(random_float(1.0, 3.0), "load_skills", id);

public client_disconnected(id) {
	if(task_exists(id)) remove_task(id);
	g_iBonusLevel[id] = 0;
	remove_skills(id);
}

public load_skills(id) {
	g_iBonusLevel[id] = jbe_get_user_lvl_rank(id);
	new iRandom = -1;
	while(g_iBonusLevel[id] != 0) {
		g_iBonusLevel[id]--;
		if(++iRandom > 3) iRandom = 0;
		g_iSkillsPerson[id][iRandom]++;
	}
}

public remove_skills(id) for(new i; i <= 3; i++) g_iSkillsPerson[id][i] = 0;

#define TaskId_RestartGame 1234
public LogEvent_RestartGame() {
	if(task_exists(TaskId_RestartGame)) remove_task(TaskId_RestartGame);
	set_task(10.0, "ResetSkills", TaskId_RestartGame);
}

public ResetSkills() {
	for(new id = 1; id <= MaxClients; id++) {
		if(is_user_connected(id)) {
			remove_skills(id);
			load_skills(id);
		}
	}
}

public Show_SkillsMenu(id) {
	jbe_informer_offset_up(id);
	CreateMenu("\yСистема прокачки навыков^nВаших очков: \w%d^n^n", g_iBonusLevel[id]);
	
	for(new iPos; iPos <= 3; iPos++) {
		if(g_iBonusLevel[id] > 0 && g_iSkillsPerson[id][iPos] < 10) {
			FormatMenu("\y[%d]\w Прокачать: \r%s\R%d/11^n", iPos + 1, g_iTextInMenu[iPos], g_iSkillsPerson[id][iPos] + 1);
			iKeys |= (1<<iPos);
		}
		else FormatMenu("\y[%d]\d Прокачать: %s\R%d/11^n", iPos + 1, g_iTextInMenu[iPos], g_iSkillsPerson[id][iPos] + 1);
	}
	
	if(jbe_get_user_lvl_rank(id) >= 1) {
		FormatMenu("^n\y[5]\w Сбросить навыки");
		iKeys |= (1<<4);
	}
	else FormatMenu("^n\y[5]\d Сбросить навыки");
	
	FormatMenu("^n^n\y[0]\w Выход");
	return ShowMenu("Show_SkillsMenu");
}

public Handle_SkillsMenu(id, iKey) {
	if(iKey == 9) return PLUGIN_HANDLED;
	if(iKey == 4) {
		g_iBonusLevel[id] = jbe_get_user_lvl_rank(id);
		remove_skills(id);
		return Show_SkillsMenu(id);
	}
	g_iBonusLevel[id]--;
	g_iSkillsPerson[id][iKey]++;
	
	if(g_iSkillsPerson[id][iKey] > 10) g_iSkillsPerson[id][iKey] = 10;
	
	return Show_SkillsMenu(id);
}

public plugin_natives() {
	register_native("jbe_open_skills_menu", "Show_SkillsMenu", 1);
	
	register_native("ujbl_set_user_bonus", "ujbl_set_user_bonus", 1);
	register_native("ujbl_get_user_bonus", "_ujbl_get_user_bonus", 1);
	
	register_native("ujbl_get_agility_skills", "_ujbl_get_agility_skills", 1);
	register_native("ujbl_get_lot_skills", "_ujbl_get_lot_skills", 1);
	register_native("ujbl_get_protection_skills", "_ujbl_get_protection_skills", 1);
}

public _ujbl_get_agility_skills(id) return g_iSkillsPerson[id][SPEED];
public _ujbl_get_lot_skills(id) return g_iSkillsPerson[id][HEALTH];
public _ujbl_get_protection_skills(id) return g_iSkillsPerson[id][ARMOR];
public _ujbl_get_user_bonus(id) return g_iBonusLevel[id];
public ujbl_set_user_bonus(id, iNum) g_iBonusLevel[id] = iNum;

stock rg_set_user_gravity(const player, Float:gravity = 1.0) {
	set_entvar(player, var_gravity, Float:gravity);
}

stock Float:rg_get_user_gravity(const player) {
	return Float:get_entvar(player, var_gravity);
}

stock Float:rg_get_user_maxspeed(const player) {
	return Float:get_entvar(player, var_maxspeed);
}

stock rg_set_user_maxspeed(const player, Float:speed = -1.0) {
	if(speed != -1.0) set_entvar(player, var_maxspeed, Float:speed);
	else rg_reset_maxspeed(player);
}

stock Float:rg_get_user_health(const player) {
	return Float:get_entvar(player, var_health);
}

stock rg_set_user_health(const player, Float:health) {
	set_entvar(player, var_health, Float:health);
}