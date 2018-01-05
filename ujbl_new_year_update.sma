#include <amxmodx>
#include <fakemeta>	
#include <engine>
#include <reapi>
#include <sqlx>
#include <jbe_core>
#include <old_menu>
#include <amxmisc>

#define COST_1	200				// Cost Hook's
#define COST_2	300				// Cost Vip's
#define COST_3	40				// Cost 100 exp and 1.000$
#define COST_4	60				// Cost 50 exp and 500$ all players
	
new const g_id_bear[] = "bear_ent";						// Index Bear
new const g_id_tree[] = "tree_ent";						// Index Tree
new const g_id_gifts[] = "gifts_ent";					// Index Gifts

new const g_BearModels[] = "models/egoist/jb/other/new_year_bear.mdl";
new const g_TreeModels[] = "models/egoist/jb/other/new_year_tree.mdl";
new const g_GiftsModels[] = "models/egoist/jb/other/new_year_gift.mdl";

new Handle:g_sqlTuple, g_szGiftHost[32], g_szGiftUser[32], g_szGiftPassword[32], g_szGiftDataBase[32], g_szGiftTable[32];
enum { SQL_CHECK, SQL_LOAD, SQL_IGNORE };

new g_szConfigFileBear[128];
new g_szConfigFileTree[128];

new Float:g_iBearCoord[3];

new g_iGifts[33], g_iBlock_Gifts[33], g_FixFloodChanel[33];
new sp_Ball;

public plugin_natives() {
	register_native("set_user_gift", "default_set_user_gift", 1);
	register_native("get_user_gift", "_get_user_gift", 1);
}

public plugin_precache() {
	sp_Ball = precache_model("sprites/egoist/jb/ball_mini.spr");
	engfunc(EngFunc_PrecacheSound, "egoist/jb/other/new_year.wav");
	engfunc(EngFunc_PrecacheGeneric, "sound/egoist/jb/other/happy.mp3");
	precache_model(g_BearModels);
	precache_model(g_TreeModels);
	precache_model(g_GiftsModels);
}

public plugin_init() {
	register_plugin("New Year Update", "0.0.3", "ToJI9IHGaa");
	
	register_menu("Show_BonusMenu", (1<<0|1<<1|1<<2|1<<3|1<<0), "Handle_BonusMenu");
	
	register_clcmd("say /give_gift_me", "TestMoney");
	register_clcmd("bear_spawn", "SpawnBear");
	register_clcmd("tree_spawn", "SpawnTree");
	register_clcmd("bear_remove", "RemoveBear");
	register_clcmd("tree_remove", "RemoveTree");
	
	register_touch(g_id_gifts, g_id_gifts, "ClearGifts");
	register_touch(g_id_bear, "player", "TouchBear");
	register_touch(g_id_gifts, "player", "TouchGifts");
	RegisterHookChain(RG_CBasePlayer_Killed, "Player_Killed", true);
	
	register_logevent("LogEvent_RoundStart", 2, "1=Round_Start");
	
	register_cvar("gift_sql_host", "127.0.0.1");	
	register_cvar("gift_sql_user", "root");	
	register_cvar("gift_sql_password", "");	
	register_cvar("gift_sql_database", "ujbl");
	register_cvar("gift_sql_table", "snowball_exp");	
}

public LogEvent_RoundStart() {
	for(new id = 1; id <= MaxClients; id++) g_iBlock_Gifts[id] = 0;
	new iHour; time(iHour);
	if(iHour >= 21 || iHour <= 8) return PLUGIN_HANDLED;
	new iEnt, Float: fOrigin[3];
	new szClassName[10], iEntity = -1;
	while((iEnt = find_ent_by_class(iEnt, g_id_tree)) > 0) {	
		if(pev_valid(iEnt)) {
			get_entvar(iEnt, var_origin, fOrigin);		
	
			while((iEntity = find_ent_in_sphere(iEntity, fOrigin, 100.0 )) > 0) {
				get_entvar(iEntity, var_classname, szClassName, 9);		
				if(equal(szClassName, g_id_gifts)) remove_entity(iEntity);				
			}
			fOrigin[2] = fOrigin[2] + 20.0;
			fOrigin[1] = fOrigin[1] + random_float(-30.0, 30.0);
			Create_Gift(fOrigin);
		}
	}
	client_print_color(0, print_team_blue, "^1[^4INFO^1] Подарки появились возле ^4ёлок^1!");
	return PLUGIN_HANDLED;
}
public TestMoney(id) if(get_user_flags(id) & ADMIN_ADMIN) g_iGifts[id] = g_iGifts[id] + 100;

public plugin_cfg() {
	_load_bear();
	_load_tree();
	set_task(0.1, "_load_db");
}

_load_bear() {
	new szMapName[32];
	get_mapname(szMapName, 31);
	strtolower(szMapName);
	
	formatex(g_szConfigFileBear[0], 127, "addons/amxmodx/data/jb_bear");
	
	if(!dir_exists(g_szConfigFileBear[0])) {
		mkdir(g_szConfigFileBear);
		format( g_szConfigFileBear, 127, "%s/%s.txt", g_szConfigFileBear, szMapName );
		return;
	}
	
	format(g_szConfigFileBear, 127, "%s/%s.txt", g_szConfigFileBear, szMapName);
	
	if(!file_exists(g_szConfigFileBear)) return;
	new iFile = fopen(g_szConfigFileBear, "rt");
	if(!iFile) return;
	
	new x[16], y[16], z[16], szData[sizeof(x) + sizeof(y) + sizeof(z) + 3];
	
	fgets(iFile, szData, charsmax(szData));
	trim(szData);
	
	if(!szData[0]) return;
	parse(szData, x, 15, y, 15, z, 15 );
	
	g_iBearCoord[0] = str_to_float(x);
	g_iBearCoord[1] = str_to_float(y);
	g_iBearCoord[2] = str_to_float(z);				
	
	CreateEntity(g_iBearCoord, 1);
	fclose(iFile);
}

_load_tree()
{
	new szMapName[32];
	get_mapname(szMapName, charsmax(szMapName));
	strtolower(szMapName);
	
	formatex(g_szConfigFileTree, 127, "addons/amxmodx/data/jb_tree");
	
	if(!dir_exists(g_szConfigFileTree)) 
	{
		mkdir(g_szConfigFileTree);
		format(g_szConfigFileTree, 127, "%s/%s.txt", g_szConfigFileTree, szMapName);	
		return;
	}
	
	format(g_szConfigFileTree, 127, "%s/%s.txt", g_szConfigFileTree, szMapName);
	
	if(!file_exists(g_szConfigFileTree)) return;
	new iFile = fopen(g_szConfigFileTree, "rt");
	if(!iFile) return;
	
	new Float:vOrigin[3], x[16], y[16], z[16], 
	szData[sizeof(x) + sizeof(y) + sizeof(z) + 3];
	
	while(!feof(iFile)) 
	{
		fgets(iFile, szData, charsmax(szData));
		trim(szData);
		
		if(!szData[0]) continue;
		
		parse(szData, x, charsmax(x), y, charsmax(y), z, charsmax(z));
		
		vOrigin[0] = str_to_float(x);
		vOrigin[1] = str_to_float(y);
		vOrigin[2] = str_to_float(z);
		
		CreateEntity(vOrigin, 2);
	}
	fclose(iFile);
}

public _load_db() {
	get_cvar_string("gift_sql_host", g_szGiftHost, charsmax(g_szGiftHost));
	get_cvar_string("gift_sql_user", g_szGiftUser, charsmax(g_szGiftUser));
	get_cvar_string("gift_sql_password", g_szGiftPassword, charsmax(g_szGiftPassword));
	get_cvar_string("gift_sql_database", g_szGiftDataBase, charsmax(g_szGiftDataBase));
	get_cvar_string("gift_sql_table", g_szGiftTable, charsmax(g_szGiftTable));
	g_sqlTuple = SQL_MakeDbTuple(g_szGiftHost, g_szGiftUser, g_szGiftPassword, g_szGiftDataBase);
	new szQuery[512], szDataNew[1];
	formatex(szQuery, charsmax(szQuery), "CREATE TABLE IF NOT EXISTS `%s` (`id` int(11) NOT NULL AUTO_INCREMENT, `authId` varchar(64) NOT NULL, `exp` int(11) DEFAULT '0', PRIMARY KEY (`id`)) ", g_szGiftTable);
	szDataNew[0] = SQL_IGNORE;
	SQL_ThreadQuery(g_sqlTuple, "SQL_Handler", szQuery, szDataNew, sizeof szDataNew);
}

public SpawnBear(id) if(get_user_flags(id) & ADMIN_RCON) Spawn_Entity(id, 1);
public SpawnTree(id) if(get_user_flags(id) & ADMIN_RCON) Spawn_Entity(id, 2);
public RemoveBear(id) if(get_user_flags(id) & ADMIN_RCON) Remove_Entity(id, 1);
public RemoveTree(id) if(get_user_flags(id) & ADMIN_RCON) Remove_Entity(id, 2);

public Spawn_Entity(id, iType) {
	new iOrigin[3]; 					//Создаем массив для хранение координат
	get_user_origin(id, iOrigin, 3); 	//Получаем координаты куда смотрит игрок
	new Float: fOrigin[3]; 				//Создаем массив для float коодинат
	IVecFVec(iOrigin, fOrigin); 			//Конвертируем координаты в дробные
	if(iType == 1) {
		g_iBearCoord[0] = fOrigin[0];
		g_iBearCoord[1] = fOrigin[1];
		g_iBearCoord[2] = fOrigin[2];
	}
	if(CreateEntity(fOrigin, iType)) SaveEntity(iType);
}

public CreateEntity(const Float:fOrigin[3], iType) {
	new iEntity = rg_create_entity("info_target", false); 			//Создаем объект info_target

	if(!pev_valid(iEntity)) return PLUGIN_HANDLED; 	//Заканчиваем. Дальше нам делать нечего

	set_entvar(iEntity, var_origin, fOrigin); 			//Присваиваем координаты
	if(iType == 1) {
		set_entvar(iEntity, var_classname, g_id_bear);
		set_entvar(iEntity, var_solid, SOLID_BBOX);
	}
	else {
		set_entvar(iEntity, var_classname, g_id_tree);
		set_entvar(iEntity, var_solid, SOLID_TRIGGER);
	}
	
	set_entvar(iEntity, var_movetype, MOVETYPE_NONE); 	//Не задаем тип движения, во всяком случаи пока
	set_entvar(iEntity, var_sequence, 0); 				//Выставляем № анимации при создании
	set_entvar(iEntity, var_framerate, 1.0); 			//Выставляем скорость анимации
	set_entvar(iEntity, var_nextthink, get_gametime() + 1.0); //Создаем запуск think

	if(iType == 1) {
		engfunc(EngFunc_SetModel, iEntity, g_BearModels);
		engfunc(EngFunc_SetSize, iEntity, Float:{-20.0,-20.0,-20.0}, Float:{5.0,10.0,30.0});
	}
	else engfunc(EngFunc_SetModel, iEntity, g_TreeModels);
	
	return PLUGIN_HANDLED;
}

public Remove_Entity(const id, iType) {	
	new Float:vOrigin[3], szClassName[10], iEntity = -1, iDeleted;
	get_entvar(id, var_origin, vOrigin);
	
	while((iEntity = find_ent_in_sphere(iEntity, vOrigin, 100.0 )) > 0) {
		get_entvar(iEntity, var_classname, szClassName, 9);
		
		switch(iType) {
			case 1: {
				if(equal(szClassName, g_id_bear)) {
					remove_entity(iEntity);	
					iDeleted++;
				}
			}
			case 2: {
				if(equal(szClassName, g_id_tree)) {
					remove_entity(iEntity);	
					iDeleted++;
				}
			}
		}
	}
	
	if(iDeleted > 0) SaveEntity(iType);
	client_print_color(id, print_team_blue, "^1[^4INFO^1] С карты было удалено %i(х) ^4%s", iDeleted, iType == 1 ? "Медведей":"Ёлок");
	return PLUGIN_HANDLED;
}

SaveEntity(iType) {
	switch(iType) {
		case 1: if(file_exists(g_szConfigFileBear)) delete_file(g_szConfigFileBear);
		case 2: if(file_exists(g_szConfigFileTree)) delete_file(g_szConfigFileTree);
	}
	new iFile;
	switch(iType) {
		case 1: {
			iFile = fopen(g_szConfigFileBear, "wt");
			fprintf(iFile, "%f %f %f", g_iBearCoord[0], g_iBearCoord[1], g_iBearCoord[2]);
		}
		case 2: {
			iFile = fopen(g_szConfigFileTree, "wt");
			if(!iFile) return;
			
			new Float:vOrigin[3], iEntity;
			while((iEntity = find_ent_by_class(iEntity, g_id_tree)) > 0) {
				get_entvar(iEntity, var_origin, vOrigin);			
				fprintf(iFile, "%f %f %f^n", vOrigin[0], vOrigin[1], vOrigin[2]);
			}
		}
	}
	fclose(iFile);
}

public Create_Gift(const Float:fOrigin[3]) {
	new iEntity = rg_create_entity("info_target", false); 			//Создаем объект info_target

	if(!pev_valid(iEntity)) return PLUGIN_HANDLED; 	//Заканчиваем. Дальше нам делать нечего

	set_entvar(iEntity, var_origin, fOrigin); 			//Присваиваем координаты
	set_entvar(iEntity, var_classname, g_id_gifts);
	set_entvar(iEntity, var_solid, SOLID_BBOX);
	set_entvar(iEntity, var_movetype, MOVETYPE_PUSHSTEP); 	//Не задаем тип движения, во всяком случаи пока
	set_entvar(iEntity, var_sequence, 0); 				//Выставляем № анимации при создании
	set_entvar(iEntity, var_framerate, 1.0); 			//Выставляем скорость анимации
	set_entvar(iEntity, var_nextthink, get_gametime() + 1.0); //Создаем запуск think

	engfunc(EngFunc_SetModel, iEntity, g_GiftsModels);
	engfunc(EngFunc_SetSize, iEntity, Float:{-20.0,-20.0,-5.0}, Float:{5.0,10.0,10.0});
	
	return PLUGIN_HANDLED;
}

public TouchGifts(iEntity, id) {
	if(g_FixFloodChanel[id]) return PLUGIN_HANDLED;

	g_FixFloodChanel[id] = true;
	set_task(1.0, "FixFloodChanel", id + 341);

	if(g_iBlock_Gifts[id] == 5) {
		user_slap(id, 0);
		client_print_color(id, print_team_red, "^1[^4INFO^1] Вы уже брали^4 5/5 ^3подарков^1.");
		return PLUGIN_HANDLED;
	}
	remove_entity(iEntity);	
	g_iBlock_Gifts[id]++;

	switch(jbe_get_user_team(id)) {
		case 1: {
			new iRandom[3];
			for(new i; i <= 2; i++) iRandom[i] = random_num(1, 3);
			_set_user_gift(id, iRandom[0], 0);
			jbe_set_user_exp_rank(id, iRandom[1], 0);
			jbe_set_user_money(id, jbe_get_user_money(id) + iRandom[2] * 10, true);
			client_print_color(id, print_team_blue, "^1[^4INFO^1] Вы подобрали подарок [^3%d/5^1], а там:^4 %d Снежинок^1, ^4%d опыта^1 и ^4%d$", g_iBlock_Gifts[id], iRandom[0], iRandom[1], iRandom[2] * 10);
		}
		case 2: {
			_set_user_gift(id, 1, 0);
			jbe_set_user_exp_rank(id, 1, 0);
			jbe_set_user_money(id, jbe_get_user_money(id) + 30, true);
			client_print_color(id, print_team_blue, "^1[^4INFO^1] Вы подобрали подарок [^3%d/5^1], а там:^4 1 Снежинка^1,^4 1 опыт^1 и^4 30$", g_iBlock_Gifts[id]);
		}
	}
	return PLUGIN_HANDLED;
}

public FixFloodChanel(id) {
	id -= 341;
	if(is_user_connected(id)) g_FixFloodChanel[id] = false;
}

public TouchBear(iEntity, pPlayer) {
	if(!(get_entvar(pPlayer, var_button) & IN_USE) || g_FixFloodChanel[pPlayer]) return PLUGIN_HANDLED;
	g_FixFloodChanel[pPlayer] = true;
	set_task(1.0, "FixFloodChanel", pPlayer + 341);
	Show_BonusMenu(pPlayer);
	return PLUGIN_HANDLED;
}

public Player_Killed(iVictim, iAttacker, iGib) {
	if(!iAttacker || !is_user_connected(iVictim) || !is_user_connected(iAttacker)) return HC_CONTINUE;

	new iOrigin[3]; 	
	get_user_origin(iVictim, iOrigin); 

	new Float: fOrigin[3]; 				
	IVecFVec(iOrigin, fOrigin); 
	
	fOrigin[2] = fOrigin[2] + 20.0;
	return Create_Gift(fOrigin);
}

public ClearGifts(iEntity, iEnt) if(pev_valid(iEntity)) remove_entity(iEntity);

public Show_BonusMenu(id) {
	jbe_informer_offset_up(id);
	CreateMenu("\r[New Year] \yНовогодний Медведь^n\r[New Year] \wУ Вас: \y%d снежинок^n^n", g_iGifts[id]);
	
	if(g_iGifts[id] >= COST_1) {
		FormatMenu("\y[1] \r~ \wКупить \rHOOK \wна карту\R\w%d *^n", COST_1);
		cK(1);
	}
	else FormatMenu("\y[1] \r~ \d[No $] Купить HOOK на карту\R\w%d *^n", COST_1);
	
	if(g_iGifts[id] >= COST_2) {
		FormatMenu("\y[2] \r~ \wКупить \rVIP \wна карту\R\w%d *^n", COST_2);
		cK(2);
	}
	else FormatMenu("\y[2] \r~ \d[No $] Купить VIP на карту\R\w%d *^n", COST_2);
	
	if(g_iGifts[id] >= COST_3) {
		FormatMenu("\y[3] \r~ \wКупить \r100 exp & 1000 money\R\w%d *^n", COST_3);
		cK(3);
	}
	else FormatMenu("\y[3] \r~ \d[No $] Купить 100 exp & 1000\R\w%d *^n", COST_3);
	
	if(g_iGifts[id] >= COST_4) {
		FormatMenu("\y[4] \r~ \wПоздравить всех с Праздником!\R\w%d *^n^n", COST_4);
		cK(4);
	}
	else FormatMenu("\y[4] \r~ \d[No $] Поздравить всех с Праздником!\R\w%d *^n^n", COST_4);
	
	FormatMenu("\y[0] \r~ \w Выход");
	return ShowMenu("Show_BonusMenu");
}

public Handle_BonusMenu(id, iKey) {
	new iName[32]; 
	get_user_name(id, iName, charsmax(iName));
	if(iKey != 9) client_cmd(id, "mp3 play sound/egoist/jb/other/happy.mp3");
	switch(iKey) {
		case 0: {
			_set_user_gift(id, COST_1, 3);
			jbe_setbit_hook(id);
			client_print_color(0, print_team_blue, "^1[^4INFO^1] Игрок^4 %s ^1купил подарок: ^4Hook на карту", iName);
		}
		case 1: {
			_set_user_gift(id, COST_2, 3);
			jbe_setbit_vip(id);
			client_print_color(0, print_team_blue, "^1[^4INFO^1] Игрок^4 %s ^1купил подарок: ^4VIP на карту", iName);
		}
		case 2: {
			_set_user_gift(id, COST_3, 3);
			jbe_set_user_exp_rank(id, 100, 0);
			jbe_set_user_money(id, jbe_get_user_money(id) + 1000, true);
			client_print_color(0, print_team_blue, "^1[^4INFO^1] Игрок^4 %s ^1купил подарок:^4 100 опыта ^1и^4 $1000", iName);
		}
		case 3: {
			_set_user_gift(id, COST_4, 3);
			new Float:orig[3];
			for(new idx = 1; idx <= MaxClients; idx++) {
				jbe_set_user_exp_rank(idx, 50, 0);
				jbe_set_user_money(idx, jbe_get_user_money(idx) + 500, true);
				client_print_color(idx, print_team_blue, "^1[^4INFO^1] Игрок^4 %s ^1поздравил Вас с праздником и вручил:^4 50 опыта ^1и^4 $500", iName);
				get_entvar(idx, var_origin, orig);
				client_cmd(idx, "spk egoist/jb/other/new_year.wav");
				client_cmd(idx, "mp3 play sound/egoist/jb/other/happy.mp3");
				CREATE_SPRITETRAIL(orig, sp_Ball, 10, 10, 3, 20, 10);
			}
		}
		case 9: return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}

public client_putinserver(id) set_task(1.0, "_load_player_gift", id + 1312);

public SQL_Handler(iFailState, Handle:sqlQuery, const szError[], iError, const szData[], iDataSize) {
	switch(iFailState) {
		case TQUERY_CONNECT_FAILED: {
			log_amx("[GIFT] MySQL connection failed");
			log_amx("[ %d ] %s", iError, szError);
			if(iDataSize) log_amx("Query state: %d", szData[0]);
			return PLUGIN_HANDLED;
		}
		case TQUERY_QUERY_FAILED: {
			log_amx("[GIFT] MySQL query failed");
			log_amx("[ %d ] %s", iError, szError);
			if(iDataSize) log_amx("Query state: %d", szData[1]);
			return PLUGIN_HANDLED;
		}
	}
	switch(szData[0]) {
		case SQL_CHECK: {
			new id = szData[1];
			if(!is_user_connected(id)) return PLUGIN_HANDLED;
			switch(SQL_NumResults(sqlQuery)) {
				case 0: {
					new szName[32], szQuery[128], szDataNew[2];
					get_user_name(id, szName, charsmax(szName));
					replace_all(szName, charsmax(szName), "'", "");
					formatex(szQuery, charsmax(szQuery), "INSERT INTO `%s`(`authId`, `exp`) VALUES ('%s', '0')", g_szGiftTable, szName);
					szDataNew[0] = SQL_IGNORE;
					szDataNew[1] = id;
					SQL_ThreadQuery(g_sqlTuple, "SQL_Handler", szQuery, szDataNew, sizeof szDataNew);
				}
				default: {
					new szName[32], szQuery[128], szDataNew[2];
					get_user_name(id, szName, charsmax(szName));
					replace_all(szName, charsmax(szName), "'", "");
					formatex(szQuery, charsmax(szQuery),"SELECT `exp` FROM `%s` WHERE `authId` = '%s'", g_szGiftTable, szName);
					szDataNew[0] = SQL_LOAD;
					szDataNew[1] = id;
					SQL_ThreadQuery(g_sqlTuple, "SQL_Handler", szQuery, szDataNew, sizeof szDataNew);
				}
			}
		}
		case SQL_LOAD: {
			new id = szData[1];
			if(!is_user_connected(id)) return PLUGIN_HANDLED;
			new iGift = SQL_ReadResult(sqlQuery, 0);
			_set_user_gift(id, iGift, 1);
		}
	}
	return PLUGIN_HANDLED;
}

public _set_user_gift(id, iGift, iType) {
	switch(iType) {
		case 1: g_iGifts[id] = iGift;
		case 3: g_iGifts[id] -= iGift;
		case 0: g_iGifts[id] += iGift;
	}
	new szName[32], szQuery[128], szData[2];
	get_user_name(id, szName, charsmax(szName));
	replace_all(szName, charsmax(szName), "'", "");
	formatex(szQuery, charsmax(szQuery), "UPDATE `%s` SET `exp`='%d' WHERE `authId` = '%s';", g_szGiftTable, g_iGifts[id], szName);
	szData[0] = SQL_IGNORE;
	szData[1] = id;
	SQL_ThreadQuery(g_sqlTuple, "SQL_Handler", szQuery, szData, sizeof szData);
}

public default_set_user_gift(id, iNum) {
	g_iGifts[id] = iNum;
	new szName[32], szQuery[128], szData[2];
	get_user_name(id, szName, charsmax(szName));
	replace_all(szName, charsmax(szName), "'", "");
	formatex(szQuery, charsmax(szQuery), "UPDATE `%s` SET `exp`='%d' WHERE `authId` = '%s';", g_szGiftTable, g_iGifts[id], szName);
	szData[0] = SQL_IGNORE;
	szData[1] = id;
	SQL_ThreadQuery(g_sqlTuple, "SQL_Handler", szQuery, szData, sizeof szData);
}

public _get_user_gift(id) return g_iGifts[id];

public _load_player_gift(pPlayer) {
	pPlayer -= 1312;
	new szName[32], szQuery[128], szData[2];
	get_user_name(pPlayer, szName, charsmax(szName));
	replace_all(szName, charsmax(szName), "'", "");
	formatex(szQuery, charsmax(szQuery), "SELECT * FROM `%s` WHERE `authId` = '%s'", g_szGiftTable, szName);
	szData[0] = SQL_CHECK;
	szData[1] = pPlayer;
	SQL_ThreadQuery(g_sqlTuple, "SQL_Handler", szQuery, szData, sizeof szData);
}

stock CREATE_SPRITETRAIL(Float:vecOrigin[3], pSprite, iCount, iLife, iScale, iVelocityAlongVector, iRandomVelocity) {
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_SPRITETRAIL);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]); // start
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]); // end
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(pSprite);
	write_byte(iCount);
	write_byte(iLife); // 0.1's
	write_byte(iScale);
	write_byte(iVelocityAlongVector);
	write_byte(iRandomVelocity);
	message_end(); 
}