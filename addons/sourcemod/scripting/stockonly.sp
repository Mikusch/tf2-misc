#include <dhooks>
#include <sdktools>
#include <tf2_stocks>

public void OnPluginStart()
{
	GameData gamedata = new GameData("stockonly");
	if (!gamedata)
		LogError("Could not find stockonly gamedata");
	
	CreateDynamicDetour(gamedata, "CTFPlayer::GetLoadoutItem", DHookCallback_CTFPlayer_GetLoadoutItem_Pre, DHookCallback_CTFPlayer_GetLoadoutItem_Post);
}

static void CreateDynamicDetour(GameData gamedata, const char[] name, DHookCallback callbackPre = INVALID_FUNCTION, DHookCallback callbackPost = INVALID_FUNCTION)
{
	DynamicDetour detour = DynamicDetour.FromConf(gamedata, name);
	if (detour)
	{
		if (callbackPre != INVALID_FUNCTION)
			detour.Enable(Hook_Pre, callbackPre);
		
		if (callbackPost != INVALID_FUNCTION)
			detour.Enable(Hook_Post, callbackPost);
	}
	else
	{
		LogError("Failed to create detour setup handle for %s", name);
	}
}

static MRESReturn DHookCallback_CTFPlayer_GetLoadoutItem_Pre(int player, DHookReturn ret, DHookParam params)
{
	// Generate base items
	GameRules_SetProp("m_bIsInTraining", true);
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CTFPlayer_GetLoadoutItem_Post(int player, DHookReturn ret, DHookParam params)
{
	GameRules_SetProp("m_bIsInTraining", false);
	
	return MRES_Ignored;
}
