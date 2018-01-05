#include <amxmodx>
#include <jbe_core>
#include <old_menu>
#include <reapi>

#define RegisterMenu(%1,%2,%3) 		register_menucmd(register_menuid(%1),%3,%2)

#define TaskId_Regen 12125

/* -> Бит суммы для игроков -> */
#define SetBit(%0,%1) 				((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) 			((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) 			((%0) & (1 << (%1)))
#define InvertBit(%0,%1) 			((%0) ^= (1 << (%1)))
#define IsNotSetBit(%0,%1) 			(~(%0) & (1 << (%1)))

/* -> Массивы для меню из игроков -> */
new g_iMenuPlayers[MAX_PLAYERS + 1][32], g_iMenuPosition[MAX_PLAYERS + 1];

enum _: eBLOCK { REGEN, MODE };

new g_iBitUserIsType[eBLOCK], g_iUserRespawnNum[MAX_PLAYERS], g_iGodModeType[MAX_PLAYERS + 1], g_iDayMode, g_iSyncText;

public plugin_natives() {
	register_native("Open_KnyazMenu", "Show_KnyazMenu", 1);
	register_native("Open_CreateMenu", "Show_CreatorMenu", 1);
	register_native("Open_GodModeMenu", "Show_GodModeMenu", 1);
	register_native("Open_Respawn_Menu", "Cmd_OpenResspawnMenu", 1);
}

public plugin_init() {
	register_plugin("[UJBL] Privileges Addon", "0.0.1", "ToJI9IHGaa");
	
	register_dictionary("jbe_core.txt");
	
	new iBits = (1<<0|1<<1|1<<2|1<<9);
	
	RegisterMenu("Show_KnyazMenu", "Handle_KnyazMenu", iBits);
	iBits |= (1<<3|1<<4);
	
	RegisterMenu("Show_CreatorMenu", "Handle_CreatorMenu", iBits);
	RegisterMenu("Show_GodModeMenu", "Handle_GodModeMenu", iBits);
	iBits |= (1<<5|1<<6|1<<7|1<<8);
	
	RegisterMenu("Show_RespawnMenu", "Handle_RespawnMenu", iBits);
	RegisterMenu("Show_GodModeList", "Handle_GodModeList", iBits);
		
	register_logevent("LogEvent_RoundStart", 2, "1=Round_Start");

	g_iSyncText = CreateHudSyncObj();
}

public LogEvent_RoundStart() {
	for(new id = 1; id <= MaxClients; id++) {
		if(~jbe_get_privileges_flags(id) & FLAGS_KNYAZ) continue;
		
		if(task_exists(id + TaskId_Regen)) remove_task(id + TaskId_Regen);
		static iMode, iInvisible;
		rg_get_user_rendering(id, iMode, iMode, iMode, iMode, iMode, iInvisible);
		if(iMode == kRenderTransAlpha && iInvisible == 70) rg_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 100);		
		g_iBitUserIsType[REGEN] = 0;
		g_iUserRespawnNum[id] = 3;
	}
}

public Show_KnyazMenu(id) {
	jbe_informer_offset_up(id);
	static iMode, iInvisible;
	rg_get_user_rendering(id, iMode, iMode, iMode, iMode, iMode, iInvisible);
	new szMenu[340], iLen, iKeys = (1<<0|1<<1|1<<9);
	iLen = formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y%L^n^n", id, "JBE_KNYAZ_TITLE");
	FormatMenu("\r(1) \y|  \w%L^n", id, "JBE_KNYAZ_REGENERATION", IsSetBit(g_iBitUserIsType[REGEN], id) ? "Включено" : "Выключено");
	FormatMenu("\r(2) \y|  \w%L^n", id, "JBE_KNYAZ_INVISIBLE", (iMode == kRenderTransAlpha && iInvisible == 70) ? "Включено" : "Выключено");
	
	if(g_iUserRespawnNum[id] > 0) {
		FormatMenu("\r(3) \y| \w %L \r[%d]^n", id, "JBE_RESPAWN_MENU", g_iUserRespawnNum[id]);
		iKeys |= (1<<2);
	}
	else FormatMenu("\r(3) \y| \d %L \r(0) \y| ^n", id, "JBE_RESPAWN_MENU");
	FormatMenu("^n\r(0) \y| \w Выход");
	return ShowMenu("Show_KnyazMenu");
}

public Handle_KnyazMenu(id, iKey) {
	switch(iKey) {
		case 0: {
			if(IsSetBit(g_iBitUserIsType[REGEN], id)) remove_task(id + TaskId_Regen);
			else set_task(10.0, "Regenerations", id + TaskId_Regen, _, _, "b");
			
			InvertBit(g_iBitUserIsType[REGEN], id);
		}
		case 1: {
			static iMode, iInvisible;
			rg_get_user_rendering(id, iMode, iMode, iMode, iMode, iMode, iInvisible);
			if(iMode == kRenderTransAlpha && iInvisible == 70) rg_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 100);
			else rg_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 70);
		}
		case 2: return Show_RespawnMenu(id, g_iMenuPosition[id] = 0);	
	}
	return Show_KnyazMenu(id);
}

public Regenerations(id) {
	id -= TaskId_Regen;
	if(jbe_get_status_duel() || jbe_get_day_mode() == 3 || !is_user_alive(id))  {
		remove_task(id + TaskId_Regen);
		return;
	}
	if(Float:rg_get_user_health(id) >= 100.0) {
		client_print(id, print_center, "Регенерация завершена!");
		remove_task(id + TaskId_Regen);
		return;
	}
	rg_set_user_health(id, Float:rg_get_user_health(id) + 5.0);
}

public Show_CreatorMenu(id) {
	jbe_informer_offset_up(id);	
	new szMenu[516], iLen, iKeys = (1<<0|1<<1|1<<2|1<<3|1<<9);

	iLen = formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y%L^n^n", id, "JBE_CREATOR_TITLE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[1] \w%L^n^n", id, "JBE_CREATER_TYPE", IsNotSetBit(g_iBitUserIsType[MODE], id) ? "Забрать" : "Дать");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[2] \w%L^n", id, "JBE_CREATE_HEALTH", rg_get_user_health(id));
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[3] \w%L^n^n", id, "JBE_CREATE_ARMOR", rg_get_user_armor(id));
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[4] \w%L^n^n", id, "JBE_CREATE_GRAVITY", Float:rg_get_user_gravity(id));
	if(!is_user_alive(id)) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[5] \w%L^n^n",id, "JBE_RESPAWN_CREATE");
		iKeys |= (1<<4);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[5] \d%L^n^n",id, "JBE_RESPAWN_CREATE");
	FormatMenu("^n\r(0) \y| \w Выход");
	return ShowMenu("Show_CreatorMenu");
}

public Handle_CreatorMenu(id, iKey) {
	switch(iKey) {
		case 0: InvertBit(g_iBitUserIsType[MODE], id);
		case 1: {
			if(IsSetBit(g_iBitUserIsType[MODE], id)) {
				if(Float:rg_get_user_health(id) >= 160.0) client_print(id, print_center, "У Вас много жизней!");
				else rg_set_user_health(id, Float:rg_get_user_health(id) + 5.0);
			}
			else {
				if(Float:rg_get_user_health(id) < 6.0) client_print(id, print_center, "У Вас мало жизней!");
				else rg_set_user_health(id, Float:rg_get_user_health(id) - 5.0);
			}
		}
		case 2: {
			if(IsSetBit(g_iBitUserIsType[MODE], id)) {
				if(rg_get_user_armor(id) >= 160) client_print(id, print_center, "У Вас много брони!");
				else rg_set_user_armor(id, rg_get_user_armor(id) + 5, ARMOR_KEVLAR);
			}
			else {
				if(rg_get_user_armor(id) < 6) client_print(id, print_center, "У Вас мало брони!");
				else rg_set_user_armor(id, rg_get_user_armor(id) - 5, ARMOR_KEVLAR);
			}
		}
		case 3: {
			if(IsSetBit(g_iBitUserIsType[MODE], id)) {
				if(Float:rg_get_user_gravity(id) <= 0.5) client_print(id, print_center, "Слишком большая гравитация!");
				else rg_set_user_gravity(id, Float:rg_get_user_gravity(id) - 0.05);
			}
			else {
				if(Float:rg_get_user_gravity(id) >= 1.0) client_print(id, print_center, "Слишком маленькая гравитация!");
				else rg_set_user_gravity(id, Float:rg_get_user_gravity(id) + 0.05);
			}
		}
		case 4: rg_round_respawn(id);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_CreatorMenu(id);
}

public Show_GodModeMenu(id) {
	jbe_informer_offset_up(id);
	
	new szMenu[700], iLen;
	iLen = formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y%L^n^n", id, "JBE_GODMODE_TITLE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[1] \w%L^n^n", id, "JBE_GODMODE_TYPE", IsNotSetBit(g_iBitUserIsType[MODE], id) ? "Забрать" : "Дать");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[2] \w%L^n", id, "JBE_GODMODE_HEALTH");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[3] \w%L^n^n", id, "JBE_GODMODE_ARMOR");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[4] \w%L^n^n", id, "JBE_GODMODE_GRAVITY");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[5] \w%s\r%L^n^n", g_iDayMode ? "Ночь | ":"День | ", id, "JBE_GODMODE_DEYMODE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\y[0] \w%L", id, "JBE_MENU_EXIT");

	return show_menu(id, (1<<0|1<<1|1<<2|1<<3|1<<4|1<<9), szMenu, -1, "Show_GodModeMenu");	
}

public Handle_GodModeMenu(id, iNum) {
	switch(iNum) {
		case 0: {
			InvertBit(g_iBitUserIsType[MODE], id);
			return Show_GodModeMenu(id);
		}
		case 1: {
			g_iGodModeType[id] = 1;
			return Show_GodModeList(id, g_iMenuPosition[id] = 0);
		}
		case 2: {
			g_iGodModeType[id] = 2;
			return Show_GodModeList(id, g_iMenuPosition[id] = 0);
		}
		case 3: {
			g_iGodModeType[id] = 3;
			return Show_GodModeList(id, g_iMenuPosition[id] = 0);
		}
		case 4: {
			DayMode_Setting();
			return Show_GodModeMenu(id);
		}
		case 5: return Show_RespawnMenu(id, g_iMenuPosition[id] = 0);
	}
	return PLUGIN_HANDLED;
}

public Cmd_OpenResspawnMenu(id) Show_RespawnMenu(id, g_iMenuPosition[id] = 0);

public Show_RespawnMenu(id, iPos) {
	if(iPos < 0) return PLUGIN_HANDLED;
	if(~jbe_get_privileges_flags(id) & FLAGS_GOD && !g_iUserRespawnNum[id]) {
		client_print(0, print_center, "У Вас закончились попытки возрождения!");
		return Show_KnyazMenu(id);
	}	

	jbe_informer_offset_up(id);
	new iPlayersNum;
	
	for(new i = 1; i <= MaxClients; i++) {
		if(jbe_get_user_team(i) == (0|3) || is_user_alive(i)) continue;
		g_iMenuPlayers[id][iPlayersNum++] = i;	
	}
	new iStart = iPos * 8;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % 8);
	g_iMenuPosition[id] = iStart / 8;
	new iEnd = iStart + 8;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[1024], iLen, iPagesNum = (iPlayersNum / 8 + ((iPlayersNum % 8) ? 1 : 0));
	switch(iPagesNum) {
		case 0: {
			client_print(id, print_center, "%L", id, "JBE_CHAT_ID_PLAYERS_NOT_VALID");			
			return PLUGIN_HANDLED;
		}
		default: iLen = formatex(szMenu, charsmax(szMenu), "\y%L \w[%d|%d]^n^n", id, "JBE_RESPAWN_MENU", iPos + 1, iPagesNum);
	}
	new szName[32], i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++) {
		i = g_iMenuPlayers[id][a];
		get_user_name(i, szName, charsmax(szName));
		iKeys |= (1<<b);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d] \w%s^n", ++b, szName);
	}
	for(new i = b; i < 8; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	if(iEnd < iPlayersNum) {
		iKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\y[9] \w%L^n\y[0] \w%L", id, "JBE_MENU_NEXT", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\y[0] \w%L", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_RespawnMenu");
}

public Handle_RespawnMenu(id, iKey) {
	switch(iKey)
	{
		case 8: return Show_RespawnMenu(id, ++g_iMenuPosition[id]);
		case 9: return Show_RespawnMenu(id, --g_iMenuPosition[id]);
		default: {
			new iTarget = g_iMenuPlayers[id][g_iMenuPosition[id] * 8 + iKey];
			if(is_user_alive(iTarget))  {
				client_print(id, print_center, "Игрок уже оживлён!");
				return Show_RespawnMenu(id, g_iMenuPosition[id] = 0);
			}
			
			if(is_user_connected(iTarget)) {			
				g_iUserRespawnNum[id]--;
				rg_round_respawn(iTarget);
				new szName[2][32];
				get_user_name(id, szName[0], charsmax(szName[]));
				get_user_name(iTarget, szName[1], charsmax(szName[]));
				
				for(new pPlayer = 1; pPlayer <= MaxClients; pPlayer++) {
					if(!is_user_connected(pPlayer)) continue;
					set_hudmessage(102, 69, 0, -1.0, 0.16, 0, 0.0, 0.9, 0.1, 3.0, -1);
					ShowSyncHudMsg(pPlayer, g_iSyncText, "Администратор [ %s ] ^nвозродил игрока [ %s ]", szName[0], szName[1]);
				}			
			}
			return Show_RespawnMenu(id, g_iMenuPosition[id]);
		}
	}
	return PLUGIN_HANDLED;
}

Show_GodModeList(id, iPos) {
	if(iPos < 0) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++) {
		if(!is_user_alive(i) || jbe_get_user_team(i) == (0|3)) continue;
		g_iMenuPlayers[id][iPlayersNum++] = i;
	}
	new iStart = iPos * 8;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % 8);
	g_iMenuPosition[id] = iStart / 8;
	new iEnd = iStart + 8;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[1024], iLen, iPagesNum = (iPlayersNum / 8 + ((iPlayersNum % 8) ? 1 : 0));
	switch(iPagesNum) {
		case 0: {
			client_print_color(id, print_team_blue, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			Show_GodModeMenu(id);
		}
		default: iLen = formatex(szMenu, charsmax(szMenu), "\y%L \w[%d|%d]^n^n", id, "JBE_GODMODE_BONUS_MENU", iPos + 1, iPagesNum);
	}
	new szName[32], i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++) {
		i = g_iMenuPlayers[id][a];
		get_user_name(i, szName, charsmax(szName));
		iKeys |= (1<<b);
		switch(g_iGodModeType[id]) {
			case 1: iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d] \w%s \d[\r%d\d]^n", ++b, szName, rg_get_user_health(i));
			case 2: iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d] \w%s\d[\r%d\d]^n", ++b, szName, rg_get_user_armor(i));
			case 3: iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d] \w%s\d[\r%f\d]^n", ++b, szName, Float:rg_get_user_gravity(i));
		}
	}
	for(new i = b; i < 8; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	if(iEnd < iPlayersNum) {
		iKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\y[9] \w%L^n\y[0] \w%L", id, "JBE_MENU_NEXT", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\y[0] \w%L", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_GodModeList");
}

public Handle_GodModeList(id, iKey) {
	switch(iKey) {
		case 8: return Show_GodModeList(id, ++g_iMenuPosition[id]);
		case 9: return Show_GodModeList(id, --g_iMenuPosition[id]);
		default: {
			new iTarget = g_iMenuPlayers[id][g_iMenuPosition[id] * 8 + iKey];
			
			if(!is_user_connected(iTarget)) {
				client_print(id, print_center, "Игрок отключён!");
				return Show_GodModeList(id, g_iMenuPosition[id] = 0);
			}
			
			if(!is_user_alive(iTarget))  {
				client_print(id, print_center, "Игрок мёртв!");
				return Show_GodModeList(id, g_iMenuPosition[id] = 0);
			}

			switch(g_iGodModeType[id]) {
				case 1: {
					if(IsSetBit(g_iBitUserIsType[MODE], id)) {
						if(Float:rg_get_user_health(iTarget) >= 160.0) client_print(id, print_center, "У игрока много жизней!");
						else rg_set_user_health(iTarget, Float:rg_get_user_health(iTarget) + 5.0);
					}
					else {
						if(Float:rg_get_user_health(iTarget) < 6.0) client_print(id, print_center, "У игрока мало жизней!");
						else rg_set_user_health(iTarget, Float:rg_get_user_health(iTarget) - 5.0);
					}
					return Show_GodModeList(id, g_iMenuPosition[id]);
				}
				case 2: {
					if(IsSetBit(g_iBitUserIsType[MODE], id)) {
						if(rg_get_user_armor(iTarget) >= 160) client_print(id, print_center, "У игрока много жизней!");
						else rg_set_user_armor(iTarget, rg_get_user_armor(iTarget) + 5, ARMOR_KEVLAR);
					}
					else {
						if(rg_get_user_armor(iTarget) < 6) client_print(id, print_center, "У игрока мало жизней!");
						else rg_set_user_armor(iTarget, rg_get_user_armor(iTarget) - 5, ARMOR_KEVLAR);
					}
					return Show_GodModeList(id, g_iMenuPosition[id]);
				}
				case 3: {					
					if(IsSetBit(g_iBitUserIsType[MODE], id)) {
						if(Float:rg_get_user_gravity(iTarget) <= 0.5) client_print(id, print_center, "Слишком большая гравитация!");
						else rg_set_user_gravity(iTarget, Float:rg_get_user_gravity(iTarget) - 0.05);
					}
					else {
						if(Float:rg_get_user_gravity(iTarget) >= 1.0) client_print(id, print_center, "Слишком маленькая гравитация!");
						else rg_set_user_gravity(iTarget, Float:rg_get_user_gravity(iTarget) + 0.05);
					}
				}
			}
			return Show_GodModeList(id, g_iMenuPosition[id]);
		}
	}
	return PLUGIN_HANDLED;
}

stock Float:rg_get_user_health(const player) return Float:get_entvar(player, var_health);
stock rg_set_user_health(const player, Float:health) set_entvar(player, var_health, Float:health);

stock Float:rg_get_user_gravity(const player) return Float:get_entvar(player, var_gravity);
stock rg_set_user_gravity(const player, Float:gravity = 1.0) set_entvar(player, var_gravity, Float:gravity);

stock rg_get_user_rendering(index, &fx, &r, &g, &b, &render, &renderamt) {
	new Float:RenderColor[3];
	RenderColor[0] = float(r);
	RenderColor[1] = float(g);
	RenderColor[2] = float(b);

	fx = get_entvar(index, var_renderfx);
	get_entvar(index, var_rendercolor, RenderColor);
	render = get_entvar(index, var_rendermode);
	renderamt = get_entvar(index, var_renderamt);
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

stock DayMode_Setting() {
	switch(g_iDayMode) {
		case false: {
			message_begin(MSG_ALL, get_user_msgid("Fog"), {0,0,0}, 0);
			write_byte(20); 	 	// Red
			write_byte(20); 		// Green
			write_byte(20); 		// Blue
			write_byte(10); 						// SD
			write_byte(41);  						// ED
			write_byte(95);  						// D1
			write_byte(59);  						// D2
			message_end();	
			g_iDayMode = true;
		}
		case true: {
			message_begin(MSG_ALL, get_user_msgid("Fog"), {0,0,0}, 0);
			write_byte(0);  // Red
			write_byte(0);  // Green
			write_byte(0);  // Blue
			write_byte(0); 	// SD
			write_byte(0);  // ED
			write_byte(0);  // D1
			write_byte(0);  // D2
			message_end();
			g_iDayMode = false;
		}
	}
}
