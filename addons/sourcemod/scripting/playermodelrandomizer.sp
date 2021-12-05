#include <sourcemod>
#include <sdktools>
#include <tf2items>

#pragma newdecls required
#pragma semicolon 1

// I copied this list from Pelipoika, but don't tell him!
static char g_Models[][] = 
{
	{ "models/bots/headless_hatman.mdl" },
	{ "models/bots/skeleton_sniper/skeleton_sniper.mdl" },
	{ "models/bots/skeleton_sniper_boss/skeleton_sniper_boss.mdl" },
	{ "models/bots/merasmus/merasmus.mdl" },
	{ "models/bots/demo/bot_demo.mdl" },
	{ "models/bots/demo/bot_sentry_buster.mdl" },
	{ "models/bots/engineer/bot_engineer.mdl" },
	{ "models/bots/heavy/bot_heavy.mdl" },
	{ "models/bots/medic/bot_medic.mdl" },
	{ "models/bots/pyro/bot_pyro.mdl" },
	{ "models/bots/scout/bot_scout.mdl" },
	{ "models/bots/sniper/bot_sniper.mdl" },
	{ "models/bots/soldier/bot_soldier.mdl" },
	{ "models/bots/spy/bot_spy.mdl" },
	{ "models/player/demo.mdl" },
	{ "models/player/engineer.mdl" },
	{ "models/player/heavy.mdl" },
	{ "models/player/medic.mdl" },
	{ "models/player/pyro.mdl" },
	{ "models/player/scout.mdl" },
	{ "models/player/sniper.mdl" },
	{ "models/player/soldier.mdl" },
	{ "models/player/spy.mdl" },
	{ "models/player/items/taunts/yeti/yeti.mdl" },
};

static Handle g_SDKCallEquipWearable;

public Plugin myinfo = 
{
	name = "Player Model Randomizer", 
	author = "Mikusch", 
	description = "", 
	version = "1.0.0", 
	url = "https://github.com/Mikusch"
};

public void OnPluginStart()
{
	HookEvent("post_inventory_application", Event_PostInventoryApplication);
	
	GameData gamedata = new GameData("playermodelrandomizer");
	if (gamedata)
	{
		StartPrepSDKCall(SDKCall_Player);
		if (PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTFPlayer::EquipWearable"))
		{
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
			g_SDKCallEquipWearable = EndPrepSDKCall();
		}
		else
		{
			SetFailState("Failed to create SDK call: CTFPlayer::EquipWearable");
		}
		
		delete gamedata;
	}
	else
	{
		SetFailState("Failed to read playermodelrandomizer gamedata");
	}
}

public void Event_PostInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	char model[PLATFORM_MAX_PATH];
	strcopy(model, sizeof(model), g_Models[GetRandomInt(0, sizeof(g_Models) - 1)]);
	
	SetVariantString(model);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	
	Handle item = TF2Items_CreateItem(OVERRIDE_ALL | FORCE_GENERATION);
	TF2Items_SetClassname(item, "tf_wearable");
	TF2Items_SetItemIndex(item, 8938);
	TF2Items_SetQuality(item, 6);
	TF2Items_SetLevel(item, 1);
	
	int wearable = TF2Items_GiveNamedItem(client, item);
	
	delete item;
	
	SDKCall(g_SDKCallEquipWearable, client, wearable);
	
	SetEntProp(client, Prop_Send, "m_nRenderFX", 6);
	SetEntProp(wearable, Prop_Data, "m_nModelIndexOverrides", PrecacheModel(model));
	SetEntProp(wearable, Prop_Send, "m_bValidatedAttachedEntity", 1);
}
