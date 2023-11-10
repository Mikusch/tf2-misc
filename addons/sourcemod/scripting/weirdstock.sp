#include <sourcescramble>
#include <sdktools>
#include <tf2attributes>
#include <sdkhooks>

public void OnPluginStart()
{
	GameData hGameConf = new GameData("weirdstock");
	if (hGameConf)
	{
		MemoryPatch patch = MemoryPatch.CreateFromConf(hGameConf, "CEconItemDefinition::BInitFromKV::DontParseAttributes");
		
		if (!patch.Validate())
		{
			ThrowError("Failed to verify patch.");
		}
		else if (patch.Enable())
		{
			LogMessage("Enabled patch.");
		}
	}
	else
	{
		LogError("Gamedata not found");
	}
	
	delete hGameConf;
	
	HookEvent("post_inventory_application", EventHook_PostInventoryApplication);
}

static void EventHook_PostInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("user"));
	if (client == 0)
		return;
	
	int numWeapons = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
	for (int i = 0; i < numWeapons; i++)
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if (weapon == -1)
			continue;
		
		TF2Attrib_RemoveAll(weapon);
	}
}
