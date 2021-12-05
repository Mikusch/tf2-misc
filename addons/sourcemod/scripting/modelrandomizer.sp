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
	if (entity > MaxClients)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawned);
	}
}

public void OnEntitySpawned(int entity)
{
	int numStrings = GetStringTableNumStrings(g_ModelPrecacheTable);
	int index = GetRandomInt(0, numStrings);
	
	char model[PLATFORM_MAX_PATH];
	ReadStringTable(g_ModelPrecacheTable, index, model, PLATFORM_MAX_PATH);
	
	SetEntProp(entity, Prop_Data, "m_nModelIndexOverrides", index);
	SetEntProp(entity, Prop_Data, "m_nModelIndex", index);
}
