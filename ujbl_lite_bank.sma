#include <amxmodx>
#include <jbe_core>
#include <sqlx>
#include <old_menu>
#include <reapi>

new g_szBankHost[32], g_szBankUser[32], g_szBankPassword[32], g_szBankDataBase[32], g_szBankTable[32], Handle: g_sqlTuple;
new g_iBitUserConnected, g_iBitUserType, g_iBitUserLoadMoneyOk, g_iBankMoney[33], g_iPutMoney[33], g_iBankLimit[33];

enum _:TOTAL_MONEY_TYPES { SQL_CHECK, SQL_LOAD, SQL_IGNORE };

/* -> Бит суммы для игроков -> */
#define SetBit(%0,%1) 				((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) 			((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) 			((%0) & (1 << (%1)))
#define InvertBit(%0,%1) 			((%0) ^= (1 << (%1)))
#define IsNotSetBit(%0,%1) 			(~(%0) & (1 << (%1)))


public plugin_natives() register_native("ujbl_open_bank", "Show_BankMenu", 1);
public plugin_init() {
	register_plugin("[UJBL] Lite Bank", "0.0.1", "ToJI9IHGaa");
	register_menucmd(register_menuid("Show_BankMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<9), "Handle_BankMenu");
	
	for(new id = 1; id <= 32; id++) {
		g_iPutMoney[id] = 10;
		g_iBankLimit[id] = 20000;
	}
	
	register_cvar("jbe_bank_sql_host", "127.0.0.1");
	register_cvar("jbe_bank_sql_user", "root");
	register_cvar("jbe_bank_sql_password", "");
	register_cvar("jbe_bank_sql_database", "ujbl");
	register_cvar("jbe_bank_sql_table", "bank");
	
	set_task(1.0, "jbe_get_cvars");
}

public jbe_get_cvars() {
	get_cvar_string("jbe_bank_sql_host", g_szBankHost, charsmax(g_szBankHost));
	get_cvar_string("jbe_bank_sql_user", g_szBankUser, charsmax(g_szBankUser));
	get_cvar_string("jbe_bank_sql_password", g_szBankPassword, charsmax(g_szBankPassword));
	get_cvar_string("jbe_bank_sql_database", g_szBankDataBase, charsmax(g_szBankDataBase));
	get_cvar_string("jbe_bank_sql_table", g_szBankTable, charsmax(g_szBankTable));

	g_sqlTuple = SQL_MakeDbTuple(g_szBankHost, g_szBankUser, g_szBankPassword, g_szBankDataBase);
	new szQuery[506], szDataNew[1];
	formatex(szQuery, charsmax(szQuery), "CREATE TABLE IF NOT EXISTS `%s` (`id` int(11) NOT NULL AUTO_INCREMENT, `authId` varchar(32) NOT NULL, `money` int(11) DEFAULT '0', PRIMARY KEY (`id`)) ", g_szBankTable);
	szDataNew[0] = SQL_IGNORE;
	SQL_ThreadQuery(g_sqlTuple, "SQL_Handler", szQuery, szDataNew, sizeof szDataNew);
}
	
public client_putinserver(id) {
	SetBit(g_iBitUserConnected, id);
	set_task(10.0, "LoadPlayerMoney", id);
}

public client_disconnected(id) {
	if(IsNotSetBit(g_iBitUserConnected, id)) return;
	ClearBit(g_iBitUserConnected, id);
	SavePlayerMoney(id);
}

public LoadPlayerMoney(id) {	
	new szSteam[32], szQuery[128], szData[2];
	get_user_authid(id, szSteam, charsmax(szSteam));
	
	formatex(szQuery, charsmax(szQuery), "SELECT * FROM `%s` WHERE `authId` = '%s'", g_szBankTable, szSteam);
	szData[0] = SQL_CHECK;
	szData[1] = id;
	SQL_ThreadQuery(g_sqlTuple, "SQL_Handler", szQuery, szData, sizeof szData);
	
	SetBit(g_iBitUserLoadMoneyOk, id);
}

public SavePlayerMoney(id) {
	new szSteam[32], szQuery[128], szData[2];
	get_user_authid(id, szSteam, charsmax(szSteam));
	
	formatex(szQuery, charsmax(szQuery), "UPDATE `%s` SET `money`='%d' WHERE `authId` = '%s';", g_szBankTable, g_iBankMoney[id], szSteam);
	szData[0] = SQL_IGNORE;
	szData[1] = id;
	SQL_ThreadQuery(g_sqlTuple, "SQL_Handler", szQuery, szData, sizeof szData);
}

public SQL_Handler(iFailState, Handle:sqlQuery, const szError[], iError, const szData[], iDataSize) {
	switch(iFailState) {
		case TQUERY_CONNECT_FAILED: {
			log_amx("[BANK] MySQL connection failed");
			log_amx("[ %d ] %s", iError, szError);
			if(iDataSize) log_amx("Query state: %d", szData[0]);
			//bSetModBit(g_bDataBaseIsConnected);
			return PLUGIN_HANDLED;
		}
		
		case TQUERY_QUERY_FAILED: {
			log_amx("[BANK] MySQL query failed");
			log_amx("[ %d ] %s", iError, szError);
			if(iDataSize) log_amx("Query state: %d", szData[1]);
			//bSetModBit(g_bDataBaseIsConnected);
			return PLUGIN_HANDLED;
		}
	}
	
	switch(szData[0]) {
		case SQL_CHECK: {
			new id = szData[1];
			if(IsNotSetBit(g_iBitUserConnected, id)) return PLUGIN_HANDLED;
			switch(SQL_NumResults(sqlQuery)) {
				case 0: {
					new szSteam[32], szQuery[128], szDataNew[2];
					get_user_authid(id, szSteam, charsmax(szSteam));
					
					formatex(szQuery, charsmax(szQuery), "INSERT INTO `%s`(`authId`, `money`) VALUES ('%s', '0')", g_szBankTable, szSteam);
					szDataNew[0] = SQL_IGNORE;
					szDataNew[1] = id;
					SQL_ThreadQuery(g_sqlTuple, "SQL_Handler", szQuery, szDataNew, sizeof szDataNew);
				}
				default: {
					new szSteam[32], szQuery[128], szDataNew[2];
					get_user_authid(id, szSteam, charsmax(szSteam));
					
					formatex(szQuery, charsmax(szQuery),"SELECT `money` FROM `%s` WHERE `authId` = '%s'", g_szBankTable, szSteam);
					szDataNew[0] = SQL_LOAD;
					szDataNew[1] = id;
					SQL_ThreadQuery(g_sqlTuple, "SQL_Handler", szQuery, szDataNew, sizeof szDataNew);
				}
			}
		}
		case SQL_LOAD: {
			new id = szData[1];
			if(IsNotSetBit(g_iBitUserConnected, id)) return PLUGIN_HANDLED;
			new iMoney = SQL_ReadResult(sqlQuery, 0);
			g_iBankMoney[id] = iMoney;
			//jbe_forse_lvl(id);
		}
	}
	return PLUGIN_HANDLED;
}

public Show_BankMenu(id) {
	if(task_exists(id)) {
		client_print(id, print_center, "Дождитесь авторизации!");
		return PLUGIN_HANDLED;
	}
	
	if(IsNotSetBit(g_iBitUserLoadMoneyOk, id)) LoadPlayerMoney(id);
	
	jbe_informer_offset_up(id);
	CreateMenu("^t^t\y<== \rБанк \y==>^n^nНаличные: \r%d$^n\yВ банке: \r%d$^n\yЛимит: \r%d$^n^n", jbe_get_user_money(id), g_iBankMoney[id], g_iBankLimit[id]);
	
	iKeys |= (1<<1|1<<1|1<<2|1<<3|1<<4);
	
	if(jbe_get_user_money(id) >= 1000) {
		FormatMenu("\r[1]\w Увеличить limit на 10.000$ - Карта \r[1000$]^n");
		iKeys |= (1<<0);
	}
	else FormatMenu("\r[1]\d Увеличить limit на 10.000$ - Карта [1000$]^n");
	
	FormatMenu("\r[2]\w %s^n", IsSetBit(g_iBitUserType, id) ? "Положить" : "Снять");
	FormatMenu("\r[3]\w [Click: %s 10] Сумма: \r%d$^n", IsSetBit(g_iBitUserType, id) ? "+" : "-", g_iPutMoney[id]);
	FormatMenu("\r[4]\w %s \rвсе \wденьги^n", IsSetBit(g_iBitUserType, id) ? "Положить" : "Снять");
	FormatMenu("\r[5]\w Выполнить задачу^n^n");
	FormatMenu("\r[0]\w Выход");
	
	return ShowMenu("Show_BankMenu");
}

public Handle_BankMenu(id, iKey) {
	switch(iKey) {
		case 0:  {
			if(g_iBankLimit[id] <= 90000) {
				if(jbe_get_user_money(id) >= 1000) {
					jbe_set_user_money(id, jbe_get_user_money(id) - 1000, true);
					g_iBankLimit[id] += 10000;
				}
			}
			else client_print(id, print_center, "Больше 100.000 нельзя!");
		}
		case 1: InvertBit(g_iBitUserType, id);
		case 2: {
			if(IsNotSetBit(g_iBitUserType, id)) {
				if(g_iPutMoney[id] >= 10) g_iPutMoney[id] -= 10;
			}
			else if(g_iPutMoney[id] <= 1000) g_iPutMoney[id] += 10;			
		}
		case 3: {
			if(IsSetBit(g_iBitUserType, id)) {
				if(g_iBankMoney[id] >= g_iBankLimit[id]) return Show_BankMenu(id);
				
				if(jbe_get_user_money(id) < g_iBankLimit[id]) {
					g_iBankMoney[id] += jbe_get_user_money(id);
					jbe_set_user_money(id, 0, true);
				}
				else {
					jbe_set_user_money(id, jbe_get_user_money(id) - (g_iBankLimit[id] - g_iBankMoney[id]), true);
					g_iBankMoney[id] += g_iBankLimit[id];					
				}
			}
			else {
				jbe_set_user_money(id, jbe_get_user_money(id) + g_iBankMoney[id], true);
				g_iBankMoney[id] = 0;
			}
		}
		case 4: {
			if(IsSetBit(g_iBitUserType, id)) {
				if(g_iBankMoney[id] >= g_iBankLimit[id]) {
					client_print(id, print_center, "Больше %d нельзя!", g_iBankLimit[id]);
					return Show_BankMenu(id);
				}
				
				if(jbe_get_user_money(id) < g_iPutMoney[id]) {
					client_print(id, print_center, "Недостаточно денег!");
					return Show_BankMenu(id);
				}
				
				jbe_set_user_money(id, jbe_get_user_money(id) - g_iPutMoney[id], true);				
				g_iBankMoney[id] += g_iPutMoney[id];
				if(g_iBankMoney[id] > g_iBankLimit[id]) g_iBankMoney[id] = g_iBankLimit[id];
			}
			else {
				if(g_iPutMoney[id] > g_iBankMoney[id]) {
					client_print(id, print_center, "В банке недостаточно денег!");
					return Show_BankMenu(id);
				}
				
				jbe_set_user_money(id, jbe_get_user_money(id) + g_iPutMoney[id], true);
				g_iBankMoney[id] -= g_iPutMoney[id];
			}
		}
		case 9: return PLUGIN_HANDLED;
	}
	return Show_BankMenu(id);
}