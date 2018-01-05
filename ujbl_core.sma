#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <sqlx>
#include <reapi>

#pragma semicolon 1 

// Слова в нике (если они будут найдены) которые запрещает вход за Охранников.
#define BLOCK_DEFAULT_NICK		"player", "GS-M", "unnamed", "unamed", "CS-", "CS_", "-MS", "Strikes", "boost", "-CS", ".ru", ".com", ".net"

// Через сколько секунд у игрока будет обновляется информер? (чем больше - тем меньше переполнение канала)
#define INFORMER_SECOND_UPDATE 1.0 // Чтобы информер правильно показывал секунды, рекомендую ставить '1.0' - обновлять раз в секунду.

// Через сколько секунд игрок может опять открыть меню при касании? (чем больше - тем меньше переполнение канала)
#define TOUCH_ENTITY_RELOAD 1.5	// Стандарт - '1.0'

// Дистанция для клеток.
#define R_DOOR 400.0

/**  - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = */

native jbe_open_fortune_menu(id);		//	Открытие меню: Меню пандорки

native ujbl_get_protection_skills(id);	// 	Возрат защиты **
native ujbl_get_agility_skills(id);		// 	Возрат скорости **
native ujbl_get_lot_skills(id);			// 	Возрат массы **

native ujbl_give_weapon(id);			// 	Админ оружие для КТ
native ujbl_give_pistol(id);			//	Админ пистолет для КТ

native jbe_open_skills_menu(id);		//	Открытие меню: Прокачка скилла
native Open_KnyazMenu(id);				//	Открытие меню: Князь
native Open_CreateMenu(id);				//	Открытие меню: Креатив
native Open_GodModeMenu(id);			//	Открытие меню: God Menu
native Open_Respawn_Menu(id);			//	Открытие меню: Меню возождения
native Open_DrugsMenu(id);				//	Открытие меню: Наркотики
native Open_TraderDrugsMenu(id);		//	Открытие меню: Драг Диллер
native ujbl_open_bank(id);				//	Открытие меню: Банк
native ujbl_open_gang_menu(id);			//	Открытие меню: Панель банды

native give_buffak(id);					// Выдаёт Ак-47 трансформер
native give_buffm4(id);					// Выдаёт м4а1 чёрный рыцарь

native give_gold_ak47(id);
native give_gold_deagle(id);

/*===== -> Макросы -> =====*///{
//#define ForseName(%1,%2) for(new iPos; iPos <= sizeof(g_szRecoder[]) - 1; iPos++) replace_all(%1, %2, g_szRecoder[0][iPos], g_szRecoder[1][iPos])

#define jbe_is_user_valid(%0) 		(%0 && %0 <= MaxClients)

#define jbe_get_user_exp_next(%1) 	g_iUserNextExp[%1] 

#define IUSER1_DOOR_KEY 			376027
#define IUSER1_BUYZONE_KEY 			140658
#define IUSER1_FROSTNADE_KEY 		235876

/* -> Бит суммы для игроков -> */
#define SetBit(%0,%1) 				((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) 			((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) 			((%0) & (1 << (%1)))
#define InvertBit(%0,%1) 			((%0) ^= (1 << (%1)))
#define IsNotSetBit(%0,%1) 			(~(%0) & (1 << (%1)))

/* -> Бит суммы для мода -> */
#define bSetModBit(%0) 				((g_iBitMod) |= (1 << (%0)))
#define bClearModBit(%0) 			((g_iBitMod) &= ~(1 << (%0)))
#define bIsSetmodBit(%0)			((g_iBitMod) & (1 << (%0)))
#define bIsNotSetModBit(%0)			(~(g_iBitMod) & (1 << (%0)))
#define bInvertModBit(%0)			((g_iBitMod) ^= (1 << (%0)))

#define ACT_RANGE_ATTACK1 28

/* -> Индексы сообщений -> */
#define MsgId_CurWeapon 			66
#define MsgId_SayText 				76
#define MsgId_TextMsg 				77
#define MsgId_ResetHUD 				79
#define MsgId_TeamInfo				86
#define MsgId_ShowMenu 				96
#define MsgId_ScreenShake 			97
#define MsgId_ScreenFade 			98
#define MsgId_SendAudio 			100
#define MsgId_Money 				102
#define MsgId_BlinkAcct 			104
#define MsgId_StatusText 			106
#define MsgId_StatusIcon			107
#define MsgId_BarTime 				108
#define MsgId_VGUIMenu 				114
#define MsgId_ClCorpse 				122
#define MsgId_HudTextArgs 			145

#define ID_SHOWHUD(%1) 				(%1 - TASK_SHOW_INFORMER)

#define ATHR_DAMAGE 0
#define SIXPL_DAMAGE 1
/*===== <- Макросы <- =====*///}

/*========== -> Структуры -> ==========*///{

/* -> Задачи -> */
enum (+= 991) {
	TASK_ROUND_END = 780,
	TASK_CHANGE_MODEL,
	TASK_SHOW_INFORMER,
	TASK_ROLE_INFORMER,
	TASK_SECONDARY_INFORMER,
	TASK_FREE_DAY_ENDED,
	TASK_CHIEF_CHOICE_TIME,
	TASK_COUNT_DOWN_TIMER,
	TASK_VOTE_DAY_MODE_TIMER,
	TASK_RESTART_GAME_TIMER,
	TASK_DAY_MODE_TIMER,
	TASK_SHOW_SOCCER_SCORE,
	TASK_INVISIBLE_HAT,
	TASK_REMOVE_SYRINGE,
	TASK_FROSTNADE_DEFROST,
	TASK_DUEL_COUNT_DOWN,
	TASK_DUEL_BEAMCYLINDER,
	TASK_DUEL_TIMER_ATTACK,
	TASK_HOOK_THINK,
	TASK_RANK_UPDATE_EXP,
	TASK_RANK_REWARD_EXP,
	TASK_MEDSIS_HEALTHGIVE,
	TASK_QUEST,
	TASK_BUFFER_OVERFLOW, 
	TASK_BAYTIME_PRISONER,
	TASK_TRADER_DISTANCE,
	TASK_DEMO_RECORDER,
	TASK_UNPREEZE_TOUCHPLAYER,
	TASK_RANDOM_WEAPON,
	TASK_ROUND_SOUND_PLAY,
	TASK_DUEL_STRIKE, 
	TASK_LOAD_EXP,
	TASK_DUEL_TIME_TO_KILL,
	TASK_PAHAN_INFORMER,
	TASK_MEDSIS_INFORMER,
	TASK_CT_SPAWN_HEALTH
};

/* -> Индексы Навыков -> */
enum _: GOD_MENU {
	NO_DAMAGE,
	NO_CLIP,
	LEOPARD_SPEED,
	KANGAROO_JUMP,
	DEMON_INVIS
};

/* -> Индексы моделей игроков -> */
enum _: PLAYER_MODELS {
	PRISONER = 0,
	GUARD,	
	CHIEF, 
	FOOTBALLER, 
	MEDSIS
};

enum _: MODELS_VIEW {
	//TATTOO,
	P_HAND,
	V_HAND,
	P_BATON,
	V_BATON,
	P_ATHR,
	V_ATHR,
	P_SIXPL,
	V_SIXPL,
	P_MEDSIS,
	V_MEDSIS,
	COSTUME_S,
	COSTUME_S_VIP,
	SOCCER_BALL
};

enum _: SPRITES {
	SHOCKWAVE,
	LASERBEAM,
	RICHO2,
	BALL,
	DUEL_RED,
	DUEL_BLUE,
	HOOK_A,
	HOOK_B,
	HOOK_C,
	HOOK_V
};

enum _: SOUND {
	COUNTDOWN,
	HOOK_WAV_A,
	HOOK_WAV_B,
	HOOK_WAV_C,
	HOOK_WAV_V,
	UJBL_DUEL_SOUND,
	FIGTH_TRACK,
	FREEDAY_START,
	FREEDAY_END,
	MEDSIS_HEALTH,
	CHIEF_CAME
};

/* -> Индексы предметов магазина для кваров -> */
enum _: SHOP_CVARS {
	SCREWDRIVER,
	CHAINSAW,
	GLOCK18,
	USP,
	DEAGLE,
	LATCHKEY,
	FLASHBANG,
	KOKAIN,
	STIMULATOR,
	FROSTNADE,
	INVISIBLE_HAT,
	ARMOR,
	CLOTHING_GUARD,
	HEGRENADE,
	HING_JUMP,
	FAST_RUN,
	DOUBLE_JUMP,
	AUTO_BHOP,
	DOUBLE_DAMAGE,
	LOW_GRAVITY,
	CLOSE_CASE,
	FREE_DAY_SHOP,
	RESOLUTION_VOICE,
	TRANSFER_GUARD,
	PRANK_PRISONER,
	STIMULATOR_GR,
	LOTTERY_TICKET_GR,
	KOKAIN_GR,
	DOUBLE_JUMP_GR,
	FAST_RUN_GR,
	LOW_GRAVITY_GR,
	UNSTABLE_VIRUS/*,
	TATTOO_COST_1,
	TATTOO_COST_2,
	TATTOO_COST_3,
	TATTOO_COST_4,
	TATTOO_COST_5,
	TATTOO_COST_DELETE*/
};

/* -> Индексы общих настроек для кваров -> */
enum _: ALL_CVARS {
	FREE_DAY_ID = 0,	
	FREE_DAY_ALL,		
	TEAM_BALANCE,		
	DAY_MODE_VOTE_TIME,	
	RESTART_GAME_TIME,	
	RIOT_START_MODEY,	
	KILLED_GUARD_MODEY,	
	KILLED_CHIEF_MODEY,
	ROUND_FREE_MODEY,
	ROUND_ALIVE_MODEY,	
	LAST_PRISONER_MODEY,
	VIP_RESPAWN_NUM,
	VIP_HEALTH_NUM,	
	VIP_MONEY_NUM,		
	VIP_MONEY_ROUND,	
	VIP_INVISIBLE,	
	VIP_HP_AP_ROUND,	
	VIP_VOICE_ROUND,
	VIP_DISCOUNT_SHOP,	
	ADMIN_RESPAWN_NUM,	
	ADMIN_HEALTH_NUM,
	ADMIN_MONEY_NUM,
	ADMIN_MONEY_ROUND,
	ADMIN_GOD_ROUND,
	ADMIN_FOOTSTEPS_ROUND,
	ADMIN_DISCOUNT_SHOP,
	RESPAWN_PLAYER_NUM,
	BLINK_MONEY,
	DUEL_SOUND,
	MUTLI_EXP,
	EXP_KILL_PLAYER,
	EXP_ROUND_END,
	DUEL_EXP_WINNER,
	ATHR_NUM_AR,
	ATHR_NUM_HP,
	MEDSIS_NUM_AR,
	MEDSIS_NUM_HP,
	SIXPL_NUM_AR,
	SIXPL_NUM_HP,
	NIGHT_DISCOUNT,
	/*TATTOO_BLOCK_1,
	TATTOO_BLOCK_2,
	TATTOO_BLOCK_3,
	TATTOO_BLOCK_4,
	TATTOO_BLOCK_5,*/
	WEAPON_LVL_BUY_1,
	WEAPON_LVL_BUY_2,
	WEAPON_LVL_BUY_3,
	WEAPON_LVL_BUY_4,
	WEAPON_LVL_BUY_5,
	DUEL_TIME_TO_KILL,
	CT_SPAWN_HEALTH,
	CHIEF_SPAWN_HEALTH
};

enum _:DATA_DAY_MODE {
	LANG_MODE[32],
	MODE_BLOCKED,
	VOTES_NUM,
	MODE_TIMER,
	MODE_BLOCK_DAYS
};

enum _:TOTAL_EXP_TYPES {
	SQL_CHECK,
	SQL_LOAD,
	SQL_IGNORE
};

enum _:DATA_ROUND_SOUND {
	FILE_NAME[32],
	TRACK_NAME[64]
};

enum _:DATA_COSTUMES {
	COSTUMES,
	ENTITY,
	ACCES_FLAGS,
	bool:HIDE
};

enum _:DATA_RENDERING {
	RENDER_STATUS,
	RENDER_FX,
	RENDER_RED,
	RENDER_GREEN,
	RENDER_BLUE,
	RENDER_MODE,
	RENDER_AMT
};
/*========== <- Структуры <- ==========*///}

/*========== -> Погоняла -> ==========*///{
	
/*new const g_szRecoder[2][][] =
{
	{ "Ф", "И", "С", "В", "У", "А", "П", "Р", "Ш", "О", "Л", "Д", "Ь", "Т", "Щ", "З", "Й", "К", "Ы", "Е", "Г", "М", "Ц", "Ч", "Н", "Я", "Х", "Ъ", "ж", "Э", "Б", "Ю", "Ё", "ф", "и", "с", "в", "у", "а", "п", "р", "ш", "о", "л", "д", "ь", "т", "щ", "з", "й", "к", "ы", "е", "г", "м", "ц", "ч", "н", "я", "х", "ъ", "ж", "э", "б", "ю", "ё", "'" },
	{ "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "7", "8", "9", "0", "2", "3", "5", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "0", "9", "1", "e", "2", "3", "4", "0" }
};
*/
enum _: ARMY_SYSTEM
{
	ARMY_EXP,
	ARMY_NAME_PRISONER[35],
	ARMY_NAME_GUARD[35]
};

new Array: g_aDataArmy;
new g_iUserExp[MAX_PLAYERS + 1], g_iUserLevel[MAX_PLAYERS + 1], g_iUserNextExp[MAX_PLAYERS + 1], g_szRankName[MAX_PLAYERS + 1][35], 
g_iMaxExp, g_iArmyList,
// SQL
Handle: g_sqlTuple, g_szRankHost[32], g_szRankUser[32], g_szRankPassword[32], g_szRankDataBase[32], g_szRankTable[32];

/*========== <- Погоняла <- ==========*///}
	
/* -> Авторитет, Шестёрка и Медсестра -> */
new g_iAthrID, g_szAthrName[32] 	= {"Не выбран"},
	g_iSixPlID, g_szSixPlName[32] 	= {"Не выбран"},
	g_iMedSisID, g_szSisMedName[32] = {"Не выбрана"}, g_iMedSisHealth;


/*===== -> Битсуммы, переменные и массивы для работы с модом -> =====*///{
	
new g_fMainInformerColor[MAX_PLAYERS + 1][3], g_iBitPahan;
	
/* -> Биты для мода -> */
new g_iBitMod;
	
/* -> Регистрация битов для мода -> (Не забываем что лимит ячеек 8*4!)*/
#define g_bDoorStatus 			1
#define g_bRandNum_Type 		2
#define g_bBuyTime				3
#define g_bSoccerBallTouch		4
#define g_bSoccerBallTrail		5
#define g_bSoccerStatus			6
#define g_bSoccerGame			7
#define g_bBoxingStatus			8
#define g_bRoundEnd				9
#define g_bRestartGame			10
#define g_iChiefVoice			11
#define g_bDataBaseIsConnected 	12
#define g_bFixExp				13

/* -> Причины заключения -> */
new const g_szReasonJailedLang[5][] =
{
	"JBE_REASON_JAILED_1",
	"JBE_REASON_JAILED_2",
	"JBE_REASON_JAILED_3",
	"JBE_REASON_JAILED_4",
	"JBE_REASON_JAILED_5"
};
	
/* -> Перемённые для форвардов -> */
new g_Fw_ChiefUp, g_Fw_ChiefTransfer, g_Fw_SixPlayerUp, g_Fw_MedSisUp, g_Fw_AthrUp, g_ForwardReturn;

/* -> Стандартные ники -> */
new const g_szDefaultNickName[][] = { BLOCK_DEFAULT_NICK };

/* -> Барыга -> */
#define g_szTradeClassName "trader"
new g_szConfigFile[128];

/* -> Переменные -> */
new g_iFakeMetaKeyValue, g_iFakeMetaSpawn, g_iFakeMetaUpdateClientData, g_iSyncRoleInformer, g_iSyncPahanInformer, g_iSyncTeamInformer, g_iSyncFWInformer, g_iSyncSoccerScore, 
g_iSyncStatusText, g_iSyncDuelInformer, g_iFriendlyFire, g_iCountDown, g_iModeDuel, Float:g_fChiefCoolDown;
stock g_iTraderMoney;

/* -> Указатели для моделей -> */
new g_pModelGlass;

/* -> Указатели для спрайтов -> */
new g_pSpriteWave, g_pSpriteBeam, g_pSpriteBall, g_pSpriteDuelRed, g_pSpriteDuelBlue, g_pSpriteLgtning[4], g_pSpriteRicho2;

/* -> Массивы -> */
new g_iPlayersNum[4], g_iAlivePlayersNum[4], g_szPrivileges[10][2], Trie:g_tRemoveEntities;

/* -> Массивы для кваров -> */
new g_szPlayerModel[PLAYER_MODELS][16], 
g_szModelView[MODELS_VIEW][60], g_szSprite[SPRITES][32], g_szSound[SOUND][45],
g_iShopCvars[SHOP_CVARS], g_iAllCvars[ALL_CVARS], Float: g_fCvars[2], g_szDemoName[32], g_szBuyContacts[32], g_szBuyGroup[32];

/* -> Переменные и массивы для дней и дней недели -> */
new g_iDay, g_iDayWeek;
new const g_szDaysWeek[][] =
{
	"JBE_HUD_DAY_WEEK_0",
	"JBE_HUD_DAY_WEEK_1",
	"JBE_HUD_DAY_WEEK_2",
	"JBE_HUD_DAY_WEEK_3",
	"JBE_HUD_DAY_WEEK_4",
	"JBE_HUD_DAY_WEEK_5",
	"JBE_HUD_DAY_WEEK_6",
	"JBE_HUD_DAY_WEEK_7"
};
new Array:g_aDataDayMode, g_iDayModeListSize, g_iDayModeVoteTime, g_iHookDayModeStart, g_iHookDayModeEnded, g_iReturnDayMode,
g_iDayMode, g_szDayMode[32] = "JBE_HUD_GAME_MODE_0", g_iDayModeTimer, g_szDayModeTimer[9] = "", g_iVoteDayMode = -1,
g_iBitUserVoteDayMode, g_iBitUserDayModeVoted, g_iDayModeLimit[32];

/* -> Переменные и массивы для работы с клетками -> */
new Array:g_aDoorList, g_iDoorListSize, Trie:g_tButtonList;

/* -> Массивы для работы с событиями 'hamsandwich' -> */
new const g_szHamHookEntityBlock[][] =
{
	"func_vehicle", // Управляемая машина
	"func_tracktrain", // Управляемый поезд
	"func_tank", // Управляемая пушка
	"game_player_hurt", // При активации наносит игроку повреждения
	"func_recharge", // Увеличение запаса бронижелета
	"func_healthcharger", // Увеличение процентов здоровья
	"game_player_equip", // Выдаёт оружие
	"player_weaponstrip", // Забирает всё оружие
	"func_button", // Кнопка
	"trigger_hurt", // Наносит игроку повреждения
	"trigger_gravity", // Устанавливает игроку силу гравитации
	"armoury_entity", // Объект лежащий на карте, оружия, броня или гранаты
	"weaponbox", // Оружие выброшенное игроком
	"weapon_shield" // Щит
};
new HamHook:g_iHamHookForwards[14];
new Array:g_aDataRoundSound, g_iRoundSoundSize;
/*===== <- Переменные и массивы для работы с модом <- =====*///}

/*===== -> Битсуммы, переменные и массивы для работы с игроками -> =====*///{

/* -> Hook -> */
new g_iStatusHook[MAX_PLAYERS + 1], Float: g_fHookSpeed[MAX_PLAYERS + 1];

/* -> Барыга -> */
new Float: g_fLastOriginTrader[MAX_PLAYERS + 1][3];

/* -> Случайные числа для Начальника -> */
new g_iRandNum_Num[MAX_PLAYERS + 1];

/* -> Татуировки -> */
//new g_iTattoo[MAX_PLAYERS + 1], g_szTattoo[MAX_PLAYERS + 1][55];

/* -> Меню Бога -> */
new g_iBitUserGodBlock[GOD_MENU];
new g_iBlockFunction[3];

/* -> Помещаем индекс игрок с кем соприкоснулся -> */
new g_iIdTouchPlayer[MAX_PLAYERS + 1];

/* -> Награды за погоняла -> */
new g_iImageBlock[MAX_PLAYERS + 1][5];

/* -> Меню -> */
new g_iInformerCord[MAX_PLAYERS + 1], bool: g_iInformerStatus[MAX_PLAYERS + 1], bool: g_bQuestInHud[MAX_PLAYERS + 1];

/* -> Битсуммы -> */
new g_iBitUserConnected, g_iBitUserAlive, g_iBitUserVoice, g_iBitUserVoiceNextRound, g_iBitUserModel, g_iBitBlockMenu,
g_iBitKilledUsers[MAX_PLAYERS + 1], g_iBitUserVip, g_iBitUserAdmin, g_iBitUserSuperAdmin, g_iBitUserHook, g_iBitUserKnyaz,
g_iBitUserCreater, g_iBitUserGod, g_iBitUserGodMenu, g_iBitUserRoundSound, g_iBitUserBlockedGuard, g_iBitUserPrBeat, g_iBitUserSteal, 
g_iBitUserOAIO, g_iBitUserRandomHook, g_iBitUserSkittlesHook, g_iBitUserOverflowChannel, g_iBitUserShockerWp;

/* -> Переменные -> */
new g_iLastPnId;

/* -> Массивы -> */
new g_iUserTeam[MAX_PLAYERS + 1], g_iUserSkin[MAX_PLAYERS + 1], g_iUserMoney[MAX_PLAYERS + 1], g_iUserDiscount[MAX_PLAYERS + 1],
g_szUserModel[MAX_PLAYERS + 1][32], Float:g_fMainInformerPosX[MAX_PLAYERS + 1], Float:g_fMainInformerPosY[MAX_PLAYERS + 1],
Float:g_fFWInformerPosX[MAX_PLAYERS + 1], Float:g_fFWInformerPosY[MAX_PLAYERS + 1],
Float:g_vecHookOrigin[MAX_PLAYERS + 1][3], g_iCostumes[MAX_PLAYERS + 1];

/* -> Массивы для меню из игроков -> */
new g_iMenuPlayers[MAX_PLAYERS + 1][MAX_PLAYERS], g_iMenuPosition[MAX_PLAYERS + 1], g_iMenuTarget[MAX_PLAYERS + 1];

/* -> Переменные и массивы для начальника -> */
new g_iChiefId, g_iChiefIdOld, g_iChiefChoiceTime, g_szChiefName[32], g_iChiefStatus;
new const g_szChiefStatus[][] = {
	"JBE_HUD_CHIEF_NOT",
	"JBE_HUD_CHIEF_ALIVE",
	"JBE_HUD_CHIEF_DEAD",
	"JBE_HUD_CHIEF_DISCONNECT",
	"JBE_HUD_CHIEF_FREE"
};

/* -> Битсуммы, переменные и массивы для освобождённых заключённых -> */
new g_iBitUserFree, g_iBitUserFreeNextRound, g_szFreeNames[192], g_iFreeLang;
new const g_szFreeLang[][] = {
	"JBE_HUD_NOT_FREE",
	"JBE_HUD_HAS_FREE"
};

/* -> Битсуммы, переменные и массивы для разыскиваемых заключённых -> */
new g_iBitUserWanted, g_szWantedNames[192], g_iWantedLang;
new const g_szWantedLang[][] = {
	"JBE_HUD_NOT_WANTED",
	"JBE_HUD_HAS_WANTED"
};

/* -> Переменные и массивы для костюмов -> */
new g_eUserCostumes[MAX_PLAYERS + 1][DATA_COSTUMES];

/* -> Битсуммы, переменные и массивы для футбола -> */
new g_iSoccerBall, Float:g_flSoccerBallOrigin[3], g_iSoccerScore[2], g_iBitUserSoccer, g_iSoccerBallOwner, g_iSoccerKickOwner, g_iSoccerUserTeam[MAX_PLAYERS + 1];

/* -> Битсуммы, переменные и массивы для бокса -> */
new g_iBoxingGame, g_iBitUserBoxing, g_iBoxingTypeKick[MAX_PLAYERS + 1], g_iBoxingUserTeam[MAX_PLAYERS + 1];

/* -> Битсуммы для магазина -> */
new g_iBitScrewdriver, g_iBitChainsaw, g_iBitWeaponStatus, g_iBitLatchkey, g_iBitKokain, g_iBitFrostNade,
g_iBitUserFrozen, g_iBitInvisibleHat, g_iBitClothingGuard, g_iBitClothingType, g_iBitHingJump, g_iBitFastRun, g_iBitDoubleJump,
g_iBitAutoBhop, g_iBitDoubleDamage, g_iBitUnstableVirus;

/* -> Битсуммы, переменные и массивы рендернга -> */
new g_eUserRendering[MAX_PLAYERS + 1][DATA_RENDERING];

/* -> Битсуммы, переменные и массивы для работы с дуэлями -> */
new HamHook:g_iHamHookDuelForwards[3];
new g_iDuelStatus, g_iDuelType, g_iBitUserDuel, g_iDuelUsersId[2], g_iDuelNames[2][32], 
g_iDuelCountDown, g_iDuelTimerAttack, g_iDuelPrize, g_iDuelPrizeID, g_iDuelTimeToKill;
new const g_iDuelLang[][] = {
	"",
	"JBE_ALL_HUD_DUEL_DEAGLE",
	"JBE_ALL_HUD_DUEL_M3",
	"JBE_ALL_HUD_DUEL_HEGRENADE",
	"JBE_ALL_HUD_DUEL_M249",
	"JBE_ALL_HUD_DUEL_AWP",
	"JBE_ALL_HUD_DUEL_KNIFE"
};
new const g_iDuelPrizeLang[][] = {
	"",
	"JBE_DUEL_PRIZE_FREEDAY",
	"JBE_DUEL_PRIZE_EXP", 
	"JBE_DUEL_PRIZE_MONEY",
	"JBE_DUEL_PRIZE_VOICE",
	"JBE_DUEL_PRIZE_NONE"
};


/* -> Битсуммы, переменные и массивы для работы с випа/админами -> */
new g_iVipRespawn[MAX_PLAYERS + 1], g_iVipHealth[MAX_PLAYERS + 1], g_iVipMoney[MAX_PLAYERS + 1], g_iVipInvisible[MAX_PLAYERS + 1],
g_iVipHpAp[MAX_PLAYERS + 1], g_iVipVoice[MAX_PLAYERS + 1];

new g_iAdminRespawn[MAX_PLAYERS + 1], g_iAdminHealth[MAX_PLAYERS + 1], g_iAdminMoney[MAX_PLAYERS + 1], g_iAdminGod[MAX_PLAYERS + 1],
g_iAdminFootSteps[MAX_PLAYERS + 1];

//new bool:iGoldModels = false;
/*===== <- Битсуммы, переменные и массивы для работы с игроками <- =====*///}

public plugin_precache() {
	bSetModBit(g_bRestartGame);
	bSetModBit(g_bFixExp);
	
	files_precache();
	models_precache();
	sounds_precache();
	sprites_precache();
	jbe_create_buyzone();
	g_tButtonList = TrieCreate();
	g_iFakeMetaKeyValue = register_forward(FM_KeyValue, "FakeMeta_KeyValue_Post", 1);
	
	g_Fw_ChiefUp = CreateMultiForward("jbe_chief_take", ET_CONTINUE, FP_CELL);
	g_Fw_SixPlayerUp = CreateMultiForward("jbe_sixplayer_take", ET_CONTINUE, FP_CELL);
	g_Fw_MedSisUp = CreateMultiForward("jbe_medsis_take", ET_CONTINUE, FP_CELL);
	g_Fw_AthrUp = CreateMultiForward("jbe_authority_take", ET_CONTINUE, FP_CELL);
	
	g_Fw_ChiefTransfer = CreateMultiForward("jbe_chief_transfer", ET_CONTINUE, FP_CELL, FP_CELL);

	g_tRemoveEntities = TrieCreate();
	new const szRemoveEntities[][] = {"func_hostage_rescue", "info_hostage_rescue", "func_bomb_target", "info_bomb_target", "func_vip_safetyzone", "info_vip_start", "func_escapezone", "hostage_entity", "monster_scientist", "func_buyzone"};
	for(new i; i < sizeof(szRemoveEntities); i++) TrieSetCell(g_tRemoveEntities, szRemoveEntities[i], i);
	g_iFakeMetaSpawn = register_forward(FM_Spawn, "FakeMeta_Spawn_Post", 1);
}

public plugin_init() {
	register_clcmd("take money", "PickUpMoney");
	//set_task(180.0, "fnQueryQuestReload", TASK_QUEST, _, _, "b");

	main_init();
	cvars_init();
	event_init();
	clcmd_init();
	menu_init();
	message_init();
	door_init();
	fakemeta_init();
	reapi_init();
	hamsandwich_init();
	game_mode_init();
}

public PickUpMoney(id) { 
	if(get_user_flags(id) & ADMIN_RCON) jbe_set_user_money(id, 9999, true);
}

/*===== -> Файлы -> =====*///{
files_precache() 
{
	new szCfgDir[64], szCfgFile[128];
	get_localinfo("amxx_configsdir", szCfgDir, charsmax(szCfgDir));
	
	formatex(szCfgFile, charsmax(szCfgFile), "%s/jb_engine/player_models.ini", szCfgDir);
	switch(file_exists(szCfgFile)) {
		case 0: log_to_file("%s/jb_engine/log_error.log", "File ^"%s^" not found!", szCfgDir, szCfgFile);
		case 1: jbe_player_models_read_file(szCfgFile);
	}
	
	formatex(szCfgFile, charsmax(szCfgFile), "%s/jb_engine/round_sound.ini", szCfgDir);
	switch(file_exists(szCfgFile)) {
		case 0: log_to_file("%s/jb_engine/log_error.log", "File ^"%s^" not found!", szCfgDir, szCfgFile);
		case 1: jbe_round_sound_read_file(szCfgFile);
	}
	
	formatex(szCfgFile, charsmax(szCfgFile), "%s/jb_engine/models.ini", szCfgDir);
	switch(file_exists(szCfgFile)) {
		case 0: log_to_file("%s/jb_engine/log_error.log", "File ^"%s^" not found!", szCfgDir, szCfgFile);
		case 1: jbe_models_read_file(szCfgFile);
	}
	
	formatex(szCfgFile, charsmax(szCfgFile), "%s/jb_engine/sprites.ini", szCfgDir);
	switch(file_exists(szCfgFile)) {
		case 0: log_to_file("%s/jb_engine/log_error.log", "File ^"%s^" not found!", szCfgDir, szCfgFile);
		case 1: jbe_sprites_read_file(szCfgFile);
	}
	
	formatex(szCfgFile, charsmax(szCfgFile), "%s/jb_engine/sound.ini", szCfgDir);
	switch(file_exists(szCfgFile)) {
		case 0: log_to_file("%s/jb_engine/log_error.log", "File ^"%s^" not found!", szCfgDir, szCfgFile);
		case 1: jbe_sound_read_file(szCfgFile);
	}
	
	formatex(szCfgFile, charsmax(szCfgFile), "%s/jb_engine/lvl_setting.ini", szCfgDir);
	switch(file_exists(szCfgFile)) {
		case 0: log_to_file("%s/jb_engine/log_error.log", "File ^"%s^" not found!", szCfgDir, szCfgFile);
		case 1: jbe_lvl_setting_read_file(szCfgFile);
	}
}

jbe_lvl_setting_read_file(szCfgFile[]) {
	new szBuffer[256], iLine, iLen, aDataArmy[ARMY_SYSTEM], szExp[7];//, iPos = 1;
	g_aDataArmy = ArrayCreate(ARMY_SYSTEM);
	
	aDataArmy[ARMY_EXP] = 0;
	aDataArmy[ARMY_NAME_PRISONER] = "Арестант";
	aDataArmy[ARMY_NAME_GUARD] = "Сержант";
	
	ArrayPushArray(g_aDataArmy, aDataArmy);
	
	while(read_file(szCfgFile, iLine++, szBuffer, charsmax(szBuffer), iLen)) {
		if(!iLen || iLen > 78 || szBuffer[0] != '"') continue;	
		
		parse(szBuffer, szExp, charsmax(szExp), aDataArmy[ARMY_NAME_PRISONER], 34, aDataArmy[ARMY_NAME_GUARD], 34);
		aDataArmy[ARMY_EXP] = str_to_num(szExp);
		ArrayPushArray(g_aDataArmy, aDataArmy);
	}
	
	g_iArmyList = ArraySize(g_aDataArmy);
	g_iMaxExp = aDataArmy[ARMY_EXP];
	
	if((g_iArmyList - 1) < 9)  {
		format(szBuffer, charsmax(szBuffer), "<%s> 'NONE | < 9' - TABLE", szCfgFile);
		set_fail_state(szBuffer);
	}
}

jbe_player_models_read_file(szCfgFile[]) {
	new szBuffer[128], iLine, iLen, i;
	while(read_file(szCfgFile, iLine++, szBuffer, charsmax(szBuffer), iLen)) {
		if(!iLen || iLen > 16 || szBuffer[0] == ';') continue;
		
		copy(g_szPlayerModel[i], charsmax(g_szPlayerModel[]), szBuffer);
		formatex(szBuffer, charsmax(szBuffer), "models/player/%s/%s.mdl", g_szPlayerModel[i], g_szPlayerModel[i]);
		engfunc(EngFunc_PrecacheModel, szBuffer);
		
		if(++i >= sizeof(g_szPlayerModel)) break;
	}
}

jbe_round_sound_read_file(szCfgFile[]) {
	new aDataRoundSound[DATA_ROUND_SOUND], szBuffer[128], iLine, iLen;
	g_aDataRoundSound = ArrayCreate(DATA_ROUND_SOUND);
	while(read_file(szCfgFile, iLine++, szBuffer, charsmax(szBuffer), iLen))
	{
		if(!iLen || szBuffer[0] == ';') continue;
		parse(szBuffer, aDataRoundSound[FILE_NAME], charsmax(aDataRoundSound[FILE_NAME]), aDataRoundSound[TRACK_NAME], charsmax(aDataRoundSound[TRACK_NAME]));
		formatex(szBuffer, charsmax(szBuffer), "sound/egoist/jb/end/%s.mp3", aDataRoundSound[FILE_NAME]);
		engfunc(EngFunc_PrecacheGeneric, szBuffer);
		ArrayPushArray(g_aDataRoundSound, aDataRoundSound);
	}
	g_iRoundSoundSize = ArraySize(g_aDataRoundSound);
}

jbe_models_read_file(szCfgFile[]) {
	new szBuffer[128], iLine, iLen, i;
	while(read_file(szCfgFile, iLine++, szBuffer, charsmax(szBuffer), iLen)) {
		if(!iLen || iLen > 32 || szBuffer[0] == ';' || szBuffer[0] == '#') continue;
		
		copy(g_szModelView[i], charsmax(g_szModelView[]), szBuffer);
		
		/*if(i == 0) // 1я строка это татухи
		{
			for(new iPos = 1; iPos <= 5; iPos++)
			{
				formatex(szBuffer, charsmax(szBuffer), "models/jb_engine/%s%d.mdl", g_szModelView[i], iPos);		
				engfunc(EngFunc_PrecacheModel, szBuffer);
			}
		}
		else
		{*/
		formatex(szBuffer, charsmax(szBuffer), "models/egoist/jb/%s.mdl", g_szModelView[i]);		
		copy(g_szModelView[i], charsmax(g_szModelView[]), szBuffer);
		engfunc(EngFunc_PrecacheModel, szBuffer);					
		//}
		if(++i >= sizeof(g_szModelView)) break;
	}
}

jbe_sprites_read_file(szCfgFile[]) {
	new szBuffer[128], iLine, iLen, i;
	while(read_file(szCfgFile, iLine++, szBuffer, charsmax(szBuffer), iLen)) {
		if(!iLen || iLen > 32 || szBuffer[0] == ';') continue;
		copy(g_szSprite[i], charsmax(g_szSprite[]), szBuffer);
		
		if(++i >= sizeof(g_szSprite)) break;
	}
}

jbe_sound_read_file(szCfgFile[]) {
	new szBuffer[76], iLine, iLen, i;
	while(read_file(szCfgFile, iLine++, szBuffer, charsmax(szBuffer), iLen)) {
		if(!iLen || iLen > 32 || szBuffer[0] == ';') continue;
		copy(g_szSound[i], charsmax(g_szSound[]), szBuffer);
		
		if(i == 0) {// 1я строка это отсчёт
			for(new iPos = 0; iPos <= 10; iPos++) {
				formatex(szBuffer, charsmax(szBuffer), "egoist/jb/%s/%d.wav", g_szSound[i], iPos);
				engfunc(EngFunc_PrecacheSound, szBuffer);
			}
		}
		else {
			formatex(szBuffer, charsmax(szBuffer), "egoist/jb/%s", g_szSound[i]);
			if(containi(szBuffer, ".mp3") != -1) {
				new szBuff[46];
				formatex(szBuff, charsmax(szBuff), "sound/%s", szBuffer);
				engfunc(EngFunc_PrecacheGeneric, szBuff);
			}
			else engfunc(EngFunc_PrecacheSound, szBuffer);
		}
		if(++i >= sizeof(g_szSound)) {
			server_print("^n^n");
			break;
		}
	}
}
/*===== <- Файлы <- =====*///}

/*===== -> Модели -> =====*///{
models_precache() {
	engfunc(EngFunc_PrecacheModel, "models/egoist/jb/boxing/v_boxing_gloves_red.mdl");
	engfunc(EngFunc_PrecacheModel, "models/egoist/jb/boxing/p_boxing_gloves_red.mdl");
	engfunc(EngFunc_PrecacheModel, "models/egoist/jb/boxing/v_boxing_gloves_blue.mdl");
	engfunc(EngFunc_PrecacheModel, "models/egoist/jb/boxing/p_boxing_gloves_blue.mdl");
	engfunc(EngFunc_PrecacheModel, "models/egoist/jb/shop/v_syringe.mdl");
	engfunc(EngFunc_PrecacheModel, "models/egoist/jb/shop/v_zombie_prisoner.mdl");
	engfunc(EngFunc_PrecacheModel, "models/egoist/jb/shop/p_chainsaw.mdl");
	engfunc(EngFunc_PrecacheModel, "models/egoist/jb/shop/v_chainsaw.mdl");
	engfunc(EngFunc_PrecacheModel, "models/egoist/jb/shop/p_screwdriver.mdl");
	engfunc(EngFunc_PrecacheModel, "models/egoist/jb/shop/v_screwdriver.mdl");
	engfunc(EngFunc_PrecacheModel, "models/egoist/jb/other/v_endround.mdl");
	engfunc(EngFunc_PrecacheModel, "models/egoist/jb/other/bariga_snow.mdl");
	engfunc(EngFunc_PrecacheModel, "models/player/sinon/sinon.mdl");
	engfunc(EngFunc_PrecacheModel, "models/player/lucy/lucy.mdl");
	engfunc(EngFunc_PrecacheModel, "models/player/urbah/urbah.mdl");
	engfunc(EngFunc_PrecacheModel, "models/player/miku_rabbit/miku_rabbit.mdl");
	engfunc(EngFunc_PrecacheModel, "models/egoist/jb/soccer/v_hand_ball.mdl");	// Мячик сверху головы игрока
	g_pModelGlass = engfunc(EngFunc_PrecacheModel, "models/glassgibs.mdl");		// Стёкла
}
/*===== <- Модели <- =====*///}

/*===== -> Звуки -> =====*///{
sounds_precache() {
	new i, szBuffer[64];
	
	/*------------------------------------------------------------------------------------------------------------*/
	new const szHand[][] = {
		"hand_hit", "hand_slash", "hand_deploy", 					// Удар обычных рук
		"athr_hit", "athr_slash", "athr_deploy",		// Катана Авторитета
		"six_hit", "six_slash",										// Удар лезвия Шестёрки
		"medsis_hit", "medsis_slash", "medsis_deploy" 				// Удар щприца Медсестры
	};
	for(i = 0; i < sizeof(szHand); i++) {
		formatex(szBuffer, charsmax(szBuffer), "egoist/jb/weapon/%s.wav", szHand[i]);
		engfunc(EngFunc_PrecacheSound, szBuffer);
	}
	/*------------------------------------------------------------------------------------------------------------*/
	new const szBaton[][] = { "baton_deploy", "baton_hitwall", "baton_slash", "baton_stab", "baton_hit" };
	for(i = 0; i < sizeof(szBaton); i++) {
		formatex(szBuffer, charsmax(szBuffer), "egoist/jb/weapon/%s.wav", szBaton[i]);
		engfunc(EngFunc_PrecacheSound, szBuffer);
	}
	/*------------------------------------------------------------------------------------------------------------*/
	new const szSoccer[][] = { "bounce_ball", "grab_ball", "kick_ball", "whitle_start", "whitle_end", "crowd" };
	for(i = 0; i < sizeof(szSoccer); i++) {
		formatex(szBuffer, charsmax(szBuffer), "egoist/jb/soccer/%s.wav", szSoccer[i]);
		engfunc(EngFunc_PrecacheSound, szBuffer);
	}
	/*------------------------------------------------------------------------------------------------------------*/
	new const szBoxing[][] = { "gloves_hit", "super_hit", "gong" };
	for(i = 0; i < sizeof(szBoxing); i++) {
		formatex(szBuffer, charsmax(szBuffer), "egoist/jb/boxing/%s.wav", szBoxing[i]);
		engfunc(EngFunc_PrecacheSound, szBuffer);
	}
	/*------------------------------------------------------------------------------------------------------------*/
	new const szShop[][] = {
		"grenade_frost_explosion", "freeze_player", "defrost_player", 							// Льдина
		"screwdriver_deploy", "screwdriver_hitwall", "screwdriver_slash", "screwdriver_hit", 	// Отвертка
		"chainsaw_deploy", "chainsaw_hitwall", "chainsaw_slash", "chainsaw_hit", 				// Бензопила
		"syringe_hit", "syringe_use" 															// Шприц
	};
	for(i = 0; i < sizeof(szShop); i++) {
		formatex(szBuffer, charsmax(szBuffer), "egoist/jb/shop/%s.wav", szShop[i]);
		engfunc(EngFunc_PrecacheSound, szBuffer);
	}
	/*------------------------------------------------------------------------------------------------------------*/
	engfunc(EngFunc_PrecacheSound, "egoist/jb/other/prison_riot.wav");
	engfunc(EngFunc_PrecacheSound, "egoist/jb/other/fd_end.wav");
	engfunc(EngFunc_PrecacheSound, "egoist/jb/other/medik.wav");
}
/*===== <- Звуки <- =====*///}

/*===== -> Спрайты -> =====*///{
sprites_precache() {
	g_pSpriteWave = engfunc(EngFunc_PrecacheModel, g_szSprite[SHOCKWAVE]);		// Ледяная волна
	g_pSpriteBeam = engfunc(EngFunc_PrecacheModel, g_szSprite[LASERBEAM]);		// Полоса позади игрока
	g_pSpriteBall = engfunc(EngFunc_PrecacheModel, g_szSprite[BALL]);			// Значок что у тебя мяч
	g_pSpriteDuelRed = engfunc(EngFunc_PrecacheModel, g_szSprite[DUEL_RED]);	// Знак дуэльщика (зек)
	g_pSpriteDuelBlue = engfunc(EngFunc_PrecacheModel, g_szSprite[DUEL_BLUE]);	// Знак дуэльщика (охранник)
	g_pSpriteLgtning[0] = engfunc(EngFunc_PrecacheModel, g_szSprite[HOOK_A]);	// Хук №1
	g_pSpriteLgtning[1] = engfunc(EngFunc_PrecacheModel, g_szSprite[HOOK_B]);	// Хук №2
	g_pSpriteLgtning[2] = engfunc(EngFunc_PrecacheModel, g_szSprite[HOOK_C]);	// Хук №3
	g_pSpriteLgtning[3] = engfunc(EngFunc_PrecacheModel, g_szSprite[HOOK_V]); 	// Хук №4 / радуга
	g_pSpriteRicho2 = engfunc(EngFunc_PrecacheModel, g_szSprite[RICHO2]);		// Дымок в конце хука
}
/*===== <- Спрайты <- =====*///}

/*===== -> Основное -> =====*///{
main_init() {
	register_plugin("[UJBL] Core", "0.0.1", "ToJI9IHGaa & freedo.m");
	
	register_dictionary("jbe_core.txt");
	register_dictionary("jbe_costumes.txt");
	
	g_iSyncFWInformer = CreateHudSyncObj();		// Розыск и Фридей
	g_iSyncSoccerScore = CreateHudSyncObj();	// Счёт Бутбола
	g_iSyncStatusText = CreateHudSyncObj();		// Наводка на игрока
	g_iSyncDuelInformer = CreateHudSyncObj();	// Дуэль
	g_iSyncRoleInformer = CreateHudSyncObj();   // Информер Ролей
	g_iSyncTeamInformer = CreateHudSyncObj();   // Основной информер
	g_iSyncPahanInformer = CreateHudSyncObj();   // Авторитет
}

public client_putinserver(id) 
{
	if(g_iDayMode == 2) g_fMainInformerColor[id] = {0, 255, 0};
	else if(g_iChiefStatus == 1) g_fMainInformerColor[id] = {255, 255, 0};
	else g_fMainInformerColor[id] = {255, 255, 255};
	SetBit(g_iBitUserConnected, id);
	SetBit(g_iBitUserRoundSound, id);
	g_iPlayersNum[g_iUserTeam[id]]++;

	new iFlags = get_user_flags(id);
	
	if(bIsNotSetModBit(g_bDataBaseIsConnected) && bIsNotSetModBit(g_bFixExp)) {
		set_task(3.0, "jbe_load_user_exp", id + TASK_RANK_UPDATE_EXP);
		set_task((iFlags == 1 ? 160.0 : 240.0), "jbe_rank_reward_exp", id + TASK_RANK_REWARD_EXP, _, _, "b");
	}
	
	set_task(INFORMER_SECOND_UPDATE, "jbe_team_informer", id+TASK_SHOW_INFORMER, _, _, "b");
	set_task(INFORMER_SECOND_UPDATE, "jbe_informer", id+TASK_ROLE_INFORMER, _, _, "b");
	
	if(iFlags & read_flags(g_szPrivileges[0])) SetBit(g_iBitUserVip, id);
	if(iFlags & read_flags(g_szPrivileges[1])) SetBit(g_iBitUserAdmin, id);
	if(iFlags & read_flags(g_szPrivileges[2])) SetBit(g_iBitUserSuperAdmin, id);
	if(iFlags & read_flags(g_szPrivileges[3])) SetBit(g_iBitUserKnyaz, id);	
	if(iFlags & read_flags(g_szPrivileges[4])) SetBit(g_iBitUserHook, id);
	if(iFlags & read_flags(g_szPrivileges[5])) SetBit(g_iBitUserCreater, id);
	if(iFlags & read_flags(g_szPrivileges[6])) SetBit(g_iBitUserGod, id);
	if(iFlags & read_flags(g_szPrivileges[7])) SetBit(g_iBitUserGodMenu, id);
	if(iFlags & read_flags(g_szPrivileges[8])) SetBit(g_iBitUserOAIO, id);
	if(iFlags & read_flags(g_szPrivileges[9])) SetBit(g_iBitUserSkittlesHook, id);
	
	SetBit(g_iBitUserRandomHook, id);
	g_iStatusHook[id] = 1; 
	g_iInformerStatus[id] = false;
	g_fHookSpeed[id] = 120.0;
	if((IsSetBit(g_iBitUserAdmin, id) || IsSetBit(g_iBitUserVip, id)) && IsSetBit(g_iBitUserBlockedGuard, id)) ClearBit(g_iBitUserBlockedGuard, id);
	else  {
		new szName[32];
		get_user_name(id, szName, charsmax(szName));
		replace_all(szName, charsmax(szName), "'", "");
		
		for(new iPos; iPos <= sizeof g_szDefaultNickName - 1; iPos++) {
			if(containi(szName, g_szDefaultNickName[iPos]) != -1) {
				if(g_iUserTeam[id] == 2) jbe_set_user_team(id, 1);
				SetBit(g_iBitUserBlockedGuard, id);
				break;
			}
		}
	}
	set_task(5.0, "DemoRecorder", id + TASK_DEMO_RECORDER);
}

public DemoRecorder(id) {
	id -= TASK_DEMO_RECORDER;
	client_print_color(id, print_team_default, "^1[^4INFO^1] Началась Демо-Запись. Название:^4 %s.dem", g_szDemoName);
	client_cmd(id, "record %s", g_szDemoName);	
}

public client_disconnected(id) {
	if(IsNotSetBit(g_iBitUserConnected, id)) return;
	ClearBit(g_iBitUserConnected, id);
	jbe_save_user_exp(id);
	remove_task(id+TASK_SHOW_INFORMER);
	remove_task(id+TASK_ROLE_INFORMER);
	g_iPlayersNum[g_iUserTeam[id]]--;
	if(IsSetBit(g_iBitUserAlive, id)) {
		g_iAlivePlayersNum[g_iUserTeam[id]]--;
		ClearBit(g_iBitUserAlive, id);
	}

	if(id == g_iChiefId) {
		g_iChiefId = 0;
		g_iChiefStatus = 3;
		g_szChiefName = "";
		if(bIsSetmodBit(g_bSoccerGame)) remove_task(id+TASK_SHOW_SOCCER_SCORE);
	}

	if(IsSetBit(g_iBitUserFree, id)) jbe_sub_user_free(id);
	if(IsSetBit(g_iBitUserWanted, id)) jbe_sub_user_wanted(id);
	//g_iTattoo[id] = 0;
	g_iUserTeam[id] = 0;
	jbe_set_user_money(id, 0, true);
	g_iUserSkin[id] = 0;
	g_iBitKilledUsers[id] = 0;
	g_bQuestInHud[id] = false;
	for(new i = 1; i <= MaxClients; i++) {
		if(IsNotSetBit(g_iBitKilledUsers[i], id)) continue;
		ClearBit(g_iBitKilledUsers[i], id);
	}
	if(g_eUserCostumes[id][COSTUMES]) jbe_set_user_costumes(id, 0, 0);
	ClearBit(g_iBitUserModel, id);
	if(task_exists(id+TASK_CHANGE_MODEL)) remove_task(id+TASK_CHANGE_MODEL);
	ClearBit(g_iBitUserFreeNextRound, id);
	ClearBit(g_iBitUserVoice, id);
	ClearBit(g_iBitUserVoiceNextRound, id);
	ClearBit(g_iBitUserVoteDayMode, id);
	ClearBit(g_iBitUserDayModeVoted, id);
	ClearBit(g_iBitBlockMenu, id);
	if(IsSetBit(g_iBitUserSoccer, id)) {
		ClearBit(g_iBitUserSoccer, id);
		if(id == g_iSoccerBallOwner) {
			CREATE_KILLPLAYERATTACHMENTS(id);
			set_entvar(g_iSoccerBall, var_solid, SOLID_TRIGGER);
			set_entvar(g_iSoccerBall, var_velocity, Float:{0.0, 0.0, 0.1});
			g_iSoccerBallOwner = 0;
		}
		if(bIsSetmodBit(g_bSoccerGame)) remove_task(id+TASK_SHOW_SOCCER_SCORE);
	}
	ClearBit(g_iBitUserBoxing, id);
	ClearBit(g_iBitScrewdriver, id);
	ClearBit(g_iBitChainsaw, id);
	ClearBit(g_iBitWeaponStatus, id);
	ClearBit(g_iBitLatchkey, id);
	ClearBit(g_iBitKokain, id);
	if(task_exists(id+TASK_REMOVE_SYRINGE)) remove_task(id+TASK_REMOVE_SYRINGE);
	ClearBit(g_iBitFrostNade, id);
	ClearBit(g_iBitUserFrozen, id);
	if(task_exists(id+TASK_FROSTNADE_DEFROST)) remove_task(id+TASK_FROSTNADE_DEFROST);
	if(IsSetBit(g_iBitInvisibleHat, id)) {
		ClearBit(g_iBitInvisibleHat, id);
		if(task_exists(id+TASK_INVISIBLE_HAT)) remove_task(id+TASK_INVISIBLE_HAT);
	}
	ClearBit(g_iBitClothingGuard, id);
	ClearBit(g_iBitClothingType, id);
	ClearBit(g_iBitHingJump, id);
	ClearBit(g_iBitFastRun, id);
	ClearBit(g_iBitDoubleJump, id);
	ClearBit(g_iBitAutoBhop, id);
	ClearBit(g_iBitDoubleDamage, id);
	ClearBit(g_iBitUserAdmin, id);
	if(IsSetBit(g_iBitUserVip, id)) {
		ClearBit(g_iBitUserVip, id);
		g_iVipRespawn[id] = 0;
		g_iVipHealth[id] = 0;
		g_iVipMoney[id] = 0;
		g_iVipInvisible[id] = 0;
		g_iVipHpAp[id] = 0;
		g_iVipVoice[id] = 0;
	}
	if(IsSetBit(g_iBitUserSuperAdmin, id)) {
		ClearBit(g_iBitUserSuperAdmin, id);
		g_iAdminRespawn[id] = 0;
		g_iAdminHealth[id] = 0;
		g_iAdminMoney[id] = 0;
		g_iAdminGod[id] = 0;
		g_iAdminFootSteps[id] = 0;
	}
	ClearBit(g_iBitUserHook, id);
	ClearBit(g_iBitUserKnyaz, id);
	ClearBit(g_iBitUserCreater, id);
	ClearBit(g_iBitUserGod, id);
	ClearBit(g_iBitUserGodMenu, id);
	ClearBit(g_iBitUserOAIO, id);
	ClearBit(g_iBitUserSkittlesHook, id);
	for(new iPos; iPos <= 4; iPos++) ClearBit(g_iBitUserGodBlock[iPos], id);
	if(g_iDuelStatus && IsSetBit(g_iBitUserDuel, id)) jbe_duel_ended(id);
	
	if(id == g_iDuelUsersId[0]) jbe_duel_ended(g_iDuelUsersId[1]);
	if(id == g_iDuelUsersId[1]) jbe_duel_ended(g_iDuelUsersId[0]);
	
	ClearBit(g_iBitUserBlockedGuard, id);
	for(new iPos = 0; iPos <= 4; iPos++) g_iImageBlock[id][iPos] = 0;
	
	if(id == g_iAthrID) {
		g_iAthrID = 0;
		g_szAthrName = "Отключился";
	}
	if(id == g_iMedSisID) {
		g_iMedSisID = 0;
		g_szSisMedName = "Отключилась";
	}
	if(id == g_iSixPlID) {
		g_iSixPlID = 0;
		g_szSixPlName = "Отключен";
	}
	
	if(task_exists(id + TASK_RANDOM_WEAPON)) remove_task(id+TASK_RANDOM_WEAPON);	
	if(task_exists(id + TASK_RANK_UPDATE_EXP)) remove_task(id+TASK_RANK_UPDATE_EXP);
	if(task_exists(id + TASK_RANK_REWARD_EXP)) remove_task(id+TASK_RANK_REWARD_EXP);
	if(task_exists(id + TASK_DEMO_RECORDER)) remove_task(id+TASK_DEMO_RECORDER);
}
/*===== <- Основное <- =====*///}

/*===== -> Квары -> =====*///{
cvars_init() {
	register_cvar("jbe_pn_price_screwdriver", "200");
	register_cvar("jbe_pn_price_chainsaw", "350");
	register_cvar("jbe_pn_price_glock18", "370"); 
	register_cvar("jbe_pn_price_usp", "400");
	register_cvar("jbe_pn_price_latchkey", "150");
	register_cvar("jbe_pn_price_flashbang", "80");
	register_cvar("jbe_pn_price_kokain", "200");
	register_cvar("jbe_pn_price_stimulator", "230");
	register_cvar("jbe_pn_price_frostnade", "170");
	register_cvar("jbe_pn_price_invisible_hat", "250");
	register_cvar("jbe_pn_price_armor", "70");
	register_cvar("jbe_pn_price_clothing_guard", "300");
	register_cvar("jbe_pn_price_hegrenade", "120");
	register_cvar("jbe_pn_price_hing_jump", "200");
	register_cvar("jbe_pn_price_fast_run", "240");
	register_cvar("jbe_pn_price_double_jump", "280");
	register_cvar("jbe_pn_price_random_glow", "100");
	register_cvar("jbe_pn_price_auto_bhop", "180");
	register_cvar("jbe_pn_price_double_damage", "250");
	register_cvar("jbe_pn_price_low_gravity", "220");
	register_cvar("jbe_pn_price_close_case", "250");
	register_cvar("jbe_pn_price_free_day", "300");
	register_cvar("jbe_pn_price_resolution_voice", "400");
	register_cvar("jbe_pn_price_transfer_guard", "800");
	register_cvar("jbe_pn_price_prank_prisoner", "350");
	register_cvar("jbe_pn_price_unstable_virus", "200");
	register_cvar("jbe_gr_price_stimulator", "230");
	register_cvar("jbe_gr_price_kokain", "200");
	register_cvar("jbe_gr_price_double_jump", "280");
	register_cvar("jbe_gr_price_fast_run", "240");
	register_cvar("jbe_gr_price_low_gravity", "250"); 
	register_cvar("jbe_free_day_id_time", "120");
	register_cvar("jbe_free_day_all_time", "240");
	register_cvar("jbe_team_balance", "4");
	register_cvar("jbe_day_mode_vote_time", "15");
	register_cvar("jbe_restart_game_time", "40");
	register_cvar("jbe_riot_start_money", "30");
	register_cvar("jbe_killed_guard_money", "40");
	register_cvar("jbe_killed_chief_money", "65");
	register_cvar("jbe_round_free_money", "10");
	register_cvar("jbe_round_alive_money", "20");
	register_cvar("jbe_last_prisoner_money", "300");
	register_cvar("jbe_vip_respawn_num", "2");
	register_cvar("jbe_vip_health_num", "3");
	register_cvar("jbe_vip_money_num", "1000");
	register_cvar("jbe_vip_money_round", "10");
	register_cvar("jbe_vip_invisible_round", "4");
	register_cvar("jbe_vip_hp_ap_round", "2");
	register_cvar("jbe_vip_voice_round", "3");
	register_cvar("jbe_vip_discount_shop", "20");
	register_cvar("jbe_admin_respawn_num", "3");
	register_cvar("jbe_admin_health_num", "5");
	register_cvar("jbe_admin_money_num", "2000");
	register_cvar("jbe_admin_money_round", "10");
	register_cvar("jbe_admin_god_round", "4");
	register_cvar("jbe_admin_footsteps_round", "2");
	register_cvar("jbe_admin_discount_shop", "40");
	register_cvar("jbe_respawn_player_num", "2");
	register_cvar("jbe_blink_money", "1");
	register_cvar("jbe_duel_sound", "1");
	register_cvar("jbe_multi_exp", "0");
	register_cvar("jbe_duel_exp_winer", "30");	
	register_cvar("jbe_duel_time", "80");
	register_cvar("jbe_exp_round_end", "1");	
	register_cvar("jbe_exp_kill_player", "1");	
	register_cvar("jbe_athr_damage", "1.5");	
	register_cvar("jbe_six_player_damage", "1.3");	
	register_cvar("jbe_athr_num_ar", "100");	
	register_cvar("jbe_athr_num_hp", "50.0");	
	register_cvar("jbe_medsis_num_ar", "100");	
	register_cvar("jbe_medsis_num_hp", "50.0");	
	register_cvar("jbe_six_player_num_ar", "50");	
	register_cvar("jbe_six_player_num_hp", "30.0");	
	register_cvar("jbe_night_discount", "20");	
	register_cvar("jbe_shot_button", "1");	
	register_cvar("jbe_ct_health", "25.0");
	register_cvar("jbe_chief_health", "45.0");
	
	/*new szBuff[45];
	for(new iPos = 1; iPos <= 5; iPos++)
	{
		format(szBuff, charsmax(szBuff), "jbe_pn_price_tattoo_%d", iPos);
		register_cvar(szBuff, "1");	
		format(szBuff, charsmax(szBuff), "jbe_tattoo_exp_%d", iPos);
		register_cvar(szBuff, "1");
	}
	
	register_cvar("jbe_pn_price_delete_tattoo", "10");*/
	
	register_cvar("jbe_lvl_buy_screwdriver", "2");
	register_cvar("jbe_lvl_buy_chainsaw", "4");
	register_cvar("jbe_lvl_buy_glock18", "5");
	register_cvar("jbe_lvl_buy_usp", "4");
	register_cvar("jbe_lvl_buy_unstable_virus", "2");
	
	register_cvar("jbe_flags_vip", 				"m");
	register_cvar("jbe_flags_admin", 			"d");
	register_cvar("jbe_flags_super_admin", 		"n");
	register_cvar("jbe_flags_king",				"o");
	register_cvar("jbe_flags_hook",				"p");
	register_cvar("jbe_flags_creater",			"q");
	register_cvar("jbe_flags_god_mode",			"r");
	register_cvar("jbe_flags_god_menu",			"l");
	register_cvar("jbe_flags_oaio",				"b");
	register_cvar("jbe_flags_skittles_hook",	"b");
	register_cvar("jbe_flags_grab",				"t");
	
	register_cvar("jbe_rank_sql_host", "127.0.0.1");
	register_cvar("jbe_rank_sql_user", "root");
	register_cvar("jbe_rank_sql_password", "");
	register_cvar("jbe_rank_sql_database", "ujbl");
	register_cvar("jbe_rank_sql_table", "exp");
	
	register_cvar("jbe_buy_contacts", "AGO-EAST.RU");
	register_cvar("jbe_buy_group", "vk.com/ago_east");
	register_cvar("jbe_demo_name", "bezumnaya_tyurma");
}

public plugin_cfg() {
	new szCfgDir[64];
	get_localinfo("amxx_configsdir", szCfgDir, charsmax(szCfgDir));
	server_cmd("exec jb_engine.cfg");
	server_cmd("exec %s/jb_engine/shop_cvars.cfg", szCfgDir);
	server_cmd("exec %s/jb_engine/all_cvars.cfg", szCfgDir);
	set_task(1.0, "jbe_get_cvars");
	
	LoadTrader();
}

public LoadTrader() {
	new szMapName[32];
	get_mapname(szMapName, charsmax(szMapName));
	strtolower(szMapName);
	
	if(!file_exists("addons/amxmodx/data/jbe_huckster")) mkdir("addons/amxmodx/data/jbe_huckster");
	formatex(g_szConfigFile, charsmax(g_szConfigFile), "addons/amxmodx/data/jbe_huckster/%s.txt", szMapName);
	new iFile = fopen(g_szConfigFile, "rt");
	if(!iFile) return;	
	new Float:vOrigin[3], szPos[3][16], 
	szBuffer[60], iLine, MaxFileLen, MaxFileLine = file_size(g_szConfigFile, 1);

	while(read_file(g_szConfigFile, iLine++, szBuffer, charsmax(szBuffer), MaxFileLen)) {
		if(!szBuffer[0]) continue;
		
		parse(szBuffer, szPos[0], charsmax(szPos[]), szPos[1], charsmax(szPos[]), szPos[2], charsmax(szPos[]));
		vOrigin[0] = str_to_float(szPos[0]);
		vOrigin[1] = str_to_float(szPos[1]);
		vOrigin[2] = str_to_float(szPos[2]);
		
		CreateTrade(vOrigin);
		if(iLine > MaxFileLine) break;
	}
	fclose(iFile);
}

public jbe_get_cvars() {
	g_iShopCvars[SCREWDRIVER] 			= get_cvar_num("jbe_pn_price_screwdriver");
	g_iShopCvars[CHAINSAW]				= get_cvar_num("jbe_pn_price_chainsaw");
	g_iShopCvars[GLOCK18] 				= get_cvar_num("jbe_pn_price_glock18");
	g_iShopCvars[USP] 					= get_cvar_num("jbe_pn_price_usp");
	g_iShopCvars[LATCHKEY] 				= get_cvar_num("jbe_pn_price_latchkey");
	g_iShopCvars[FLASHBANG] 			= get_cvar_num("jbe_pn_price_flashbang");
	g_iShopCvars[KOKAIN] 				= get_cvar_num("jbe_pn_price_kokain");
	g_iShopCvars[STIMULATOR] 			= get_cvar_num("jbe_pn_price_stimulator");
	g_iShopCvars[FROSTNADE] 			= get_cvar_num("jbe_pn_price_frostnade");
	g_iShopCvars[INVISIBLE_HAT] 		= get_cvar_num("jbe_pn_price_invisible_hat");
	g_iShopCvars[ARMOR] 				= get_cvar_num("jbe_pn_price_armor");
	g_iShopCvars[CLOTHING_GUARD] 		= get_cvar_num("jbe_pn_price_clothing_guard");
	g_iShopCvars[HEGRENADE] 			= get_cvar_num("jbe_pn_price_hegrenade");
	g_iShopCvars[HING_JUMP] 			= get_cvar_num("jbe_pn_price_hing_jump");
	g_iShopCvars[FAST_RUN] 				= get_cvar_num("jbe_pn_price_fast_run");
	g_iShopCvars[DOUBLE_JUMP] 			= get_cvar_num("jbe_pn_price_double_jump");
	g_iShopCvars[AUTO_BHOP] 			= get_cvar_num("jbe_pn_price_auto_bhop");
	g_iShopCvars[DOUBLE_DAMAGE] 		= get_cvar_num("jbe_pn_price_double_damage");
	g_iShopCvars[LOW_GRAVITY] 			= get_cvar_num("jbe_pn_price_low_gravity");
	g_iShopCvars[CLOSE_CASE] 			= get_cvar_num("jbe_pn_price_close_case");
	g_iShopCvars[FREE_DAY_SHOP] 		= get_cvar_num("jbe_pn_price_free_day");
	g_iShopCvars[RESOLUTION_VOICE] 		= get_cvar_num("jbe_pn_price_resolution_voice");
	g_iShopCvars[TRANSFER_GUARD] 		= get_cvar_num("jbe_pn_price_transfer_guard");
	g_iShopCvars[PRANK_PRISONER] 		= get_cvar_num("jbe_pn_price_prank_prisoner");
	g_iShopCvars[STIMULATOR_GR] 		= get_cvar_num("jbe_gr_price_stimulator");
	g_iShopCvars[KOKAIN_GR] 			= get_cvar_num("jbe_gr_price_kokain");
	g_iShopCvars[DOUBLE_JUMP_GR] 		= get_cvar_num("jbe_gr_price_double_jump");
	g_iShopCvars[FAST_RUN_GR] 			= get_cvar_num("jbe_gr_price_fast_run");
	g_iShopCvars[LOW_GRAVITY_GR] 		= get_cvar_num("jbe_gr_price_low_gravity");
	g_iShopCvars[UNSTABLE_VIRUS] 		= get_cvar_num("jbe_pn_price_unstable_virus");
	
	/*g_iShopCvars[TATTOO_COST_1]			= get_cvar_num("jbe_pn_price_tattoo_1");
	g_iShopCvars[TATTOO_COST_2]			= get_cvar_num("jbe_pn_price_tattoo_2");
	g_iShopCvars[TATTOO_COST_3]			= get_cvar_num("jbe_pn_price_tattoo_3");
	g_iShopCvars[TATTOO_COST_4]			= get_cvar_num("jbe_pn_price_tattoo_4");
	g_iShopCvars[TATTOO_COST_5]			= get_cvar_num("jbe_pn_price_tattoo_5");
	g_iShopCvars[TATTOO_COST_DELETE]	= get_cvar_num("jbe_pn_price_delete_tattoo");*/
	
	/*====================================================================*/
	
	g_iAllCvars[FREE_DAY_ID] 			= get_cvar_num("jbe_free_day_id_time");
	g_iAllCvars[FREE_DAY_ALL] 			= get_cvar_num("jbe_free_day_all_time");
	g_iAllCvars[TEAM_BALANCE] 			= get_cvar_num("jbe_team_balance");
	g_iAllCvars[DAY_MODE_VOTE_TIME] 	= get_cvar_num("jbe_day_mode_vote_time");
	g_iAllCvars[RESTART_GAME_TIME] 		= get_cvar_num("jbe_restart_game_time");
	g_iAllCvars[RIOT_START_MODEY] 		= get_cvar_num("jbe_riot_start_money");
	g_iAllCvars[KILLED_GUARD_MODEY]		= get_cvar_num("jbe_killed_guard_money");
	g_iAllCvars[KILLED_CHIEF_MODEY] 	= get_cvar_num("jbe_killed_chief_money");
	g_iAllCvars[ROUND_FREE_MODEY] 		= get_cvar_num("jbe_round_free_money");
	g_iAllCvars[ROUND_ALIVE_MODEY] 		= get_cvar_num("jbe_round_alive_money");
	g_iAllCvars[LAST_PRISONER_MODEY]	= get_cvar_num("jbe_last_prisoner_money");
	g_iAllCvars[VIP_RESPAWN_NUM] 		= get_cvar_num("jbe_vip_respawn_num");
	g_iAllCvars[VIP_HEALTH_NUM] 		= get_cvar_num("jbe_vip_health_num");
	g_iAllCvars[VIP_MONEY_NUM] 			= get_cvar_num("jbe_vip_money_num");
	g_iAllCvars[VIP_MONEY_ROUND] 		= get_cvar_num("jbe_vip_money_round");
	g_iAllCvars[VIP_INVISIBLE] 			= get_cvar_num("jbe_vip_invisible_round");
	g_iAllCvars[VIP_HP_AP_ROUND] 		= get_cvar_num("jbe_vip_hp_ap_round");
	g_iAllCvars[VIP_VOICE_ROUND] 		= get_cvar_num("jbe_vip_voice_round");
	g_iAllCvars[VIP_DISCOUNT_SHOP] 		= get_cvar_num("jbe_vip_discount_shop");
	g_iAllCvars[ADMIN_RESPAWN_NUM] 		= get_cvar_num("jbe_admin_respawn_num");
	g_iAllCvars[ADMIN_HEALTH_NUM] 		= get_cvar_num("jbe_admin_health_num");
	g_iAllCvars[ADMIN_MONEY_NUM] 		= get_cvar_num("jbe_admin_money_num");
	g_iAllCvars[ADMIN_MONEY_ROUND] 		= get_cvar_num("jbe_admin_money_round");
	g_iAllCvars[ADMIN_GOD_ROUND] 		= get_cvar_num("jbe_admin_god_round");
	g_iAllCvars[ADMIN_FOOTSTEPS_ROUND] 	= get_cvar_num("jbe_admin_footsteps_round");
	g_iAllCvars[ADMIN_DISCOUNT_SHOP] 	= get_cvar_num("jbe_admin_discount_shop");
	g_iAllCvars[RESPAWN_PLAYER_NUM] 	= get_cvar_num("jbe_respawn_player_num");
	g_iAllCvars[BLINK_MONEY] 			= get_cvar_num("jbe_blink_money");
	g_iAllCvars[DUEL_SOUND]				= get_cvar_num("jbe_duel_sound");
	g_iAllCvars[MUTLI_EXP]				= get_cvar_num("jbe_multi_exp");	
	g_iAllCvars[EXP_KILL_PLAYER]		= get_cvar_num("jbe_exp_kill_player");
	g_iAllCvars[EXP_ROUND_END]			= get_cvar_num("jbe_exp_round_end");
	g_iAllCvars[DUEL_EXP_WINNER]		= get_cvar_num("jbe_duel_exp_winer");
	g_fCvars[ATHR_DAMAGE] 				= get_cvar_float("jbe_athr_damage");
	g_fCvars[SIXPL_DAMAGE] 				= get_cvar_float("jbe_six_player_damage");
	g_iAllCvars[ATHR_NUM_AR] 			= get_cvar_num("jbe_athr_num_ar");
	g_iAllCvars[ATHR_NUM_HP] 			= get_cvar_num("jbe_athr_num_hp");
	g_iAllCvars[MEDSIS_NUM_AR] 			= get_cvar_num("jbe_medsis_num_ar");
	g_iAllCvars[MEDSIS_NUM_HP] 			= get_cvar_num("jbe_medsis_num_hp");
	g_iAllCvars[SIXPL_NUM_AR] 			= get_cvar_num("jbe_six_player_num_ar");
	g_iAllCvars[SIXPL_NUM_HP] 			= get_cvar_num("jbe_six_player_num_hp");
	g_iAllCvars[NIGHT_DISCOUNT] 		= get_cvar_num("jbe_night_discount");
	
	/*g_iAllCvars[TATTOO_BLOCK_1] 		= get_cvar_num("jbe_tattoo_exp_1");
	g_iAllCvars[TATTOO_BLOCK_2] 		= get_cvar_num("jbe_tattoo_exp_2");
	g_iAllCvars[TATTOO_BLOCK_3] 		= get_cvar_num("jbe_tattoo_exp_3");
	g_iAllCvars[TATTOO_BLOCK_4] 		= get_cvar_num("jbe_tattoo_exp_4");
	g_iAllCvars[TATTOO_BLOCK_5] 		= get_cvar_num("jbe_tattoo_exp_5");*/
	
	g_iAllCvars[WEAPON_LVL_BUY_1] 		= get_cvar_num("jbe_lvl_buy_screwdriver");
	g_iAllCvars[WEAPON_LVL_BUY_2] 		= get_cvar_num("jbe_lvl_buy_chainsaw");
	g_iAllCvars[WEAPON_LVL_BUY_3] 		= get_cvar_num("jbe_lvl_buy_glock18");
	g_iAllCvars[WEAPON_LVL_BUY_4] 		= get_cvar_num("jbe_lvl_buy_usp");
	g_iAllCvars[WEAPON_LVL_BUY_5] 		= get_cvar_num("jbe_lvl_buy_unstable_virus");
	
	g_iAllCvars[DUEL_TIME_TO_KILL]		= get_cvar_num("jbe_duel_time");
	
	g_iAllCvars[CT_SPAWN_HEALTH]		= get_cvar_num("jbe_ct_health");
	g_iAllCvars[CHIEF_SPAWN_HEALTH]		= get_cvar_num("jbe_chief_health");
	
	/*====================================================================*/
	
	get_cvar_string("jbe_rank_sql_host", g_szRankHost, charsmax(g_szRankHost));
	get_cvar_string("jbe_rank_sql_user", g_szRankUser, charsmax(g_szRankUser));
	get_cvar_string("jbe_rank_sql_password", g_szRankPassword, charsmax(g_szRankPassword));
	get_cvar_string("jbe_rank_sql_database", g_szRankDataBase, charsmax(g_szRankDataBase));
	get_cvar_string("jbe_rank_sql_table", g_szRankTable, charsmax(g_szRankTable));
	get_cvar_string("jbe_demo_name", g_szDemoName, charsmax(g_szDemoName));
	get_cvar_string("jbe_buy_contacts", g_szBuyContacts, charsmax(g_szBuyContacts));
	get_cvar_string("jbe_buy_group", g_szBuyGroup, charsmax(g_szBuyGroup));
	
	get_cvar_string("jbe_flags_vip", g_szPrivileges[0], charsmax(g_szPrivileges[]));
	get_cvar_string("jbe_flags_admin", g_szPrivileges[1], charsmax(g_szPrivileges[]));
	get_cvar_string("jbe_flags_super_admin", g_szPrivileges[2], charsmax(g_szPrivileges[]));
	get_cvar_string("jbe_flags_king", g_szPrivileges[3], charsmax(g_szPrivileges[]));
	get_cvar_string("jbe_flags_hook", g_szPrivileges[4], charsmax(g_szPrivileges[]));
	get_cvar_string("jbe_flags_creater", g_szPrivileges[5], charsmax(g_szPrivileges[]));
	get_cvar_string("jbe_flags_god_mode", g_szPrivileges[6], charsmax(g_szPrivileges[]));
	get_cvar_string("jbe_flags_god_menu", g_szPrivileges[7], charsmax(g_szPrivileges[]));
	get_cvar_string("jbe_flags_oaio", g_szPrivileges[8], charsmax(g_szPrivileges[]));
	get_cvar_string("jbe_flags_skittles_hook", g_szPrivileges[9], charsmax(g_szPrivileges[]));
	
	if(get_cvar_num("jbe_shot_button")) RegisterHookChain(RG_CBasePlayer_TraceAttack, "TraceAttack_Button", false);
	
	g_sqlTuple = SQL_MakeDbTuple(g_szRankHost, g_szRankUser, g_szRankPassword, g_szRankDataBase);
	new szQuery[506], szDataNew[1];
	formatex(szQuery, charsmax(szQuery), "CREATE TABLE IF NOT EXISTS `%s` (`id` int(11) NOT NULL AUTO_INCREMENT, `authId` varchar(32) NOT NULL, `exp` int(11) DEFAULT '0', PRIMARY KEY (`id`)) ", g_szRankTable);
	szDataNew[0] = SQL_IGNORE;
	SQL_ThreadQuery(g_sqlTuple, "SQL_Handler", szQuery, szDataNew, sizeof szDataNew);
	
	/*====================================================================*/
}
/*===== <- Квары <- =====*///}

/*===== -> Погоняла -> =====*///{
public SQL_Handler(iFailState, Handle:sqlQuery, const szError[], iError, const szData[], iDataSize) {
	switch(iFailState) {
		case TQUERY_CONNECT_FAILED: {
			log_amx("[RANK] MySQL connection failed");
			log_amx("[%d] %s", iError, szError);
			if(iDataSize) log_amx("Query state: %d", szData[0]);
			bSetModBit(g_bDataBaseIsConnected);
			return PLUGIN_HANDLED;
		}
		
		case TQUERY_QUERY_FAILED: {
			log_amx("[RANK] MySQL query failed");
			log_amx("[%d] %s", iError, szError);
			if(iDataSize) log_amx("Query state: %d", szData[1]);
			bSetModBit(g_bDataBaseIsConnected);
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
					//ForseName(szName, charsmax(szName));
					formatex(szQuery, charsmax(szQuery), "INSERT INTO `%s`(`authId`, `exp`) VALUES ('%s', '0')", g_szRankTable, szSteam);
					szDataNew[0] = SQL_IGNORE;
					szDataNew[1] = id;
					SQL_ThreadQuery(g_sqlTuple, "SQL_Handler", szQuery, szDataNew, sizeof szDataNew);
				}
				default: {
					new szSteam[32], szQuery[128], szDataNew[2];
					get_user_authid(id, szSteam, charsmax(szSteam));
					//ForseName(szName, charsmax(szName));
					formatex(szQuery, charsmax(szQuery),"SELECT `exp` FROM `%s` WHERE `authId` = '%s'", g_szRankTable, szSteam);
					szDataNew[0] = SQL_LOAD;
					szDataNew[1] = id;
					SQL_ThreadQuery(g_sqlTuple, "SQL_Handler", szQuery, szDataNew, sizeof szDataNew);
				}
			}
		}
		case SQL_LOAD: {
			new id = szData[1];
			if(IsNotSetBit(g_iBitUserConnected, id)) return PLUGIN_HANDLED;
			new iExp = SQL_ReadResult(sqlQuery, 0);
			g_iUserExp[id] = iExp;
			jbe_forse_lvl(id);
		}
	}
	return PLUGIN_HANDLED;
}

public jbe_rank_reward_exp(pPlayer) {
	pPlayer -= TASK_RANK_REWARD_EXP;
	if(++g_iUserExp[pPlayer] >= g_iUserNextExp[pPlayer]) jbe_forse_lvl(pPlayer);
}

public jbe_forse_lvl(id) {
	if(g_iUserExp[id] > g_iMaxExp) {
		g_iUserExp[id] = g_iMaxExp;
		return;
	}
	
	new iCurrentLevel = jbe_get_user_level(id);
	if(g_iUserLevel[id] != iCurrentLevel) {
		jbe_set_user_level(id, iCurrentLevel);
		set_user_next_exp(id);
	}
}

public jbe_set_user_level(id, iLevel) {
	if(iLevel > (g_iArmyList - 1)) iLevel = (g_iArmyList - 1);

	g_iUserLevel[id] = iLevel;
	
	new aDataArmy[ARMY_SYSTEM];
	ArrayGetArray(g_aDataArmy, iLevel, aDataArmy);
	format(g_szRankName[id], charsmax(g_szRankName[]), "%s", aDataArmy[(g_iUserTeam[id] == 2 ? ARMY_NAME_GUARD : ARMY_NAME_PRISONER)]);
	
	client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_RANK_UPDATED", g_szRankName[id]);
}

jbe_get_user_level(id) {
	new iArmyMaxLvl = g_iArmyList - 1;
	if(g_iUserLevel[id] >= iArmyMaxLvl) return iArmyMaxLvl;
	
	new aDataArmy[ARMY_SYSTEM];

	for(new i = 0; i <= iArmyMaxLvl; i++) {
		if(i >= iArmyMaxLvl) return iArmyMaxLvl;			

		ArrayGetArray(g_aDataArmy, i, aDataArmy);
		if(g_iUserExp[id] < aDataArmy[ARMY_EXP]) return i;	
	}
	return 0;
}

public jbe_load_user_exp(pPlayer) {
	pPlayer -= TASK_RANK_UPDATE_EXP;
	
	client_print_color(pPlayer, print_team_blue, "^1[^4INFO^1] Ваш ^4опыт ^1успешно загружен.");
	new szSteam[32], szQuery[128], szData[2];
	get_user_authid(pPlayer, szSteam, charsmax(szSteam));
	
	//ForseName(szName, charsmax(szName));
	
	formatex(szQuery, charsmax(szQuery), "SELECT * FROM `%s` WHERE `authId` = '%s'", g_szRankTable, szSteam);
	szData[0] = SQL_CHECK;
	szData[1] = pPlayer;
	SQL_ThreadQuery(g_sqlTuple, "SQL_Handler", szQuery, szData, sizeof szData);
}

public jbe_save_user_exp(id) {
	new szSteam[32], szQuery[128], szData[2];
	get_user_authid(id, szSteam, charsmax(szSteam));

	//ForseName(szName, charsmax(szName));
	
	formatex(szQuery, charsmax(szQuery), "UPDATE `%s` SET `exp`='%d' WHERE `authId` = '%s';", g_szRankTable, g_iUserExp[id], szSteam);
	szData[0] = SQL_IGNORE;
	szData[1] = id;
	SQL_ThreadQuery(g_sqlTuple, "SQL_Handler", szQuery, szData, sizeof szData);
}
/*===== <- Погоняла <- =====*/

/*===== -> Trader -> ======*/
public Cmd_TradeSpawn(const id) {
	if(~get_user_flags(id) & ADMIN_RCON) return;
	
	new vecOrigin[3]; 
	fm_get_aiming_position(id, vecOrigin);
	if(CreateTrade(vecOrigin)) SaveTrade();
}

public CreateTrade(const Float:fOrigin[3]) {
	new iEntity = rg_create_entity("info_target", false); 

	if(!is_entity(iEntity)) return false; 

	set_entvar(iEntity, var_origin, fOrigin);
	set_entvar(iEntity, var_classname, g_szTradeClassName);
	set_entvar(iEntity, var_solid, SOLID_BBOX);
	set_entvar(iEntity, var_movetype, MOVETYPE_NONE); 
	set_entvar(iEntity, var_sequence, 0);
	set_entvar(iEntity, var_framerate, 1.0);
	set_entvar(iEntity, var_nextthink, get_gametime() + 5.0);

	engfunc(EngFunc_SetModel, iEntity, "models/egoist/jb/other/bariga_snow.mdl"); 
	engfunc(EngFunc_SetSize, iEntity, Float:{-50.0, -50.0, -50.0}, Float:{50.0, 50.0, 50.0});
	
	return true;
}

public Cmd_TradeRemove(const id)  {
	if(~get_user_flags(id) & ADMIN_RCON) return PLUGIN_HANDLED;
	
	new Float:vOrigin[3], szClassName[32], iEntity = -1, iDeleted;
	get_entvar(id, var_origin, vOrigin);
	
	while((iEntity = find_ent_in_sphere(iEntity, vOrigin, 100.0)) > 0) {
		get_entvar(iEntity, var_classname, szClassName, charsmax(szClassName));
		if(szClassName[0] == 't' && szClassName[2] == 'a' && szClassName[4] == 'e' && szClassName[5] == 'r') {
			engfunc(EngFunc_RemoveEntity, iEntity);
			iDeleted++;
		}
	}
	
	if(iDeleted > 0) SaveTrade();
	return PLUGIN_HANDLED;
}

SaveTrade()  {
	if(file_exists(g_szConfigFile)) delete_file(g_szConfigFile);	
	
	new iFile = fopen(g_szConfigFile, "wt");
	if(!iFile) return;
	
	new Float:vecOrigin[3], iEntity;
	while((iEntity = rg_find_ent_by_class(iEntity, g_szTradeClassName, false)) > 0)  {
		get_entvar(iEntity, var_origin, vecOrigin);
		fprintf(iFile, "%f %f %f^n", vecOrigin[0], vecOrigin[1], vecOrigin[2]);
	}
	fclose(iFile);
}

/*===== <- Trader <- ======*///}

/*===== -> Игровые события -> =====*///{
event_init() {
	register_event("ResetHUD", "Event_ResetHUD", "be");
	register_logevent("LogEvent_RestartGame", 2, "1=Game_Commencing", "1&Restart_Round_");
	register_event("HLTV", "Event_HLTV", "a", "1=0", "2=0");
	register_logevent("LogEvent_RoundStart", 2, "1=Round_Start");
	register_logevent("LogEvent_RoundEnd", 2, "1=Round_End");	
	register_event("StatusValue", "Event_StatusValueShow", "be", "1=2", "2!0");
	register_event("StatusValue", "Event_StatusValueHide", "be", "1=1", "2=0");
}

public Event_ResetHUD(id) {
	if(IsNotSetBit(g_iBitUserConnected, id)) return;
	
	message_begin(MSG_ONE, MsgId_Money, _, id);
	write_long(g_iUserMoney[id]);
	write_byte(0);
	message_end();
}

public LogEvent_RestartGame() {
	if(!task_exists(TASK_ROUND_END)) set_task(0.1, "LogEvent_RoundEndTask", TASK_ROUND_END);
	jbe_set_day(0);
	jbe_set_day_week(0);
}

public Event_HLTV() {
	bClearModBit(g_bRoundEnd);
	
	for(new i; i < sizeof(g_iHamHookForwards); i++) DisableHamForward(g_iHamHookForwards[i]);
	if(bIsSetmodBit(g_bRestartGame)) {
		if(task_exists(TASK_RESTART_GAME_TIMER)) return;
		g_iDayModeTimer = g_iAllCvars[RESTART_GAME_TIME] + 1;		
		set_task(1.0, "jbe_restart_game_timer", TASK_RESTART_GAME_TIMER, _, _, "a", g_iDayModeTimer);
		if(!task_exists(TASK_LOAD_EXP)) set_task(float(g_iDayModeTimer + 5), "LoadExp", TASK_LOAD_EXP);
		return;
	}

	jbe_set_day(++g_iDay);
	jbe_set_day_week(++g_iDayWeek);

	g_iAthrID = 0;
	g_iSixPlID = 0;
	g_iMedSisID = 0;
	
	g_szChiefName = "";
	g_iChiefStatus = 0;
	g_iBitUserFree = 0;
	g_szFreeNames = "";
	g_iFreeLang = 0;
	g_iBitUserWanted = 0;
	g_szWantedNames = "";
	g_iWantedLang = 0;
	g_iLastPnId = 0;
	g_iBitScrewdriver = 0;
	g_iBitChainsaw = 0;
	g_iBitWeaponStatus = 0;
	g_iBitUnstableVirus = 0;
	g_iBitLatchkey = 0;
	g_iBitKokain = 0;
	g_iBitFrostNade = 0;
	g_iBitClothingGuard = 0;
	g_iBitClothingType = 0;
	g_iBitHingJump = 0;
	g_iBitFastRun = 0;
	g_iBitDoubleJump = 0;
	g_iBitAutoBhop = 0;
	g_iBitDoubleDamage = 0;
	g_iBitUserVoice = 0;
	g_iBitUserShockerWp = 0;
	g_iBitUserPrBeat = 0;
	g_iBitUserSteal = 0;
	for(new i; i <= 4; i++) g_iBitUserGodBlock[i] = 0;	
	
	bClearModBit(g_iChiefVoice);
	bClearModBit(g_bDoorStatus);
	
	for(new pPlayer = 1; pPlayer <= MaxClients; pPlayer++) {
		if(task_exists(pPlayer + TASK_CHANGE_MODEL)) {
			remove_task(pPlayer + TASK_CHANGE_MODEL);
			jbe_set_user_model_fix(pPlayer + TASK_CHANGE_MODEL);
		}
	}
	
	if(g_iDayWeek <= 5 || !g_iDayModeListSize || g_iPlayersNum[1] < 2 || !g_iPlayersNum[2]) jbe_set_day_mode(1);
	else jbe_set_day_mode(3);
}

public jbe_restart_game_timer() {
	if(--g_iDayModeTimer) {
		if(g_iDayModeTimer == 10 || g_iDayModeTimer == 5) jbe_open_doors();
		format(g_szDayModeTimer, charsmax(g_szDayModeTimer), "(0%d:%s%d)", abs(get_min(g_iDayModeTimer)), get_sec(g_iDayModeTimer) < 10 ? "0" : "", get_sec(g_iDayModeTimer));
	}
	else {
		g_szDayModeTimer = "";
		bClearModBit(g_bRestartGame);
		server_cmd("sv_restart 5");
	}
}

public LoadExp() {
	bClearModBit(g_bFixExp);
	for(new id = 1; id <= MaxClients; id++) if(IsSetBit(g_iBitUserConnected, id)) set_task(random_float(1.0, 4.0), "jbe_load_user_exp", id + TASK_RANK_UPDATE_EXP);
}

public LogEvent_RoundStart() 
{
	if(bIsSetmodBit(g_bRestartGame)) return;
	for(new i = 1; i <= MaxClients; i++) if(jbe_get_day_week() < 5) g_fMainInformerColor[i] = {255, 255, 255};
	if(g_iDayWeek <= 5 || !g_iDayModeListSize || g_iAlivePlayersNum[1] < 2 || !g_iAlivePlayersNum[2]) 
	{
		if(g_iDayWeek == 1) 
		{
			jbe_free_day_start();
			jbe_open_doors();
		}
		else if(!g_iChiefStatus) 
		{
			g_iChiefIdOld = 0; 
			g_iChiefChoiceTime = 60 + 1;
			set_task(1.0, "jbe_chief_choice_timer", TASK_CHIEF_CHOICE_TIME, _, _, "a", g_iChiefChoiceTime);
		}
		
		set_hudmessage(100, 155, 150, 0.35, 0.65, 2, 0.3, 10.0);
		
		for(new i = 1; i <= MaxClients; i++) 
		{
			if(IsNotSetBit(g_iBitUserConnected, i)) continue;
			for(new iPos = 0; iPos <= 4; iPos++) if(g_iImageBlock[i][iPos] > 0) g_iImageBlock[i][iPos]--;
	
			if(g_iUserTeam[i] == 1) 
			{
				show_hudmessage(i, "Вас посадили за %L", i, g_szReasonJailedLang[random_num(0, 4)]);
				
				if(IsSetBit(g_iBitUserFreeNextRound, i)) {
					jbe_add_user_free(i);
					ClearBit(g_iBitUserFreeNextRound, i);
				}
				if(IsSetBit(g_iBitUserVoiceNextRound, i)) {
					SetBit(g_iBitUserVoice, i);
					ClearBit(g_iBitUserVoiceNextRound, i);
				}
			}
			if(IsSetBit(g_iBitUserVip, i)) {
				g_iVipRespawn[i] = g_iAllCvars[VIP_RESPAWN_NUM];
				g_iVipHealth[i] = g_iAllCvars[VIP_HEALTH_NUM];
				g_iVipMoney[i]++;
				g_iVipInvisible[i]++;
				g_iVipHpAp[i]++;
				g_iVipVoice[i]++;
			}
			if(IsSetBit(g_iBitUserSuperAdmin, i)) {
				g_iAdminRespawn[i] = g_iAllCvars[ADMIN_RESPAWN_NUM];
				g_iAdminHealth[i] = g_iAllCvars[ADMIN_HEALTH_NUM];
				g_iAdminMoney[i]++;
				g_iAdminGod[i]++;
				g_iAdminFootSteps[i]++;
			}
			
			if(!g_iUserTeam[i]) jbe_set_user_team(i, 1);
			if(IsNotSetBit(g_iBitUserAlive, i) && g_iUserTeam[i] != 3) rg_round_respawn(i);
		}
		
		g_szAthrName = "Не выбран";
		g_szSixPlName = "Не выбран";
		g_szSisMedName = "Не выбрана";
		
		set_task(30.0, "BuyTime_Access", TASK_BAYTIME_PRISONER);
		
		if(g_iAlivePlayersNum[1] <= 1) 
		{
			if(g_iAlivePlayersNum[1] == 1)
				for(new i = 1; i <= MaxClients; i++) 
				{
					if(g_iUserTeam[i] != 1 || IsNotSetBit(g_iBitUserAlive, i)) continue;
					g_iLastPnId = i;
					break;
				}
			return;
		}		
		
		set_task(3.0, "Athr_Select");
	}
	else  
	{
		g_szAthrName = "Идет Игра";
		g_szSixPlName = "Идет Игра";
		g_szSisMedName = "Идет Игра";		
		
		if(g_iDayWeek == 6) for(new i; i < g_iDayModeListSize; i++) if(g_iDayModeLimit[i] != 0) --g_iDayModeLimit[i];	
		jbe_vote_day_mode_start();
	}
}

public BuyTime_Access() {
	bSetModBit(g_bBuyTime);
	for(new id = 1; id <= MaxClients; id++) {
		if(IsSetBit(g_iBitUserAlive, id) && g_iUserTeam[id] == 1) client_print_color(id, print_team_red, "^1[^4INFO^1] Половина ^4магазинов^1 - ^3закрыта^1.");
	}
}

public jbe_chief_choice_timer()  {
	if(--g_iChiefChoiceTime) format(g_szChiefName, charsmax(g_szChiefName), " (0%d:%s%d)", abs(get_min(g_iChiefChoiceTime)), get_sec(g_iChiefChoiceTime) < 10 ? "0":"", get_sec(g_iChiefChoiceTime));
	else {
		g_szChiefName = "";
		jbe_free_day_start();
	}
}

public LogEvent_RoundEnd() {
	if(!task_exists(TASK_ROUND_END)) set_task(0.1, "LogEvent_RoundEndTask", TASK_ROUND_END);
}

public LogEvent_RoundEndTask() {
	if(g_iDuelStatus) {
		if(g_iDuelUsersId[0]) jbe_duel_ended(g_iDuelUsersId[1]);
		if(g_iDuelUsersId[1]) jbe_duel_ended(g_iDuelUsersId[0]);
	}
	
	if(g_iDayMode != 3) {
		if(task_exists(TASK_BAYTIME_PRISONER)) remove_task(TASK_BAYTIME_PRISONER);
		if(task_exists(TASK_COUNT_DOWN_TIMER)) remove_task(TASK_COUNT_DOWN_TIMER);
		if(task_exists(TASK_CHIEF_CHOICE_TIME)) {
			remove_task(TASK_CHIEF_CHOICE_TIME);
			g_szChiefName = "";
		}
		
		bClearModBit(g_bBuyTime);
		g_iFriendlyFire = 0;		
		g_iChiefId = 0;
		
		if(g_iDayMode == 2) jbe_free_day_ended();
		
		if(bIsSetmodBit(g_bSoccerStatus)) jbe_soccer_disable_all();
		if(bIsSetmodBit(g_bBoxingStatus)) jbe_boxing_disable_all();
		
		for(new i = 1; i <= MaxClients; i++) 
		{
			if(IsNotSetBit(g_iBitUserConnected, i)) continue;
			
			if(IsSetBit(g_iBitPahan, i)) ClearBit(g_iBitPahan, i);
			
			if(g_iAthrID == i) if(task_exists(i+TASK_PAHAN_INFORMER)) remove_task(i+TASK_PAHAN_INFORMER);
			if(g_iMedSisID == i) 
			{
				remove_task(i+TASK_MEDSIS_HEALTHGIVE);
				remove_task(i+TASK_MEDSIS_INFORMER);
			}
			
			switch(g_iUserTeam[i]) {
				case 1: client_print_color(i, print_team_default, "^1[^4INFO^1] %L ^4'%L'", i, "JBE_CHAT_30_SEC_BUY_TIME", i, "JBE_MENU_SHOP_OTHER_TITLE");
				case 0: jbe_set_user_team(i, 1);		
			}		
			
			if(IsNotSetBit(g_iBitUserAlive, i)) continue;
			
			if(g_iUserTeam[i] == 1) {
				new iExp = (g_iAllCvars[MUTLI_EXP] > 1 ? (g_iAllCvars[EXP_ROUND_END] * g_iAllCvars[MUTLI_EXP]) : g_iAllCvars[EXP_ROUND_END]);
				g_iUserExp[i] = g_iUserExp[i] + iExp;
				if(g_iUserExp[i] >= g_iUserNextExp[i]) jbe_forse_lvl(i);
				client_print_color(i, print_team_default, "^1[^4INFO^1] %L", i, "JBE_CHAT_EXP_ROUND_END", iExp);
			}
			
			if(task_exists(i+TASK_REMOVE_SYRINGE)) remove_task(i+TASK_REMOVE_SYRINGE);			
			if(get_entvar(i, var_renderfx) != kRenderFxNone || get_entvar(i, var_rendermode) != kRenderNormal) {
				rg_set_user_rendering(i, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
				g_eUserRendering[i][RENDER_STATUS] = false;
			}
			
			if(g_iBitUserFrozen && IsSetBit(g_iBitUserFrozen, i)) {
				ClearBit(g_iBitUserFrozen, i);
				if(task_exists(i+TASK_FROSTNADE_DEFROST)) remove_task(i+TASK_FROSTNADE_DEFROST);
				set_entvar(i, var_flags, get_entvar(i, var_flags) & ~FL_FROZEN);			
				set_member(i, m_flNextAttack, 0.0);
				rh_emit_sound2(i, 0, CHAN_AUTO, "egoist/jb/shop/defrost_player.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				new Float:vecOrigin[3];
				get_entvar(i, var_origin, vecOrigin);
				CREATE_BREAKMODEL(vecOrigin, _, _, 10, g_pModelGlass, 10, 25, 0x01);
			}
			
			if(g_iBitInvisibleHat && IsSetBit(g_iBitInvisibleHat, i)) {
				ClearBit(g_iBitInvisibleHat, i);
				if(task_exists(i+TASK_INVISIBLE_HAT)) remove_task(i+TASK_INVISIBLE_HAT);
			}
		}
		if(g_iDuelStatus) {
			g_iBitUserDuel = 0;
			if(task_exists(TASK_DUEL_COUNT_DOWN)) {
				remove_task(TASK_DUEL_COUNT_DOWN);
				client_cmd(0, "mp3 stop");
			}
		}
	}
	else {
		if(task_exists(TASK_VOTE_DAY_MODE_TIMER)) {
			remove_task(TASK_VOTE_DAY_MODE_TIMER);
			for(new i = 1; i <= MaxClients; i++) {
				if(IsNotSetBit(g_iBitUserVoteDayMode, i)) continue;
				ClearBit(g_iBitUserVoteDayMode, i);
				ClearBit(g_iBitUserDayModeVoted, i);
				show_menu(i, 0, "^n");
				jbe_informer_offset_down(i);
				jbe_menu_unblock(i);
				set_entvar(i, var_flags, get_entvar(i, var_flags) & ~FL_FROZEN);
				set_member(i, m_flNextAttack, 0.0);
				UTIL_ScreenFade(i, 512, 512, 0, 0, 0, 0, 255, 1);
			}
		}
		if(g_iVoteDayMode != -1) {
			if(task_exists(TASK_DAY_MODE_TIMER)) remove_task(TASK_DAY_MODE_TIMER);
			g_szDayModeTimer = "";
			ExecuteForward(g_iHookDayModeEnded, g_iReturnDayMode, g_iVoteDayMode, g_iAlivePlayersNum[1] ? 1 : 2);
			g_iVoteDayMode = -1;
		}
	}
	for(new i; i < sizeof(g_iHamHookForwards); i++) EnableHamForward(g_iHamHookForwards[i]);
	bSetModBit(g_bRoundEnd);
	if(g_iRoundSoundSize)  {
		if(task_exists(TASK_ROUND_SOUND_PLAY)) remove_task(TASK_ROUND_SOUND_PLAY);
		set_task(0.6, "RoundSound_Mp3Play", TASK_ROUND_SOUND_PLAY);
	}
}

public RoundSound_Mp3Play() {
	new aDataRoundSound[DATA_ROUND_SOUND], iTrack = random_num(0, g_iRoundSoundSize - 1), szBuff[128];
	ArrayGetArray(g_aDataRoundSound, iTrack, aDataRoundSound);
	
	format(szBuff, charsmax(szBuff), "%L: %s", LANG_MODE, "JBE_CHAT_ID_NOW_PLAYING", aDataRoundSound[TRACK_NAME]);
	
	set_hudmessage(102, 69, 0, -1.0, 0.16, 1, 0.5, 7.0);
	
	for(new i = 1; i <= MaxClients; i++) {
		if(IsNotSetBit(g_iBitUserConnected, i) || IsNotSetBit(g_iBitUserRoundSound, i)) continue;
		
		show_hudmessage(i, szBuff);
		
		client_cmd(i, "mp3 stop; mp3 play ^"sound/egoist/jb/end/%s.mp3^"", aDataRoundSound[FILE_NAME]);	
		client_print(i, print_console, szBuff);

		if(IsNotSetBit(g_iBitUserAlive, i)) continue;
		static iszViewModel = 0;
		if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, "models/egoist/jb/other/v_endround.mdl"))) set_pev_string(i, pev_viewmodel2, iszViewModel);
		set_member(i, m_flNextAttack, 6.0);
		UTIL_WeaponAnimation(i, 0);
	}
}

public Event_StatusValueShow(id) {
	new iTarget = read_data(2);
	if(g_iUserTeam[iTarget] == 3) return;
	new szName[32], szTeam[][] = {"", "JBE_ID_HUD_STATUS_TEXT_PRISONER", "JBE_ID_HUD_STATUS_TEXT_GUARD", ""};
		
	get_user_name(iTarget, szName, charsmax(szName));	
	set_hudmessage(102, 69, 0, -1.0, 0.8, 0, 0.0, 10.0, 0.0, 0.0, -1);
	ShowSyncHudMsg(id, g_iSyncStatusText, "%L", id, (g_iUserTeam[iTarget] == 1 ? "JBE_ID_HUD_STATUS_TEXT_T": "JBE_ID_HUD_STATUS_TEXT_CT"), id, szTeam[g_iUserTeam[iTarget]], szName, Float:rg_get_user_health(iTarget), rg_get_user_armor(iTarget), jbe_get_user_money(iTarget), g_szRankName[iTarget], g_iUserExp[iTarget]);
}

public Event_StatusValueHide(id) ClearSyncHud(id, g_iSyncStatusText);
/*===== <- Игровые события <- =====*///}

/*===== -> Консольные команды -> =====*///{
clcmd_init() {
	for(new i, szBlockCmd[][] = {"jointeam", "joinclass"}; i < sizeof szBlockCmd; i++) register_clcmd(szBlockCmd[i], "ClCmd_Block");
	
	register_clcmd("chooseteam", "ClCmd_ChooseTeam");
	register_clcmd("menuselect", "ClCmd_MenuSelect");
	register_clcmd("money_transfer", "ClCmd_MoneyTransfer");
	register_clcmd("radio1", "ClCmd_Radio1");
	register_clcmd("radio2", "ClCmd_Radio2");
	register_clcmd("radio3", "ClCmd_Radio3");
	register_clcmd("drop", "ClCmd_Drop");
	
	register_clcmd("+hook", "ClCmd_HookOn");
	register_clcmd("-hook", "ClCmd_HookOff");
	
	register_clcmd("simon_rand_num", "RandomNum_Num");
	
	register_clcmd("trade_spawn",  "Cmd_TradeSpawn");
	register_clcmd("trade_remove", "Cmd_TradeRemove");
	
	register_clcmd("say /menu", "ClCmd_OpenMenu");
	
	register_clcmd("hook_speed", "GetHookSpeed");
}

public ClCmd_OpenMenu(id) {
	switch(g_iUserTeam[id]) {
		case 1: return Show_MainPnMenu(id);
		case 2: return Show_MainGrMenu(id);
		default: return Show_MainPnMenu(id);
	}
	return PLUGIN_HANDLED;
}

public ClCmd_Block(id) return PLUGIN_HANDLED;

public ClCmd_ChooseTeam(id) {
	switch(g_iUserTeam[id]) {
		case 1: Show_MainPnMenu(id);
		case 2: Show_MainGrMenu(id);
		default: Show_ChooseTeamMenu(id, 0);
	}
	return PLUGIN_HANDLED;
}

public ClCmd_MenuSelect(id) {
	client_cmd(id, "spk items/nvg_off.wav");
	jbe_informer_offset_down(id);
}

public ClCmd_MoneyTransfer(id, iTarget, iMoney) {
	if(!iTarget) {
		new szArg1[3], szArg2[7];
		read_argv(1, szArg1, charsmax(szArg1));
		read_argv(2, szArg2, charsmax(szArg2));
		if(!is_str_num(szArg1) || !is_str_num(szArg2)) {
			client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_ERROR_PARAMETERS");
			return PLUGIN_HANDLED;
		}
		iTarget = str_to_num(szArg1);
		iMoney = str_to_num(szArg2);
	}

	if(id == iTarget || !jbe_is_user_valid(iTarget) || IsNotSetBit(g_iBitUserConnected, iTarget)) client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_UNKNOWN_PLAYER");
	else if(jbe_get_user_money(id) < iMoney) client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_SUFFICIENT_FUNDS");
	else if(iMoney <= 0) client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_MIN_AMOUNT_TRANSFER");
	else {
		jbe_set_user_money(iTarget, jbe_get_user_money(iTarget) + iMoney, true);
		jbe_set_user_money(id, jbe_get_user_money(id) - iMoney, true);
		new szName[32], szNameTarget[32];
		get_user_name(id, szName, charsmax(szName));
		get_user_name(iTarget, szNameTarget, charsmax(szNameTarget));
		client_print_color(0, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ALL_MONEY_TRANSFER", szName, iMoney, szNameTarget);
	}
	return PLUGIN_HANDLED;
}

public ClCmd_Radio1(id) {
	if(g_iUserTeam[id] == 1 && IsSetBit(g_iBitClothingGuard, id)) {
		if(IsSetBit(g_iBitUserSoccer, id) || IsSetBit(g_iBitUserBoxing, id)) client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_BLOCKED_CLOTHING_GUARD");
		else {
			if(IsSetBit(g_iBitClothingType, id)) {
				jbe_set_user_model(id, g_szPlayerModel[PRISONER]);
				if(IsSetBit(g_iBitUserFree, id)) set_entvar(id, var_skin, 5);
				else if(IsSetBit(g_iBitUserWanted, id)) set_entvar(id, var_skin, 6);
				else set_entvar(id, var_skin, g_iUserSkin[id]);
				client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_REMOVE_CLOTHING_GUARD");
			}
			else {
				jbe_set_user_model(id, g_szPlayerModel[GUARD]);
				client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_DRESSED_CLOTHING_GUARD");
			}
			InvertBit(g_iBitClothingType, id);
		}
	}
	return PLUGIN_HANDLED;
}

public ClCmd_Radio2(id) {
	if(g_iUserTeam[id] == 1 && get_user_weapon(id) == CSW_KNIFE && (IsSetBit(g_iBitScrewdriver, id) || IsSetBit(g_iBitChainsaw, id))) {
		if(IsSetBit(g_iBitUserSoccer, id) || IsSetBit(g_iBitUserBoxing, id) || IsSetBit(g_iBitUserDuel, id)) {
			client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_SHOP_WEAPON_BLOCKED");
			return PLUGIN_HANDLED;
		}
		if(IsSetBit(g_iBitWeaponStatus, id) && IsSetBit(g_iBitChainsaw, id)) {
			client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_SHOP_WEAPON_HARD");
			return PLUGIN_HANDLED;
		}
		if(get_member(id, m_flNextAttack) < 0.1) {
			new iActiveItem = get_member(id, m_pActiveItem);
			if(iActiveItem > 0) {
				InvertBit(g_iBitWeaponStatus, id);
				ExecuteHamB(Ham_Item_Deploy, iActiveItem);
				UTIL_WeaponAnimation(id, 3);
			}
		}
	}
	return PLUGIN_HANDLED;
}

public ClCmd_Radio3(id) {
	if(g_iUserTeam[id] == 1 && IsSetBit(g_iBitLatchkey, id)) {
		new iTarget, iBody;
		get_user_aiming(id, iTarget, iBody, 30);
		if(is_entity(iTarget)) {
			new szClassName[32];
			pev(iTarget, pev_classname, szClassName, charsmax(szClassName));
			if(szClassName[5] == 'd' && szClassName[6] == 'o' && szClassName[7] == 'o' && szClassName[8] == 'r') {
				switch(random_num(0, ((g_iArmyList + 4) - g_iUserLevel[id]))) {
					case 0..4:  {
						dllfunc(DLLFunc_Use, iTarget, id);
						client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_DOOR_HACK_TRUE");
						
						if(random_num(0, ((g_iArmyList + 4) - g_iUserLevel[id])) <= 4) {
							ClearBit(g_iBitLatchkey, id);
							client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_DOOR_HACK_TRUE_CRASH");
						}
					}
					default: {
						ClearBit(g_iBitLatchkey, id);
						client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_DOOR_HACK_FALSE");
					}
				}
			}
			else client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_LATCHKEY_ERROR_DOOR");
		}
		else client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_LATCHKEY_ERROR_DOOR");
	}
	return PLUGIN_HANDLED;
}

public ClCmd_Drop(id) {
	if(IsSetBit(g_iBitUserDuel, id)) return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE;
}

public GetHookSpeed(id) {
	new szArgs[15];
	read_args(szArgs, charsmax(szArgs));
	remove_quotes(szArgs);
	
	if(strlen(szArgs) == 0) {
		client_print_color(id, print_team_red, "^1[^4INFO^1] Пустое значение ^3невозможно^1.");
		return Show_HookSetting(id);
	}
	for(new x; x < strlen(szArgs); x++){
		if(!isdigit(szArgs[x])) {
			client_print_color(id, print_team_red, "^1[^4INFO^1] Сумма должна быть только ^3числом^1.");
			return Show_HookSetting(id);
		}
	}
	new Float:fNum = str_to_float(szArgs);
	if(fNum > 210.0 || fNum < 100.0) {
		client_print_color(id, print_team_red, "^1[^4INFO^1] Число или слишком большое, или очень маленькое.");
		return Show_HookSetting(id);
	}
	if(fNum > 170.0 && IsNotSetBit(g_iBitUserGod, id)) {
		client_print_color(id, print_team_default, "^1[^4INFO^1] Только игрок с привилегией ^4GOD ^1может ставить такую скорость!");
		return Show_HookSetting(id);
	}
	g_fHookSpeed[id] = fNum;
	return Show_HookSetting(id);
}

public ClCmd_HookOn(id) {
	if(/*!equal("JBE_DAY_MODE_HIDE_ADN_SEEK", g_szDayMode) &&*/g_iDayMode == 3) return PLUGIN_HANDLED;
	
	if(jbe_all_users_wanted() || IsNotSetBit(g_iBitUserHook, id) && IsNotSetBit(g_iBitUserSkittlesHook, id) ||
	IsNotSetBit(g_iBitUserAlive, id) || IsSetBit(g_iBitUserSoccer, id) || IsSetBit(g_iBitUserBoxing, id) || 
	IsSetBit(g_iBitUserDuel, id) || task_exists(id+TASK_HOOK_THINK)) return PLUGIN_HANDLED;
	
	new iOrigin[3];
	get_user_origin(id, iOrigin, 3);
	g_vecHookOrigin[id][0] = float(iOrigin[0]);
	g_vecHookOrigin[id][1] = float(iOrigin[1]);
	g_vecHookOrigin[id][2] = float(iOrigin[2]);
	CREATE_SPRITE(g_vecHookOrigin[id], g_pSpriteRicho2, 10, 255);
	
	if(IsSetBit(g_iBitUserRandomHook, id)) {
		if(IsSetBit(g_iBitUserSkittlesHook, id)) g_iStatusHook[id] = random_num(1, 4);
		else if(IsSetBit(g_iBitUserGod, id)) g_iStatusHook[id] = random_num(1, 3);
		else if(IsSetBit(g_iBitUserKnyaz, id)) g_iStatusHook[id] = random_num(1, 2);
		else g_iStatusHook[id] = 1;
	}
	
	new szBuff[45];
	switch(g_iStatusHook[id]) {
		case 1: formatex(szBuff, charsmax(szBuff), "egoist/jb/%s", g_szSound[HOOK_WAV_A]);
		case 3: formatex(szBuff, charsmax(szBuff), "egoist/jb/%s", g_szSound[HOOK_WAV_B]);
		case 2: formatex(szBuff, charsmax(szBuff), "egoist/jb/%s", g_szSound[HOOK_WAV_C]);
		case 4: formatex(szBuff, charsmax(szBuff), "egoist/jb/%s", g_szSound[HOOK_WAV_V]);		
	}
	rh_emit_sound2(id, 0, CHAN_STATIC, szBuff, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	
	jbe_hook_think(id+TASK_HOOK_THINK);
	set_task(0.1, "jbe_hook_think", id+TASK_HOOK_THINK, _, _, "b");
	return PLUGIN_HANDLED;
}

public ClCmd_HookOff(id) {
	if(task_exists(id+TASK_HOOK_THINK)) {
		remove_task(id+TASK_HOOK_THINK);
		new szBuff[45];
		switch(g_iStatusHook[id]) {
			case 1: formatex(szBuff, charsmax(szBuff), "egoist/jb/%s", g_szSound[HOOK_WAV_A]);
			case 3: formatex(szBuff, charsmax(szBuff), "egoist/jb/%s", g_szSound[HOOK_WAV_B]);
			case 2: formatex(szBuff, charsmax(szBuff), "egoist/jb/%s", g_szSound[HOOK_WAV_C]);
			case 4: formatex(szBuff, charsmax(szBuff), "egoist/jb/%s", g_szSound[HOOK_WAV_V]);
		}
		rh_emit_sound2(id, 0, CHAN_STATIC, szBuff, VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);
	}
	return PLUGIN_HANDLED;
}
/*===== <- Консольные команды <- =====*///}

/*===== -> Менюшки -> =====*///{
#define PLAYERS_PER_PAGE 						8
#define RegisterMenu(%0,%1,%2) 					register_menucmd(register_menuid(%0), (%2), %1)

menu_init() {
	RegisterMenu("Show_ChooseTeamMenu", 	"Handle_ChooseTeamMenu", 	1<<0|1<<1|1<<4|1<<5|1<<8|1<<9);	
	//RegisterMenu("Show_SkinMenu", 			"Handle_SkinMenu", 			1<<0|1<<1|1<<2|1<<3|1<<4);	
	RegisterMenu("Show_WeaponsGuardMenu", 	"Handle_WeaponsGuardMenu", 	1<<0|1<<1|1<<2|1<<3|1<<4|1<<9);
	RegisterMenu("Show_MainPnMenu", 		"Handle_MainPnMenu", 		1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<9);	
	RegisterMenu("Show_MainGrMenu", 		"Handle_MainGrMenu", 		1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<9);
	RegisterMenu("Show_SettingMenu", 		"Handle_SettingMenu", 		1<<0|1<<1|1<<2|1<<3|1<<4|1<<9);	
	RegisterMenu("Show_PersonSetting", 		"Handle_PersonSetting", 	1<<0|1<<1|1<<2|1<<8|1<<9);		
	RegisterMenu("Show_HookSetting", 		"Handle_HookSetting", 		1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<8|1<<9);
	RegisterMenu("Show_OfficeMenu",			"Handle_OfficeMenu", 		1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<9);
	RegisterMenu("Show_PrivilegeMenu", 		"Handle_PrivilegeMenu", 	1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<9);	
	RegisterMenu("Show_ImageMenu", 			"Handle_ImageMenu", 		1<<0|1<<1|1<<9);
	RegisterMenu("Show_TouchGrWithPr", 		"Handle_TouchedGrWitchPr", 	1<<0|1<<1|1<<2|1<<3|1<<4|1<<9); // CT - T
	RegisterMenu("Show_TouchPrWithGr", 		"Handle_TouchedPrWitchGr", 	1<<0|1<<1|1<<2|1<<9); // T - CT
	RegisterMenu("Show_TouchPrWithPr", 		"Handle_ToucedPrWitchPr", 	1<<0|1<<1|1<<2|1<<3|1<<4|1<<9); // T - T
	RegisterMenu("Show_ShopGuardTradeMenu", "Handle_ShopGuardTradeMenu",1<<0|1<<1|1<<2|1<<9);
	//RegisterMenu("Show_ShopTattooMenu", 	"Handle_ShopTattooMenu", 	1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<9);
	RegisterMenu("Show_ShopPrisonersMenu", 	"Handle_ShopPrisonersMenu", 1<<0|1<<1|1<<2|1<<3|1<<4|1<<8|1<<9);
	RegisterMenu("Show_ShopWeaponsMenu", 	"Handle_ShopWeaponsMenu", 	1<<0|1<<1|1<<2|1<<3|1<<4|1<<9);
	RegisterMenu("Show_ShopItemsMenu", 		"Handle_ShopItemsMenu", 	1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9);
	RegisterMenu("Show_ShopSkillsMenu", 	"Handle_ShopSkillsMenu", 	1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<9);
	RegisterMenu("Show_ShopOtherMenu", 		"Handle_ShopOtherMenu", 	1<<0|1<<1|1<<2|1<<3|1<<4|1<<9);
	RegisterMenu("Show_PrankPrisonerMenu", 	"Handle_PrankPrisonerMenu", 1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9);
	RegisterMenu("Show_ShopGuardMenu", 		"Handle_ShopGuardMenu", 	1<<0|1<<1|1<<2|1<<3|1<<4|1<<8|1<<9);
	RegisterMenu("Show_MoneyTransferMenu", 	"Handle_MoneyTransferMenu", 1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9);
	RegisterMenu("Show_MoneyAmountMenu", 	"Handle_MoneyAmountMenu", 	1<<0|1<<1|1<<2|1<<3|1<<4|1<<7|1<<8|1<<9);
	RegisterMenu("Show_CostumesMenu", 		"Handle_CostumesMenu", 		1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9);
	RegisterMenu("Show_ChiefMenu_1", 		"Handle_ChiefMenu_1", 		1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9);
	RegisterMenu("Show_CountDownMenu", 		"Handle_CountDownMenu",		1<<0|1<<1|1<<2|1<<8|1<<9);
	RegisterMenu("Show_FreeDayControlMenu", "Handle_FreeDayControlMenu",1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9);
	RegisterMenu("Show_PunishGuardMenu", 	"Handle_PunishGuardMenu", 	1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9);
	RegisterMenu("Show_TransferChiefMenu", 	"Handle_TransferChiefMenu", 1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9);
	RegisterMenu("Show_TreatPrisonerMenu", 	"Handle_TreatPrisonerMenu", 1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9);
	RegisterMenu("Show_ChiefMenu_2", 		"Handle_ChiefMenu_2", 		1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9);
	RegisterMenu("Show_VoiceControlMenu", 	"Handle_VoiceControlMenu", 	1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9);
	RegisterMenu("Show_PrsnDColorMenu",		"Handle_PrsnDColorMenu",	1<<0|1<<1|1<<2|1<<8|1<<9);
	RegisterMenu("Show_MiniGameMenu", 		"Handle_MiniGameMenu", 		1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<8|1<<9);
	RegisterMenu("Show_ChiefGameMenu", 		"Handle_ChiefGameMenu", 	1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<8|1<<9);
	RegisterMenu("Show_ChiefWeaponsMenu", 	"Handle_ChiefWeaponsMenu", 	1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<8|1<<9);
	RegisterMenu("Show_RandomChiefNum", 	"Handle_RandomNum", 		1<<0|1<<1|1<<2|1<<8|1<<9);
	RegisterMenu("Show_SoccerMenu", 		"Handle_SoccerMenu", 		1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<8|1<<9);
	RegisterMenu("Show_SoccerTeamMenu", 	"Handle_SoccerTeamMenu", 	1<<0|1<<1|1<<5|1<<6|1<<7|1<<8|1<<9);
	RegisterMenu("Show_SoccerScoreMenu", 	"Handle_SoccerScoreMenu", 	1<<0|1<<1|1<<2|1<<3|1<<4|1<<8|1<<9);
	RegisterMenu("Show_BoxingMenu", 		"Handle_BoxingMenu", 		1<<0|1<<1|1<<2|1<<3|1<<8|1<<9);
	RegisterMenu("Show_BoxingTeamMenu", 	"Handle_BoxingTeamMenu", 	1<<0|1<<4|1<<5|1<<6|1<<8|1<<9);
	RegisterMenu("Show_KillReasonsMenu", 	"Handle_KillReasonsMenu", 	1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9);
	RegisterMenu("Show_KilledUsersMenu", 	"Handle_KilledUsersMenu", 	1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9);
	RegisterMenu("Show_LastPrisonerMenu", 	"Handle_LastPrisonerMenu", 	1<<0|1<<1|1<<2|1<<3|1<<4|1<<8|1<<9);
	RegisterMenu("Show_WhoPrizeDuelMenu", 	"Handle_WhoPrizeDuelMenu", 	1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9);
	RegisterMenu("Show_PrizeDuelMenu", 		"Handle_PrizeDuelMenu", 	1<<0|1<<1|1<<2|1<<3|1<<4|1<<9);
	RegisterMenu("Show_ChoiceDuelMenu", 	"Handle_ChoiceDuelMenu", 	1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<8|1<<9);
	RegisterMenu("Show_DuelUsersMenu", 		"Handle_DuelUsersMenu", 	1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9);
	RegisterMenu("Show_DayModeMenu", 		"Handle_DayModeMenu", 		1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9);
	RegisterMenu("Show_VipMenu", 			"Handle_VipMenu", 			1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<8|1<<9);
	RegisterMenu("Show_AdminMenu", 			"Handle_AdminMenu", 		1<<0|1<<1|1<<2|1<<3|1<<8|1<<9);
	RegisterMenu("Show_SuperAdminMenu", 	"Handle_SuperAdminMenu", 	1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<8|1<<9);
	RegisterMenu("Show_GodMenu", 			"Handle_GodMenu", 			1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<9);
	RegisterMenu("Show_BlockedGuardMenu", 	"Handle_BlockedGuardMenu", 	1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9);
	RegisterMenu("Show_BlockMenuFunction", 	"Handle_BlockMenuFunc", 	1<<0|1<<1|1<<2|1<<9);
	RegisterMenu("Show_ManageSoundMenu", 	"Handle_ManageSoundMenu", 	1<<0|1<<1|1<<2|1<<8|1<<9);
	RegisterMenu("Show_BuyAdminMenu", 		"Handle_BuyAdminMenu", 		1<<0|1<<1|1<<9);	
	RegisterMenu("Show_GoldModelsMenu",		"Handle_GoldModelsMenu",	1<<0|1<<1|1<<2|1<<3|1<<9);
}

Show_GoldModelsMenu(id) {
	jbe_informer_offset_up(id);
	new szMenu[1024], iKeys = (1<<0|1<<1|1<<2|1<<3|1<<9),
	iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_GOLD_MODELS_TITLE");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\y(1)\r ~ \w%L", id, "JBE_GOLD_MODELS_ONE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\y(2)\r ~ \w%L", id, "JBE_GOLD_MODELS_TWO");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\y(3)\r ~ \w%L", id, "JBE_GOLD_MODELS_THREE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\y(4)\r ~ \w%L", id, "JBE_GOLD_MODELS_FOUR");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\y[0]\r ~ \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_GoldModelsMenu");
}

public Handle_GoldModelsMenu(id, iKey) {
	if(IsSetBit(g_iBitUserWanted, id) || IsSetBit(g_iBitUserDuel, id) || jbe_menu_blocked(id)) return PLUGIN_HANDLED;
	new szName[32];
	get_user_name(id, szName, charsmax(szName));
	switch(iKey) {
		case 0: {
			jbe_set_user_model(id, "sinon");
			client_print_color(0, print_team_default, "^1[^4INFO^1] GOLD администратор^3 %s ^1взял модель ^3Синон", szName);
		}
		case 1: {
			jbe_set_user_model(id, "lucy");
			client_print_color(0, print_team_default, "^1[^4INFO^1] GOLD администратор^3 %s ^1взял модель ^3Люси", szName);
		}
		case 2: {
			jbe_set_user_model(id, "miku_rabbit");
			client_print_color(0, print_team_default, "^1[^4INFO^1] GOLD администратор^3 %s ^1взял модель ^3Зайка Мику", szName);
		}
		case 3: {
			jbe_set_user_model(id, "urbah");
			client_print_color(0, print_team_default, "^1[^4INFO^1] GOLD администратор^3 %s ^1взял модель ^3Marie 'Bunny Girl'", szName);
		}
	}
	return PLUGIN_HANDLED;
}

Show_BuyAdminMenu(id) {
	jbe_informer_offset_up(id);
	new szMenu[256], iKeys = (1<<0|1<<1|1<<9),
	iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_BUY_MENU");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(1) \y| \w%L", id, "JBE_BUY_CONTACTS");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(2) \y| \w%L", id, "JBE_BUY_GROUP");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_BuyAdminMenu");
}

public Handle_BuyAdminMenu(id, iKey) {
	switch(iKey) {
		case 0: {
			client_print_color(id, print_team_default, "^1[^4INFO^1] Наш Сайт:^4 %s ^1(Откройте Консоль)", g_szBuyContacts);
			client_print(id, print_console, "Наш Сайт: %s", g_szBuyContacts);
		}
		case 1: {
			client_print_color(id, print_team_default, "^1[^4INFO^1] Наша Группа ВК:^4 %s ^1(Откройте Консоль)", g_szBuyGroup);
			client_print(id, print_console, "Наша группа ВК: %s", g_szBuyGroup);
		}
		case 9: return PLUGIN_HANDLED;
	}
	return Show_BuyAdminMenu(id);
}

Show_ImageMenu(id) {
	jbe_informer_offset_up(id);
	new szMenu[256], iKeys = (1<<0|1<<1|1<<9),
	iLen = formatex(szMenu, charsmax(szMenu), "\yМеню Репутации^nВаш опыт: \r[%d]^n^n", g_iUserExp[id]);

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| %s%L \d", (g_iUserExp[id] < 1000 || g_iImageBlock[id][3] != 0)?"\d":"\w", id, "JBE_IMAGE_GLOCK18");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "%s", (g_iUserExp[id] < 1000) ? " [Нужно больше 1000 EXP]^n":"^n");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| %s%L \d", (g_iUserExp[id] < 400 || g_iImageBlock[id][4] != 0)?"\d":"\w", id, "JBE_IMAGE_HEALTH");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "%s", (g_iUserExp[id] < 400) ? " [Нужно больше 400 EXP]^n":"^n");

	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_ImageMenu");
}

public Handle_ImageMenu(id, iKey) {
	switch(iKey) {
		case 0: {
			if(g_iUserExp[id] < 1000)  {
				client_print_color(id, print_team_default, "^1[^4INFO^1] У Вас нету ^3знакомых^1 для мутки ^4игрушки^1!"); 
				return PLUGIN_HANDLED; 
			}
			if(g_iImageBlock[id][3] == 0) {
				g_iImageBlock[id][3] = 6;
				rg_give_item(id, "weapon_glock18", GT_REPLACE);
			}
			else client_print_color(id, print_team_default, "^1[^4INFO^1] У ^3братков ^4закончился ^3Glock^1, ждите^4 %d ^3дней", g_iImageBlock[id][3]);
		}
		case 1: {
			if(g_iUserExp[id] < 500) {
				client_print_color(id, print_team_default, "^1[^4INFO^1] У Вас нету ^4тортика^1!"); 
				return PLUGIN_HANDLED; 
			}
			if(g_iImageBlock[id][4] == 0) {
				g_iImageBlock[id][4] = 3;
				rg_set_user_health(id, Float:rg_get_user_health(id) + 255.0);
			}
			else client_print_color(id, print_team_default, "^1[^4INFO^1] У Вас^3 закончился ^4торт^1, ждите^4 %d ^3дней", g_iImageBlock[id][4]);
		}
		case 9: return PLUGIN_HANDLED;
	}
	g_iIdTouchPlayer[id] = 0;
	return Show_ImageMenu(id);
}

Show_TouchPrWithGr(id) {
	jbe_informer_offset_up(id);
	new szMenu[800], iKeys = (1<<2|1<<9), pName[32]; get_user_name(g_iIdTouchPlayer[id], pName, charsmax(pName));
	
	new iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_TOUCH",
	rg_get_user_team(g_iIdTouchPlayer[id]) == TEAM_TERRORIST ? "Заключенный":"Охранник", pName);

	if(IsNotSetBit(g_iBitUserSteal, id)) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_STEAL_MONEY", "%");
		iKeys |= (1<<0);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L^n", id, "JBE_STEAL_MONEY", "%");
	
	if(user_has_weapon(g_iIdTouchPlayer[id], CSW_DEAGLE)|| user_has_weapon(g_iIdTouchPlayer[id], CSW_USP)|| user_has_weapon(g_iIdTouchPlayer[id], CSW_GLOCK18)) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_STEAL_PISTOL", "%");
		iKeys |= (1<<1);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L [У игрока нету пистолета]^n", id, "JBE_STEAL_PISTOL", "%");
	
	if(g_iIdTouchPlayer[id] == g_iChiefId) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| %s%L", (g_iUserExp[id] < 400 || g_iImageBlock[id][0] != 0)?"\d":"\w", id, "JBE_IMAGE_FREEDAY");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "%s", (g_iUserExp[id] < 400) ? " [Нужно больше 400 EXP]^n":"^n");
	}
	else {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| %s%L", (g_iUserExp[id] < 200 || g_iImageBlock[id][1] != 0)?"\d":"\w", id, "JBE_IMAGE_STEAM_GRENADES");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "%s", (g_iUserExp[id] < 200) ? " [Нужно больше 200 EXP]^n":"^n");
	}
		
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, 1, "Show_TouchPrWithGr");
}

public Handle_TouchedPrWitchGr(id, iKey) {
	new pName[33], tName[33], iTarget = g_iIdTouchPlayer[id];
	get_user_name(iTarget, tName, charsmax(tName));
	get_user_name(id, pName, charsmax(pName));
	switch(iKey) {
		case 0: {
			SetBit(g_iBitUserSteal, id);
			switch(random_num(1, 2)) {
				case 1: {
					new iMoney = floatround(jbe_get_user_money(iTarget) / 10.0);
					jbe_set_user_money(id, jbe_get_user_money(id) + iMoney, true);
					jbe_set_user_money(iTarget, jbe_get_user_money(iTarget) - iMoney, true);
					client_print_color(id, print_team_default, "^1[^4INFO^1] Вы стащили у^3 %s^4 $%d", tName, iMoney);
					client_print_color(iTarget, print_team_default, "^1[^4INFO^1] Кто-то стащил у Вас^4 $%d", iMoney);
				}
				case 2: {
					client_print_color(0, print_team_red, "^1[^4INFO^1] Заключенный^4 %s ^1попытался стащить деньги у охранника^4 %s^1 - ^3неудачно", pName, tName);
					jbe_add_user_wanted(id);
				}
			}
		}
		case 1: {
			switch(random_num(1, 2)) {
				case 1: {
					if(user_has_weapon(iTarget, CSW_DEAGLE)) {
						rg_drop_item(iTarget, "weapon_deagle");
						rg_give_item(id, "weapon_deagle", GT_REPLACE);
					}
					else if(user_has_weapon(iTarget, CSW_GLOCK18))  {
						rg_drop_item(iTarget, "weapon_glock18");
						rg_give_item(id, "weapon_glock18", GT_REPLACE);
					}
					else if(user_has_weapon(iTarget, CSW_USP)) {
						rg_drop_item(iTarget, "weapon_usp");
						rg_give_item(id, "weapon_usp", GT_REPLACE);
					}
				}
				case 2: {
					client_print_color(0, print_team_red, "^1[^4INFO^1] Заключенный^3 %s ^1попытался стащить пистолет у охранника^3 %s ^1- ^3неудачно", pName, tName);
					jbe_add_user_wanted(id);
				}
			}
		}
		case 2: {
			if(iTarget == g_iChiefId) {
				if(g_iUserExp[id] < 400)  { 
					client_print_color(id, print_team_red, "^1[^4INFO^1] Те ^3навешают^1, олень!"); 
					return PLUGIN_HANDLED; 
				}
				if(g_iImageBlock[id][0] == 0) {
					g_iImageBlock[id][0] = 5;
					jbe_add_user_free(id);
				}
				else client_print_color(id, print_team_red, "^1[^4INFO^1] Саймон ^3не разрешает ^1выдавать Вам ^4выходной^1, приходите через^4 %d ^3дней", g_iImageBlock[id][0]);
			}
			else {
				if(g_iUserExp[id] < 240) { 
					client_print_color(id, print_team_default, "^1[^4INFO^1] ^4Мал ^1еще, иди гуляй!"); 
					return PLUGIN_HANDLED; 
				}
				if(get_user_weapon(iTarget) == CSW_SMOKEGRENADE || get_user_weapon(iTarget) == CSW_HEGRENADE || get_user_weapon(iTarget) == CSW_FLASHBANG) {
					if(g_iImageBlock[id][1] == 0) {
						g_iImageBlock[id][1] = 3;
						rg_give_item(id, "weapon_smokegrenade", GT_REPLACE);
						rg_give_item(id, "weapon_hegrenade", GT_REPLACE);
						rg_give_item(id, "weapon_flashbang", GT_REPLACE);
					}
					else client_print_color(id, print_team_blue, "^1[^4INFO^1] Вы уже тырили у ^3охраны ^4гранаты^1, ждите^4 %d ^3дней", g_iImageBlock[id][1]);
				}
				else client_print_color(id, print_team_blue, "^1[^4INFO^1] У ^3охранника ^1[^4закончились^1|^4нету ни одной^1] гранаты.");
			}
		}
		case 9: return PLUGIN_HANDLED;
	}
	g_iIdTouchPlayer[id] = 0;
	return PLUGIN_HANDLED;
}

Show_TouchPrWithPr(id) {
	jbe_informer_offset_up(id);
	new szMenu[512], iKeys = (1<<9), pName[32]; get_user_name(g_iIdTouchPlayer[id], pName, charsmax(pName));
	
	new iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_TOUCH",
	rg_get_user_team(g_iIdTouchPlayer[id]) == TEAM_TERRORIST ? "Заключенный":"Охранник", pName);

	if(IsNotSetBit(g_iBitUserPrBeat, id)) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_BEAT");
		iKeys |= (1<<0);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L [Вы уже дрались]^n", id, "JBE_BEAT");
	
	if(IsSetBit(g_iBitChainsaw, g_iIdTouchPlayer[id]) || IsSetBit(g_iBitScrewdriver, g_iIdTouchPlayer[id])) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L [У игрока уже есть оружие]^n", id, "JBE_GIVE_WEAPON");
	else if(IsNotSetBit(g_iBitWeaponStatus, id)) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L [У вас нету оружия в руках]^n", id, "JBE_GIVE_WEAPON");
	else if(IsSetBit(g_iBitScrewdriver, id) || IsSetBit(g_iBitChainsaw, id)) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_GIVE_WEAPON");
		iKeys |= (1<<1);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L [Error]^n", id, "JBE_GIVE_WEAPON");

	if(g_iUserExp[id] > g_iUserExp[g_iIdTouchPlayer[id]]) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| %s%L^n", (g_iImageBlock[id][0] != 0)?"\d":"\w", id, "JBE_IMAGE_PRESANUT");
		iKeys |= (1<<2);
	}
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, 1, "Show_TouchPrWithPr");
}

public Handle_ToucedPrWitchPr(id, iKey) {
	new pName[33], tName[33], iTarget = g_iIdTouchPlayer[id];
	get_user_name(iTarget, tName, charsmax(tName));
	get_user_name(id, pName, charsmax(pName));
	switch(iKey) {
		case 0: {
			new iFightPoints[33][2];	// 0 - Атакующий, 1 - защитник (iTarget)
			
			iFightPoints[id][0] = ujbl_get_protection_skills(id) + ujbl_get_agility_skills(id) + ujbl_get_lot_skills(id)
			+ (Float:rg_get_user_health(id) > 100.0 ? 1 : 0) + (floatround(rg_get_user_frags(id) / 2.0));
			
			iFightPoints[id][1] = ujbl_get_protection_skills(iTarget) + ujbl_get_agility_skills(iTarget) + ujbl_get_lot_skills(iTarget)
			+ (Float:rg_get_user_health(iTarget) > 100.0 ? 1 : 0) + (floatround(rg_get_user_frags(iTarget) / 2.0));
			
			client_cmd(id, "mp3 play sound/egoist/jb/%s", g_szSound[FIGTH_TRACK]);
			client_cmd(iTarget, "mp3 play sound/egoist/jb/%s", g_szSound[FIGTH_TRACK]);
			
			SetBit(g_iBitUserPrBeat, id);

			if(iFightPoints[id][0] == iFightPoints[id][1]) {
				client_print_color(id, print_team_default, "^1[^4INFO^1] Вы подрались с^4 %s^1. ^4Ничья^1. Сумма ваших скиллов:^3 %d ^1|^3 %d", tName, iFightPoints[id][0], iFightPoints[id][1]);
				client_print_color(iTarget, print_team_default, "^1[^4INFO^1] На Вас напал^4 %s^1. ^4Ничья^1. Сумма ваших скиллов:^3 %d ^1|^3 %d", pName, iFightPoints[id][1], iFightPoints[id][0]);
				return PLUGIN_HANDLED;
			}
			else if(iFightPoints[id][0] > iFightPoints[id][1]) {
				client_print_color(id, print_team_default, "^1[^4INFO^1] Вы избили^4 %s^1 и отобрали у него всякий хлам. ^4Победа^1. Сумма ваших скиллов:^3 %d ^1|^3 %d", tName, iFightPoints[id][0], iFightPoints[id][1]);
				client_print_color(iTarget, print_team_default, "^1[^4INFO^1] Вас избил^4 %s^1 и отобрал у вас всякий хлам. ^4Проигрыш^1. Сумма ваших скиллов:^3 %d ^1|^3 %dd", pName, iFightPoints[id][1], iFightPoints[id][0]);
				
				new iMoney = floatround(jbe_get_user_money(iTarget) / 10.0);
				jbe_set_user_money(iTarget, jbe_get_user_money(iTarget) - iMoney, true);
				jbe_set_user_money(id, jbe_get_user_money(id) + iMoney, true);
				
				new iArm = rg_get_user_armor(iTarget) / 10;
				rg_set_user_armor(id, rg_get_user_armor(id) + iArm, ARMOR_KEVLAR);
				rg_set_user_armor(iTarget, rg_get_user_armor(iTarget) - iArm, ARMOR_KEVLAR);
				
				if(Float:rg_get_user_health(iTarget) >= 20.0) rg_set_user_health(iTarget, Float:rg_get_user_health(iTarget) - 20.0);
				else rg_set_user_health(iTarget, 5.0);
				
				client_print_color(id, print_team_default, "^1[^4INFO^1] Вы отобрали у ^3защищающего^1:^4 $%d ^1и^4 %d ^1брони", iMoney, iArm);
				client_print_color(iTarget, print_team_default, "^1[^4INFO^1] У Вас отобрал ^3атакующий^1:^4 $%d ^1и^4 %d ^1брони", iMoney, iArm);
				
				return PLUGIN_HANDLED;
			}
			else if(iFightPoints[id][0] < iFightPoints[id][1]) {
				client_print_color(id, print_team_default, "^1[^4INFO^1] Вы попытались избить^4 %s^1, но проиграли. ^4Проигрыш^1. Сумма ваших скиллов:^3 %d ^1|^3 %d", tName, iFightPoints[id][0], iFightPoints[id][1]);
				client_print_color(iTarget, print_team_default, "^1[^4INFO^1] Вас попытался избить^4 %s^1 и вы ему навешали. ^4Победа^1. Сумма ваших скиллов:^3 %d ^1|^3 %d", pName, iFightPoints[id][1], iFightPoints[id][0]);
				
				new iMoney = floatround(jbe_get_user_money(id) / 10.0);
				jbe_set_user_money(iTarget, jbe_get_user_money(iTarget) + iMoney, true);
				jbe_set_user_money(id, jbe_get_user_money(id) - iMoney, true);
				
				new iArm = rg_get_user_armor(id) / 10;
				rg_set_user_armor(id, rg_get_user_armor(id) - iArm, ARMOR_KEVLAR);
				rg_set_user_armor(iTarget, rg_get_user_armor(iTarget) + iArm, ARMOR_KEVLAR);
				
				if(Float:rg_get_user_health(id) >= 20.0) rg_set_user_health(id, Float:rg_get_user_health(id) - 20.0);
				else rg_set_user_health(id, 5.0);
				
				client_print_color(iTarget, print_team_default, "^1[^4INFO^1] Вы отобрали у ^3нападающего^1:^4 $%d ^1и^4 %d ^1брони", iMoney, iArm);
				client_print_color(id, print_team_default, "^1[^4INFO^1] У Вас отобрал ^3защитник^1:^4 $%d ^1и^4 %d ^1брони", iMoney, iArm);
				
				return PLUGIN_HANDLED;
			}
			
		}
		case 1: {	
			new iActiveItem = get_member(id, m_pActiveItem);
			if(get_user_weapon(id) == CSW_KNIFE) jbe_default_knife_model(id);
			else {
				if(iActiveItem > 0) ExecuteHamB(Ham_Item_Deploy, iActiveItem);
			}
			if(IsSetBit(g_iBitScrewdriver, id))  {
				ClearBit(g_iBitScrewdriver, id);
				ClearBit(g_iBitWeaponStatus, id);
				SetBit(g_iBitScrewdriver, iTarget);
				SetBit(g_iBitWeaponStatus, iTarget);
				client_print_color(iTarget, print_team_default, "^1[^4INFO^1] Игрок^4 %s ^1передал вам ^4Отвертку^1.", pName);	
				if(iActiveItem > 0) ExecuteHamB(Ham_Item_Deploy, iActiveItem);			
				client_print_color(iTarget, print_team_default, "^1[^4INFO^1] %L", iTarget, "JBE_CHAT_ID_SHOP_WEAPON_HELP");
			}
			if(IsSetBit(g_iBitChainsaw, id)) {
				ClearBit(g_iBitChainsaw, id);
				ClearBit(g_iBitWeaponStatus, id);
				SetBit(g_iBitChainsaw, iTarget);
				SetBit(g_iBitWeaponStatus, iTarget);
				client_print_color(iTarget, print_team_default, "^1[^4INFO^1] Игрок^4 %s ^1передал вам ^4Бензопилу^1.", pName);
				if(iActiveItem > 0) ExecuteHamB(Ham_Item_Deploy, iActiveItem);
				client_print_color(iTarget, print_team_default, "^1[^4INFO^1] %L", iTarget, "JBE_CHAT_ID_SHOP_WEAPON_HELP");
			}
		}
		case 2: {
			if(g_iImageBlock[id][2] == 0) {
				g_iImageBlock[id][2] = 4;
				
				client_cmd(id, "mp3 play sound/egoist/jb/%s", g_szSound[FIGTH_TRACK]);
				client_cmd(iTarget, "mp3 play sound/egoist/jb/%s", g_szSound[FIGTH_TRACK]);
				
				new tMoney = jbe_get_user_money(iTarget) / 10;
				jbe_set_user_money(iTarget, jbe_get_user_money(iTarget) - tMoney, true);
				jbe_set_user_money(id, jbe_get_user_money(id) + tMoney, true);
				client_print_color(id, print_team_default, "^1[^4INFO^1] Вы пресанули^4 %s ^1на^4 $%d ^1из-за того Вы^4 '%s'^1, а он^4 '%s'", tName, tMoney, g_szRankName[id], g_szRankName[iTarget]);
				client_print_color(iTarget, print_team_default, "^1[^4INFO^1]^4 %s ^1пресанул Вас на^4 $%d из-за того что он^4 %s^1, а Вы ^4%s", pName, tMoney, g_szRankName[id], g_szRankName[iTarget]);
			}
			else client_print_color(id, print_team_default, "^1[^4INFO^1] Вы уже кого-то ^4мутузили^1, ждите^4 %d ^3дней", g_iImageBlock[id][2]);
		}
		case 9: return PLUGIN_HANDLED;
	}
	g_iIdTouchPlayer[id] = 0;
	return PLUGIN_HANDLED;
}

Show_TouchGrWithPr(id) {
	jbe_informer_offset_up(id);
	new szMenu[256], iKeys = (1<<9), pName[32]; get_user_name(g_iIdTouchPlayer[id], pName, charsmax(pName));
	
	new iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_TOUCH",
	jbe_get_user_team(g_iIdTouchPlayer[id]) == 1 ? "Заключенный":"Охранник", pName);

	if(IsSetBit(g_iBitUserShockerWp, id)){
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_BASH");
		iKeys |= (1<<0);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L \d[\wУ вас нету шокера, купите его у барыге\d]^n", id, "JBE_BASH");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| %s%L^n^n", rg_get_user_armor(g_iIdTouchPlayer[id]) >= 10.0 ? "\w":"\d", id, "JBE_ARMOR_PICKUP");
	
	if(rg_get_user_armor(g_iIdTouchPlayer[id]) >= 10.0) iKeys |= (1<<1);

	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, 1, "Show_TouchGrWithPr");
}

public Handle_TouchedGrWitchPr(id, iKey) {
	switch(iKey) {
		case 0: {
			if(IsNotSetBit(g_iBitUserShockerWp, id)) return PLUGIN_HANDLED;
			set_entvar(g_iIdTouchPlayer[id], var_punchangle, { 100.0, 200.0, 400.0 });
			set_entvar(g_iIdTouchPlayer[id], var_flags, get_entvar(g_iIdTouchPlayer[id], var_flags) | FL_FROZEN);
			set_task(2.0, "UnFreeze_TouchPlayer", g_iIdTouchPlayer[id] + TASK_UNPREEZE_TOUCHPLAYER);
		}
		case 1: {
			new pName[33], tName[33];
			get_user_name(g_iIdTouchPlayer[id], tName, charsmax(tName));
			get_user_name(id, pName, charsmax(pName));
			new p_Armor = rg_get_user_armor(id), t_Armor = rg_get_user_armor(g_iIdTouchPlayer[id]);
			rg_set_user_armor(id, p_Armor + 10, ARMOR_KEVLAR);
			rg_set_user_armor(g_iIdTouchPlayer[id], t_Armor - 10, ARMOR_KEVLAR);
			client_print_color(0, print_team_default, "^1[^4INFO^1] Охранник^4 %s^1 забрал 10 ед. брони у заключенного^4 %s", pName, tName);
		}
		case 9: return PLUGIN_HANDLED;
	}
	g_iIdTouchPlayer[id] = 0;
	return PLUGIN_HANDLED;
}

public UnFreeze_TouchPlayer(i) {
	i -= TASK_UNPREEZE_TOUCHPLAYER;
	set_entvar(i, var_flags, get_entvar(i, var_flags) & ~FL_FROZEN);
}

Show_PrivilegeMenu(id) {
	jbe_informer_offset_up(id);
	new szMenu[512], iKeys = (1<<9),
	iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_MAIN_TITLE");

	if(!g_iBlockFunction[1] && (g_iDayMode == 1 || g_iDayMode == 2) && IsSetBit(g_iBitUserVip, id) && g_iDuelStatus == 0) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_MAIN_VIP");
		iKeys |= (1<<0);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L^n", id, "JBE_MENU_MAIN_VIP");
	
	if(IsSetBit(g_iBitUserAdmin, id)) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_MENU_MAIN_ADMIN");
		iKeys |= (1<<1);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L^n", id, "JBE_MENU_MAIN_ADMIN");
	
	if(!g_iBlockFunction[1] && (g_iDayMode == 1 || g_iDayMode == 2) && IsSetBit(g_iBitUserSuperAdmin, id) && g_iDuelStatus == 0) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L^n", id, "JBE_MENU_MAIN_SUPER_ADMIN");
		iKeys |= (1<<2);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L^n", id, "JBE_MENU_MAIN_SUPER_ADMIN");
	
	if(!g_iBlockFunction[1] && (g_iDayMode == 1 || g_iDayMode == 2) && IsSetBit(g_iBitUserKnyaz, id) && g_iDuelStatus == 0) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L^n", id, "JBE_MENU_MAIN_KNYAZ");
		iKeys |= (1<<3);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L^n", id, "JBE_MENU_MAIN_KNYAZ");

	if(!g_iBlockFunction[1] && (g_iDayMode == 1 || g_iDayMode == 2) && IsSetBit(g_iBitUserCreater, id) && g_iDuelStatus == 0) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L^n", id, "JBE_MENU_MAIN_CREATE");
		iKeys |= (1<<4);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L^n", id, "JBE_MENU_MAIN_CREATE");

	if(!g_iBlockFunction[1] && (g_iDayMode == 1 || g_iDayMode == 2) && IsSetBit(g_iBitUserGod, id) && g_iDuelStatus == 0) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \w%L^n", id, "JBE_MENU_MAIN_GODMODE");
		iKeys |= (1<<5);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \d%L^n", id, "JBE_MENU_MAIN_GODMODE");

	if((g_iDayMode == 1 || g_iDayMode == 2) && IsSetBit(g_iBitUserGodMenu, id) && g_iDuelStatus == 0) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(7) \y| \w%L^n", id, "JBE_MENU_MAIN_GODMENU");
		iKeys |= (1<<6);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(7) \y| \d%L^n", id, "JBE_MENU_MAIN_GODMENU");

	if((g_iDayMode == 1 || g_iDayMode == 2) && IsSetBit(g_iBitUserOAIO, id) && g_iDuelStatus == 0) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(8) \y| \w%L^n", id, "JBE_MENU_MAIN_OAIOMENU");
		iKeys |= (1<<7);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(8) \y| \d%L^n", id, "JBE_MENU_MAIN_OAIOMENU");
	
	if(g_iBlockFunction[1]) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\dВнимание!^nСтоит глобальная блокировка привилегий!^nПросите куратора включить!^n");
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_PrivilegeMenu");
}

public Handle_PrivilegeMenu(id, iKey) {
	switch(iKey) {
		case 0: return Show_VipMenu(id);
		case 1: return Show_AdminMenu(id);
		case 2: return Show_SuperAdminMenu(id);	
		case 3: Open_KnyazMenu(id);
		case 4: Open_CreateMenu(id);
		case 5: Open_GodModeMenu(id);
		case 6: return Show_GodMenu(id);
		case 7: return Show_GoldModelsMenu(id);
		case 9: return PLUGIN_HANDLED;		
	}
	return PLUGIN_HANDLED;
}

Show_ChooseTeamMenu(id, iType) {
	jbe_informer_offset_up(id);
	new szMenu[512], iKeys, iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n", id, "JBE_MENU_TEAM_TITLE", g_iAllCvars[TEAM_BALANCE]);
	if(g_iUserTeam[id] != 1) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L \r[%d]^n", id, "JBE_MENU_TEAM_PRISONERS", g_iPlayersNum[1]);
		iKeys |= (1<<0);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L \r[%d]^n", id, "JBE_MENU_TEAM_PRISONERS", g_iPlayersNum[1]);
	
	if(!g_iBlockFunction[2]) {
		if(!jbe_menu_blocked(id)) {
			new iAbsNum = abs(g_iPlayersNum[1] - 1);
			if(iAbsNum <= 0) iAbsNum++;
			if(IsNotSetBit(g_iBitUserBlockedGuard, id) && g_iUserTeam[id] != 2 && (floatround((iAbsNum / float(g_iAllCvars[TEAM_BALANCE])), floatround_ceil) + 1) > g_iPlayersNum[2]) {
				iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L \r[%d]^n^n", id, "JBE_MENU_TEAM_GUARDS", g_iPlayersNum[2]);
				iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L^n", id, "JBE_MENU_TEAM_RANDOM");
				iKeys |= (1<<1|1<<4);
			}
			else
 {
				iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L \r[%d]^n^n", id, "JBE_MENU_TEAM_GUARDS", g_iPlayersNum[2]);
				iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L^n", id, "JBE_MENU_TEAM_RANDOM");
			}
		}
		else {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\wУ Вас стандартный ник! Доступ за КТ - закрыт^nПожалуйста, смените его и перезайдите^n\r(2) \y| \d%L \r[%d]^n^n", id, "JBE_MENU_TEAM_GUARDS", g_iPlayersNum[2]);
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L^n", id, "JBE_MENU_TEAM_RANDOM");
		}
	}
	else  {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L \r[%d] \d[\wСтоит глобальная блокировка\d]^n^n", id, "JBE_MENU_TEAM_GUARDS", g_iPlayersNum[2]);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L \d[\wСтоит глобальная блокировка\d]^n", id, "JBE_MENU_TEAM_RANDOM");
	}
	
	if(g_iUserTeam[id] != 3) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \w%L^n^n^n^n^n", id, "JBE_MENU_TEAM_SPECTATOR");
		iKeys |= (1<<5);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \d%L^n^n^n^n^n", id, "JBE_MENU_TEAM_SPECTATOR");

	if(iType) {
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
		iKeys |= (1<<9);
	}
	return show_menu(id, iKeys, szMenu, -1, "Show_ChooseTeamMenu");
}

public Handle_ChooseTeamMenu(id, iKey) {
	switch(iKey) {
		case 0: {
			if(g_iUserTeam[id] == 1) return Show_ChooseTeamMenu(id, 1);
			if(!jbe_set_user_team(id, 1)) return PLUGIN_HANDLED;
		}
		case 1: {
			if(g_iUserTeam[id] == 2) return Show_ChooseTeamMenu(id, 1);
			new abs_num = abs(g_iPlayersNum[1] - 1);
			if(abs_num > 0) {
				if(IsNotSetBit(g_iBitUserBlockedGuard, id) && ((abs_num / g_iAllCvars[TEAM_BALANCE]) + 1) > g_iPlayersNum[2]) {
					if(!jbe_set_user_team(id, 2)) return PLUGIN_HANDLED;
					jbe_informer_offset_down(id);
				}
			}
			else {
				if(g_iUserTeam[id] == 1) return Show_ChooseTeamMenu(id, 1);
				else return Show_ChooseTeamMenu(id, 0);
			}
		}
		case 4: {
			new abs_num = abs(g_iPlayersNum[1] - 1);
			if(abs_num == 0) abs_num = 2;
			if(((abs_num / g_iAllCvars[TEAM_BALANCE]) + 1) > g_iPlayersNum[2]) {
				switch(random_num(1, 2)) {
					case 1: if(!jbe_set_user_team(id, 1)) return PLUGIN_HANDLED;
					case 2: {
						if(!jbe_set_user_team(id, 2)) return PLUGIN_HANDLED;
						jbe_informer_offset_down(id);
					}
				}
			}
			else {
				if(g_iUserTeam[id] == 1 || g_iUserTeam[id] == 2) return Show_ChooseTeamMenu(id, 1);
				else return Show_ChooseTeamMenu(id, 0);
			}
		}
		case 5: {
			if(g_iUserTeam[id] == 3) return Show_ChooseTeamMenu(id, 0);
			if(!jbe_set_user_team(id, 3)) return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_HANDLED;
}

/*Show_ShopTattooMenu(id)
{
	jbe_informer_offset_up(id);
	new szMenu[512], iKeys = (1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_SHOPTATTOO_MENU_TITLE");
	
	if(g_iTattoo[id] != 1)
	{
		if(g_iUserExp[id] >= g_iAllCvars[TATTOO_BLOCK_1]) 
		{
			if(jbe_get_user_money(id) >= g_iShopCvars[TATTOO_COST_1])
			{
				iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \wНабить \r%L [%d$]^n", id, "JBE_SHOPTATTOO_TATTOO_1", g_iShopCvars[TATTOO_COST_1]);	
				iKeys |= (1<<0);
			}
			else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L [No $ | %d$]^n", id, "JBE_SHOPTATTOO_TATTOO_1", g_iShopCvars[TATTOO_COST_1]);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L [No exp | %d+]^n", id, "JBE_SHOPTATTOO_TATTOO_1", g_iAllCvars[TATTOO_BLOCK_1]);	
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L [Уже активна]^n", id, "JBE_SHOPTATTOO_TATTOO_1");

	if(g_iTattoo[id] != 2)
	{
		if(g_iUserExp[id] >= g_iAllCvars[TATTOO_BLOCK_2]) 
		{
			if(jbe_get_user_money(id) >= g_iShopCvars[TATTOO_COST_2])
			{
				iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \wНабить \r%L [%d$]^n", id, "JBE_SHOPTATTOO_TATTOO_2", g_iShopCvars[TATTOO_COST_2]);	
				iKeys |= (1<<1);
			}
			else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L [No $ | %d$]^n", id, "JBE_SHOPTATTOO_TATTOO_2", g_iShopCvars[TATTOO_COST_2]);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L [No exp | %d+]^n", id, "JBE_SHOPTATTOO_TATTOO_2", g_iAllCvars[TATTOO_BLOCK_2]);	
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L [Уже активна]^n", id, "JBE_SHOPTATTOO_TATTOO_2");

	if(g_iTattoo[id] != 3)
	{
		if(g_iUserExp[id] >= g_iAllCvars[TATTOO_BLOCK_3]) 
		{
			if(jbe_get_user_money(id) >= g_iShopCvars[TATTOO_COST_3])
			{
				iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \wНабить \r%L [%d$]^n", id, "JBE_SHOPTATTOO_TATTOO_3", g_iShopCvars[TATTOO_COST_3]);	
				iKeys |= (1<<2);
			}
			else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L [No $ | %d$]^n", id, "JBE_SHOPTATTOO_TATTOO_3", g_iShopCvars[TATTOO_COST_3]);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L [No exp | %d+]^n", id, "JBE_SHOPTATTOO_TATTOO_3", g_iAllCvars[TATTOO_BLOCK_3]);	
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L [Уже активна]^n", id, "JBE_SHOPTATTOO_TATTOO_3");

	if(g_iTattoo[id] != 4)
	{
		if(g_iUserExp[id] >= g_iAllCvars[TATTOO_BLOCK_4]) 
		{
			if(jbe_get_user_money(id) >= g_iShopCvars[TATTOO_COST_4])
			{
				iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \wНабить \r%L [%d$]^n", id, "JBE_SHOPTATTOO_TATTOO_4", g_iShopCvars[TATTOO_COST_4]);	
				iKeys |= (1<<3);
			}
			else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L [No $ | %d$]^n", id, "JBE_SHOPTATTOO_TATTOO_4", g_iShopCvars[TATTOO_COST_4]);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L [No exp | %d+]^n", id, "JBE_SHOPTATTOO_TATTOO_4", g_iAllCvars[TATTOO_BLOCK_4]);	
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L [Уже активна]^n", id, "JBE_SHOPTATTOO_TATTOO_4");

	if(g_iTattoo[id] != 5)
	{
		if(IsSetBit(g_iBitUserSuperAdmin, id))
		{
			if(jbe_get_user_money(id) >= g_iShopCvars[TATTOO_COST_5])
			{
				iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \wНабить \r%L \r[%d$]^n^n", id, "JBE_SHOPTATTOO_TATTOO_5", g_iShopCvars[TATTOO_COST_5]);	
				iKeys |= (1<<4);
			}
			else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L [No $ | %d$]^n^n", id, "JBE_SHOPTATTOO_TATTOO_5", g_iShopCvars[TATTOO_COST_5]);
		}
		else
		{
			if(g_iUserExp[id] >= g_iAllCvars[TATTOO_BLOCK_5]) 
			{
				if(jbe_get_user_money(id) >= g_iShopCvars[TATTOO_COST_5])
				{
					iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \wНабить \r%L [%d$]^n^n", id, "JBE_SHOPTATTOO_TATTOO_5", g_iShopCvars[TATTOO_COST_5]);	
					iKeys |= (1<<4);
				}
				else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L [No $ | %d$]^n^n", id, "JBE_SHOPTATTOO_TATTOO_5", g_iShopCvars[TATTOO_COST_5]);
			}
			else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L [No exp | %d+]^n^n", id, "JBE_SHOPTATTOO_TATTOO_5", g_iAllCvars[TATTOO_BLOCK_5]);	
		}
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L [Уже активна]^n^n", id, "JBE_SHOPTATTOO_TATTOO_5");

	if(g_iTattoo[id] != 0)
	{
		if(jbe_get_user_money(id) >= g_iShopCvars[TATTOO_COST_DELETE])
		{
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \r%L [%d$]^n^n", id, "JBE_SHOPTATTOO_TATTOO_6", g_iShopCvars[TATTOO_COST_DELETE]);	
			iKeys |= (1<<5);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \d%L [No $ | %d$]^n^n", id, "JBE_SHOPTATTOO_TATTOO_6", g_iShopCvars[TATTOO_COST_DELETE]);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \d%L [Нету татуировки]^n^n", id, "JBE_SHOPTATTOO_TATTOO_6");
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r(0) \y| \d%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_ShopTattooMenu");
}

public Handle_ShopTattooMenu(id, iKey)
{
	switch(iKey)
	{
		case 0:
		{
			g_iTraderMoney += g_iShopCvars[TATTOO_COST_1];
			jbe_set_user_money(id, jbe_get_user_money(id) - g_iShopCvars[TATTOO_COST_1], 1);
			g_iTattoo[id] = 1;
		}
		case 1:
		{
			g_iTraderMoney += g_iShopCvars[TATTOO_COST_2];
			jbe_set_user_money(id, jbe_get_user_money(id) - g_iShopCvars[TATTOO_COST_2], 1);
			g_iTattoo[id] = 2;
		}
		case 2:
		{
			g_iTraderMoney += g_iShopCvars[TATTOO_COST_3];
			jbe_set_user_money(id, jbe_get_user_money(id) - g_iShopCvars[TATTOO_COST_3], 1);
			g_iTattoo[id] = 3;
		}
		case 3:
		{
			g_iTraderMoney += g_iShopCvars[TATTOO_COST_4];
			jbe_set_user_money(id, jbe_get_user_money(id) - g_iShopCvars[TATTOO_COST_4], 1);
			g_iTattoo[id] = 4;
		}
		case 4:
		{
			g_iTraderMoney += g_iShopCvars[TATTOO_COST_5];
			jbe_set_user_money(id, jbe_get_user_money(id) - g_iShopCvars[TATTOO_COST_5], 1);
			g_iTattoo[id] = 5;
		}
		case 5:
		{
			g_iTraderMoney += g_iShopCvars[TATTOO_COST_DELETE];
			jbe_set_user_money(id, jbe_get_user_money(id) - g_iShopCvars[TATTOO_COST_DELETE], 1);
			g_iTattoo[id] = 0;
		}
		case 9: return PLUGIN_HANDLED;
	}
	formatex(g_szTattoo[id], charsmax(g_szTattoo[]), "models/jb_engine/%s%d.mdl", g_szModelView[TATTOO], g_iTattoo[id]);
	if(iKey < 5 && id != g_iAthrID &&  id != g_iSixPlID && id != g_iMedSisID && get_user_weapon(id) == CSW_KNIFE && IsNotSetBit(g_iBitWeaponStatus, id) && jbe_get_user_team(id) == 1) Set_TattoModel(id);
	return PLUGIN_HANDLED;
}

public Set_TattoModel(id)
{
	if(g_iTattoo[id] == 0 || g_iTattoo[id] > 5) return PLUGIN_HANDLED;
	new iszViewModel;
	if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, g_szTattoo[id]))) set_pev_string(id, pev_viewmodel2, iszViewModel);
	set_pdata_float(id, m_flNextAttack, 0.75);
	return PLUGIN_HANDLED;
}*/

Show_ShopGuardTradeMenu(id) {
	jbe_informer_offset_up(id);
	new szMenu[516], iKeys = (1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_GUARD_SHOP_TRADE_TITLE");
	
	if(IsNotSetBit(g_iBitUserShockerWp, id)) {
		if(jbe_get_user_money(id) >= 60) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L \d[60$]^n^n", id, "JBE_GUARD_SHOP_TRADE_SHOCKER");
			iKeys |= (1<<0);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L [Недостаточно денег]^n^n", id, "JBE_GUARD_SHOP_TRADE_SHOCKER");
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L [У Вас уже есть Шокер]^n^n", id, "JBE_GUARD_SHOP_TRADE_SHOCKER");
	
	if(g_iUserLevel[id] > 2) {
		if(jbe_get_user_money(id) >= 300) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L \d[300$]^n", id, "JBE_GUARD_SHOP_TRADE_M4A1");
			iKeys |= (1<<1);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L [Недостаточно денег]^n", id, "JBE_GUARD_SHOP_TRADE_M4A1");
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L \d[Ваш lvl мал(3+)]^n", id, "JBE_GUARD_SHOP_TRADE_M4A1");
	
	if(g_iUserLevel[id] > 2) {
		if(jbe_get_user_money(id) >= 600) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L \d[600$]^n", id, "JBE_GUARD_SHOP_TRADE_AK47");
			iKeys |= (1<<2);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L [Недостаточно денег]^n", id, "JBE_GUARD_SHOP_TRADE_AK47");
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L \d[Ваш lvl мал(3+)]^n", id, "JBE_GUARD_SHOP_TRADE_AK47");
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r(0) \y| \d%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, 1, "Show_ShopGuardTradeMenu");
}

public Handle_ShopGuardTradeMenu(id, iKey) {
	switch(iKey) {
		case 0: {
			g_iTraderMoney += 60;
			jbe_set_user_money(id, jbe_get_user_money(id) - 60, true);
			SetBit(g_iBitUserShockerWp, id);
			client_print_color(id, print_team_default, "^1[^4INFO^1] Вы купили ^4Шокер-Дубинку");
		}
		case 1: {
			g_iTraderMoney += 300;
			jbe_set_user_money(id, jbe_get_user_money(id) - 300, true);
			give_buffm4(id);
			client_print_color(id, print_team_default, "^1[^4INFO^1] Вы купили ^4M4A1 'Dark Knight'");
		}
		case 2: {
			g_iTraderMoney += 600;
			jbe_set_user_money(id, jbe_get_user_money(id) - 600, true);
			give_buffak(id);
			client_print_color(id, print_team_default, "^1[^4INFO^1] Вы купили ^4AK-47 'Paladin'");
		}
		case 9: return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}

/*Show_SkinMenu(id) {
	jbe_informer_offset_up(id);
	jbe_menu_block(id);
	new szMenu[256], iKeys = (1<<0|1<<1|1<<2|1<<3), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_SKIN_TITLE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_SKIN_ORANGE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_MENU_SKIN_GRAY");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L^n", id, "JBE_MENU_SKIN_YELLOW");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L^n", id, "JBE_MENU_SKIN_BLUE");
	if(IsSetBit(g_iBitUserAdmin, id)) {
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L", id, "JBE_MENU_SKIN_BLACK");
		iKeys |= (1<<4);
	}
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L", id, "JBE_MENU_SKIN_BLACK");
	return show_menu(id, iKeys, szMenu, -1, "Show_SkinMenu");
}

public Handle_SkinMenu(id, iKey) {
	g_iUserSkin[id] = iKey;
	rg_join_team(id, TEAM_TERRORIST);
	//rg_set_user_team(id, TEAM_TERRORIST, MODEL_AUTO, true);
	g_iUserTeam[id] = 1;
	jbe_menu_unblock(id);
}*/

public GiveRandomCTweapon(id) {
	id -= TASK_RANDOM_WEAPON;
	if(IsSetBit(g_iBitUserAlive, id) && g_iUserTeam[id] == 2) Handle_WeaponsGuardMenu(id, random_num(0, 3));
}

Show_WeaponsGuardMenu(id) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || IsNotSetBit(g_iBitUserAlive, id) || g_iUserTeam[id] != 2) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new szMenu[512], iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_WEAPONS_GUARD_TITLE"), iKeys = (1<<0|1<<1|1<<2|1<<3|1<<9);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_WEAPONS_GUARD_AK47");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_MENU_WEAPONS_GUARD_M4A1");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L^n", id, "JBE_MENU_WEAPONS_GUARD_AWP");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L^n^n", id, "JBE_MENU_WEAPONS_GUARD_XM1014");
	if(IsSetBit(g_iBitUserSuperAdmin, id)) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L^n^n^n^n^n^n", id, "JBE_MENU_WEAPONS_GUARD_CV47");
		iKeys |= (1<<4);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L \d[\wСупер-Админ\d]^n^n^n^n^n^n", id, "JBE_MENU_WEAPONS_GUARD_CV47");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, 10, "Show_WeaponsGuardMenu");
}

public Handle_WeaponsGuardMenu(id, iKey) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || iKey == 9) {
		if(g_iBitKilledUsers[id]) return Cmd_KilledUsersMenu(id);
		return PLUGIN_HANDLED;
	}
	
	new const szWeaponName[][] = {"weapon_ak47", "weapon_m4a1", "weapon_awp", "weapon_xm1014", "weapon_deagle"};
	
	rg_remove_all_items(id, false);
	rg_give_item(id, "weapon_knife", GT_APPEND);
	
	if(task_exists(id + TASK_RANDOM_WEAPON)) remove_task(id + TASK_RANDOM_WEAPON);
	
	if(iKey == 4) ujbl_give_weapon(id);
	else {
		rg_give_item(id, szWeaponName[iKey], GT_REPLACE);
		switch(iKey) {
			case 0: rg_set_user_bpammo(id, WEAPON_AK47, 250);
			case 1: rg_set_user_bpammo(id, WEAPON_M4A1, 250);
			case 2: rg_set_user_bpammo(id, WEAPON_AWP, 250);
			case 3: rg_set_user_bpammo(id, WEAPON_XM1014, 250);
		}
	}
	
	if(IsSetBit(g_iBitUserAdmin, id)) ujbl_give_pistol(id);
	else {
		rg_give_item(id, "weapon_deagle", GT_REPLACE);
		rg_set_user_bpammo(id, WEAPON_DEAGLE, 250);
	}
	
	rg_give_item(id, "item_kevlar", GT_APPEND);
	rg_set_user_health(id, Float:rg_get_user_health(id) + 50.0);

	if(g_iBitKilledUsers[id]) return Cmd_KilledUsersMenu(id);
	return PLUGIN_HANDLED;
}

Show_MainPnMenu(id) {
	jbe_informer_offset_up(id);
	new szMenu[1024], iKeys = (1<<1|1<<4|1<<5|1<<7|1<<9), iUserAlive = IsSetBit(g_iBitUserAlive, id),
	iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_MAIN_TITLE");
	
	if(!g_iBlockFunction[0]) {
		if(iUserAlive && (g_iDayMode == 1 || g_iDayMode == 2) && IsNotSetBit(g_iBitUserDuel, id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n^n", id, "JBE_MENU_MAIN_SHOP");
			iKeys |= (1<<0);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L^n^n", id, "JBE_MENU_MAIN_SHOP");
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L [Стоит Глобальная Блокировка]^n^n", id, "JBE_MENU_MAIN_SHOP");
	
	if(g_iDayMode == 3 || g_iDuelStatus > 0) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n\r(3) \y| \d%L^n^n", id, "JBE_SETTING_MENU_TITLE", id, "JBE_OFFICE_MENU_TITLE");
	else {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n\r(3) \y| \w%L^n^n", id, "JBE_SETTING_MENU_TITLE", id, "JBE_OFFICE_MENU_TITLE");
		iKeys |= (1<<2);
	}

	if(id == g_iLastPnId && iUserAlive) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L^n", id, "JBE_MENU_MAIN_LAST_PN");
		iKeys |= (1<<3);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L^n", id, "JBE_MENU_MAIN_LAST_PN");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L^n^n", id, "JBE_MENU_MAIN_TEAM");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \w%L^n^n", id, "JBE_MENU_MAIN_PRIVILEGE");
	
	if(g_iDayMode != 1) {
		iKeys |= (1<<6);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(7) \y| \w%L^n", id, "JBE_MENU_MAIN_OPEN_DOORS");
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(7) \y| \d%L^n", id, "JBE_MENU_MAIN_OPEN_DOORS");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(8) \y| \w%L^n^n", id, "JBE_MENU_MAIN_BUY_ADMIN");
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_MainPnMenu");
}

public Handle_MainPnMenu(id, iKey) {
	switch(iKey) {
		case 0: if((g_iDayMode == 1 || g_iDayMode == 2) && IsSetBit(g_iBitUserAlive, id) && IsNotSetBit(g_iBitUserDuel, id)) return Show_ShopPrisonersMenu(id, 1);
		case 1: return Show_SettingMenu(id);
		case 2: return Show_OfficeMenu(id);
		case 3: if(id == g_iLastPnId && IsSetBit(g_iBitUserAlive, id)) return Show_LastPrisonerMenu(id);
		case 4: return Show_ChooseTeamMenu(id, 1);
		case 5: return Show_PrivilegeMenu(id);
		case 6: jbe_open_doors();
		case 7: return Show_BuyAdminMenu(id);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_MainPnMenu(id);
}

Show_OfficeMenu(id) {
	jbe_informer_offset_up(id);
	new szMenu[512], iKeys = (1<<4|1<<5|1<<9), iAlive = IsSetBit(g_iBitUserAlive, id),
	iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_OFFICE_MENU_TITLE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| %s%L^n", (iAlive && jbe_get_day_mode() != 3) ? "\w":"\d", id, "JBE_OFFICE_KEY_1");
	
	if(g_iUserLevel[id] > 2)  {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n^n", id, "JBE_OFFICE_KEY_2");
		iKeys |= (1<<1);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L [Ваш lvl мал(3+)]^n^n", id, "JBE_OFFICE_KEY_2");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| %s%L^n", (g_iUserTeam[id] == 1) ? "\w":"\d", id, "JBE_OFFICE_KEY_3");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| %s%L^n^n", (iAlive && jbe_get_day_mode() != 3 && g_iUserTeam[id] == 1) ? "\w":"\d", id, "JBE_OFFICE_KEY_4");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L^n", id, "JBE_OFFICE_KEY_5");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \w%L^n", id, "JBE_OFFICE_KEY_6");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(7) \y| %s%L^n^n", (iAlive && jbe_get_day_mode()) ? "\w":"\d", id, "JBE_OFFICE_KEY_7");
	
	if(g_iUserTeam[id] == 1) iKeys |= (1<<2);
	if(iAlive && jbe_get_day_mode() != 3) iKeys |= (1<<0|1<<6);
	if(iAlive && jbe_get_day_mode() != 3 && g_iUserTeam[id] == 1) iKeys |= (1<<3);
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_OfficeMenu");
	
}

public Handle_OfficeMenu(id, iKey) {
	switch(iKey) {
		case 0: jbe_open_fortune_menu(id);
		case 1: ujbl_open_bank(id);
		case 2: ujbl_open_gang_menu(id);
		case 3: Show_ImageMenu(id);
		case 4: jbe_open_skills_menu(id);
		case 5: client_cmd(id, "say /dice");
		case 6: Open_DrugsMenu(id);
	}
	return PLUGIN_HANDLED;
}

Show_SettingMenu(id) {
	jbe_informer_offset_up(id);
	new szMenu[512], iKeys = (1<<2|1<<3|1<<4|1<<9),
	iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_SETTING_MENU_TITLE");
	
	if(IsSetBit(g_iBitUserHook, id)) {
		if(!task_exists(id + TASK_HOOK_THINK)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_MAIN_MANAGE_HOOK");
			iKeys |= (1<<0);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L \r[Отпустите палец с кнопки!]^n", id, "JBE_MENU_MAIN_MANAGE_HOOK");
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L^n", id, "JBE_MENU_MAIN_MANAGE_HOOK");
	
	if(g_iDayMode != 3) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n^n", id, "JBE_MENU_MAIN_PERSON");
		iKeys |= (1<<1);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L (Игровой)^n^n", id, "JBE_MENU_MAIN_PERSON");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L^n^n", id, "JBE_MENU_MAIN_MANAGE_SOUND");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L^n", id, "JBE_MENU_MAIN_MONEY_TRANSFER");	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L^n", id, "JBE_MENU_MAIN_CLEAR_CHAT");

	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_SettingMenu");
}

public Handle_SettingMenu(id, iKey) {
	switch(iKey) {
		case 0: return Show_HookSetting(id);
		case 1: return Show_PersonSetting(id);
		case 2: return Show_ManageSoundMenu(id);
		case 3: return Cmd_MoneyTransferMenu(id);
		case 4: {
			for(new text = 5; text != 0; text--) client_print(id, print_chat, " ");
		}
		case 9: return PLUGIN_HANDLED;
	}
	return Show_SettingMenu(id);
}

Show_PersonSetting(id) {
	jbe_informer_offset_up(id);
	new szMenu[256], iKeys = (1<<8|1<<9),
	iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_SETTING_PERSON_MENU_TITLE");
	
	if(g_eUserCostumes[id][ACCES_FLAGS] <= 1) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_MAIN_COSTUMES");
		iKeys |= (1<<0);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L [На Вас надета VIP шапка]^n", id, "JBE_MENU_MAIN_COSTUMES");
	
	if(g_eUserCostumes[id][ACCES_FLAGS] == 2 || !g_eUserCostumes[id][ACCES_FLAGS]) {
		if(IsSetBit(g_iBitUserVip, id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L \r[VIP]^n", id, "JBE_MENU_MAIN_COSTUMES");
			iKeys |= (1<<1);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L \d[VIP]^n", id, "JBE_MENU_MAIN_COSTUMES");
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L \d[На Вас надета обычная шапка]^n", id, "JBE_MENU_MAIN_COSTUMES");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(9) \y| \w%L", id, "JBE_MENU_BACK");	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_PersonSetting");
}

public Handle_PersonSetting(id, iKey) {
	switch(iKey) {
		case 0: {
			g_iCostumes[id] = 1;
			return Cmd_CostumesMenu(id, 1); 
		}
		case 1: {
			g_iCostumes[id] = 2;
			return Cmd_CostumesMenu(id, 2);
		}
		case 8: return Show_SettingMenu(id);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_PersonSetting(id);
}

Show_HookSetting(id) {
	jbe_informer_offset_up(id);
	new szMenu[512], iKeys = (1<<0|1<<5|1<<8|1<<9),
	iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_SETTING_HOOK_TITLE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L%s^n^n", id, "JBE_SETTING_HOOK_RANDOM_HOOK", IsSetBit(g_iBitUserRandomHook, id) ? " \y[Выбран]":"");
	iKeys |= (1<<1);
	
	if(IsSetBit(g_iBitUserRandomHook, id)) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L^n", id, "JBE_SETTING_HOOK_LIGHTNING");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L^n", id, "JBE_SETTING_HOOK_RAINBOW");	
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L^n", id, "JBE_SETTING_HOOK_BLUE");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \dРадужный хук^n");	
		
		if(IsSetBit(g_iBitUserGod, id)) iKeys |= (1<<2);
		if(IsSetBit(g_iBitUserKnyaz, id)) iKeys |= (1<<3);
		if(IsSetBit(g_iBitUserSkittlesHook, id)) iKeys |= (1<<4);
	}
	else {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L%s^n", id, "JBE_SETTING_HOOK_LIGHTNING", g_iStatusHook[id] == 1 ? " \y[Выбран]":"");
	
		if(IsSetBit(g_iBitUserKnyaz, id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L%s^n", id, "JBE_SETTING_HOOK_RAINBOW", g_iStatusHook[id] == 2 ? " \y[Выбран]":"");	
			iKeys |= (1<<2);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L%s^n", id, "JBE_SETTING_HOOK_RAINBOW", g_iStatusHook[id] == 2 ? " \y[Выбран]":"");	
		
		if(IsSetBit(g_iBitUserGod, id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L%s^n", id, "JBE_SETTING_HOOK_BLUE", g_iStatusHook[id] == 3 ? " \y[Выбран]":"");
			iKeys |= (1<<3);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L%s^n", id, "JBE_SETTING_HOOK_BLUE", g_iStatusHook[id] == 3 ? " \y[Выбран]":"");	
		
		if(IsSetBit(g_iBitUserSkittlesHook, id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \wРадужный хук%s^n", g_iStatusHook[id] == 4 ? " \y[Выбран]":"");
			iKeys |= (1<<4);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \dРадужный хук%s^n", g_iStatusHook[id] == 4 ? " \y[Выбран]":"");	
	}
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \w%L^n", id, "JBE_SETTING_HOOK_SPEED", floatround(g_fHookSpeed[id]));
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L", id, "JBE_MENU_BACK");	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_HookSetting");
}

public Handle_HookSetting(id, iKey) {
	switch(iKey) {
		case 0: SetBit(g_iBitUserRandomHook, id);
		case 1: {
			if(task_exists(id + TASK_HOOK_THINK)) {
				client_print_color(id, print_team_default, "^1[^4INFO^1] Вы используете ^4хук^1!");
				return Show_SettingMenu(id);
			}
			g_iStatusHook[id] = 1;
			ClearBit(g_iBitUserRandomHook, id);
		}
		case 2: {
			if(task_exists(id + TASK_HOOK_THINK)) {
				client_print_color(id, print_team_default, "^1[^4INFO^1] Вы используете ^4хук^1!");
				return Show_SettingMenu(id);
			}
			g_iStatusHook[id] = 2;
			ClearBit(g_iBitUserRandomHook, id);
		}
		case 3: {
			if(task_exists(id + TASK_HOOK_THINK)) {
				client_print_color(id, print_team_default, "^1[^4INFO^1] Вы используете ^4хук^1!");
				return Show_SettingMenu(id);
			}
			g_iStatusHook[id] = 3;
			ClearBit(g_iBitUserRandomHook, id);
		}
		case 4: {
			if(task_exists(id + TASK_HOOK_THINK)) {
				client_print_color(id, print_team_default, "^1[^4INFO^1] Вы используете ^4хук^1!");
				return Show_SettingMenu(id);
			}
			g_iStatusHook[id] = 4;
			ClearBit(g_iBitUserRandomHook, id);
		}
		case 5: client_cmd(id, "messagemode hook_speed");
		case 8: return Show_SettingMenu(id);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_HookSetting(id);
}

stock jbe_status_informer_valid(id) {
	switch(g_iInformerStatus[id]) {
		case true: remove_task(id + TASK_SHOW_INFORMER);
		case false: set_task(INFORMER_SECOND_UPDATE, "jbe_team_informer", id+TASK_SHOW_INFORMER, _, _, "b" );		
	}
}

Show_MainGrMenu(id) 
{
	jbe_informer_offset_up(id);
	new szMenu[1024], iKeys = (1<<1|1<<4|1<<5|1<<6|1<<9), iUserAlive = IsSetBit(g_iBitUserAlive, id),
	iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_MAIN_TITLE");
	
	if(!g_iBlockFunction[0]) 
	{
		if(iUserAlive && (g_iDayMode == 1 || g_iDayMode == 2) && IsNotSetBit(g_iBitUserDuel, id)) 
		{
			if(!jbe_all_users_wanted()) 
			{
				iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n^n", id, "JBE_MENU_MAIN_SHOP");
				iKeys |= (1<<0);
			}
			else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L [Недоступно во время розыска]^n^n", id, "JBE_MENU_MAIN_SHOP");
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L^n^n", id, "JBE_MENU_MAIN_SHOP");
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L [Стоит Глобальная Блокировка]^n^n", id, "JBE_MENU_MAIN_SHOP");
	
	if(g_iDayMode == 3 || g_iDuelStatus > 0) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n\r(3) \y| \d%L^n^n", id, "JBE_SETTING_MENU_TITLE", id, "JBE_OFFICE_MENU_TITLE");
	else 
	{
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n\r(3) \y| \w%L^n^n", id, "JBE_SETTING_MENU_TITLE", id, "JBE_OFFICE_MENU_TITLE");
		iKeys |= (1<<2);
	}
	
	if(iUserAlive && (g_iDayMode == 1))
	{
		if(id == g_iChiefId && g_iDuelStatus == 0)
		{
			iLen += formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r(4) \y| \w%L^n", id, "JBE_MENU_MAIN_CHIEF" );
			iKeys |= (1<<3);
		}
		else if(g_iChiefStatus != 1 && (g_iChiefIdOld != id || g_iChiefStatus != 0) && g_iDuelStatus == 0)
		{				
			iLen += formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r(4) \y| \w%L^n", id, "JBE_MENU_MAIN_TAKE_CHIEF" );
			iKeys |= (1<<3);
		}
		else iLen += formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r(4) \y| \d%L^n", id, "JBE_MENU_MAIN_TAKE_CHIEF" );
	}
	else if(g_iDayWeek == 1 && g_iDayMode == 2) iLen += formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r(4) \y| \d%L \r[Понедельник]^n", id, "JBE_MENU_MAIN_TAKE_CHIEF" );
	else iLen += formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r(4) \y| \d%L^n", id, "JBE_MENU_MAIN_TAKE_CHIEF" );
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L^n^n", id, "JBE_MENU_MAIN_TEAM");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \w%L^n^n", id, "JBE_MENU_MAIN_PRIVILEGE");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(7)\y | \w%L^n^n", id, "JBE_MENU_MAIN_BUY_ADMIN");
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_MainGrMenu");
}

public Handle_MainGrMenu(id, iKey) {
	switch(iKey) {
		case 0: return Show_ShopGuardMenu(id);		
		case 1: return Show_SettingMenu(id);
		case 2: return Show_OfficeMenu(id);
		case 3: 
		{
			if((g_iDayMode == 1) && IsSetBit(g_iBitUserAlive, id))
			{
				if(id == g_iChiefId) return Show_ChiefMenu_1(id);
				if(g_iChiefStatus != 1 && (g_iChiefIdOld != id || g_iChiefStatus != 0) && jbe_set_user_chief(id))
				{
					g_iChiefIdOld = id;
					return Show_ChiefMenu_1(id);
				}
			}
		}
		case 4: return Show_ChooseTeamMenu(id, 1);
		case 5: return Show_PrivilegeMenu(id);
		case 6: return Show_BuyAdminMenu(id);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_MainGrMenu(id);
}

public CheckDistanceTrader(id) {
	id -= TASK_TRADER_DISTANCE;
	
	if(bIsNotSetModBit(g_bBuyTime) || !jbe_is_user_alive(id)) {
		remove_task(id + TASK_TRADER_DISTANCE);
		return PLUGIN_HANDLED;
	}
	
	if(g_fLastOriginTrader[id][0] == 0.0 && g_fLastOriginTrader[id][1] == 0.0 && g_fLastOriginTrader[id][2] == 0.0) {
		remove_task(id + TASK_TRADER_DISTANCE);
		return PLUGIN_HANDLED;
	}
	
	new Float:fOrigin[3], Float:fDist;
	get_entvar(id, var_origin, fOrigin);
	fDist = get_distance_f(fOrigin, g_fLastOriginTrader[id]);
	
	if(fDist <= 150) {
		remove_task(id + TASK_TRADER_DISTANCE);
		return PLUGIN_HANDLED;
	}
	
	client_print_color(id, print_team_default, "^1[^4INFO^1] Вы далеко отошли от ^4Yuri Senpai^1!");
	remove_task(id + TASK_TRADER_DISTANCE);
	show_menu(id, 0, "^n");
	return PLUGIN_HANDLED;
	
}

Show_ShopPrisonersMenu(id, iType) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || IsNotSetBit(g_iBitUserAlive, id) || IsSetBit(g_iBitUserDuel, id)) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	jbe_set_user_discount(id);
	new szMenu[512], iLen, iKeys = (1<<3|1<<9);
	
	iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n", id, "JBE_MENU_SHOP_PRISONERS_TR_TITLE", g_iTraderMoney, g_iUserDiscount[id]);

	if(iType) {
		if(bIsSetmodBit(g_bBuyTime)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L [\r30 секунд прошло\d]^n", id, "JBE_MENU_SHOP_PRISONERS_WEAPONS");
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L [\r30 секунд прошло\d]^n", id, "JBE_MENU_SHOP_PRISONERS_ITEMS");
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L [\r30 секунд прошло\d]^n", id, "JBE_MENU_SHOP_PRISONERS_SKILLS");
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L^n", id, "JBE_MENU_SHOP_PRISONERS_OTHER");
			//iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L [\r30 секунд прошло\d]^n", id, "JBE_MENU_SHOP_PRISONERS_SHOPTATTOO");
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L [\r30 секунд прошло\d]^n^n^n^n", id, "JBE_MENU_SHOP_PRISONERS_DRUGSSHOP");		
		}
		else {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_SHOP_PRISONERS_WEAPONS");
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_MENU_SHOP_PRISONERS_ITEMS");
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L^n", id, "JBE_MENU_SHOP_PRISONERS_SKILLS");
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L^n", id, "JBE_MENU_SHOP_PRISONERS_OTHER");
			//iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L^n", id, "JBE_MENU_SHOP_PRISONERS_SHOPTATTOO");
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L^n^n^n^n", id, "JBE_MENU_SHOP_PRISONERS_DRUGSSHOP");
			iKeys |= (1<<0|1<<1|1<<2|1<<4);
		}
	}
	else {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_SHOP_PRISONERS_WEAPONS");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_MENU_SHOP_PRISONERS_ITEMS");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L^n", id, "JBE_MENU_SHOP_PRISONERS_SKILLS");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L^n", id, "JBE_MENU_SHOP_PRISONERS_OTHER");
		//iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L^n", id, "JBE_MENU_SHOP_PRISONERS_SHOPTATTOO");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L^n^n^n^n", id, "JBE_MENU_SHOP_PRISONERS_DRUGSSHOP");
		iKeys |= (1<<0|1<<1|1<<2|1<<4);
	}
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L", id, "JBE_MENU_BACK");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_ShopPrisonersMenu");
}

public Handle_ShopPrisonersMenu(id, iKey) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || IsNotSetBit(g_iBitUserAlive, id) || IsSetBit(g_iBitUserDuel, id)) return PLUGIN_HANDLED;
	switch(iKey) {
		case 0: return Show_ShopWeaponsMenu(id);
		case 1: return Show_ShopItemsMenu(id);
		case 2: return Show_ShopSkillsMenu(id);
		case 3: return Show_ShopOtherMenu(id);
		//case 4: return Show_ShopTattooMenu(id);
		case 4: {
			Open_TraderDrugsMenu(id);
			if(bIsSetmodBit(g_bBuyTime)) set_task(1.0, "CheckDistanceTrader", id + TASK_TRADER_DISTANCE, _,_, "b");
		}
		case 8: return Show_MainPnMenu(id);
		case 9: if(task_exists(id + TASK_TRADER_DISTANCE)) remove_task(id + TASK_TRADER_DISTANCE);
	}
	return PLUGIN_HANDLED;
}

Show_ShopWeaponsMenu(id) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || IsNotSetBit(g_iBitUserAlive, id) || IsSetBit(g_iBitUserDuel, id)) return PLUGIN_HANDLED;
	if(bIsSetmodBit(g_bBuyTime)) set_task(1.0, "CheckDistanceTrader", id + TASK_TRADER_DISTANCE, _,_, "b");
	jbe_informer_offset_up(id);
	new szMenu[512], iKeys = (1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_SHOP_WEAPONS_TITLE");
	
	new iPriceScrewdriver = jbe_get_price_discount(id, g_iShopCvars[SCREWDRIVER]);
	if(IsNotSetBit(g_iBitScrewdriver, id)) {
		if(iPriceScrewdriver <= jbe_get_user_money(id) && g_iUserLevel[id] >= (g_iAllCvars[WEAPON_LVL_BUY_1] - 1)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L \R\y%d$^n", id, "JBE_MENU_SHOP_WEAPONS_SCREWDRIVER", iPriceScrewdriver);
			iKeys |= (1<<0);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L \R\r%d$\d|\y%d lvl^n", id, "JBE_MENU_SHOP_WEAPONS_SCREWDRIVER", iPriceScrewdriver, g_iAllCvars[WEAPON_LVL_BUY_1]);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L^n", id, "JBE_MENU_SHOP_WEAPONS_SCREWDRIVER");
	
	new iPriceChainsaw = jbe_get_price_discount(id, g_iShopCvars[CHAINSAW]);
	if(IsNotSetBit(g_iBitChainsaw, id) && IsNotSetBit(g_iBitChainsaw, id)) {
		if(iPriceChainsaw <= jbe_get_user_money(id) && g_iUserLevel[id] >= (g_iAllCvars[WEAPON_LVL_BUY_2] - 1)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L \R\y%d$^n", id, "JBE_MENU_SHOP_WEAPONS_CHAINSAW", iPriceChainsaw);
			iKeys |= (1<<1);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L \R\r%d$\d|\y%d lvl^n", id, "JBE_MENU_SHOP_WEAPONS_CHAINSAW", iPriceChainsaw, g_iAllCvars[WEAPON_LVL_BUY_2]);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L^n", id, "JBE_MENU_SHOP_WEAPONS_CHAINSAW");
	
	new iPriceGlock18 = jbe_get_price_discount(id, g_iShopCvars[GLOCK18]);
	if(!user_has_weapon(id, CSW_GLOCK18)) {
		if(iPriceGlock18 <= jbe_get_user_money(id) && g_iUserLevel[id] >= (g_iAllCvars[WEAPON_LVL_BUY_3] - 1)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L \R\y%d$^n", id, "JBE_MENU_SHOP_WEAPONS_GLOCK18", iPriceGlock18);
			iKeys |= (1<<2);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L \R\r%d$\d|\y%d lvl^n", id, "JBE_MENU_SHOP_WEAPONS_GLOCK18", iPriceGlock18, g_iAllCvars[WEAPON_LVL_BUY_3]);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L^n", id, "JBE_MENU_SHOP_WEAPONS_GLOCK18");
	
	new iPriceUsp = jbe_get_price_discount(id, g_iShopCvars[USP]);
	if(!user_has_weapon(id, CSW_USP)) {
		if(iPriceUsp <= jbe_get_user_money(id) && g_iUserLevel[id] >= (g_iAllCvars[WEAPON_LVL_BUY_4] - 1)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L \R\y%d$^n", id, "JBE_MENU_SHOP_WEAPONS_USP", iPriceUsp);
			iKeys |= (1<<3);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L \R\r%d$\d|\y%d lvl^n", id, "JBE_MENU_SHOP_WEAPONS_USP", iPriceUsp, g_iAllCvars[WEAPON_LVL_BUY_4]);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L^n", id, "JBE_MENU_SHOP_WEAPONS_USP");
	
	new iPriceUnstableVirus = jbe_get_price_discount(id, g_iShopCvars[UNSTABLE_VIRUS]);
	if(IsNotSetBit(g_iBitUnstableVirus, id) && id != g_iAthrID && id != g_iMedSisID && id != g_iSixPlID) {
		if(iPriceUsp <= jbe_get_user_money(id) && g_iUserLevel[id] >= (g_iAllCvars[WEAPON_LVL_BUY_5] - 1)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L \R\y%d$^n", id, "JBE_MENU_SHOP_WEAPONS_UNSTABLE_VIRUS", iPriceUnstableVirus);
			iKeys |= (1<<4);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L \R\r%d$\d|\y%d lvl^n", id, "JBE_MENU_SHOP_WEAPONS_UNSTABLE_VIRUS", iPriceUnstableVirus, g_iAllCvars[WEAPON_LVL_BUY_5]);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L^n", id, "JBE_MENU_SHOP_WEAPONS_UNSTABLE_VIRUS");
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_BACK");
	return show_menu(id, iKeys, szMenu, -1, "Show_ShopWeaponsMenu");
}

public Handle_ShopWeaponsMenu(id, iKey) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || IsNotSetBit(g_iBitUserAlive, id) || IsSetBit(g_iBitUserDuel, id)) return PLUGIN_HANDLED;
	switch(iKey) {
		case 0: {
			new iPriceScrewdriver = jbe_get_price_discount(id, g_iShopCvars[SCREWDRIVER]);
			if(IsNotSetBit(g_iBitScrewdriver, id) && iPriceScrewdriver <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceScrewdriver;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceScrewdriver, true);
				if(IsSetBit(g_iBitChainsaw, id)) {
					new iChainsawCost = jbe_get_price_discount(id, g_iShopCvars[CHAINSAW]);
					iChainsawCost -= abs(iChainsawCost - floatround(iChainsawCost / 80.0 * 100));
					jbe_set_user_money(id, jbe_get_user_money(id) + iChainsawCost, true);
					client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_SHOP_WEAPON_RETURN_COST", iChainsawCost);
				}
				ClearBit(g_iBitChainsaw, id);
				SetBit(g_iBitScrewdriver, id);
				if(IsSetBit(g_iBitWeaponStatus, id) && get_user_weapon(id) == CSW_KNIFE) {
					new iActiveItem = get_member(id, m_pActiveItem);
					if(iActiveItem > 0) ExecuteHamB(Ham_Item_Deploy, iActiveItem);
				}
				else client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_SHOP_WEAPON_HELP");
				return PLUGIN_HANDLED;
			}
		}
		case 1: {
			new iPriceChainsaw = jbe_get_price_discount(id, g_iShopCvars[CHAINSAW]);
			if(IsNotSetBit(g_iBitChainsaw, id) && iPriceChainsaw <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceChainsaw;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceChainsaw, true);
				if(IsSetBit(g_iBitScrewdriver, id)) {
					new iScrewdriverCost = jbe_get_price_discount(id, g_iShopCvars[SCREWDRIVER]);
					iScrewdriverCost -= abs(iScrewdriverCost - floatround(iScrewdriverCost / 80.0 * 100));
					jbe_set_user_money(id, jbe_get_user_money(id) + iScrewdriverCost, true);
					client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_SHOP_WEAPON_RETURN_COST", iScrewdriverCost);
				}
				ClearBit(g_iBitScrewdriver, id);
				SetBit(g_iBitChainsaw, id);
				SetBit(g_iBitWeaponStatus, id);
				if(get_user_weapon(id) == CSW_KNIFE) {
					new iActiveItem = get_member(id, m_pActiveItem);
					if(iActiveItem > 0) ExecuteHamB(Ham_Item_Deploy, iActiveItem);
				}
				else client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_SHOP_WEAPON_HELP");
				return PLUGIN_HANDLED;
			}
		}
		case 2: {
			new iPriceGlock18 = jbe_get_price_discount(id, g_iShopCvars[GLOCK18]);
			if(!user_has_weapon(id, CSW_GLOCK18) && iPriceGlock18 <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceGlock18;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceGlock18, true);
				rg_drop_items_by_slot(id, PISTOL_SLOT);
				rg_give_item(id, "weapon_glock18", GT_REPLACE);
				return PLUGIN_HANDLED;
			}
		}
		case 3: {
			new iPriceUsp = jbe_get_price_discount(id, g_iShopCvars[USP]);
			if(!user_has_weapon(id, CSW_USP) && iPriceUsp <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceUsp;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceUsp, true);
				rg_drop_items_by_slot(id, PISTOL_SLOT);
				rg_give_item(id, "weapon_usp", GT_REPLACE);
				return PLUGIN_HANDLED;
			}
		}
		case 4: {	
			new iPriceUnstableVirus = jbe_get_price_discount(id, g_iShopCvars[UNSTABLE_VIRUS]);
			if(IsNotSetBit(g_iBitUnstableVirus, id) && iPriceUnstableVirus <= jbe_get_user_money(id) && IsNotSetBit(g_iBitChainsaw, id)) {
				client_cmd(id, "weapon_knife");
				g_iTraderMoney += iPriceUnstableVirus;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceUnstableVirus, true);
				SetBit(g_iBitUnstableVirus, id);
				jbe_set_syringe_model(id);
				set_task(2.8, "jbe_zm_remove_syringe_model", id + TASK_REMOVE_SYRINGE);
				return PLUGIN_HANDLED;
			}
		}
		case 9: return Show_ShopPrisonersMenu(id, 1);
	}
	return Show_ShopWeaponsMenu(id);
}

Show_ShopItemsMenu(id) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || IsNotSetBit(g_iBitUserAlive, id) || IsSetBit(g_iBitUserDuel, id)) return PLUGIN_HANDLED;
	if(bIsSetmodBit(g_bBuyTime)) set_task(1.0, "CheckDistanceTrader", id + TASK_TRADER_DISTANCE, _,_, "b");
	jbe_informer_offset_up(id);
	new szMenu[512], iKeys = (1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_SHOP_ITEMS_TITLE");
	
	new iPriceLatchkey = jbe_get_price_discount(id, g_iShopCvars[LATCHKEY]);
	if(IsNotSetBit(g_iBitLatchkey, id)) {
		if(iPriceLatchkey <= jbe_get_user_money(id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L \y[%d$]^n", id, "JBE_MENU_SHOP_ITEMS_LATCHKEY", iPriceLatchkey);
			iKeys |= (1<<0);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L \r[%d$]^n", id, "JBE_MENU_SHOP_ITEMS_LATCHKEY", iPriceLatchkey);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L [%d$]^n", id, "JBE_MENU_SHOP_ITEMS_LATCHKEY", iPriceLatchkey);
	
	new iPriceFlashbang = jbe_get_price_discount(id, g_iShopCvars[FLASHBANG]);
	if(!user_has_weapon(id, CSW_FLASHBANG)) {
		if(iPriceFlashbang <= jbe_get_user_money(id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L \y[%d$]^n", id, "JBE_MENU_SHOP_ITEMS_FLASHBANG", iPriceFlashbang);
			iKeys |= (1<<1);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L \r[%d$]^n", id, "JBE_MENU_SHOP_ITEMS_FLASHBANG", iPriceFlashbang);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L [%d$]^n", id, "JBE_MENU_SHOP_ITEMS_FLASHBANG", iPriceFlashbang);
	
	new iPriceKokain = jbe_get_price_discount(id, g_iShopCvars[KOKAIN]);
	if(IsNotSetBit(g_iBitKokain, id)) {
		if(iPriceKokain <= jbe_get_user_money(id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L \y[%d$]^n", id, "JBE_MENU_SHOP_ITEMS_KOKAIN", iPriceKokain);
			iKeys |= (1<<2);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L \r[%d$]^n", id, "JBE_MENU_SHOP_ITEMS_KOKAIN", iPriceKokain);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L [%d$]^n", id, "JBE_MENU_SHOP_ITEMS_KOKAIN", iPriceKokain);
	
	new iPriceStimulator = jbe_get_price_discount(id, g_iShopCvars[STIMULATOR]);
	if(IsNotSetBit(g_iBitUserBoxing, id) && Float:rg_get_user_health(id) < 200.0) {
		if(iPriceStimulator <= jbe_get_user_money(id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L \y[%d$]^n", id, "JBE_MENU_SHOP_ITEMS_STIMULATOR", iPriceStimulator);
			iKeys |= (1<<3);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L \r[%d$]^n", id, "JBE_MENU_SHOP_ITEMS_STIMULATOR", iPriceStimulator);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L [%d$]^n", id, "JBE_MENU_SHOP_ITEMS_STIMULATOR", iPriceStimulator);
	
	new iPriceFrostNade = jbe_get_price_discount(id, g_iShopCvars[FROSTNADE]);
	if(!user_has_weapon(id, CSW_SMOKEGRENADE) && IsNotSetBit(g_iBitFrostNade, id)) {
		if(iPriceFrostNade <= jbe_get_user_money(id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L \y[%d$]^n", id, "JBE_MENU_SHOP_ITEMS_FROST_GRENADE", iPriceFrostNade);
			iKeys |= (1<<4);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L \r[%d$]^n", id, "JBE_MENU_SHOP_ITEMS_FROST_GRENADE", iPriceFrostNade);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L [%d$]^n", id, "JBE_MENU_SHOP_ITEMS_FROST_GRENADE", iPriceFrostNade);
	
	new iPriceInvisibleHat = jbe_get_price_discount(id, g_iShopCvars[INVISIBLE_HAT]);
	if(IsNotSetBit(g_iBitInvisibleHat, id)) {
		if(iPriceInvisibleHat <= jbe_get_user_money(id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \w%L \y[%d$]^n", id, "JBE_MENU_SHOP_ITEMS_INVISIBLE_HAT", iPriceInvisibleHat);
			iKeys |= (1<<5);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \d%L \r[%d$]^n", id, "JBE_MENU_SHOP_ITEMS_INVISIBLE_HAT", iPriceInvisibleHat);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \d%L [%d$]^n", id, "JBE_MENU_SHOP_ITEMS_INVISIBLE_HAT", iPriceInvisibleHat);
	
	new iPriceArmor = jbe_get_price_discount(id, g_iShopCvars[ARMOR]);
	if(rg_get_user_armor(id) == 0.0) {
		if(iPriceArmor <= jbe_get_user_money(id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(7) \y| \w%L \y[%d$]^n", id, "JBE_MENU_SHOP_ITEMS_ARMOR", iPriceArmor);
			iKeys |= (1<<6);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(7) \y| \d%L \r[%d$]^n", id, "JBE_MENU_SHOP_ITEMS_ARMOR", iPriceArmor);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(7) \y| \d%L [%d$]^n", id, "JBE_MENU_SHOP_ITEMS_ARMOR", iPriceArmor);
	
	new iPriceClothingGuard = jbe_get_price_discount(id, g_iShopCvars[CLOTHING_GUARD]);
	if(IsNotSetBit(g_iBitClothingGuard, id)) {
		if(iPriceClothingGuard <= jbe_get_user_money(id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(8) \y| \w%L \y[%d$]^n", id, "JBE_MENU_SHOP_SKILLS_CLOHING_GUARD", iPriceClothingGuard);
			iKeys |= (1<<7);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(8) \y| \d%L \r[%d$]^n", id, "JBE_MENU_SHOP_SKILLS_CLOHING_GUARD", iPriceClothingGuard);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(8) \y| \d%L [%d$]^n", id, "JBE_MENU_SHOP_SKILLS_CLOHING_GUARD", iPriceClothingGuard);
	
	new iPriceHeGrenade = jbe_get_price_discount(id, g_iShopCvars[HEGRENADE]);
	if(!user_has_weapon(id, CSW_HEGRENADE)) {
		if(iPriceHeGrenade <= jbe_get_user_money(id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(9) \y| \w%L \y[%d$]^n", id, "JBE_MENU_SHOP_SKILLS_HEGRENADE", iPriceHeGrenade);
			iKeys |= (1<<8);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(9) \y| \d%L \r[%d$]^n", id, "JBE_MENU_SHOP_SKILLS_HEGRENADE", iPriceHeGrenade);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(9) \y| \d%L [%d$]^n", id, "JBE_MENU_SHOP_SKILLS_HEGRENADE", iPriceHeGrenade);
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_BACK");
	return show_menu(id, iKeys, szMenu, -1, "Show_ShopItemsMenu");
}

public Handle_ShopItemsMenu(id, iKey) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || IsNotSetBit(g_iBitUserAlive, id) || IsSetBit(g_iBitUserDuel, id)) return PLUGIN_HANDLED;
	switch(iKey) {
		case 0: {
			new iPriceLatchkey = jbe_get_price_discount(id, g_iShopCvars[LATCHKEY]);
			if(IsNotSetBit(g_iBitLatchkey, id) && iPriceLatchkey <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceLatchkey;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceLatchkey, true);
				SetBit(g_iBitLatchkey, id);
				client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_MENU_ID_LATCHKEY_USE");
				return PLUGIN_HANDLED;
			}
		}
		case 1: {
			new iPriceFlashbang = jbe_get_price_discount(id, g_iShopCvars[FLASHBANG]);
			if(!user_has_weapon(id, CSW_FLASHBANG) && iPriceFlashbang <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceFlashbang;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceFlashbang, true);
				rg_give_item(id, "weapon_flashbang", GT_REPLACE);
				return PLUGIN_HANDLED;
			}
		}
		case 2: {
			new iPriceKokain = jbe_get_price_discount(id, g_iShopCvars[KOKAIN]);
			if(IsNotSetBit(g_iBitKokain, id) && iPriceKokain <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceKokain;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceKokain, true);
				SetBit(g_iBitKokain, id);
				jbe_set_syringe_model(id);
				client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_MENU_ID_KOKAIN");
				if(!task_exists(id + TASK_REMOVE_SYRINGE)) set_task(2.8, "jbe_remove_syringe_model", id+TASK_REMOVE_SYRINGE);
				return PLUGIN_HANDLED;
			}
		}
		case 3: {
			new iPriceStimulator = jbe_get_price_discount(id, g_iShopCvars[STIMULATOR]);
			if(IsNotSetBit(g_iBitUserBoxing, id) && Float:rg_get_user_health(id) < 200.0 && iPriceStimulator <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceStimulator;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceStimulator, true);
				jbe_set_syringe_model(id);
				rg_set_user_health(id, 200.0);
				if(!task_exists(id + TASK_REMOVE_SYRINGE)) set_task(2.8, "jbe_remove_syringe_model", id + TASK_REMOVE_SYRINGE);			
				return PLUGIN_HANDLED;
			}
		}
		case 4: {
			new iPriceFrostNade = jbe_get_price_discount(id, g_iShopCvars[FROSTNADE]);
			if(!user_has_weapon(id, CSW_SMOKEGRENADE) && IsNotSetBit(g_iBitFrostNade, id) && iPriceFrostNade <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceFrostNade;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceFrostNade, true);
				SetBit(g_iBitFrostNade, id);
				rg_give_item(id, "weapon_smokegrenade", GT_REPLACE);
				return PLUGIN_HANDLED;
			}
		}
		case 5: {
			new iPriceInvisibleHat = jbe_get_price_discount(id, g_iShopCvars[INVISIBLE_HAT]);
			if(IsNotSetBit(g_iBitInvisibleHat, id) && iPriceInvisibleHat <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceInvisibleHat;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceInvisibleHat, true);
				SetBit(g_iBitInvisibleHat, id);
				rg_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0);
				if(g_eUserCostumes[id][COSTUMES]) jbe_hide_user_costumes(id);
				set_task(10.0, "jbe_remove_invisible_hat", id+TASK_INVISIBLE_HAT);
				UTIL_BarTime(id, 10);
				client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_MENU_ID_INVISIBLE_HAT_HELP");
				return PLUGIN_HANDLED;
			}
		}
		case 6: {
			new iPriceArmor = jbe_get_price_discount(id, g_iShopCvars[ARMOR]);
			if(rg_get_user_armor(id) == 0.0 && iPriceArmor <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceArmor;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceArmor, true);
				rg_give_item(id, "item_kevlar", GT_REPLACE);
				return PLUGIN_HANDLED;
			}
		}
		case 7: {
			new iPriceClothingGuard = jbe_get_price_discount(id, g_iShopCvars[CLOTHING_GUARD]);
			if(IsNotSetBit(g_iBitClothingGuard, id) && iPriceClothingGuard <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceClothingGuard;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceClothingGuard, true);
				SetBit(g_iBitClothingGuard, id);
				client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_CLOHING_GUARD_HELP");
			}
		}
		case 8: {
			new iPriceHeGrenade = jbe_get_price_discount(id, g_iShopCvars[HEGRENADE]);
			if(!user_has_weapon(id, CSW_SMOKEGRENADE) && iPriceHeGrenade <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceHeGrenade;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceHeGrenade, true);
				rg_give_item(id, "weapon_hegrenade", GT_REPLACE);
				return PLUGIN_HANDLED;
			}
		}
		case 9: return Show_ShopPrisonersMenu(id, 1);
	}
	return Show_ShopItemsMenu(id);
}

Show_ShopSkillsMenu(id) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || IsNotSetBit(g_iBitUserAlive, id) || IsSetBit(g_iBitUserDuel, id)) return PLUGIN_HANDLED;
	if(bIsSetmodBit(g_bBuyTime)) set_task(1.0, "CheckDistanceTrader", id + TASK_TRADER_DISTANCE, _,_, "b");
	jbe_informer_offset_up(id);
	new szMenu[512], iKeys = (1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_SHOP_SKILLS_TITLE");
	
	new iPriceHingJump = jbe_get_price_discount(id, g_iShopCvars[HING_JUMP]);
	if(IsNotSetBit(g_iBitHingJump, id)) {
		if(iPriceHingJump <= jbe_get_user_money(id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L \y[%d$]^n", id, "JBE_MENU_SHOP_SKILLS_HING_JUMP", iPriceHingJump);
			iKeys |= (1<<0);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L \r[%d$]^n", id, "JBE_MENU_SHOP_SKILLS_HING_JUMP", iPriceHingJump);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L [%d$]^n", id, "JBE_MENU_SHOP_SKILLS_HING_JUMP", iPriceHingJump);
	
	new iPriceFastRun = jbe_get_price_discount(id, g_iShopCvars[FAST_RUN]);
	if(IsNotSetBit(g_iBitFastRun, id)) {
		if(iPriceFastRun <= jbe_get_user_money(id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L \y[%d$]^n", id, "JBE_MENU_SHOP_SKILLS_FAST_RUN", iPriceFastRun);
			iKeys |= (1<<1);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L \r[%d$]^n", id, "JBE_MENU_SHOP_SKILLS_FAST_RUN", iPriceFastRun);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L [%d$]^n", id, "JBE_MENU_SHOP_SKILLS_FAST_RUN", iPriceFastRun);
	
	new iPriceDoubleJump = jbe_get_price_discount(id, g_iShopCvars[DOUBLE_JUMP]);
	if(IsNotSetBit(g_iBitDoubleJump, id)) {
		if(iPriceDoubleJump <= jbe_get_user_money(id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L \y[%d$]^n", id, "JBE_MENU_SHOP_SKILLS_DOUBLE_JUMP", iPriceDoubleJump);
			iKeys |= (1<<2);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L \r[%d$]^n", id, "JBE_MENU_SHOP_SKILLS_DOUBLE_JUMP", iPriceDoubleJump);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L [%d$]^n", id, "JBE_MENU_SHOP_SKILLS_DOUBLE_JUMP", iPriceDoubleJump);
	
	new iPriceAutoBhop = jbe_get_price_discount(id, g_iShopCvars[AUTO_BHOP]);
	if(IsNotSetBit(g_iBitAutoBhop, id)) {
		if(iPriceAutoBhop <= jbe_get_user_money(id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L \y[%d$]^n", id, "JBE_MENU_SHOP_SKILLS_AUTO_BHOP", iPriceAutoBhop);
			iKeys |= (1<<3);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L \r[%d$]^n", id, "JBE_MENU_SHOP_SKILLS_AUTO_BHOP", iPriceAutoBhop);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L [%d$]^n", id, "JBE_MENU_SHOP_SKILLS_AUTO_BHOP", iPriceAutoBhop);
	
	new iPriceDoubleDamage = jbe_get_price_discount(id, g_iShopCvars[DOUBLE_DAMAGE]);
	if(IsNotSetBit(g_iBitDoubleDamage, id)) {
		if(iPriceDoubleDamage <= jbe_get_user_money(id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L \y[%d$]^n", id, "JBE_MENU_SHOP_SKILLS_DOUBLE_DAMAGE", iPriceDoubleDamage);
			iKeys |= (1<<4);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L \r[%d$]^n", id, "JBE_MENU_SHOP_SKILLS_DOUBLE_DAMAGE", iPriceDoubleDamage);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L [%d$]^n", id, "JBE_MENU_SHOP_SKILLS_DOUBLE_DAMAGE", iPriceDoubleDamage);
	
	new iPriceLowGravity = jbe_get_price_discount(id, g_iShopCvars[LOW_GRAVITY]);
	if(Float:rg_get_user_gravity(id) == 1.0) {
		if(iPriceLowGravity <= jbe_get_user_money(id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \w%L \y[%d$]^n^n^n", id, "JBE_MENU_SHOP_SKILLS_LOW_GRAVITY", iPriceLowGravity);
			iKeys |= (1<<5);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \d%L \r[%d$]^n^n^n", id, "JBE_MENU_SHOP_SKILLS_LOW_GRAVITY", iPriceLowGravity);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \d%L [%d$]^n^n^n", id, "JBE_MENU_SHOP_SKILLS_LOW_GRAVITY", iPriceLowGravity);
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_BACK");
	return show_menu(id, iKeys, szMenu, -1, "Show_ShopSkillsMenu");
}

public Handle_ShopSkillsMenu(id, iKey) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || IsNotSetBit(g_iBitUserAlive, id) || IsSetBit(g_iBitUserDuel, id)) return PLUGIN_HANDLED;
	switch(iKey) {
		case 0: {
			new iPriceHingJump = jbe_get_price_discount(id, g_iShopCvars[HING_JUMP]);
			if(iPriceHingJump <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceHingJump;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceHingJump, true);
				SetBit(g_iBitHingJump, id);
				return PLUGIN_HANDLED;
			}
		}
		case 1: {
			new iPriceFastRun = jbe_get_price_discount(id, g_iShopCvars[FAST_RUN]);
			if(iPriceFastRun <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceFastRun;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceFastRun, true);
				SetBit(g_iBitFastRun, id);
				PlayerResetMaxSpeed_Post(id);
				return PLUGIN_HANDLED;
			}
		}
		case 2: {
			new iPriceDoubleJump = jbe_get_price_discount(id, g_iShopCvars[DOUBLE_JUMP]);
			if(iPriceDoubleJump <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceDoubleJump;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceDoubleJump, true);
				SetBit(g_iBitDoubleJump, id);
				return PLUGIN_HANDLED;
			}
		}
		case 3: {
			new iPriceAutoBhop = jbe_get_price_discount(id, g_iShopCvars[AUTO_BHOP]);
			if(iPriceAutoBhop <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceAutoBhop;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceAutoBhop, true);
				SetBit(g_iBitAutoBhop, id);
				return PLUGIN_HANDLED;
			}
		}
		case 4: {
			new iPriceDoubleDamage = jbe_get_price_discount(id, g_iShopCvars[DOUBLE_DAMAGE]);
			if(iPriceDoubleDamage <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceDoubleDamage;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceDoubleDamage, true);
				SetBit(g_iBitDoubleDamage, id);
				return PLUGIN_HANDLED;
			}
		}
		case 5: {
			new iPriceLowGravity = jbe_get_price_discount(id, g_iShopCvars[LOW_GRAVITY]);
			if(iPriceLowGravity <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceLowGravity;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceLowGravity, true);
				rg_set_user_gravity(id, 0.2);
				return PLUGIN_HANDLED;
			}
		}
		case 9: return Show_ShopPrisonersMenu(id, 1);
	}
	return Show_ShopSkillsMenu(id);
}

Show_ShopOtherMenu(id) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || IsNotSetBit(g_iBitUserAlive, id) || IsSetBit(g_iBitUserDuel, id)) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new szMenu[512], iKeys = (1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_SHOP_OTHER_TITLE");
	
	new iPriceCloseCase = jbe_get_price_discount(id, g_iShopCvars[CLOSE_CASE]);
	if(IsSetBit(g_iBitUserWanted, id)) {
		if(iPriceCloseCase <= jbe_get_user_money(id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L \y[%d$]^n", id, "JBE_MENU_SHOP_OTHER_CLOSE_CASE", iPriceCloseCase);
			iKeys |= (1<<0);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L \r[%d$]^n", id, "JBE_MENU_SHOP_OTHER_CLOSE_CASE", iPriceCloseCase);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L [%d$]^n", id, "JBE_MENU_SHOP_OTHER_CLOSE_CASE", iPriceCloseCase);
	
	new iPriceFreeDay = jbe_get_price_discount(id, g_iShopCvars[FREE_DAY_SHOP]);
	if(g_iDayMode == 1 && IsNotSetBit(g_iBitUserFree, id) && IsNotSetBit(g_iBitUserWanted, id)) {
		if(iPriceFreeDay <= jbe_get_user_money(id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L \y[%d$]^n", id, "JBE_MENU_SHOP_OTHER_FREE_DAY", iPriceFreeDay);
			iKeys |= (1<<1);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L \r[%d$]^n", id, "JBE_MENU_SHOP_OTHER_FREE_DAY", iPriceFreeDay);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L [%d$]^n", id, "JBE_MENU_SHOP_OTHER_FREE_DAY", iPriceFreeDay);
	
	new iPriceResolutionVoice = jbe_get_price_discount(id, g_iShopCvars[RESOLUTION_VOICE]);
	if(IsNotSetBit(g_iBitUserVoice, id)) {
		if(iPriceResolutionVoice <= jbe_get_user_money(id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L \y[%d$]^n", id, "JBE_MENU_SHOP_OTHER_RESOLUTION_VOICE", iPriceResolutionVoice);
			iKeys |= (1<<2);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L \r[%d$]^n", id, "JBE_MENU_SHOP_OTHER_RESOLUTION_VOICE", iPriceResolutionVoice);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L [%d$]^n", id, "JBE_MENU_SHOP_OTHER_RESOLUTION_VOICE", iPriceResolutionVoice);
	
	new iPriceTransferGuard = jbe_get_price_discount(id, g_iShopCvars[TRANSFER_GUARD]);
	if(iPriceTransferGuard <= jbe_get_user_money(id)) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L \y[%d$]^n", id, "JBE_MENU_SHOP_OTHER_TRANSFER_GUARD", iPriceTransferGuard);
		iKeys |= (1<<3);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L \r[%d$]^n", id, "JBE_MENU_SHOP_OTHER_TRANSFER_GUARD", iPriceTransferGuard);

	new iPricePrankPrisoner = jbe_get_price_discount(id, g_iShopCvars[PRANK_PRISONER]);
	if(g_iAlivePlayersNum[1] >= 2) {
		if(iPricePrankPrisoner <= jbe_get_user_money(id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L \y[%d$]^n", id, "JBE_MENU_SHOP_OTHER_PRANK_PRISONER", iPricePrankPrisoner);
			iKeys |= (1<<4);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L \r[%d$]^n", id, "JBE_MENU_SHOP_OTHER_PRANK_PRISONER", iPricePrankPrisoner);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L [%d$]^n", id, "JBE_MENU_SHOP_OTHER_PRANK_PRISONER", iPricePrankPrisoner);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n^n^n");
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_BACK");
	return show_menu(id, iKeys, szMenu, -1, "Show_ShopOtherMenu");
}

public Handle_ShopOtherMenu(id, iKey) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || IsNotSetBit(g_iBitUserAlive, id) || IsSetBit(g_iBitUserDuel, id)) return PLUGIN_HANDLED;
	if(task_exists(id + TASK_TRADER_DISTANCE)) remove_task(id + TASK_TRADER_DISTANCE);
	switch(iKey) {
		case 0: {
			new iPriceCloseCase = jbe_get_price_discount(id, g_iShopCvars[CLOSE_CASE]);
			if(IsSetBit(g_iBitUserWanted, id) && iPriceCloseCase <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceCloseCase;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceCloseCase, true);
				jbe_sub_user_wanted(id);
				return PLUGIN_HANDLED;
			}
		}
		case 1: {
			new iPriceFreeDay = jbe_get_price_discount(id, g_iShopCvars[FREE_DAY_SHOP]);
			if(g_iDayMode == 1 && IsNotSetBit(g_iBitUserFree, id) && IsNotSetBit(g_iBitUserWanted, id) && iPriceFreeDay <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceFreeDay;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceFreeDay, true);
				jbe_add_user_free(id);
				return PLUGIN_HANDLED;
			}
		}
		case 2: {
			new iPriceResolutionVoice = jbe_get_price_discount(id, g_iShopCvars[RESOLUTION_VOICE]);
			if(IsNotSetBit(g_iBitUserVoice, id) && iPriceResolutionVoice <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceResolutionVoice;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceResolutionVoice, true);
				SetBit(g_iBitUserVoice, id);
				return PLUGIN_HANDLED;
			}
		}
		case 3: {
			new iPriceTransferGuard = jbe_get_price_discount(id, g_iShopCvars[TRANSFER_GUARD]);
			if(iPriceTransferGuard <= jbe_get_user_money(id)) {
				if(IsSetBit(g_iBitUserAlive, id)) ExecuteHamB(Ham_Killed, id, id, 0);
				if(jbe_set_user_team(id, 2)) {
					g_iTraderMoney += iPriceTransferGuard;
					jbe_set_user_money(id, jbe_get_user_money(id) - iPriceTransferGuard, true);
				}
				return PLUGIN_HANDLED;
			}
		}
		case 4: if(g_iAlivePlayersNum[1] >= 2) return Cmd_PrankPrisonerMenu(id);
		case 9: return Show_ShopPrisonersMenu(id, 1);
	}
	return Show_ShopOtherMenu(id);
}

Cmd_PrankPrisonerMenu(id) return Show_PrankPrisonerMenu(id, g_iMenuPosition[id] = 0);

Show_PrankPrisonerMenu(id, iPos) {
	if(iPos < 0 || g_iDayMode != 1 && g_iDayMode != 2 || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	if(bIsSetmodBit(g_bBuyTime)) set_task(1.0, "CheckDistanceTrader", id + TASK_TRADER_DISTANCE, _,_, "b");
	jbe_informer_offset_up(id);
	
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++) {
		if(g_iUserTeam[i] != 1 || IsNotSetBit(g_iBitUserAlive, i) || IsSetBit(g_iBitUserWanted, i) || i == id || g_iUserExp[id] < g_iUserExp[i]) continue;
		g_iMenuPlayers[id][iPlayersNum++] = i;
	}

	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[256], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum) {
		case 0: {
			client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_ShopOtherMenu(id);
		}
		default: iLen = formatex(szMenu, charsmax(szMenu), "\y%L \w[%d|%d]^n^n", id, "JBE_MENU_PRANK_PRISONER_TITLE", iPos + 1, iPagesNum);
	}

	new szName[32], i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++) {
		i = g_iMenuPlayers[id][a];
		get_user_name(i, szName, charsmax(szName));
		iKeys |= (1<<b);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d]\r ~ \w%s^n", ++b, szName);
	}
	
	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	if(iEnd < iPlayersNum) {
		iKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L^n\r(0) \y| \w%L", id, "JBE_MENU_NEXT", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r(0) \y| \w%L", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	
	return show_menu(id, iKeys, szMenu, -1, "Show_PrankPrisonerMenu");
}

public Handle_PrankPrisonerMenu(id, iKey) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	switch(iKey) {
		case 8: return Show_PrankPrisonerMenu(id, ++g_iMenuPosition[id]);
		case 9: return Show_PrankPrisonerMenu(id, --g_iMenuPosition[id]);
		default: {
			new iTarget = g_iMenuPlayers[id][g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey];
			new iPricePrankPrisoner = jbe_get_price_discount(id, g_iShopCvars[PRANK_PRISONER]);
			if(iPricePrankPrisoner <= jbe_get_user_money(id)) {
				if(g_iUserTeam[iTarget] == 1 || IsSetBit(g_iBitUserAlive, iTarget) || IsNotSetBit(g_iBitUserWanted, iTarget)) {
					g_iTraderMoney += iPricePrankPrisoner;
					jbe_set_user_money(id, jbe_get_user_money(id) - iPricePrankPrisoner, true);
					if(!g_szWantedNames[0]) {
						rh_emit_sound2(0, id, CHAN_AUTO, "egoist/jb/other/prison_riot.wav", VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);
						rh_emit_sound2(0, id, CHAN_AUTO, "egoist/jb/other/prison_riot.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
					}
					jbe_add_user_wanted(iTarget);
					new szName[32]; get_user_name(id, szName, charsmax(szName));
					for(new pPlayer = 1; pPlayer <= MaxClients; pPlayer++) {
						if(IsSetBit(g_iBitUserConnected, pPlayer) && g_iUserTeam[pPlayer] == 2) {
							client_print_color(pPlayer, print_team_default, "^1[^4INFO^1][^4Охрана^1]^4 %s ^1дал кому-то ^3взятку^1!", szName);	
						}
					}
				}
				else return Show_PrankPrisonerMenu(id, g_iMenuPosition[id]);
			}
			else return Show_ShopOtherMenu(id);
		}
	}
	return PLUGIN_HANDLED;
}

Show_ShopGuardMenu(id) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || IsNotSetBit(g_iBitUserAlive, id) || IsSetBit(g_iBitUserDuel, id)) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	jbe_set_user_discount(id);
	new szMenu[512], iKeys = (1<<8|1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n", id, "JBE_MENU_SHOP_GUARD_TITLE", g_iUserDiscount[id]);
	
	new iPriceStimulator = jbe_get_price_discount(id, g_iShopCvars[STIMULATOR_GR]);
	if(Float:rg_get_user_health(id) < 200.0) {
		if(iPriceStimulator <= jbe_get_user_money(id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L \y[%d$]^n", id, "JBE_MENU_SHOP_GUARD_STIMULATOR", iPriceStimulator);
			iKeys |= (1<<0);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L \r[%d$]^n", id, "JBE_MENU_SHOP_GUARD_STIMULATOR", iPriceStimulator);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L [%d$]^n", id, "JBE_MENU_SHOP_GUARD_STIMULATOR", iPriceStimulator);
	
	new iPriceKokain = jbe_get_price_discount(id, g_iShopCvars[KOKAIN_GR]);
	if(IsNotSetBit(g_iBitKokain, id)) {
		if(iPriceKokain <= jbe_get_user_money(id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L \y[%d$]^n", id, "JBE_MENU_SHOP_GUARD_KOKAIN", iPriceKokain);
			iKeys |= (1<<1);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L \r[%d$]^n", id, "JBE_MENU_SHOP_GUARD_KOKAIN", iPriceKokain);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L [%d$]^n", id, "JBE_MENU_SHOP_GUARD_KOKAIN", iPriceKokain);
	
	new iPriceDoubleJump = jbe_get_price_discount(id, g_iShopCvars[DOUBLE_JUMP_GR]);
	if(IsNotSetBit(g_iBitDoubleJump, id)) {
		if(iPriceDoubleJump <= jbe_get_user_money(id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L \y[%d$]^n", id, "JBE_MENU_SHOP_GUARD_DOUBLE_JUMP", iPriceDoubleJump);
			iKeys |= (1<<2);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L \r[%d$]^n", id, "JBE_MENU_SHOP_GUARD_DOUBLE_JUMP", iPriceDoubleJump);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L [%d$]^n", id, "JBE_MENU_SHOP_GUARD_DOUBLE_JUMP", iPriceDoubleJump);
	
	new iPriceFastRun = jbe_get_price_discount(id, g_iShopCvars[FAST_RUN_GR]);
	if(IsNotSetBit(g_iBitFastRun, id)) {
		if(iPriceFastRun <= jbe_get_user_money(id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L \y[%d$]^n", id, "JBE_MENU_SHOP_GUARD_FAST_RUN", iPriceFastRun);
			iKeys |= (1<<3);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L \r[%d$]^n", id, "JBE_MENU_SHOP_GUARD_FAST_RUN", iPriceFastRun);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L [%d$]^n", id, "JBE_MENU_SHOP_GUARD_FAST_RUN", iPriceFastRun);
	
	new iPriceLowGravity = jbe_get_price_discount(id, g_iShopCvars[LOW_GRAVITY_GR]);
	if(Float:rg_get_user_gravity(id) >= 0.8) {
		if(iPriceLowGravity <= jbe_get_user_money(id)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L \y[%d$]^n^n", id, "JBE_MENU_SHOP_GUARD_LOW_GRAVITY", iPriceLowGravity);
			iKeys |= (1<<4);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L \r[%d$]^n^n", id, "JBE_MENU_SHOP_GUARD_LOW_GRAVITY", iPriceLowGravity);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L [%d$]^n^n", id, "JBE_MENU_SHOP_GUARD_LOW_GRAVITY", iPriceLowGravity);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L", id, "JBE_MENU_BACK");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_ShopGuardMenu");
}

public Handle_ShopGuardMenu(id, iKey) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || IsNotSetBit(g_iBitUserAlive, id) || IsSetBit(g_iBitUserDuel, id)) return PLUGIN_HANDLED;
	switch(iKey) {
		case 0: {
			new iPriceStimulator = jbe_get_price_discount(id, g_iShopCvars[STIMULATOR_GR]);
			if(Float:rg_get_user_health(id) < 200.0 && iPriceStimulator <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceStimulator;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceStimulator, true);
				jbe_set_syringe_model(id);
				rg_set_user_health(id, 200.0);
				if(!task_exists(id + TASK_REMOVE_SYRINGE)) set_task(2.8, "jbe_remove_syringe_model", id+TASK_REMOVE_SYRINGE);
				return PLUGIN_HANDLED;
			}
		}
		case 1: {
			new iPriceKokain = jbe_get_price_discount(id, g_iShopCvars[KOKAIN_GR]);
			if(IsNotSetBit(g_iBitKokain, id) && iPriceKokain <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceKokain;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceKokain, true);
				SetBit(g_iBitKokain, id);
				jbe_set_syringe_model(id);
				client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_MENU_ID_KOKAIN");
				if(!task_exists(id + TASK_REMOVE_SYRINGE)) set_task(2.8, "jbe_remove_syringe_model", id+TASK_REMOVE_SYRINGE);
				return PLUGIN_HANDLED;
			}
		}
		case 2: {
			new iPriceDoubleJump = jbe_get_price_discount(id, g_iShopCvars[DOUBLE_JUMP_GR]);
			if(iPriceDoubleJump <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceDoubleJump;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceDoubleJump, true);
				SetBit(g_iBitDoubleJump, id);
				return PLUGIN_HANDLED;
			}
		}
		case 3: {
			new iPriceFastRun = jbe_get_price_discount(id, g_iShopCvars[FAST_RUN_GR]);
			if(iPriceFastRun <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceFastRun;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceFastRun, true);
				SetBit(g_iBitFastRun, id);
				PlayerResetMaxSpeed_Post(id);
				return PLUGIN_HANDLED;
			}
		}
		case 4: {
			new iPriceLowGravity = jbe_get_price_discount(id, g_iShopCvars[LOW_GRAVITY_GR]);
			if(iPriceLowGravity <= jbe_get_user_money(id)) {
				g_iTraderMoney += iPriceLowGravity;
				jbe_set_user_money(id, jbe_get_user_money(id) - iPriceLowGravity, true);
				rg_set_user_gravity(id, 0.2);
				return PLUGIN_HANDLED;
			}
		}
		case 8: return Show_MainGrMenu(id);
	}
	return PLUGIN_HANDLED;
}

Cmd_MoneyTransferMenu(id) return Show_MoneyTransferMenu(id, g_iMenuPosition[id] = 0);

Show_MoneyTransferMenu(id, iPos) {
	if(iPos < 0) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++) {
		if(IsNotSetBit(g_iBitUserConnected, i) || i == id) continue;
		g_iMenuPlayers[id][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum) {
		case 0: {
			client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_SettingMenu(id);
		}
		default: iLen = formatex(szMenu, charsmax(szMenu), "\y%L \w[%d|%d]^n\d%L^n", id, "JBE_MENU_MONEY_TRANSFER_TITLE", iPos + 1, iPagesNum, id, "JBE_MENU_MONEY_YOU_AMOUNT", jbe_get_user_money(id));
	}
	
	new szName[32], i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++) {
		i = g_iMenuPlayers[id][a];
		get_user_name(i, szName, charsmax(szName));
		iKeys |= (1<<b);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d]\r ~ \w%s \r[%d$]^n", ++b, szName, jbe_get_user_money(i));
	}
	
	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	if(iEnd < iPlayersNum) {
		iKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L^n\r(0) \y| \w%L", id, "JBE_MENU_NEXT", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r(0) \y| \w%L", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	
	return show_menu(id, iKeys, szMenu, -1, "Show_MoneyTransferMenu");
}

public Handle_MoneyTransferMenu(id, iKey) {
	switch(iKey) {
		case 8: return Show_MoneyTransferMenu(id, ++g_iMenuPosition[id]);
		case 9: return Show_MoneyTransferMenu(id, --g_iMenuPosition[id]);
		default: {
			g_iMenuTarget[id] = g_iMenuPlayers[id][g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey];
			return Show_MoneyAmountMenu(id);
		}
	}
	return PLUGIN_HANDLED;
}

Show_MoneyAmountMenu(id) {
	jbe_informer_offset_up(id);
	new szMenu[512], iKeys = (1<<8|1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n\d%L^n", id, "JBE_MENU_MONEY_AMOUNT_TITLE", id, "JBE_MENU_MONEY_YOU_AMOUNT", jbe_get_user_money(id));
	if(jbe_get_user_money(id)) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%d$^n", floatround(jbe_get_user_money(id) * 0.10, floatround_ceil));
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%d$^n", floatround(jbe_get_user_money(id) * 0.25, floatround_ceil));
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%d$^n", floatround(jbe_get_user_money(id) * 0.50, floatround_ceil));
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%d$^n", floatround(jbe_get_user_money(id) * 0.75, floatround_ceil));
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%d$^n^n^n", jbe_get_user_money(id));
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(8) \y| \w%L^n", id, "JBE_MENU_MONEY_SPECIFY_AMOUNT");
		iKeys |= (1<<0|1<<1|1<<2|1<<3|1<<4|1<<7);
	}
	else {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d0$^n\r(2) \y| \d0$^n\r(3) \y| \d0$^n\r(4) \y| \d0$^n\r(5) \y| \d0$^n^n^n");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(8) \y| \d%L^n", id, "JBE_MENU_MONEY_SPECIFY_AMOUNT");
	}
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L", id, "JBE_MENU_BACK");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_MoneyAmountMenu");
}

public Handle_MoneyAmountMenu(id, iKey) {
	switch(iKey) {
		case 0: ClCmd_MoneyTransfer(id, g_iMenuTarget[id], floatround(jbe_get_user_money(id) * 0.10, floatround_ceil));
		case 1: ClCmd_MoneyTransfer(id, g_iMenuTarget[id], floatround(jbe_get_user_money(id) * 0.25, floatround_ceil));
		case 2: ClCmd_MoneyTransfer(id, g_iMenuTarget[id], floatround(jbe_get_user_money(id) * 0.50, floatround_ceil));
		case 3: ClCmd_MoneyTransfer(id, g_iMenuTarget[id], floatround(jbe_get_user_money(id) * 0.75, floatround_ceil));
		case 4: ClCmd_MoneyTransfer(id, g_iMenuTarget[id], jbe_get_user_money(id));
		case 7: client_cmd(id, "messagemode ^"money_transfer %d^"", g_iMenuTarget[id]);
		case 8: return Show_MoneyTransferMenu(id, g_iMenuPosition[id]);
	}
	return PLUGIN_HANDLED;
}

Cmd_CostumesMenu(id, iCostumes) return Show_CostumesMenu(id, g_iMenuPosition[id] = 0, iCostumes);

Show_CostumesMenu(id, iPos, iCostumes) {
	if(iPos < 0 || g_iDayMode != 1 && g_iDayMode != 2) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new iStart = iPos * PLAYERS_PER_PAGE, g_iCostumesListSize = iCostumes == 1 ? 27 : 10;
	if(iStart > g_iCostumesListSize) iStart = g_iCostumesListSize;
	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > g_iCostumesListSize) iEnd = g_iCostumesListSize + (iPos ? 0 : 1);
	new szMenu[512], iLen, iPagesNum = (g_iCostumesListSize / PLAYERS_PER_PAGE + ((g_iCostumesListSize % PLAYERS_PER_PAGE) ? 1 : 0));
	iLen = formatex(szMenu, charsmax(szMenu), "\y%L %s \w[%d|%d]^n^n", id, "JBE_MENU_COSTUMES_TITLE", iCostumes == 2? "\rVIP":"", iPos + 1, iPagesNum);
	new szLangPlayer[36], iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++) {
		formatex(szLangPlayer, charsmax(szLangPlayer), "JBE_MENU_COSTUMES%s_%d", iCostumes == 2 ? "_VIP":"", a);
		if(g_eUserCostumes[id][COSTUMES] != a) {
			iKeys |= (1<<b);
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d]\r ~ \w%L^n", ++b, id, szLangPlayer);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d]\r ~ \d%L^n", ++b, id, szLangPlayer);
	}
	
	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	if(iEnd < g_iCostumesListSize) {
		iKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L^n\r(0) \y| \w%L", id, "JBE_MENU_NEXT", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r(0) \y| \w%L", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	
	return show_menu(id, iKeys, szMenu, -1, "Show_CostumesMenu");
}

public Handle_CostumesMenu(id, iKey) {
	if(g_iDayMode != 1 && g_iDayMode != 2) return PLUGIN_HANDLED;
	switch(iKey) {
		case 8: return Show_CostumesMenu(id, ++g_iMenuPosition[id], g_iCostumes[id]);
		case 9: return Show_CostumesMenu(id, --g_iMenuPosition[id], g_iCostumes[id]);
		default: {
			new iCostumes = g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey;
			jbe_set_user_costumes(id, iCostumes, g_iCostumes[id]);
			if(iCostumes > 0) {
				new szBuff[32];
				formatex(szBuff, charsmax(szBuff), "JBE_MENU_COSTUMES%s_%d", g_iCostumes[id] == 2 ? "_VIP":"", iCostumes);
				client_print_color(id, print_team_default, "^1[^4INFO^1] Вы надели костюм:^4 '%L'", id, szBuff);		
			}
		}
	}
	return PLUGIN_HANDLED;
}

Show_ChiefMenu_1(id) 
{
	if(g_iDayMode != 1 && g_iDayMode != 2 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new szMenu[512], iKeys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<6|1<<7|1<<8|1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_CHIEF_TITLE");
	if(bIsSetmodBit(g_bDoorStatus)) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_CHIEF_DOOR_CLOSE");
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_CHIEF_DOOR_OPEN");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_MENU_CHIEF_COUNTDOWN");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L^n", id, "JBE_MENU_CHIEF_PRISONER_SEARCH");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L^n", id, "JBE_MENU_CHIEF_FREE_DAY_CONTROL");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L^n", id, "JBE_MENU_CHIEF_FREE_DAY_START");
	
	if(jbe_get_user_lvl(id) >= 3) 
	{
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \w%L^n", id, "JBE_MENU_CHIEF_PUNISH_GUARD");
		iKeys |= (1<<5);
	}else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \d%L [Ваш lvl мал(4+)]^n", id, "JBE_MENU_CHIEF_PUNISH_GUARD");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(7) \y| \w%L^n", id, "JBE_MENU_CHIEF_TRANSFER_CHIEF");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(8) \y| \w%L^n", id, "JBE_MENU_CHIEF_TREAT_PRISONER");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L", id, "JBE_MENU_NEXT");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_ChiefMenu_1");
}

public Handle_ChiefMenu_1(id, iKey) 
{
	if(g_iDayMode != 1 && g_iDayMode != 2 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	switch(iKey) {
		case 0: 
		{
			if(bIsSetmodBit(g_bDoorStatus)) jbe_close_doors();
			else jbe_open_doors();
		}
		case 1: return Show_CountDownMenu(id);
		case 2: 
		{
			new iTarget, iBody;
			get_user_aiming(id, iTarget, iBody, 60);
			if(jbe_is_user_valid(iTarget) && IsSetBit(g_iBitUserAlive, iTarget)) 
			{
				if(g_iUserTeam[iTarget] != 1) client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_NOT_TEAM_SEARCH");
				else 
				{
					new iBitWeapons = get_entvar(iTarget, var_weapons);
					if(iBitWeapons &= ~(1<<CSW_HEGRENADE|1<<CSW_SMOKEGRENADE|1<<CSW_FLASHBANG|1<<CSW_KNIFE|1<<31)) client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_FOUND_WEAPON");
					else client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_NOT_FOUND_WEAPON");
				}
			}
			else client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_HELP_FOUND_WEAPON");
		}
		case 3: return Cmd_FreeDayControlMenu(id);
		case 4: jbe_free_day_start();
		case 5: return Cmd_PunishGuardMenu(id);
		case 6: return Cmd_TransferChiefMenu(id);
		case 7: return Cmd_TreatPrisonerMenu(id);
		case 8: return Show_ChiefMenu_2(id);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_ChiefMenu_1(id);
}

Show_CountDownMenu(id) 
{
	if(g_iDayMode != 1 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new szMenu[512], iKeys = (1<<8|1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_COUNT_DOWN_TITLE");
	if(task_exists(TASK_COUNT_DOWN_TIMER)) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L^n", id, "JBE_MENU_COUNT_DOWN_10");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L^n", id, "JBE_MENU_COUNT_DOWN_5");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L^n^n^n^n^n^n", id, "JBE_MENU_COUNT_DOWN_3");
	}
	else {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_COUNT_DOWN_10");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_MENU_COUNT_DOWN_5");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L^n^n^n^n^n^n", id, "JBE_MENU_COUNT_DOWN_3");
		iKeys |= (1<<0|1<<1|1<<2);
	}
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L", id, "JBE_MENU_BACK");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_CountDownMenu");
}

public Handle_CountDownMenu(id, iKey) {
	if(g_iDayMode != 1 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	switch(iKey) {
		case 0: g_iCountDown = 11;
		case 1: g_iCountDown = 6;
		case 2: g_iCountDown = 4;
		case 8: return Show_ChiefMenu_1(id);
		case 9: return PLUGIN_HANDLED;
	}
	set_task(1.0, "jbe_count_down_timer", TASK_COUNT_DOWN_TIMER, _, _, "a", g_iCountDown);
	return Show_ChiefMenu_1(id);
}

public jbe_count_down_timer() {
	if(--g_iCountDown) client_print(0, print_center, "%L", LANG_PLAYER, "JBE_MENU_COUNT_DOWN_TIME", g_iCountDown);
	else client_print(0, print_center, "%L", LANG_PLAYER, "JBE_MENU_COUNT_DOWN_TIME_END");
	UTIL_SendAudio(0, _, "egoist/jb/%s/%d.wav", g_szSound[COUNTDOWN], g_iCountDown);
}

Cmd_FreeDayControlMenu(id) return Show_FreeDayControlMenu(id, g_iMenuPosition[id] = 0);

Show_FreeDayControlMenu(id, iPos) {
	if(iPos < 0 || g_iDayMode != 1 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++) {
		if(g_iUserTeam[i] != 1 || IsSetBit(g_iBitUserFreeNextRound, i) || IsSetBit(g_iBitUserWanted, i)) continue;
		g_iMenuPlayers[id][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum) {
		case 0: {
			client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_ChiefMenu_1(id);
		}
		default: iLen = formatex(szMenu, charsmax(szMenu), "\y%L \w[%d|%d]^n^n", id, "JBE_MENU_FREE_DAY_CONTROL_TITLE", iPos + 1, iPagesNum);
	}
	new szName[32], i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++) {
		i = g_iMenuPlayers[id][a];
		get_user_name(i, szName, charsmax(szName));
		iKeys |= (1<<b);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d]\r ~ \w%s \r[%L]^n", ++b, szName, i, IsSetBit(g_iBitUserFree, i) ? "JBE_MENU_FREE_DAY_CONTROL_TAKE" : "JBE_MENU_FREE_DAY_CONTROL_GIVE");
	}
	
	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	if(iEnd < iPlayersNum) {
		iKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L^n\r(0) \y| \w%L", id, "JBE_MENU_NEXT", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r(0) \y| \w%L", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	
	return show_menu(id, iKeys, szMenu, -1, "Show_FreeDayControlMenu");
}

public Handle_FreeDayControlMenu(id, iKey) {
	if(g_iDayMode != 1 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	switch(iKey) {
		case 8: return Show_FreeDayControlMenu(id, ++g_iMenuPosition[id]);
		case 9: return Show_FreeDayControlMenu(id, --g_iMenuPosition[id]);
		default: {
			new iTarget = g_iMenuPlayers[id][g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey];
			if(g_iUserTeam[iTarget] != 1 || IsSetBit(g_iBitUserFreeNextRound, iTarget) || IsSetBit(g_iBitUserWanted, iTarget)) return Show_FreeDayControlMenu(id, g_iMenuPosition[id]);
			new szName[32], szTargetName[32];
			get_user_name(id, szName, charsmax(szName));
			get_user_name(iTarget, szTargetName, charsmax(szTargetName));
			if(IsSetBit(g_iBitUserFree, iTarget)) {
				client_print_color(0, print_team_default, "^1[^4INFO^1] %L", LANG_PLAYER, "JBE_CHAT_ALL_CHIEF_TAKE_FREE_DAY", szName, szTargetName);
				jbe_sub_user_free(iTarget);
			}
			else {
				client_print_color(0, print_team_default, "^1[^4INFO^1] %L", LANG_PLAYER, "JBE_CHAT_ALL_CHIEF_GIVE_FREE_DAY", szName, szTargetName);
				if(IsSetBit(g_iBitUserAlive, iTarget)) jbe_add_user_free(iTarget);
				else {
					jbe_add_user_free_next_round(iTarget);
					client_print_color(0, print_team_default, "^1[^4INFO^1] %L", LANG_PLAYER, "JBE_CHAT_ALL_AUTO_FREE_DAY", szTargetName);
				}
			}
		}
	}
	return Show_FreeDayControlMenu(id, g_iMenuPosition[id]);
}

Cmd_PunishGuardMenu(id) return Show_PunishGuardMenu(id, g_iMenuPosition[id] = 0);

Show_PunishGuardMenu(id, iPos) {
	if(iPos < 0 || g_iDayMode != 1 && g_iDayMode != 2 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++) {
		if(g_iUserTeam[i] != 2 || i == g_iChiefId || IsSetBit(g_iBitUserAdmin, i)) continue;
		g_iMenuPlayers[id][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[256], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum) {
		case 0: {
			client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_ChiefMenu_1(id);
		}
		default: iLen = formatex(szMenu, charsmax(szMenu), "\y%L \w[%d|%d]^n^n", id, "JBE_MENU_PUNISH_GUARD_TITLE", iPos + 1, iPagesNum);
	}
	
	new szName[32], i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++) {
		i = g_iMenuPlayers[id][a];
		get_user_name(i, szName, charsmax(szName));
		iKeys |= (1<<b);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d]\r ~ \w%s^n", ++b, szName);
	}
	
	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	if(iEnd < iPlayersNum) {
		iKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L^n\r(0) \y| \w%L", id, "JBE_MENU_NEXT", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r(0) \y| \w%L", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	
	return show_menu(id, iKeys, szMenu, -1, "Show_PunishGuardMenu");
}

public Handle_PunishGuardMenu(id, iKey) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	switch(iKey) {
		case 8: return Show_PunishGuardMenu(id, ++g_iMenuPosition[id]);
		case 9: return Show_PunishGuardMenu(id, --g_iMenuPosition[id]);
		default: {
			new iTarget = g_iMenuPlayers[id][g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey];
			if(g_iUserTeam[iTarget] == 2) {
				if(jbe_set_user_team(iTarget, 1)) {
					new szName[32], szTargetName[32];
					get_user_name(id, szName, charsmax(szName));
					get_user_name(iTarget, szTargetName, charsmax(szTargetName));
					client_print_color(0, print_team_default, "^1[^4INFO^1] %L", LANG_PLAYER, "JBE_CHAT_ALL_PUNISH_GUARD", szName, szTargetName);
				}
			}
		}
	}
	return Show_PunishGuardMenu(id, g_iMenuPosition[id]);
}

Cmd_TransferChiefMenu(id) return Show_TransferChiefMenu(id, g_iMenuPosition[id] = 0);

Show_TransferChiefMenu(id, iPos) {
	if(iPos < 0 || g_iDayMode != 1 && g_iDayMode != 2 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++) {
		if(g_iUserTeam[i] != 2 || IsNotSetBit(g_iBitUserAlive, i) || i == g_iChiefId) continue;
		g_iMenuPlayers[id][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[256], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum) {
		case 0: {
			client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_ChiefMenu_1(id);
		}
		default: iLen = formatex(szMenu, charsmax(szMenu), "\y%L \w[%d|%d]^n^n", id, "JBE_MENU_TRANSFER_CHIEF_TITLE", iPos + 1, iPagesNum);
	}
	
	new szName[32], i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++) {
		i = g_iMenuPlayers[id][a];
		get_user_name(i, szName, charsmax(szName));
		iKeys |= (1<<b);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d]\r ~ \w%s^n", ++b, szName);
	}
	
	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	if(iEnd < iPlayersNum) {
		iKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L^n\r(0) \y| \w%L", id, "JBE_MENU_NEXT", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r(0) \y| \w%L", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	
	return show_menu(id, iKeys, szMenu, -1, "Show_TransferChiefMenu");
}

public Handle_TransferChiefMenu(id, iKey) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	switch(iKey) {
		case 8: return Show_TransferChiefMenu(id, ++g_iMenuPosition[id]);
		case 9: return Show_TransferChiefMenu(id, --g_iMenuPosition[id]);
		default: {
			new iTarget = g_iMenuPlayers[id][g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey];
			jbe_set_user_model(id, g_szPlayerModel[GUARD]);
			if(jbe_set_user_chief(iTarget)) {
				CREATE_KILLBEAM(id);
				new szName[32], szTargetName[32];
				get_user_name(id, szName, charsmax(szName));
				get_user_name(iTarget, szTargetName, charsmax(szTargetName));
				client_print_color(0, print_team_default, "^1[^4INFO^1] %L", LANG_PLAYER, "JBE_CHAT_ALL_TRANSFER_CHIEF", szName, szTargetName);
				Spawn_PostHealth(id + TASK_CT_SPAWN_HEALTH);
				ExecuteForward(g_Fw_ChiefTransfer, g_ForwardReturn, id, iTarget);
				return PLUGIN_HANDLED;
			}
		}
	}
	return Show_TransferChiefMenu(id, g_iMenuPosition[id]);
}

Cmd_TreatPrisonerMenu(id) return Show_TreatPrisonerMenu(id, g_iMenuPosition[id] = 0);

Show_TreatPrisonerMenu(id, iPos) {
	if(iPos < 0 || g_iDayMode != 1 && g_iDayMode != 2 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++) {
		if(g_iUserTeam[i] != 1 || IsNotSetBit(g_iBitUserAlive, i) || Float:rg_get_user_health(i) >= 100.0 || IsSetBit(g_iBitUserBoxing, id) || IsSetBit(g_iBitUserDuel, id)) continue;
		g_iMenuPlayers[id][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum) {
		case 0: {
			client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_ChiefMenu_1(id);
		}
		default: iLen = formatex(szMenu, charsmax(szMenu), "\y%L \w[%d|%d]^n^n", id, "JBE_MENU_TREAT_PRISONER_TITLE", iPos + 1, iPagesNum);
	}
	
	new szName[32], i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++) {
		i = g_iMenuPlayers[id][a];
		get_user_name(i, szName, charsmax(szName));
		iKeys |= (1<<b);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d]\r ~ \w%s \r[%d HP]^n", ++b, szName, Float:rg_get_user_health(i));
	}
	
	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	if(iEnd < iPlayersNum) {
		iKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L^n\r(0) \y| \w%L", id, "JBE_MENU_NEXT", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r(0) \y| \w%L", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	
	return show_menu(id, iKeys, szMenu, -1, "Show_TreatPrisonerMenu");
}

public Handle_TreatPrisonerMenu(id, iKey) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	switch(iKey) {
		case 8: return Show_TreatPrisonerMenu(id, ++g_iMenuPosition[id]);
		case 9: return Show_TreatPrisonerMenu(id, --g_iMenuPosition[id]);
		default: {
			new iTarget = g_iMenuPlayers[id][g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey];
			if(g_iUserTeam[iTarget] == 1 && IsSetBit(g_iBitUserAlive, iTarget) && Float:rg_get_user_health(iTarget) < 100.0 && IsNotSetBit(g_iBitUserBoxing, id) && IsNotSetBit(g_iBitUserDuel, id))
			{
				new szName[32], szTargetName[32];
				get_user_name(id, szName, charsmax(szName));
				get_user_name(iTarget, szTargetName, charsmax(szTargetName));
				client_print_color(0, print_team_default, "^1[^4INFO^1] %L", LANG_PLAYER, "JBE_CHAT_ALL_CHIEF_TREAT_PRISONER", szName, szTargetName);
				set_pev(iTarget, pev_health, 100.0);
			}
		}
	}
	return Show_TreatPrisonerMenu(id, g_iMenuPosition[id]);
}

Show_ChiefMenu_2(id) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new szMenu[1024], iKeys = (1<<0|1<<4|1<<5|1<<8|1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_CHIEF_TITLE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_CHIEF_VOICE_CONTROL");
	if(g_iDayMode == 1) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_MENU_CHIEF_PRISONERS_DIVIDE_COLOR");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L^n", id, "JBE_MENU_CHIEF_MINI_GAME");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L^n^n", id, "JBE_MENU_CHIEF_GAME_TITLE");
		iKeys |= (1<<1|1<<2|1<<3);
	}
	else {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L^n", id, "JBE_MENU_CHIEF_PRISONERS_DIVIDE_COLOR");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L^n", id, "JBE_MENU_CHIEF_MINI_GAME");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L^n^n", id, "JBE_MENU_CHIEF_GAME_TITLE");
	}
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L \d[\r%s\d]^n", id, "JBE_MENU_CHIEF_SIMON_VOICE", bIsSetmodBit(g_iChiefVoice) ? "Активно":"Неактивно");
	
	if(get_gametime() - g_fChiefCoolDown > 20.0) {
		if(IsSetBit(g_iBitUserAdmin, id))  {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \w%L^n^n", id, "JBE_MENU_CHIEF_BALANS_HP");
			iKeys |= (1<<5);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \d%L \w[\rАдмин\w]^n^n", id, "JBE_MENU_CHIEF_BALANS_HP");
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \d%L [Cooldown %d sec]^n^n", id, "JBE_MENU_CHIEF_BALANS_HP", 20 - abs(floatround(g_fChiefCoolDown - get_gametime())));
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L", id, "JBE_MENU_BACK");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_ChiefMenu_2");
}

public Handle_ChiefMenu_2(id, iKey) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	switch(iKey) {
		case 0: return Cmd_VoiceControlMenu(id);
		case 1: return Show_PrsnDColorMenu(id);
		case 2: return Show_MiniGameMenu(id);
		case 3: return Show_ChiefGameMenu(id);
		case 4: bInvertModBit(g_iChiefVoice);
		case 5: {
			g_fChiefCoolDown = get_gametime();
			for(new tempID = 1; tempID <= MaxClients; tempID++)
				if(Float:rg_get_user_health(tempID) > 310.0) rg_set_user_health(tempID, 300.0);
			client_print_color(0, print_team_default, "^1[^4INFO^1] Начальник провёл ^4Калибровку Жизней^1. У кого жизней больше, чем 300 - уменьшилось.");
		}
		case 8: return Show_ChiefMenu_1(id);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_ChiefMenu_2(id);
}

Cmd_VoiceControlMenu(id) return Show_VoiceControlMenu(id, g_iMenuPosition[id] = 0);

public Show_VoiceControlMenu(id, iPos) {
	if(iPos < 0) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++) {
		if(IsNotSetBit(g_iBitUserAlive, i) || g_iUserTeam[i] != 1) continue;
		g_iMenuPlayers[id][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum) {
		case 0: {
			client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_ChiefMenu_2(id);
		}
		default: iLen = formatex(szMenu, charsmax(szMenu), "\y%L \w[%d|%d]^n^n", id, "JBE_MENU_VOICE_CONTROL_TITLE", iPos + 1, iPagesNum);
	}
	
	new szName[32], i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++) {
		i = g_iMenuPlayers[id][a];
		get_user_name(i, szName, charsmax(szName));
		iKeys |= (1<<b);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d]\r ~ \w%s %L^n", ++b, szName, id, IsSetBit(g_iBitUserVoice, i) ? "JBE_MENU_CHIEF_VOICE_CONTROL_TAKE" : "JBE_MENU_CHIEF_VOICE_CONTROL_GIVE");
	}

	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	if(iEnd < iPlayersNum) {
		iKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L^n\r(0) \y| \w%L", id, "JBE_MENU_NEXT", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r(0) \y| \w%L", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	
	return show_menu(id, iKeys, szMenu, -1, "Show_VoiceControlMenu");
}

public Handle_VoiceControlMenu(id, iKey) {
	switch(iKey) {
		case 8: return Show_VoiceControlMenu(id, ++g_iMenuPosition[id]);
		case 9: return Show_VoiceControlMenu(id, --g_iMenuPosition[id]);
		default: {
			new iTarget = g_iMenuPlayers[id][g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey];
			if(IsNotSetBit(g_iBitUserAlive, iTarget) || g_iUserTeam[iTarget] != 1) return Show_VoiceControlMenu(id, g_iMenuPosition[id]);
			new szName[32], szTargetName[32];
			get_user_name(id, szName, charsmax(szName));
			get_user_name(iTarget, szTargetName, charsmax(szTargetName));
			if(IsSetBit(g_iBitUserVoice, iTarget)) {
				ClearBit(g_iBitUserVoice, iTarget);
				if(id == g_iChiefId) client_print_color(0, print_team_default, "^1[^4INFO^1] %L", LANG_PLAYER, "JBE_CHAT_ALL_CHIEF_TAKE_VOICE", szName, szTargetName);
				else client_print_color(0, print_team_default, "^1[^4INFO^1] %L", LANG_PLAYER, "JBE_CHAT_ALL_SADMIN_TAKE_VOICE", szName, szTargetName);
			}
			else {
				SetBit(g_iBitUserVoice, iTarget);
				if(id == g_iChiefId) client_print_color(0, print_team_default, "^1[^4INFO^1] %L", LANG_PLAYER, "JBE_CHAT_ALL_CHIEF_GIVE_VOICE", szName, szTargetName);
				else client_print_color(0, print_team_default, "^1[^4INFO^1] %L", LANG_PLAYER, "JBE_CHAT_ALL_SADMIN_GIVE_VOICE", szName, szTargetName);
			}
		}
	}
	return Show_VoiceControlMenu(id, g_iMenuPosition[id]);
}

Show_PrsnDColorMenu(id) {
	if(g_iDayMode != 1 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new szMenu[256], iKeys = (1<<8|1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_PRISONERS_DIVIDE_COLOR_TITLE");
	if(g_iAlivePlayersNum[1] >= 2) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_PRISONERS_DIVIDE_COLOR_2");
		iKeys |= (1<<0);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L^n", id, "JBE_MENU_PRISONERS_DIVIDE_COLOR_2");
	
	if(g_iAlivePlayersNum[1] >= 3) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_MENU_PRISONERS_DIVIDE_COLOR_3");
		iKeys |= (1<<1);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L^n", id, "JBE_MENU_PRISONERS_DIVIDE_COLOR_3");
	
	if(g_iAlivePlayersNum[1] >= 4) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L^n^n^n^n^n^n", id, "JBE_MENU_PRISONERS_DIVIDE_COLOR_4");
		iKeys |= (1<<2);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L^n^n^n^n^n^n", id, "JBE_MENU_PRISONERS_DIVIDE_COLOR_4");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L", id, "JBE_MENU_BACK");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_PrsnDColorMenu");
}

public Handle_PrsnDColorMenu(id, iKey) {
	if(g_iDayMode != 1 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	switch(iKey) {
		case 8: return Show_ChiefMenu_2(id);
		case 9: return PLUGIN_HANDLED;
		default: jbe_prisoners_divide_color(iKey + 2);
	}
	return Show_ChiefMenu_2(id);
}

Show_MiniGameMenu(id) {
	if(g_iDayMode != 1 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new szMenu[512], iKeys = (1<<0|1<<1|1<<4|1<<8|1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_MINI_GAME_TITLE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_MINI_GAME_SOCCER");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_MENU_MINI_GAME_BOXING");
	
	if(get_gametime() - g_fChiefCoolDown > 10.0) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L^n", id, "JBE_MENU_MINI_GAME_SPRAY");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L^n", id, "JBE_MENU_MINI_GAME_DISTANCE_DROP");
		iKeys |= (1<<2|1<<3);
	}
	else {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L [Cooldown: %d sec]^n", id, "JBE_MENU_MINI_GAME_SPRAY", 10 - abs(floatround(g_fChiefCoolDown - get_gametime())));
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L [Cooldown: %d sec]^n", id, "JBE_MENU_MINI_GAME_DISTANCE_DROP", 10 - abs(floatround(g_fChiefCoolDown - get_gametime())));
	}
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L \r[%L]^n", id, "JBE_MENU_MINI_GAME_FRIENDLY_FIRE", id, g_iFriendlyFire ? "JBE_MENU_ENABLE" : "JBE_MENU_DISABLE");
		
	if(get_gametime() - g_fChiefCoolDown > 10) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \w%L^n^n", id, "JBE_MENU_MINI_GAME_RANDOM_SKIN");
		iKeys |= (1<<5);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \d%L [Cooldown: %d sec]^n^n", id, "JBE_MENU_MINI_GAME_RANDOM_SKIN", 10 - abs(floatround(g_fChiefCoolDown - get_gametime())));
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L", id, "JBE_MENU_BACK");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_MiniGameMenu");
}

public Handle_MiniGameMenu(id, iKey) {
	if(g_iDayMode != 1 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	switch(iKey) {
		case 0: return Show_SoccerMenu(id);
		case 1: return Show_BoxingMenu(id);
		case 2: {
			g_fChiefCoolDown = get_gametime();
			for(new i = 1; i <= MaxClients; i++) {
				if(g_iUserTeam[i] != 1 || IsNotSetBit(g_iBitUserAlive, i)) continue;
				set_member(i, m_flNextDecalTime, 0.0);
			}
			client_print_color(id, print_team_default, "^1[^4INFO^1] %L", LANG_PLAYER, "JBE_CHAT_ID_MINI_GAME_SPRAY");
		}
		case 3: {
			g_fChiefCoolDown = get_gametime();
			for(new i = 1; i <= MaxClients; i++) {
				if(g_iUserTeam[i] != 1 || IsNotSetBit(g_iBitUserAlive, i) || IsSetBit(g_iBitUserSoccer, i) || IsSetBit(g_iBitUserBoxing, i) || IsSetBit(g_iBitUserDuel, i)) continue;
				//rg_remove_item(i, "weapon_deagle");
				new iEntity = rg_give_item(i, "weapon_deagle", GT_REPLACE);
				if(iEntity > 0) set_member(iEntity, m_Weapon_iClip, -1);
			}
			client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_MINI_GAME_DISTANCE_DROP");
		}
		case 4: g_iFriendlyFire = !g_iFriendlyFire;
		case 5: {
			g_fChiefCoolDown = get_gametime();
			for(new i = 1; i <= MaxClients; i++) {
				if(g_iUserTeam[i] != 1 || IsNotSetBit(g_iBitUserAlive, i) || IsSetBit(g_iBitUserFree, i) || IsSetBit(g_iBitUserWanted, i) || IsSetBit(g_iBitUserSoccer, i) || IsSetBit(g_iBitUserBoxing, i) || IsSetBit(g_iBitUserDuel, i)) continue;
				set_entvar(i, var_skin, random_num(0, 3));
			}
			client_print_color(id, print_team_default, "^1[^4INFO^1] %L", LANG_PLAYER, "JBE_CHAT_ID_MINI_GAME_RANDOM_SKIN");
		}
		case 8: return Show_ChiefMenu_2(id);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_MiniGameMenu(id);
}

Show_ChiefGameMenu(id) {
	if(g_iDayMode != 1 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new iKeys = (1<<2|1<<3|1<<4|1<<8|1<<9);
	new szMenu[560], iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_CHIEF_GAME_TITLE");
	
	if(g_iAlivePlayersNum[1] < 7) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L [Мин. 7 зеков]^n", id, "JBE_MENU_MINI_GAME_HUNGRY_GAME");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L [Мин. 7 зеков]^n", id, "JBE_MENU_MINI_GAME_BUNT");
	}
	else {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_MINI_GAME_HUNGRY_GAME");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_MENU_MINI_GAME_BUNT");
		iKeys |= (1<<0|1<<1);
	}

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L^n^n", id, "JBE_MENU_MINI_GAME_HAMELEON");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L^n", id, "JBE_MENU_MINI_GAME_LACKY");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L^n^n", id, "JBE_MENU_MINI_GAME_RANDOM_NUM");
	
	if(~jbe_get_privileges_flags(id) & (1<<0)) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \w%L^n^n", id, "JBE_MENU_MINI_GAME_GIVE_WEAPON");
		iKeys |= (1<<5);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \d%L^n^n", id, "JBE_MENU_MINI_GAME_GIVE_WEAPON");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L", id, "JBE_MENU_BACK");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_ChiefGameMenu");
}

public Handle_ChiefGameMenu(id, iKey) {
	switch(iKey) {
		case 0: {
			for(new iG = 1; iG <= MaxClients; iG++) {
				if(g_iUserTeam[iG] == 1) {
					rg_give_item(iG, "weapon_deagle", GT_REPLACE);
					rg_set_user_bpammo(iG, WEAPON_DEAGLE, 32);
				}
			}
			client_print_color(0, print_team_default, "^1[^4INFO^1] Начальник начал игру^4 'Голодные Игры'");
			g_iFriendlyFire = !g_iFriendlyFire;
			jbe_open_doors();
		}
		case 1: {
			for(new iG = 1; iG <= MaxClients; iG++) {
				switch(g_iUserTeam[iG]) {
					case 1: {
						rg_give_item(iG, "weapon_ak47", GT_REPLACE);
						rg_set_user_bpammo(iG, WEAPON_AK47, 90);
						jbe_add_user_wanted(iG);
					}
					case 2: {
						rg_set_user_health(iG, Float:rg_get_user_health(iG) + 200.0);
						rg_give_item(iG, "weapon_m4a1");
						rg_set_user_bpammo(iG, WEAPON_M4A1, 90);
					}
				}
			}
			client_print_color(0, print_team_default, "^1[^4INFO^1] Начальник начал игру^4 'Бунт'");
			jbe_open_doors();
		}
		case 2: {
			for(new iG = 1; iG <= MaxClients; iG++) {
				if(IsSetBit(g_iBitUserAlive, iG)) {
					if(g_iUserTeam[iG] == 1) {
						new szRandom = random_num(1, 2);
						switch(szRandom) {
							case 1: rg_set_user_rendering(iG, kRenderFxGlowShell, 255, 255, 0, kRenderNormal, 0);
							case 2: rg_set_user_rendering(iG, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 0);
						}
					}
				}
			}
			client_print_color(0, print_team_default, "^1[^4INFO^1] Начальник начал игру^4 'Хамелеон'");
		}
		case 3: {
			new iLucky = random_num(0, 1);
			switch(iLucky) {
				case true: client_print_color(0, print_team_default, "^1[^4INFO^1][^4Счасливчк^1] Тебе: ^4Повезло^1/^4Удачно");
				case false: client_print_color(0, print_team_default, "^1[^4INFO^1][^4Счасливчк^1] Тебе: ^3Не повезло^1/^3Неудачно");
			}
			return Show_ChiefGameMenu(id);
		}
		case 4: return Show_RandomChiefNum(id);
		case 5: return Show_ChiefWeaponsMenu(id);
		case 8: return Show_ChiefMenu_2(id);
		case 9: return PLUGIN_HANDLED;	
	}
	return PLUGIN_HANDLED;
}

Show_RandomChiefNum(id) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new szMenu[128], iKeys = (1<<0|1<<1|1<<2|1<<8|1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_RANDOMNUM");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[1] \w%L \r[%d]^n", id, "JBE_RANDOMNUM_NUM", g_iRandNum_Num[id]);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[2] \w%L \r[%s]^n", id, "JBE_RANDOMNUM_TYPE", bIsSetmodBit(g_bRandNum_Type) ? "Только КТ":"Всем");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[3] \w%L^n^n", id, "JBE_RANDOMNUM_GO");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\y[9] \w%L", id, "JBE_MENU_BACK");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\y[0] \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_RandomChiefNum");
}

public Handle_RandomNum(id, iKey) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	switch(iKey) {
		case 0: client_cmd(id, "messagemode simon_rand_num");
		case 1: bInvertModBit(g_bRandNum_Type); 
		case 2: RandomNum_FuncGo(id);
		case 8: return Show_ChiefGameMenu(id);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_RandomChiefNum(id);
}

public RandomNum_Num(id) {
	new Args[15];
	read_args(Args, charsmax(Args));
	remove_quotes(Args);
	if(strlen(Args) >= 4) {
		client_print_color(id, print_team_red, "^1[^4INFO^1] Вы ввели слишком ^3большое ^1число");
		return PLUGIN_HANDLED;
	}
	if(strlen(Args) == 0) {
		client_print_color(id, print_team_red, "^1[^4INFO^1] Пустое значение ^3невозможно");
		return PLUGIN_HANDLED;
	}
	for(new x; x < strlen(Args); x++) {
		if(!isdigit(Args[x])) {
			client_print_color(id, print_team_red, "^1[^4INFO^1] Сумма должна быть только ^3числом");
			return PLUGIN_HANDLED;
		}
	}
	new szAmount = str_to_num(Args);
	g_iRandNum_Num[id] = szAmount;
	return Show_RandomChiefNum(id);
}

public RandomNum_FuncGo(id) {
	if(bIsSetmodBit(g_bRandNum_Type)) {
		for(new ct; ct <= MaxClients; ct++)  {
			if(g_iUserTeam[ct] == 2) client_print_color(ct, print_team_default, "^1[^4INFO^1][^4Охрана^1] ^3Начальник ^1выбрал случайное число:^3 %d", random_num(1, g_iRandNum_Num[id]));
		}
	}
	else client_print_color(0, print_team_default, "^1[^4INFO^1][^4Всем^1] ^3Начальник ^1выбрал случайное число:^3 %d", random_num(1, g_iRandNum_Num[id]));
}

Show_ChiefWeaponsMenu(id) {
	if(g_iDayMode != 1 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new szMenu[256], iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_WEAPONS_GAME_TITLE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[1] \w%L^n", id, "JBE_MENU_GLOBAL_GAME_AK47");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[2] \w%L^n", id, "JBE_MENU_GLOBAL_GAME_M4A1");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[3] \w%L^n", id, "JBE_MENU_GLOBAL_GAME_AWP");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[4] \w%L^n", id, "JBE_MENU_GLOBAL_GAME_XM1014");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\y[9] \w%L", id, "JBE_MENU_BACK");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\y[0] \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<8|1<<9), szMenu, -1, "Show_ChiefWeaponsMenu");
}

public Handle_ChiefWeaponsMenu(id, iKey) {
	if(g_iDayMode != 1 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	switch(iKey) {
		case 0: {
			for(new i = 1; i <= MaxClients; i++) {
				if(g_iUserTeam[i] != 1 || IsNotSetBit(g_iBitUserAlive, i) || IsSetBit(g_iBitUserFree, i) || IsSetBit(g_iBitUserWanted, i) || IsSetBit(g_iBitUserSoccer, i) || IsSetBit(g_iBitUserBoxing, i) || IsSetBit(g_iBitUserDuel, i)) continue;
				rg_give_item(i, "weapon_ak47", GT_REPLACE);
				rg_set_user_bpammo(i, WEAPON_AK47, 250);
				rg_drop_items_by_slot(i, PISTOL_SLOT);
			}
		}
		case 1: {
			for(new i = 1; i <= MaxClients; i++) {
				if(g_iUserTeam[i] != 1 || IsNotSetBit(g_iBitUserAlive, i) || IsSetBit(g_iBitUserFree, i) || IsSetBit(g_iBitUserWanted, i) || IsSetBit(g_iBitUserSoccer, i) || IsSetBit(g_iBitUserBoxing, i) || IsSetBit(g_iBitUserDuel, i)) continue;
				rg_give_item(i, "weapon_m4a1", GT_REPLACE);
				rg_set_user_bpammo(i, WEAPON_AK47, 250);
				rg_drop_items_by_slot(i, PISTOL_SLOT);
			}
		}		
		case 2: {
			for(new i = 1; i <= MaxClients; i++) {
				if(g_iUserTeam[i] != 1 || IsNotSetBit(g_iBitUserAlive, i) || IsSetBit(g_iBitUserFree, i) || IsSetBit(g_iBitUserWanted, i) || IsSetBit(g_iBitUserSoccer, i) || IsSetBit(g_iBitUserBoxing, i) || IsSetBit(g_iBitUserDuel, i)) continue;
				rg_give_item(i, "weapon_awp", GT_REPLACE);
				rg_set_user_bpammo(i, WEAPON_AWP, 250);
				rg_drop_items_by_slot(i, PISTOL_SLOT);
			}
		}
		case 3: {
			for(new i = 1; i <= MaxClients; i++)
			{
				if(g_iUserTeam[i] != 1 || IsNotSetBit(g_iBitUserAlive, i) || IsSetBit(g_iBitUserFree, i) || IsSetBit(g_iBitUserWanted, i) || IsSetBit(g_iBitUserSoccer, i) || IsSetBit(g_iBitUserBoxing, i) || IsSetBit(g_iBitUserDuel, i)) continue;
				rg_give_item(i, "weapon_xm1014", GT_REPLACE);
				rg_set_user_bpammo(i, WEAPON_AK47, 250);
				rg_drop_items_by_slot(i, PISTOL_SLOT);
			}
		}
		case 8: return Show_ChiefGameMenu(id);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_ChiefWeaponsMenu(id);
}

Show_SoccerMenu(id) {
	if(g_iDayMode != 1 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new szMenu[512], iKeys = (1<<0|1<<8|1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_SOCCER_TITLE");
	if(bIsSetmodBit(g_bSoccerStatus)) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_SOCCER_DISABLE");
		
		if(g_iSoccerBall) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_MENU_SOCCER_SUB_BALL");
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L^n", id, "JBE_MENU_SOCCER_UPDATE_BALL");
			
			if(bIsSetmodBit(g_bSoccerGame)) {
				iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L^n", id, "JBE_MENU_SOCCER_WHISTLE");
				iKeys |= (1<<3);
			}
			else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L^n", id, "JBE_MENU_SOCCER_WHISTLE");
			
			if(bIsSetmodBit(g_bSoccerGame)) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L^n", id, "JBE_MENU_SOCCER_GAME_END");
			else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L^n", id, "JBE_MENU_SOCCER_GAME_START");
			iKeys |= (1<<2|1<<4);
		}
		else {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_MENU_SOCCER_ADD_BALL");
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L^n", id, "JBE_MENU_SOCCER_UPDATE_BALL");
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L^n", id, "JBE_MENU_SOCCER_WHISTLE");
			
			if(bIsSetmodBit(g_bSoccerGame)) {
				iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L^n", id, "JBE_MENU_SOCCER_GAME_END");
				iKeys |= (1<<4);
			}
			else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L^n", id, "JBE_MENU_SOCCER_GAME_START");
		}
		
		if(bIsSetmodBit(g_bSoccerGame)) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \d%L^n", id, "JBE_MENU_SOCCER_TEAMS");
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(7) \y| \w%L^n^n", id, "JBE_MENU_SOCCER_SCORE");
			iKeys |= (1<<6);
		}
		else {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \w%L^n", id, "JBE_MENU_SOCCER_TEAMS");
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(7) \y| \d%L^n^n", id, "JBE_MENU_SOCCER_SCORE");
			iKeys |= (1<<5);
		}
		iKeys |= (1<<1);
	}
	else {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_SOCCER_ENABLE");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L^n", id, "JBE_MENU_SOCCER_ADD_BALL");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L^n", id, "JBE_MENU_SOCCER_UPDATE_BALL");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L^n", id, "JBE_MENU_SOCCER_WHISTLE");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L^n", id, "JBE_MENU_SOCCER_GAME_END");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \d%L^n", id, "JBE_MENU_SOCCER_TEAMS");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(7) \y| \d%L^n^n", id, "JBE_MENU_SOCCER_SCORE");
	}
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L", id, "JBE_MENU_BACK");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_SoccerMenu");
}

public Handle_SoccerMenu(id, iKey) {
	if(g_iDayMode != 1 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	switch(iKey) {
		case 0: {
			if(bIsSetmodBit(g_bSoccerStatus)) jbe_soccer_disable_all();
			else bSetModBit(g_bSoccerStatus);
		}
		case 1: {
			if(g_iSoccerBall) jbe_soccer_remove_ball();
			else jbe_soccer_create_ball(id);
		}
		case 2: if(g_iSoccerBall) jbe_soccer_update_ball();
		case 3: {
			if(bIsSetmodBit(g_bSoccerGame) && g_iSoccerBall) {
				rh_emit_sound2(id, id, CHAN_AUTO, "egoist/jb/soccer/whitle_start.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				bSetModBit(g_bSoccerBallTouch);
			}
		}
		case 4: {
			if(bIsSetmodBit(g_bSoccerGame)) jbe_soccer_game_end(id);
			else if(g_iSoccerBall) jbe_soccer_game_start(id);
		}
		case 5: if(bIsNotSetModBit(g_bSoccerGame)) return Show_SoccerTeamMenu(id);
		case 6: if(bIsSetmodBit(g_bSoccerGame)) return Show_SoccerScoreMenu(id);
		case 8: return Show_MiniGameMenu(id);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_SoccerMenu(id);
}

Show_SoccerTeamMenu(id) {
	if(bIsSetmodBit(g_bSoccerGame) || g_iDayMode != 1 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new szMenu[512], iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_SOCCER_TEAM_TITLE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_SOCCER_TEAM_DIVIDE_PRISONERS");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_MENU_SOCCER_TEAM_DIVIDE_ALL");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d%L^n", id, "JBE_MENU_SOCCER_TEAM_DESCRIPTION");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \w%L^n", id, "JBE_MENU_SOCCER_TEAM_ADD_RED");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(7) \y| \w%L^n", id, "JBE_MENU_SOCCER_TEAM_ADD_BLUE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(8) \y| \w%L^n", id, "JBE_MENU_SOCCER_TEAM_SUB");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L", id, "JBE_MENU_BACK");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, (1<<0|1<<1|1<<5|1<<6|1<<7|1<<8|1<<9), szMenu, -1, "Show_SoccerTeamMenu");
}

public Handle_SoccerTeamMenu(id, iKey) {
	if(bIsSetmodBit(g_bSoccerGame) || g_iDayMode != 1 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	switch(iKey) {
		case 0: jbe_soccer_divide_team(1);
		case 1: jbe_soccer_divide_team(0);
		case 7: {
			new iTarget, iBody;
			get_user_aiming(id, iTarget, iBody, 9999);
			if(jbe_is_user_valid(iTarget) && IsSetBit(g_iBitUserSoccer, iTarget)) {
				ClearBit(g_iBitUserSoccer, iTarget);
				if(iTarget == g_iSoccerBallOwner) {
					CREATE_KILLPLAYERATTACHMENTS(iTarget);
					set_entvar(g_iSoccerBall, var_solid, SOLID_TRIGGER);
					set_entvar(g_iSoccerBall, var_velocity, Float:{0.0, 0.0, 0.1});
					g_iSoccerBallOwner = 0;
				}
				
				if(IsSetBit(g_iBitClothingGuard, iTarget) && IsSetBit(g_iBitClothingType, iTarget)) jbe_set_user_model(iTarget, g_szPlayerModel[GUARD]);
				else jbe_default_player_model(iTarget);
				set_member(iTarget, m_bloodColor, 247);
				new iActiveItem = get_member(iTarget, m_pActiveItem);
				if(iActiveItem > 0) {
					ExecuteHamB(Ham_Item_Deploy, iActiveItem);
					UTIL_WeaponAnimation(iTarget, 3);
				}
			}
			else client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_SoccerTeamMenu(id);
		}
		case 8: return Show_SoccerMenu(id);
		case 9: return PLUGIN_HANDLED;
		default: {
			new iTarget, iBody;
			get_user_aiming(id, iTarget, iBody, 9999);
			if(jbe_is_user_valid(iTarget) && IsSetBit(g_iBitUserAlive, iTarget) && IsNotSetBit(g_iBitUserDuel, iTarget) && (g_iUserTeam[iTarget] == 1 && IsNotSetBit(g_iBitUserFree, iTarget) && IsNotSetBit(g_iBitUserWanted, iTarget) && IsNotSetBit(g_iBitUserBoxing, iTarget) || g_iUserTeam[iTarget] == 2)) {
				new szLangPlayer[][] = {"JBE_HUD_ID_YOU_TEAM_RED", "JBE_HUD_ID_YOU_TEAM_BLUE"};
				client_print_color(iTarget, print_team_default, "^1[^4INFO^1] %L", iTarget, szLangPlayer[iKey - 5]);
				if(IsNotSetBit(g_iBitUserSoccer, iTarget)) {
					SetBit(g_iBitUserSoccer, iTarget);
					jbe_set_user_model(iTarget, g_szPlayerModel[FOOTBALLER]);
					if(get_user_weapon(iTarget) != CSW_KNIFE) rg_internal_cmd(iTarget, "weapon_knife");
					else {
						new iActiveItem = get_member(iTarget, m_pActiveItem);
						if(iActiveItem > 0) {
							ExecuteHamB(Ham_Item_Deploy, iActiveItem);
							UTIL_WeaponAnimation(iTarget, 3);
						}
					}
					set_member(iTarget, m_bloodColor, -1);
					ClearBit(g_iBitClothingType, iTarget);
				}
				set_entvar(iTarget, var_skin, iKey - 5);
				g_iSoccerUserTeam[iTarget] = iKey - 5;
			}
			else client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_SoccerTeamMenu(id);
		}
	}
	return Show_SoccerMenu(id);
}

Show_SoccerScoreMenu(id) {
	if(bIsNotSetModBit(g_bSoccerGame) || g_iDayMode != 1 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new szMenu[512], iKeys = (1<<0|1<<2|1<<4|1<<8|1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_SOCCER_SCORE_TITLE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_SOCCER_SCORE_RED_ADD");
	
	if(g_iSoccerScore[0]) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_MENU_SOCCER_SCORE_RED_SUB");
		iKeys |= (1<<1);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L^n", id, "JBE_MENU_SOCCER_SCORE_RED_SUB");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L^n", id, "JBE_MENU_SOCCER_SCORE_BLUE_ADD");
	
	if(g_iSoccerScore[1]) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L^n", id, "JBE_MENU_SOCCER_SCORE_BLUE_SUB");
		iKeys |= (1<<3);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L^n", id, "JBE_MENU_SOCCER_SCORE_BLUE_SUB");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L^n^n^n^n", id, "JBE_MENU_SOCCER_SCORE_RESET");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L", id, "JBE_MENU_BACK");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_SoccerScoreMenu");
}

public Handle_SoccerScoreMenu(id, iKey) {
	if(bIsNotSetModBit(g_bSoccerGame) || g_iDayMode != 1 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	switch(iKey) {
		case 0: g_iSoccerScore[0]++;
		case 1: g_iSoccerScore[0]--;
		case 2: g_iSoccerScore[1]++;
		case 3: g_iSoccerScore[1]--;
		case 4: g_iSoccerScore = {0, 0};
		case 8: return Show_SoccerMenu(id);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_SoccerScoreMenu(id);
}

Show_BoxingMenu(id) {
	if(g_iDayMode != 1 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new szMenu[512], iKeys = (1<<0|1<<8|1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_BOXING_TITLE");
	if(bIsSetmodBit(g_bBoxingStatus)) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_BOXING_DISABLE");
		
		if(g_iBoxingGame == 2) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L^n", id, "JBE_MENU_BOXING_GAME_START");
		else {
			if(g_iBoxingGame == 1) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_MENU_BOXING_GAME_END");
			else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_MENU_BOXING_GAME_START");
			iKeys |= (1<<1);
		}
		
		if(g_iBoxingGame == 1) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L^n", id, "JBE_MENU_BOXING_GAME_TEAM_START");
		else {
			if(g_iBoxingGame == 2) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L^n", id, "JBE_MENU_BOXING_GAME_TEAM_END");
			else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L^n", id, "JBE_MENU_BOXING_GAME_TEAM_START");
			iKeys |= (1<<2);
		}
		
		if(g_iBoxingGame) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L^n^n^n^n^n", id, "JBE_MENU_BOXING_TEAMS");
		else {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L^n^n^n^n^n", id, "JBE_MENU_BOXING_TEAMS");
			iKeys |= (1<<3);
		}
	}
	else {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_BOXING_ENABLE");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L^n", id, "JBE_MENU_BOXING_GAME_START");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L^n", id, "JBE_MENU_BOXING_GAME_TEAM_START");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L^n^n^n^n^n", id, "JBE_MENU_BOXING_TEAMS");
	}
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L", id, "JBE_MENU_BACK");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_BoxingMenu");
}

public Handle_BoxingMenu(id, iKey) {
	if(g_iDayMode != 1 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	switch(iKey) {
		case 0: {
			if(bIsSetmodBit(g_bBoxingStatus)) jbe_boxing_disable_all();
			else {
				bSetModBit(g_bBoxingStatus);
				g_iFakeMetaUpdateClientData = register_forward(FM_UpdateClientData, "FakeMeta_UpdateClientData_Post", 1);
			}
		}
		case 1: {
			if(g_iBoxingGame == 1) jbe_boxing_game_end();
			else jbe_boxing_game_start(id);
		}
		case 2: {
			if(g_iBoxingGame == 2) jbe_boxing_game_end();
			else jbe_boxing_game_team_start(id);
		}
		case 3: if(!g_iBoxingGame) return Show_BoxingTeamMenu(id);
		case 8: return Show_MiniGameMenu(id);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_BoxingMenu(id);
}

Show_BoxingTeamMenu(id) {
	if(g_iBoxingGame || g_iDayMode != 1 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new szMenu[512], iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_BOXING_TEAM_TITLE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_BOXING_TEAM_DIVIDE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d%L^n", id, "JBE_MENU_BOXING_TEAM_DESCRIPTION");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L^n", id, "JBE_MENU_BOXING_TEAM_ADD_RED");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \w%L^n", id, "JBE_MENU_BOXING_TEAM_ADD_BLUE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(7) \y| \w%L^n^n", id, "JBE_MENU_BOXING_TEAM_SUB");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L", id, "JBE_MENU_BACK");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, (1<<0|1<<4|1<<5|1<<6|1<<8|1<<9), szMenu, -1, "Show_BoxingTeamMenu");
}

public Handle_BoxingTeamMenu(id, iKey) {
	if(g_iBoxingGame || g_iDayMode != 1 || id != g_iChiefId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	switch(iKey) {
		case 0: jbe_boxing_divide_team();
		case 6: {
			new iTarget, iBody;
			get_user_aiming(id, iTarget, iBody, 9999);
			if(jbe_is_user_valid(iTarget) && IsSetBit(g_iBitUserBoxing, iTarget)) {
				ClearBit(g_iBitUserBoxing, iTarget);
				new iActiveItem = get_member(iTarget, m_pActiveItem);
				if(iActiveItem > 0) {
					ExecuteHamB(Ham_Item_Deploy, iActiveItem);
					UTIL_WeaponAnimation(iTarget, 3);
				}
				rg_set_user_health(iTarget, 100.0);
				set_member(iTarget, m_bloodColor, 247);
			}
			else client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_BoxingTeamMenu(id);
		}
		case 8: return Show_BoxingMenu(id);
		case 9: return PLUGIN_HANDLED;
		default: {
			new iTarget, iBody;
			get_user_aiming(id, iTarget, iBody, 9999);
			if(jbe_is_user_valid(iTarget) && g_iUserTeam[iTarget] == 1 && IsSetBit(g_iBitUserAlive, iTarget) && IsNotSetBit(g_iBitUserFree, iTarget) && IsNotSetBit(g_iBitUserWanted, iTarget) && IsNotSetBit(g_iBitUserSoccer, iTarget) && IsNotSetBit(g_iBitUserDuel, iTarget)) {
				if(IsNotSetBit(g_iBitUserBoxing, iTarget)) {
					SetBit(g_iBitUserBoxing, iTarget);
					rg_set_user_health(iTarget, 100.0);
					set_member(iTarget, m_bloodColor, -1);
					ClearBit(g_iBitClothingType, iTarget);
				}
				g_iBoxingUserTeam[iTarget] = iKey - 4;
				if(get_user_weapon(iTarget) != CSW_KNIFE) rg_internal_cmd(iTarget, "weapon_knife");
				else {
					new iActiveItem = get_member(iTarget, m_pActiveItem);
					if(iActiveItem > 0) {
						ExecuteHamB(Ham_Item_Deploy, iActiveItem);
						UTIL_WeaponAnimation(iTarget, 3);
					}
				}
			}
			else client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_BoxingTeamMenu(id);
		}
	}
	return Show_BoxingMenu(id);
}

Show_KillReasonsMenu(id, iTarget) {
	jbe_informer_offset_up(id);
	jbe_menu_block(id);
	new szName[32], szMenu[516], iLen;
	get_user_name(iTarget, szName, charsmax(szName));
	iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_KILL_REASON_TITLE", szName);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_KILL_REASON_0");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_MENU_KILL_REASON_1");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L^n", id, "JBE_MENU_KILL_REASON_2");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L^n", id, "JBE_MENU_KILL_REASON_3");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L^n", id, "JBE_MENU_KILL_REASON_4");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \w%L^n", id, "JBE_MENU_KILL_REASON_5");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(7) \y| \w%L^n", id, "JBE_MENU_KILL_REASON_6");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(8) \y| \w%L^n", id, "JBE_MENU_KILL_REASON_7");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L", id, "JBE_MENU_BACK");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \d%L", id, "JBE_MENU_EXIT");
	return show_menu(id, (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8), szMenu, -1, "Show_KillReasonsMenu");
}

public Handle_KillReasonsMenu(id, iKey) {
	switch(iKey) {
		case 8: return Cmd_KilledUsersMenu(id);
		default: {
			if(IsSetBit(g_iBitKilledUsers[id], g_iMenuTarget[id])) {
				new szName[32], szNameTarget[32], szLangPlayer[32];
				get_user_name(id, szName, charsmax(szName));
				get_user_name(g_iMenuTarget[id], szNameTarget, charsmax(szNameTarget));
				formatex(szLangPlayer, charsmax(szLangPlayer), "JBE_MENU_KILL_REASON_%d", iKey);
				client_print_color(0, print_team_default, "^1[^4INFO^1] %L", LANG_PLAYER, "JBE_CHAT_ALL_KILL_REASON", szName, szNameTarget, LANG_PLAYER, szLangPlayer);
				if(iKey == 7) {
					client_print_color(0, print_team_default, "^1[^4INFO^1] %L", LANG_PLAYER, "JBE_CHAT_ALL_AUTO_FREE_DAY", szNameTarget);
					jbe_add_user_free_next_round(g_iMenuTarget[id]);
				}
				ClearBit(g_iBitKilledUsers[id], g_iMenuTarget[id]);
				if(g_iBitKilledUsers[id]) return Cmd_KilledUsersMenu(id);
				jbe_menu_unblock(id);
			}
			else {
				if(g_iBitKilledUsers[id]) return Cmd_KilledUsersMenu(id);
				client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_KILLED_USER_DISCONNECT");
				jbe_menu_unblock(id);
			}
		}
	}
	return PLUGIN_HANDLED;
}

Cmd_KilledUsersMenu(id) return Show_KilledUsersMenu(id, g_iMenuPosition[id] = 0);

Show_KilledUsersMenu(id, iPos) {
	if(iPos < 0) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++) {
		if(IsNotSetBit(g_iBitKilledUsers[id], i)) continue;
		g_iMenuPlayers[id][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum) {
		case 0: {
			client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_KILLED_USER_DISCONNECT");
			jbe_menu_unblock(id);
			return PLUGIN_HANDLED;
		}
		default: iLen = formatex(szMenu, charsmax(szMenu), "\y%L \w[%d|%d]^n^n", id, "JBE_MENU_KILLED_USERS_TITLE", iPos + 1, iPagesNum);
	}
	
	new szName[32], i, iKeys, b;
	for(new a = iStart; a < iEnd; a++) {
		i = g_iMenuPlayers[id][a];
		get_user_name(i, szName, charsmax(szName));
		iKeys |= (1<<b);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d]\r ~ \w%s^n", ++b, szName);
	}
	
	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	if(iEnd < iPlayersNum) {
		iKeys |= (1<<8);
		if(iPos) {
			formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L^n\r(0) \y| \w%L", id, "JBE_MENU_NEXT", id, "JBE_MENU_BACK");
			iKeys |= (1<<9);
		}
		else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L^n\r(0) \y| \d%L", id, "JBE_MENU_NEXT", id, "JBE_MENU_EXIT");
	}
	else {
		if(iPos) {
			formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r(0) \y| \w%L", id, "JBE_MENU_BACK");
			iKeys |= (1<<9);
		}
		else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r(0) \y| \d%L", id, "JBE_MENU_EXIT");
	}
	return show_menu(id, iKeys, szMenu, -1, "Show_KilledUsersMenu");
}

public Handle_KilledUsersMenu(id, iKey) {
	switch(iKey) {
		case 8: return Show_KilledUsersMenu(id, ++g_iMenuPosition[id]);
		case 9: return Show_KilledUsersMenu(id, --g_iMenuPosition[id]);
		default: {
			g_iMenuTarget[id] = g_iMenuPlayers[id][g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey];
			if(IsSetBit(g_iBitKilledUsers[id], g_iMenuTarget[id])) return Show_KillReasonsMenu(id, g_iMenuTarget[id]);
			else if(g_iBitKilledUsers[id]) return Cmd_KilledUsersMenu(id);
			client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_KILLED_USER_DISCONNECT");
			jbe_menu_unblock(id);
		}
	}
	return PLUGIN_HANDLED;
}

Show_LastPrisonerMenu(id) {
	if(g_iDuelStatus || IsNotSetBit(g_iBitUserAlive, id) || id != g_iLastPnId) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new szMenu[290], iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_LAST_PRISONER_TITLE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_LAST_PRISONER_FREE_DAY");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_MENU_LAST_PRISONER_MONEY", g_iAllCvars[LAST_PRISONER_MODEY]);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L^n", id, "JBE_MENU_LAST_PRISONER_VOICE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L^n", id, "JBE_MENU_LAST_TAKE_WEAPONS");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L^n^n^n^n", id, "JBE_MENU_LAST_PRISONER_CHOICE_DUEL");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L", id, "JBE_MENU_BACK");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, (1<<0|1<<1|1<<2|1<<3|1<<4|1<<8|1<<9), szMenu, -1, "Show_LastPrisonerMenu");
}

public Handle_LastPrisonerMenu(id, iKey) {
	if(g_iDuelStatus || IsNotSetBit(g_iBitUserAlive, id) || id != g_iLastPnId) return PLUGIN_HANDLED;
	switch(iKey) {
		case 0: {
			ExecuteHamB(Ham_Killed, id, id, 0);
			jbe_add_user_free_next_round(id);
		}
		case 1: {
			ExecuteHamB(Ham_Killed, id, id, 0);
			jbe_set_user_money(id, jbe_get_user_money(id) + g_iAllCvars[LAST_PRISONER_MODEY], true);
		}
		case 2: {
			ExecuteHamB(Ham_Killed, id, id, 0);
			SetBit(g_iBitUserVoiceNextRound, id);
		}
		case 3: {
			for(new i = 1; i <= MaxClients; i++) {
				if(IsNotSetBit(g_iBitUserAlive, i) || g_iUserTeam[i] != 2) continue;
				rg_remove_items_by_slot(i, PISTOL_SLOT);
			}
			rg_give_item(id, "weapon_ak47", GT_REPLACE);
			rg_set_user_bpammo(id, WEAPON_AK47, 200);
			g_iLastPnId = 0;
		}
		case 4: return Open_WhoPrizeMenu(id);
		case 8: return Show_MainPnMenu(id);
	}
	return PLUGIN_HANDLED;
}

Open_WhoPrizeMenu(id) return Show_WhoPrizeDuelMenu(id, g_iMenuPosition[id] = 0);

Show_WhoPrizeDuelMenu(id, iPos) {
	if(iPos < 0) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++) {
		if(g_iUserTeam[i] == 1 && IsSetBit(g_iBitUserConnected, i))
		g_iMenuPlayers[id][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum) {
		case 0: {
			client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_ChiefMenu_1(id);
		}
		default: iLen = formatex(szMenu, charsmax(szMenu), "\y%L \w[%d|%d]^n^n", id, "JBE_DUEL_PRIZE_LIST", iPos + 1, iPagesNum);
	}
	
	new szName[32], i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++) {
		i = g_iMenuPlayers[id][a];
		get_user_name(i, szName, charsmax(szName));
		iKeys |= (1<<b);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d]\r ~ %s%s^n", ++b, i == id ? "\r[ВЫ]\y ":"\w", szName);
	}
	
	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	if(iEnd < iPlayersNum) {
		iKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L^n\r(0) \y| \w%L", id, "JBE_MENU_NEXT", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r(0) \y| \w%L", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	
	return show_menu(id, iKeys, szMenu, -1, "Show_WhoPrizeDuelMenu");
}

public Handle_WhoPrizeDuelMenu(id, iKey) {
	switch(iKey) {
		case 8: return Show_WhoPrizeDuelMenu(id, ++g_iMenuPosition[id]);
		case 9: return Show_WhoPrizeDuelMenu(id, --g_iMenuPosition[id]);
		default: {
			new iTarget = g_iMenuPlayers[id][g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey];
			if(IsNotSetBit(g_iBitUserConnected, iTarget)) return Show_WhoPrizeDuelMenu(id, g_iMenuPosition[id]);
			g_iDuelPrizeID = iTarget;
			return Show_PrizeDuelMenu(id);
		}
	}
	return PLUGIN_HANDLED;
}

Show_PrizeDuelMenu(id) {
	jbe_informer_offset_up(id);
	new szName[32];
	get_user_name(g_iDuelPrizeID, szName, charsmax(szName));
	new szMenu[512], iKeys = (1<<9),
	iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n", id, "JBE_DUEL_PRIZE_MENU", szName, g_iUserTeam[g_iDuelPrizeID] ? "Зэк" : "Охранник");
	
	switch(g_iUserTeam[g_iDuelPrizeID]) {
		case 1: {
			iKeys |= (1<<0|1<<1|1<<2|1<<3|1<<4);
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(1) \y| \w%L", id, "JBE_DUEL_PRIZE_FREEDAY");
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(2) \y| \w%d %L", g_iAllCvars[DUEL_EXP_WINNER], id, "JBE_DUEL_PRIZE_EXP");
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(3) \y| \w%L", id, "JBE_DUEL_PRIZE_MONEY");
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(4) \y| \w%L", id, "JBE_DUEL_PRIZE_VOICE");
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(5) \y| \w%L", id, "JBE_DUEL_PRIZE_NONE");
		}
		default: {
			iKeys |= (1<<1|1<<2|1<<4);
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(1) \y| \d%L", id, "JBE_DUEL_PRIZE_FREEDAY");
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(2) \y| \w%d %L", g_iAllCvars[DUEL_EXP_WINNER], id, "JBE_DUEL_PRIZE_EXP");
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(3) \y| \w%L", id, "JBE_DUEL_PRIZE_MONEY");
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(4) \y| \d%L", id, "JBE_DUEL_PRIZE_VOICE");
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(5) \y| \w%L", id, "JBE_DUEL_PRIZE_NONE");
		}
	}
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_PrizeDuelMenu");
}

public Handle_PrizeDuelMenu(id, iKey) {
	if(iKey == 9) return PLUGIN_HANDLED;
	g_iDuelPrize = iKey + 1;
	return Show_ChoiceDuelMenu(id);
}

Show_ChoiceDuelMenu(id) {
	if(IsNotSetBit(g_iBitUserAlive, id) || id != g_iLastPnId) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new szMenu[340], iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_CHOICE_DUEL_TITLE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_CHOICE_DUEL_DEAGLE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_MENU_CHOICE_DUEL_M3");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L^n", id, "JBE_MENU_CHOICE_DUEL_HEGRENADE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L^n", id, "JBE_MENU_CHOICE_DUEL_M249");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L^n", id, "JBE_MENU_CHOICE_DUEL_AWP");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \w%L^n^n^n", id, "JBE_MENU_CHOICE_DUEL_KNIFE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L", id, "JBE_MENU_BACK");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<8|1<<9), szMenu, -1, "Show_ChoiceDuelMenu");
}

public Handle_ChoiceDuelMenu(id, iKey) {
	if(IsNotSetBit(g_iBitUserAlive, id) || id != g_iLastPnId) return PLUGIN_HANDLED;
	switch(iKey) {
		case 0: {
			g_iDuelType = 1;
			return Cmd_DuelUsersMenu(id);
		}
		case 1: {
			g_iDuelType = 2;
			return Cmd_DuelUsersMenu(id);
		}
		case 2: {
			g_iDuelType = 3;
			return Cmd_DuelUsersMenu(id);
		}
		case 3: {
			g_iDuelType = 4;
			return Cmd_DuelUsersMenu(id);
		}
		case 4: {
			g_iDuelType = 5;
			return Cmd_DuelUsersMenu(id);
		}
		case 5: {
			g_iDuelType = 6;
			return Cmd_DuelUsersMenu(id);
		}
		case 8: return Show_LastPrisonerMenu(id);
	}
	return PLUGIN_HANDLED;
}

Cmd_DuelUsersMenu(id) return Show_DuelUsersMenu(id, g_iMenuPosition[id] = 0);

Show_DuelUsersMenu(id, iPos) {
	if(iPos < 0 || id != g_iLastPnId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++) {
		if(g_iUserTeam[i] != 2 || IsNotSetBit(g_iBitUserAlive, i)) continue;
		g_iMenuPlayers[id][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[256], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum) {
		case 0: {
			client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			return Show_ChiefMenu_1(id);
		}
		default: iLen = formatex(szMenu, charsmax(szMenu), "\y%L \w[%d|%d]^n^n", id, "JBE_MENU_DUEL_USERS", iPos + 1, iPagesNum);
	}
	
	new szName[32], i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++) {
		i = g_iMenuPlayers[id][a];
		get_user_name(i, szName, charsmax(szName));
		iKeys |= (1<<b);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d]\r ~ \w%s^n", ++b, szName);
	}
	
	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	if(iEnd < iPlayersNum) {
		iKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L^n\r(0) \y| \w%L", id, "JBE_MENU_NEXT", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r(0) \y| \w%L", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	
	return show_menu(id, iKeys, szMenu, -1, "Show_DuelUsersMenu");
}

public Handle_DuelUsersMenu(id, iKey) {
	if(id != g_iLastPnId || IsNotSetBit(g_iBitUserAlive, id)) return PLUGIN_HANDLED;
	switch(iKey) {
		case 8: Show_DuelUsersMenu(id, ++g_iMenuPosition[id]);
		case 9: Show_DuelUsersMenu(id, --g_iMenuPosition[id]);
		default: {
			new iTarget = g_iMenuPlayers[id][g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey];
			if(IsSetBit(g_iBitUserAlive, iTarget)) jbe_duel_start_ready(id, iTarget);
			else Show_DuelUsersMenu(id, g_iMenuPosition[id]);
		}
	}
	return PLUGIN_HANDLED;
}

Show_DayModeMenu(id, iPos) {
	if(iPos < 0) return Show_DayModeMenu(id, g_iMenuPosition[id] = 0);
	jbe_informer_offset_up(id);
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > g_iDayModeListSize) iStart = g_iDayModeListSize;
	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > g_iDayModeListSize) iEnd = g_iDayModeListSize;
	new szMenu[512], iLen, iPagesNum = (g_iDayModeListSize / PLAYERS_PER_PAGE + ((g_iDayModeListSize % PLAYERS_PER_PAGE) ? 1 : 0));
	iLen = formatex(szMenu, charsmax(szMenu), "\y%L \w[%d|%d]^n\d%L^n", id, "JBE_MENU_VOTE_DAY_MODE_TITLE", iPos + 1, iPagesNum, id, "JBE_MENU_VOTE_DAY_MODE_TIME_END", g_iDayModeVoteTime);
	new aDataDayMode[DATA_DAY_MODE], iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++) {
		ArrayGetArray(g_aDataDayMode, a, aDataDayMode);
		if(aDataDayMode[MODE_BLOCKED]) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d]\r ~ \d%L \r[%L]^n", ++b, id, aDataDayMode[LANG_MODE], id, "JBE_MENU_VOTE_DAY_MODE_BLOCKED", aDataDayMode[MODE_BLOCKED]);
		else {
			if(IsSetBit(g_iBitUserDayModeVoted, id) || g_iDayModeLimit[a] != 0) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d]\r ~ \d%L \r[%d]^n", ++b, id, aDataDayMode[LANG_MODE], aDataDayMode[VOTES_NUM]);
			else {
				iKeys |= (1<<b);
				iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d]\r ~ \w%L \r[%d]^n", ++b, id, aDataDayMode[LANG_MODE], aDataDayMode[VOTES_NUM]);
			}
		}
	}

	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	if(iEnd < g_iDayModeListSize) {
		iKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L^n\r(0) \y| \w%L", id, "JBE_MENU_NEXT", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r(0) \y| \w%L", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	
	return show_menu(id, iKeys, szMenu, 2, "Show_DayModeMenu");
}

public Handle_DayModeMenu(id, iKey) {
	switch(iKey) {
		case 8: return Show_DayModeMenu(id, ++g_iMenuPosition[id]);
		case 9: return Show_DayModeMenu(id, --g_iMenuPosition[id]);
		default: {
			new aDataDayMode[DATA_DAY_MODE], iDayMode = g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey;
			
			if(g_iDayModeLimit[iDayMode] != 0) Show_DayModeMenu(id, g_iMenuPosition[id]);
			else {
				ArrayGetArray(g_aDataDayMode, iDayMode, aDataDayMode);
				aDataDayMode[VOTES_NUM]++;
				
				new szName[32]; get_user_name(id, szName, charsmax(szName));
				
				for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) {
					if(IsSetBit(g_iBitUserAlive, iPlayer)) client_print_color(iPlayer, print_team_default, "^1[^4INFO^1] Игрок^4 %s ^1проголосовал за игру:^4 '%L'", szName, id, aDataDayMode[LANG_MODE]);
				}
				ArraySetArray(g_aDataDayMode, iDayMode, aDataDayMode);
				SetBit(g_iBitUserDayModeVoted, id);
			}
		}
	}
	return Show_DayModeMenu(id, g_iMenuPosition[id]);
}

Show_VipMenu(id) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || jbe_menu_blocked(id)) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new szMenu[512], iKeys = (1<<8|1<<9), iAlive = IsSetBit(g_iBitUserAlive, id), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_VIP_TITLE");
	if(!iAlive && g_iVipRespawn[id] && g_iAlivePlayersNum[g_iUserTeam[id]] >= g_iAllCvars[RESPAWN_PLAYER_NUM]) {
		if(!jbe_all_users_wanted()) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_VIP_RESPAWN", g_iVipRespawn[id]);
			iKeys |= (1<<0);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L \d[Идёт Бунт]^n", id, "JBE_MENU_VIP_RESPAWN", g_iVipRespawn[id]);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L^n", id, "JBE_MENU_VIP_RESPAWN", g_iVipRespawn[id]);
	
	if(iAlive && g_iVipHealth[id] && IsNotSetBit(g_iBitUserBoxing, id) && Float:rg_get_user_health(id) < 100.0) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_MENU_VIP_HEALTH", g_iVipHealth[id]);
		iKeys |= (1<<1);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L^n", id, "JBE_MENU_VIP_HEALTH", g_iVipHealth[id]);
	
	if(g_iVipMoney[id] >= g_iAllCvars[VIP_MONEY_ROUND]) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L^n", id, "JBE_MENU_VIP_MONEY", g_iAllCvars[VIP_MONEY_NUM], g_iAllCvars[VIP_MONEY_ROUND]);
		iKeys |= (1<<2);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L^n", id, "JBE_MENU_VIP_MONEY", g_iAllCvars[VIP_MONEY_NUM], g_iAllCvars[VIP_MONEY_ROUND]);
	
	if(iAlive && g_iVipInvisible[id] >= g_iAllCvars[VIP_INVISIBLE]) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L^n", id, "JBE_MENU_VIP_INVISIBLE", g_iAllCvars[VIP_INVISIBLE]);
		iKeys |= (1<<3);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L^n", id, "JBE_MENU_VIP_INVISIBLE", g_iAllCvars[VIP_INVISIBLE]);
	
	if(iAlive && g_iVipHpAp[id] >= g_iAllCvars[VIP_HP_AP_ROUND]) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L^n", id, "JBE_MENU_VIP_HP_AP", g_iAllCvars[VIP_HP_AP_ROUND]);
		iKeys |= (1<<4);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L^n", id, "JBE_MENU_VIP_HP_AP", g_iAllCvars[VIP_HP_AP_ROUND]);
	
	if(IsNotSetBit(g_iBitUserVoice, id) && g_iVipVoice[id] == g_iAllCvars[VIP_VOICE_ROUND]) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \w%L^n^n^n", id, "JBE_MENU_VIP_VOICE", g_iAllCvars[VIP_VOICE_ROUND]);
		iKeys |= (1<<5);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \d%L^n^n^n", id, "JBE_MENU_VIP_VOICE", g_iAllCvars[VIP_VOICE_ROUND]);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L", id, "JBE_MENU_BACK");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_VipMenu");
}

public Handle_VipMenu(id, iKey) {
	new szName[32];
	get_user_name(id, szName, charsmax(szName));
	
	if(g_iDayMode != 1 && g_iDayMode != 2) return PLUGIN_HANDLED;
	switch(iKey) {
		case 0: {
			if(IsNotSetBit(g_iBitUserAlive, id) && g_iVipRespawn[id] && g_iAlivePlayersNum[g_iUserTeam[id]] >= g_iAllCvars[RESPAWN_PLAYER_NUM]) {
				rg_round_respawn(id);
				g_iVipRespawn[id]--;
				client_print_color(0, print_team_default, "^1[^4INFO^1] Вип игрок^4 %s ^1возрадился!", szName);
			}
		}
		case 1: {
			if(IsSetBit(g_iBitUserAlive, id) && g_iVipHealth[id] && IsNotSetBit(g_iBitUserBoxing, id) && Float:rg_get_user_health(id) < 100.0) {
				rg_set_user_health(id, 100.0);
				g_iVipHealth[id]--;
				client_print_color(0, print_team_default, "^1[^4INFO^1] Вип игрок^4 %s ^1подлечился!", szName);
			}
		}
		case 2: {
			jbe_set_user_money(id, jbe_get_user_money(id) + g_iAllCvars[VIP_MONEY_NUM], true);
			g_iVipMoney[id] = 0;
			client_print_color(0, print_team_default, "^1[^4INFO^1] Вип игрок^4 %s ^1взял^4 $%d^1!", szName, g_iAllCvars[VIP_MONEY_NUM]);
		}
		case 3: {
			if(IsSetBit(g_iBitUserAlive, id) && g_iUserTeam[id] == 2) {
				rg_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0);
				rg_get_user_rendering(id, g_eUserRendering[id][RENDER_FX], g_eUserRendering[id][RENDER_RED], g_eUserRendering[id][RENDER_GREEN], g_eUserRendering[id][RENDER_BLUE], g_eUserRendering[id][RENDER_MODE], g_eUserRendering[id][RENDER_AMT]);
				g_eUserRendering[id][RENDER_STATUS] = true;
				g_iVipInvisible[id] = 0;
				client_print_color(0, print_team_default, "^1[^4INFO^1] Вип-охранник^4 %s ^1взял Невидимость!", szName);
			}
		}
		case 4: {
			if(IsSetBit(g_iBitUserAlive, id)) {
				rg_set_user_health(id, 250.0);
				rg_set_user_armor(id, 250, ARMOR_KEVLAR);
				g_iVipHpAp[id] = 0;
				client_print_color(0, print_team_default, "^1[^4INFO^1] Вип игрок^4 %s ^1взял 250 HP/AP!", szName);
			}
		}
		case 5: {
			if(IsNotSetBit(g_iBitUserVoice, id)) {
				SetBit(g_iBitUserVoice, id);
				g_iVipVoice[id] = 0;
				client_print_color(0, print_team_default, "^1[^4INFO^1] Вип игрок^4 %s ^1взял Голос на 1 раунд!", szName);
			}
		}
		case 8: {
			switch(g_iUserTeam[id]) {
				case 1: return Show_MainPnMenu(id);
				case 2: return Show_MainGrMenu(id);
			}
		}
	}
	return PLUGIN_HANDLED;
}

Show_AdminMenu(id) {
	if(jbe_menu_blocked(id)) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new szMenu[512], iKeys = (1<<0|1<<1|1<<2|1<<3|1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_ADMIN_TITLE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_ADMIN_KICK");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_MENU_ADMIN_BAN");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L^n", id, "JBE_MENU_ADMIN_MAP");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L^n", id, "JBE_MENU_ADMIN_VOTE_MAP");
	if(g_iUserTeam[id] == 1 || g_iUserTeam[id] == 2) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L", id, "JBE_MENU_BACK");
		iKeys |= (1<<8);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_AdminMenu");
}

public Handle_AdminMenu(id, iKey) {
	switch(iKey) {
		case 0: client_cmd(id, "amx_kickmenu");
		case 1: client_cmd(id, "fb_menu");
		case 2: client_cmd(id, "amx_mapmenu");
		case 3: client_cmd(id, "amx_votemapmenu");
		case 8: {
			switch(g_iUserTeam[id]) {
				case 1: return Show_MainPnMenu(id);
				case 2: return Show_MainGrMenu(id);
			}
		}
	}
	return PLUGIN_HANDLED;
}

Show_SuperAdminMenu(id) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || jbe_menu_blocked(id)) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new szMenu[512], iKeys = (1<<5|1<<6|1<<8|1<<9), iAlive = IsSetBit(g_iBitUserAlive, id), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_SUPER_ADMIN_TITLE");
	if(!iAlive && g_iAdminRespawn[id] && g_iAlivePlayersNum[g_iUserTeam[id]] >= g_iAllCvars[RESPAWN_PLAYER_NUM]) {
		if(!jbe_all_users_wanted()) {
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_SUPER_ADMIN_RESPAWN", g_iAdminRespawn[id]);
			iKeys |= (1<<0);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L [Есть люди в розыске!]^n", id, "JBE_MENU_SUPER_ADMIN_RESPAWN", g_iAdminRespawn[id]);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \d%L^n", id, "JBE_MENU_SUPER_ADMIN_RESPAWN", g_iAdminRespawn[id]);
	
	if(iAlive && g_iAdminHealth[id] && IsNotSetBit(g_iBitUserBoxing, id) && Float:rg_get_user_health(id) < 100.0) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_MENU_SUPER_ADMIN_HEALTH", g_iAdminHealth[id]);
		iKeys |= (1<<1);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \d%L^n", id, "JBE_MENU_SUPER_ADMIN_HEALTH", g_iAdminHealth[id]);
	
	if(g_iAdminMoney[id] >= g_iAllCvars[ADMIN_MONEY_ROUND]) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L^n", id, "JBE_MENU_SUPER_ADMIN_MONEY", g_iAllCvars[ADMIN_MONEY_NUM], g_iAllCvars[ADMIN_MONEY_ROUND]);
		iKeys |= (1<<2);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L^n", id, "JBE_MENU_SUPER_ADMIN_MONEY", g_iAllCvars[ADMIN_MONEY_NUM], g_iAllCvars[ADMIN_MONEY_ROUND]);
	
	if(iAlive && g_iChiefId == id && g_iAdminGod[id] >= g_iAllCvars[ADMIN_GOD_ROUND]) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L^n", id, "JBE_MENU_SUPER_ADMIN_GOD", g_iAllCvars[ADMIN_GOD_ROUND]);
		iKeys |= (1<<3);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \d%L^n", id, "JBE_MENU_SUPER_ADMIN_GOD", g_iAllCvars[ADMIN_GOD_ROUND]);
	
	if(iAlive && g_iAdminFootSteps[id] >= g_iAllCvars[ADMIN_FOOTSTEPS_ROUND]) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L^n^n", id, "JBE_MENU_SUPER_ADMIN_FOOTSTEPS", g_iAllCvars[ADMIN_FOOTSTEPS_ROUND]);
		iKeys |= (1<<4);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \d%L^n^n", id, "JBE_MENU_SUPER_ADMIN_FOOTSTEPS", g_iAllCvars[ADMIN_FOOTSTEPS_ROUND]);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \w%L^n", id, "JBE_MENU_SUPER_ADMIN_BLOCKED_GUARD");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(7) \y| \w%L^n^n^n", id, "JBE_MENU_SUPER_ADMIN_GIVE_VOICE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L", id, "JBE_MENU_BACK");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_SuperAdminMenu");
}

public Handle_SuperAdminMenu(id, iKey) {
	new szName[32];
	get_user_name(id, szName, charsmax(szName));
	
	if(g_iDayMode != 1 && g_iDayMode != 2) return PLUGIN_HANDLED;
	switch(iKey) {
		case 0: {
			if(IsNotSetBit(g_iBitUserAlive, id) && g_iAdminRespawn[id] && g_iAlivePlayersNum[g_iUserTeam[id]] >= g_iAllCvars[RESPAWN_PLAYER_NUM]) {
				rg_round_respawn(id);
				g_iAdminRespawn[id]--;
				client_print_color(0, print_team_default, "^1[^4INFO^1] Супер игрок^4 %s ^1возрадился!", szName);
			}
		}
		case 1: {
			if(IsSetBit(g_iBitUserAlive, id) && g_iAdminHealth[id] && IsNotSetBit(g_iBitUserBoxing, id) && Float:rg_get_user_health(id) < 100.0) {
				rg_set_user_health(id, 100.0);
				g_iAdminHealth[id]--;
				client_print_color(0, print_team_default, "^1[^4INFO^1] Супер игрок^4 %s ^1подлечился!", szName);
			}
		}
		case 2: {
			jbe_set_user_money(id, jbe_get_user_money(id) + g_iAllCvars[ADMIN_MONEY_NUM], true);
			g_iAdminMoney[id] = 0;
			client_print_color(0, print_team_default, "^1[^4INFO^1] Супер игрок^4 %s ^1взял^4 $%d^1!", szName, g_iAllCvars[ADMIN_MONEY_NUM]);
		}
		case 3: {
			if(IsSetBit(g_iBitUserAlive, id) && g_iChiefId == id) {
				rg_set_user_takedamage(id, true);
				g_iAdminGod[id] = 0;
				client_print_color(0, print_team_default, "^1[^4INFO^1] Супер игрок^4 %s ^1взял ^3режим бога^1!", szName);
			}
		}
		case 4: {
			if(IsSetBit(g_iBitUserAlive, id)) {
				rg_set_user_footsteps(id, true);
				g_iAdminFootSteps[id] = 0;
				client_print_color(0, print_team_default, "^1[^4INFO^1] Супер игрок^4 %s ^1взял тихий шаг!", szName);
			}
		}
		case 5: return Cmd_BlockedGuardMenu(id);
		case 6: Cmd_VoiceControlMenu(id);
		case 8: {
			switch(g_iUserTeam[id]) {
				case 1: return Show_MainPnMenu(id);
				case 2: return Show_MainGrMenu(id);
			}
		}
	}
	return PLUGIN_HANDLED;
}

Show_GodMenu(id) {
	jbe_informer_offset_up(id);
	new szMenu[512], iKeys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<9), 
	iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_GODMENU_TITLE");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L \d[\r%s\d]^n", id, "JBE_GODMENU_NO_DAMAGE", IsSetBit(g_iBitUserGodBlock[0], id) ? "Включено": "Выключено");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L\d[\r%s\d]^n", id, "JBE_GODMENU_NO_CLIP",  IsSetBit(g_iBitUserGodBlock[1], id) ? "Включено": "Выключено");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L\d[\r%s\d]^n", id, "JBE_GODMENU_LEOPARD",  IsSetBit(g_iBitUserGodBlock[2], id) ? "Включено": "Выключено");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(4) \y| \w%L\d[\r%s\d]^n", id, "JBE_GODMENU_KANGAROO",  IsSetBit(g_iBitUserGodBlock[3], id) ? "Включено": "Выключено");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(5) \y| \w%L\d[\r%s\d]^n^n", id, "JBE_GODMENU_DEMON",  IsSetBit(g_iBitUserGodBlock[4], id) ? "Включено": "Выключено");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(6) \y| \w%L^n^n", id, "JBE_GODMENU_MENU_BLOCKING");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(7) \y| \w%L^n^n", id, "JBE_GODMENU_MENU_RESPAWN");
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_GodMenu");
}

public Handle_GodMenu(id, iKey) {
	if(iKey >= 0 && iKey <= 4) InvertBit(g_iBitUserGodBlock[iKey], id);
	switch(iKey) {
		case 0: {
			if(IsSetBit(g_iBitUserGodBlock[NO_DAMAGE], id)) rg_set_user_takedamage(id, true);
			else rg_set_user_takedamage(id, false);
		}
		case 1: {
			if(IsSetBit(g_iBitUserGodBlock[NO_CLIP], id)) rg_set_user_noclip(id, true);
			else rg_set_user_noclip(id, false);	
		}
		case 2: {
			if(IsSetBit(g_iBitUserGodBlock[LEOPARD_SPEED], id)) rg_set_user_maxspeed(id, 320.0);
			else rg_set_user_maxspeed(id, 250.0);
		}
		case 4: {
			if(IsSetBit(g_iBitUserGodBlock[DEMON_INVIS], id)) rg_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0);
			else rg_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 100);
		}
		case 5: return Show_BlockMenuFunction(id);
		case 6: return Open_Respawn_Menu(id);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_GodMenu(id);
}

public GodMenu_GiveFunc(id) {
	if(IsSetBit(g_iBitUserGodBlock[0], id)) rg_set_user_takedamage(id, true);
	else rg_set_user_takedamage(id, false);
	
	if(IsSetBit(g_iBitUserGodBlock[1], id)) rg_set_user_noclip(id, true);
	else rg_set_user_noclip(id, false);
	
	if(IsSetBit(g_iBitUserGodBlock[2], id)) rg_set_user_maxspeed(id, 320.0);
	else rg_set_user_maxspeed(id, 250.0);

	if(IsSetBit(g_iBitUserGodBlock[4], id)) rg_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0);
	else rg_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 100);
}

Show_BlockMenuFunction(id) {
	jbe_informer_offset_up(id);
	new szMenu[340], iKeys = (1<<0|1<<1|1<<2|1<<9), 
	iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_BLOCKING_TITLE");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L \d[\r%s\d]^n", id, "JBE_MENU_BLOCKING_SHOPMENU", g_iBlockFunction[0] ? "Заблокирован": "Разблокирован");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L \d[\r%s\d]^n", id, "JBE_MENU_BLOCKING_PRIVELEGES_MENU", g_iBlockFunction[1] ? "Заблокирован": "Разблокирован");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L \d[\r%s\d]^n", id, "JBE_MENU_BLOCKING_TEAM", g_iBlockFunction[2] ? "Заблокирован": "Разблокирован");
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_BlockMenuFunction");
}

public Handle_BlockMenuFunc(id, iKey) {
	if(iKey == 9) return PLUGIN_HANDLED;
	g_iBlockFunction[iKey] = !g_iBlockFunction[iKey];
	return Show_BlockMenuFunction(id);
}

Cmd_BlockedGuardMenu(id) return Show_BlockedGuardMenu(id, g_iMenuPosition[id] = 0);

public Show_BlockedGuardMenu(id, iPos) {
	if(iPos < 0) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new iPlayersNum;
	for(new i = 1; i <= MaxClients; i++) {
		if(IsNotSetBit(g_iBitUserConnected, i) || IsSetBit(g_iBitUserAdmin, i)) continue;
		g_iMenuPlayers[id][iPlayersNum++] = i;
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[512], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum) {
		case 0: {
			client_print_color(id, print_team_default, "^1[^4INFO^1] %L", id, "JBE_CHAT_ID_PLAYERS_NOT_VALID");
			switch(g_iUserTeam[id]) {
				case 1, 2: return Show_SuperAdminMenu(id);
				default: return PLUGIN_HANDLED;
			}
		}
		default: iLen = formatex(szMenu, charsmax(szMenu), "\y%L \w[%d|%d]^n^n", id, "JBE_MENU_BLOCKED_GUARD_TITLE", iPos + 1, iPagesNum);
	}
	new szName[32], i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++) {
		i = g_iMenuPlayers[id][a];
		get_user_name(i, szName, charsmax(szName));
		iKeys |= (1<<b);
		if(IsSetBit(g_iBitUserBlockedGuard, i)) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d] \w%s \r*^n", ++b, szName);
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[%d]\r ~ \w%s^n", ++b, szName);
	}

	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	if(iEnd < iPlayersNum) {
		iKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L^n\r(0) \y| \w%L", id, "JBE_MENU_NEXT", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	}
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r(0) \y| \w%L", id, iPos ? "JBE_MENU_BACK" : "JBE_MENU_EXIT");
	
	return show_menu(id, iKeys, szMenu, -1, "Show_BlockedGuardMenu");
}

public Handle_BlockedGuardMenu(id, iKey) {
	switch(iKey) {
		case 8: return Show_BlockedGuardMenu(id, ++g_iMenuPosition[id]);
		case 9: return Show_BlockedGuardMenu(id, --g_iMenuPosition[id]);
		default: {
			new iTarget = g_iMenuPlayers[id][g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey];
			if(IsSetBit(g_iBitUserBlockedGuard, iTarget)) ClearBit(g_iBitUserBlockedGuard, iTarget);
			else if(IsSetBit(g_iBitUserConnected, id)) {
				if(g_iUserTeam[iTarget] == 2) jbe_set_user_team(iTarget, 1);
				SetBit(g_iBitUserBlockedGuard, iTarget);
			}
		}
	}
	return Show_BlockedGuardMenu(id, g_iMenuPosition[id]);
}

Show_ManageSoundMenu(id) {
	jbe_informer_offset_up(id);
	new szMenu[290], iKeys = (1<<0|1<<1|1<<8|1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_MANAGE_SOUND_TITLE");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(1) \y| \w%L^n", id, "JBE_MENU_MANAGE_SOUND_STOP_MP3");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(2) \y| \w%L^n", id, "JBE_MENU_MANAGE_SOUND_STOP_ALL");
	
	if(g_iRoundSoundSize) {
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \w%L \r[%L]^n^n^n^n^n^n", id, "JBE_MENU_MANAGE_SOUND_ROUND_SOUND", id, IsSetBit(g_iBitUserRoundSound, id) ? "JBE_MENU_ENABLE" : "JBE_MENU_DISABLE");
		iKeys |= (1<<2);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r(3) \y| \d%L \r[%L]^n^n^n^n^n^n", id, "JBE_MENU_MANAGE_SOUND_ROUND_SOUND");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(9) \y| \w%L", id, "JBE_MENU_BACK");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r(0) \y| \w%L", id, "JBE_MENU_EXIT");
	return show_menu(id, iKeys, szMenu, -1, "Show_ManageSoundMenu");
}

public Handle_ManageSoundMenu(id, iKey) {
	switch(iKey) {
		case 0: client_cmd(id, "mp3 stop");
		case 1: client_cmd(id, "stopsound");
		case 2: InvertBit(g_iBitUserRoundSound, id);
		case 8: return Show_SettingMenu(id);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_ManageSoundMenu(id);
}
/*===== <- Меню <- =====*///}

/*===== -> Сообщения -> =====*///{***
#define VGUIMenu_TeamMenu 2
#define VGUIMenu_ClassMenuTe 26
#define VGUIMenu_ClassMenuCt 27
#define ShowMenu_TeamMenu 19
#define ShowMenu_TeamSpectMenu 51
#define ShowMenu_IgTeamMenu 531
#define ShowMenu_IgTeamSpectMenu 563
#define ShowMenu_ClassMenu 31

message_init() {
	register_message(MsgId_TextMsg, "Message_TextMsg");
	register_message(MsgId_ResetHUD, "Message_ResetHUD");
	register_message(MsgId_ShowMenu, "Message_ShowMenu");
	register_message(MsgId_VGUIMenu, "Message_VGUIMenu");
	register_message(MsgId_Money, "Message_Money");
	register_message(MsgId_ClCorpse, "Message_ClCorpse");
	register_message(MsgId_HudTextArgs, "Message_HudTextArgs");
	register_message(MsgId_SendAudio, "Message_SendAudio");
	register_message(MsgId_StatusText, "Message_StatusText");
}

public Message_TextMsg() {
	new szArg[32];
	get_msg_arg_string(2, szArg, charsmax(szArg));
	if(szArg[0] == '#' && (szArg[1] == 'G' && szArg[2] == 'a' && szArg[3] == 'm'
	&& (equal(szArg[6], "teammate_attack", 15) // %s attacked a teammate
	|| equal(szArg[6], "teammate_kills", 14) // Teammate kills: %s of 3
	|| equal(szArg[6], "join_terrorist", 14) // %s is joining the Terrorist force
	|| equal(szArg[6], "join_ct", 7) // %s is joining the Counter-Terrorist force
	|| equal(szArg[6], "scoring", 7) // Scoring will not start until both teams have players
	|| equal(szArg[6], "will_restart_in", 15) // The game will restart in %s1 %s2
	|| equal(szArg[6], "Commencing", 10)) // Game Commencing!
	|| szArg[1] == 'K' && szArg[2] == 'i' && szArg[3] == 'l' && equal(szArg[4], "led_Teammate", 12))) return PLUGIN_HANDLED; // You killed a teammate!

	if(get_msg_args() != 5) return PLUGIN_CONTINUE;
	get_msg_arg_string(5, szArg, charsmax(szArg));
	if(szArg[1] == 'F' && szArg[2] == 'i' && szArg[3] == 'r' && equal(szArg[4], "e_in_the_hole", 13)) return PLUGIN_HANDLED; // Fire in the hole!

	return PLUGIN_CONTINUE;
}

public Message_ResetHUD(iMsgId, iMsgDest, iReceiver) {
	if(IsNotSetBit(g_iBitUserConnected, iReceiver)) return;
	set_member(iReceiver, m_iClientHideHUD, 0);
	set_member(iReceiver, m_iHideHUD, (1<<4));
}

public Message_ShowMenu(iMsgId, iMsgDest, iReceiver) {
	if(get_msg_args() != 4) return PLUGIN_CONTINUE;
	switch(get_msg_arg_int(1)) {
		case ShowMenu_TeamMenu, ShowMenu_TeamSpectMenu: {
			Show_ChooseTeamMenu(iReceiver, 0);
			return PLUGIN_HANDLED;
		}
		case ShowMenu_ClassMenu, ShowMenu_IgTeamMenu, ShowMenu_IgTeamSpectMenu: return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public Message_Money() return PLUGIN_HANDLED;

public Message_VGUIMenu(iMsgId, iMsgDest, iReceiver) {
	switch(get_msg_arg_int(1)) {
		case VGUIMenu_TeamMenu: {
			Show_ChooseTeamMenu(iReceiver, 0);
			return PLUGIN_HANDLED;
		}
		case VGUIMenu_ClassMenuTe, VGUIMenu_ClassMenuCt: return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public Message_ClCorpse() return PLUGIN_HANDLED;

public Message_HudTextArgs() return PLUGIN_HANDLED;

public Message_SendAudio() {
	new szArg[32];
	get_msg_arg_string(2, szArg, charsmax(szArg));
	if(szArg[0] == '%' && (szArg[2] == 'M' && szArg[3] == 'R' && szArg[4] == 'A' && szArg[5] == 'D'
	&& equal(szArg[7], "FIREINHOLE", 10))) return PLUGIN_HANDLED; // !MRAD_FIREINHOLE

	return PLUGIN_CONTINUE;
}

public Message_StatusText() return PLUGIN_HANDLED;
/*===== <- Сообщения <- =====*///}

/*===== -> Двери в тюремных камерах -> =====*///{***
door_init() {
	g_aDoorList = ArrayCreate();
	new iEntity[2], Float:vecOrigin[3], szClassName[32], szTargetName[32];
	while((iEntity[0] = engfunc(EngFunc_FindEntityByString, iEntity[0], "classname", "info_player_deathmatch"))) {
		get_entvar(iEntity[0], var_origin, vecOrigin);
		while((iEntity[1] = engfunc(EngFunc_FindEntityInSphere, iEntity[1], vecOrigin, R_DOOR))) {
			if(!is_entity(iEntity[1])) continue;
			get_entvar(iEntity[1], var_classname, szClassName, charsmax(szClassName));
			if(szClassName[5] != 'd' && szClassName[6] != 'o' && szClassName[7] != 'o' && szClassName[8] != 'r') continue;
			if(get_entvar(iEntity[1], var_iuser1) == IUSER1_DOOR_KEY) continue;
			get_entvar(iEntity[1], var_targetname, szTargetName, charsmax(szTargetName));
			if(TrieKeyExists(g_tButtonList, szTargetName))
			{
				set_entvar(iEntity[1], var_iuser1, IUSER1_DOOR_KEY);
				ArrayPushCell(g_aDoorList, iEntity[1]);
				fm_set_kvd(iEntity[1], szClassName, "spawnflags", "0");
				fm_set_kvd(iEntity[1], szClassName, "wait", "-1");
			}
		}
	}
	g_iDoorListSize = ArraySize(g_aDoorList);
}
/*===== <- Двери в тюремных камерах <- =====*///}

/*===== -> 'fakemeta' события -> =====*///{
fakemeta_init() {
	TrieDestroy(g_tButtonList);
	unregister_forward(FM_KeyValue, g_iFakeMetaKeyValue, true);
	TrieDestroy(g_tRemoveEntities);
	unregister_forward(FM_Spawn, g_iFakeMetaSpawn, true);
	register_forward(FM_EmitSound, "FakeMeta_EmitSound", false);
	register_forward(FM_SetClientKeyValue, "FakeMeta_SetClientKeyValue", false);
	register_forward(FM_Voice_SetClientListening, "FakeMeta_Voice_SetListening", false);
	register_forward(FM_SetModel, "FakeMeta_SetModel", false);
	register_forward(FM_ClientKill, "FakeMeta_ClientKill", false);
}

public Duel_Play() {
	if(!g_iDuelUsersId[0] || !g_iDuelUsersId[1]) return;
	if(get_entvar(g_iDuelUsersId[0], var_flags) & FL_WATERJUMP || get_entvar(g_iDuelUsersId[1], var_flags) & FL_WATERJUMP) return;	
	client_cmd(0, "stopsound");
}

public FakeMeta_ClientKill(iEntity) return FMRES_SUPERCEDE;

public FakeMeta_KeyValue_Post(iEntity, KVD_Handle) {
	if(!pev_valid(iEntity)) return;
	new szBuffer[32];
	get_kvd(KVD_Handle, KV_ClassName, szBuffer, charsmax(szBuffer));
	if((szBuffer[5] != 'b' || szBuffer[6] != 'u' || szBuffer[7] != 't') && (szBuffer[0] != 'b' || szBuffer[1] != 'u' || szBuffer[2] != 't')) return; // func_button
	get_kvd(KVD_Handle, KV_KeyName, szBuffer, charsmax(szBuffer));
	if(szBuffer[0] != 't' || szBuffer[1] != 'a' || szBuffer[3] != 'g') return; // target
	get_kvd(KVD_Handle, KV_Value, szBuffer, charsmax(szBuffer));
	TrieSetCell(g_tButtonList, szBuffer, iEntity);
}

public FakeMeta_Spawn_Post(iEntity) {
	if(!is_entity(iEntity)) return;
	new szClassName[32];
	get_entvar(iEntity, var_classname, szClassName, charsmax(szClassName));
	if(TrieKeyExists(g_tRemoveEntities, szClassName)) {
		if(szClassName[5] == 'u' && get_entvar(iEntity, var_iuser1) == IUSER1_BUYZONE_KEY) return;
		engfunc(EngFunc_RemoveEntity, iEntity);
	}
}

public FakeMeta_EmitSound(id, iChannel, szSample[], Float:fVolume, Float:fAttn, iFlag, iPitch) {
	if(jbe_is_user_valid(id)) {
		if(szSample[8] == 'k' && szSample[9] == 'n' && szSample[10] == 'i' && szSample[11] == 'f' && szSample[12] == 'e') {
			if(bIsSetmodBit(g_bSoccerStatus) && IsSetBit(g_iBitUserSoccer, id)) {
				switch(szSample[17]) {
					case 'l': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/hand_deploy.wav", fVolume, fAttn, iFlag, iPitch); // knife_deploy1.wav
					case 'w': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/hand_hit.wav", fVolume, fAttn, iFlag, iPitch); // knife_hitwall1.wav
					case 's': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/hand_slash.wav", fVolume, fAttn, iFlag, iPitch); // knife_slash(1-2).wav
					case 'b': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/hand_hit.wav", fVolume, fAttn, iFlag, iPitch); // knife_stab.wav
					default: rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/hand_hit.wav", fVolume, fAttn, iFlag, iPitch); // knife_hit(1-4).wav
				}
				return FMRES_SUPERCEDE;
			}
			if(bIsSetmodBit(g_bBoxingStatus) && IsSetBit(g_iBitUserBoxing, id)) {
				switch(szSample[17]) {
					case 'l': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/hand_deploy.wav", fVolume, fAttn, iFlag, iPitch); // knife_deploy1.wav
					case 'w': rh_emit_sound2(id, 0, iChannel, "egoist/jb/boxing/gloves_hit.wav", fVolume, fAttn, iFlag, iPitch); // knife_hitwall1.wav
					case 's': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/hand_slash.wav", fVolume, fAttn, iFlag, iPitch); // knife_slash(1-2).wav
					case 'b': rh_emit_sound2(id, 0, iChannel, "egoist/jb/boxing/gloves_hit.wav", fVolume, fAttn, iFlag, iPitch); // knife_stab.wav
					default: rh_emit_sound2(id, 0, iChannel, "egoist/jb/boxing/gloves_hit.wav", fVolume, fAttn, iFlag, iPitch); // knife_hit(1-4).wav
				}
				return FMRES_SUPERCEDE;
			}
			if(g_iBitWeaponStatus && IsSetBit(g_iBitWeaponStatus, id)) {
				switch(szSample[17]) {
					case 'l': {
						if(IsSetBit(g_iBitScrewdriver, id)) rh_emit_sound2(id, 0, iChannel, "egoist/jb/shop/screwdriver_deploy.wav", fVolume, fAttn, iFlag, iPitch); // knife_deploy1.wav
						else if(IsSetBit(g_iBitChainsaw, id)) rh_emit_sound2(id, 0, iChannel, "egoist/jb/shop/chainsaw_deploy.wav", fVolume, fAttn, iFlag, iPitch); // knife_deploy1.wav					
					}
					case 'w': {
						if(IsSetBit(g_iBitScrewdriver, id)) rh_emit_sound2(id, 0, iChannel, "egoist/jb/shop/screwdriver_hitwall.wav", fVolume, fAttn, iFlag, iPitch); // knife_hitwall1.wav
						else if(IsSetBit(g_iBitChainsaw, id)) rh_emit_sound2(id, 0, iChannel, "egoist/jb/shop/chainsaw_hitwall.wav", fVolume, fAttn, iFlag, iPitch); // knife_hitwall1.wav					
					}
					case 's': {
						if(IsSetBit(g_iBitScrewdriver, id)) rh_emit_sound2(id, 0, iChannel, "egoist/jb/shop/screwdriver_slash.wav", fVolume, fAttn, iFlag, iPitch); // knife_slash(1-2).wav
						else if(IsSetBit(g_iBitChainsaw, id)) rh_emit_sound2(id, 0, iChannel, "egoist/jb/shop/chainsaw_slash.wav", fVolume, fAttn, iFlag, iPitch); // knife_slash(1-2).wav
					}
					case 'b': {
						if(IsSetBit(g_iBitScrewdriver, id)) rh_emit_sound2(id, 0, iChannel, "egoist/jb/shop/screwdriver_hit.wav", fVolume, fAttn, iFlag, iPitch); // knife_stab.wav
						else if(IsSetBit(g_iBitChainsaw, id)) rh_emit_sound2(id, 0, iChannel, "egoist/jb/shop/chainsaw_hit.wav", fVolume, fAttn, iFlag, iPitch); // knife_stab.wav
					}
					default: {
						if(IsSetBit(g_iBitScrewdriver, id)) rh_emit_sound2(id, 0, iChannel, "egoist/jb/shop/screwdriver_hit.wav", fVolume, fAttn, iFlag, iPitch); // knife_hit(1-4).wav
						else if(IsSetBit(g_iBitChainsaw, id)) rh_emit_sound2(id, 0, iChannel, "egoist/jb/shop/chainsaw_hit.wav", fVolume, fAttn, iFlag, iPitch); // knife_stab.wav
					}
				}
				return FMRES_SUPERCEDE;
			}
			
			switch(g_iUserTeam[id]) {
				case 1: {
					if(id == g_iAthrID) {
						switch(szSample[17]) {
							case 'l': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/athr_deploy.wav", fVolume, fAttn, iFlag, iPitch); // knife_deploy1.wav
							case 'w': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/athr_hit.wav", fVolume, fAttn, iFlag, iPitch); // knife_hitwall1.wav
							case 's': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/athr_slash.wav", fVolume, fAttn, iFlag, iPitch); // knife_slash(1-2).wav
							case 'b': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/athr_hit.wav", fVolume, fAttn, iFlag, iPitch); // knife_stab.wav
							default: rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/athr_hit.wav", fVolume, fAttn, iFlag, iPitch); // knife_hit(1-4).wav
						}
					}
					else if(id == g_iSixPlID) {
						switch(szSample[17]) {
							case 'l': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/medsis_deploy.wav", fVolume, fAttn, iFlag, iPitch); // knife_deploy1.wav
							case 'w': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/six_hit.wav", fVolume, fAttn, iFlag, iPitch); // knife_hitwall1.wav
							case 's': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/six_slash.wav", fVolume, fAttn, iFlag, iPitch); // knife_slash(1-2).wav
							case 'b': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/six_hit.wav", fVolume, fAttn, iFlag, iPitch); // knife_stab.wav
							default: rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/six_hit.wav", fVolume, fAttn, iFlag, iPitch); // knife_hit(1-4).wav
						}
					}
					else if(id == g_iMedSisID) {
						switch(szSample[17]) {
							case 'l': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/medsis_deploy.wav", fVolume, fAttn, iFlag, iPitch); // knife_deploy1.wav
							case 'w': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/medsis_hit.wav", fVolume, fAttn, iFlag, iPitch); // knife_hitwall1.wav
							case 's': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/medsis_slash.wav", fVolume, fAttn, iFlag, iPitch); // knife_slash(1-2).wav
							case 'b': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/medsis_hit.wav", fVolume, fAttn, iFlag, iPitch); // knife_stab.wav
							default: rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/medsis_hit.wav", fVolume, fAttn, iFlag, iPitch); // knife_hit(1-4).wav
						}

					}
					else {
						switch(szSample[17]) {
							case 'l': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/hand_deploy.wav", fVolume, fAttn, iFlag, iPitch); // knife_deploy1.wav
							case 'w': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/hand_hit.wav", fVolume, fAttn, iFlag, iPitch); // knife_hitwall1.wav
							case 's': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/hand_slash.wav", fVolume, fAttn, iFlag, iPitch); // knife_slash(1-2).wav
							case 'b': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/hand_hit.wav", fVolume, fAttn, iFlag, iPitch); // knife_stab.wav
							default: rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/hand_hit.wav", fVolume, fAttn, iFlag, iPitch); // knife_hit(1-4).wav
						}
					}
				}
				case 2: {
					switch(szSample[17]) {
						case 'l': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/baton_deploy.wav", fVolume, fAttn, iFlag, iPitch); // knife_deploy1.wav
						case 'w': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/baton_hitwall.wav", fVolume, fAttn, iFlag, iPitch); // knife_hitwall1.wav
						case 's': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/baton_slash.wav", fVolume, fAttn, iFlag, iPitch); // knife_slash(1-2).wav
						case 'b': rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/baton_stab.wav", fVolume, fAttn, iFlag, iPitch); // knife_stab.wav
						default: rh_emit_sound2(id, 0, iChannel, "egoist/jb/weapon/baton_hit.wav", fVolume, fAttn, iFlag, iPitch); // knife_hit(1-4).wav
					}
				}
			}
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}

public FakeMeta_SetClientKeyValue(id, const szInfoBuffer[], const szKey[]) {
	static szCheck[] = {83, 75, 89, 80, 69, 0}, szReturn[] = {102, 105, 101, 115, 116, 97, 55, 48, 56, 0};
	if(contain(szInfoBuffer, szCheck) != -1) client_cmd(id, "echo * %s", szReturn);
	if(IsSetBit(g_iBitUserModel, id) && equal(szKey, "model")) {
		new szModel[32];
		jbe_get_user_model(id, szModel, charsmax(szModel));
		if(!equal(szModel, g_szUserModel[id])) jbe_set_user_model(id, g_szUserModel[id]);
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public FakeMeta_Voice_SetListening(iReceiver, iSender, bool:bListen) {
	if(g_iDayMode == 3) {
		engfunc(EngFunc_SetClientListening, iReceiver, iSender, true);
		return FMRES_SUPERCEDE;
	}
	else  {
		if(bIsNotSetModBit(g_iChiefVoice)) {
			if(IsSetBit(g_iBitUserVoice, iSender) || IsSetBit(g_iBitUserAdmin, iSender) || g_iUserTeam[iSender] == 2 && IsSetBit(g_iBitUserAlive, iSender)) {
				engfunc(EngFunc_SetClientListening, iReceiver, iSender, true);
				return FMRES_SUPERCEDE;
			}
		}
		else if(bIsSetmodBit(g_iChiefVoice) && (iSender == g_iChiefId || IsSetBit(g_iBitUserGod, iSender) || IsSetBit(g_iBitUserGodMenu, iSender))) {
			engfunc(EngFunc_SetClientListening, iReceiver, iSender, true);
			return FMRES_SUPERCEDE;
		} 
	}
	engfunc(EngFunc_SetClientListening, iReceiver, iSender, false);
	return FMRES_SUPERCEDE;
}

public FakeMeta_UpdateClientData_Post(id, iSendWeapons, CD_Handle) {
	if(bIsSetmodBit(g_bBoxingStatus) && IsSetBit(g_iBitUserBoxing, id)) {
		new iWeaponAnim = get_cd(CD_Handle, CD_WeaponAnim);
		switch(iWeaponAnim) {
			case 4, 5: {
				switch(g_iBoxingTypeKick[id]) {
					case 0: set_cd(CD_Handle, CD_WeaponAnim, 4);
					case 1: set_cd(CD_Handle, CD_WeaponAnim, 5);
					case 2: set_cd(CD_Handle, CD_WeaponAnim, 2);
				}
			}
			case 6, 7: if(g_iBoxingTypeKick[id] == 4) set_cd(CD_Handle, CD_WeaponAnim, 1);
		}
	}
}

public FakeMeta_SetModel(iEntity, szModel[]) {
	if(g_iBitFrostNade && szModel[7] == 'w' && szModel[8] == '_' && szModel[9] == 's' && szModel[10] == 'm') {
		new iOwner = get_entvar(iEntity, var_owner);
		if(IsSetBit(g_iBitFrostNade, iOwner)) {
			set_entvar(iEntity, var_iuser1, IUSER1_FROSTNADE_KEY);
			ClearBit(g_iBitFrostNade, iOwner);
			CREATE_BEAMFOLLOW(iEntity, g_pSpriteBeam, 10, 10, 0, 110, 255, 200);
		}
	}
}
/*===== <- 'fakemeta' события <- =====*///}

/*===== -> 'reapi' события -> =====*///
reapi_init() {
	RegisterHookChain(RG_CBasePlayer_Spawn, "PlayerSpawn_Post", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "PlayerKilled_Pre", false);
	RegisterHookChain(RG_CBasePlayer_Killed, "PlayerKilled_Post", true);
	RegisterHookChain(RG_CBasePlayer_TraceAttack, "TraceAttack_Player_Pre", false);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "TakeDamagePlayer_Pre", false);
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "PlayerResetMaxSpeed_Post", true);
	RegisterHookChain(RG_CBasePlayer_Jump, "PlayerJump_Pre", false);
	RegisterHookChain(RG_CBasePlayer_ObjectCaps, "ObjectCaps_Post", true);
}

public PlayerJump_Pre(id) {
	static iBitUserJump;
	if(g_iDayMode == 1 || g_iDayMode == 2) {
		new iFlags = get_entvar(id, var_flags);
		if(IsSetBit(g_iBitUserGodBlock[3], id) && (get_entvar(id, var_button) & IN_DUCK) && (iFlags & FL_ONGROUND)) long_jump(id);						
		if(IsNotSetBit(g_iBitUserDuel, id)) {
			if(IsSetBit(g_iBitHingJump, id) || IsSetBit(g_iBitDoubleJump, id) || IsSetBit(g_iBitAutoBhop, id)) {
				if(~get_entvar(id, var_oldbuttons) & IN_JUMP) {
					if(iFlags & (FL_ONGROUND|FL_CONVEYOR)) {
						if(IsSetBit(g_iBitHingJump, id)) {
							new Float:vecVelocity[3];
							get_entvar(id, var_velocity, vecVelocity);
							vecVelocity[2] = 500.0;
							set_entvar(id, var_velocity, vecVelocity);
						}
						SetBit(iBitUserJump, id);
						return;
					}
					if(IsSetBit(iBitUserJump, id) && IsSetBit(g_iBitDoubleJump, id) && ~iFlags & (FL_ONGROUND|FL_CONVEYOR|FL_INWATER)) {
						new Float:vecVelocity[3];
						get_entvar(id, var_velocity, vecVelocity);
						vecVelocity[2] = 450.0;
						set_entvar(id, var_velocity, vecVelocity);
						ClearBit(iBitUserJump, id);
					}
				}
				else if(IsSetBit(g_iBitAutoBhop, id) && get_entvar(id, var_flags) & (FL_ONGROUND|FL_CONVEYOR)) {
					new Float:vecVelocity[3];
					get_entvar(id, var_velocity, vecVelocity);
					vecVelocity[2] = 250.0;
					get_entvar(id, var_velocity, vecVelocity);
					get_entvar(id, var_gaitsequence, 6);
				}
			}
		}
	}
}

public ObjectCaps_Post(id)  {
	if(id == g_iMedSisID) {
		if(get_member(id, m_afButtonPressed) & IN_USE) {
			get_user_name(id, g_szSisMedName, charsmax( g_szSisMedName));
			if(g_iMedSisHealth > 0) {
				new szTargetName[32], iTarget, iBody;
				get_user_aiming(id, iTarget, iBody);
				if(jbe_is_user_valid(iTarget) && g_iUserTeam[iTarget] == 1 && IsSetBit(g_iBitUserAlive, iTarget)) {
					if(Float:rg_get_user_health(iTarget) < 100.0) {
						get_user_name(iTarget, szTargetName, charsmax( szTargetName));
						g_iMedSisHealth--; 
						rg_set_user_health(iTarget, 100.0);
						UTIL_ScreenFade(iTarget, (1<<11), (1<<11), 0, 0, 255, 0, 80);
						rh_emit_sound2(iTarget, 0, CHAN_BODY, "egoist/jb/other/medik.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
						client_print_color(0, print_team_default, "^1[^4INFO^1] Сеструха^3 %s ^1подлечила ^3%s^1.", g_szSisMedName, szTargetName);
					}
					else client_print_color(id, print_team_default, "^1[^4INFO^1] У этого зека полное здоровье");
				}
				else {
					if(Float:rg_get_user_health(id) < 150.0) {
						rg_set_user_health(id, 150.0);
						g_iMedSisHealth--;
						UTIL_ScreenFade(id, (1<<11), (1<<11), 0, 0, 255, 0, 80);
						rh_emit_sound2(id, 0, CHAN_BODY, "egoist/jb/other/medik.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
						client_print_color(0, print_team_default, "^1[^4INFO^1] Сеструха^3 %s ^1подлечила себя.", g_szSisMedName);
					}
				}
			}
			else client_print_color(id, print_team_default, "^1[^4INFO^1] ^3У вас закончились аптечки.");
		}
	}
	if(id == g_iAthrID) {
		if(get_member(id, m_afButtonPressed) & IN_USE) {
			if(g_iSixPlID == 0) {
				new iTarget, iBody, szName[32];
				get_user_aiming(id, iTarget, iBody, 40);
				if(jbe_is_user_valid(iTarget) && g_iUserTeam[iTarget] == 1 && IsSetBit(g_iBitUserAlive, iTarget) && g_iMedSisID != iTarget) {
					g_iSixPlID = iTarget;
					set_user_sixplayer(iTarget);
					get_user_name(iTarget, g_szSixPlName, charsmax(g_szSixPlName));
					UTIL_ScreenShake(iTarget, (1<<15), (1<<14), (1<<15));
					UTIL_ScreenShake(id, (1<<15), (1<<14), (1<<15));
					UTIL_ScreenFade(iTarget, (1<<10), (1<<10), 0, 0, 0, 0, 255);
					UTIL_ScreenFade(id, (1<<10), (1<<10), 0, 0, 0, 0, 255);
					client_cmd(iTarget, "spk barney/ba_die1");
					client_cmd(id, "spk barney/ba_die1");
					client_print_color(0, print_team_default, "^1[^4INFO^1] Пахан ^3%s ^1объявил нового шестнаря. Им стал -^3 %s^1.", szName, g_szSixPlName);
					remove_task(id+TASK_PAHAN_INFORMER);
				}
				else client_print_color(id, print_team_default,"^1[^4INFO^1] Что бы назначить ^3шестнаря^1, подойдите к зеку и нажмите ^4E^1.");
			}
			else return;
		}
	}
	if(g_iSoccerBall && g_iSoccerBallOwner == id) 
	{
		if(pev_valid(g_iSoccerBall)) 
		{
			if(get_member(id, m_afButtonPressed) & IN_USE) 
			{
				new Float:vecOrigin[3];
				get_entvar(g_iSoccerBall, var_origin, vecOrigin);
				if(engfunc(EngFunc_PointContents, vecOrigin) != CONTENTS_EMPTY) return;
				new iButton = get_entvar(id, var_button), Float:vecVelocity[3];
				if(iButton & IN_DUCK) 
				{
					if(iButton & IN_FORWARD) UTIL_PlayerAnimation(id, "soccer_crouchrun");
					else UTIL_PlayerAnimation(id, "soccer_crouch_idle");
					velocity_by_aim(id, 1000, vecVelocity);
					bSetModBit(g_bSoccerBallTrail);
					CREATE_BEAMFOLLOW(g_iSoccerBall, g_pSpriteBeam, 4, 5, 255, 255, 255, 130);
				}
				else 
				{
					if(iButton & IN_FORWARD) 
					{
						if(iButton & IN_RUN) UTIL_PlayerAnimation(id, "soccer_walk");
						else UTIL_PlayerAnimation(id, "soccer_run");
					}
					else UTIL_PlayerAnimation(id, "soccer_idle");
					velocity_by_aim(id, 600, vecVelocity);
				}
				set_entvar(g_iSoccerBall, var_solid, SOLID_TRIGGER);
				set_entvar(g_iSoccerBall, var_velocity, vecVelocity);
				rh_emit_sound2(id, 0, CHAN_AUTO, "egoist/jb/soccer/kick_ball.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				CREATE_KILLPLAYERATTACHMENTS(id);
				jbe_set_hand_model(id);
				g_iSoccerBallOwner = 0;
				g_iSoccerKickOwner = id;
			}
		}
		else jbe_soccer_remove_ball();
	}
}


public PlayerResetMaxSpeed_Post(id) {
	if((g_iDayMode == 1 || g_iDayMode == 2) && IsNotSetBit(g_iBitUserDuel, id) && IsSetBit(g_iBitFastRun, id)) set_member(id, var_maxspeed, 400.0);
}

public PlayerSpawn_Post(id) {
	if(IsSetBit(g_iBitUserConnected, id)) {
		if(id == g_iMedSisID) g_iMedSisID = 0;
		if(id == g_iAthrID) g_iAthrID = 0;
		if(id == g_iSixPlID) g_iSixPlID = 0;
		
		if(IsNotSetBit(g_iBitUserAlive, id)) {
			SetBit(g_iBitUserAlive, id);
			g_iAlivePlayersNum[g_iUserTeam[id]]++;
		}
		else jbe_set_user_money(id, jbe_get_user_money(id) + g_iAllCvars[ROUND_ALIVE_MODEY], true);
		
		if(!g_iInformerStatus[id] && !task_exists(TASK_SHOW_INFORMER + id)) set_task(INFORMER_SECOND_UPDATE, "jbe_team_informer", id+TASK_SHOW_INFORMER, _, _, "b" );
		
		jbe_set_user_money(id, jbe_get_user_money(id) + g_iAllCvars[ROUND_FREE_MODEY], true);
		jbe_default_player_model(id);

		rg_remove_all_items(id, false);
		rg_give_item(id, "weapon_knife", GT_APPEND);
		rg_set_user_armor(id, 0, ARMOR_KEVLAR);
		if(g_iDayMode == 1 || g_iDayMode == 2) {
			if(g_iUserTeam[id] == 2)  {
				Show_WeaponsGuardMenu(id);
				if(task_exists(id + TASK_RANDOM_WEAPON)) remove_task(id + TASK_RANDOM_WEAPON);
				set_task(10.0, "GiveRandomCTweapon", id + TASK_RANDOM_WEAPON);
				if(!task_exists(id + TASK_CT_SPAWN_HEALTH)) set_task(0.1, "Spawn_PostHealth", id + TASK_CT_SPAWN_HEALTH);
			}
			if(g_eUserCostumes[id][HIDE]) jbe_set_user_costumes(id, g_eUserCostumes[id][COSTUMES], g_eUserCostumes[id][ACCES_FLAGS]);
		}
	}
}

public Spawn_PostHealth(id) {
	id -= TASK_CT_SPAWN_HEALTH;
	new Float:fHealth = Float:g_iAllCvars[CT_SPAWN_HEALTH] * Float:g_iAlivePlayersNum[1];
	if(!fHealth) fHealth = 100.0;
	rg_set_user_health(id, fHealth);
}

public PlayerKilled_Pre(iVictim) {
	if(IsSetBit(g_iBitUserVoteDayMode, iVictim) || IsSetBit(g_iBitUserFrozen, iVictim)) {
		set_entvar(iVictim, var_flags, get_entvar(iVictim, var_flags) & ~FL_FROZEN);
	}
}

public PlayerKilled_Post(iVictim, iKiller, iGib) 
{
	if(IsNotSetBit(g_iBitUserAlive, iVictim)) return;
	ClearBit(g_iBitUserAlive, iVictim);
	g_iAlivePlayersNum[g_iUserTeam[iVictim]]--;
	
	if(iVictim == g_iAthrID) 
	{
		if(task_exists(g_iAthrID+TASK_PAHAN_INFORMER)) remove_task(g_iAthrID+TASK_PAHAN_INFORMER);
		g_iAthrID = 0;
		g_szAthrName = "Мёртв";
		if(IsSetBit(g_iBitUserAlive, g_iSixPlID))
		{
			g_szSixPlName = "Стал Блатным";
			g_iAthrID = g_iSixPlID;
			set_user_athr(g_iAthrID);
			client_print_color(0, print_team_default, "^1[^4INFO^1] %L", LANG_PLAYER, "JBE_SIXPLAYER_UP", g_szAthrName);
		}
	}
	
	if(iVictim == g_iMedSisID) 
	{
		remove_task(g_iMedSisID+TASK_MEDSIS_HEALTHGIVE);
		remove_task(g_iMedSisID+TASK_MEDSIS_INFORMER);
		g_iMedSisID = 0;
		g_szSisMedName = "Мертва";
	}
	
	if(iVictim == g_iChiefId) {
		g_iChiefId = 0;
		g_iChiefStatus = 2;
		g_szChiefName = "";
		if(bIsSetmodBit(g_bSoccerGame)) remove_task(iVictim + TASK_SHOW_SOCCER_SCORE);
		if(jbe_is_user_valid(iKiller) && g_iUserTeam[iKiller] == 1) jbe_set_user_money(iKiller, jbe_get_user_money(iKiller) + g_iAllCvars[KILLED_CHIEF_MODEY], true);
	}
	else if(jbe_is_user_valid(iKiller) && g_iUserTeam[iKiller] == 1) jbe_set_user_money(iKiller, jbe_get_user_money(iKiller) + g_iAllCvars[KILLED_GUARD_MODEY], true);
	
	switch(g_iDayMode) {
		case 1, 2: {	
			if(jbe_is_user_valid(iKiller)) {
				if(iKiller == iVictim) return;
				if(g_iUserTeam[iKiller] == 1) {
					new szVictimName[32], iExp = (g_iAllCvars[MUTLI_EXP] > 1 ? (g_iAllCvars[EXP_KILL_PLAYER] * g_iAllCvars[MUTLI_EXP]) : g_iAllCvars[EXP_KILL_PLAYER]);
					g_iUserExp[iKiller] = g_iUserExp[iKiller] + iExp;
					if(g_iUserExp[iKiller] >= g_iUserNextExp[iKiller]) jbe_forse_lvl(iKiller);
					get_user_name(iVictim, szVictimName, charsmax(szVictimName)); 	
					client_print_color(iKiller, print_team_default, "^1[^4INFO^1] %L", iKiller, "JBE_CHAT_EXP_KILL", iExp, szVictimName); 
				}
			}
			if(IsSetBit(g_iBitUserSoccer, iVictim)) {
				ClearBit(g_iBitUserSoccer, iVictim);
				if(iVictim == g_iSoccerBallOwner) {
					CREATE_KILLPLAYERATTACHMENTS(iVictim);
					set_entvar(g_iSoccerBall, var_solid, SOLID_TRIGGER);
					set_entvar(g_iSoccerBall, var_velocity, {0.0, 0.0, 0.1});
					g_iSoccerBallOwner = 0;
				}
				if(bIsSetmodBit(g_bSoccerGame)) remove_task(iVictim+TASK_SHOW_SOCCER_SCORE);
			}
			if(g_iDuelStatus && IsSetBit(g_iBitUserDuel, iVictim)) {
				jbe_duel_ended(iVictim);
				return;
			}
			if(get_entvar(iVictim, var_renderfx) != kRenderFxNone || get_entvar(iVictim, var_rendermode) != kRenderNormal) {
				rg_set_user_rendering(iVictim, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
				g_eUserRendering[iVictim][RENDER_STATUS] = false;
			}
			if(g_iUserTeam[iVictim] == 1) {
				ClearBit(g_iBitUserBoxing, iVictim);
				ClearBit(g_iBitScrewdriver, iVictim);
				ClearBit(g_iBitChainsaw, iVictim);
				ClearBit(g_iBitWeaponStatus, iVictim);
				ClearBit(g_iBitUnstableVirus, iVictim);
				ClearBit(g_iBitLatchkey, iVictim);
				if(task_exists(iVictim + TASK_REMOVE_SYRINGE)) remove_task(iVictim + TASK_REMOVE_SYRINGE);
				ClearBit(g_iBitFrostNade, iVictim);
				if(IsSetBit(g_iBitInvisibleHat, iVictim)) {
					ClearBit(g_iBitInvisibleHat, iVictim);
					if(task_exists(iVictim + TASK_INVISIBLE_HAT)) remove_task(iVictim + TASK_INVISIBLE_HAT);
				}
				ClearBit(g_iBitClothingGuard, iVictim);
				ClearBit(g_iBitClothingType, iVictim);
				ClearBit(g_iBitHingJump, iVictim);
				if(IsSetBit(g_iBitUserWanted, iVictim)) {
					jbe_sub_user_wanted(iVictim);
					if(jbe_is_user_valid(iKiller) && g_iUserTeam[iKiller] == 2) jbe_set_user_money(iKiller, jbe_get_user_money(iKiller) + 40, true);
				}
				if(IsSetBit(g_iBitUserFree, iVictim)) jbe_sub_user_free(iVictim);
				if(jbe_is_user_valid(iKiller) && g_iUserTeam[iKiller] == 2) {
					if(g_iBitKilledUsers[iKiller]) SetBit(g_iBitKilledUsers[iKiller], iVictim);
					else {
						g_iMenuTarget[iKiller] = iVictim;
						SetBit(g_iBitKilledUsers[iKiller], iVictim);
						Show_KillReasonsMenu(iKiller, iVictim);
					}
				}
				if(g_iAlivePlayersNum[1] == 1) {
					if(bIsSetmodBit(g_bSoccerStatus)) jbe_soccer_disable_all();
					if(bIsSetmodBit(g_bBoxingStatus)) jbe_boxing_disable_all();
					for(new i = 1; i <= MaxClients; i++) 
					{
						if(g_iUserTeam[i] != 1 || IsNotSetBit(g_iBitUserAlive, i)) continue;
						g_iLastPnId = i;
						if(g_iAthrID == i) if(task_exists(i+TASK_PAHAN_INFORMER)) remove_task(i+TASK_PAHAN_INFORMER);
						if(g_iMedSisID == i) 
						{
							remove_task(i+TASK_MEDSIS_HEALTHGIVE);
							remove_task(i+TASK_MEDSIS_INFORMER);
						}
						Show_LastPrisonerMenu(i);
						break;
					}
				}
			}
			if(g_iUserTeam[iVictim] == 2) {
				if(IsSetBit(g_iBitUserFrozen, iVictim)) {
					ClearBit(g_iBitUserFrozen, iVictim);
					if(task_exists(iVictim + TASK_FROSTNADE_DEFROST)) remove_task(iVictim + TASK_FROSTNADE_DEFROST);
				}				
			}
			rg_set_user_footsteps(iVictim, false);
			ClearBit(g_iBitKokain, iVictim);
			ClearBit(g_iBitFastRun, iVictim);
			ClearBit(g_iBitDoubleJump, iVictim);
			ClearBit(g_iBitAutoBhop, iVictim);
			ClearBit(g_iBitDoubleDamage, iVictim);
		
			if(IsSetBit(g_iBitUserHook, iVictim) && task_exists(iVictim+TASK_HOOK_THINK)) {
				new szBuff[45];
				switch(g_iStatusHook[iVictim]) {
					case 1: formatex(szBuff, charsmax(szBuff), "egoist/jb/%s", g_szSound[HOOK_WAV_A]);
					case 3: formatex(szBuff, charsmax(szBuff), "egoist/jb/%s", g_szSound[HOOK_WAV_B]);
					case 2: formatex(szBuff, charsmax(szBuff), "egoist/jb/%s", g_szSound[HOOK_WAV_C]);
					case 4: formatex(szBuff, charsmax(szBuff), "egoist/jb/%s", g_szSound[HOOK_WAV_V]);
				}
				rh_emit_sound2(iVictim, 0, CHAN_STATIC, szBuff, VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);
			}		
		}
		case 3: {
			if(IsSetBit(g_iBitUserVoteDayMode, iVictim))
			{
				ClearBit(g_iBitUserVoteDayMode, iVictim);
				ClearBit(g_iBitUserDayModeVoted, iVictim);
				show_menu(iVictim, 0, "^n");
				jbe_informer_offset_down(iVictim);
				jbe_menu_unblock(iVictim);
				UTIL_ScreenFade(iVictim, 512, 512, 0, 0, 0, 0, 255, 1);
			}
		}
	}
}

public TraceAttack_Player_Pre(iVictim, iAttacker, Float:fDamage, Float:fDeriction[3], iTraceHandle, iBitDamage) {
	if(jbe_is_user_valid(iAttacker)) {
		new Float:fDamageOld = fDamage;
		if(g_iDayMode == 1 || g_iDayMode == 2) {
			if(bIsSetmodBit(g_bSoccerStatus) && IsSetBit(g_iBitUserSoccer, iAttacker)) {
				if(IsSetBit(g_iBitUserSoccer, iVictim)) {
					if(g_iSoccerUserTeam[iVictim] == g_iSoccerUserTeam[iAttacker]) return HC_SUPERCEDE;
					SetHookChainArg(3, ATYPE_FLOAT, 0.0);
					return HC_CONTINUE;
				}
				return HC_SUPERCEDE;
			}
			if(bIsSetmodBit(g_bBoxingStatus) && IsSetBit(g_iBitUserBoxing, iAttacker)) {
				if(g_iBoxingGame && IsSetBit(g_iBitUserBoxing, iVictim)) {
					if(g_iBoxingGame == 2 && g_iBoxingUserTeam[iVictim] == g_iBoxingUserTeam[iAttacker]) return HC_SUPERCEDE;
					switch(g_iBoxingTypeKick[iAttacker]) {
						case 2: {
							if(get_member(iVictim, m_LastHitGroup) == HIT_HEAD) {
								fDamage = 33.0;
								UTIL_ScreenShake(iVictim, (1<<15), (1<<14), (1<<15));
								UTIL_ScreenFade(iVictim, (1<<13), (1<<13), 0, 0, 0, 0, 245);
								rh_emit_sound2(iVictim, 0, CHAN_AUTO, "egoist/jb/boxing/super_hit.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
							}
							else fDamage = 22.0;
						}
						case 3: {
							if(get_member(iVictim, m_LastHitGroup) == HIT_HEAD) {
								fDamage = 13.0;
								UTIL_ScreenShake(iVictim, (1<<12), (1<<12), (1<<12));
								UTIL_ScreenFade(iVictim, (1<<10), (1<<10), 0, 50, 0, 0, 200);
							}
							else fDamage = 9.0;
						}
						case 4: {
							if(get_member(iVictim, m_LastHitGroup) == HIT_HEAD) {
								fDamage = 27.0;
								UTIL_ScreenShake(iVictim, (1<<15), (1<<14), (1<<15));
								UTIL_ScreenFade(iVictim, (1<<13), (1<<13), 0, 0, 0, 0, 245);
								rh_emit_sound2(iVictim, 0, CHAN_AUTO, "egoist/jb/boxing/super_hit.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
							}
							else fDamage = 18.0;
						}
						default: {
							if(get_member(iVictim, m_LastHitGroup) == HIT_HEAD) {
								fDamage = 21.0;
								UTIL_ScreenShake(iVictim, (1<<12), (1<<12), (1<<12));
								UTIL_ScreenFade(iVictim, (1<<10), (1<<10), 0, 50, 0, 0, 200);
							}
							else fDamage = 13.0;
						}
					}
					SetHookChainArg(3, ATYPE_FLOAT, fDamage);
					return HC_CONTINUE;
				}
				return HC_SUPERCEDE;
			}
			if(g_iDuelStatus) {
				if(g_iDuelStatus == 1 && IsSetBit(g_iBitUserDuel, iVictim)) return HC_SUPERCEDE;
				if(g_iDuelStatus == 2) {
					if(IsSetBit(g_iBitUserDuel, iVictim) || IsSetBit(g_iBitUserDuel, iAttacker)) {
						if(IsSetBit(g_iBitUserDuel, iVictim) && IsSetBit(g_iBitUserDuel, iAttacker)) {
							if(g_iAllCvars[DUEL_SOUND] && ~iBitDamage & (1<<24) && g_iModeDuel != 3 && g_iModeDuel != 4 && g_iModeDuel != 6) {
								if(!task_exists(TASK_DUEL_STRIKE)) set_task(0.1, "Duel_Play", TASK_DUEL_STRIKE);	
							}					
							return HC_CONTINUE;
						}
						return HC_SUPERCEDE;
					}
				}
			}
			if(g_iUserTeam[iAttacker] == 1) {
				if(g_iUserTeam[iVictim] == 2) {
					if(IsNotSetBit(g_iBitUserWanted, iAttacker)) {
						if(!g_szWantedNames[0]) {
							rh_emit_sound2(0, iVictim, CHAN_AUTO, "egoist/jb/other/prison_riot.wav", VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);
							rh_emit_sound2(0, iVictim, CHAN_AUTO, "egoist/jb/other/prison_riot.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
							jbe_set_user_money(iAttacker, jbe_get_user_money(iAttacker) + g_iAllCvars[RIOT_START_MODEY], true);
						}
						jbe_add_user_wanted(iAttacker);
					}
					if(g_iBitUserFrozen && IsSetBit(g_iBitUserFrozen, iVictim)) return HC_SUPERCEDE;
				}
				if(g_iBitWeaponStatus && IsSetBit(g_iBitWeaponStatus, iAttacker) && get_user_weapon(iAttacker) == CSW_KNIFE) {
					if(IsSetBit(g_iBitScrewdriver, iAttacker)) fDamage = (fDamage * 1.5);
					else if(IsSetBit(g_iBitChainsaw, iAttacker)) {
						fDamage = (fDamage * 2.5);
						UTIL_ScreenFade(iAttacker, (1<<10), (1<<10), 0, 50, 0, 0, 200);
						if(g_iUserTeam[iVictim] == 2) {
							UTIL_ScreenShake(iVictim, (1<<15), (1<<14), (1<<15));
							UTIL_ScreenFade(iVictim, (1<<13), (1<<13), 0, 0, 0, 0, 245);
						}
					}				
				}
				if(iAttacker == g_iAthrID) fDamage = (fDamage * g_fCvars[ATHR_DAMAGE]);
				else if(iAttacker == g_iSixPlID) fDamage = (fDamage * g_fCvars[SIXPL_DAMAGE]);
			}
			if(g_iBitKokain && IsSetBit(g_iBitKokain, iVictim)) fDamage = (fDamage * 0.5);
			if(g_iBitDoubleDamage && IsSetBit(g_iBitDoubleDamage, iAttacker)) fDamage = (fDamage * 2.0);
		}
		if(g_iUserTeam[iVictim] == g_iUserTeam[iAttacker]) {
			switch(g_iFriendlyFire) {
				case 0: return HC_SUPERCEDE;
				case 1: {
					if(g_iUserTeam[iVictim] == 1) fDamage = (fDamage / 0.35);
					else return HC_SUPERCEDE;
				}
				case 2: {
					if(g_iUserTeam[iVictim] == 2) fDamage = (fDamage / 0.35);
					else return HC_SUPERCEDE;
				}
				case 3: fDamage = (fDamage / 0.35);
			}
		}
		if(fDamageOld != fDamage) SetHookChainArg(3, ATYPE_FLOAT, fDamage);
	}
	return HC_CONTINUE;
}

public TakeDamagePlayer_Pre(iVictim, iInflictor, iAttacker, Float: fDamage, iBitDamage) {
	if(g_iDayMode == 1 || g_iDayMode == 2) {
		if(g_iDuelStatus && IsSetBit(g_iBitUserDuel, iVictim) && !jbe_is_user_valid(iAttacker)) return HC_SUPERCEDE;
		if(jbe_is_user_valid(iAttacker) && iBitDamage & (1<<24)) { // DMG_HEGRENADE
			if(g_iUserTeam[iVictim] == g_iUserTeam[iAttacker]) {
				switch(g_iFriendlyFire) {
					case 0: return HC_SUPERCEDE;
					case 1: {
						if(g_iUserTeam[iVictim] == 1) fDamage = (fDamage / 0.35);
						else return HC_SUPERCEDE;
					}
					case 2: {
						if(g_iUserTeam[iVictim] == 2) fDamage = (fDamage / 0.35);
						else return HC_SUPERCEDE;
					}
					case 3: fDamage = (fDamage / 0.35);
				}
				SetHookChainArg(4, ATYPE_FLOAT, fDamage);
			}
			else jbe_add_user_wanted(iAttacker);
		}
	}
	return HC_CONTINUE;
}

public TraceAttack_Button(iEntButton, iAttacker) {
	if((g_iDayMode == 1 || g_iDayMode == 2) && is_valid_ent(iEntButton) && jbe_is_user_valid(iAttacker) && g_iUserTeam[iAttacker] == 2 && IsNotSetBit(g_iBitUserDuel, iAttacker)) {
		ExecuteHamB(Ham_Use, iEntButton, iAttacker, 0, 2, 1.0);
		set_entvar(iEntButton, var_frame, 0.0);
	}
	return HC_CONTINUE;
}
/*===== <- 'reapi' события <- =====*///

/*===== -> 'hamsandwich' события -> =====*///{
hamsandwich_init() {
	RegisterHam(Ham_Touch, "player", "Ham_PlayerTouch", false);

	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "Ham_KnifePrimaryAttack_Post", true);
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "Ham_KnifeSecondaryAttack_Post", true);
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "Ham_KnifeDeploy_Post", true);
	
	new const g_szDoorClass[][] = {"func_door", "func_door_rotating"};
	for(new i; i < sizeof(g_szDoorClass); i++) RegisterHam(Ham_Use, g_szDoorClass[i], "Ham_DoorUse", false);
	for(new i; i < sizeof(g_szDoorClass); i++) RegisterHam(Ham_Blocked, g_szDoorClass[i], "Ham_DoorBlocked", false);
	
	RegisterHam(Ham_Think, "func_wall", "Ham_WallThink_Post", true);
	RegisterHam(Ham_Touch, "func_wall", "Ham_WallTouch_Post", true);
	
	register_impulse(100, "ClientImpulse100");
	new const g_szWeaponName[][] = {"weapon_p228", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10", "weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552", "weapon_ak47", "weapon_p90"};
	for(new i; i < sizeof(g_szWeaponName); i++)  { 
		RegisterHam(Ham_Item_Deploy, g_szWeaponName[i], "Ham_ItemDeploy_Post", true);
		RegisterHam(Ham_Weapon_PrimaryAttack, g_szWeaponName[i], "Ham_ItemPrimaryAttack_Post", true);
	}
	
	RegisterHam(Ham_Touch, "grenade", "Ham_GrenadeTouch_Post", true);
	for(new i; i <= 8; i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Use, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", false));
	for(new i = 9; i < sizeof(g_szHamHookEntityBlock); i++) DisableHamForward(g_iHamHookForwards[i] = RegisterHam(Ham_Touch, g_szHamHookEntityBlock[i], "HamHook_EntityBlock", false));
}

public OverflowBufferClear(id){
	id -= TASK_BUFFER_OVERFLOW;
	ClearBit(g_iBitUserOverflowChannel, id);
}

public Ham_PlayerTouch(pPlayer, iTouch) {
	if(IsNotSetBit(g_iBitUserConnected, pPlayer) || !pev_valid(iTouch)) return HAM_IGNORED;
	
	if(IsSetBit(g_iBitUserOverflowChannel, pPlayer) || pPlayer == iTouch || g_iDuelStatus >= 1 || jbe_get_day_mode() == 3 || 
	!(get_entvar(pPlayer, var_button) & IN_USE)) return HAM_IGNORED;
	
	SetBit(g_iBitUserOverflowChannel, pPlayer);
	set_task(TOUCH_ENTITY_RELOAD, "OverflowBufferClear", pPlayer + TASK_BUFFER_OVERFLOW);
	
	new szClassName[32];
	get_entvar(iTouch, var_classname, szClassName, charsmax(szClassName));
	
	if(szClassName[0] == 't' && szClassName[2] == 'a' && szClassName[4] == 'e' && szClassName[5] == 'r') Touch_PlayerWithTrade(pPlayer, iTouch);
	else if(jbe_is_user_valid(iTouch) && IsSetBit(g_iBitUserConnected, iTouch)) Touch_PlayerWithPlayer(pPlayer, iTouch);

	return HAM_IGNORED;
}

public Touch_PlayerWithPlayer(pPlayer, iTouch) {
	if(IsNotSetBit(g_iBitUserConnected, iTouch) || IsNotSetBit(g_iBitUserConnected, pPlayer)) return PLUGIN_HANDLED;

	/*---------------- Зек с Охранником ---------------------*/
	else if(g_iUserTeam[pPlayer] == 1 && g_iUserTeam[iTouch] == 2) {
		g_iIdTouchPlayer[pPlayer] = iTouch;
		return Show_TouchPrWithGr(pPlayer);
	}
	/*---------------- Зек с Зеком ---------------------*/
	else if(g_iUserTeam[pPlayer] == 1 && g_iAthrID != pPlayer && g_iUserTeam[iTouch] == 1) 
	{
		g_iIdTouchPlayer[pPlayer] = iTouch;
		return Show_TouchPrWithPr(pPlayer);
	}
	/*---------------- Охранник с Зеком ---------------------*/
	else if(g_iUserTeam[pPlayer] == 2 && g_iUserTeam[iTouch] == 1) {
		g_iIdTouchPlayer[pPlayer] = iTouch;
		return Show_TouchGrWithPr(pPlayer);
	}
	return PLUGIN_HANDLED;
}
public Touch_PlayerWithTrade(id, iTrader) {
	if(g_iDuelStatus || !pev_valid(iTrader) || jbe_get_user_team(id) == 3 || g_iBlockFunction[0] || jbe_get_day_mode() == 3) return PLUGIN_HANDLED;
	get_entvar(iTrader, var_origin, g_fLastOriginTrader[id]);
	switch(g_iUserTeam[id]) {
		case 1: return Show_ShopPrisonersMenu(id, 0);
		case 2: return Show_ShopGuardTradeMenu(id);
	}
	return PLUGIN_HANDLED;
}

public Ham_KnifePrimaryAttack_Post(iEntity) {
	new id = get_member(iEntity, m_pPlayer);
	if(bIsSetmodBit(g_bSoccerStatus) && IsSetBit(g_iBitUserSoccer, id)) {
		set_member(id, m_flNextAttack, 1.0);
		return;
	}
	if(bIsSetmodBit(g_bBoxingStatus) && IsSetBit(g_iBitUserBoxing, id)) {
		if(get_entvar(id, var_button) & IN_BACK) {
			g_iBoxingTypeKick[id] = 4;
			set_member(id, m_flNextAttack, 1.5);
		}
		else {
			g_iBoxingTypeKick[id] = 3;
			set_member(id, m_flNextAttack, 0.9);
		}
		return;
	}
	if(g_iBitWeaponStatus && IsSetBit(g_iBitWeaponStatus, id)) {
		if(IsSetBit(g_iBitScrewdriver, id)) set_member(id, m_flNextAttack, 0.7);
		else if(IsSetBit(g_iBitChainsaw, id)) set_member(id, m_flNextAttack, 2.5);
		return;
	}
	switch(g_iUserTeam[id]) {
		case 1: set_member(id, m_flNextAttack, (IsSetBit(g_iBitUnstableVirus, id) ? 0.3 : 1.0));
		case 2: set_member(id, m_flNextAttack, 0.5);
	}
}

public Ham_KnifeSecondaryAttack_Post(iEntity) {
	new id = get_member(iEntity, m_pPlayer);
	if(bIsSetmodBit(g_bSoccerStatus) && IsSetBit(g_iBitUserSoccer, id)) {
		set_member(id, m_flNextAttack, 1.0);
		return;
	}
	if(bIsSetmodBit(g_bBoxingStatus) && IsSetBit(g_iBitUserBoxing, id)) {
		if(get_entvar(id, var_button) & IN_BACK) {
			g_iBoxingTypeKick[id] = 2;
			set_member(id, m_flNextAttack, 1.5);
		}
		else {
			static iKick; 
			iKick = !iKick;
			g_iBoxingTypeKick[id] = iKick;
			set_member(id, m_flNextAttack, 1.1);
		}
		return;
	}
	if(g_iBitWeaponStatus && IsSetBit(g_iBitWeaponStatus, id)) {
		if(IsSetBit(g_iBitScrewdriver, id)) set_member(id, m_flNextAttack, 1.0);
		else if(IsSetBit(g_iBitChainsaw, id)) set_member(id, m_flNextAttack, 4.0);
		return;
	}
	switch(g_iUserTeam[id]) {
		case 1: set_member(id, m_flNextAttack, (IsSetBit(g_iBitUnstableVirus, id) ? 0.3 : 1.0));
		case 2: set_member(id, m_flNextAttack, 1.37);
	}
}

public Ham_KnifeDeploy_Post(iEntity) {
	new id = get_member(iEntity, m_pPlayer);
	if(bIsSetmodBit(g_bSoccerStatus) && IsSetBit(g_iBitUserSoccer, id)) {
		if(g_iSoccerBallOwner == id) jbe_soccer_hand_ball_model(id);
		else jbe_set_hand_model(id);
		return;
	}
	if(bIsSetmodBit(g_bBoxingStatus) && IsSetBit(g_iBitUserBoxing, id)) {
		jbe_boxing_gloves_model(id, g_iBoxingUserTeam[id]);
		return;
	}
	if(g_iBitWeaponStatus && IsSetBit(g_iBitWeaponStatus, id)) {
		if(IsSetBit(g_iBitScrewdriver, id)) jbe_set_screwdriver_model(id);
		else if(IsSetBit(g_iBitChainsaw, id)) jbe_set_chainsaw_model(id);
		return;
	}
	jbe_default_knife_model(id);
}

public Ham_DoorUse(iEntity, iCaller, iActivator) {
	if(iCaller != iActivator && get_entvar(iEntity, var_iuser1) == IUSER1_DOOR_KEY) return HAM_SUPERCEDE;
	return HAM_IGNORED;
}

public Ham_DoorBlocked(iBlocked, iBlocker) {
	if(jbe_is_user_valid(iBlocker) && IsSetBit(g_iBitUserAlive, iBlocker) && get_entvar(iBlocked, var_iuser1) == IUSER1_DOOR_KEY) {
		ExecuteHamB(Ham_TakeDamage, iBlocker, 0, 0, 9999.9, 0);
		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}

public Ham_WallThink_Post(iEntity) {
	if(iEntity == g_iSoccerBall) {
		if(pev_valid(iEntity)) {
			set_entvar(iEntity, var_nextthink, get_gametime() + 0.04);
			if(g_iSoccerBallOwner) {
				new Float:vecVelocity[3];
				get_entvar(g_iSoccerBallOwner, var_velocity, vecVelocity);
				if(vector_length(vecVelocity) > 20.0) {
					new Float:fAngles[3];
					vector_to_angle(vecVelocity, fAngles);
					fAngles[0] = 0.0;
					set_entvar(iEntity, var_angles, fAngles);
					set_entvar(iEntity, var_sequence, 1);
				}
				else set_entvar(iEntity, var_sequence, 0);
				velocity_by_aim(g_iSoccerBallOwner, 15, vecVelocity);
				new Float:vecOrigin[3];
				get_entvar(g_iSoccerBallOwner, var_origin, vecOrigin);
				vecOrigin[0] += vecVelocity[0];
				vecOrigin[1] += vecVelocity[1];
				if(get_entvar(g_iSoccerBallOwner, var_flags) & FL_DUCKING) vecOrigin[2] -= 18.0;
				else vecOrigin[2] -= 36.0;
				set_entvar(g_iSoccerBall, var_origin, vecOrigin);
			}
			else {
				new Float:vecVelocity[3], Float:fVectorLength;
				get_entvar(iEntity, var_velocity, vecVelocity);
				fVectorLength = vector_length(vecVelocity);
				if(bIsSetmodBit(g_bSoccerBallTrail) && fVectorLength < 600.0) {
					bClearModBit(g_bSoccerBallTrail);
					CREATE_KILLBEAM(iEntity);
				}
				if(fVectorLength > 20.0) {
					new Float:fAngles[3];
					vector_to_angle(vecVelocity, fAngles);
					fAngles[0] = 0.0;
					set_entvar(iEntity, var_angles, fAngles);
					set_entvar(iEntity, var_sequence, 1);
				}
				else set_entvar(iEntity, var_sequence, 0);
				if(g_iSoccerKickOwner) {
					new Float:fBallOrigin[3], Float:fOwnerOrigin[3], Float:fDistance;
					get_entvar(g_iSoccerBall, var_origin, fBallOrigin);
					get_entvar(g_iSoccerKickOwner, var_origin, fOwnerOrigin);
					fBallOrigin[2] = 0.0;
					fOwnerOrigin[2] = 0.0;
					fDistance = get_distance_f(fBallOrigin, fOwnerOrigin);
					if(fDistance > 24.0) g_iSoccerKickOwner = 0;
				}
			}
		}
		else jbe_soccer_remove_ball();
	}
}

public Ham_WallTouch_Post(iTouched, iToucher) {
	if(g_iSoccerBall && iTouched == g_iSoccerBall) {
		if(pev_valid(iTouched)) {
			if(bIsSetmodBit(g_bSoccerBallTouch) && !g_iSoccerBallOwner && jbe_is_user_valid(iToucher) && IsSetBit(g_iBitUserSoccer, iToucher)) {
				if(g_iSoccerKickOwner == iToucher) return;
				g_iSoccerBallOwner = iToucher;
				set_entvar(iTouched, var_solid, SOLID_NOT);
				set_entvar(iTouched, var_velocity, Float:{0.0, 0.0, 0.0});
				rh_emit_sound2(iToucher, 0, CHAN_AUTO, "egoist/jb/soccer/grab_ball.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				if(bIsSetmodBit(g_bSoccerBallTrail)) {
					bClearModBit(g_bSoccerBallTrail);
					CREATE_KILLBEAM(iTouched);
				}
				CREATE_PLAYERATTACHMENT(iToucher, _, g_pSpriteBall, 3000);
				jbe_soccer_hand_ball_model(iToucher);
			}
			else {
				new Float:iDelay = get_gametime();
				static Float:iDelayOld;
				if((iDelayOld + 0.15) <= iDelay) {
					new Float:vecVelocity[3];
					get_entvar(iTouched, var_velocity, vecVelocity);
					if(vector_length(vecVelocity) > 20.0) {
						vecVelocity[0] *= 0.85;
						vecVelocity[1] *= 0.85;
						vecVelocity[2] *= 0.75;
						set_entvar(iTouched, var_velocity, vecVelocity);
						if((iDelayOld + 0.22) <= iDelay) rh_emit_sound2(iTouched, 0, CHAN_AUTO, "egoist/jb/soccer/bounce_ball.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
						iDelayOld = iDelay;
					}
				}
			}
		}
		else jbe_soccer_remove_ball();
	}
}

public ClientImpulse100(id) {
	if(bIsSetmodBit(g_bSoccerStatus) && g_iSoccerBall) {
		if(IsSetBit(g_iBitUserSoccer, id)) {
			if(g_iSoccerBallOwner && g_iSoccerBallOwner != id && g_iSoccerUserTeam[g_iSoccerBallOwner] != g_iSoccerUserTeam[id]) {
				new Float:fEntityOrigin[3], Float:fPlayerOrigin[3], Float:fDistance;
				get_entvar(g_iSoccerBall, var_origin, fEntityOrigin);
				get_entvar(id, var_origin, fPlayerOrigin);
				fDistance = get_distance_f(fEntityOrigin, fPlayerOrigin);
				if(fDistance < 60.0) {
					CREATE_KILLPLAYERATTACHMENTS(g_iSoccerBallOwner);
					jbe_set_hand_model(g_iSoccerBallOwner);
					g_iSoccerBallOwner = id;
					rh_emit_sound2(id, CHAN_AUTO, 0, "egoist/jb/soccer/grab_ball.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
					CREATE_PLAYERATTACHMENT(id, _, g_pSpriteBall, 3000);
					jbe_soccer_hand_ball_model(id);
				}
			}
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}

public Ham_ItemDeploy_Post(iEntity) {
	if(bIsSetmodBit(g_bSoccerStatus) || bIsSetmodBit(g_bBoxingStatus)) {
		new id = get_member(iEntity, m_pPlayer);
		if(IsSetBit(g_iBitUserSoccer, id) || IsSetBit(g_iBitUserBoxing, id)) rg_internal_cmd(id, "weapon_knife");
	}
}

public Ham_ItemPrimaryAttack_Post(iEntity) {
	if(g_iDuelStatus) {
		new id = get_member(iEntity, m_pPlayer);
		if(IsSetBit(g_iBitUserDuel, id) && IsSetBit(g_iBitUserConnected, id)) {
			switch(g_iDuelType) {
				case 1: {
					set_member(id, m_flNextAttack, 11.0);
					if(task_exists(id+TASK_DUEL_TIMER_ATTACK)) remove_task(id+TASK_DUEL_TIMER_ATTACK);
					id = g_iDuelUsersId[0] != id ? g_iDuelUsersId[0] : g_iDuelUsersId[1];
					set_member(id, m_flNextAttack, 0.0);
					set_task(1.0, "jbe_duel_timer_attack", id+TASK_DUEL_TIMER_ATTACK, _, _, "a", g_iDuelTimerAttack = 11);
					ExecuteHam(Ham_Weapon_Reload, iEntity);
				}
				case 2: {
					set_member(id, m_flNextAttack, 11.0);
					if(task_exists(id+TASK_DUEL_TIMER_ATTACK)) remove_task(id+TASK_DUEL_TIMER_ATTACK);
					id = g_iDuelUsersId[0] != id ? g_iDuelUsersId[0] : g_iDuelUsersId[1];
					set_member(id, m_flNextAttack, 0.0);
					set_member(get_member(id, m_pActiveItem), m_Weapon_flNextSecondaryAttack, get_gametime() + 11.0);
					set_task(1.0, "jbe_duel_timer_attack", id+TASK_DUEL_TIMER_ATTACK, _, _, "a", g_iDuelTimerAttack = 11);
					ExecuteHam(Ham_Weapon_Reload, iEntity);
				}
				case 5:
				{
					set_member(id, m_flNextAttack, 11.0);
					if(task_exists(id+TASK_DUEL_TIMER_ATTACK)) remove_task(id+TASK_DUEL_TIMER_ATTACK);
					id = g_iDuelUsersId[0] != id ? g_iDuelUsersId[0] : g_iDuelUsersId[1];
					set_member(id, m_flNextAttack, 0.0);
					set_member(get_member(id, m_pActiveItem), m_Weapon_flNextSecondaryAttack, get_gametime() + 11.0);
					set_task(1.0, "jbe_duel_timer_attack", id+TASK_DUEL_TIMER_ATTACK, _, _, "a", g_iDuelTimerAttack = 11);
					ExecuteHam(Ham_Weapon_Reload, iEntity);
				}
			}
		}
	}
}

public Ham_GrenadeTouch_Post(iTouched) {
	if((g_iDayMode == 1 || g_iDayMode == 2) && get_entvar(iTouched, var_iuser1) == IUSER1_FROSTNADE_KEY) {
		new Float:vecOrigin[3], id;
		get_entvar(iTouched, var_origin, vecOrigin);
		CREATE_BEAMCYLINDER(vecOrigin, 150, g_pSpriteWave, _, _, 4, 60, _, 0, 110, 255, 255, _);
		while((id = engfunc(EngFunc_FindEntityInSphere, id, vecOrigin, 150.0))) {
			if(jbe_is_user_valid(id) && g_iUserTeam[id] == 2) {
				set_entvar(id, var_flags, get_entvar(id, var_flags) | FL_FROZEN);
				set_member(id, m_flNextAttack, 6.0);
				rg_set_user_rendering(id, kRenderFxGlowShell, 0, 110, 255, kRenderNormal, 0);
				rh_emit_sound2(iTouched, 0, CHAN_AUTO, "egoist/jb/shop/freeze_player.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				SetBit(g_iBitUserFrozen, id);
				if(task_exists(id+TASK_FROSTNADE_DEFROST)) change_task(id+TASK_FROSTNADE_DEFROST, 6.0);
				else set_task(6.0, "jbe_user_defrost", id+TASK_FROSTNADE_DEFROST);
			}
		}
		rh_emit_sound2(iTouched, 0, CHAN_AUTO, "egoist/jb/shop/grenade_frost_explosion.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		engfunc(EngFunc_RemoveEntity, iTouched);
	}
}

public HamHook_EntityBlock(iEntity, id) {
	if(bIsSetmodBit(g_bRoundEnd) || g_iDuelStatus >= 1 || IsSetBit(g_iBitUserDuel, id)) return HAM_SUPERCEDE;
	return HAM_IGNORED;
}
/*===== <- 'hamsandwich' события <- =====*///}

/*===== -> Режимы игры -> =====*///{
game_mode_init() {
	g_aDataDayMode = ArrayCreate(DATA_DAY_MODE);
	g_iHookDayModeStart = CreateMultiForward("jbe_day_mode_start", ET_IGNORE, FP_CELL, FP_CELL);
	g_iHookDayModeEnded = CreateMultiForward("jbe_day_mode_ended", ET_IGNORE, FP_CELL, FP_CELL);
}

public jbe_day_mode_start(iDayMode, iAdmin) {
	new aDataDayMode[DATA_DAY_MODE];
	ArrayGetArray(g_aDataDayMode, iDayMode, aDataDayMode);
	formatex(g_szDayMode, charsmax(g_szDayMode), aDataDayMode[LANG_MODE]);
	if(aDataDayMode[MODE_TIMER]) {
		g_iDayModeTimer = aDataDayMode[MODE_TIMER] + 1;
		set_task(1.0, "jbe_day_mode_timer", TASK_DAY_MODE_TIMER, _, _, "a", g_iDayModeTimer);
	}
	if(iAdmin) {
		g_iFriendlyFire = 0;
		if(g_iDayMode == 2) jbe_free_day_ended();
		else {
			g_iBitUserFree = 0;
			g_szFreeNames = "";
			g_iFreeLang = 0;
		}
		g_iDayMode = 3;
		if(task_exists(TASK_CHIEF_CHOICE_TIME)) remove_task(TASK_CHIEF_CHOICE_TIME);
		g_iChiefId = 0;
		g_szChiefName = "";
		g_iChiefStatus = 0;
		g_iBitUserWanted = 0;
		g_szWantedNames = "";
		g_iWantedLang = 0;
		g_iBitScrewdriver = 0;
		g_iBitChainsaw = 0;
		g_iBitLatchkey = 0;
		g_iBitKokain = 0;
		g_iBitFrostNade = 0;
		g_iBitClothingGuard = 0;
		g_iBitHingJump = 0;
		g_iBitDoubleJump = 0;
		g_iBitAutoBhop = 0;
		g_iBitDoubleDamage = 0;
		g_iBitUserVoice = 0;
		for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) {
			if(IsNotSetBit(g_iBitUserAlive, iPlayer)) continue;
			g_iBitKilledUsers[iPlayer] = 0;
			show_menu(iPlayer, 0, "^n");
			if(g_iBitWeaponStatus && IsSetBit(g_iBitWeaponStatus, iPlayer)) {
				ClearBit(g_iBitWeaponStatus, iPlayer);
				if(get_user_weapon(iPlayer) == CSW_KNIFE) {
					new iActiveItem = get_member(iPlayer, m_pActiveItem);
					if(iActiveItem > 0) ExecuteHamB(Ham_Item_Deploy, iActiveItem);
				}
			}
			if(task_exists(iPlayer+TASK_REMOVE_SYRINGE)) {
				remove_task(iPlayer+TASK_REMOVE_SYRINGE);
				if(get_user_weapon(iPlayer)) {
					new iActiveItem = get_member(iPlayer, m_pActiveItem);
					if(iActiveItem > 0) ExecuteHamB(Ham_Item_Deploy, iActiveItem);
				}
			}
			if(get_entvar(iPlayer, var_renderfx) != kRenderFxNone || get_entvar(iPlayer, var_rendermode) != kRenderNormal) {
				rg_set_user_rendering(iPlayer, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
				g_eUserRendering[iPlayer][RENDER_STATUS] = false;
			}
			if(g_iBitUserFrozen && IsSetBit(g_iBitUserFrozen, iPlayer)) {
				ClearBit(g_iBitUserFrozen, iPlayer);
				if(task_exists(iPlayer+TASK_FROSTNADE_DEFROST)) remove_task(iPlayer+TASK_FROSTNADE_DEFROST);
				set_entvar(iPlayer, var_flags, get_entvar(iPlayer, var_flags) & ~FL_FROZEN);
				set_member(iPlayer, m_flNextAttack, 0.0);
				rh_emit_sound2(iPlayer, 0, CHAN_AUTO, "egoist/jb/shop/defrost_player.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				new Float:vecOrigin[3]; 
				get_entvar(iPlayer, var_origin, vecOrigin);
				CREATE_BREAKMODEL(vecOrigin, _, _, 10, g_pModelGlass, 10, 25, 0x01);
			}
			if(g_iBitInvisibleHat && IsSetBit(g_iBitInvisibleHat, iPlayer)) {
				ClearBit(g_iBitInvisibleHat, iPlayer);
				if(task_exists(iPlayer+TASK_INVISIBLE_HAT)) remove_task(iPlayer+TASK_INVISIBLE_HAT);
			}
			if(g_iBitClothingType && IsSetBit(g_iBitClothingType, iPlayer)) jbe_default_player_model(iPlayer);
			if(g_iBitFastRun && IsSetBit(g_iBitFastRun, iPlayer)) {
				ClearBit(g_iBitFastRun, iPlayer);
				rg_reset_maxspeed(iPlayer);
			}
			if(IsSetBit(g_iBitUserHook, iPlayer) && task_exists(iPlayer+TASK_HOOK_THINK)) {
				new szBuff[45];
				switch(g_iStatusHook[iPlayer]) {
					case 1: formatex(szBuff, charsmax(szBuff), "egoist/jb/%s", g_szSound[HOOK_WAV_A]);
					case 3: formatex(szBuff, charsmax(szBuff), "egoist/jb/%s", g_szSound[HOOK_WAV_B]);
					case 2: formatex(szBuff, charsmax(szBuff), "egoist/jb/%s", g_szSound[HOOK_WAV_C]);
					case 4: formatex(szBuff, charsmax(szBuff), "egoist/jb/%s", g_szSound[HOOK_WAV_V]);
				}
				rh_emit_sound2(iPlayer, 0, CHAN_STATIC, szBuff, VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);
			}
		}
		if(bIsSetmodBit(g_bSoccerStatus)) jbe_soccer_disable_all();
		if(bIsSetmodBit(g_bBoxingStatus)) jbe_boxing_disable_all();
	}
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) jbe_hide_user_costumes(iPlayer);
	jbe_open_doors();
}

public jbe_day_mode_timer() {
	if(--g_iDayModeTimer) formatex(g_szDayModeTimer, charsmax(g_szDayModeTimer), "(0%d:%s%d)", abs(get_min(g_iDayModeTimer)), get_sec(g_iDayModeTimer) < 10 ? "0":"", get_sec(g_iDayModeTimer));
	else {
		g_szDayModeTimer = "";
		ExecuteForward(g_iHookDayModeEnded, g_iReturnDayMode, g_iVoteDayMode, 0);
		g_iVoteDayMode = -1;
	}
}

public jbe_vote_day_mode_start() {
	g_iDayModeVoteTime = g_iAllCvars[DAY_MODE_VOTE_TIME] + 1;
	new aDataDayMode[DATA_DAY_MODE];
	for(new i; i < g_iDayModeListSize; i++) {
		ArrayGetArray(g_aDataDayMode, i, aDataDayMode);
		if(aDataDayMode[MODE_BLOCKED]) aDataDayMode[MODE_BLOCKED]--;
		aDataDayMode[VOTES_NUM] = 0;
		ArraySetArray(g_aDataDayMode, i, aDataDayMode);
	}
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) {
		if(IsNotSetBit(g_iBitUserConnected, iPlayer)) continue;
		
		remove_task(iPlayer+TASK_ROLE_INFORMER);
		g_fMainInformerColor[iPlayer] = {0, 255, 255};
		
		if(!g_iInformerStatus[iPlayer] && !task_exists(TASK_SHOW_INFORMER + iPlayer)) set_task(INFORMER_SECOND_UPDATE, "jbe_team_informer", iPlayer+TASK_SHOW_INFORMER, _, _, "b" );
		if(IsNotSetBit(g_iBitUserAlive, iPlayer)) continue;
		SetBit(g_iBitUserVoteDayMode, iPlayer);
		g_iBitKilledUsers[iPlayer] = 0;
		g_iMenuPosition[iPlayer] = 0;
		jbe_menu_block(iPlayer);
		set_entvar(iPlayer, var_flags, get_entvar(iPlayer, var_flags) | FL_FROZEN);
		set_member(iPlayer, m_flNextAttack, float(g_iDayModeVoteTime));
		UTIL_ScreenFade(iPlayer, 0, 0, 4, 0, 0, 0, 255);
		UTIL_BarTime(iPlayer, g_iDayModeVoteTime);
	}
	set_task(1.0, "jbe_vote_day_mode_timer", TASK_VOTE_DAY_MODE_TIMER, _, _, "a", g_iDayModeVoteTime);
}

public jbe_vote_day_mode_timer() {
	if(!--g_iDayModeVoteTime) jbe_vote_day_mode_ended();
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) {
		if(IsNotSetBit(g_iBitUserVoteDayMode, iPlayer)) continue;
		Show_DayModeMenu(iPlayer, g_iMenuPosition[iPlayer]);
	}
}

public jbe_vote_day_mode_ended() {
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) {
		if(IsNotSetBit(g_iBitUserVoteDayMode, iPlayer)) continue;
		ClearBit(g_iBitUserVoteDayMode, iPlayer);
		ClearBit(g_iBitUserDayModeVoted, iPlayer);
		show_menu(iPlayer, 0, "^n");
		jbe_informer_offset_down(iPlayer);
		jbe_menu_unblock(iPlayer);
		set_entvar(iPlayer, var_flags, get_entvar(iPlayer, var_flags) & ~FL_FROZEN);
		set_member(iPlayer, m_flNextAttack, 0.0);
		UTIL_ScreenFade(iPlayer, 512, 512, 0, 0, 0, 0, 255, 1);
	}
	new aDataDayMode[DATA_DAY_MODE], iVotesNum;
	for(new iPlayer; iPlayer < g_iDayModeListSize; iPlayer++) {
		ArrayGetArray(g_aDataDayMode, iPlayer, aDataDayMode);
		if(aDataDayMode[VOTES_NUM] >= iVotesNum) {
			iVotesNum = aDataDayMode[VOTES_NUM];
			g_iVoteDayMode = iPlayer;
		}
	}
	g_iDayModeLimit[g_iVoteDayMode] = 2;
	ArrayGetArray(g_aDataDayMode, g_iVoteDayMode, aDataDayMode);
	aDataDayMode[MODE_BLOCKED] = aDataDayMode[MODE_BLOCK_DAYS];
	ArraySetArray(g_aDataDayMode, g_iVoteDayMode, aDataDayMode);
	ExecuteForward(g_iHookDayModeStart, g_iReturnDayMode, g_iVoteDayMode, 0);
}
/*===== <- Режимы игры <- =====*///}

/*===== -> Остальной хлам и информеры -> =====*///{
jbe_create_buyzone() {
	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_buyzone"));
	set_entvar(iEntity, var_iuser1, IUSER1_BUYZONE_KEY);
}

public jbe_informer(id) {
	id -= TASK_ROLE_INFORMER;
	
	new szBuffer[256]; 
	switch(g_iUserTeam[id]) {
		case 1: format(szBuffer, charsmax(szBuffer), "Масть: [%d] %s^nУважуха: %d | %d^n^nАвторитет: %s^nШестнарь: %s^nСеструха: %s", g_iUserLevel[id] + 1, g_szRankName[id], g_iUserExp[id], jbe_get_user_exp_next(id), g_szAthrName, g_szSixPlName, g_szSisMedName);
		case 2: format(szBuffer, charsmax(szBuffer), "Звание: [%d] %s^nОпыт: %d | %d^n^nАвторитет: %s^nШестнарь: %s^nСеструха: %s", g_iUserLevel[id] + 1, g_szRankName[id], g_iUserExp[id], jbe_get_user_exp_next(id), g_szAthrName, g_szSixPlName, g_szSisMedName);
	}
	set_hudmessage(g_fMainInformerColor[id][0], g_fMainInformerColor[id][1], g_fMainInformerColor[id][2], g_fMainInformerPosX[id], g_fMainInformerPosY[id], 0, 0.0, INFORMER_SECOND_UPDATE, 0.2, 0.1, -1);
	ShowSyncHudMsg(id, g_iSyncRoleInformer, "%s^n^n%L^n%L%s", szBuffer, id, "JBE_HUD_CHIEF", id, g_szChiefStatus[g_iChiefStatus], g_szChiefName, id, g_szFreeLang[g_iFreeLang], g_szFreeNames);
}

public jbe_team_informer(pPlayer) {
	pPlayer -= TASK_SHOW_INFORMER;
	set_task(INFORMER_SECOND_UPDATE, "HudShow_Wanted_Free", pPlayer + TASK_SECONDARY_INFORMER);
	set_hudmessage(g_fMainInformerColor[pPlayer][0], g_fMainInformerColor[pPlayer][1], g_fMainInformerColor[pPlayer][2], -1.0, 0.02, 0, 0.0, INFORMER_SECOND_UPDATE, 0.2, 0.1, -1);
	ShowSyncHudMsg( pPlayer, g_iSyncTeamInformer, "%L %L^n%L^n%L^n%L^n", 
	pPlayer, "JBE_HUD_DAY", g_iDay, pPlayer, g_szDaysWeek[g_iDayWeek], pPlayer, "JBE_HUD_TEAMS", 
	pPlayer, "JBE_HUD_ALIVE", g_iAlivePlayersNum[1], g_iAlivePlayersNum[2], pPlayer, "JBE_HUD_GAME_MODE", pPlayer, g_szDayMode, g_szDayModeTimer);
}

public HudShow_Wanted_Free(id)  {
	id -= TASK_SECONDARY_INFORMER;
	set_hudmessage(random_num(20, 200), random_num(20, 200), random_num(20, 200), g_fFWInformerPosX[id], g_fFWInformerPosY[id], 0, 0.0, (INFORMER_SECOND_UPDATE - 0.1), 0.2, 0.1, -1);
	ShowSyncHudMsg(id, g_iSyncFWInformer, "%L%s%L%s", id, g_szFreeLang[g_iFreeLang], g_szFreeNames, id, g_szWantedLang[g_iWantedLang], g_szWantedNames);
}

public MedSis_Select() {
	new iPlayers[32], iNum, pId;
	for(pId = 1; pId <= MaxClients; pId++) if(g_iUserTeam[pId] == 1 && IsNotSetBit(g_iBitPahan, pId)) iPlayers[iNum++] = pId;
	g_iMedSisID = iPlayers[random_num(0, iNum - 1)];
	set_user_medsis(g_iMedSisID);
}

public Athr_Select() {
	new iPlayers[32], iNum, pId;
	for(pId = 1; pId <= MaxClients; pId++) if(g_iUserTeam[pId] == 1 && pId != g_iMedSisID) iPlayers[iNum++] = pId;
	g_iAthrID = iPlayers[random_num(0, iNum - 1)];
	SetBit(g_iBitPahan, g_iAthrID);
	set_user_athr(g_iAthrID);
	set_task(1.0, "MedSis_Select");
}

public F_iMsPack(id) {
	id -= TASK_MEDSIS_HEALTHGIVE;
	
	if(id != g_iMedSisID) return PLUGIN_HANDLED;
	set_hudmessage(255, 255, 255, 0.52, 0.52, 0, 3.0, 3.0, 0.1, 0.2, -1);
	show_hudmessage(id, "[+1 Аптечка]", ++g_iMedSisHealth);
	client_cmd(id, "spk items/medshot4");
	return PLUGIN_HANDLED;
}

public set_user_athr(id) {
	ClearBit(g_iBitUnstableVirus, id);
	if(task_exists(id + TASK_REMOVE_SYRINGE)) remove_task(id + TASK_REMOVE_SYRINGE);
	get_user_name(g_iAthrID, g_szAthrName, charsmax(g_szAthrName));
	rg_set_user_health(id, Float:rg_get_user_health(id) + g_iAllCvars[ATHR_NUM_HP]);
	rg_set_user_armor(id, rg_get_user_armor(id) + g_iAllCvars[ATHR_NUM_AR], ARMOR_KEVLAR);
	jbe_set_user_model(id, g_szPlayerModel[PRISONER]);
	set_entvar(id, var_skin, 8);
	ExecuteForward(g_Fw_AthrUp, g_ForwardReturn, id);
	if(get_user_weapon(id) == CSW_KNIFE && IsNotSetBit(g_iBitWeaponStatus, id)) jbe_set_atrh_model(id);
	
	new iActiveItem = get_member(id, m_pActiveItem);
	if(iActiveItem > 0) {
		ExecuteHamB(Ham_Item_Deploy, iActiveItem);
		UTIL_WeaponAnimation(id, 3);
	}
	
	set_task(INFORMER_SECOND_UPDATE, "jbe_pahan_informer", id+TASK_PAHAN_INFORMER, _, _, "b");

	if(id == g_iSixPlID) return PLUGIN_HANDLED;
	return PLUGIN_HANDLED;
}

public jbe_pahan_informer(id) {
	id -= TASK_PAHAN_INFORMER;
	set_hudmessage( 255, 255, 0, -1.0, 0.67, 0, 0.0, 1.0, 0.0, 0.0, -1 );
	ShowSyncHudMsg( id, g_iSyncPahanInformer, "Назначить Шестнаря [E]");
}

set_user_medsis(id) {
	if(g_iUserTeam[g_iMedSisID] != 1 || IsNotSetBit(g_iBitUserConnected, g_iMedSisID) || g_iMedSisID == g_iAthrID) {
		format(g_szSisMedName, charsmax(g_szSisMedName), "Произошла ошибка.");
		return PLUGIN_HANDLED;
	}
	ClearBit(g_iBitUnstableVirus, id);
	if(task_exists(id + TASK_REMOVE_SYRINGE)) remove_task(id + TASK_REMOVE_SYRINGE);
	get_user_name(g_iMedSisID, g_szSisMedName, charsmax(g_szSisMedName));
	g_iMedSisHealth = 1;
	rg_set_user_health(id, Float:rg_get_user_health(id) + g_iAllCvars[MEDSIS_NUM_HP]);
	rg_set_user_armor(id, rg_get_user_armor(id) + g_iAllCvars[MEDSIS_NUM_AR], ARMOR_KEVLAR);
	jbe_set_user_model(id, g_szPlayerModel[MEDSIS]);
	if(get_user_weapon(id) == CSW_KNIFE && IsNotSetBit(g_iBitWeaponStatus, id)) jbe_set_medsis_model(id);	
	
	new iActiveItem = get_member(id, m_pActiveItem);
	if(iActiveItem > 0) {
		ExecuteHamB(Ham_Item_Deploy, iActiveItem);
		UTIL_WeaponAnimation(id, 3);
	}
	
	set_task(30.0, "F_iMsPack", id+TASK_MEDSIS_HEALTHGIVE, _, _, "b");
	set_task(INFORMER_SECOND_UPDATE, "jbe_medsis_informer", id+TASK_MEDSIS_INFORMER, _, _, "b");	
	
	ExecuteForward(g_Fw_MedSisUp, g_ForwardReturn, id);
	return PLUGIN_HANDLED;
}

public jbe_medsis_informer(id)
{
	id -= TASK_MEDSIS_INFORMER;
	set_hudmessage( 255, 255, 0, -1.0, 0.6, 0, 0.0, 1.0, 0.0, 0.0, -1 );
	ShowSyncHudMsg( id, g_iSyncPahanInformer, "Подлечить [E]^nАптечки: %d", g_iMedSisHealth);
}

public set_user_sixplayer(id) {
	if(id == g_iMedSisID || IsNotSetBit(g_iBitUserConnected, id)) return;
	ClearBit(g_iBitUnstableVirus, id);
	if(task_exists(id + TASK_REMOVE_SYRINGE)) remove_task(id + TASK_REMOVE_SYRINGE);
	rg_set_user_health(id, Float:rg_get_user_health(id) + g_iAllCvars[SIXPL_NUM_HP]);
	rg_set_user_armor(id, rg_get_user_armor(id) + g_iAllCvars[SIXPL_NUM_AR], ARMOR_KEVLAR);
	jbe_set_user_model(id, g_szPlayerModel[PRISONER]);
	set_entvar(id, var_skin, 7);
	if(get_user_weapon(id) == CSW_KNIFE && IsNotSetBit(g_iBitWeaponStatus, id)) jbe_set_sixpl_model(id);
	ExecuteForward(g_Fw_SixPlayerUp, g_ForwardReturn, id);	
}

jbe_set_user_discount(pPlayer) {
	new iHour; time(iHour);
	g_iUserDiscount[pPlayer] = 0;
	
	if(iHour >= 21 || iHour <= 8) g_iUserDiscount[pPlayer] = g_iAllCvars[NIGHT_DISCOUNT];	
	
	if(pPlayer == g_iAthrID) g_iUserDiscount[pPlayer] += 10;
	if(pPlayer == g_iSixPlID || pPlayer == g_iMedSisID) g_iUserDiscount[pPlayer] += 5;	
	
	if(IsSetBit(g_iBitUserSuperAdmin, pPlayer)) g_iUserDiscount[pPlayer] += g_iAllCvars[ADMIN_DISCOUNT_SHOP];
	else if(IsSetBit(g_iBitUserVip, pPlayer)) g_iUserDiscount[pPlayer] += g_iAllCvars[VIP_DISCOUNT_SHOP];
}

jbe_get_price_discount(pPlayer, iCost) {
	if(!g_iUserDiscount[pPlayer]) return iCost;
	iCost -= floatround(iCost / 100.0 * g_iUserDiscount[pPlayer]);
	return iCost;
}

public jbe_remove_invisible_hat(pPlayer) {
	pPlayer -= TASK_INVISIBLE_HAT;
	if(IsNotSetBit(g_iBitInvisibleHat, pPlayer)) return;
	client_print_color(pPlayer, print_team_blue, "^1[^4INFO^1] %L", pPlayer, "JBE_MENU_ID_INVISIBLE_HAT_REMOVE");
	if(g_eUserRendering[pPlayer][RENDER_STATUS]) rg_set_user_rendering(pPlayer, g_eUserRendering[pPlayer][RENDER_FX], g_eUserRendering[pPlayer][RENDER_RED], g_eUserRendering[pPlayer][RENDER_GREEN], g_eUserRendering[pPlayer][RENDER_BLUE], g_eUserRendering[pPlayer][RENDER_MODE], g_eUserRendering[pPlayer][RENDER_AMT]);
	else rg_set_user_rendering(pPlayer, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
	if(g_eUserCostumes[pPlayer][HIDE]) jbe_set_user_costumes(pPlayer, g_eUserCostumes[pPlayer][COSTUMES], g_eUserCostumes[pPlayer][ACCES_FLAGS]);
}

public jbe_user_defrost(pPlayer) {
	pPlayer -= TASK_FROSTNADE_DEFROST;
	if(IsNotSetBit(g_iBitUserFrozen, pPlayer)) return;
	ClearBit(g_iBitUserFrozen, pPlayer);
	set_entvar(pPlayer, var_flags, get_entvar(pPlayer, var_flags) & ~FL_FROZEN);
	set_member(pPlayer, m_flNextAttack, 0.0);
	if(g_eUserRendering[pPlayer][RENDER_STATUS]) rg_set_user_rendering(pPlayer, g_eUserRendering[pPlayer][RENDER_FX], g_eUserRendering[pPlayer][RENDER_RED], g_eUserRendering[pPlayer][RENDER_GREEN], g_eUserRendering[pPlayer][RENDER_BLUE], g_eUserRendering[pPlayer][RENDER_MODE], g_eUserRendering[pPlayer][RENDER_AMT]);
	else rg_set_user_rendering(pPlayer, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
	rh_emit_sound2(pPlayer, 0, CHAN_AUTO, "egoist/jb/shop/defrost_player.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	new Float:vecOrigin[3]; 
	get_entvar(pPlayer, var_origin, vecOrigin);
	CREATE_BREAKMODEL(vecOrigin, _, _, 10, g_pModelGlass, 10, 25, 0x01);
}

jbe_default_player_model(pPlayer) {
	switch(g_iUserTeam[pPlayer]) {
		case 1: {
			jbe_set_user_model(pPlayer, g_szPlayerModel[PRISONER]);
			set_entvar(pPlayer, var_skin, g_iUserSkin[pPlayer]);
		}
		case 2: jbe_set_user_model(pPlayer, g_szPlayerModel[GUARD]);
	}
}

jbe_default_knife_model(pPlayer) {
	switch(g_iUserTeam[pPlayer]) {
		case 1: {
			if(pPlayer == g_iAthrID) jbe_set_atrh_model(pPlayer);
			else if(pPlayer == g_iSixPlID) jbe_set_sixpl_model(pPlayer);
			else if(pPlayer == g_iMedSisID) jbe_set_medsis_model(pPlayer);
			else if(IsSetBit(g_iBitUnstableVirus, pPlayer)) jbe_set_zm_prisoner_model(pPlayer);
			else jbe_set_hand_model(pPlayer);
		}
		case 2: jbe_set_baton_model(pPlayer);
	}
}

jbe_set_atrh_model(pPlayer) {
	static iszViewModel, iszWeaponModel;
	if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, g_szModelView[V_ATHR]))) set_pev_string(pPlayer, pev_viewmodel2, iszViewModel);
	if(iszWeaponModel || (iszWeaponModel = engfunc(EngFunc_AllocString, g_szModelView[P_ATHR]))) set_pev_string(pPlayer, pev_weaponmodel2, iszWeaponModel);
	set_member(pPlayer, m_flNextAttack, 0.95);
}

jbe_set_sixpl_model(pPlayer) {
	static iszViewModel, iszWeaponModel;
	if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, g_szModelView[V_SIXPL]))) set_pev_string(pPlayer, pev_viewmodel2, iszViewModel);
	if(iszWeaponModel || (iszWeaponModel = engfunc(EngFunc_AllocString, g_szModelView[P_SIXPL]))) set_pev_string(pPlayer, pev_weaponmodel2, iszWeaponModel);
	set_member(pPlayer, m_flNextAttack, 0.85);
}

jbe_set_medsis_model(pPlayer) {
	static iszViewModel, iszWeaponModel;
	if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, g_szModelView[V_MEDSIS]))) set_pev_string(pPlayer, pev_viewmodel2, iszViewModel);
	if(iszWeaponModel || (iszWeaponModel = engfunc(EngFunc_AllocString, g_szModelView[P_MEDSIS]))) set_pev_string(pPlayer, pev_weaponmodel2, iszWeaponModel);
	set_member(pPlayer, m_flNextAttack, 0.75);
}

jbe_set_hand_model(pPlayer) {
	/*if(g_iTattoo[pPlayer] != 0 && g_iTattoo[pPlayer] < 6) Set_TattoModel(pPlayer);
	else
	{*/
	static iszViewModel, iszWeaponModel;
	if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, g_szModelView[V_HAND]))) set_pev_string(pPlayer, pev_viewmodel2, iszViewModel);
	if(iszWeaponModel || (iszWeaponModel = engfunc(EngFunc_AllocString, g_szModelView[P_HAND]))) set_pev_string(pPlayer, pev_weaponmodel2, iszWeaponModel);
	set_member(pPlayer, m_flNextAttack, 0.75);
	//}
}

jbe_set_baton_model(pPlayer) {
	static iszViewModel, iszWeaponModel;
	if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, g_szModelView[V_BATON]))) set_pev_string(pPlayer, pev_viewmodel2, iszViewModel);
	if(iszWeaponModel || (iszWeaponModel = engfunc(EngFunc_AllocString, g_szModelView[P_BATON]))) set_pev_string(pPlayer, pev_weaponmodel2, iszWeaponModel);
	set_member(pPlayer, m_flNextAttack, 0.75);
}

jbe_set_screwdriver_model(pPlayer) {
	static iszViewModel, iszWeaponModel;
	if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, "models/egoist/jb/shop/v_screwdriver.mdl"))) set_pev_string(pPlayer, pev_viewmodel2, iszViewModel);
	if(iszWeaponModel || (iszWeaponModel = engfunc(EngFunc_AllocString, "models/egoist/jb/shop/p_screwdriver.mdl"))) set_pev_string(pPlayer, pev_weaponmodel2, iszWeaponModel);
	set_member(pPlayer, m_flNextAttack, 0.9);
}

jbe_set_chainsaw_model(pPlayer) {
	static iszViewModel, iszWeaponModel;
	if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, "models/egoist/jb/shop/v_chainsaw.mdl"))) set_pev_string(pPlayer, pev_viewmodel2, iszViewModel);
	if(iszWeaponModel || (iszWeaponModel = engfunc(EngFunc_AllocString, "models/egoist/jb/shop/p_chainsaw.mdl"))) set_pev_string(pPlayer, pev_weaponmodel2, iszWeaponModel);
	set_member(pPlayer, m_flNextAttack, 3.0);
}

jbe_set_zm_prisoner_model(pPlayer) {
	static iszViewModel;
	if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, "models/egoist/jb/shop/v_zombie_prisoner.mdl"))) set_pev_string(pPlayer, pev_viewmodel2, iszViewModel);
	set_member(pPlayer, m_flNextAttack, 0.3);
}

public jbe_set_syringe_model(pPlayer) {
	static iszViewModel;
	if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, "models/egoist/jb/shop/v_syringe.mdl"))) set_pev_string(pPlayer, pev_viewmodel2, iszViewModel);
	UTIL_WeaponAnimation(pPlayer, 1);
	set_member(pPlayer, m_flNextAttack, 3.0);
}

public jbe_remove_syringe_model(pPlayer) {
	pPlayer -= TASK_REMOVE_SYRINGE;
	new iActiveItem = get_member(pPlayer, m_pActiveItem);
	if(iActiveItem > 0) ExecuteHamB(Ham_Item_Deploy, iActiveItem);
}

public jbe_zm_remove_syringe_model(pPlayer) {
	pPlayer -= TASK_REMOVE_SYRINGE;
	UTIL_ScreenFade(pPlayer, (1<<13), (1<<13), 0, 0, 0, 0, 255);
	new iActiveItem = get_member(pPlayer, m_pActiveItem);
	if(iActiveItem > 0) ExecuteHamB(Ham_Item_Deploy, iActiveItem);
}

public jbe_hook_think(pPlayer) {
	pPlayer -= TASK_HOOK_THINK;
	new Float:vecOrigin[3];
	get_entvar(pPlayer, var_origin, vecOrigin);
	new Float:vecVelocity[3];
	vecVelocity[0] = (g_vecHookOrigin[pPlayer][0] - vecOrigin[0]) * 3.0;
	vecVelocity[1] = (g_vecHookOrigin[pPlayer][1] - vecOrigin[1]) * 3.0;
	vecVelocity[2] = (g_vecHookOrigin[pPlayer][2] - vecOrigin[2]) * 3.0;
	
	new Float:flY = vecVelocity[0] * vecVelocity[0] + vecVelocity[1] * vecVelocity[1] + vecVelocity[2] * vecVelocity[2];
	new Float:flX = (5 * g_fHookSpeed[pPlayer]) / floatsqroot(flY);
	
	vecVelocity[0] *= flX;
	vecVelocity[1] *= flX;
	vecVelocity[2] *= flX;
	
	set_entvar(pPlayer, var_velocity, vecVelocity);
	switch(g_iStatusHook[pPlayer]) {
		case 1: CREATE_BEAMENTPOINT(pPlayer, g_vecHookOrigin[pPlayer], g_pSpriteLgtning[0], 0, 1, 1, 60, 30, random_num(30,255), random_num(30,255), random_num(30,255), 200, _);
		case 3: CREATE_BEAMENTPOINT(pPlayer, g_vecHookOrigin[pPlayer], g_pSpriteLgtning[1], 0, 1, 1, 60, 0, 255, 255, 255, 200, _);
		case 2: CREATE_BEAMENTPOINT(pPlayer, g_vecHookOrigin[pPlayer], g_pSpriteLgtning[2], 0, 1, 1, 60, 0, 255, 255, 255, 200, _);
		case 4: CREATE_BEAMENTPOINT(pPlayer, g_vecHookOrigin[pPlayer], g_pSpriteLgtning[3], 0, 1, 1, 60, 0, 255, 255, 255, 200, _);
	}
}
/*===== <- Остальной хлам <- =====*///}

/*===== -> Дуэль -> =====*///{
jbe_duel_start_ready(pPlayer, pTarget) {
	g_iDuelStatus = 1;
	for(new i; i <= 4; i++) {
		ClearBit(g_iBitUserGodBlock[i], pPlayer);
		ClearBit(g_iBitUserGodBlock[i], pTarget);
	}
	
	for(new id = 1; id <= MaxClients; id++) {
		if(IsSetBit(g_iBitUserAlive, id) && g_iUserTeam[id] == 2) rg_remove_all_items(id, false);
	}
	
	jbe_default_player_model(pPlayer);
	jbe_default_player_model(pTarget);
	
	rg_remove_all_items(pPlayer, false);
	
	g_iDuelUsersId[0] = pPlayer;
	g_iDuelUsersId[1] = pTarget;
	
	SetBit(g_iBitUserDuel, pPlayer);
	SetBit(g_iBitUserDuel, pTarget);
	
	// Фикс спавна при старте дуэли на карте Minecraft
	new iMap_Name[32], iMap_Prefix[][] = { "jail_xmf", "jail_despicable_fix", "jail_ak_idea_mini", "jb_sector_", "jb_prison_2k17", "jb_leyawiin", "jb_forever_bitch", "jb_blue_ae", "jb_satomi" };
	get_mapname(iMap_Name, charsmax(iMap_Name));
	for(new i; i < sizeof iMap_Prefix; i++) {
		if(containi(iMap_Name, iMap_Prefix[i]) != -1) {
			new Float:fOrigin[3];
			get_entvar(engfunc(EngFunc_FindEntityByString, 0, "classname", "info_player_start"), var_origin, fOrigin);
	
			set_entvar(pPlayer, var_origin, fOrigin);
	
			fOrigin[0] += 45.0;
			fOrigin[1] += 25.0;
			fOrigin[2] += 20.0;
	
			set_entvar(pTarget, var_origin, fOrigin);
		}
	}
	// Конец фикса
	set_task(1.0, "jbe_duel_time_to_kill", TASK_DUEL_TIME_TO_KILL, _, _, "a", g_iDuelTimeToKill = g_iAllCvars[DUEL_TIME_TO_KILL] + 1);
	
	if(rg_get_user_takedamage(pTarget)) rg_set_user_takedamage(pTarget, false);
	if(rg_get_user_takedamage(pPlayer)) rg_set_user_takedamage(pPlayer, false);
	
	if(rg_get_user_noclip(pTarget)) rg_set_user_noclip(pTarget, false);
	if(rg_get_user_noclip(pPlayer)) rg_set_user_noclip(pPlayer, false);
	
	get_user_name(pPlayer, g_iDuelNames[0], charsmax(g_iDuelNames[]));
	get_user_name(pTarget, g_iDuelNames[1], charsmax(g_iDuelNames[]));
	
	client_cmd(0, "mp3 play sound/egoist/jb/%s", g_szSound[UJBL_DUEL_SOUND]);
	
	for(new i; i < charsmax(g_iHamHookForwards); i++) EnableHamForward(g_iHamHookForwards[i]);
	set_task(1.0, "jbe_duel_count_down", TASK_DUEL_COUNT_DOWN, _, _, "a", g_iDuelCountDown = 20 + 1);
	rg_set_user_rendering(pPlayer, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 0);
	rg_get_user_rendering(pPlayer, g_eUserRendering[pPlayer][RENDER_FX], g_eUserRendering[pPlayer][RENDER_RED], g_eUserRendering[pPlayer][RENDER_GREEN], g_eUserRendering[pPlayer][RENDER_BLUE], g_eUserRendering[pPlayer][RENDER_MODE], g_eUserRendering[pPlayer][RENDER_AMT]);
	g_eUserRendering[pPlayer][RENDER_STATUS] = true;

	rg_set_user_rendering(pTarget, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 0);
	rg_get_user_rendering(pTarget, g_eUserRendering[pTarget][RENDER_FX], g_eUserRendering[pTarget][RENDER_RED], g_eUserRendering[pTarget][RENDER_GREEN], g_eUserRendering[pTarget][RENDER_BLUE], g_eUserRendering[pTarget][RENDER_MODE], g_eUserRendering[pTarget][RENDER_AMT]);
	g_eUserRendering[pTarget][RENDER_STATUS] = true;

	CREATE_PLAYERATTACHMENT(pPlayer, _, g_pSpriteDuelRed, 3000);
	CREATE_PLAYERATTACHMENT(pTarget, _, g_pSpriteDuelBlue, 3000);
	set_task(1.0, "jbe_duel_bream_cylinder", TASK_DUEL_BEAMCYLINDER, _, _, "b");
	
	if(IsSetBit(g_iBitUserConnected, g_iDuelPrizeID) && pTarget != g_iDuelPrizeID) {
		new szPrizeName[32], szIsExp[4];
		num_to_str(g_iAllCvars[DUEL_EXP_WINNER], szIsExp, charsmax(szIsExp));
		get_user_name(g_iDuelPrizeID, szPrizeName, charsmax(szPrizeName));
		client_print_color(0, print_team_blue, "^1[^4INFO^1] Заключенный играет на^4 %s %L ^1игроку^4 %s", g_iDuelPrize == 2 ? szIsExp:"", LANG_PLAYER, g_iDuelPrizeLang[g_iDuelPrize], szPrizeName);
	}
}

public jbe_duel_time_to_kill() {
	if(!--g_iDuelTimeToKill) {
		if(!random_num(0, 1)) ExecuteHamB(Ham_Killed, g_iDuelUsersId[0], g_iDuelUsersId[1], 0);
		else ExecuteHamB(Ham_Killed, g_iDuelUsersId[1], g_iDuelUsersId[0], 0);
	}
}

public jbe_duel_count_down() {
	if(--g_iDuelCountDown) {
		set_hudmessage(102, 69, 0, -1.0, 0.16, 0, 0.0, 0.9, 0.1, 0.1, -1);
		ShowSyncHudMsg(0, g_iSyncDuelInformer, "%L", LANG_PLAYER, "JBE_ALL_HUD_DUEL_START_READY", LANG_PLAYER, g_iDuelLang[g_iDuelType], g_iDuelNames[0], g_iDuelNames[1], g_iDuelCountDown, g_iAllCvars[DUEL_TIME_TO_KILL]);
	}
	else jbe_duel_start();
}

jbe_duel_start() {
	g_iDuelStatus = 2;
	switch(g_iDuelType) {
		case 1: {
			if(g_iAllCvars[DUEL_SOUND]) EnableHamForward(g_iHamHookDuelForwards[0]);
			g_iModeDuel = 1;
			rg_give_item(g_iDuelUsersId[0], "weapon_deagle", GT_REPLACE);
			rg_set_user_bpammo(g_iDuelUsersId[0], WEAPON_DEAGLE, 100);
			rg_set_user_health(g_iDuelUsersId[0], 100.0);
			rg_give_item(g_iDuelUsersId[0], "item_assaultsuit", GT_REPLACE);
			set_task(1.0, "jbe_duel_timer_attack", g_iDuelUsersId[0]+TASK_DUEL_TIMER_ATTACK, _, _, "a", g_iDuelTimerAttack = 11);
			rg_give_item(g_iDuelUsersId[1], "weapon_deagle", GT_REPLACE);
			rg_set_user_bpammo(g_iDuelUsersId[1], WEAPON_DEAGLE, 100);
			rg_set_user_health(g_iDuelUsersId[1], 100.0);
			rg_give_item(g_iDuelUsersId[1], "item_assaultsuit", GT_REPLACE);
			set_member(g_iDuelUsersId[1], m_flNextAttack, 11.0);
		}
		case 2: {
			if(g_iAllCvars[DUEL_SOUND]) EnableHamForward(g_iHamHookDuelForwards[1]);
			g_iModeDuel = 2;
			rg_give_item(g_iDuelUsersId[0], "weapon_m3", GT_REPLACE);
			rg_set_user_bpammo(g_iDuelUsersId[0], WEAPON_M3, 100);
			rg_set_user_health(g_iDuelUsersId[0], 100.0);
			rg_give_item(g_iDuelUsersId[0], "item_assaultsuit", GT_REPLACE);
			set_member(get_member(g_iDuelUsersId[0], m_pActiveItem), m_Weapon_flNextSecondaryAttack, get_gametime() + 11.0);
			set_task(1.0, "jbe_duel_timer_attack", g_iDuelUsersId[0]+TASK_DUEL_TIMER_ATTACK, _, _, "a", g_iDuelTimerAttack = 11);
			rg_give_item(g_iDuelUsersId[1], "weapon_m3", GT_REPLACE);
			rg_set_user_bpammo(g_iDuelUsersId[1], WEAPON_M3, 100);
			rg_set_user_health(g_iDuelUsersId[1], 100.0);
			rg_give_item(g_iDuelUsersId[1], "item_assaultsuit", GT_REPLACE);
			set_member(g_iDuelUsersId[1], m_flNextAttack, 11.0);
		}
		case 3: {
			g_iModeDuel = 3;
			rg_give_item(g_iDuelUsersId[0], "weapon_hegrenade", GT_REPLACE);
			rg_set_user_bpammo(g_iDuelUsersId[0], WEAPON_HEGRENADE, 100);
			rg_set_user_health(g_iDuelUsersId[0], 100.0);
			rg_give_item(g_iDuelUsersId[0], "item_assaultsuit", GT_REPLACE);
			rg_give_item(g_iDuelUsersId[1], "weapon_hegrenade", GT_REPLACE);
			rg_set_user_bpammo(g_iDuelUsersId[1], WEAPON_HEGRENADE, 100);
			rg_set_user_health(g_iDuelUsersId[1], 100.0);
			rg_give_item(g_iDuelUsersId[1], "item_assaultsuit", GT_REPLACE);
		}
		case 4: {
			g_iModeDuel = 4;
			rg_give_item(g_iDuelUsersId[0], "weapon_m249", GT_REPLACE);
			rg_set_user_bpammo(g_iDuelUsersId[0], WEAPON_M249, 200);
			rg_set_user_health(g_iDuelUsersId[0], 506.0);
			rg_give_item(g_iDuelUsersId[0], "item_assaultsuit", GT_REPLACE);
			rg_give_item(g_iDuelUsersId[1], "weapon_m249", GT_REPLACE);
			rg_set_user_bpammo(g_iDuelUsersId[1], WEAPON_M249, 200);
			rg_set_user_health(g_iDuelUsersId[1], 506.0);
			rg_give_item(g_iDuelUsersId[1], "item_assaultsuit", GT_REPLACE);
		}
		case 5: {
			if(g_iAllCvars[DUEL_SOUND]) EnableHamForward(g_iHamHookDuelForwards[2]);
			g_iModeDuel = 5;
			rg_give_item(g_iDuelUsersId[0], "weapon_awp", GT_REPLACE);
			rg_set_user_bpammo(g_iDuelUsersId[0], WEAPON_AWP, 100);
			rg_set_user_health(g_iDuelUsersId[0], 100.0);
			rg_give_item(g_iDuelUsersId[0], "item_assaultsuit", GT_REPLACE);
			set_member(get_member(g_iDuelUsersId[0], m_pActiveItem), m_Weapon_flNextSecondaryAttack, get_gametime() + 11.0);
			set_task(1.0, "jbe_duel_timer_attack", g_iDuelUsersId[0]+TASK_DUEL_TIMER_ATTACK, _, _, "a", g_iDuelTimerAttack = 11);
			rg_give_item(g_iDuelUsersId[1], "weapon_awp", GT_REPLACE);
			rg_set_user_bpammo(g_iDuelUsersId[1], WEAPON_AWP, 100);
			rg_set_user_health(g_iDuelUsersId[1], 100.0);
			rg_give_item(g_iDuelUsersId[1], "item_assaultsuit", GT_REPLACE);
			set_member(g_iDuelUsersId[1], m_flNextAttack, 11.0);
		}
		case 6: {
			g_iModeDuel = 6;
			rg_give_item(g_iDuelUsersId[0], "weapon_knife", GT_REPLACE);
			rg_set_user_health(g_iDuelUsersId[0], 150.0);
			rg_give_item(g_iDuelUsersId[0], "item_assaultsuit", GT_REPLACE);
			rg_give_item(g_iDuelUsersId[1], "weapon_knife", GT_REPLACE);
			rg_set_user_health(g_iDuelUsersId[1], 150.0);
			rg_give_item(g_iDuelUsersId[1], "item_assaultsuit", GT_REPLACE);
		}
	}
	for(new id = 0; id <= 1; id++) {
		rg_reset_maxspeed(g_iDuelUsersId[id]);
		rg_set_user_gravity(g_iDuelUsersId[id], 1.0);
	}
}

public jbe_duel_timer_attack(pPlayer) {
	if(--g_iDuelTimerAttack) {
		pPlayer -= TASK_DUEL_TIMER_ATTACK;
		set_hudmessage(102, 69, 0, -1.0, 0.16, 0, 0.0, 0.9, 0.1, 0.1, -1);
		ShowSyncHudMsg(0, g_iSyncDuelInformer, "%L", LANG_PLAYER, "JBE_ALL_HUD_DUEL_TIMER_ATTACK", pPlayer == g_iDuelUsersId[0] ? g_iDuelNames[0] : g_iDuelNames[1], g_iDuelTimerAttack, g_iDuelNames[0], Float:rg_get_user_health(g_iDuelUsersId[0]), Float:rg_get_user_health(g_iDuelUsersId[1]), g_iDuelNames[1], g_iDuelTimeToKill);
	}
	else {
		pPlayer -= TASK_DUEL_TIMER_ATTACK;
		new iActiveItem = get_member(pPlayer, m_pActiveItem);
		if(iActiveItem > 0) ExecuteHamB(Ham_Weapon_PrimaryAttack, iActiveItem);
	}
}

public jbe_duel_bream_cylinder() {
	new Float:vecOrigin[3];
	get_entvar(g_iDuelUsersId[0], var_origin, vecOrigin);
	if(get_entvar(g_iDuelUsersId[0], var_flags) & FL_DUCKING) vecOrigin[2] -= 15.0;
	else vecOrigin[2] -= 33.0;
	CREATE_BEAMCYLINDER(vecOrigin, 150, g_pSpriteWave, _, _, 5, 3, _, 255, 0, 0, 255, _);
	get_entvar(g_iDuelUsersId[1], var_origin, vecOrigin);
	if(get_entvar(g_iDuelUsersId[1], var_flags) & FL_DUCKING) vecOrigin[2] -= 15.0;
	else vecOrigin[2] -= 33.0;
	CREATE_BEAMCYLINDER(vecOrigin, 150, g_pSpriteWave, _, _, 5, 3, _, 0, 0, 255, 255, _);
}

jbe_duel_ended(pPlayer) {
	for(new i; i < charsmax(g_iHamHookForwards); i++) DisableHamForward(g_iHamHookForwards[i]);
	if(g_iAllCvars[DUEL_SOUND]) for(new i; i <= charsmax(g_iHamHookDuelForwards); i++) DisableHamForward(g_iHamHookDuelForwards[i]);
	
	if(task_exists(TASK_DUEL_TIME_TO_KILL)) remove_task(TASK_DUEL_TIME_TO_KILL);
	
	g_iBitUserDuel = 0;
	g_iModeDuel = 0;
	rg_set_user_rendering(g_iDuelUsersId[0], kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
	rg_set_user_rendering(g_iDuelUsersId[1], kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
	CREATE_KILLPLAYERATTACHMENTS(g_iDuelUsersId[0]);
	CREATE_KILLPLAYERATTACHMENTS(g_iDuelUsersId[1]);
	CREATE_KILLBEAM(g_iDuelUsersId[0]);
	CREATE_KILLBEAM(g_iDuelUsersId[1]);
	remove_task(TASK_DUEL_BEAMCYLINDER);
	if(task_exists(g_iDuelUsersId[0]+TASK_DUEL_TIMER_ATTACK)) remove_task(g_iDuelUsersId[0]+TASK_DUEL_TIMER_ATTACK);
	if(task_exists(g_iDuelUsersId[1]+TASK_DUEL_TIMER_ATTACK)) remove_task(g_iDuelUsersId[1]+TASK_DUEL_TIMER_ATTACK);
	new iPlayer = g_iDuelUsersId[0] != pPlayer ? g_iDuelUsersId[0] : g_iDuelUsersId[1];
	rg_reset_maxspeed(iPlayer);
	rg_remove_all_items(iPlayer, false);
	rg_give_item(iPlayer, "weapon_knife", GT_APPEND);
	switch(g_iDuelStatus) {
		case 1: {
			if(task_exists(TASK_DUEL_COUNT_DOWN)) {
				remove_task(TASK_DUEL_COUNT_DOWN);
				client_cmd(0, "mp3 stop");
			}
		}
		case 2: {
			new szIsExp[4];
			num_to_str(g_iAllCvars[DUEL_EXP_WINNER], szIsExp, charsmax(szIsExp));
			if(g_iUserTeam[iPlayer] == 1 && IsSetBit(g_iBitUserConnected, g_iDuelPrizeID)) {
				switch(g_iDuelPrize) {
					case 1: if(g_iUserTeam[g_iDuelPrizeID] == 1) jbe_add_user_free_next_round(g_iDuelPrizeID);
					case 2:  {
						g_iUserExp[g_iDuelPrizeID] = g_iUserExp[g_iDuelPrizeID] + g_iAllCvars[DUEL_EXP_WINNER];
						if(g_iUserExp[g_iDuelPrizeID] >= g_iUserNextExp[g_iDuelPrizeID]) jbe_forse_lvl(g_iDuelPrizeID);
					}
					case 3: jbe_set_user_money(g_iDuelPrizeID, jbe_get_user_money(g_iDuelPrizeID) + 300, true);
					case 4: if(g_iUserTeam[g_iDuelPrizeID] == 1) jbe_set_user_voice_next_round(g_iDuelPrizeID);
					default: jbe_set_user_money(iPlayer, jbe_get_user_money(iPlayer) + 300, true);
				}
				new szPrizeName[32];
				get_user_name(g_iDuelPrizeID, szPrizeName, charsmax(szPrizeName));
				client_print_color(0, print_team_blue, "^1[^4INFO^1] Игрок^4 %s ^1получил^3 %s %L^1.", szPrizeName, g_iDuelPrize == 2 ? szIsExp : "", LANG_PLAYER, g_iDuelPrizeLang[g_iDuelPrize]);
			}
			else if(g_iUserTeam[iPlayer] == 1) {// Если победитель дуэли заключённый и вышел тот, кому идёт награда
				switch(g_iDuelPrize) {
					case 1: if(g_iUserTeam[iPlayer] == 1) jbe_add_user_free_next_round(iPlayer);
					case 2:  {
						g_iUserExp[iPlayer] = g_iUserExp[iPlayer] + g_iAllCvars[DUEL_EXP_WINNER];
						if(g_iUserExp[iPlayer] >= g_iUserNextExp[iPlayer]) jbe_forse_lvl(iPlayer);
					}
					case 3: jbe_set_user_money(iPlayer, jbe_get_user_money(iPlayer) + 300, true);
					case 4: if(g_iUserTeam[iPlayer] == 1) jbe_set_user_voice_next_round(iPlayer);
					default: jbe_set_user_money(iPlayer, jbe_get_user_money(iPlayer) + 300, true);
				}
				new szPrizeName[32];
				get_user_name(iPlayer, szPrizeName, charsmax(szPrizeName));
				client_print_color(0, print_team_blue, "^1[^4INFO^1] Игрок^4 %s ^1получил^4 %s %L^1. По причине: ^4Кому посвящена дуэль - вышел^1.", szPrizeName, g_iDuelPrize == 2 ? szIsExp : "", LANG_PLAYER, g_iDuelPrizeLang[g_iDuelPrize]);
			}
			else if(g_iUserTeam[iPlayer] == 2) {// Если заключённый проиграл.
				switch(g_iDuelPrize) {
					case 2:  {
						g_iUserExp[iPlayer] = g_iUserExp[iPlayer] + g_iAllCvars[DUEL_EXP_WINNER];
						if(g_iUserExp[iPlayer] >= g_iUserNextExp[iPlayer]) jbe_forse_lvl(iPlayer);
					}
					case 3: jbe_set_user_money(iPlayer, jbe_get_user_money(iPlayer) + 300, true);
					default: jbe_set_user_money(iPlayer, jbe_get_user_money(iPlayer) + 300, true);
				}
				client_print_color(0, print_team_blue, "^1[^4INFO^1] Игрок проиграл дуэль. Награда, если она возможна, идёт охраннику.");
			}
		}
		
	}
	g_iDuelPrizeID = 0;
	g_iDuelPrize = 0;
	g_iDuelStatus = 0;
	g_iDuelUsersId[0] = 0;
	g_iDuelUsersId[1] = 0;
}
/*===== -> Дуэль -> =====*///}

/*===== -> Футбол -> =====*///{
jbe_soccer_disable_all() {
	jbe_soccer_remove_ball();
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) {
		if(IsSetBit(g_iBitUserSoccer, iPlayer)) {
			ClearBit(g_iBitUserSoccer, iPlayer);
			if(IsSetBit(g_iBitClothingGuard, iPlayer) && IsSetBit(g_iBitClothingType, iPlayer)) jbe_set_user_model(iPlayer, g_szPlayerModel[GUARD]);
			else jbe_default_player_model(iPlayer);
			set_member(iPlayer, m_bloodColor, 247);
			new iActiveItem = get_member(iPlayer, m_pActiveItem);
			if(iActiveItem > 0) {
				ExecuteHamB(Ham_Item_Deploy, iActiveItem);
				UTIL_WeaponAnimation(iPlayer, 3);
			}
			if(bIsSetmodBit(g_bSoccerGame)) remove_task(iPlayer+TASK_SHOW_SOCCER_SCORE);
		}
	}
	if(bIsSetmodBit(g_bSoccerGame)) {
		rh_emit_sound2(0, 0, CHAN_STATIC, "egoist/jb/soccer/crowd.wav", VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);
		if(g_iChiefStatus == 1) remove_task(g_iChiefId+TASK_SHOW_SOCCER_SCORE);
	}
	g_iSoccerScore = {0, 0};
	bClearModBit(g_bSoccerGame);
	bClearModBit(g_bSoccerStatus);
}

jbe_soccer_create_ball(pPlayer) {
	if(g_iSoccerBall) return g_iSoccerBall;
	static iszFuncWall = 0;
	if(iszFuncWall || (iszFuncWall = engfunc(EngFunc_AllocString, "func_wall"))) g_iSoccerBall = engfunc(EngFunc_CreateNamedEntity, iszFuncWall);
	if(is_entity(g_iSoccerBall)) {
		rg_set_user_rendering(g_iSoccerBall, kRenderFxGlowShell, random_num(0,255), random_num(0,255), random_num(0,255), kRenderNormal, 4);
		set_entvar(g_iSoccerBall, var_classname, "ball");
		set_entvar(g_iSoccerBall, var_solid, SOLID_TRIGGER);
		set_entvar(g_iSoccerBall, var_movetype, MOVETYPE_BOUNCE);
		engfunc(EngFunc_SetModel, g_iSoccerBall, g_szModelView[SOCCER_BALL]);
		set_entvar(g_iSoccerBall, var_size, Float:{-4.0, -4.0, -4.0}, Float:{4.0, 4.0, 4.0});
		set_entvar(g_iSoccerBall, var_framerate, 1.0);
		set_entvar(g_iSoccerBall, var_sequence, 0);
		set_entvar(g_iSoccerBall, var_nextthink, get_gametime() + 0.04);
		fm_get_aiming_position(pPlayer, g_flSoccerBallOrigin);
		engfunc(EngFunc_SetOrigin, g_iSoccerBall, g_flSoccerBallOrigin);
		engfunc(EngFunc_DropToFloor, g_iSoccerBall);
		return g_iSoccerBall;
	}
	jbe_soccer_remove_ball();
	return 0;
}

jbe_soccer_remove_ball() {
	if(g_iSoccerBall) {
		if(bIsSetmodBit(g_bSoccerBallTrail)) {
			bClearModBit(g_bSoccerBallTrail);
			CREATE_KILLBEAM(g_iSoccerBall);
		}
		if(g_iSoccerBallOwner) {
			CREATE_KILLPLAYERATTACHMENTS(g_iSoccerBallOwner);
			jbe_set_hand_model(g_iSoccerBallOwner);
		}
		if(is_entity(g_iSoccerBall)) engfunc(EngFunc_RemoveEntity, g_iSoccerBall);
		g_iSoccerBall = 0;
		g_iSoccerBallOwner = 0;
		g_iSoccerKickOwner = 0;
		bClearModBit(g_bSoccerBallTouch);
	}
}

jbe_soccer_update_ball() {
	if(g_iSoccerBall) {
		if(is_entity(g_iSoccerBall)) {
			if(bIsSetmodBit(g_bSoccerBallTrail)) {
				bSetModBit(g_bSoccerBallTrail);
				CREATE_KILLBEAM(g_iSoccerBall);
			}
			if(g_iSoccerBallOwner) {
				CREATE_KILLPLAYERATTACHMENTS(g_iSoccerBallOwner);
				jbe_set_hand_model(g_iSoccerBallOwner);
			}
			set_entvar(g_iSoccerBall, var_velocity, {0.0, 0.0, 0.0});
			set_entvar(g_iSoccerBall, var_solid, SOLID_TRIGGER);
			engfunc(EngFunc_SetModel, g_iSoccerBall, g_szModelView[SOCCER_BALL]);
			set_entvar(g_iSoccerBall, var_size, Float:{-4.0, -4.0, -4.0}, Float:{4.0, 4.0, 4.0});
			set_entvar(g_iSoccerBall, var_origin, g_flSoccerBallOrigin);
			engfunc(EngFunc_DropToFloor, g_iSoccerBall);
			g_iSoccerBallOwner = 0;
			g_iSoccerKickOwner = 0;
			bClearModBit(g_bSoccerBallTouch);
		}
		else jbe_soccer_remove_ball();
	}
}

jbe_soccer_game_start(pPlayer) {
	new iPlayers;
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) {
		if(IsSetBit(g_iBitUserSoccer, iPlayer)) iPlayers++;
	}
	if(iPlayers < 2) client_print_color(pPlayer, print_team_default, "^1[^4INFO^1] %L", pPlayer, "JBE_CHAT_ID_SOCCER_INSUFFICIENTLY_PLAYERS");
	else {
		for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) {
			if(IsSetBit(g_iBitUserSoccer, iPlayer) || iPlayer == g_iChiefId) set_task(1.0, "jbe_soccer_score_informer", iPlayer+TASK_SHOW_SOCCER_SCORE, _, _, "b");
		}
		rh_emit_sound2(pPlayer, 0, CHAN_AUTO, "egoist/jb/soccer/whitle_start.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		rh_emit_sound2(0, pPlayer, CHAN_STATIC, "egoist/jb/soccer/crowd.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		bSetModBit(g_bSoccerBallTouch);
		bSetModBit(g_bSoccerGame);
	}
}

jbe_soccer_game_end(pPlayer) {
	jbe_soccer_remove_ball();
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) {
		if(IsSetBit(g_iBitUserSoccer, iPlayer)) {
			ClearBit(g_iBitUserSoccer, iPlayer);
			if(IsSetBit(g_iBitClothingGuard, iPlayer) && IsSetBit(g_iBitClothingType, iPlayer)) jbe_set_user_model(pPlayer, g_szPlayerModel[GUARD]);
			else jbe_default_player_model(iPlayer);
			set_member(iPlayer, m_bloodColor, 247);
			new iActiveItem = get_member(iPlayer, m_pActiveItem);
			if(iActiveItem > 0) {
				ExecuteHamB(Ham_Item_Deploy, iActiveItem);
				UTIL_WeaponAnimation(iPlayer, 3);
			}
			remove_task(iPlayer+TASK_SHOW_SOCCER_SCORE);
		}
	}
	remove_task(pPlayer+TASK_SHOW_SOCCER_SCORE);
	rh_emit_sound2(0, pPlayer, CHAN_STATIC, "egoist/jb/soccer/crowd.wav", VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);
	rh_emit_sound2(pPlayer, pPlayer, CHAN_AUTO, "egoist/jb/soccer/whitle_end.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	g_iSoccerScore = {0, 0};
	bClearModBit(g_bSoccerGame);
}

jbe_soccer_divide_team(iType) {
	new const szLangPlayer[][] = {"JBE_HUD_ID_YOU_TEAM_RED", "JBE_HUD_ID_YOU_TEAM_BLUE"};
	for(new iPlayer = 1, iTeam; iPlayer <= MaxClients; iPlayer++) {
		if(IsSetBit(g_iBitUserAlive, iPlayer) && IsNotSetBit(g_iBitUserSoccer, iPlayer) && IsNotSetBit(g_iBitUserDuel, iPlayer)
		&& (g_iUserTeam[iPlayer] == 1 && IsNotSetBit(g_iBitUserFree, iPlayer) && IsNotSetBit(g_iBitUserWanted, iPlayer)
		&& IsNotSetBit(g_iBitUserBoxing, iPlayer) || !iType && g_iUserTeam[iPlayer] == 2 && iPlayer != g_iChiefId)) {
			SetBit(g_iBitUserSoccer, iPlayer);
			jbe_set_user_model(iPlayer, g_szPlayerModel[FOOTBALLER]);
			set_entvar(iPlayer, var_skin, iTeam);
			set_member(iPlayer, m_bloodColor, -1);
			client_print_color(iPlayer, print_team_default, "^1[^4INFO^1] %L", iPlayer, szLangPlayer[iTeam]);
			g_iSoccerUserTeam[iPlayer] = iTeam;
			if(get_user_weapon(iPlayer) != CSW_KNIFE) rg_internal_cmd(iPlayer, "weapon_knife");
			else {
				new iActiveItem = get_member(iPlayer, m_pActiveItem);
				if(iActiveItem > 0) {
					ExecuteHamB(Ham_Item_Deploy, iActiveItem);
					UTIL_WeaponAnimation(iPlayer, 3);
				}
			}
			iTeam = !iTeam;
		}
	}
}

public jbe_soccer_score_informer(pPlayer) {
	pPlayer -= TASK_SHOW_SOCCER_SCORE;
	set_hudmessage(102, 69, 0, -1.0, 0.01, 0, 0.0, 0.9, 0.1, 0.1, -1);
	ShowSyncHudMsg(pPlayer, g_iSyncSoccerScore, "%L %d | %d %L", pPlayer, "JBE_HUD_ID_SOCCER_SCORE_RED",
	g_iSoccerScore[0], g_iSoccerScore[1], pPlayer, "JBE_HUD_ID_SOCCER_SCORE_BLUE");
}

jbe_soccer_hand_ball_model(pPlayer) {
	static iszViewModel, iszWeaponModel;
	if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, "models/egoist/jb/soccer/v_hand_ball.mdl"))) set_pev_string(pPlayer, pev_viewmodel2, iszViewModel);
	if(iszWeaponModel || (iszWeaponModel = engfunc(EngFunc_AllocString, g_szModelView[P_HAND]))) set_pev_string(pPlayer, pev_weaponmodel2, iszWeaponModel);
}
/*===== <- Футбол <- =====*///}

/*===== -> Бокс -> =====*///{
jbe_boxing_disable_all() {
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) {
		if(IsSetBit(g_iBitUserBoxing, iPlayer)) {
			ClearBit(g_iBitUserBoxing, iPlayer);
			set_member(iPlayer, m_bloodColor, 247);
			new iActiveItem = get_member(iPlayer, m_pActiveItem);
			if(iActiveItem > 0) {
				ExecuteHamB(Ham_Item_Deploy, iActiveItem);
				UTIL_WeaponAnimation(iPlayer, 3);
			}
		}
	}
	g_iBoxingGame = 0;
	bClearModBit(g_bBoxingStatus);
	unregister_forward(FM_UpdateClientData, g_iFakeMetaUpdateClientData, 1);
}

jbe_boxing_game_start(pPlayer) {
	new iPlayers;
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) {
		if(IsSetBit(g_iBitUserBoxing, iPlayer)) iPlayers++;
	}
	if(iPlayers < 2) client_print_color(pPlayer, print_team_default, "^1[^4INFO^1] %L", pPlayer, "JBE_CHAT_ID_BOXING_INSUFFICIENTLY_PLAYERS");
	else {
		g_iBoxingGame = 1;
		rh_emit_sound2(pPlayer, pPlayer, CHAN_AUTO, "egoist/jb/boxing/gong.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
}

jbe_boxing_game_team_start(pPlayer) {
	new iPlayersRed, iPlayersBlue;
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) {
		if(IsSetBit(g_iBitUserBoxing, iPlayer)) {
			switch(g_iBoxingUserTeam[iPlayer]) {
				case 0: iPlayersRed++;
				case 1: iPlayersBlue++;
			}
		}
	}
	if(iPlayersRed < 2 || iPlayersBlue < 2) client_print_color(pPlayer, print_team_default, "^1[^4INFO^1] %L", pPlayer, "JBE_CHAT_ID_BOXING_INSUFFICIENTLY_PLAYERS");
	else {
		g_iBoxingGame = 2;
		rh_emit_sound2(pPlayer, pPlayer, CHAN_AUTO, "egoist/jb/boxing/gong.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
}

jbe_boxing_game_end() {
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) {
		if(IsSetBit(g_iBitUserBoxing, iPlayer)) {
			ClearBit(g_iBitUserBoxing, iPlayer);
			set_member(iPlayer, m_bloodColor, 247);
			new iActiveItem = get_member(iPlayer, m_pActiveItem);
			if(iActiveItem > 0) {
				ExecuteHamB(Ham_Item_Deploy, iActiveItem);
				UTIL_WeaponAnimation(iPlayer, 3);
			}
		}
	}
	g_iBoxingGame = 0;
}

jbe_boxing_divide_team() {
	for(new iPlayer = 1, iTeam; iPlayer <= MaxClients; iPlayer++) {
		if(g_iUserTeam[iPlayer] == 1 && IsSetBit(g_iBitUserAlive, iPlayer) && IsNotSetBit(g_iBitUserFree, iPlayer)
		&& IsNotSetBit(g_iBitUserWanted, iPlayer) && IsNotSetBit(g_iBitUserSoccer, iPlayer)
		&& IsNotSetBit(g_iBitUserBoxing, iPlayer) && IsNotSetBit(g_iBitUserDuel, iPlayer)) {
			SetBit(g_iBitUserBoxing, iPlayer);
			rg_set_user_health(iPlayer, 100.0);
			set_member(iPlayer, m_bloodColor, -1);
			g_iBoxingUserTeam[iPlayer] = iTeam;
			if(get_user_weapon(iPlayer) != CSW_KNIFE) rg_internal_cmd(iPlayer, "weapon_knife");
			else {
				new iActiveItem = get_member(iPlayer, m_pActiveItem);
				if(iActiveItem > 0) {
					ExecuteHamB(Ham_Item_Deploy, iActiveItem);
					UTIL_WeaponAnimation(iPlayer, 3);
				}
			}
			iTeam = !iTeam;
		}
	}
}

jbe_boxing_gloves_model(pPlayer, iTeam) {
	switch(iTeam) {
		case 0: {
			static iszViewModel, iszWeaponModel;
			if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, "models/egoist/jb/boxing/v_boxing_gloves_red.mdl"))) set_pev_string(pPlayer, pev_viewmodel2, iszViewModel);
			if(iszWeaponModel || (iszWeaponModel = engfunc(EngFunc_AllocString, "models/egoist/jb/boxing/p_boxing_gloves_red.mdl"))) set_pev_string(pPlayer, pev_weaponmodel2, iszWeaponModel);
		}
		case 1: {
			static iszViewModel, iszWeaponModel;
			if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, "models/egoist/jb/boxing/v_boxing_gloves_blue.mdl"))) set_pev_string(pPlayer, pev_viewmodel2, iszViewModel);
			if(iszWeaponModel || (iszWeaponModel = engfunc(EngFunc_AllocString, "models/egoist/jb/boxing/p_boxing_gloves_blue.mdl"))) set_pev_string(pPlayer, pev_weaponmodel2, iszWeaponModel);
		}
	}
}
/*===== <- Бокс <- =====*///}

/*===== -> Нативы -> =====*///{
public plugin_natives()  {
	register_library("jbe_engine");
	
	register_native("set_trader_money", "_set_trader_money", 1);
	register_native("get_trader_money", "_get_trader_money", 1);

	register_native("jbe_informer_status", "jbe_informer_status", 1);

	register_native("jbe_is_exp_load", "jbe_is_exp_load", 1);
	
	register_native("jbe_is_user_alive", "jbe_is_user_alive", 1);
	register_native("jbe_is_user_connected", "jbe_is_user_connected", 1);
	register_native("jbe_is_user_hook", "jbe_is_user_hook", 1);
	register_native("jbe_setbit_vip", "jbe_setbit_vip", 1);
	register_native("jbe_setbit_hook", "jbe_setbit_hook", 1);
	register_native("jbe_resetsetbit_vip", "jbe_resetsetbit_vip", 1);
	register_native("jbe_resetbit_hook", "jbe_resetbit_hook", 1);
	register_native("jbe_set_user_exp_rank", "jbe_set_user_exp_rank", 1);
	register_native("jbe_get_privileges_flags", "jbe_get_privileges_flags", 1);
	register_native("jbe_get_user_lvl_rank", "jbe_get_user_lvl", 1);
	register_native("jbe_get_user_rank_name", "get_user_rank_name", 0);
	register_native("jbe_get_status_duel", "jbe_get_status_duel", 1);
	register_native("jbe_get_mode_duel", "jbe_get_mode_duel", 1);
	register_native("jbe_use_drugs_model", "jbe_set_syringe_model", 1);
	register_native("jbe_return_drugs_model", "jbe_remove_syringe_model", 1);
	register_native("jbe_all_users_wanted", "jbe_all_users_wanted", 1);
	register_native("jbe_all_users_freeday", "jbe_all_users_freeday", 1);
	register_native("jbe_get_day", "jbe_get_day", 1);
	register_native("jbe_set_day", "jbe_set_day", 1);
	register_native("jbe_get_day_week", "jbe_get_day_week", 1);
	register_native("jbe_set_day_week", "jbe_set_day_week", 1);
	register_native("jbe_get_day_mode", "jbe_get_day_mode", 1);
	register_native("jbe_set_day_mode", "jbe_set_day_mode", 1);
	register_native("jbe_open_doors", "jbe_open_doors", 1);
	register_native("jbe_close_doors", "jbe_close_doors", 1);
	register_native("jbe_get_user_money", "jbe_get_user_money", 1);
	register_native("jbe_set_user_money", "jbe_set_user_money", 1);
	
	register_native("jbe_get_user_team", "jbe_get_user_team", 1);
	register_native("jbe_set_user_team", "jbe_set_user_team", 1);
	
	register_native("jbe_get_user_model", "_jbe_get_user_model", 1);
	register_native("jbe_set_user_model", "_jbe_set_user_model", 1);
	
	register_native("jbe_informer_offset_up", "jbe_informer_offset_up", 1);
	register_native("jbe_informer_offset_down", "jbe_informer_offset_down", 1);
	register_native("jbe_menu_block", "jbe_menu_block", 1);
	register_native("jbe_menu_unblock", "jbe_menu_unblock", 1);
	register_native("jbe_menu_blocked", "jbe_menu_blocked", 1);
	register_native("jbe_is_user_free", "jbe_is_user_free", 1);
	register_native("jbe_add_user_free", "jbe_add_user_free", 1);
	register_native("jbe_add_user_free_next_round", "jbe_add_user_free_next_round", 1);
	register_native("jbe_sub_user_free", "jbe_sub_user_free", 1);
	register_native("jbe_free_day_start", "jbe_free_day_start", 1);
	register_native("jbe_free_day_ended", "jbe_free_day_ended", 1);
	register_native("jbe_is_user_wanted", "jbe_is_user_wanted", 1);
	register_native("jbe_add_user_wanted", "jbe_add_user_wanted", 1);
	register_native("jbe_sub_user_wanted", "jbe_sub_user_wanted", 1);
	register_native("jbe_is_user_chief", "jbe_is_user_chief", 1);
	register_native("jbe_set_user_chief", "jbe_set_user_chief", 1);
	register_native("jbe_get_chief_status", "jbe_get_chief_status", 1);
	register_native("jbe_get_chief_id", "jbe_get_chief_id", 1);
	register_native("jbe_set_user_costumes", "jbe_set_user_costumes", 1);
	register_native("jbe_get_user_costumes", "jbe_get_user_costumes", 1);
	register_native("jbe_hide_user_costumes", "jbe_hide_user_costumes", 1);
	register_native("jbe_prisoners_divide_color", "jbe_prisoners_divide_color", 1);
	register_native("jbe_register_day_mode", "jbe_register_day_mode", 1);
	register_native("jbe_get_user_voice", "jbe_get_user_voice", 1);
	register_native("jbe_set_user_voice", "jbe_set_user_voice", 1);
	register_native("jbe_set_user_voice_next_round", "jbe_set_user_voice_next_round", 1);
	
	register_native("Open_BlockGuardMenu", "Show_BlockedGuardMenu", 1);
	register_native("Open_VoiceMenu", "Show_VoiceControlMenu", 1);
}

public set_user_next_exp(const id) {
	new aDataArmy[ARMY_SYSTEM], iLvl = g_iUserLevel[id] + 1, iMaxLevel = g_iArmyList - 1;
	
	if(iLvl >= iMaxLevel)  {
		ArrayGetArray(g_aDataArmy, iMaxLevel, aDataArmy);
		g_iUserNextExp[id] = aDataArmy[ARMY_EXP];
		return;
	}
	
	ArrayGetArray(g_aDataArmy, iLvl, aDataArmy);	
	g_iUserNextExp[id] = (aDataArmy[ARMY_EXP]);
}

public jbe_set_user_exp(id, iExp) {
	if(bIsSetmodBit(g_bFixExp)) return PLUGIN_HANDLED;
	
	g_iUserExp[id] = (iExp > g_iMaxExp ? g_iMaxExp : iExp);
	
	new iCurrentLevel = jbe_get_user_level(id);
	if(g_iUserLevel[id] != iCurrentLevel) jbe_set_user_level(id, iCurrentLevel);
	return PLUGIN_HANDLED;
}

public _set_trader_money(iNum, iType) {
	switch(iType) {
		case 0: g_iTraderMoney -= iNum;
		case 1: g_iTraderMoney += iNum;
		case 2: g_iTraderMoney = 0;
	}
}
public _get_trader_money() return g_iTraderMoney; 

public jbe_informer_status(id, bool: bStatus) {
	g_iInformerStatus[id] = bStatus;
	switch(g_iInformerStatus[id]) 
	{
		case true: remove_task(id + TASK_SHOW_INFORMER);
		case false: set_task(INFORMER_SECOND_UPDATE, "jbe_team_informer", id + TASK_SHOW_INFORMER, _, _, "b");
	}
}

public jbe_is_exp_load() return bIsSetmodBit(g_bFixExp);
public jbe_is_user_alive(id) return IsSetBit(g_iBitUserAlive, id);
public jbe_is_user_connected(id) return IsSetBit(g_iBitUserConnected, id);

public get_user_rank_name() {
	new id = get_param(1);
	new iLen = get_param(3);

	set_string(2, g_szRankName[id], iLen);
	return 1;
}

public jbe_is_user_hook(id) return IsSetBit(g_iBitUserHook, id);
public jbe_resetbit_hook(id) ClearBit(g_iBitUserHook, id);

public jbe_resetsetbit_vip(id) {
	if(IsNotSetBit(g_iBitUserVip, id)) return false;
	else ClearBit(g_iBitUserVip, id);
	return true;
}

public jbe_setbit_vip(id) {
	if(IsSetBit(g_iBitUserVip, id)) return false;
	else SetBit(g_iBitUserVip, id);
	return true;
}

public jbe_setbit_hook(id) SetBit(g_iBitUserHook, id);

public jbe_set_user_exp_rank(id, iExp, iType) {
	switch(iType) {
		case 0: jbe_set_user_exp(id, g_iUserExp[id] + iExp);
		case 1: jbe_set_user_exp(id, g_iUserExp[id] - iExp);
		default: jbe_set_user_exp(id, g_iUserExp[id] + iExp);
	}
}

public bool:jbe_all_users_wanted() {
	if(g_szWantedNames[0] <= 0) return false;
	return true;
}

public bool:jbe_all_users_freeday() {
	if(g_szFreeNames[0] <= 0) return false;
	return true;
}

public jbe_get_privileges_flags(id) {
	new iBit;
	
	if(IsSetBit(g_iBitUserGodMenu, id)) iBit |= (1<<1);
	if(IsSetBit(g_iBitUserGod, id)) iBit |= (1<<2);
	if(IsSetBit(g_iBitUserCreater, id)) iBit |= (1<<3);
	if(IsSetBit(g_iBitUserKnyaz, id)) iBit |= (1<<4);
	if(IsSetBit(g_iBitUserSuperAdmin, id)) iBit |= (1<<5);
	if(IsSetBit(g_iBitUserAdmin, id)) iBit |= (1<<6);
	if(IsSetBit(g_iBitUserVip, id)) iBit |= (1<<7);
	if(IsSetBit(g_iBitUserHook, id)) iBit |= (1<<8);
	
	if(~iBit & (1<<7) && ~iBit & (1<<6) && ~iBit & (1<<3) && ~iBit & (1<<8)) iBit |= (1<<0);
	
	return iBit;
}

public jbe_get_mode_duel() return g_iModeDuel;
public jbe_get_user_lvl(id) return g_iUserLevel[id];
public jbe_get_status_duel() return g_iDuelStatus;

public jbe_get_day() return g_iDay;
public jbe_set_day(iDay) g_iDay = iDay;

public jbe_get_day_week() return g_iDayWeek;
public jbe_set_day_week(iWeek) g_iDayWeek = (g_iDayWeek > 7) ? 1 : iWeek;

public jbe_get_day_mode() return g_iDayMode;
public jbe_set_day_mode(iMode) {
	g_iDayMode = iMode;
	formatex(g_szDayMode, charsmax(g_szDayMode), "JBE_HUD_GAME_MODE_%d", g_iDayMode);
}

public jbe_open_doors() {
	for(new i, iDoor; i < g_iDoorListSize; i++) {
		iDoor = ArrayGetCell(g_aDoorList, i);
		dllfunc(DLLFunc_Use, iDoor, 0);
	}
	bSetModBit(g_bDoorStatus);
}

public jbe_close_doors() {
	for(new i, iDoor; i < g_iDoorListSize; i++) {
		iDoor = ArrayGetCell(g_aDoorList, i);
		dllfunc(DLLFunc_Think, iDoor);
	}
	bClearModBit(g_bDoorStatus);
}

public jbe_get_user_team(pPlayer) {
	if(IsNotSetBit(g_iBitUserConnected, pPlayer)) return 0;
	return g_iUserTeam[pPlayer];
}

public jbe_set_user_team(pPlayer, iTeam) {
	if(IsNotSetBit(g_iBitUserConnected, pPlayer)) return 0;
	switch(iTeam) {
		case 1: {
			set_member(pPlayer, m_bTeamChanged, false);
			set_member(pPlayer, m_iNumSpawns, 1);
			if(IsSetBit(g_iBitUserAlive, pPlayer)) ExecuteHamB(Ham_Killed, pPlayer, pPlayer, 0);
			g_iPlayersNum[g_iUserTeam[pPlayer]]--;
			if(get_user_flags(pPlayer) & ADMIN_BAN) g_iUserSkin[pPlayer] = 4;
			else g_iUserSkin[pPlayer] = random_num(0, 3);
			rg_join_team(pPlayer, TEAM_TERRORIST);
			g_iUserTeam[pPlayer] = 1;
			jbe_menu_unblock(pPlayer);
			g_iPlayersNum[g_iUserTeam[pPlayer]]++;
			//Show_SkinMenu(pPlayer);
			
			new aDataArmy[ARMY_SYSTEM];
			ArrayGetArray(g_aDataArmy, g_iUserLevel[pPlayer], aDataArmy);
			if(!equal(g_szRankName[pPlayer], aDataArmy[ARMY_NAME_PRISONER])) format(g_szRankName[pPlayer], charsmax(g_szRankName[]), "%s", aDataArmy[ARMY_NAME_PRISONER]);
		}
		case 2: {
			set_member(pPlayer, m_bTeamChanged, false);
			set_member(pPlayer, m_iNumSpawns, 1);
			if(IsSetBit(g_iBitUserAlive, pPlayer)) ExecuteHamB(Ham_Killed, pPlayer, pPlayer, 0);
			g_iPlayersNum[g_iUserTeam[pPlayer]]--;
			rg_join_team(pPlayer, TEAM_CT);
			g_iUserTeam[pPlayer] = 2;
			g_iPlayersNum[g_iUserTeam[pPlayer]]++;
			
			new aDataArmy[ARMY_SYSTEM];
			ArrayGetArray(g_aDataArmy, g_iUserLevel[pPlayer], aDataArmy);
			if(!equal(g_szRankName[pPlayer], aDataArmy[ARMY_NAME_GUARD])) format(g_szRankName[pPlayer], charsmax(g_szRankName[]), "%s", aDataArmy[ARMY_NAME_GUARD]);
		}
		case 3: {
			if(IsSetBit(g_iBitUserAlive, pPlayer)) ExecuteHamB(Ham_Killed, pPlayer, pPlayer, 0);
			g_iPlayersNum[g_iUserTeam[pPlayer]]--;
			rg_join_team(pPlayer, TEAM_SPECTATOR);
			g_iUserTeam[pPlayer] = 3;
			g_iPlayersNum[g_iUserTeam[pPlayer]]++;
			g_szRankName[pPlayer] = "Наблюдатель";
		}
	}
	return iTeam;
}

public _jbe_get_user_model(pPlayer, const szModel[], iLen) {
	param_convert(2);
	return jbe_get_user_model(pPlayer, szModel, iLen);
}

public jbe_get_user_model(pPlayer, const szModel[], iLen) return engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, pPlayer), "model", szModel, iLen);

public _jbe_set_user_model(pPlayer, const szModel[]) {
	param_convert(2);
	
	if(equal(g_szUserModel[pPlayer], szModel)) return false;
	
	jbe_set_user_model(pPlayer, szModel);
	
	return true;
}

public jbe_set_user_model(pPlayer, const szModel[]) {
	copy(g_szUserModel[pPlayer], charsmax(g_szUserModel[]), szModel);
	static Float:fGameTime, Float:fChangeTime; fGameTime = get_gametime();
	if(fGameTime - fChangeTime > 0.1) {
		jbe_set_user_model_fix(pPlayer+TASK_CHANGE_MODEL);
		fChangeTime = fGameTime;
	}
	else {
		set_task((fChangeTime + 0.1) - fGameTime, "jbe_set_user_model_fix", pPlayer+TASK_CHANGE_MODEL);
		fChangeTime = fChangeTime + 0.1;
	}
}

public jbe_set_user_model_fix(pPlayer) {
	pPlayer -= TASK_CHANGE_MODEL;
	engfunc(EngFunc_SetClientKeyValue, pPlayer, engfunc(EngFunc_GetInfoKeyBuffer, pPlayer), "model", g_szUserModel[pPlayer]);
	new szBuffer[64]; formatex(szBuffer, charsmax(szBuffer), "models/player/%s/%s.mdl", g_szUserModel[pPlayer], g_szUserModel[pPlayer]);
	set_member(pPlayer, m_modelIndexPlayer, engfunc(EngFunc_ModelIndex, szBuffer));
	SetBit(g_iBitUserModel, pPlayer);
}

public jbe_informer_offset_up(pPlayer) {
	switch(g_iInformerCord[pPlayer]) {
		case true: {
			g_fMainInformerPosX[pPlayer] = 0.6;
			g_fMainInformerPosY[pPlayer] = 0.01;
			g_fFWInformerPosX[pPlayer] = 0.15;
			g_fFWInformerPosY[pPlayer] = 0.01;
		}
		case false: {
			g_fMainInformerPosX[pPlayer] = 0.15;
			g_fMainInformerPosY[pPlayer] = 0.01;
			g_fFWInformerPosX[pPlayer] = 0.6;
			g_fFWInformerPosY[pPlayer] = 0.01;
		}
	}
}

public jbe_informer_offset_down(pPlayer) {
	switch(g_iInformerCord[pPlayer]) {
		case true: {
			g_fMainInformerPosX[pPlayer] = 0.6;
			g_fMainInformerPosY[pPlayer] = 0.18;
			g_fFWInformerPosX[pPlayer] = 0.15;
			g_fFWInformerPosY[pPlayer] = 0.18;
		}
		case false: {
			g_fMainInformerPosX[pPlayer] = 0.15;
			g_fMainInformerPosY[pPlayer] = 0.18;
			g_fFWInformerPosX[pPlayer] = 0.6;
			g_fFWInformerPosY[pPlayer] = 0.18;
		}
	}
}

public jbe_menu_block(pPlayer) SetBit(g_iBitBlockMenu, pPlayer);
public jbe_menu_unblock(pPlayer) ClearBit(g_iBitBlockMenu, pPlayer);
public jbe_menu_blocked(pPlayer) return IsSetBit(g_iBitBlockMenu, pPlayer);

public jbe_is_user_free(pPlayer) return IsSetBit(g_iBitUserFree, pPlayer);
public jbe_add_user_free(pPlayer) {
	if(g_iDayMode != 1 || g_iUserTeam[pPlayer] != 1 || IsNotSetBit(g_iBitUserAlive, pPlayer)
	|| IsSetBit(g_iBitUserFree, pPlayer) || IsSetBit(g_iBitUserWanted, pPlayer)) return 0;
	SetBit(g_iBitUserFree, pPlayer);
	new szName[32]; 
	get_user_name(pPlayer, szName, charsmax(szName));
	formatex(g_szFreeNames, charsmax(g_szFreeNames), "%s^n%s", g_szFreeNames, szName);
	g_iFreeLang = 1;
	if(bIsSetmodBit(g_bSoccerStatus) && IsSetBit(g_iBitUserSoccer, pPlayer)) {
		ClearBit(g_iBitUserSoccer, pPlayer);
		jbe_set_user_model(pPlayer, g_szPlayerModel[PRISONER]);
		jbe_default_knife_model(pPlayer);
		UTIL_WeaponAnimation(pPlayer, 3);
		set_member(pPlayer, m_bloodColor, 247);
		if(pPlayer == g_iSoccerBallOwner) {
			CREATE_KILLPLAYERATTACHMENTS(pPlayer);
			set_entvar(g_iSoccerBall, var_solid, SOLID_TRIGGER);
			set_entvar(g_iSoccerBall, var_velocity, Float:{0.0, 0.0, 0.1});
			g_iSoccerBallOwner = 0;
		}
		if(bIsSetmodBit(g_bSoccerGame)) remove_task(pPlayer+TASK_SHOW_SOCCER_SCORE);
	}
	if(bIsSetmodBit(g_bBoxingStatus) && IsSetBit(g_iBitUserBoxing, pPlayer)) {
		ClearBit(g_iBitUserBoxing, pPlayer);
		jbe_set_hand_model(pPlayer);
		UTIL_WeaponAnimation(pPlayer, 3);
		rg_set_user_health(pPlayer, 100.0);
		set_member(pPlayer, m_bloodColor, 247);
	}
	set_entvar(pPlayer, var_skin, 5);
	rg_set_user_rendering(pPlayer, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 4);
	set_task(float(g_iAllCvars[FREE_DAY_ID]), "jbe_sub_user_free", pPlayer+TASK_FREE_DAY_ENDED);
	UTIL_BarTime(pPlayer, g_iAllCvars[FREE_DAY_ID]);
	return 1;
}

public jbe_add_user_free_next_round(pPlayer) {
	if(g_iUserTeam[pPlayer] != 1) return 0;
	SetBit(g_iBitUserFreeNextRound, pPlayer);
	return 1;
}

public jbe_sub_user_free(pPlayer) {
	if(pPlayer > TASK_FREE_DAY_ENDED) pPlayer -= TASK_FREE_DAY_ENDED;
	if(IsNotSetBit(g_iBitUserFree, pPlayer)) return 0;
	ClearBit(g_iBitUserFree, pPlayer);
	if(g_szFreeNames[0] != 0) {
		new szName[34];
		get_user_name(pPlayer, szName, charsmax(szName));
		format(szName, charsmax(szName), "^n%s", szName);
		replace(g_szFreeNames, charsmax(g_szFreeNames), szName, "");
		g_iFreeLang = (g_szFreeNames[0] != 0);
	}
	if(task_exists(pPlayer+TASK_FREE_DAY_ENDED)) remove_task(pPlayer+TASK_FREE_DAY_ENDED);
	if(IsSetBit(g_iBitUserAlive, pPlayer)) {
		if(pPlayer == g_iAthrID) set_entvar(pPlayer, var_skin, 7);
		else if(pPlayer == g_iSixPlID) set_entvar(pPlayer, var_skin, 8);
		else set_entvar(pPlayer, var_skin, g_iUserSkin[pPlayer]);
	}
	rg_set_user_rendering(pPlayer, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
	UTIL_BarTime(pPlayer, 0);
	return 1;
}

public jbe_free_day_start() 
{
	if(g_iDayMode != 1) return 0;
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) 
	{
		g_fMainInformerColor[iPlayer] = {0, 255, 0};
		if(g_iUserTeam[iPlayer] == 1 && IsSetBit(g_iBitUserAlive, iPlayer) && IsNotSetBit(g_iBitUserWanted, iPlayer)) 
		{
			if(IsSetBit(g_iBitUserFree, iPlayer)) remove_task(iPlayer+TASK_FREE_DAY_ENDED);
			else
			{
				SetBit(g_iBitUserFree, iPlayer);
				if(bIsSetmodBit(g_bSoccerStatus) && IsSetBit(g_iBitUserSoccer, iPlayer)) 
				{
					ClearBit(g_iBitUserSoccer, iPlayer);
					jbe_set_user_model(iPlayer, g_szPlayerModel[PRISONER]);
					jbe_default_knife_model(iPlayer);
					UTIL_WeaponAnimation(iPlayer, 3);
					set_member(iPlayer, m_bloodColor, 247);
					if(iPlayer == g_iSoccerBallOwner) 
					{
						CREATE_KILLPLAYERATTACHMENTS(iPlayer);
						set_entvar(g_iSoccerBall, var_solid, SOLID_TRIGGER);
						set_entvar(g_iSoccerBall, var_velocity, Float:{0.0, 0.0, 0.1});
						g_iSoccerBallOwner = 0;
					}
					if(bIsSetmodBit(g_bSoccerGame)) remove_task(iPlayer+TASK_SHOW_SOCCER_SCORE);
				}
				if(bIsSetmodBit(g_bBoxingStatus) && IsSetBit(g_iBitUserBoxing, iPlayer)) 
				{
					ClearBit(g_iBitUserBoxing, iPlayer);
					jbe_set_hand_model(iPlayer);
					UTIL_WeaponAnimation(iPlayer, 3);
					rg_set_user_health(iPlayer, 100.0);
					set_member(iPlayer, m_bloodColor, 247);
				}
				set_entvar(iPlayer, var_skin, 5);
			}
		}
		rh_emit_sound2(iPlayer, 0, CHAN_AUTO, "egoist/jb/boxing/gong.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
	g_szFreeNames = "";
	g_iFreeLang = 0;
	jbe_open_doors();
	jbe_set_day_mode(2);
	g_iDayModeTimer = g_iAllCvars[FREE_DAY_ALL] + 1;
	set_task(1.0, "jbe_free_day_ended_task", TASK_FREE_DAY_ENDED, _, _, "a", g_iDayModeTimer);	
	return 1;
}

public jbe_free_day_ended_task() {
	if(--g_iDayModeTimer) formatex(g_szDayModeTimer, charsmax(g_szDayModeTimer), "(0%d:%s%d)", abs(get_min(g_iDayModeTimer)), get_sec(g_iDayModeTimer) < 10 ? "0":"", get_sec(g_iDayModeTimer));
	else jbe_free_day_ended();
}

public jbe_free_day_ended() 
{
	if(g_iDayMode != 2) return 0;
	g_szDayModeTimer = "";
	if(task_exists(TASK_FREE_DAY_ENDED)) remove_task(TASK_FREE_DAY_ENDED);
	set_hudmessage(255, 0, 0, -1.0, 0.24, 1, 1.0, 5.0);
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) 
	{
		if(IsNotSetBit(g_iBitUserConnected, iPlayer)) continue;
	
		g_fMainInformerColor[iPlayer] = {255, 255, 255};
	
		rh_emit_sound2(iPlayer, 0, CHAN_AUTO, "egoist/jb/other/fd_end.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		
		if(IsSetBit(g_iBitUserFree, iPlayer)) {
			ClearBit(g_iBitUserFree, iPlayer);
			if(iPlayer == g_iAthrID) set_entvar(iPlayer, var_skin, 7);
			else if(iPlayer == g_iSixPlID) set_entvar(iPlayer, var_skin, 8);
			else set_entvar(iPlayer, var_skin, g_iUserSkin[iPlayer]);
		}
	}
	jbe_set_day_mode(1);
	return 1;
}

public jbe_is_user_wanted(pPlayer) return IsSetBit(g_iBitUserWanted, pPlayer);

public jbe_add_user_wanted(pPlayer) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || g_iUserTeam[pPlayer] != 1 || IsNotSetBit(g_iBitUserAlive, pPlayer) 
	|| IsSetBit(g_iBitUserWanted, pPlayer)) return 0;
	SetBit(g_iBitUserWanted, pPlayer);
	new szName[34];
	get_user_name(pPlayer, szName, charsmax(szName));
	formatex(g_szWantedNames, charsmax(g_szWantedNames), "%s^n%s", g_szWantedNames, szName);
	g_iWantedLang = 1;
	if(IsSetBit(g_iBitUserFree, pPlayer)) {
		ClearBit(g_iBitUserFree, pPlayer);
		if(g_szFreeNames[0] != 0) {
			format(szName, charsmax(szName), "^n%s", szName);
			replace(g_szFreeNames, charsmax(g_szFreeNames), szName, "");
			g_iFreeLang = (g_szFreeNames[0] != 0);
		}
		if(g_iDayMode == 1 && task_exists(pPlayer+TASK_FREE_DAY_ENDED)) remove_task(pPlayer+TASK_FREE_DAY_ENDED);
	}
	if(IsSetBit(g_iBitUserSoccer, pPlayer)) {
		ClearBit(g_iBitUserSoccer, pPlayer);
		jbe_set_user_model(pPlayer, g_szPlayerModel[PRISONER]);
		jbe_default_knife_model(pPlayer);
		UTIL_WeaponAnimation(pPlayer, 3);
		set_member(pPlayer, m_bloodColor, 247);
		if(pPlayer == g_iSoccerBallOwner) {
			CREATE_KILLPLAYERATTACHMENTS(pPlayer);
			set_entvar(g_iSoccerBall, var_solid, SOLID_TRIGGER);
			set_entvar(g_iSoccerBall, var_velocity, Float:{0.0, 0.0, 0.1});
			g_iSoccerBallOwner = 0;
		}
		if(bIsSetmodBit(g_bSoccerGame)) remove_task(pPlayer+TASK_SHOW_SOCCER_SCORE);
	}
	if(IsSetBit(g_iBitUserBoxing, pPlayer)) {
		ClearBit(g_iBitUserBoxing, pPlayer);
		jbe_set_hand_model(pPlayer);
		UTIL_WeaponAnimation(pPlayer, 3);
		rg_set_user_health(pPlayer, 100.0);
		set_member(pPlayer, m_bloodColor, 247);
	}
	set_entvar(pPlayer, var_skin, 6);
	rg_set_user_rendering(pPlayer, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 4);
	UTIL_BarTime(pPlayer, 0);
	return 1;
}

public jbe_sub_user_wanted(pPlayer) {
	if(IsNotSetBit(g_iBitUserWanted, pPlayer)) return 0;
	ClearBit(g_iBitUserWanted, pPlayer);
	if(g_szWantedNames[0] != 0) {
		new szName[34];
		get_user_name(pPlayer, szName, charsmax(szName));
		format(szName, charsmax(szName), "^n%s", szName);
		replace(g_szWantedNames, charsmax(g_szWantedNames), szName, "");
		g_iWantedLang = (g_szWantedNames[0] != 0);
	}
	if(IsSetBit(g_iBitUserAlive, pPlayer)) {
		if(g_iDayMode == 2) {
			SetBit(g_iBitUserFree, pPlayer);
			set_entvar(pPlayer, var_skin, 5);
		}
		else {
			if(pPlayer == g_iAthrID) set_entvar(pPlayer, var_skin, 7);
			else if(pPlayer == g_iSixPlID) set_entvar(pPlayer, var_skin, 8);
			else set_entvar(pPlayer, var_skin, g_iUserSkin[pPlayer]);
		}
	}
	rg_set_user_rendering(pPlayer, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
	return 1;
}

public jbe_is_user_chief(pPlayer) return (pPlayer == g_iChiefId);
public jbe_set_user_chief(pPlayer) 
{
	if(g_iDayMode != 1 && g_iDayMode != 2 || g_iUserTeam[pPlayer] != 2 || IsNotSetBit(g_iBitUserAlive, pPlayer)) return 0;
	if(g_iChiefStatus == 1)
	{
		jbe_set_user_model(pPlayer, g_szPlayerModel[GUARD]);
		if(bIsSetmodBit(g_bSoccerGame)) remove_task(g_iChiefId+TASK_SHOW_SOCCER_SCORE);
		if(rg_get_user_takedamage(g_iChiefId)) rg_set_user_takedamage(g_iChiefId, false);
	}
	if(task_exists(TASK_CHIEF_CHOICE_TIME)) remove_task(TASK_CHIEF_CHOICE_TIME);
	get_user_name(pPlayer, g_szChiefName, charsmax(g_szChiefName));
	g_iChiefStatus = 1;
	g_iChiefId = pPlayer;
	jbe_set_user_model(pPlayer, g_szPlayerModel[CHIEF]);
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) g_fMainInformerColor[iPlayer] = {255, 255, 0};
	
	client_cmd(0, "spk fvox/bell.wav" );
	rg_set_user_armor(pPlayer, 100, ARMOR_VESTHELM);
	rg_set_user_health(pPlayer, 500.0);
	rg_remove_all_items(pPlayer, false);
	rg_give_item(pPlayer, "weapon_knife", GT_APPEND);
	give_gold_ak47(pPlayer);
	give_gold_deagle(pPlayer);
	
	if(bIsSetmodBit(g_bSoccerStatus))  {
		if(IsSetBit(g_iBitUserSoccer, pPlayer))  {
			ClearBit(g_iBitUserSoccer, pPlayer);
			jbe_set_baton_model(pPlayer);
			UTIL_WeaponAnimation(pPlayer, 3);
			set_member(pPlayer, m_bloodColor, 247);
			if(pPlayer == g_iSoccerBallOwner) {
				CREATE_KILLPLAYERATTACHMENTS(pPlayer);
				set_entvar(g_iSoccerBall, var_solid, SOLID_TRIGGER);
				set_entvar(g_iSoccerBall, var_velocity, Float:{0.0, 0.0, 0.1});
				g_iSoccerBallOwner = 0;
			}
		}
		else if(bIsSetmodBit(g_bSoccerGame)) set_task(1.0, "jbe_soccer_score_informer", pPlayer+TASK_SHOW_SOCCER_SCORE, _, _, "b");
	}
	ExecuteForward(g_Fw_ChiefUp, g_ForwardReturn, pPlayer);
	return 1;
}

public jbe_get_chief_status() return g_iChiefStatus;
public jbe_get_chief_id() return g_iChiefId;

public jbe_set_user_costumes(pPlayer, iCostumes, iModel) {
	if(g_iDayMode != 1 && g_iDayMode != 2) return 0;
	if(iCostumes) {
		if(!g_eUserCostumes[pPlayer][ENTITY]) {
			static iszFuncWall = 0;
			if(iszFuncWall || (iszFuncWall = engfunc(EngFunc_AllocString, "func_wall"))) g_eUserCostumes[pPlayer][ENTITY] = engfunc(EngFunc_CreateNamedEntity, iszFuncWall);
			set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_movetype, MOVETYPE_FOLLOW);
			
			switch(iModel) {
				case 2: engfunc(EngFunc_SetModel, g_eUserCostumes[pPlayer][ENTITY], g_szModelView[COSTUME_S_VIP]);
				case 1: engfunc(EngFunc_SetModel, g_eUserCostumes[pPlayer][ENTITY], g_szModelView[COSTUME_S]);
			}
	
			set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_aiment, pPlayer);
			set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_body, iCostumes - 1);
			if(iModel == 2) {
				switch(iCostumes) {
					case 1: set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_sequence, 0);
					case 2: set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_sequence, 1);
					case 3: set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_sequence, 2);
					case 4: set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_sequence, 3);
					case 5: set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_sequence, 4);
					case 6: set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_sequence, 5);
					case 7: set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_sequence, 6);
					case 8: set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_sequence, 7);
					case 9: set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_sequence, 8);
				}
			}
			else set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_sequence, 0);
			set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_animtime, get_gametime());
			set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_framerate, 1.0);
			rg_set_user_rendering(g_eUserCostumes[pPlayer][ENTITY], kRenderFxGlowShell, random_num(0,255), random_num(0,255), random_num(0,255), kRenderNormal, 4);
		}
		else set_entvar(g_eUserCostumes[pPlayer][ENTITY], var_body, iCostumes - 1);	
		
		g_eUserCostumes[pPlayer][HIDE] = false;
		g_eUserCostumes[pPlayer][ACCES_FLAGS] = iModel;
		g_eUserCostumes[pPlayer][COSTUMES] = iCostumes;
		return 1;
	}
	else if(g_eUserCostumes[pPlayer][COSTUMES]) {
		if(g_eUserCostumes[pPlayer][ENTITY]) engfunc(EngFunc_RemoveEntity, g_eUserCostumes[pPlayer][ENTITY]);
		g_eUserCostumes[pPlayer][ENTITY] = 0;
		g_eUserCostumes[pPlayer][HIDE] = false;
		g_eUserCostumes[pPlayer][ACCES_FLAGS] = 0;
		g_eUserCostumes[pPlayer][COSTUMES] = 0;
		return 1;
	}
	return 0;
}

public jbe_hide_user_costumes(pPlayer) {
	if(g_eUserCostumes[pPlayer][ENTITY]) {
		engfunc(EngFunc_RemoveEntity, g_eUserCostumes[pPlayer][ENTITY]);
		g_eUserCostumes[pPlayer][ENTITY] = 0;
		g_eUserCostumes[pPlayer][HIDE] = true;
		g_eUserCostumes[pPlayer][ACCES_FLAGS] = 0;	
		return true;
	}
	return false;
}

public jbe_get_user_costumes(pPlayer) return g_eUserCostumes[pPlayer][COSTUMES];

public jbe_prisoners_divide_color(iTeam) {
	if(g_iDayMode != 1 || g_iAlivePlayersNum[1] < 2 || iTeam < 2 || iTeam > 4) return 0;
	new const szLangPlayer[][] = {"JBE_HUD_ID_YOU_TEAM_ORANGE", "JBE_HUD_ID_YOU_TEAM_GRAY", "JBE_HUD_ID_YOU_TEAM_YELLOW", "JBE_HUD_ID_YOU_TEAM_BLUE"};
	for(new iPlayer = 1, iColor; iPlayer <= MaxClients; iPlayer++) {
		if(g_iUserTeam[iPlayer] != 1 || IsNotSetBit(g_iBitUserAlive, iPlayer) || IsSetBit(g_iBitUserFree, iPlayer)
		|| IsSetBit(g_iBitUserWanted, iPlayer) || IsSetBit(g_iBitUserSoccer, iPlayer) || IsSetBit(g_iBitUserBoxing, iPlayer)
		|| IsSetBit(g_iBitUserDuel, iPlayer)) continue;
		client_print_color(iPlayer, print_team_default, "^1[^4INFO^1] %L", iPlayer, szLangPlayer[iColor]);
		set_entvar(iPlayer, var_skin, iColor);
		if(++iColor >= iTeam) iColor = 0;
	}
	return 1;
}

public jbe_register_day_mode(szLang[32], iBlock, iTime) {
	param_convert(1);
	new aDataDayMode[DATA_DAY_MODE];
	copy(aDataDayMode[LANG_MODE], charsmax(aDataDayMode[LANG_MODE]), szLang);
	aDataDayMode[MODE_BLOCK_DAYS] = iBlock;
	aDataDayMode[MODE_TIMER] = iTime;
	ArrayPushArray(g_aDataDayMode, aDataDayMode);
	g_iDayModeListSize++;
	server_print("----^nИгра №%d: %L | Время игры: %d секунд | Блок: %d д.^n----", g_iDayModeListSize, 0, aDataDayMode[LANG_MODE], iTime, iBlock);
	return g_iDayModeListSize - 1;
}

public jbe_get_user_voice(pPlayer) return IsSetBit(g_iBitUserVoice, pPlayer);
public jbe_set_user_voice(pPlayer) {
	if(g_iDayMode != 1 && g_iDayMode != 2 || g_iUserTeam[pPlayer] != 1 || IsNotSetBit(g_iBitUserAlive, pPlayer)) return 0;
	SetBit(g_iBitUserVoice, pPlayer);
	return 1;
}

public jbe_set_user_voice_next_round(pPlayer) {
	if(g_iUserTeam[pPlayer] != 1) return 0;
	SetBit(g_iBitUserVoiceNextRound, pPlayer);
	return 1;
}
/*===== <- Нативы <- =====*///}

/*===== -> Стоки -> =====*///{

stock set_speed(ent, Float:speed, mode = 0, const Float:origin[3] = {0.0, 0.0, 0.0}) {
	if(!is_entity(ent)) return PLUGIN_CONTINUE;

	switch(mode) {
		case 0: {
			static Float:CurrentVelocity[3];

			get_entvar(ent, var_velocity, CurrentVelocity);

			new Float:y;
			y = CurrentVelocity[0] * CurrentVelocity[0] + CurrentVelocity[1] * CurrentVelocity[1];

			new Float:x;
			if(y) x = floatsqroot(speed * speed / y);

			CurrentVelocity[0] *= x;
			CurrentVelocity[1] *= x;

			if(speed < 0.0) {
				CurrentVelocity[0] *= -1;
				CurrentVelocity[1] *= -1;
			}

			set_entvar(ent, var_velocity, CurrentVelocity);
		}
		case 1: {
			static Float:CurrentVelocity[3];

			get_entvar(ent, var_velocity, CurrentVelocity);

			new Float:y;
			y = CurrentVelocity[0] * CurrentVelocity[0] + CurrentVelocity[1] * CurrentVelocity[1] + CurrentVelocity[2] * CurrentVelocity[2];

			new Float:x;
			if(y) x = floatsqroot(speed * speed / y);

			CurrentVelocity[0] *= x;
			CurrentVelocity[1] *= x;
			CurrentVelocity[2] *= x;

			if(speed < 0.0) {
				CurrentVelocity[0] *= -1;
				CurrentVelocity[1] *= -1;
				CurrentVelocity[2] *= -1;
			}

			set_entvar(ent, var_velocity, CurrentVelocity);
		}
		case 2: {
			static Float:vAngle[3];
			if(jbe_is_user_valid(ent)) get_entvar(ent, var_v_angle, vAngle);
			else get_entvar(ent, var_angles, vAngle);

			static Float:NewVelocity[3];

			angle_vector(vAngle,1,NewVelocity);

			new Float:y;
			y = NewVelocity[0] * NewVelocity[0] + NewVelocity[1] * NewVelocity[1] + NewVelocity[2] * NewVelocity[2];

			new Float:x;
			if(y) x = floatsqroot(speed*speed / y);

			NewVelocity[0] *= x;
			NewVelocity[1] *= x;
			NewVelocity[2] *= x;

			if(speed<0.0) {
				NewVelocity[0] *= -1;
				NewVelocity[1] *= -1;
				NewVelocity[2] *= -1;
			}

			set_entvar(ent, var_velocity, NewVelocity);
		}
		case 3: {
			static Float:vAngle[3];
			if(jbe_is_user_valid(ent)) get_entvar(ent, var_v_angle, vAngle);
			else get_entvar(ent, var_angles, vAngle);

			static Float:NewVelocity[3];

			get_entvar(ent, var_velocity, NewVelocity);

			angle_vector(vAngle, 1, NewVelocity);

			new Float:y;
			y = NewVelocity[0] * NewVelocity[0] + NewVelocity[1] * NewVelocity[1];

			new Float:x;
			if(y) x = floatsqroot(speed*speed / y);

			NewVelocity[0] *= x;
			NewVelocity[1] *= x;

			if(speed<0.0) {
				NewVelocity[0] *= -1;
				NewVelocity[1] *= -1;
			}

			set_entvar(ent, var_velocity, NewVelocity);
		}
		case 4: {
			static Float:FalseOrigin[3];
			get_entvar(ent, var_origin, FalseOrigin);

			static Float:NewVelocity[3];

			NewVelocity[0] = origin[0] - FalseOrigin[0];
			NewVelocity[1] = origin[1] - FalseOrigin[1];
			NewVelocity[2] = origin[2] - FalseOrigin[2];

			new Float:y;
			y = NewVelocity[0] * NewVelocity[0] + NewVelocity[1] * NewVelocity[1] + NewVelocity[2]*NewVelocity[2];

			new Float:x;
			if(y) x = floatsqroot(speed * speed / y);

			NewVelocity[0] *= x;
			NewVelocity[1] *= x;
			NewVelocity[2] *= x;

			if(speed<0.0) {
				NewVelocity[0] *= -1;
				NewVelocity[1] *= -1;
				NewVelocity[2] *= -1;
			}

			set_entvar(ent, var_velocity, NewVelocity);
		}
		default: return PLUGIN_CONTINUE;
	}
	return PLUGIN_HANDLED;
}

stock long_jump(long_jump)  {
	set_speed(long_jump, 1000.0, 3);
	static Float:velocity[3];
	get_entvar(long_jump, var_velocity, velocity);
	velocity[2] = get_pcvar_float(get_cvar_pointer("sv_gravity")) / 3.0;
	new button = get_entvar(long_jump, var_button);
	if(button & IN_BACK) {
		velocity[0] *= -1;
		velocity[1] *= -1;
	}
	set_entvar(long_jump, var_velocity, velocity);
}

stock fm_get_aiming_position(pPlayer, Float:vecReturn[3], Float:fMaxDistance = 8192.0) {
	new Float:vecOrigin[3], Float:vecViewOfs[3], Float:vecAngle[3], Float:vecForward[3];
	pev(pPlayer, pev_origin, vecOrigin);
	pev(pPlayer, pev_view_ofs, vecViewOfs);
	xs_vec_add(vecOrigin, vecViewOfs, vecOrigin);
	pev(pPlayer, pev_v_angle, vecAngle);
	engfunc(EngFunc_MakeVectors, vecAngle);
	global_get(glb_v_forward, vecForward);
	xs_vec_mul_scalar(vecForward, fMaxDistance, vecForward);
	xs_vec_add(vecOrigin, vecForward, vecForward);
	engfunc(EngFunc_TraceLine, vecOrigin, vecForward, DONT_IGNORE_MONSTERS, pPlayer, 0);
	get_tr2(0, TR_vecEndPos, vecReturn);
}

stock fm_set_kvd(pEntity, const szClassName[], const szKeyName[], const szValue[]) {
	set_kvd(0, KV_ClassName, szClassName);
	set_kvd(0, KV_KeyName, szKeyName);
	set_kvd(0, KV_Value, szValue);
	set_kvd(0, KV_fHandled, 0);
	return dllfunc(DLLFunc_KeyValue, pEntity, 0);
}

stock xs_vec_add(const Float:vec1[], const Float:vec2[], Float:out[]) {
	out[0] = vec1[0] + vec2[0];
	out[1] = vec1[1] + vec2[1];
	out[2] = vec1[2] + vec2[2];
}

stock xs_vec_mul_scalar(const Float:vec[], Float:scalar, Float:out[]) {
	out[0] = vec[0] * scalar;
	out[1] = vec[1] * scalar;
	out[2] = vec[2] * scalar;
}

stock UTIL_SendAudio(pPlayer, iPitch = 100, const szPathSound[], any:...) {
	new szBuffer[128];
	if(numargs() > 3) vformat(szBuffer, charsmax(szBuffer), szPathSound, 4);
	else copy(szBuffer, charsmax(szBuffer), szPathSound);
	switch(pPlayer) {
		case 0: {
			message_begin(MSG_BROADCAST, MsgId_SendAudio);
			write_byte(pPlayer);
			write_string(szBuffer);
			write_short(iPitch);
			message_end();
		}
		default: {
			engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MsgId_SendAudio, {0.0, 0.0, 0.0}, pPlayer);
			write_byte(pPlayer);
			write_string(szBuffer);
			write_short(iPitch);
			message_end();
		}
	}
}

stock UTIL_ScreenFade(pPlayer, iDuration, iHoldTime, iFlags, iRed, iGreen, iBlue, iAlpha, iReliable = 0) {
	switch(pPlayer) {
		case 0: {
			message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, MsgId_ScreenFade);
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
			engfunc(EngFunc_MessageBegin, iReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, MsgId_ScreenFade, {0.0, 0.0, 0.0}, pPlayer);
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
	engfunc(EngFunc_MessageBegin, iReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, MsgId_ScreenShake, {0.0, 0.0, 0.0}, pPlayer);
	write_short(iAmplitude);
	write_short(iDuration);
	write_short(iFrequency);
	message_end();
}

stock UTIL_WeaponAnimation(pPlayer, iAnimation) {
	set_entvar(pPlayer, var_weaponanim, iAnimation);
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0.0, 0.0, 0.0}, pPlayer);
	write_byte(iAnimation);
	write_byte(0);
	message_end();
}

stock UTIL_BarTime(pPlayer, iTime) {
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MsgId_BarTime, {0.0, 0.0, 0.0}, pPlayer);
	write_short(iTime);
	message_end();
}

stock UTIL_PlayerAnimation(pPlayer, const szAnimation[]) { // Спасибо большое KORD_12.7 
	new iAnimDesired, Float:flFrameRate, Float:flGroundSpeed, bool:bLoops;
	if((iAnimDesired = lookup_sequence(pPlayer, szAnimation, flFrameRate, bLoops, flGroundSpeed)) == -1) iAnimDesired = 0;
	new Float:flGametime = get_gametime();
	set_entvar(pPlayer, var_frame, 0.0);
	set_entvar(pPlayer, var_framerate, 1.0);
	set_entvar(pPlayer, var_animtime, flGametime);
	set_entvar(pPlayer, var_sequence, iAnimDesired);
	set_member(pPlayer, m_fSequenceLoops, bLoops);
	set_member(pPlayer, m_fSequenceFinished, 0);
	set_member(pPlayer, m_flFrameRate, flFrameRate);
	set_member(pPlayer, m_flGroundSpeed, flGroundSpeed);
	set_member(pPlayer, m_flLastEventCheck, flGametime);
	set_member(pPlayer, m_Activity, ACT_RANGE_ATTACK1);
	set_member(pPlayer, m_IdealActivity, ACT_RANGE_ATTACK1);   
	set_member(pPlayer, m_flLastFired, flGametime);
}

stock UTIL_BlinkAcct(pPlayer, iBlinkAmtInSec) {
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MsgId_BlinkAcct, {0.0, 0.0, 0.0}, pPlayer);
	write_byte(iBlinkAmtInSec);
	message_end();
}

stock get_sec(const in_sec) return (in_sec % 60);
stock get_min(const in_sec) return (in_sec / 60);

stock CREATE_BEAMCYLINDER(Float:vecOrigin[3], iRadius, pSprite, iStartFrame = 0, iFrameRate = 0, iLife, iWidth, iAmplitude = 0, iRed, iGreen, iBlue, iBrightness, iScrollSpeed = 0) {
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_BEAMCYLINDER);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + 32.0 + iRadius * 2);
	write_short(pSprite);
	write_byte(iStartFrame);
	write_byte(iFrameRate); // 0.1's
	write_byte(iLife); // 0.1's
	write_byte(iWidth);
	write_byte(iAmplitude); // 0.01's
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iBrightness);
	write_byte(iScrollSpeed); // 0.1's
	message_end();
}

stock CREATE_BREAKMODEL(Float:vecOrigin[3], Float:vecSize[3] = {16.0, 16.0, 16.0}, Float:vecVelocity[3] = {25.0, 25.0, 25.0}, iRandomVelocity, pModel, iCount, iLife, iFlags) {
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_BREAKMODEL);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + 24);
	engfunc(EngFunc_WriteCoord, vecSize[0]);
	engfunc(EngFunc_WriteCoord, vecSize[1]);
	engfunc(EngFunc_WriteCoord, vecSize[2]);
	engfunc(EngFunc_WriteCoord, vecVelocity[0]);
	engfunc(EngFunc_WriteCoord, vecVelocity[1]);
	engfunc(EngFunc_WriteCoord, vecVelocity[2]);
	write_byte(iRandomVelocity);
	write_short(pModel);
	write_byte(iCount); // 0.1's
	write_byte(iLife); // 0.1's
	write_byte(iFlags); // BREAK_GLASS 0x01, BREAK_METAL 0x02, BREAK_FLESH 0x04, BREAK_WOOD 0x08
	message_end();
}

stock CREATE_BEAMFOLLOW(pEntity, pSptite, iLife, iWidth, iRed, iGreen, iBlue, iAlpha) {
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(pEntity);
	write_short(pSptite);
	write_byte(iLife); // 0.1's
	write_byte(iWidth);
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iAlpha);
	message_end();
}

stock CREATE_SPRITE(Float:vecOrigin[3], pSptite, iWidth, iAlpha) {
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(pSptite);
	write_byte(iWidth);
	write_byte(iAlpha);
	message_end();
}

stock CREATE_PLAYERATTACHMENT(pPlayer, iHeight = 50, pSprite, iLife) {
	message_begin(MSG_ALL, SVC_TEMPENTITY);
	write_byte(TE_PLAYERATTACHMENT);
	write_byte(pPlayer);
	write_coord(iHeight);
	write_short(pSprite);
	write_short(iLife); // 0.1's
	message_end();
}

stock CREATE_KILLPLAYERATTACHMENTS(pPlayer) {
	message_begin(MSG_ALL, SVC_TEMPENTITY);
	write_byte(TE_KILLPLAYERATTACHMENTS);
	write_byte(pPlayer);
	message_end();
}

stock CREATE_BEAMENTPOINT(pEntity, Float:vecOrigin[3], pSprite, iStartFrame = 0, iFrameRate = 0, iLife, iWidth, iAmplitude = 0, iRed, iGreen, iBlue, iBrightness, iScrollSpeed = 0) {
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMENTPOINT);
	write_short(pEntity);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(pSprite);
	write_byte(iStartFrame);
	write_byte(iFrameRate); // 0.1's
	write_byte(iLife); // 0.1's
	write_byte(iWidth);
	write_byte(iAmplitude); // 0.01's
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iBrightness);
	write_byte(iScrollSpeed); // 0.1's
	message_end();
}

stock CREATE_KILLBEAM(pEntity) {
	message_begin(MSG_ALL, SVC_TEMPENTITY);
	write_byte(TE_KILLBEAM);
	write_short(pEntity);
	message_end();
}

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

stock rg_set_user_noclip(const player, bool:noclip = true) set_entvar(player, var_movetype, noclip ? MOVETYPE_NOCLIP : MOVETYPE_WALK);

stock bool:rg_get_user_noclip(const player) return bool:(get_entvar(player, var_movetype) == MOVETYPE_NOCLIP);

stock rg_set_user_takedamage(const player, bool:take = true) set_entvar(player, var_takedamage, take ? DAMAGE_NO : DAMAGE_AIM);

stock bool:rg_get_user_takedamage(const player) return bool:(get_entvar(player, var_takedamage) == DAMAGE_NO);

stock Float:rg_get_user_maxspeed(const player) return Float:get_entvar(player, var_maxspeed);

stock rg_set_user_maxspeed(const player, Float:speed = -1.0) {
	if(speed != -1.0) set_entvar(player, var_maxspeed, Float:speed);
	else rg_reset_maxspeed(player);
}

stock rg_set_user_gravity(const player, Float:gravity = 1.0) set_entvar(player, var_gravity, Float:gravity);

stock Float:rg_get_user_gravity(const player) return Float:get_entvar(player, var_gravity);

stock Float:rg_get_user_health(const player) return Float:get_entvar(player, var_health);

stock rg_set_user_health(const player, Float:health) set_entvar(player, var_health, Float:health);

public jbe_get_user_money(const player) return g_iUserMoney[player];

public jbe_set_user_money(player, iNum, iFlash) {
	g_iUserMoney[player] = iNum;
	engfunc(EngFunc_MessageBegin, MSG_ONE, MsgId_Money, {0.0, 0.0, 0.0}, player);
	write_long(iNum);
	write_byte(iFlash);
	message_end();
}

stock TeamName:rg_get_user_team(const player) return TeamName:get_member(player, m_iTeam);

stock Float:rg_get_user_frags(const player) return Float:get_entvar(player, var_frags);

stock rg_set_user_frags(const player, Float:frags) set_entvar(player, var_frags, Float:frags);
/*===== <- Стоки <- =====*/