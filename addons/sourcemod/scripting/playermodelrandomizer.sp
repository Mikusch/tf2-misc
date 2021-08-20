#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

//I copied this list from Pelipoika, but don't tell him!
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
	{ "models/player/items/taunts/yeti/yeti.mdl" }
};

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
}

public void Event_PostInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	//Grab a random model
	char model[PLATFORM_MAX_PATH];
	strcopy(model, sizeof(model), g_Models[GetRandomInt(0, sizeof(g_Models) - 1)]);
	
	//Set the model
	SetVariantString(model);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
}
