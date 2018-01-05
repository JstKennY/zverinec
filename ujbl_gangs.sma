#include <amxmodx>
#include <amxmisc>
#include <sqlvault_ex>
#include <reapi>
//#include <hamsandwich>
#include <jbe_core>
	
#define jbe_is_user_valid(%0) (%0 && %0 <= MaxClients)
	
#define ADMIN_CREATE	ADMIN_ADMIN

new const g_szVersion[] = "3.1.0";
enum _:GangInfo { Trie:GangMembers, GangName[64], GangHP, GangGravity, GangDamage, GangStamina, GangWeaponDrop, GangKills, NumMembers };
	
enum { VALUE_HP, VALUE_GRAVITY, VALUE_DAMAGE, VALUE_STAMINA, VALUE_WEAPONDROP, VALUE_KILLS };

enum { STATUS_NONE, STATUS_MEMBER, STATUS_ADMIN, STATUS_LEADER };

new const g_szGangValues[][] = { "HP", "Gravity", "Damage", "Stamina", "WeaponDrop", "Kills" };

new const g_szPrefix[] = "^1[^4INFO^1]";


new Trie:g_tGangNames;
new Trie:g_tGangValues;

new SQLVault:g_hVault;

new Array:g_aGangs;

new g_pCreateCost, g_pHealthCost, g_pGravityCost, g_pDamageCost, g_pStaminaCost, g_pWeaponDropCost;
new g_pHealthMax, g_pGravityMax, g_pDamageMax, g_pStaminaMax, g_pWeaponDropMax;
new g_pHealthPerLevel, g_pGravityPerLevel, g_pDamagePerLevel, g_pStaminaPerLevel, g_pWeaponDropPerLevel;

new g_pMaxMembers, g_pNumbersSkills, g_pAdminCreate, g_iSortText;

new g_iGang[33];
	
cvars_init() {
	register_cvar("jb_gang_cost", 			"20000");	/** Цена создания банды 												**/
	register_cvar("jb_health_cost", 		"1000");	/** Цена прокачки HP 													**/
	register_cvar("jb_gravity_cost", 		"1000");	/** Цена прокачки гравитации  											**/
	register_cvar("jb_damage_cost", 		"2500");	/** Цена прокачки урона	 												**/
	register_cvar("jb_stamina_cost", 		"2500");	/** Цена прокачки вынослвости 											**/
	register_cvar("jb_weapondrop_cost", 	"1000");	/** Цена прокачки дропа	 												**/
	register_cvar("jb_health_max", 			"6"	  );	/** Сколько можно прокачивать HP 										**/
	register_cvar("jb_gravity_max", 		"5"   );	/** Сколько можно прокачивать гравитацию								**/
	register_cvar("jb_damage_max", 			"5"   );	/** Сколько можно прокачивать урон 										**/
	register_cvar("jb_stamina_max", 		"5"   );	/** Сколько можно прокачивать выносливость 								**/
	register_cvar("jb_weapondrop_max", 		"10"  );	/** Сколько можно прокачивать дроп 										**/
	register_cvar("jb_health_per", 			"5"   );	/** Сколько выдавать при прокачки										**/
	register_cvar("jb_gravity_per", 		"50"  );	/** Сколько выдавать при прокачки 										**/
	register_cvar("jb_damage_per", 			"2"   );	/** Сколько выдавать при прокачки 										**/
	register_cvar("jb_stamina_per", 		"10"  );	/** Сколько выдавать при прокачки 										**/
	register_cvar("jb_weapondrop_per", 		"1"   );	/** Сколько выдавать при прокачки 										**/
	register_cvar("jb_max_members",			"10"  );	/** Максимальное количество членов клана 								**/
	register_cvar("jb_limit_lock_skills",	"3"   ); 	/** Сколько людей нужно иметь в банде чтобы был доступен пункт "Навыки" **/
	register_cvar("jb_admin_create", 		"0"   ); 	/** Может ли админ создавать банду бесплатно? 							**/

	new szCfgDir[64];
	get_localinfo("amxx_configsdir", szCfgDir, charsmax(szCfgDir));
	server_cmd("exec %s/jb_engine/gang_cvars.cfg", szCfgDir);
	set_task(0.1, "LoadCvars");
}

public LoadCvars() {
	g_pCreateCost = get_cvar_num("jb_gang_cost");
	g_pHealthCost = get_cvar_num("jb_health_cost");
	g_pGravityCost = get_cvar_num("jb_gravity_cost");
	g_pDamageCost = get_cvar_num("jb_damage_cost");
	g_pStaminaCost = get_cvar_num("jb_stamina_cost");
	g_pWeaponDropCost = get_cvar_num("jb_weapondrop_cost");
	g_pHealthMax = get_cvar_num("jb_health_max");
	g_pGravityMax = get_cvar_num("jb_gravity_max");
	g_pDamageMax = get_cvar_num("jb_damage_max");
	g_pStaminaMax = get_cvar_num("jb_stamina_max");
	g_pWeaponDropMax = get_cvar_num("jb_weapondrop_max");
	g_pHealthPerLevel = get_cvar_num("jb_health_per");
	g_pGravityPerLevel = get_cvar_num("jb_gravity_per");
	g_pDamagePerLevel = get_cvar_num("jb_damage_per");
	g_pStaminaPerLevel = get_cvar_num("jb_stamina_per");
	g_pWeaponDropPerLevel = get_cvar_num("jb_weapondrop_per");
	g_pMaxMembers = get_cvar_num("jb_max_members");
	g_pNumbersSkills = get_cvar_num("jb_limit_lock_skills");
	g_pAdminCreate = get_cvar_num("jb_admin_create");
}

public plugin_init() {
	register_plugin("[UJBL] Gang System", g_szVersion, "H3avY Ra1n");
	
	g_aGangs = ArrayCreate(GangInfo);

	g_tGangValues = TrieCreate();
	g_tGangNames = TrieCreate();
	
	g_hVault = sqlv_open_local("jb_gangs", false);
	sqlv_init_ex(g_hVault);
	
	cvars_init();
	//ham_init();
	cmd_init();
	reapi_init();
	
	register_event("DeathMsg", "Event_DeathMsg", "a");
	
	register_menu("Gang Menu", 1023, "GangMenu_Handler");
	register_menu("Skills Menu", 1023, "SkillsMenu_Handler");
	
	for(new i = 0; i < sizeof g_szGangValues; i++) TrieSetCell(g_tGangValues, g_szGangValues[i], i);
	
	LoadGangs();
}

cmd_init() {
	register_clcmd("say_team", "Chat_Text");
	register_clcmd("gang_name", "Cmd_CreateGang");
	register_clcmd("new_gang_name", "ChangeName_Handler");
}

reapi_init() {
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "Player_TakeDamage_Post", true);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "Player_TakeDamage_Pre", false);
	RegisterHookChain(RG_CBasePlayer_Spawn, "Player_Spawn_Post", true);
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "Player_ResetMaxSpeed_Post", true);
}

/*ham_init() {
	RegisterHam(Ham_Spawn, "player", "Ham_PlayerSpawn_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "Ham_TakeDamage_Pre", 0);
	RegisterHam(Ham_TakeDamage, "player", "Ham_TakeDamage_Post", 1);
	RegisterHam(Ham_Item_PreFrame, "player", "Ham_PlayerResetSpeedPost", 1);
}*/

public plugin_natives()  {
	register_native("ujbl_open_gang_menu", "Cmd_Gang", 1);
	
	register_native("is_user_connect_gang", "_is_user_connect_gang", 1);
	register_native("get_user_gang_name", "_get_gang_name", 0);
	register_native("get_user_rang_gang", "_get_user_rang_gang", 1);
}
public bool: _is_user_connect_gang(id)
{
	if(g_iGang[id] > -1) return true;
	return false;
}
public _get_gang_name()
{
	new id = get_param(1);
	new iLen = get_param(3);
	if(!_is_user_connect_gang(id))
	{
		log_amx("[GANG] Error Native 'get_user_gang_name' - Player not connect GANG.");
		return PLUGIN_HANDLED;
	}
	new aData[GangInfo];
	ArrayGetArray(g_aGangs, g_iGang[id], aData);
	set_string(2, aData[GangName], iLen);
	return PLUGIN_HANDLED;
}
public _get_user_rang_gang(id) return getStatus(id, g_iGang[id]);

public Chat_Text(id) {
	if(rg_get_user_team(id) != TEAM_TERRORIST) {
		client_print_color(id, print_team_blue, "%s Вы не заключенный!", g_szPrefix);
		return PLUGIN_HANDLED;
	}
	if(g_iGang[id] <= -1) {
		client_print_color(id, print_team_blue, "%s Вы не в банде!", g_szPrefix);
		return PLUGIN_HANDLED;
	}
	new Args[50];
	read_args(Args, charsmax(Args));
	remove_quotes(Args);
	if(strlen(Args) == 0) {
		client_print_color(id, print_team_blue, "%s ^1Пустое значение ^3невозможно", g_szPrefix);
		return PLUGIN_HANDLED;
	}
	
	new szText[125], szName[35];
	get_user_name(id, szName, charsmax(szName));
	formatex(szText, charsmax(szText), "[%s]: %s", szName, Args);
	replace_all(szText, charsmax(szText), "'", "");
	
	new ColorSay[4][3] = {
		{ 255, 0, 0 },		
		{ 236, 242, 54 },
		{ 35, 142, 124 },
		{ 38, 35, 142 }
	};
	#define ColorSet(%1,%2) ColorSay[getStatus(%1, g_iGang[%1])][%2-1]
	switch(g_iSortText) {
		case 0: {
			set_hudmessage(ColorSet(id, 1), ColorSet(id, 2), ColorSet(id, 3), 0.58, 0.01, 0, 10.0, 10.0);
			g_iSortText++;
		}
		case 1: {
			set_hudmessage(ColorSet(id, 1), ColorSet(id, 2), ColorSet(id, 3), 0.58, 0.07, 0, 10.0, 10.0);
			g_iSortText++;
		}
		case 2: {
			set_hudmessage(ColorSet(id, 1), ColorSet(id, 2), ColorSet(id, 3), 0.58, 0.13, 0, 10.0, 10.0);
			g_iSortText++;
		}
		case 3: {
			set_hudmessage(ColorSet(id, 1), ColorSet(id, 2), ColorSet(id, 3), 0.58, 0.19, 0, 10.0, 10.0);
			g_iSortText = 0;
		}
	}
	
	for(new iClan = 1; iClan <= MaxClients; iClan++) {
		if(g_iGang[iClan] > -1 && rg_get_user_team(iClan) == TEAM_TERRORIST) show_hudmessage(iClan, "[Gang]%s", szText);
	}
	
	return PLUGIN_HANDLED;
}

public client_disconnected(id) g_iGang[id] = -1;
public client_putinserver(id) g_iGang[id] = get_user_gang(id);

public plugin_end() {
	SaveGangs();
	sqlv_close(g_hVault);
}

public Player_Spawn_Post(id) {
	if(!is_user_alive(id) || !is_user_connected(id) || rg_get_user_team(id) != TEAM_TERRORIST || jbe_get_day_mode() >= 3 || jbe_get_status_duel() > 0 || g_iGang[id] == -1) return HC_CONTINUE;
		
	new aData[GangInfo];
	ArrayGetArray(g_aGangs, g_iGang[id], aData);
	
	new iHealth = 100 + aData[GangHP] * g_pHealthPerLevel;
	set_entvar(id, var_health, float(iHealth));
	
	new iGravity = 800 - (g_pGravityPerLevel * aData[GangGravity]);
	set_entvar(id, var_gravity, float(iGravity) / 800.0);
		
	return HC_CONTINUE;
}

public Player_TakeDamage_Pre(iVictim, iInflictor, iAttacker, Float:flDamage, iBits) {
	if(jbe_get_day_mode() >= 3 || jbe_get_status_duel() > 0) return HC_CONTINUE;
	
	if(jbe_is_user_valid(iAttacker)) {
		if(g_iGang[iAttacker] == -1 || rg_get_user_team(iAttacker) != TEAM_TERRORIST) return HC_CONTINUE;
		
		new aData[GangInfo];
		ArrayGetArray(g_aGangs, g_iGang[iAttacker], aData);
		SetHookChainArg(4, ATYPE_FLOAT, flDamage + (g_pDamagePerLevel * (aData[GangDamage])));
	}
	return HC_CONTINUE;
}

public Player_TakeDamage_Post(iVictim, iInflictor, iAttacker, Float:flDamage, iBits) {
	if(!(0 < iAttacker < MaxClients) || !is_user_alive(iAttacker) || !is_user_connected(iAttacker) || jbe_get_day_mode() >= 3 || jbe_get_status_duel() > 0) return HC_CONTINUE;
	if(g_iGang[iAttacker] == -1 || rg_get_user_team(iAttacker) != TEAM_TERRORIST || get_user_weapon(iAttacker) != CSW_KNIFE) return HC_CONTINUE;

	new aData[GangInfo];
	ArrayGetArray(g_aGangs, g_iGang[iAttacker], aData);
	
	new iChance = aData[GangWeaponDrop] * g_pWeaponDropPerLevel;
	
	if(iChance == 0) return HC_CONTINUE;
	
	new bool:bDrop = (random_num(1, 100) <= iChance);
	
	if(bDrop) client_cmd(iVictim, "drop");
	
	return HC_CONTINUE;
}

public Event_DeathMsg() {
	new iKiller = read_data(1);
	new iVictim = read_data(2);
	
	if(!is_user_alive(iKiller) || !is_user_alive(iVictim) || rg_get_user_team(iKiller) != TEAM_TERRORIST || jbe_get_day_mode() >= 3 || jbe_get_status_duel() > 0) return PLUGIN_CONTINUE;
	
	if(g_iGang[iKiller] > -1) {
		new aData[GangInfo];
		ArrayGetArray(g_aGangs, g_iGang[iKiller], aData);
		aData[GangKills]++;
		ArraySetArray(g_aGangs, g_iGang[iKiller], aData);
	}
	return PLUGIN_CONTINUE;
}

public Player_ResetMaxSpeed_Post(id) {
	if(g_iGang[id] == -1 || !is_user_alive(id) || !is_user_connected(id) || rg_get_user_team(id) != TEAM_TERRORIST || jbe_get_day_mode() >= 3 || jbe_get_status_duel() > 0) return HC_CONTINUE;
	
	new aData[GangInfo];
	ArrayGetArray(g_aGangs, g_iGang[id], aData);
	
	if(aData[GangStamina] > 0 && get_entvar(id, var_maxspeed) > 1.0) set_entvar(id, var_maxspeed, 250.0 + (aData[GangStamina] * g_pStaminaPerLevel));
		
	return HC_CONTINUE;
}

public Cmd_Gang(id) {
	if(!is_user_connected(id) || rg_get_user_team(id) != TEAM_TERRORIST || jbe_get_day_mode() >= 3 || jbe_get_status_duel() > 0) {
		client_print_color(id, print_team_blue, "%s Only ^4prisoners ^1can access this menu.", g_szPrefix);
		return PLUGIN_HANDLED;
	}

	jbe_informer_offset_up(id);
	static szMenu[512], iLen, aData[GangInfo], iKeys, iStatus;
	
	iKeys = MENU_KEY_0 | MENU_KEY_4;
	iStatus = getStatus(id, g_iGang[id]);
	
	if(g_iGang[id] > -1) {
		ArrayGetArray(g_aGangs, g_iGang[id], aData);
		iLen = formatex(szMenu, charsmax(szMenu),  "\d[Клан] \yМеню Клана^n\d[Клан] \wНазвание Банды:\y %s^n\d[Клан] \wУбиства клана: \y%d^n", aData[GangName], aData[GangKills]);
		iLen +=	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[Клан] \wВаши деньги: \y%i^n^n", jbe_get_user_money(id));
		iLen +=	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[1] \dВы в клане^n");
	}
	else {
		iLen = 	formatex(szMenu, charsmax(szMenu),  "\d[Клан] \yМеню Клана^n\d[Клан] \wНазвание Банды:\r None^n");
		iLen +=	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[Клан] \wВаши деньги: \w%i^n^n", jbe_get_user_money(id));
		iLen +=	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[1] \wСоздать Банду [%i $]^n",  g_pCreateCost);
		iKeys |= MENU_KEY_1;
	}
	
	if(iStatus > STATUS_MEMBER && g_iGang[id] > -1 && g_pMaxMembers > aData[NumMembers]) {
		iLen +=	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[2] \wПриглосить в Банду^n");
		iKeys |= MENU_KEY_2;
	}
	else iLen +=	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[2] \dПриглосить в Банду^n");
	
	if(g_iGang[id] > -1) {
		if(aData[NumMembers] >= g_pNumbersSkills) {
			iLen +=	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[3] \wНавыки^n");
			iKeys |= MENU_KEY_3;
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[3] \dНавыки [Нужно иметь больше %d-х людей в банде]^n", g_pNumbersSkills);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[3] \dНавыки^n");
	
	if(g_iGang[id] > -1) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[4] \wПокинуть Клан^n");
		iKeys |= MENU_KEY_5;
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[4] \dПокинуть Клан^n");
	
	if(iStatus > STATUS_MEMBER) {
		iLen +=	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[5] \wЛидер-Панель^n");
		iKeys |= MENU_KEY_6;
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[5] \dЛидер-Панель^n");
	
	if(g_iGang[id] > -1) {
		iLen +=	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[6] \wСокланы Онлайн^n");
		iKeys |= MENU_KEY_7;
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[6] \dСокланы Онлайн^n");

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\y[0] \wВыход");
	show_menu(id, iKeys, szMenu, -1, "Gang Menu");
	return PLUGIN_CONTINUE;
}

public GangMenu_Handler(id, iKey) {
	switch((iKey + 1) % 10) {
		case 0: return PLUGIN_HANDLED;
		case 1:  {
			if(g_pAdminCreate && get_user_flags(id) & ADMIN_CREATE) client_cmd(id, "messagemode gang_name");
			else if(jbe_get_user_money(id) <  g_pCreateCost) client_print_color(id, print_team_blue, "%s Недостаточно средств!", g_szPrefix);
			else client_cmd(id, "messagemode gang_name");
		}
		case 2: ShowInviteMenu(id);
		case 3: ShowSkillsMenu(id);
		case 4: ShowLeaveConfirmMenu(id);
		case 5: ShowLeaderMenu(id);
		case 6: ShowMembersMenu(id);	
	}
	return PLUGIN_HANDLED;
}

public Cmd_CreateGang(id) {
	new bool:bAdmin = false;
	if(g_pAdminCreate && get_user_flags(id) & ADMIN_CREATE) bAdmin = true;
	else if(jbe_get_user_money(id) < g_pCreateCost) {
		client_print_color(id, print_team_blue, "%s Недостаточно средств!", g_szPrefix);
		return PLUGIN_HANDLED;
	}
	else if(g_iGang[id] > -1) {
		client_print_color(id, print_team_blue, "%s Ты уже в банде!", g_szPrefix);
		return PLUGIN_HANDLED;
	}
	else if(rg_get_user_team(id) != TEAM_TERRORIST) {
		client_print_color(id, print_team_blue, "%s Нужно быть ^3заключенным ^1чтобы создать банду!", g_szPrefix);
		return PLUGIN_HANDLED;
	}
	
	new szArgs[60];
	read_args(szArgs, charsmax(szArgs));
	
	remove_quotes(szArgs);
	replace_all(szArgs, charsmax(szArgs), "'", "");
	replace_all(szArgs, charsmax(szArgs), "%", "");
	
	if(!szArgs[0]) {
		client_print_color(id, print_team_blue, "%s Название банды пустое.", g_szPrefix);
		return PLUGIN_HANDLED;
	}
	
	if(TrieKeyExists(g_tGangNames, szArgs)) {
		client_print_color(id, print_team_blue, "%s That gang with that name already exists.", g_szPrefix);
		Cmd_Gang(id);
		return PLUGIN_HANDLED;
	}
	
	new aData[GangInfo];
	
	aData[GangName] = szArgs;
	aData[GangHP] = 0;
	aData[GangGravity] = 0;
	aData[GangStamina] = 0;
	aData[GangWeaponDrop] = 0;
	aData[GangDamage] = 0;
	aData[NumMembers] = 0;
	aData[GangMembers] = _:TrieCreate();
	
	ArrayPushArray(g_aGangs, aData);
	
	if(!bAdmin) jbe_set_user_money(id, jbe_get_user_money(id) - g_pCreateCost, true);
	set_user_gang(id, ArraySize(g_aGangs) - 1, STATUS_LEADER);
	
	client_print_color(id, print_team_blue, "%s Вы создали банду под названием '^3%s^1'.", g_szPrefix, szArgs);
	return PLUGIN_HANDLED;
}

public ShowInviteMenu(id) {	
	jbe_informer_offset_up(id);
	new iPlayers[32], iNum;
	get_players(iPlayers, iNum);
	
	new szInfo[6], hMenu;
	hMenu = menu_create("Выбери игрока для приглашения:", "InviteMenu_Handler");
	new szName[32];
	
	for(new i = 0, iPlayer; i < iNum; i++) {
		iPlayer = iPlayers[i];
		
		
		if(iPlayer == id || g_iGang[iPlayer] == g_iGang[id] || rg_get_user_team(iPlayer) != TEAM_TERRORIST) continue;
		get_user_name(iPlayer, szName, charsmax(szName));
		num_to_str(iPlayer, szInfo, charsmax(szInfo));
		menu_additem(hMenu, szName, szInfo);
	}
	menu_display(id, hMenu, 0);
}

public InviteMenu_Handler(id, hMenu, iItem) {
	if(iItem == MENU_EXIT) {
		Cmd_Gang(id);
		return PLUGIN_HANDLED;
	}
	
	new szData[6], iAccess, hCallback, szName[32];
	menu_item_getinfo(hMenu, iItem, iAccess, szData, 5, szName, 31, hCallback);
	
	new iPlayer = str_to_num(szData);

	if(!is_user_connected(iPlayer)) return PLUGIN_HANDLED;
		
	ShowInviteConfirmMenu(id, iPlayer);
	client_print_color(id, print_team_blue, "%s Вы пригласили %s в Вашу банду.", g_szPrefix, szName);
	
	Cmd_Gang(id);
	return PLUGIN_HANDLED;
}

public ShowInviteConfirmMenu(id, iPlayer) {
	jbe_informer_offset_up(id);
	new szName[32];
	get_user_name(id, szName, charsmax(szName));
	
	new aData[GangInfo];
	ArrayGetArray(g_aGangs, g_iGang[id], aData);
	
	new szMenuTitle[128];
	formatex(szMenuTitle, charsmax(szMenuTitle), "%s пригласил Вас в банду %s", szName, aData[GangName]);
	new hMenu = menu_create(szMenuTitle, "InviteConfirmMenu_Handler");
	
	new szInfo[6];
	num_to_str(g_iGang[id], szInfo, 5);
	
	menu_additem(hMenu, "Вступить в банду", szInfo);
	menu_additem(hMenu, "Отказаться", "-1");
	
	menu_display(iPlayer, hMenu, 0);	
}

public InviteConfirmMenu_Handler(id, hMenu, iItem) {
	if(iItem == MENU_EXIT) return PLUGIN_HANDLED;
	
	new szData[6], iAccess, hCallback;
	menu_item_getinfo(hMenu, iItem, iAccess, szData, 5, _, _, hCallback);
	
	new iGang = str_to_num(szData);
	
	if(iGang == -1) return PLUGIN_HANDLED;
	
	if(getStatus(id, g_iGang[id]) == STATUS_LEADER) {
		client_print_color(id, print_team_blue, "%s Лидеры не могут покинуть банду.", g_szPrefix);
		return PLUGIN_HANDLED;
	}
	
	set_user_gang(id, iGang);
	
	new aData[GangInfo];
	ArrayGetArray(g_aGangs, iGang, aData);
	
	client_print_color(id, print_team_blue, "%s Вы успешно вступили в банду ^3%s^1.", g_szPrefix, aData[GangName]);
	
	return PLUGIN_HANDLED;
}
	

public ShowSkillsMenu(id) {
	jbe_informer_offset_up(id);
	static szMenu[512], iLen, iKeys, aData[GangInfo];
	
	if(!iKeys) iKeys = MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5 | MENU_KEY_6 | MENU_KEY_0;
	
	ArrayGetArray(g_aGangs, g_iGang[id], aData);
	iLen = formatex(szMenu, charsmax(szMenu), "\ySkills Menu^n^n");	
	iLen += formatex(szMenu[iLen], 511 - iLen, "\y[1] \wЗдоровье [\rЦена: \y%i $\w] \y[lvl:%i/%i]^n", g_pHealthCost, aData[GangHP], g_pHealthMax);
	iLen += formatex(szMenu[iLen], 511 - iLen, "\y[2] \wГравитация [\rЦена: \y%i $\w] \y[lvl:%i/%i]^n", g_pGravityCost, aData[GangGravity], g_pGravityMax);
	iLen += formatex(szMenu[iLen], 511 - iLen, "\y[3] \wУрон [\rЦена: \y%i $\w] \y[lvl:%i/%i]^n", g_pDamageCost, aData[GangDamage], g_pDamageMax);
	iLen += formatex(szMenu[iLen], 511 - iLen, "\y[4] \wМетание [\rЦена: \y%i $\w] \y[lvl:%i/%i]^n", g_pWeaponDropCost, aData[GangWeaponDrop], g_pWeaponDropMax);
	iLen += formatex(szMenu[iLen], 511 - iLen, "\y[5] \wСкорость [\rЦена: \y%i $\w] \y[lvl:%i/%i]^n", g_pStaminaCost, aData[GangStamina], g_pStaminaMax);
	iLen += formatex(szMenu[iLen], 511 - iLen, "^n\y[0] \wВыход");
	
	show_menu(id, iKeys, szMenu, -1, "Skills Menu");
}

public SkillsMenu_Handler(id, iKey) {
	new aData[GangInfo];
	ArrayGetArray(g_aGangs, g_iGang[id], aData);
	
	switch((iKey + 1) % 10) {
		case 0:  {
			Cmd_Gang(id);
			return PLUGIN_HANDLED;
		}
		case 1: {
			if(aData[GangHP] == g_pHealthMax) {
				client_print_color(id, print_team_blue, "%s Ваша банда уже на максимальном уровне для этого навыка.", g_szPrefix );
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			if(aData[GangHP] >= 3) {
				if(aData[GangKills] < 50) {
					client_print_color(id, print_team_blue, "%s Нужно иметь больше 50 убийств для дальнейшего прогресса.", g_szPrefix );
					ShowSkillsMenu(id);
					return PLUGIN_HANDLED;
				}
			}
			
			new iRemaining = jbe_get_user_money(id) - g_pHealthCost;
			if(iRemaining <= 0) {
				client_print_color(id, print_team_blue, "%s Вам не хватает долларов.", g_szPrefix);
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			
			aData[GangHP]++;
			jbe_set_user_money(id, iRemaining, true);
		}
		case 2: {
			if(aData[GangGravity] ==  g_pGravityMax) {
				client_print_color(id, print_team_blue, "%s Ваша банда уже на максимальном уровне для этого навыка.", g_szPrefix );
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			if(aData[GangGravity] >= 3) {
				if(aData[GangKills] < 100.0) {
					client_print_color(id, print_team_blue, "%s Нужно иметь больше 100 убийств для дальнейшего прогресса.", g_szPrefix );
					ShowSkillsMenu(id);
					return PLUGIN_HANDLED;
				}
			}
			
			new iRemaining = jbe_get_user_money(id) - g_pGravityCost;
			if(iRemaining <= 0) {
				client_print_color(id, print_team_blue, "%s Вам не хватает долларов.", g_szPrefix);
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			
			aData[GangGravity]++;
			jbe_set_user_money(id, iRemaining, true);
		}
		case 3: {
			if(aData[GangDamage] ==  g_pDamageMax) {
				client_print_color(id, print_team_blue, "%s Ваша банда уже на максимальном уровне для этого навыка.", g_szPrefix );
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			if(aData[GangDamage] >= 3) {
				if(aData[GangKills] < 150) {
					client_print_color(id, print_team_blue, "%s Нужно иметь больше 150 убийств для дальнейшего прогресса.", g_szPrefix );
					ShowSkillsMenu(id);
					return PLUGIN_HANDLED;
				}
			}
			
			new iRemaining = jbe_get_user_money(id) - g_pDamageCost;
			if(iRemaining <= 0) {
				client_print_color(id, print_team_blue, "%s Вам не хватает долларов.", g_szPrefix);
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}

			aData[GangDamage]++;
			jbe_set_user_money(id, iRemaining, true);
		}
		case 4: {
			if(aData[GangWeaponDrop] ==  g_pWeaponDropMax) {
				client_print_color(id, print_team_blue, "%s Ваша банда уже на максимальном уровне для этого навыка.", g_szPrefix );
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = jbe_get_user_money(id) - g_pWeaponDropCost;
			if(iRemaining <= 0) {
				client_print_color(id, print_team_blue, "%s Вам не хватает долларов.", g_szPrefix);
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			
			aData[GangWeaponDrop]++;
			jbe_set_user_money(id, iRemaining, true);
		}
		case 5: {
			if(aData[GangStamina] ==  g_pStaminaMax) {
				client_print_color(id, print_team_blue, "%s Ваша банда уже на максимальном уровне для этого навыка.", g_szPrefix );
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			if(aData[GangStamina] >= 2) {
				if(aData[GangKills] < 50) {
					client_print_color(id, print_team_blue, "%s Нужно иметь больше 50 убийств для дальнейшего прогресса.", g_szPrefix );
					ShowSkillsMenu(id);
					return PLUGIN_HANDLED;
				}
			}
			new iRemaining = jbe_get_user_money(id) - g_pStaminaCost;
			if(iRemaining <= 0) {
				client_print_color(id, print_team_blue, "%s Вам не хватает долларов.", g_szPrefix);
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			
			aData[GangStamina]++;
			jbe_set_user_money(id, iRemaining, true);
		}
	}
	ArraySetArray(g_aGangs, g_iGang[id], aData);
	
	new iPlayers[32], iNum, iPlayer;
	new szName[32];
	get_players(iPlayers, iNum);
	
	for(new i = 0; i < iNum; i++) {
		iPlayer = iPlayers[i];
		
		if(iPlayer == id || g_iGang[iPlayer] != g_iGang[id]) continue;	
		client_print_color(iPlayer, print_team_blue, "%s ^3%s ^1обновил навык клана", g_szPrefix, szName);
	}
	client_print_color(id, print_team_blue, "%s Вы успешно обновили навык клана", g_szPrefix);
	ShowSkillsMenu(id);
	
	return PLUGIN_HANDLED;
}

public ShowLeaveConfirmMenu(id) {
	jbe_informer_offset_up(id);
	new hMenu = menu_create("Вы уверены что хотите покинуть банду?", "LeaveConfirmMenu_Handler");
	menu_additem(hMenu, "Да, покинуть.", "0");
	menu_additem(hMenu, "Нет, я передумал", "1");
	
	menu_display(id, hMenu, 0);
}

public LeaveConfirmMenu_Handler(id, hMenu, iItem) {
	if(iItem == MENU_EXIT) return PLUGIN_HANDLED;
	
	new szData[6], iAccess, hCallback;
	menu_item_getinfo(hMenu, iItem, iAccess, szData, 5, _, _, hCallback);
	
	switch(str_to_num(szData)) {
		case 0:  {
			if(getStatus(id, g_iGang[id]) == STATUS_LEADER) {
				client_print_color(id, print_team_blue, "%s Вы должны передать лидерство перед уходом из этой банды или распустить её.", g_szPrefix);
				Cmd_Gang(id);
				return PLUGIN_HANDLED;
			}
			client_print_color(id, print_team_blue, "%s Вы успешно покинули свою банду.", g_szPrefix);
			set_user_gang(id, -1);
			Cmd_Gang(id);
		}
		case 1: Cmd_Gang(id);
	}
	return PLUGIN_HANDLED;
}

public ShowLeaderMenu(id) {
	jbe_informer_offset_up(id);
	new hMenu = menu_create("Панель Лидера", "LeaderMenu_Handler");
	new iStatus = getStatus(id, g_iGang[id]);
	if(iStatus == STATUS_LEADER) {
		menu_additem(hMenu, "Распустить Банду", "0");
		menu_additem(hMenu, "Передать Лидерство", "1");
		menu_additem(hMenu, "Добавить Замвожа", "4");
		menu_additem(hMenu, "Снять Замвожа", "5");
		
	}
	menu_additem(hMenu, "Выгнать с банды Offline", "6");
	menu_additem(hMenu, "Выгнать с банды", "2");
	menu_additem(hMenu, "Сменить название Банды", "3");
	menu_display(id, hMenu, 0);
}

public LeaderMenu_Handler(id, hMenu, iItem) {
	if(iItem == MENU_EXIT) {
		Cmd_Gang(id);
		return PLUGIN_HANDLED;
	}
	
	new iAccess, hCallback, szData[6];
	menu_item_getinfo(hMenu, iItem, iAccess, szData, 5, _, _, hCallback);
	
	switch(str_to_num(szData)) {
		case 0: ShowDisbandConfirmMenu(id);
		case 1: ShowTransferMenu(id);
		case 2: ShowKickMenu(id);
		case 3: client_cmd(id, "messagemode new_gang_name");
		case 4: ShowAddAdminMenu(id);
		case 5:	ShowRemoveAdminMenu(id);
		case 6: ShowKickOfflineMenu(id);
	}
	return PLUGIN_HANDLED;
}

new const g_szRanks[3][32] = { "Бандит", "Заместитель", "Лидер" };
public ShowKickOfflineMenu(id) {
	jbe_informer_offset_up(id);
	new hMenu = menu_create("\rOffline изгнание", "OfflineKick_Handler");
	
	new szBuffer[128], iNum;
	new aData[GangInfo], szGangName[64], iRangs[4], szName[35], szPos[4];
	ArrayGetArray(g_aGangs, g_iGang[id], aData);
	
	for(new iPos; iPos <= sqlv_size_ex(g_hVault); iPos++) {
		sqlv_read_ex(g_hVault, iPos, szName, charsmax(szName), szGangName, charsmax(szGangName), iRangs, 3);
		
		if(equal(szGangName, aData[GangName])) {
			num_to_str(iPos, szPos, charsmax(szPos));
			iNum = str_to_num(iRangs);
			format(szBuffer, charsmax(szBuffer), "%s | %s", szName, g_szRanks[iNum - 1]);
			menu_additem(hMenu, szBuffer, szPos);
		}
	}
	return menu_display(id, hMenu, 0);
}

public OfflineKick_Handler(id, hMenu, iItem) {
	if(iItem == MENU_EXIT) return PLUGIN_HANDLED;
	
	new szData[6], iAccess, hCallback;
	menu_item_getinfo(hMenu, iItem, iAccess, szData, 5, _, _, hCallback);
	
	new aData[GangInfo], szGangName[64], szRangs[4], szName[35];
	ArrayGetArray(g_aGangs, g_iGang[id], aData);
	
	sqlv_read_ex(g_hVault, str_to_num(szData), szName, charsmax(szName), szGangName, charsmax(szGangName), szRangs, 3);
	
	if(!TrieKeyExists(aData[GangMembers], szName)) {
		client_print_color(id, print_team_blue, "%s Ошибка, игрока нету в базе!", g_szPrefix);
		return ShowKickOfflineMenu(id);
	}
	
	if(str_to_num(szRangs) == 3) {
		client_print_color(id, print_team_blue, "%s Лидера выгнать нельзя!", g_szPrefix);
		return ShowKickOfflineMenu(id);
	}
	
	client_print_color(id, print_team_blue, "%s ^3%s^1 был кикнут из банды в ^4Offline^1 режиме", g_szPrefix, szName);
	TrieDeleteKey(aData[GangMembers], szName);
	aData[NumMembers]--;
	ArraySetArray(g_aGangs, g_iGang[id], aData);
	sqlv_remove_ex(g_hVault, szName, aData[GangName]);

	return ShowKickOfflineMenu(id);
}

public ShowDisbandConfirmMenu(id) {
	jbe_informer_offset_up(id);
	new hMenu = menu_create("Ты уверен что хочешь распустить банду?", "DisbandConfirmMenu_Handler");
	menu_additem(hMenu, "Да.", "0");
	menu_additem(hMenu, "Нет. Передумал", "1");
	
	menu_display(id, hMenu, 0);
}

public DisbandConfirmMenu_Handler(id, hMenu, iItem) {
	if(iItem == MENU_EXIT) return PLUGIN_HANDLED;
	
	new szData[6], iAccess, hCallback;
	menu_item_getinfo(hMenu, iItem, iAccess, szData, 5, _, _, hCallback);
	
	switch(str_to_num(szData)) {
		case 0: {
			client_print_color(id, print_team_blue, "%s Ты распустил банду.", g_szPrefix);
			
			new iPlayers[32], iNum;
			get_players(iPlayers, iNum);

			new iPlayer;
			for(new i = 0; i < iNum; i++) {
				iPlayer = iPlayers[i];

				if(iPlayer == id) continue;
				if(g_iGang[id] != g_iGang[iPlayer]) continue;

				client_print_color(iPlayer, print_team_blue, "%s Ваша банда расформирована лидером", g_szPrefix);
				set_user_gang(iPlayer, -1);
			}
			new iGang = g_iGang[id];
			set_user_gang(id, -1);

			ArrayDeleteItem(g_aGangs, iGang);
			Cmd_Gang(id);
		}
		case 1: Cmd_Gang(id);
	}
	return PLUGIN_HANDLED;
}

public ShowTransferMenu(id) {
	jbe_informer_offset_up(id);
	new iPlayers[32], iNum;
	get_players(iPlayers, iNum, "e", "TERRORIST");
	
	new hMenu = menu_create("Передача Лидерства:", "TransferMenu_Handler");
	new szName[32], szData[6];
	
	for(new i = 0, iPlayer; i < iNum; i++) {
		iPlayer = iPlayers[i];

		if(g_iGang[iPlayer] != g_iGang[id] || id == iPlayer) continue;

		get_user_name(iPlayer, szName, charsmax(szName));
		num_to_str(iPlayer, szData, charsmax(szData));
		menu_additem(hMenu, szName, szData);
	}
	menu_display(id, hMenu, 0);
}

public TransferMenu_Handler(id, hMenu, iItem) {
	if(iItem == MENU_EXIT) {
		ShowLeaderMenu(id);
		return PLUGIN_HANDLED;
	}

	new iAccess, hCallback, szData[6], szName[32];
	menu_item_getinfo(hMenu, iItem, iAccess, szData, 5, szName, charsmax(szName), hCallback);
	
	new iPlayer = str_to_num(szData);
	if(!is_user_connected(iPlayer)) {
		client_print_color(id, print_team_blue, "%s That player is no longer connected.", g_szPrefix);
		ShowTransferMenu(id);
		return PLUGIN_HANDLED;
	}

	set_user_gang(iPlayer, g_iGang[id], STATUS_LEADER);
	set_user_gang(id, g_iGang[id], STATUS_ADMIN);
	Cmd_Gang(id);

	new iPlayers[32], iNum, iTemp;
	get_players(iPlayers, iNum);
	for(new i = 0; i < iNum; i++) {
		iTemp = iPlayers[i];
		if(iTemp == iPlayer) {
			client_print_color(iTemp, print_team_blue, "%s Вы новый лидер банды", g_szPrefix);
			continue;
		}
		else if(g_iGang[iTemp] != g_iGang[id]) continue;

		client_print_color(iTemp, print_team_blue, "%s ^3%s^1 новый лидер банды", g_szPrefix, szName);
	}
	return PLUGIN_HANDLED;
}

public ShowKickMenu(id) {
	jbe_informer_offset_up(id);
	new iPlayers[32], iNum;
	get_players(iPlayers, iNum);
	
	new hMenu = menu_create("Выберите кого изгнать из банды:", "KickMenu_Handler");
	new szName[32], szData[6];
	
	for(new i = 0, iPlayer; i < iNum; i++) {
		iPlayer = iPlayers[i];
		if(g_iGang[iPlayer] != g_iGang[id] || id == iPlayer) continue;
			
		get_user_name(iPlayer, szName, charsmax(szName));
		num_to_str(iPlayer, szData, charsmax(szData));
		menu_additem(hMenu, szName, szData);
	}
	menu_display(id, hMenu, 0);
}

public KickMenu_Handler(id, hMenu, iItem) {
	if(iItem == MENU_EXIT) {
		ShowLeaderMenu(id);
		return PLUGIN_HANDLED;
	}
	
	new iAccess, hCallback, szData[6], szName[32];
	menu_item_getinfo(hMenu, iItem, iAccess, szData, 5, szName, charsmax(szName), hCallback);
	new iPlayer = str_to_num(szData);
	if(!is_user_connected(iPlayer)) {
		client_print_color(id, print_team_blue, "%s Игрок не подключен.", g_szPrefix);
		ShowTransferMenu(id);
		return PLUGIN_HANDLED;
	}
	
	set_user_gang(iPlayer, -1);
	Cmd_Gang(id);
	
	new iPlayers[32], iNum, iTemp;
	get_players(iPlayers, iNum);
	for(new i = 0; i < iNum; i++) {
		iTemp = iPlayers[i];
		if(iTemp == iPlayer || g_iGang[iTemp] != g_iGang[id]) continue;
		client_print_color(iTemp, print_team_blue, "%s ^3%s^1 был кикнут из банды", g_szPrefix, szName);
	}
	client_print_color(iPlayer, print_team_blue, "%s Вы были кикнуты из вашей банды", g_szPrefix);
	return PLUGIN_HANDLED;
}

public ChangeName_Handler(id) {
	if(g_iGang[id] == -1 || getStatus(id, g_iGang[id]) == STATUS_MEMBER) return;
	
	new iGang = g_iGang[id];
	new szArgs[64];
	read_args(szArgs, charsmax(szArgs));
	remove_quotes(szArgs);
	
	replace_all(szArgs, charsmax(szArgs), "'", "");
	replace_all(szArgs, charsmax(szArgs), "%", "");
	
	if(!szArgs[0]) {
		client_print_color(id, print_team_blue, "%s Название банды пустое.", g_szPrefix);
		return;
	}
	
	new iPlayers[32], iNum;
	get_players(iPlayers, iNum);
	
	new bool: bInGang[33];
	new iStatus[33];
	
	for(new i = 0, iPlayer; i < iNum; i++) {
		iPlayer = iPlayers[i];
		
		if(g_iGang[id] != g_iGang[iPlayer]) continue;
	
		bInGang[iPlayer] = true;
		iStatus[iPlayer] = getStatus(id, iGang);
		
		set_user_gang(iPlayer, -1);
	}
	new aData[GangInfo];
	ArrayGetArray(g_aGangs, iGang, aData);
	aData[GangName] = szArgs;
	ArraySetArray(g_aGangs, iGang, aData);
	
	for(new i = 0, iPlayer; i < iNum; i++) {
		iPlayer = iPlayers[i];
		if(!bInGang[iPlayer]) continue;
		set_user_gang(iPlayer, iGang, iStatus[id]);
	}
}
	
public ShowAddAdminMenu(id) {
	jbe_informer_offset_up(id);
	new iPlayers[32], iNum;
	new szName[32], szData[6];
	new hMenu = menu_create("Выберите игрока кому дать замвожа:", "AddAdminMenu_Handler");
	
	get_players(iPlayers, iNum);
	
	for(new i = 0, iPlayer; i < iNum; i++) {
		iPlayer = iPlayers[i];
		
		if(g_iGang[id] != g_iGang[iPlayer] || getStatus(iPlayer, g_iGang[iPlayer]) > STATUS_MEMBER) continue;
		
		get_user_name(iPlayer, szName, charsmax(szName));
		num_to_str(iPlayer, szData, charsmax(szData));
		menu_additem(hMenu, szName, szData);
	}
	menu_display(id, hMenu, 0);
}

public AddAdminMenu_Handler(id, hMenu, iItem) {
	if(iItem == MENU_EXIT) {
		menu_destroy(hMenu);
		ShowLeaderMenu(id);
		return PLUGIN_HANDLED;
	}
	
	new iAccess, hCallback, szData[6], szName[32];
	menu_item_getinfo(hMenu, iItem, iAccess, szData, charsmax(szData), szName, charsmax(szName), hCallback);
	new iChosen = str_to_num(szData);
	if(!is_user_connected(iChosen)) {
		menu_destroy(hMenu);
		ShowLeaderMenu(id);
		return PLUGIN_HANDLED;
	}
	
	set_user_gang(iChosen, g_iGang[id], STATUS_ADMIN);
	new iPlayers[32], iNum;
	get_players(iPlayers, iNum);
	for(new i = 0, iPlayer; i < iNum; i++) {
		iPlayer = iPlayers[i];
		
		if(g_iGang[iPlayer] != g_iGang[id] || iPlayer == iChosen) continue;
		client_print_color(iPlayer, print_team_blue, "%s ^3%s ^1стал замвожем банды", g_szPrefix, szName);
	}
	client_print_color(iChosen, print_team_blue, "%s ^1Ты стал замовожем банды.", g_szPrefix);
	menu_destroy(hMenu);
	return PLUGIN_HANDLED;
}

public ShowRemoveAdminMenu(id) {
	jbe_informer_offset_up(id);
	new iPlayers[32], iNum;
	new szName[32], szData[6];
	new hMenu = menu_create("Выбери замвожа для снятия:", "RemoveAdminMenu_Handler");
	get_players(iPlayers, iNum);
	for(new i = 0, iPlayer; i < iNum; i++) {
		iPlayer = iPlayers[i];
		
		if(g_iGang[id] != g_iGang[iPlayer] || getStatus(iPlayer, g_iGang[iPlayer]) != STATUS_ADMIN) continue;
		
		get_user_name(iPlayer, szName, charsmax(szName));
		num_to_str(iPlayer, szData, charsmax(szData));
		menu_additem(hMenu, szName, szData);
	}
	menu_display(id, hMenu, 0);
}

public RemoveAdminMenu_Handler(id, hMenu, iItem) {
	if(iItem == MENU_EXIT) {
		menu_destroy(hMenu);
		ShowLeaderMenu(id);
		return PLUGIN_HANDLED;
	}
	
	new iAccess, hCallback, szData[6], szName[32];
	menu_item_getinfo(hMenu, iItem, iAccess, szData, charsmax(szData), szName, charsmax(szName), hCallback);
	
	new iChosen = str_to_num(szData);
	if(!is_user_connected(iChosen)) {
		menu_destroy(hMenu);
		ShowLeaderMenu(id);
		return PLUGIN_HANDLED;
	}
	
	set_user_gang(iChosen, g_iGang[id], STATUS_MEMBER);
	
	new iPlayers[32], iNum;
	get_players(iPlayers, iNum);
	for(new i = 0, iPlayer; i < iNum; i++) {
		iPlayer = iPlayers[i];
		
		if(g_iGang[iPlayer] != g_iGang[id] || iPlayer == iChosen) continue;
		client_print_color(iPlayer, print_team_blue, "%s ^3%s ^1снять с поста 'Замвож'.", g_szPrefix, szName);
	}
	client_print_color(iChosen, print_team_blue, "%s ^1Тебя сняли с поства замвожа.", g_szPrefix);
	
	menu_destroy(hMenu);
	return PLUGIN_HANDLED;
}
	
public ShowMembersMenu(id) {
	jbe_informer_offset_up(id);
	new szName[64], iPlayers[32], iNum;
	get_players(iPlayers, iNum);
	
	new hMenu = menu_create("Online Бандитов:", "MemberMenu_Handler");
	for(new i = 0, iPlayer; i < iNum; i++) {
		iPlayer = iPlayers[i];
		
		if(g_iGang[id] != g_iGang[iPlayer]) continue;
		
		get_user_name(iPlayer, szName, charsmax(szName));
		
		switch(getStatus(iPlayer, g_iGang[id])) {
			case STATUS_MEMBER: add(szName, charsmax(szName), " \r[Член Банды]");
			case STATUS_ADMIN: add(szName, charsmax(szName), " \r[Замвож]");
			case STATUS_LEADER: add(szName, charsmax(szName), " \r[Лидер]");
		}
		menu_additem(hMenu, szName);
	}
	menu_display(id, hMenu, 0);
}

public MemberMenu_Handler(id, hMenu, iItem) {
	if(iItem == MENU_EXIT) {
		menu_destroy(hMenu);
		Cmd_Gang(id);
		return PLUGIN_HANDLED;
	}
	
	menu_destroy(hMenu);
	ShowMembersMenu(id)
	return PLUGIN_HANDLED;
}

// Credits to Tirant from zombie mod and xOR from xRedirect
public LoadGangs() {
	new szConfigsDir[60];
	get_configsdir(szConfigsDir, charsmax(szConfigsDir));
	add(szConfigsDir, charsmax(szConfigsDir), "/jb_gangs.ini");
	
	new iFile = fopen(szConfigsDir, "rt");
	new aData[GangInfo];
	new szBuffer[512], szData[6], szValue[6], i, iCurGang;
	
	while(!feof(iFile)) {
		fgets(iFile, szBuffer, charsmax(szBuffer));
		
		trim(szBuffer);
		remove_quotes(szBuffer);
		
		if(!szBuffer[0] || szBuffer[0] == ';') continue;
		if(szBuffer[0] == '[' && szBuffer[strlen(szBuffer) - 1] == ']') {
			copy(aData[GangName], strlen(szBuffer) - 2, szBuffer[1]);
			aData[GangHP] = 0;
			aData[GangGravity] = 0;
			aData[GangStamina] = 0;
			aData[GangWeaponDrop] = 0;
			aData[GangDamage] = 0;
			aData[GangKills] = 0;
			aData[NumMembers] = 0;
			aData[GangMembers] = _:TrieCreate();
			
			if(TrieKeyExists(g_tGangNames, aData[GangName])) {
				new szError[256];
				formatex(szError, charsmax(szError), "[JB Gangs] Gang already exists: %s", aData[GangName]);
				continue;
			}
			
			ArrayPushArray(g_aGangs, aData);
			TrieSetCell(g_tGangNames, aData[GangName], iCurGang);
			log_amx("Gang Created: %s", aData[GangName]);
	
			iCurGang++;
			continue;
		}
		
		strtok(szBuffer, szData, 31, szValue, 511, '=');
		trim(szData);
		trim(szValue);
		
		if(TrieGetCell(g_tGangValues, szData, i)) {
			ArrayGetArray(g_aGangs, iCurGang - 1, aData);
			switch(i) {					
				case VALUE_HP: aData[GangHP] = str_to_num(szValue);
				case VALUE_GRAVITY: aData[GangGravity] = str_to_num(szValue);
				case VALUE_STAMINA: aData[GangStamina] = str_to_num(szValue);
				case VALUE_WEAPONDROP: aData[GangWeaponDrop] = str_to_num(szValue);
				case VALUE_DAMAGE: aData[GangDamage] = str_to_num(szValue);
				case VALUE_KILLS: aData[GangKills] = str_to_num(szValue);
			}
			ArraySetArray(g_aGangs, iCurGang - 1, aData);
		}
		else log_amx("[%s][%d] Speels not load.", aData[GangName], str_to_num(szValue));
	}
	
	new Array:aSQL;
	sqlv_read_all_ex(g_hVault, aSQL);
	
	new aVaultData[SQLVaultEntryEx];
	new iGang;
	
	for(i = 0; i < ArraySize(aSQL); i++) {
		ArrayGetArray(aSQL, i, aVaultData);
		
		if(TrieGetCell(g_tGangNames, aVaultData[SQLVEx_Key2], iGang)) {
			ArrayGetArray(g_aGangs, iGang, aData);
			TrieSetCell(aData[GangMembers], aVaultData[SQLVEx_Key1], str_to_num(aVaultData[SQLVEx_Data]));
			aData[NumMembers]++;
			ArraySetArray(g_aGangs, iGang, aData);
		}
	}
	fclose(iFile);
}

public SaveGangs() {
	new szConfigsDir[64];
	get_configsdir(szConfigsDir, charsmax(szConfigsDir));
	
	add(szConfigsDir, charsmax(szConfigsDir), "/jb_gangs.ini");
	
	if(file_exists(szConfigsDir)) delete_file(szConfigsDir);
		
	new iFile = fopen(szConfigsDir, "wt");
	new aData[GangInfo];
	new szBuffer[256];

	for(new i = 0; i < ArraySize(g_aGangs); i++) {
		ArrayGetArray(g_aGangs, i, aData);
		
		formatex(szBuffer, charsmax(szBuffer), "[%s]^n", aData[GangName]);
		fputs(iFile, szBuffer);
		
		formatex(szBuffer, charsmax(szBuffer), "HP=%i^n", aData[GangHP]);
		fputs(iFile, szBuffer);
		
		formatex(szBuffer, charsmax(szBuffer), "Gravity=%i^n", aData[GangGravity]);
		fputs(iFile, szBuffer);
		
		formatex(szBuffer, charsmax(szBuffer), "Stamina=%i^n", aData[GangStamina]);
		fputs(iFile, szBuffer);
		
		formatex(szBuffer, charsmax(szBuffer), "WeaponDrop=%i^n", aData[GangWeaponDrop]);
		fputs(iFile, szBuffer);
		
		formatex(szBuffer, charsmax(szBuffer), "Damage=%i^n", aData[GangDamage]);
		fputs(iFile, szBuffer);
		
		formatex(szBuffer, charsmax(szBuffer), "Kills=%i^n^n", aData[GangKills]);
		fputs(iFile, szBuffer);
	}
	
	fclose(iFile);
}

set_user_gang(id, iGang, iStatus=STATUS_MEMBER) {
	new szName[35];
	get_user_name(id, szName, charsmax(szName));

	new aData[GangInfo];
	
	if(g_iGang[id] > -1) {
		ArrayGetArray(g_aGangs, g_iGang[id], aData);
		TrieDeleteKey(aData[GangMembers], szName);
		aData[NumMembers]--;
		ArraySetArray(g_aGangs, g_iGang[id], aData);
		
		sqlv_remove_ex(g_hVault, szName, aData[GangName]);
	}
	if(iGang > -1) {
		ArrayGetArray(g_aGangs, iGang, aData);
		TrieSetCell(aData[GangMembers], szName, iStatus);
		aData[NumMembers]++;
		ArraySetArray(g_aGangs, iGang, aData);
		
		sqlv_set_num_ex(g_hVault, szName, aData[GangName], iStatus);		
	}
	g_iGang[id] = iGang;
	return 1;
}
	
get_user_gang(id) {
	new szName[35];
	get_user_name(id, szName, charsmax(szName));
	new aData[GangInfo];
	for(new i = 0; i < ArraySize(g_aGangs); i++) {
		ArrayGetArray(g_aGangs, i, aData);
		if(TrieKeyExists(aData[GangMembers], szName)) return i;
	}
	return -1;
}
			
getStatus(id, iGang) {
	if(!is_user_connected(id) || iGang == -1) return STATUS_NONE;
		
	new aData[GangInfo];
	ArrayGetArray(g_aGangs, iGang, aData);
	
	new szName[35];
	get_user_name(id, szName, charsmax(szName));
	
	new iStatus;
	TrieGetCell(aData[GangMembers], szName, iStatus);
	
	return iStatus;
}

stock TeamName:rg_get_user_team(const player, &{ModelName,_}:model = MODEL_UNASSIGNED) {
	model = get_member(player, m_iModelName);
	return TeamName:get_member(player, m_iTeam);
}