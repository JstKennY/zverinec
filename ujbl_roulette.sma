#include <amxmodx>
#include <old_menu>
#include <jbe_core>
#include <reapi>

#define is_user_admin(%1) (~jbe_get_privileges_flags(%1) & FLAGS_NONE)

new Float: g_fRouletteCoolDown[33][2], g_iTicketNum[33], g_iSyncObjInformer;

#define COOL_DOWN_ONE 560.0
#define COOL_DOWN_TWO 350.0

#define ForseTime(%1,%2,%3) (COOL_DOWN_ONE - (get_gametime() - g_fRouletteCoolDown[%1][%2]))
public plugin_natives() register_native("jbe_open_fortune_menu", "Show_RouletteMenu", 1);

public plugin_init() {
	register_plugin("[UJBL] Roulette", "0.0.1", "ToJI9IHGaa");
	register_menucmd(register_menuid("Show_RouletteMenu"), (1<<0|1<<1|1<<2|1<<9), "Handle_RouletteMenu");
	g_iSyncObjInformer = CreateHudSyncObj();
}

public client_putinserver(id) {
	g_fRouletteCoolDown[id][0] = get_gametime();
	g_fRouletteCoolDown[id][1] = get_gametime();
	g_iTicketNum[id] = 0;
}

public Show_RouletteMenu(id) {
	jbe_informer_offset_up(id);
	
	new Float: fTime = ForseTime(id, 0, COOL_DOWN_ONE);
	if(!fTime && g_iTicketNum[id] <= 4) {
		g_iTicketNum[id]++;
		g_fRouletteCoolDown[id][0] = get_gametime();
	}
	
	CreateMenu("\y^t^tРулетка^nБилетов: \r%d|5^n\yВремя до следуйщего билета: \r[%d s.]^n^n", g_iTicketNum[id], floatround(fTime < 0.0 ? 0.0 : fTime));
	if(g_iTicketNum[id] > 0) {
		FormatMenu("\r(1)\y | \wОткрыть пандору^n");
		iKeys |= (1<<0);
	}
	else FormatMenu("\r(1)\y | \dОткрыть пандору \r[Недостаточно билетов]^n");
	
	if(is_user_admin(id)) {
		if(g_iTicketNum[id] < 5) {
			fTime = ForseTime(id, 1, COOL_DOWN_TWO);
			if(fTime < 0) {
				FormatMenu("\r(2)\y | \wAdmin Free Tickets^n");
				iKeys |= (1<<1);
			}
			else FormatMenu("\r(2)\y | \dAdmin Free Tickets \r[wait %d s.]^n", floatround(fTime));
		}
		else FormatMenu("\r(2)\y | \dAdmin Free Tickets \r[у Вас max билетов]^n");
	}
	else FormatMenu("\r(2)\y | \dAdmin Free Tickets \r[No Privileges]^n");
	
	if(get_member(id, m_iAccount) >= 200)
	{
		FormatMenu("\r(3)\y | \wКупить +1 билет \r[200$]^n");
		iKeys |= (1<<2);
	}
	else FormatMenu("\r(3)\y | \dКупить +1 билет \r[200$]^n");
	FormatMenu("^n\r(0)\y | \wВыход");
	return ShowMenu("Show_RouletteMenu");
}

public Handle_RouletteMenu(id, iKey) {
	switch(iKey) {
		case 0:  {
			g_iTicketNum[id]--;
			return RoulettePush(id);
		}
		case 1: {
			g_fRouletteCoolDown[id][1] = get_gametime();
			g_iTicketNum[id]++;
		}
		case 2: {
			jbe_set_user_money(id, jbe_get_user_money(id) - 200, true);
			g_iTicketNum[id]++;
		}
		case 9: return PLUGIN_HANDLED;
	}
	return Show_RouletteMenu(id);
}

new const g_szWiners[][] = { "100$", "5 опыта", "Выходной", "Дробовик [3 пт.]", "Билеты [2 шт.]", "Билеты [2 шт.]", "Билеты [2 шт.]", 
"Билет", "Билет", "Билет", "Билет", "Гравитацию", "Гравитацию", "Гравитацию", "Здоровье", "Здоровье", "Здоровье", "500$", 
"Дигл [12 пт.]", "Бронь", "Бронь", "Бронь", "Ничего"};

RoulettePush(id) {
	new iRandom = random_num(0, 25);
	switch(iRandom) {
		case 0: jbe_set_user_money(id, jbe_get_user_money(id) + 150, true);
		case 1: jbe_set_user_exp_rank(id, 5, 0);
		case 2: {
			if(!jbe_is_user_free(id)) {		
				set_hudmessage(102, 69, 0, -1.0, 0.16, 0, 0.0, 5.9, 0.1, 0.1, -1);
					
				new szName[32];
				get_user_name(id, szName, charsmax(szName));
				ShowSyncHudMsg(0, g_iSyncObjInformer, "Игрок %s^nВыбил с рулетки:^n[ FREE DAY ]", szName);
			
				jbe_add_user_free(id); 
				return PLUGIN_HANDLED;
			}
			else return RoulettePush(id);
		}
		case 3: set_member(rg_give_item(id, "weapon_m3", GT_REPLACE), m_Weapon_iClip, 3);
		case 4..6: g_iTicketNum[id] += 2;
		case 7..10: g_iTicketNum[id]++;
		case 11..13: {
			if(Float:rg_get_user_gravity(id) <= 0.6) return RoulettePush(id);
			rg_set_user_gravity(id, 0.6);
		}
		case 14..16: {
			if(Float:rg_get_user_health(id) <= 200.0) return RoulettePush(id);
			rg_set_user_health(id, 200.0);
		}
		case 17: jbe_set_user_money(id, jbe_get_user_money(id) + 500, true);
		case 18: set_member(rg_give_item(id, "weapon_deagle", GT_REPLACE), m_Weapon_iClip, 3);
		case 19..21: {
			if(rg_get_user_armor(id) <= 200) return RoulettePush(id);
			rg_set_user_armor(id, 200, ARMOR_KEVLAR);
		}
	}
	
	set_hudmessage(102, 69, 0, -1.0, 0.16, 0, 0.0, 5.9, 0.1, 0.1, -1);
	ShowSyncHudMsg(id, g_iSyncObjInformer, "Вы выбили с рулетки:^n[ %s ]", g_szWiners[(iRandom > 21 ? 21 : iRandom)]);
	
	return PLUGIN_HANDLED;	
}

stock Float:rg_get_user_gravity(const player) return Float:get_entvar(player, var_gravity);
stock rg_set_user_gravity(const player, Float:gravity = 1.0) set_entvar(player, var_gravity, Float:gravity);

stock Float:rg_get_user_health(const player) return Float:get_entvar(player, var_health);
stock rg_set_user_health(const player, Float:health) set_entvar(player, var_health, Float:health);