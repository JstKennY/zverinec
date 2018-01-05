#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <old_menu>
#include <jbe_core>

#define BREAKING 					0
#define OVERDOSE 					1

#define SetBit(%0,%1) 				((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) 			((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) 			((%0) & (1 << (%1)))
#define IsNotSetBit(%0,%1) 			(~(%0) & (1 << (%1)))

new g_iBitUserBreaking, g_iBitUserUseDrugs, g_iBitUserDamageDodge, g_iBitUserSpeed, g_iBitUserGravity, g_iBitUserMultiDamage, g_iBitUserRequestFreedom,
g_iBitUserRequestTrue;

#define RANDOM_LIMIT 		60 // Диапазон макс. количества груза которое может появится у барыги.

new const g_CostMaterial[4] = { 4, 5, 6, 7 };		// Цены в магазине на материалы
new g_TraderResources[4] = { 1, 1, 1, 1 };			// Еденицы материалов у барыги

new g_szRequestInfo[33][80];	// Ксива.
new g_iRequestType[33];			// Что привозим?
new g_iRequestNum[33];			// Количество.

#define SYRINEG 			0
#define SIGARETTE 			1
#define TABLET 				2

new const g_szDrugs[2][4][] = {
	{ "Бумага", "Лезвие", "Синтезаторы", "Марихуана" },
	{ "Гашиш", "Амфетамин", "ЛСД", "ДОБ" }
};

new const g_iCraftDrugs[4][4] = {
	//Бумага / Лезвие / Синтезаторы / Каннабис
	{ 3, 1, 0, 3 },	// Гашиш
	{ 1, 3, 3, 3 },	// Амфетамин
	{ 5, 1, 5, 0 },	// ЛСД
	{ 6, 0, 6, 6 }	// ДОБ
}

#define PAPER(%1) 				g_iDrugs[%1][4]
#define RAZOR(%1) 				g_iDrugs[%1][4+1]
#define SYNTHS(%1) 				g_iDrugs[%1][4+2]
#define HEMP(%1) 				g_iDrugs[%1][4+3]
#define CRAFT(%0) 				g_iCraftDrugs[iPos][%0]
	
enum _: GET_DRUGS_AND_MATERIAL {
	CANNABIS = 0,
	METH,
	LSD,
	EXT,
	
	PAPER,
	RAZOR,
	SYNTHS,
	HEMP
};

new g_iDrugs[33][GET_DRUGS_AND_MATERIAL];
new g_iWarns[33][2];

enum (+= 912) {
	TASK_DRUGS_USE = 1241,
	TASK_UPDATE_RESOURCES,
	TASK_UN_USE_DRUGS,
	TASK_SCREEN_FADE,
	TASK_SCREEN_SHAKE,
	TASK_PUN_CHANGLE,
	TASK_BREAKING,
	TASK_OVERDOSE,
	TASK_SLAP_BREAKING, 
	TASK_GET_REQUEST
};

new const g_MaxTask[9] = {
	TASK_DRUGS_USE,
	TASK_UPDATE_RESOURCES,
	TASK_UN_USE_DRUGS,
	TASK_SCREEN_FADE,
	TASK_SCREEN_SHAKE,
	TASK_PUN_CHANGLE,
	TASK_BREAKING,
	TASK_OVERDOSE,
	TASK_SLAP_BREAKING
};

public plugin_natives() {
	register_native("Open_DrugsMenu", "Show_DrugsMenu", 1);
	register_native("Open_TraderDrugsMenu", "Show_TraderDrugsMenu", 1);
}

public plugin_precache() engfunc(EngFunc_PrecacheModel, "models/egoist/jb/shop/v_syringe.mdl");

public plugin_init() {
	register_plugin("[UJBL] Drugs System", "0.1.0", "ToJI9IHGaa & Minni Mouse");
	
	set_task(120.0, "UpdateTraderResources", TASK_UPDATE_RESOURCES, _, _, "b");
	
	register_clcmd("say /drugsnull", "drugsnull");
	register_clcmd("DrugsTrader_Num", "GetRequestNumSet");
	
	RegisterHookChain(RG_CBasePlayer_Killed, "Player_Killed_Post", true);
	RegisterHookChain(RG_CBasePlayer_Spawn, "Player_Spawn_Post", true);
	RegisterHookChain(RG_CBasePlayer_TraceAttack, "Player_TraceAttack_Pre", false);
	RegisterHam(Ham_Item_PreFrame, "player", "Ham_PlayerItemPreFrame_Post", true);
	
	_register_menu("Show_TraderDrugsMenu", (1<<0|1<<1|1<<2|1<<9), "Handle_TraderDrugsMenu");
	_register_menu("Show_TraderBuyDrugsMenu", (1<<0|1<<1|1<<2|1<<3|1<<9), "Handle_TraderBuyDrugsMenu");
	_register_menu("Show_TraderSellDrugsMenu", (1<<0|1<<1|1<<2|1<<3|1<<9), "Handle_TraderSellDrugsMenu");
	
	_register_menu("Show_DrugsMenu", (1<<0|1<<1|1<<2|1<<3|1<<4|1<<9), "Handle_DrugsMenu");
	_register_menu("Show_Gear", (1<<0|1<<1|1<<2|1<<3|1<<9), "Handle_GearMenu");
	_register_menu("Show_CraftDrugs", (1<<0|1<<1|1<<2|1<<3|1<<9), "Handle_CraftDrugsMenu");
	_register_menu("Show_TraderRequestFreedom", (1<<0|1<<1|1<<2|1<<9), "Handle_TraderRequestFreedom");
	_register_menu("Show_TraderRequestSetting", (1<<0|1<<1|1<<9), "Handle_TraderRequestSetting");
}

public drugsnull(id) {
	if(~get_user_flags(id) & ADMIN_RCON) return;
	for(new iPos; iPos < 8; iPos++) g_iDrugs[id][iPos] += 20;
}

public client_disconnected(id) {
	for(new iPos; iPos < 9; iPos++) {
		if(task_exists(id + g_MaxTask[iPos])) remove_task(id + g_MaxTask[iPos]);
	}
	g_iWarns[id][OVERDOSE] = 0;
	g_iWarns[id][BREAKING] = 0;
	
	for(new iPos; iPos < GET_DRUGS_AND_MATERIAL; iPos++) g_iDrugs[id][iPos] = 0;
	
	ClearBit(g_iBitUserBreaking, id);
	ClearBit(g_iBitUserDamageDodge, id);
	ClearBit(g_iBitUserGravity, id);
	ClearBit(g_iBitUserMultiDamage, id);
	ClearBit(g_iBitUserSpeed, id);
	ClearBit(g_iBitUserUseDrugs, id);
	ClearBit(g_iBitUserRequestFreedom, id);
	ClearBit(g_iBitUserRequestTrue, id);
	
	g_iRequestNum[id] = 10;
	
	if(task_exists(id + TASK_GET_REQUEST)) remove_task(id + TASK_GET_REQUEST);
}

public Ham_PlayerItemPreFrame_Post(id) {
	if(IsSetBit(g_iBitUserSpeed, id)) set_entvar(id, var_maxspeed, float(get_entvar(id, var_maxspeed)) * 1.5);
}

public Player_TraceAttack_Pre(iVictim, iAttacker, Float:fDamage, Float:fDeriction[3], iTraceHandle, iBitDamage) {
	if(is_user_connected(iAttacker)){	
		new Float: fOldDamage = fDamage;
		if(IsSetBit(g_iBitUserMultiDamage, iAttacker)) fDamage = fDamage * 2.0;
		if(IsSetBit(g_iBitUserDamageDodge, iVictim) && random_num(1, 10) < 4) fDamage = 0.0;
		if(fOldDamage != fDamage) SetHookChainArg(3, ATYPE_FLOAT, fDamage);
	}
}

public Player_Killed_Post(iVictim, iKiller) {
	if(!is_user_alive(iVictim)) return;
	if(is_user_connected(iVictim)) {
		if(task_exists(iVictim + TASK_UN_USE_DRUGS)) remove_task(iVictim + TASK_UN_USE_DRUGS);
		if(task_exists(iVictim + TASK_OVERDOSE)) remove_task(iVictim + TASK_OVERDOSE);
		if(task_exists(iVictim + TASK_SLAP_BREAKING)) remove_task(iVictim + TASK_SLAP_BREAKING);
		UnUseDrugs(iVictim + TASK_UN_USE_DRUGS);
		g_iWarns[iVictim][OVERDOSE] = 0;
	}
}

public Player_Spawn_Post(id) {
	if(!is_user_connected(id) || IsNotSetBit(g_iBitUserBreaking, id)) return;	
	if(task_exists(id + TASK_BREAKING)) remove_task(id + TASK_BREAKING);
	set_task(120.0, "UserBreaking", id + TASK_BREAKING, _, _, "b");

}

public UpdateTraderResources() {
	new iRandom;
	for(new iPos; iPos <= 3; iPos++) {
		iRandom = random_num(1, RANDOM_LIMIT);
		g_TraderResources[iPos] += iRandom;
	}
}

public Show_TraderDrugsMenu(id) {
	jbe_informer_offset_up(id);
	CreateMenu("\w[Yuri Senpai]\y Здравствуй, милый! Хочешь купить зелья?^n^n");
	iKeys |= (1<<0|1<<1);
	FormatMenu("\rМатериалов у Yuri Senpai: [%d]^n\r[\w1\r]\w Купить материалы^n^n", g_TraderResources[0]+g_TraderResources[1]+g_TraderResources[2]+g_TraderResources[3]);
	FormatMenu("\rМатериалов у Вас: [%d]^n\r[\w2\r]\w Продать материалы^n^n", g_iDrugs[id][PAPER]+g_iDrugs[id][RAZOR]+g_iDrugs[id][SYNTHS]+g_iDrugs[id][HEMP]);
	
	if(jbe_get_user_lvl_rank(id) > 3) {
		FormatMenu("\r[\w3\r]\w Заказать крупную поставку^n");
		iKeys |= (1<<2);
	}
	else FormatMenu("\r[\w3\r]\d Заказать крупную поставку \r[Ваш lvl мал]^n");
	
	FormatMenu("^n\r[\w0\r]\w Выход");
	ShowMenu("Show_TraderDrugsMenu");
}

public Handle_TraderDrugsMenu(id, iKey) {
	switch(iKey) {
		case 0: return Show_TraderBuyDrugsMenu(id);
		case 1: return Show_TraderSellDrugsMenu(id);
		case 2: return Show_TraderRequestFreedom(id);
		default: return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}

public Show_TraderRequestFreedom(id) {
	jbe_informer_offset_up(id);
	CreateMenu("\w[Freedom Request]\y При заказе поставки, Вы сэкономите 30%%...^n");
	FormatMenu("\w[Freedom Request]\y от стоимости товара у Yuri Senpai!^n^n");
	
	new iCost = g_iRequestNum[id] * floatround(g_CostMaterial[g_iRequestType[id]] / 1.3);
	
	if(IsNotSetBit(g_iBitUserRequestFreedom, id) && IsNotSetBit(g_iBitUserRequestTrue, id)) {
		if(jbe_get_user_money(id) >= iCost) {
			if(iCost >= 200) {
				FormatMenu("\r[\w1\r]\w Заказать поставку^n^t^tЕё цена: \r%d$ \w| Товар: \r%s \w| Кол-во: \r%d^n^n", iCost, g_szDrugs[0][g_iRequestType[id]], g_iRequestNum[id]); 
				iKeys |= (1<<0);
			}
			else FormatMenu("\r[\w1\r]\d Заказать поставку \r[(%d) Заказ беру минимум на 200$]^n^n", iCost);
		}
		else FormatMenu("\r[\w1\r]\d Заказать поставку \r[Мало денег]^n^n");
	}
	else FormatMenu("\r[\w1\r]\d Заказать поставку \r[Заберите товар и прочитайте ксиву]^n^n");
	
	if(IsSetBit(g_iBitUserRequestFreedom, id) && IsSetBit(g_iBitUserRequestTrue, id))
	{
		FormatMenu("\r[\w2\r]\w Прочитать \rксиву \wи \rзабрать товар^n");
		iKeys |= (1<<1);
	}
	else FormatMenu("\r[\w2\r]\d Прочитать ксиву \r[Нету заказа]^n");
	
	if(IsNotSetBit(g_iBitUserRequestFreedom, id) && IsNotSetBit(g_iBitUserRequestTrue, id))
	{
		FormatMenu("\r[\w3\r]\w Выбрать \rтовар \wи \rколичество^n");
		iKeys |= (1<<2);
	}
	else FormatMenu("\r[\w3\r]\d Выбрать товар и количество\r [Вы сделали заказ]^n");
	
	FormatMenu("^n\r[\w0\r]\w Выход");
	return ShowMenu("Show_TraderRequestFreedom");
}

public Handle_TraderRequestFreedom(id, iKey) {
	switch(iKey) {
		case 0: {
			new Float: iTime = random_float(120.0, 420.0), iCost = g_iRequestNum[id] * floatround(g_CostMaterial[g_iRequestType[id]] / 1.3);
			SetBit(g_iBitUserRequestFreedom, id);
			jbe_set_user_money(id, jbe_get_user_money(id) - iCost, true);
			set_trader_money(iCost, 1);
			client_print_color(id, print_team_blue, "^1[^4INFO^1] Вы заказали ^4%s^1. Количество: ^4%d^1. Цена: ^4%d$^1. Товар будет через: ^4%d минут.", g_szRequestInfo[id], g_iRequestNum[id], iCost, floatround(iTime / 60.0));
			set_task(iTime, "GetRequest", id + TASK_GET_REQUEST);
		}
		case 1: {
			client_print_color(id, print_team_blue, "^1[^4INFO^1] %s", g_szRequestInfo[id]);
			if(g_iRequestNum[id] > 1) {
				client_print_color(id, print_team_blue, "^1[^4INFO^1] Вы получили: ^4%s ^1в количестве ^4%d", g_szDrugs[0][g_iRequestType[id]], g_iRequestNum[id]);
				g_iDrugs[id][4 + g_iRequestType[id]] += g_iRequestNum[id];
			}
			else if(g_iRequestNum[id] == -1) jbe_add_user_wanted(id);
			
			g_iRequestNum[id] = 15;
			formatex(g_szRequestInfo[id], charsmax(g_szRequestInfo[]), g_szDrugs[0][g_iRequestType[id]]);
			ClearBit(g_iBitUserRequestTrue, id);
			ClearBit(g_iBitUserRequestFreedom, id);
		}
		case 2: return Show_TraderRequestSetting(id);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_TraderRequestFreedom(id);
}

public GetRequest(id) {
	id -= TASK_GET_REQUEST;
	switch(random_num(1, 10)) {
		case 1..4: formatex(g_szRequestInfo[id], charsmax(g_szRequestInfo[]), "Были усложнения, но я выполнила уговор - забирай!");
		case 5: {
			formatex(g_szRequestInfo[id], charsmax(g_szRequestInfo[]), "Мой сладкий, не обижайся, но я малую часть потеряла. Ну не дуйся...");
			g_iRequestNum[id] = floatround(g_iRequestNum[id] / 1.1);
		}
		case 6: {
			formatex(g_szRequestInfo[id], charsmax(g_szRequestInfo[]), "Пупсик, эти сволочи содрали с меня 30% за отправку... Я не виновата!");
			g_iRequestNum[id] = floatround(g_iRequestNum[id] / 1.3);
		}
		case 7: {
			formatex(g_szRequestInfo[id], charsmax(g_szRequestInfo[]), "Была облава, милый, и мне пришлось отдать половину. Черти!");
			g_iRequestNum[id] = floatround(g_iRequestNum[id] / 1.5);
		}
		case 8: {
			formatex(g_szRequestInfo[id], charsmax(g_szRequestInfo[]), "Свои же сделали мне темную... Забрали почти всё...");
			g_iRequestNum[id] = floatround(g_iRequestNum[id] / 1.7);
		}
		case 9: {
			formatex(g_szRequestInfo[id], charsmax(g_szRequestInfo[]), "Мой пупсик, у меня ничего нету. Эти фараоны не имеют совести...");
			g_iRequestNum[id] = 0;
		}
		case 10: {
			formatex(g_szRequestInfo[id], charsmax(g_szRequestInfo[]), "^4*Охрана*^1 Ну что арестант, готовся к худшему!");
			g_iRequestNum[id] = -1;
		}
	}
	SetBit(g_iBitUserRequestTrue, id);
	client_print_color(id, print_team_blue, "^1[^4INFO^1] ^4Сырьё ^1доставлено.");
}

public Show_TraderRequestSetting(id)
{
	jbe_informer_offset_up(id);
	CreateMenu("\w[Freedom Request]\y Выбирай товар и количество!^n^n");
	iKeys |= (1<<0|1<<1);
	
	FormatMenu("\r[\w1\r]\w Количество (Нажми чтобы сменить): \r%d^n", g_iRequestNum[id]);
	FormatMenu("\r[\w2\r]\w Товар: \r%s^n", g_szDrugs[0][g_iRequestType[id]]);
	
	FormatMenu("^n\r[\w0\r]\w Выход");
	return	ShowMenu("Show_TraderRequestSetting");
}

public Handle_TraderRequestSetting(id, iKey) {
	switch(iKey) {
		case 0: client_cmd(id, "messagemode DrugsTrader_Num");
		case 1: {
			formatex(g_szRequestInfo[id], charsmax(g_szRequestInfo[]), "%s", g_szDrugs[0][g_iRequestType[id]++]);
			if(g_iRequestType[id] > 3) g_iRequestType[id] = 0;
			return Show_TraderRequestSetting(id);
		}
	}
	return PLUGIN_HANDLED;
}

public GetRequestNumSet(id) {
	if(IsSetBit(g_iBitUserRequestFreedom, id) || IsSetBit(g_iBitUserRequestTrue, id)) {
		client_print_color(id, print_team_blue, "^1[^4INFO^1] Сначала забери товар!");
		return Show_TraderRequestFreedom(id);
	}
	
	new szArgs[10];
	read_args(szArgs, charsmax(szArgs));
	remove_quotes(szArgs);
	
	for(new iPos; iPos < strlen(szArgs); iPos++) {
		if(!isdigit(szArgs[iPos])) {
			client_print_color(id, print_team_blue, "^1[^4INFO^1] Сумма должна быть только числом.");
			return Show_TraderRequestSetting(id);
		}
	}
	
	if(strlen(szArgs) == 0) {
		client_print_color(id, print_team_blue, "^1[^4INFO^1] Пустое значение невозможно.");
		return Show_TraderRequestSetting(id);
	}
	
	if(str_to_num(szArgs) > 50) {
		client_print_color(id, print_team_blue, "^1[^4INFO^1] Вы ввели слишком большое число.");
		return Show_TraderRequestSetting(id);
	}
	
	if(str_to_num(szArgs) < 5) {
		client_print_color(id, print_team_blue, "^1[^4INFO^1] Меньше 5-ти товаров нельзя заказывать!");
		return Show_TraderRequestSetting(id);
	}
	
	g_iRequestNum[id] = str_to_num(szArgs);
	return Show_TraderRequestSetting(id);
}

public Show_TraderBuyDrugsMenu(id) {
	jbe_informer_offset_up(id);
	CreateMenu("\w[Yuri Senpai]\y У меня для тебя только лучший товар, милый!^n\w[Yuri Senpai]\y У меня есть: \r%d$^n", get_trader_money());
	
	for(new iPos; iPos <= 3; iPos++) {
		if(g_iDrugs[id][iPos+4] >= 10 && jbe_get_user_lvl_rank(id) <= 3) FormatMenu("\r[\w%d\r]\d %s [У Вас больше 10 сырья и lvl < 4]^n", iPos+1, g_szDrugs[0][iPos]);
		else  {
			if(g_TraderResources[iPos] == 1) {
				if(jbe_get_user_money(id) >= (g_CostMaterial[iPos]*2)) {
					FormatMenu("\r[\w%d\r]\w [1] %s \R\r%d^n", iPos+1, g_szDrugs[0][iPos], g_CostMaterial[iPos]*2);
					iKeys |= (1<<iPos);
				}
				else FormatMenu("\r[\w%d\r]\d [1] %s \R\d%d^n", iPos+1, g_szDrugs[0][iPos], g_CostMaterial[iPos]*2);
			}
			else if(g_TraderResources[iPos] > 1) {
				if(jbe_get_user_money(id) >= g_CostMaterial[iPos]) {
					FormatMenu("\r[\w%d\r]\w [%d] %s \R\r%d^n", iPos+1, g_TraderResources[iPos], g_szDrugs[0][iPos], g_CostMaterial[iPos]);
					iKeys |= (1<<iPos);
				}
				else FormatMenu("\r[\w%d\r]\d [%d] %s \R\d%d^n", iPos+1, g_TraderResources[iPos], g_szDrugs[0][iPos], g_CostMaterial[iPos]);
			}
			else FormatMenu("\r[\w%d\r]\d [0] %s \R\d%d^n", iPos+1, g_szDrugs[0][iPos], g_CostMaterial[iPos]);
		}
	}
	FormatMenu("^n\r[\w0\r]\w Выход");
	return ShowMenu("Show_TraderBuyDrugsMenu");
}

public Handle_TraderBuyDrugsMenu(id, iKey) {
	if(iKey == 9) return PLUGIN_HANDLED;
	new iCost = g_TraderResources[iKey] == 1 ? g_CostMaterial[iKey] * 2 : g_CostMaterial[iKey];
	jbe_set_user_money(id, jbe_get_user_money(id) - iCost, true);
	set_trader_money(iCost, 1);
	g_iDrugs[id][iKey+4]++;
	g_TraderResources[iKey]--;
	client_print_color(id, print_team_blue, "^1[^4INFO^1] Вы успешно купили 1 еденицу ^4%s ^1за ^4%d$^1. У Вас: ^4%d ^1шт. ^4%s'а", g_szDrugs[0][iKey], iCost, g_iDrugs[id][iKey+4], g_szDrugs[0][iKey]);
	return Show_TraderBuyDrugsMenu(id);
}

public Show_TraderSellDrugsMenu(id) {
	jbe_informer_offset_up(id);
	CreateMenu("\w[Yuri Senpai]\y Привет, зайчик мой, показывай свое барахло!^n\w[Yuri Senpai]\y У меня есть: \r%d$^n", get_trader_money());
	for(new iPos; iPos <= 3; iPos++) {
		new iReturnMoney = floatround(g_CostMaterial[iPos] / 2.0);
		if(get_trader_money() < iReturnMoney) FormatMenu("\r[\w%d\r]\d (Trader no $) %s \R+%d^n", iPos+1, g_szDrugs[0][iPos], iReturnMoney);
		else  {
			if(g_iDrugs[id][iPos+4] > 0) {
				FormatMenu("\r[\w%d\r]\w [%d] %s \R\r+%d^n", iPos+1, g_iDrugs[id][iPos+4], g_szDrugs[0][iPos], iReturnMoney);
				iKeys |= (1<<iPos);
			}
			else FormatMenu("\r[\w%d\r]\w (No Material) %s \R\r+%d^n", iPos+1, g_szDrugs[0][iPos], iReturnMoney);
		}
	}
	FormatMenu("^n\r[\w0\r]\w Выход");
	return ShowMenu("Show_TraderSellDrugsMenu");
}

public Handle_TraderSellDrugsMenu(id, iKey) {
	if(iKey == 9) return PLUGIN_HANDLED;
	new iReturnMoney = floatround(g_CostMaterial[iKey] / 2.0);
	set_trader_money(iReturnMoney, 0);
	jbe_set_user_money(id, jbe_get_user_money(id) + iReturnMoney, true);
	g_TraderResources[iKey]++;
	g_iDrugs[id][iKey+4]--;
	client_print_color(id, print_team_blue, "^1[^4INFO^1] Вы успешно продали 1 еденицу ^4%s ^1за ^4%d$^1. У Вас: ^4%d ^1шт. ^4%s'а", g_szDrugs[0][iKey], iReturnMoney, g_iDrugs[id][iKey+4], g_szDrugs[0][iKey]);
	return Show_TraderSellDrugsMenu(id);
}

public Show_DrugsMenu(id) {
	CreateMenu("\w[Drugs]\y Панель наркотиков^n^n");
	iKeys |= (1<<0|1<<1|1<<2);
	
	FormatMenu("\r[\w1\r]\w Инвентарь^n");
	FormatMenu("\r[\w2\r]\w Крафт наркотиков^n");
	FormatMenu("\r[\w3\r]\w Узнать своё состояние^n");	
	
	FormatMenu("^n\r[\w0\r]\w Выход");
	return ShowMenu("Show_DrugsMenu");
}

public Handle_DrugsMenu(id, iKey) {
	switch(iKey) {
		case 0: return Show_Gear(id);
		case 1: return Show_CraftDrugs(id);
		case 2: {
			client_print_color(id, print_team_blue, "^1[^4INFO^1] Передоз: %s | Ломка: %s", g_iWarns[id][OVERDOSE] > 2 ? "Вам очень плохо":"Вы в нормально состоянии", g_iWarns[id][BREAKING] > 2 ? "Еще чуть-чуть и у Вас будет зависимость":"Вы не зависимы");
			return Show_DrugsMenu(id);
		}
		default: return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}

public Show_Gear(id) {
	jbe_informer_offset_up(id);
	if(IsSetBit(g_iBitUserUseDrugs, id)) {
		client_print_color(id, print_team_blue, "^1[^4INFO^1] Простите, Вы уже ^4использовали наркотики^1 в течении^4 30 секунд!");
		return Show_DrugsMenu(id);
	}

	new iDrugs = g_iDrugs[id][0]+g_iDrugs[id][1]+g_iDrugs[id][2]+g_iDrugs[id][3];
	CreateMenu("\w[Drugs]\y Инвентарь^n\w[Drugs]\y У Вас всего %d наркотиков^n^n", iDrugs);
	for(new iPos; iPos <= 3; iPos++) {
		if(g_iDrugs[id][iPos] > 0) {
			FormatMenu("\r[\w%d\r]\w [%d] %s^n", iPos+1, g_iDrugs[id][iPos], g_szDrugs[1][iPos])
			iKeys |= (1<<iPos);
		}
		else FormatMenu("\r[\w%d\r]\d [0] %s^n", iPos+1, g_szDrugs[1][iPos])
	}
	FormatMenu("^n\r[\w0\r]\w Выход");
	return ShowMenu("Show_Gear");
}

public Handle_GearMenu(id, iKey) {
	if(iKey == 9) return;
	new szBuff[20];
	formatex(szBuff, charsmax(szBuff), "UseDrugs_%d", iKey+1);
	if(task_exists(id + TASK_DRUGS_USE)) remove_task(id + TASK_DRUGS_USE);
	set_task(3.0, szBuff, id + TASK_DRUGS_USE);
	set_task(30.0, "UnUseDrugs", id + TASK_UN_USE_DRUGS);
	g_iDrugs[id][iKey]--;
	switch(iKey) {
		case 0: SetModel(id, SIGARETTE);
		case 1: SetModel(id, TABLET);
		case 2: SetModel(id, TABLET);
		case 3: SetModel(id, SYRINEG);
	}
}

public Show_CraftDrugs(id) {
	jbe_informer_offset_up(id);
	CreateMenu("\w[Drugs]\y Крафтинг наркотиков^n");
	FormatMenu("\wБумага: %d | Лезвие: %d ^nСинтезаторы: %d | Каннабис: %d^n\rRed\y - Нету ресурсва | \wБелый \y- есть ресурс^n^n", g_iDrugs[id][4], g_iDrugs[id][1 + 4], g_iDrugs[id][2 + 4], g_iDrugs[id][3 + 4]);
	
	for(new iPos; iPos <= 3; iPos++) {
		if(PAPER(id) >= CRAFT(0) && RAZOR(id) >= CRAFT(1) && SYNTHS(id) >= CRAFT(2) && HEMP(id) >= CRAFT(3)) {
			FormatMenu("\r[\w%d\r] \w(%d) \y[\w%d\y|\w%d\y|\w%d\y|\w%d\y]\w %s^n", iPos+1, g_iDrugs[id][4+iPos], CRAFT(0), CRAFT(1), CRAFT(2), CRAFT(3), g_szDrugs[0][iPos]);
			iKeys |= (1<<iPos);
		}
		else {
			// Грёбанный лимит --_--
			new szText[50];
			formatex(szText, charsmax(szText), "%s%d\y|", PAPER(id) < CRAFT(0) ? "\r":"\w", CRAFT(0));
			formatex(szText, charsmax(szText), "%s%s%d\y|", szText, RAZOR(id) < CRAFT(1) ? "\r":"\w", CRAFT(1));
			formatex(szText, charsmax(szText), "%s%s%d\y|", szText, SYNTHS(id) < CRAFT(2) ? "\r":"\w", CRAFT(2));
			formatex(szText, charsmax(szText), "%s%s%d", szText, HEMP(id) < CRAFT(3) ? "\r":"\w", CRAFT(3));
			
			FormatMenu("\r[\w%d\r] \w(%d) \y[%s\y]\w %s^n", iPos+1, g_iDrugs[id][4+iPos], szText, g_szDrugs[1][iPos]);
		}																
	}
	FormatMenu("^n\r[\w0\r]\w Выход");
	return ShowMenu("Show_CraftDrugs");
}

public Handle_CraftDrugsMenu(id, iPos) {
	if(iPos == 9) return PLUGIN_HANDLED;
	
	PAPER(id) -= CRAFT(0);
	RAZOR(id) -= CRAFT(1);
	SYNTHS(id) -= CRAFT(2);
	HEMP(id) -= CRAFT(3);
	
	if(random_num(1, 10) <= 5) {
		new iReturnDrugs = random_num(0, 5);
		g_iDrugs[id][iPos] += !iReturnDrugs ? 2:1; 
		client_print_color(id, print_team_blue, "^1[^4INFO^1] Вы изготовили^4 %s^1. Количество:^4 %d^1.", g_szDrugs[1][iPos], !iReturnDrugs ? 2:1);
	}
	else client_print_color(id, print_team_blue, "^1[^4INFO^1] Что-то пошло не так, наркотик^4 %s^1 испортился.", g_szDrugs[1][iPos]);	
	return Show_CraftDrugs(id);
}

public UnUseDrugs(id) {
	id -= TASK_UN_USE_DRUGS;
	if(IsSetBit(g_iBitUserUseDrugs, id)) {
		if(is_user_alive(id)) {
			UTIL_SetFov(id);
			UTIL_ScreenFade(id, 0, 0, 0, 0, 0, 0, 0, 1);
		}
		if(task_exists(id + TASK_DRUGS_USE)) remove_task(id + TASK_DRUGS_USE);
		if(task_exists(id + TASK_SCREEN_SHAKE)) remove_task(id + TASK_SCREEN_SHAKE);
		if(task_exists(id + TASK_SCREEN_FADE)) remove_task(id + TASK_SCREEN_FADE);
		if(task_exists(id + TASK_PUN_CHANGLE)) remove_task(id + TASK_PUN_CHANGLE);
		ClearBit(g_iBitUserUseDrugs, id);
		ClearBit(g_iBitUserDamageDodge, id);
		ClearBit(g_iBitUserMultiDamage, id);
		if(IsSetBit(g_iBitUserSpeed, id)) {
			ClearBit(g_iBitUserSpeed, id);		
			if(is_user_alive(id)) set_entvar(id, var_maxspeed, get_entvar(id, var_maxspeed) / 1.5);
		}
		if(IsSetBit(g_iBitUserGravity, id)) {
			ClearBit(g_iBitUserGravity, id);
			if(is_user_alive(id)) set_entvar(id, var_gravity, rg_get_user_gravity(id) + 0.2);
		}
	}
}

public UnOverdose(id) {
	id -= TASK_OVERDOSE;
	if(g_iWarns[id][OVERDOSE] > 0) g_iWarns[id][OVERDOSE]--;
	else remove_task(id + TASK_OVERDOSE);
}

public UserBreaking(id) {
	id -= TASK_BREAKING;
	if(!is_user_alive(id)) return;
	if(!task_exists(id + TASK_SLAP_BREAKING)) set_task(1.0, "UserSlap", id + TASK_SLAP_BREAKING, _, _, "b");
}

public UserSlap(id) {
	id -= TASK_SLAP_BREAKING;
	if(get_entvar(id, var_health) <= 1.0) {
		ExecuteHamB(Ham_Killed, id, id, 0);
		if(task_exists(id + TASK_SLAP_BREAKING)) remove_task(id + TASK_SLAP_BREAKING);
		return;
	}
	UTIL_ScreenFade(id, (1<<13), (1<<13), 4, 255, 0, 0, 100, 1);
	user_slap(id, 1, 1);
}

public UseDrugs_1(id) {
	id -= TASK_DRUGS_USE;
	if(task_exists(id + TASK_SLAP_BREAKING)) remove_task(id + TASK_SLAP_BREAKING);
	if(g_iWarns[id][OVERDOSE]++ && !task_exists(id + TASK_OVERDOSE)) set_task(60.0, "UnOverdose", id + TASK_OVERDOSE, _, _, "b");
	if(g_iWarns[id][OVERDOSE] >= 5) {
		if(task_exists(id + TASK_OVERDOSE)) remove_task(id + TASK_OVERDOSE);
		client_print_color(id, print_team_blue, "^1[^4INFO^1] Вы умерли от ^4передозировки.");
		ExecuteHamB(Ham_Killed, id, id, 0);
		g_iWarns[id][OVERDOSE] = 0;
		return;
	}
		
	if(IsNotSetBit(g_iBitUserBreaking, id) && g_iWarns[id][BREAKING]++ >= 5) {
		SetBit(g_iBitUserBreaking, id);
		if(!task_exists(id + TASK_BREAKING)) remove_task(id + TASK_BREAKING);
		set_task(120.0, "UserBreaking", id + TASK_BREAKING, _, _, "b");
	}
	
	jbe_return_drugs_model(id);
	SetBit(g_iBitUserUseDrugs, id);
	SetBit(g_iBitUserDamageDodge, id);
	UTIL_ScreenFade(id, 0, 0, 4, 255, 0, 0, 100, 1);
	set_task(1.5, "ScreenShakeUse1", id + TASK_SCREEN_SHAKE, _, _, "a", 16);
	client_print_color(id, print_team_blue, "^1[^4INFO^1] В течении 30 секунд Вы будете уворачиваться от^4 30%% пуль.");
}

public UseDrugs_2(id) {
	id -= TASK_DRUGS_USE;
	if(task_exists(id + TASK_SLAP_BREAKING)) remove_task(id + TASK_SLAP_BREAKING);
	if(g_iWarns[id][OVERDOSE]++ && !task_exists(id + TASK_OVERDOSE)) set_task(60.0, "UnOverdose", id + TASK_OVERDOSE, _, _, "b");
	if(g_iWarns[id][OVERDOSE] >= 5) {
		if(task_exists(id + TASK_OVERDOSE)) remove_task(id + TASK_OVERDOSE);
		client_print_color(id, print_team_blue, "^1[^4INFO^1] Вы умерли от ^4передозировки.");
		ExecuteHamB(Ham_Killed, id, id, 0);
		g_iWarns[id][OVERDOSE] = 0;
		return;
	}
		
	if(IsNotSetBit(g_iBitUserBreaking, id) && g_iWarns[id][BREAKING]++ >= 5) {
		SetBit(g_iBitUserBreaking, id);
		if(!task_exists(id + TASK_BREAKING)) remove_task(id + TASK_BREAKING);
		set_task(120.0, "UserBreaking", id + TASK_BREAKING, _, _, "b");
	}
	
	jbe_return_drugs_model(id);
	SetBit(g_iBitUserUseDrugs, id);
	SetBit(g_iBitUserSpeed, id);
	UTIL_SetFov(id, 250);
	set_entvar(id, var_maxspeed, float(get_entvar(id, var_maxspeed)) * 1.5);
	UTIL_ScreenFade(id, (1<<130), (1<<130), 0, 0, 100, 0, 10);
	client_print_color(id, print_team_blue, "^1[^4INFO^1] В течении 30 секунд Вы будете бегать в 1.5 раза быстрее.");
}

public UseDrugs_3(id)
{
	id -= TASK_DRUGS_USE;
	if(task_exists(id + TASK_SLAP_BREAKING)) remove_task(id + TASK_SLAP_BREAKING);	
	if(g_iWarns[id][OVERDOSE]++ && !task_exists(id + TASK_OVERDOSE)) set_task(60.0, "UnOverdose", id + TASK_OVERDOSE, _, _, "b");
	if(g_iWarns[id][OVERDOSE] >= 5) {
		if(task_exists(id + TASK_OVERDOSE)) remove_task(id + TASK_OVERDOSE);
		client_print_color(id, print_team_blue, "^1[^4INFO^1] Вы умерли от ^4передозировки.");
		ExecuteHamB(Ham_Killed, id, id, 0);
		g_iWarns[id][OVERDOSE] = 0;
		return;
	}
		
	if(IsNotSetBit(g_iBitUserBreaking, id) && g_iWarns[id][BREAKING]++ >= 5) {
		SetBit(g_iBitUserBreaking, id);
		if(!task_exists(id + TASK_BREAKING)) remove_task(id + TASK_BREAKING);
		set_task(120.0, "UserBreaking", id + TASK_BREAKING, _, _, "b");
	}
	
	jbe_return_drugs_model(id);
	SetBit(g_iBitUserUseDrugs, id);
	SetBit(g_iBitUserGravity, id);
	set_task(1.5, "ScreenFadeUse3", id + TASK_SCREEN_FADE, _, _, "a", 14);
	set_entvar(id, var_gravity, rg_get_user_gravity(id) - 0.2);
	client_print_color(id, print_team_blue, "^1[^4INFO^1] В течении 30 секунд Вы будете прыгать на 20%% выше.");
}

public UseDrugs_4(id) {
	id -= TASK_DRUGS_USE;
	if(task_exists(id + TASK_SLAP_BREAKING)) remove_task(id + TASK_SLAP_BREAKING);
	if(g_iWarns[id][OVERDOSE]++ && !task_exists(id + TASK_OVERDOSE)) set_task(60.0, "UnOverdose", id + TASK_OVERDOSE, _, _, "b");
	if(g_iWarns[id][OVERDOSE] >= 5) {
		if(task_exists(id + TASK_OVERDOSE)) remove_task(id + TASK_OVERDOSE);
		client_print_color(id, print_team_blue, "^1[^4INFO^1] Вы умерли от ^4передозировки.");
		ExecuteHamB(Ham_Killed, id, id, 0);
		g_iWarns[id][OVERDOSE] = 0;
		return;
	}
		
	if(IsNotSetBit(g_iBitUserBreaking, id) && g_iWarns[id][BREAKING]++ >= 5) {
		SetBit(g_iBitUserBreaking, id);
		if(!task_exists(id + TASK_BREAKING)) remove_task(id + TASK_BREAKING);
		set_task(120.0, "UserBreaking", id + TASK_BREAKING, _, _, "b");
	}
	
	jbe_return_drugs_model(id);
	SetBit(g_iBitUserUseDrugs, id);
	SetBit(g_iBitUserDamageDodge, id);
	SetBit(g_iBitUserMultiDamage, id);
	UTIL_SetFov(id, 250);
	set_task(4.0, "UTIL_PunChangle", id + TASK_PUN_CHANGLE, _, _, "a", 7);
	set_task(1.5, "ScreenFadeUse3", id + TASK_SCREEN_FADE, _, _, "a", 14);
	set_task(1.5, "ScreenShakeUse1", id + TASK_SCREEN_SHAKE, _, _, "a", 16);
	client_print_color(id, print_team_blue, "^1[^4INFO^1] В течении 30 секунд у Вас 30%% шанс уворота от пуль и увеличение урона на 1.5 раз.");
}

public UTIL_PunChangle(id) {
	id -= TASK_PUN_CHANGLE
	if(!is_user_alive(id) && task_exists(id + TASK_PUN_CHANGLE)) {
		remove_task(id + TASK_PUN_CHANGLE)
		return;
	}		
	set_entvar(id, var_punchangle, { 150.0, 200.0, 50.0 });
}

public ScreenFadeUse3(id) {
	id -= TASK_SCREEN_FADE;
	if(!is_user_alive(id) && task_exists(id + TASK_SCREEN_FADE)) {
		remove_task(id + TASK_SCREEN_FADE)
		return;
	}	
	UTIL_ScreenFade(id, 0, 0, 4, random_num(100, 255), random_num(100, 255), random_num(100, 255), 100, 1);
}

public ScreenShakeUse1(id) {
	id -= TASK_SCREEN_SHAKE;
	if(!is_user_alive(id) && task_exists(id + TASK_SCREEN_SHAKE)) {
		remove_task(id + TASK_SCREEN_SHAKE)
		return;
	}	
	UTIL_ScreenShake(id, (1<<15), (1<<14), (1<<15));
}

stock _register_menu(szMenu[], iKey, szHandle[]) register_menucmd(register_menuid(szMenu), iKey, szHandle);

stock SetModel(id, iModel) {
	if(iModel == SYRINEG) {
		jbe_use_drugs_model(id);
		return PLUGIN_HANDLED;
	}

	static iszViewModel, szBuff[60];
	formatex(szBuff, charsmax(szBuff), "models/egoist/jb/shop/v_syringe.mdl");
		
	if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, szBuff))) set_entvar(id, var_viewmodel, iszViewModel);
	UTIL_WeaponAnimation(id, 1);
	set_member(id, m_flNextAttack, 3.0);
	return PLUGIN_HANDLED;
}

stock jbe_return_drugs_model(pPlayer) {
	new iActiveItem = get_member(pPlayer, m_pActiveItem);
	if(iActiveItem > 0) ExecuteHamB(Ham_Item_Deploy, iActiveItem);
}

stock UTIL_ScreenFade(pPlayer, iDuration, iHoldTime, iFlags, iRed, iGreen, iBlue, iAlpha, iReliable = 0) {
	switch(pPlayer) {
		case 0: {
			message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, 98);
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
			engfunc(EngFunc_MessageBegin, iReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, 98, {0.0, 0.0, 0.0}, pPlayer);
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

stock UTIL_ScreenShake(pPlayer, iAmplitude, iDuration, iFrequency, iReliable = 0) {
	engfunc(EngFunc_MessageBegin, iReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, 97, {0.0, 0.0, 0.0}, pPlayer);
	write_short(iAmplitude);
	write_short(iDuration);
	write_short(iFrequency);
	message_end();
}

stock UTIL_SetFov( iPlayer, iDegrees = 90 ) {
	message_begin( MSG_ONE_UNRELIABLE, 95, _, iPlayer );
	write_byte( iDegrees );
	message_end( );
}

stock UTIL_WeaponAnimation(pPlayer, iAnimation) {
	set_pev(pPlayer, pev_weaponanim, iAnimation);
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0.0, 0.0, 0.0}, pPlayer);
	write_byte(iAnimation);
	write_byte(0);
	message_end();
}

stock Float:rg_get_user_gravity(const player) {
	return Float:get_entvar(player, var_gravity);
}