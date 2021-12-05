#include <sdktools>
#include <sdkhooks>
#include <tf2items>

static int g_ModelPrecacheTable;

public Plugin myinfo = 
{
	name = "Model Randomizer",
	author = "Mikusch",
	description = "",
	version = "1.0.0",
	url = "https://github.com/Mikusch"
};

public void OnPluginStart()
{
	g_ModelPrecacheTable = FindStringTable("modelprecache");
}

public void OnEntityCreated(int entity, const char[] classname)
{
	// Check if this entity is a non-player CBaseAnimating
	if (entity > MaxClients && HasEntProp(entity, Prop_Send, "m_bClientSideAnimation"))
	{
		SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawned);
	}
}

public void OnEntitySpawned(int entity)
{
	for (;;)
	{
		int numStrings = GetStringTableNumStrings(g_ModelPrecacheTable);
		int index = GetRandomInt(0, numStrings);
		
		char model[PLATFORM_MAX_PATH];
		ReadStringTable(g_ModelPrecacheTable, index, model, PLATFORM_MAX_PATH);
		
		// Only allow proper models, ignore brush and sprite entities
		if (StrContains(model, ".mdl") != -1)
		{
			SetEntProp(entity, Prop_Data, "m_nModelIndexOverrides", index);
			SetEntProp(entity, Prop_Data, "m_nModelIndex", index);
			break;
		}
	}
}
