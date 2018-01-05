#include <amxmodx>
#include <old_menu>
#include <jbe_core>
#include <reapi>

new g_iMenuPlayers[33][32], g_iMenuPosition[33], g_iTarget[33], g_iNumDice[33], g_iBitUserDiceStatus;

#define RegisterMenu(%1,%2,%3) register_menucmd(register_menuid(%1), %3, %2)

#define SetBit(%0,%1) 				((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) 			((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) 			((%0) & (1 << (%1)))
#define InvertBit(%0,%1) 			((%0) ^= (1 << (%1)))

public plugin_init() {
	register_plugin("[UJBL] Casino", "0.0.1", "ToJI9IHGaa");
	new iBits = (1<<0|1<<1|1<<9);
	
	RegisterMenu("Show_AcceptMenu", "Handle_AcceptMenu", iBits);
	RegisterMenu("Show_CasinoMenu", "Handle_CasinoMenu", (iBits |= (1<<2)));
	RegisterMenu("Show_PlayerListMenu", "Handle_PlayerListMenu", (iBits |= (1<<3|1<<4|1<<5|1<<6|1<<7|1<<8)));
	
	register_clcmd("ujbl_set_casino_num", "SetCasinoNum");
	
	register_clcmd("say /dice", "Show_CasinoMenu");
	register_clcmd("say /accept", "AcceptF");
	register_clcmd("say /cancel", "CancelF");	
}

public AcceptF(id) return Handle_AcceptMenu(id, 0);
public CancelF(id) return Handle_AcceptMenu(id, 1);

public client_disconnected(id) {
	ClearBit(g_iBitUserDiceStatus, id);
	g_iNumDice[id] = 10;
}

public Show_CasinoMenu(id) {
	jbe_informer_offset_up(id);
	CreateMenu("^t^t\yКазино^n\yВаши деньги: \r%d$^n\yСтавка: \r%d$^n^n", jbe_get_user_money(id), g_iNumDice[id]);
	FormatMenu("\r(1)\y | \wСменить ставку^n");
	FormatMenu("\r(2)\y | \wСписок игроков^n");
	FormatMenu("\r(3)\y | \wПредложение кидать ставки [Вам]: \r%s^n", IsSetBit(g_iBitUserDiceStatus, id) ? "Нельзя" : "Можно");
	FormatMenu("^n\r(0)\y | \wВыход");
	iKeys |= (1<<0|1<<1|1<<2);
	return ShowMenu("Show_CasinoMenu");
}

public Handle_CasinoMenu(id, iKey) {
	switch(iKey) {
		case 0: client_cmd(id, "messagemode ujbl_set_casino_num");
		case 1: {
			if(jbe_get_user_money(id) >= g_iNumDice[id]) return Show_PlayerListMenu(id, g_iMenuPosition[id] = 0);
			else client_print(id, print_center, "Ставка выше ваших средств!");
		}
		case 2: InvertBit(g_iBitUserDiceStatus, id);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_CasinoMenu(id);
}

public SetCasinoNum(id) {
	new szArgs[6], iArgsLen;
	read_args(szArgs, charsmax(szArgs));
	remove_quotes(szArgs);
	
	iArgsLen = strlen(szArgs);
	
	if(!iArgsLen) {
		client_print_color(id, print_team_blue, "^1[^4INFO^1] Пустое значение ^3невозможно.");
		return;
	}
	
	for(new iPos; iPos < strlen(szArgs); iPos++) {
		if(!isdigit(szArgs[iPos])) {
			client_print_color(id, print_team_blue, "^1[^4INFO^1] Сумма должна быть только ^3числом.");
			return;
		}
	}
	
	new iNum = str_to_num(szArgs);
	
	if(iNum > 90000) {
		client_print_color(id, print_team_blue, "^1[^4INFO^1] Слишком большое ^3число.");
		return;
	}
	
	if(jbe_get_user_money(id) < iNum) {
		client_print_color(id, print_team_blue, "^1[^4INFO^1] У вас недостаточно ^3средств.");
		return;
	}

	g_iNumDice[id] = iNum;
}

Show_PlayerListMenu(id, iPos) {
	if(iPos < 0) return Show_CasinoMenu(id);
	jbe_informer_offset_up(id);
	
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++) {
		if(id == i || IsSetBit(g_iBitUserDiceStatus, i) || !is_user_connected(i) || jbe_get_user_money(id) < jbe_get_user_money(i)) continue;
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
		case 0: return Show_CasinoMenu(id);
		default: iLen = formatex(szMenu, charsmax(szMenu), "\yВыбери игрока: \w[%d|%d]^n^n", iPos + 1, iPagesNum);
	}
	
	new szName[32], i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++) {
		i = g_iMenuPlayers[id][a];
		get_user_name(i, szName, charsmax(szName));
		iKeys |= (1<<b);
		
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(%d)\y | \w%s \d[\r%d\d]^n", ++b, szName, jbe_get_user_money(i));
	}
	
	for(new i = b; i < 8; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	if(iEnd < iPlayersNum) {
		iKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9)\y | \w%L^n\r(0)\y | \w%L", id, "JBE_MENU_NEXT", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r(0)\y | \w%L", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_PlayerListMenu");
}

public Handle_PlayerListMenu(id, iKey) {
	switch(iKey) {
		case 8: return Show_PlayerListMenu(id, ++g_iMenuPosition[id]);
		case 9: return Show_PlayerListMenu(id, --g_iMenuPosition[id]);
		default: {
			new iTarget = g_iMenuPlayers[id][g_iMenuPosition[id] * 8 + iKey];
			if(is_user_connected(iTarget)) {
				new szName[2][32];
				
				get_user_name(iTarget, szName[1], charsmax(szName[]));
				get_user_name(id, szName[0], charsmax(szName[]));			
				
				g_iTarget[ iTarget ] = id;
				Show_AcceptMenu(iTarget);
				
				client_print_color(id, print_team_blue, "^1[^4INFO^1] Вы предложили ^4%s^1 кинуть кости на ^4%d$", szName[1], g_iNumDice[id]);
				client_print_color(iTarget, print_team_blue, "^1[^4INFO^1]^3 %s^1 предложил кинуть кости на ^4%d$. ^4/accept^1 или ^4/cancel^1", szName[0], g_iNumDice[id]);
			}
		}
	}
	return PLUGIN_HANDLED;
}

public Show_AcceptMenu(id) {
	jbe_informer_offset_up(id);
	new szMenu[512], iLen, szName[32];
	get_user_name(g_iTarget[id], szName, charsmax(szName));
	
	iLen = formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\yИгрок \r%s\y предложил кинуть кости на \r%d$^n\wВаши деньги: \r%d$^n^n", szName, g_iNumDice[g_iTarget[id]], jbe_get_user_money(id));
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1)\y | \w Сыграть^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2)\y | \w Отказать^n^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(0)\y | \w Выход");
	show_menu(id, (1<<0|1<<1|1<<9), szMenu, 15, "Show_AcceptMenu");	
}

public Handle_AcceptMenu(id, iKey) {
	if(iKey == 0) {
		#define iMoney[%1] jbe_get_user_money(%1)
		#define iTarget g_iTarget[id]
		
		new iWinDollar = g_iNumDice[iTarget];
		
		if(iMoney[id] < iWinDollar || iMoney[iTarget] < iWinDollar) {
			g_iTarget[iTarget] = 0;
			client_print_color(id, print_team_blue, "^1[^4INFO^1] У кого-то из ^4Вас^1 - недостаточно ^4денег!");
			client_print_color(iTarget, print_team_blue, "^1[^4INFO^1] У кого-то из ^4Вас^1 - недостаточно ^4денег!");
			return PLUGIN_HANDLED
		}
		#define ID 0
		#define TARGET 1
		
		new iScore[2], bool:iWinScore;
		
		iScore[ID] = random_num(1, 5);
		iScore[TARGET] = random_num(1, 5);
		
		new iWinerId, iLoserId;
		
		if(iScore[0] == iScore[1]) {
			client_print_color(id, print_team_blue, "^1[^4INFO^1] (^4%d ^1| ^3%d^1) У Вас: ^4Ничья.", iScore[ID], iScore[TARGET]);
			client_print_color(iTarget, print_team_blue, "^1[^4INFO^1] (^4%d ^1| ^3%d^1) У Вас: ^4Ничья.", iScore[TARGET], iScore[ID]);
		}
		
		if(iScore[ID] > iScore[TARGET]) {
			iWinScore = false;
			iWinerId = id;
			iLoserId = iTarget;
		}
		else {
			iWinScore = true;
			iWinerId = iTarget;
			iLoserId = id;
		}
		
		client_print_color(iWinerId, print_team_blue, "^1[^4INFO^1] (^3%d ^1| ^3%d^1) Гратс! ^4Победа^1. Выигрыш: ^4+%d$", iScore[iWinScore], iScore[!iWinScore], iWinDollar);
		client_print_color(iLoserId, print_team_blue, "^1[^4INFO^1] (^3%d ^1| ^3%d^1) Гратс! ^4Поражение^1. Проигрыш: ^4-%d$", iScore[!iWinScore], iScore[iWinScore], iWinDollar);
		
		jbe_set_user_money(iWinerId, jbe_get_user_money(iWinerId) + iWinDollar, true);
		jbe_set_user_money(iLoserId, jbe_get_user_money(iLoserId) - iWinDollar, true);
	}
	else if(iKey == 1) g_iTarget[id] = 0;
	
	return PLUGIN_HANDLED;
}