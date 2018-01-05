#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <jbe_core>
#include <hamsandwich>
#include <reapi>

#define PLUGIN 							"[UJBL] Grab"
#define VERSION							"3.0"
#define AUTHOR							"ToJI9IHGaa & Xify"

#define GRABBED 		0
#define GRABBER 		1
#define GRAB_LEN		2
#define FLAGS 			3

stock close_menu_player(id) show_menu(id, 0, "^n", 1);

new client_data[33][4];
new p_throw_force, p_min_dist, p_speed, p_grab_force;
new speed_off[33];
new sp_Ball;
new bool:g_Freez[33], iPlayerType[33][2];

public plugin_precache() {
	sp_Ball = precache_model("sprites/egoist/jb/ball_mini.spr");
	
	precache_sound("egoist/jb/other/ujbl_grab_target.wav");
	precache_sound("egoist/jb/other/ujbl_grab_id.wav");
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	p_min_dist = register_cvar ("gp_min_dist", "90");
	p_throw_force = register_cvar("gp_throw_force", "1500");
	p_grab_force = register_cvar("gp_grab_force", "8");
	p_speed = register_cvar("gp_speed", "5");
	
	register_clcmd("amx_grab", "force_grab")
	register_clcmd("+grab", "grab")
	register_clcmd("-grab", "unset_grabbed")
	register_clcmd("+push", "push")
	register_clcmd("-push", "push")
	register_clcmd("+pull", "pull")
	register_clcmd("-pull", "pull")
	register_clcmd("push", "push2")
	register_clcmd("pull", "pull2")
	
	register_menu("grab_menu", (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_GrabMenu")
	register_clcmd("drop", "throw")
	register_event("DeathMsg", "DeathMsg", "a")
	register_forward(FM_PlayerPreThink, "fm_player_prethink")
}

public fm_player_prethink(id) {
	new target;
	if(client_data[id][GRABBED] == -1) {
		new Float:orig[3], Float:ret[3];
		get_view_pos(id, orig);
		ret = vel_by_aim(id, 9999);
		
		ret[0] += orig[0];
		ret[1] += orig[1];
		ret[2] += orig[2];
		
		target = traceline(orig, ret, id, ret);
		
		if(0 < target <= MaxClients) {
			if(is_grabbed(target, id)) return FMRES_IGNORED;
			set_grabbed(id, target);
		}
	}
	
	target = client_data[id][GRABBED];

	if(target > 0) {
		if(!pev_valid(target) || (get_entvar(target, var_health) < 1 && get_entvar(target, var_max_health))) {
			unset_grabbed(id);
			return FMRES_IGNORED;
		}
		
		//Push and pull
		new cdf = client_data[id][FLAGS];
		if(cdf & (1<<1)) do_pull(id);
		else if(cdf & (1<<0)) do_push(id);
		
		if(target > MaxClients) grab_think(id);
	}
	
	//If they're grabbed
	target = client_data[id][GRABBER];
	if(target > 0) grab_think(target);
	
	return FMRES_IGNORED;
}

public grab_think(id) {
	new target = client_data[id][GRABBED];
	
	//Keep grabbed clients from sticking to ladders
	if(get_entvar(target, var_movetype) == MOVETYPE_FLY && !(get_entvar(target, var_button) & IN_JUMP)) client_cmd(target, "+jump;wait;-jump");
	
	//Move targeted client
	new Float:tmpvec[3], Float:tmpvec2[3], Float:torig[3], Float:tvel[3];
	get_view_pos(id, tmpvec);
	
	tmpvec2 = vel_by_aim(id, client_data[id][GRAB_LEN]);
	torig = get_target_origin_f(target);
	
	new force = get_pcvar_num(p_grab_force);
	
	tvel[0] = ((tmpvec[0] + tmpvec2[0]) - torig[0]) * force;
	tvel[1] = ((tmpvec[1] + tmpvec2[1]) - torig[1]) * force;
	tvel[2] = ((tmpvec[2] + tmpvec2[2] ) - torig[2]) * force;
	
	set_entvar(target, var_velocity, tvel);
}

stock Float:get_target_origin_f(id) {
	new Float:orig[3];
	get_entvar(id, var_origin, orig);
	
	//If grabbed is not a player, move origin to center
	if(id > MaxClients) {
		new Float:mins[3], Float:maxs[3];
		get_entvar(id, var_mins, mins);
		get_entvar(id, var_maxs, maxs);
		
		if(!mins[2]) orig[2] += maxs[2] / 2;
	}
	
	return orig;
}

public grab(id) {
	if(!(get_user_flags(id) & ADMIN_LEVEL_H) || jbe_get_day() == 0 || jbe_get_day_mode() == 3 || !is_user_alive(id) || jbe_all_users_wanted() 
	|| jbe_get_status_duel() == (2|1)) return PLUGIN_HANDLED;
	
	if(!client_data[id][GRABBED]) client_data[id][GRABBED] = -1;
	
	return PLUGIN_HANDLED;
}

public grab_menu(id, iType) {
	jbe_informer_offset_up(id);
	new tg = client_data[id][GRABBED];
	iPlayerType[id][0] = iType;
	
	new szMenu[1024], iLen, iKeys;
	if(iType == 1) {
		iKeys = (1<<0|1<<1|1<<2|1<<5|1<<6|1<<7|1<<8|1<<9) 
		new name[32];
		get_user_name(tg, name, charsmax(name));
		iLen = formatex(szMenu[iLen], charsmax(szMenu) - iLen, "Вы взяли: \r%s^n\wЖизни: \r%d \d|\w Броня: \r%d^n\wДеньги: \r%d \d|\w Команда: \r%s^n^n", 
		name, Float:rg_get_user_health(tg), rg_get_user_armor(tg), jbe_get_user_money(tg), jbe_get_user_team(tg) == 2 ? "Охранник":"Зэк");
		
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[1]\w Перевести за \r%s^n", jbe_get_user_team(tg) == 1 ? "Зеков":"Охрану");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[2]\w Убить^n");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[3]\r %s^n^n", !g_Freez[tg] ? "Заморозить":"Разморозить");
		
		if(get_user_flags(id) & ADMIN_RESERVATION) {
			switch(jbe_get_user_team(tg)) {
				case 1: {
					iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[4]\r %s\w розыск^n", jbe_is_user_wanted(tg) ? "Забрать" : "Дать");
					iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[5]\r %s\w отдых^n^n", jbe_is_user_free(tg) ? "Забрать" : "Дать");
				}
				default: {
					iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[4]\r %s\w Бесмертие^n", rg_get_user_takedamage(tg) ? "Забрать" : "Дать");
					iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[5]\r %s\w Режим Призрака^n^n", rg_get_user_noclip(tg) ? "Забрать" : "Дать");
				}
			}
			iKeys |= (1<<3|1<<4)
		}
		else {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[4]\d Мало Полномочий [Для GOLD]^n");
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[5]\d Мало Полномочий [Для GOLD]^n^n");
		}
		
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[6]\w Закрутить Экран^n^n");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[7]\r Притянуть^n");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[8]\r Отблизить^n^n");
	}
	else {
		iKeys = (1<<0|1<<1|1<<9);
		iLen = formatex(szMenu[iLen], charsmax(szMenu) - iLen, "Вы взяли: \rОружие^n^n");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[1]\r Притянуть^n");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[2]\r Отблизить^n^n");
	}	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\y[0]\w Выход^n^n");
	show_menu(id, iKeys, szMenu, -1, "grab_menu");	
}

public Handle_GrabMenu(id, iKey) {
	new tg = client_data[id][GRABBED]
	new pName[32], tName[32]
	get_user_name(id, pName, charsmax(tName));
	get_user_name(tg, tName, charsmax(tName));
	if(iPlayerType[id][0] == 1) if(!is_user_alive(tg) || !is_user_connected(tg)) return PLUGIN_HANDLED;
	
	switch(iKey) {
		case 0: {
			switch(iPlayerType[id][0]) {
				case 1: {
					switch(jbe_get_user_team(tg)) {
						case 1: {
							jbe_set_user_team(tg, 2);
							client_print_color(0, print_team_blue, "^1[^4INFO^1] Администратор ^4%s^1 перевёл ^4%s^1 за ^4Охранников", pName, tName);
						}
						default: {
							jbe_set_user_team(tg, 1);
							client_print_color(0, print_team_blue, "^1[^4INFO^1] Администратор ^4%s^1 перевёл ^4%s^1 за ^4Заключенных", pName, tName);
						}
					}
				}
				case 0: {
					client_cmd(id, "+pull");
					iPlayerType[id][1] = 1;
					set_task(0.4, "UnPullPushTask", id + 9876);
					grab_menu(id, 0); 
				}
			}
		}
		case 1: {
			switch(iPlayerType[id][0]) {
				case 1: user_kill(tg);
				case 0: {
					client_cmd(id, "+push");
					iPlayerType[id][1] = 2;
					set_task(0.4, "UnPullPushTask", id + 9876);
					grab_menu(id, 0); 
				}
				
			}
		}
		case 2: {
			switch(g_Freez[tg]) {
				case false: {
					rg_set_user_freeze(tg, true);
					client_print_color(0, print_team_blue, "^1[^4INFO^1] Администратор ^4%s^1 заморозил ^4%s^1", pName, tName);
					g_Freez[tg] = true;
				}
				case true: {
					rg_set_user_freeze(tg, false);
					client_print_color(0, print_team_blue, "^1[^4INFO^1] Администратор ^4%s^1 разморозил ^4%s^1", pName, tName);
					g_Freez[tg] = false;
				}
			}
		}
		case 3: {
			switch(jbe_get_user_team(tg)) {
				case 1: {
					if(jbe_is_user_wanted(tg)) {
						jbe_sub_user_wanted(tg)
						client_print_color(0, print_team_blue, "^1[^4INFO^1] Администратор ^4%s^1 забрал розыск у ^4%s^1", pName, tName);
					}
					else {
						jbe_add_user_wanted(tg);
						client_print_color(0, print_team_blue, "^1[^4INFO^1] Администратор ^4%s^1 дал розыск ^4%s^1", pName, tName);
					}
				}
				default: {
					if(!rg_get_user_takedamage(tg)) {
						rg_set_user_takedamage(tg, true);
						client_print_color(0, print_team_blue, "^1[^4INFO^1] Администратор ^4%s^1 дал GodMode ^4%s^1", pName, tName);
					}
					else {
						rg_set_user_takedamage(tg, false);
						client_print_color(0, print_team_blue, "^1[^4INFO^1] Администратор ^4%s^1 забрал GodMode у ^4%s^1", pName, tName);
					}
				}
			}
		}
		case 4: {
			switch(jbe_get_user_team(tg)) {
				case 1: {
					if(jbe_is_user_free(tg)) {
						jbe_sub_user_free(tg)
						client_print_color(0, print_team_blue, "^1[^4INFO^1] Администратор ^4%s^1 забрал выходной у ^4%s^1", pName, tName);
					}
					else {
						jbe_add_user_free(tg);
						client_print_color(0, print_team_blue, "^1[^4INFO^1] Администратор ^4%s^1 дал выходной ^4%s^1", pName, tName);
					}
				}
				default: {
					if(rg_get_user_noclip(tg)) {
						rg_set_user_noclip(tg, false);
						client_print_color(0, print_team_blue, "^1[^4INFO^1] Администратор ^4%s^1 забрал NoClip у ^4%s^1", pName, tName);
					}
					else {
						rg_set_user_noclip(tg, true);
						client_print_color(0, print_team_blue, "^1[^4INFO^1] Администратор ^4%s^1 дал NoClip ^4%s^1", pName, tName);
					}
				}
			}
		}
		case 5: {
			set_entvar(tg, var_punchangle, { 400.0, 999.0, 400.0 });
			client_print_color(0, print_team_blue, "^1[^4INFO^1] Администратор ^4%s^1 закрутил экран ^4%s^1", pName, tName);
		}
		case 6: {
			client_cmd(id, "+pull");
			iPlayerType[id][1] = 1;
			set_task(0.4, "UnPullPushTask", id + 9876);
			grab_menu(id, 1); 
		}
		case 7: {
			client_cmd(id, "+push");
			iPlayerType[id][1] = 2;
			set_task(0.4, "UnPullPushTask", id + 9876);
			grab_menu(id, 1); 
		}
		case 8: return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}

public UnPullPushTask(id) {
	id -= 9876;
	switch(iPlayerType[id][1]) {
		case 1: client_cmd(id, "-pull");
		case 2: client_cmd(id, "-push");
	}
}

public throw(id) {
	new target = client_data[id][GRABBED];
	if(target > 0) {
		set_entvar(target, var_velocity, vel_by_aim(id, get_pcvar_num(p_throw_force)));
		unset_grabbed(id);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public unset_grabbed(id) {
	new target = client_data[id][GRABBED];
	if(target > 0 && pev_valid(target)) {
		if(task_exists(target + 9141)) remove_task(target + 9141); 
		if(!jbe_is_user_wanted(target) && !jbe_is_user_free(target)) {
			set_entvar(target, var_renderfx, kRenderFxNone);
			set_entvar(target, var_rendercolor, {0.0, 0.0, 0.0});
			set_entvar(target, var_rendermode, kRenderNormal);
			set_entvar(target, var_renderamt, 16.0);
		}
		
		if(0 < target <= MaxClients) client_data[target][GRABBER] = 0;
	}
	close_menu_player(id);
	client_data[id][GRABBED] = 0;
}

public set_grabbed(id, target) {
	if(!jbe_is_user_wanted(target) && !jbe_is_user_free(target) && pev_valid(target)) {
		rg_set_user_rendering(id, kRenderFxGlowShell, random_num(0,255), random_num(0,255), random_num(0,255), kRenderNormal, 4);
		set_task(0.4, "Task_RandomGlow", target + 9141, _, _, "b");
	}
	if(0 < target <= MaxClients) client_data[target][GRABBER] = id;
	client_data[id][FLAGS] = 0;
	client_data[id][GRABBED] = target;
	new name[33], name2[33];
	get_user_name(id, name, 32);
	get_user_name(target, name2, 32);
	client_print_color(target, print_team_blue, "^1[^4INFO^1] Администратор ^4%s ^1взял Вас ^4грабом", name);
	client_print_color(id, print_team_blue, "^1[^4INFO^1] Вы взяли грабом ^4%s", name2);
	grab_menu(id, 1);
	rh_emit_sound2(id, 0, CHAN_AUTO, "egoist/jb/other/ujbl_grab_id.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	rh_emit_sound2(id, target, CHAN_AUTO, "egoist/jb/other/ujbl_grab_target.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	new Float:torig[3], Float:orig[3];
	get_entvar(target, var_origin, torig);
	get_entvar(id, var_origin, orig);
	CREATE_SPRITETRAIL(torig, sp_Ball, 10, 10, 1, 20, 10);
	client_data[id][GRAB_LEN] = floatround(get_distance_f(torig, orig));
	if(client_data[id][GRAB_LEN] < get_pcvar_num(p_min_dist)) client_data[id][GRAB_LEN] = get_pcvar_num(p_min_dist);
}

public Task_RandomGlow(id) {
	id -= 9141;
	if(!jbe_is_user_wanted(id) && !jbe_is_user_free(id) && id > 0 && pev_valid(id)) rg_set_user_rendering(id, kRenderFxGlowShell, random_num(0,255), random_num(0,255), random_num(0,255), kRenderNormal, 4);
	else remove_task(id + 9141);
}

public push(id) {
	client_data[id][FLAGS] ^= (1<<0);
	return PLUGIN_HANDLED;
}

public pull(id) {
	client_data[id][FLAGS] ^= (1<<1);
	return PLUGIN_HANDLED;
}

public push2(id) {
	if(client_data[id][GRABBED] > 0) {
		do_push(id);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public pull2(id) {
	if(client_data[id][GRABBED] > 0) {
		do_pull(id);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public do_push(id) if(client_data[id][GRAB_LEN] < 9999) client_data[id][GRAB_LEN] += get_pcvar_num(p_speed);

public do_pull(id) {
	new mindist = get_pcvar_num(p_min_dist);
	new len = client_data[id][GRAB_LEN];
	
	if(len > mindist) {
		len -= get_pcvar_num(p_speed);
		if(len < mindist) len = mindist;
		client_data[id][GRAB_LEN] = len;
	}
}

//Grabs the client and teleports them to the admin
public force_grab(id) {
	if(!(get_user_flags(id) & ADMIN_BAN)) return PLUGIN_HANDLED;

	new arg[33];
	read_argv(1, arg, 32);

	new targetid = cmd_target(id, arg, 1);
	
	if(is_grabbed(targetid, id)) return PLUGIN_HANDLED;
	if(!is_user_alive(targetid)) return PLUGIN_HANDLED;

	new Float:tmpvec[3], Float:orig[3], Float:torig[3], Float:trace_ret[3];
	new bool:safe = false, i;
	
	get_view_pos(id, orig);
	tmpvec = vel_by_aim(id, get_pcvar_num(p_min_dist));
	
	for(new j = 1; j < 11 && !safe; j++) {
		torig[0] = orig[0] + tmpvec[i] * j;
		torig[1] = orig[1] + tmpvec[i] * j;
		torig[2] = orig[2] + tmpvec[i] * j;
		
		traceline(tmpvec, torig, id, trace_ret);
		
		if(get_distance_f(trace_ret, torig)) break;		
		engfunc(EngFunc_TraceHull, torig, torig, 0, HULL_HUMAN, 0, 0);
		if(!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen)) safe = true;
	}
	
	get_entvar(id, var_origin, orig);
	new try[3];
	orig[2] += 2;
	while(try[2] < 3 && !safe) {
		for(i = 0; i < 3; i++)
			switch(try[i]) {
				case 0: torig[i] = orig[i] + (i == 2 ? 80 : 40);
				case 1: torig[i] = orig[i];
				case 2: torig[i] = orig[i] - (i == 2 ? 80 : 40);
			}
		
		traceline(tmpvec, torig, id, trace_ret);
		
		engfunc(EngFunc_TraceHull, torig, torig, 0, HULL_HUMAN, 0, 0);
		if(!get_tr2( 0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen) && !get_distance_f(trace_ret, torig)) safe = true;
		
		try[0]++;
		if(try[0] == 3) {
			try[0] = 0;
			try[1]++;
			if(try[1] == 3) {
				try[1] = 0;
				try[2]++;
			}
		}
	}
	if(safe) {
		set_entvar(targetid, var_origin, torig);
		set_grabbed(id, targetid);
	}
	return PLUGIN_HANDLED;
}

public is_grabbed(target, grabber) {
	for(new id = 1; id <= MaxClients; id++) {
		if(client_data[id][GRABBED] == target) {
			unset_grabbed(grabber);
			return true;
		}
	}
	return false;
}

public DeathMsg() kill_grab(read_data(2));

public client_disconnected(id) {
	kill_grab(id);
	speed_off[id] = false;
	return PLUGIN_CONTINUE;
}

public kill_grab(id) {
	//If given client has grabbed, or has a grabber, unset it
	if(client_data[id][GRABBED]) unset_grabbed(id);
	else if(client_data[id][GRABBER]) unset_grabbed(client_data[id][GRABBER]);
}

stock traceline(const Float:vStart[3], const Float:vEnd[3], const pIgnore, Float:vHitPos[3]) {
	engfunc(EngFunc_TraceLine, vStart, vEnd, 0, pIgnore, 0);
	get_tr2(0, TR_vecEndPos, vHitPos);
	return get_tr2(0, TR_pHit);
}

stock get_view_pos(const id, Float:vViewPos[3]) {
	new Float:vOfs[3];
	get_entvar(id, var_origin, vViewPos);
	get_entvar(id, var_view_ofs, vOfs)	;	
	
	vViewPos[0] += vOfs[0];
	vViewPos[1] += vOfs[1];
	vViewPos[2] += vOfs[2];
}

stock Float:vel_by_aim(id, speed = 1) {
	new Float:v1[3], Float:vBlah[3];
	get_entvar(id, var_v_angle, v1);
	engfunc(EngFunc_AngleVectors, v1, v1, vBlah, vBlah);
	
	v1[0] *= speed;
	v1[1] *= speed;
	v1[2] *= speed;
	
	return v1;
}

stock CREATE_SPRITETRAIL(Float:vecOrigin[3], pSprite, iCount, iLife, iScale, iVelocityAlongVector, iRandomVelocity)
{
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

// Установка обводки вокруг игрока(энтити)
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

// Устанавливаем / убираем ноклип
stock rg_set_user_noclip(const player, bool:noclip = true) {
	set_entvar(player, var_movetype, noclip ? MOVETYPE_NOCLIP : MOVETYPE_WALK);
}

// Статус ноклип
stock bool:rg_get_user_noclip(const player) {
	return bool:(get_entvar(player, var_movetype) == MOVETYPE_NOCLIP);
}

// Установиливаем / убраем бессмертие 
stock rg_set_user_freeze(const player, bool:freeze = true) {
	if(freeze) set_entvar(player, var_flags, get_entvar(player, var_flags) | FL_FROZEN);
	else set_entvar(player, var_flags, get_entvar(player, var_flags) & ~FL_FROZEN);
}

// Установиливаем / убраем бессмертие 
stock rg_set_user_takedamage(const player, bool:take = true) {
	set_entvar(player, var_takedamage, take ? DAMAGE_NO : DAMAGE_AIM);
}

// Статус бессмертия
stock bool:rg_get_user_takedamage(const player) {
	return bool:(get_entvar(player, var_takedamage) == DAMAGE_NO);
}

stock Float:rg_get_user_health(const player) {
	return Float:get_entvar(player, var_health);
}