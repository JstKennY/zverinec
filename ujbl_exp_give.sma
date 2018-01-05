#include <amxmodx>

#define NEW_YEAR_UPDATE			1		// New Year обновление. 1 - есть, 0 - нету

#if NEW_YEAR_UPDATE == 1
native set_user_gift(id, num);
native get_user_gift(id);
#endif

native jbe_set_user_exp_rank(id, iExp, iType);

public plugin_init() {
	register_plugin("[UJBL] Exp Giver", "0.0.5", "ToJI9IHGaa");
	register_concmd("give_exp", "exp_give");
	#if NEW_YEAR_UPDATE == 1
	register_concmd("give_gift", "gift_give");
	#endif
}

public exp_give(id){
	if(get_user_flags(id) & ADMIN_MENU) {
		new Name[32], iNum[10], bool:iCheck;
		
		read_argv(1, Name, charsmax(Name));
		read_argv(2, iNum, charsmax(iNum));
		
		remove_quotes(Name);
		
		for(new i; i <= MaxClients; i++) {
			new iName[32]; get_user_name(i, iName, charsmax(iName));
			if(equali(iName, Name)) {
				iCheck = true;
				break;
			}
		}
		if(!iCheck) {
			client_print_color(id, print_team_blue, "^1[^4INFO^1] Указан неправильный ник игрока");
			return PLUGIN_HANDLED;
		}

		if(iNum[0] < 0) {
			client_print_color(id, print_team_blue, "^1[^4INFO^1] Отрицательное значение ^4невозможно");
			return PLUGIN_HANDLED;
		}

		if(strlen(iNum) == 0) {
			client_print_color(id, print_team_blue, "^1[^4INFO^1] Нужно указать количество ^4опыта!");
			return PLUGIN_HANDLED;
		}

		for(new x; x < strlen(iNum); x++) {
			if(!isdigit(iNum[x])) {
				client_print_color(id, print_team_blue, "^1[^4INFO^1] Количество ^4опыта ^1состоит только из числа!");
				return PLUGIN_HANDLED;
			}
		}

		new target = get_user_index(Name);
		new iAdmin[32]; get_user_name(id, iAdmin, charsmax(iAdmin));
		client_print_color(0, print_team_blue, "^1[^4INFO^1] Администратор^4 %s ^1выдал^4 %s^3 %d ^1опыта", iAdmin, Name, str_to_num(iNum));
		jbe_set_user_exp_rank(target, str_to_num(iNum), 0);
	}
	return PLUGIN_HANDLED;
}

#if NEW_YEAR_UPDATE == 1
public gift_give(id) {
	if(get_user_flags(id) & ADMIN_MENU) {
		new Name[32], iNum[10], bool:iCheck;
		read_argv(1, Name, charsmax(Name));
		read_argv(2, iNum, charsmax(iNum));
		
		remove_quotes(Name);
		
		for(new i; i <= MaxClients; i++) {
			new iName[32]; get_user_name(i, iName, charsmax(iName));
			if(equali(iName, Name)) {
				iCheck = true;
				break;
			}
		}

		if(!iCheck) {
			client_print_color(id, print_team_blue, "^1[^4INFO^1] Указан неправильный ник игрока");
			return PLUGIN_HANDLED;
		}

		if(iNum[0] < 0) {
			client_print_color(id, print_team_blue, "^1[^4INFO^1] Отрицательное значение ^4невозможно");
			return PLUGIN_HANDLED;
		}

		if(strlen(iNum) == 0) {
			client_print_color(id, print_team_blue, "^1[^4INFO^1] Нужно указать количество ^4снежков!");
			return PLUGIN_HANDLED;
		}

		for(new x; x < strlen(iNum); x++) {
			if(!isdigit(iNum[x])) {
				client_print_color(id, print_team_blue, "^1[^4INFO^1] Количество ^4снежков ^1состоит только из числа!");
				return PLUGIN_HANDLED;
			}
		}

		new target = get_user_index(Name);
		new iAdmin[32]; get_user_name(id, iAdmin, charsmax(iAdmin));
		client_print_color(0, print_team_blue, "^1[^4INFO^1] Администратор^4 %s ^1выдал^4 %s^3 %d ^1снежков", iAdmin, Name, str_to_num(iNum));
		set_user_gift(target, get_user_gift(target) + str_to_num(iNum));
	}
	return PLUGIN_HANDLED;
}
#endif