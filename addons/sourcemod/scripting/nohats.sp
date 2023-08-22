#include <sourcemod>
#include <tf_econ_data>
#include <tf2>
#include <tf2utils>

enum
{
	LOADOUT_POSITION_INVALID = -1,
	
	// Weapons & Equipment
	LOADOUT_POSITION_PRIMARY = 0,
	LOADOUT_POSITION_SECONDARY,
	LOADOUT_POSITION_MELEE,
	LOADOUT_POSITION_UTILITY,
	LOADOUT_POSITION_BUILDING,
	LOADOUT_POSITION_PDA,
	LOADOUT_POSITION_PDA2,
	
	// Wearables. If you add new wearable slots, make sure you add them to IsWearableSlot() below this.
	LOADOUT_POSITION_HEAD,
	LOADOUT_POSITION_MISC,
	
	// other
	LOADOUT_POSITION_ACTION,
	
	// More wearables, yay!
	LOADOUT_POSITION_MISC2,
	
	// taunts
	LOADOUT_POSITION_TAUNT,
	LOADOUT_POSITION_TAUNT2,
	LOADOUT_POSITION_TAUNT3,
	LOADOUT_POSITION_TAUNT4,
	LOADOUT_POSITION_TAUNT5,
	LOADOUT_POSITION_TAUNT6,
	LOADOUT_POSITION_TAUNT7,
	LOADOUT_POSITION_TAUNT8,
	
	CLASS_LOADOUT_POSITION_COUNT,
};

bool IsWearableSlot(int iSlot)
{
	return iSlot == LOADOUT_POSITION_HEAD
		|| iSlot == LOADOUT_POSITION_MISC
		//|| iSlot == LOADOUT_POSITION_ACTION
		|| IsMiscSlot(iSlot)
		|| IsTauntSlot(iSlot);
}

bool IsMiscSlot(int iSlot)
{
	return iSlot == LOADOUT_POSITION_MISC
		|| iSlot == LOADOUT_POSITION_MISC2
		|| iSlot == LOADOUT_POSITION_HEAD;
}

bool IsTauntSlot(int iSlot)
{
	return iSlot == LOADOUT_POSITION_TAUNT
		|| iSlot == LOADOUT_POSITION_TAUNT2
		|| iSlot == LOADOUT_POSITION_TAUNT3
		|| iSlot == LOADOUT_POSITION_TAUNT4
		|| iSlot == LOADOUT_POSITION_TAUNT5
		|| iSlot == LOADOUT_POSITION_TAUNT6
		|| iSlot == LOADOUT_POSITION_TAUNT7
		|| iSlot == LOADOUT_POSITION_TAUNT8;
}

public Plugin myinfo =
{
	name = "No Hats",
	author = "Mikusch",
	description = "Removes all cosmetics.",
	version = "1.0.0",
	url = "https://github.com/Mikusch"
}

public void OnPluginStart()
{
	HookEvent("post_inventory_application", EventHook_PostInventoryApplication);
}

void EventHook_PostInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	for (int i = TF2Util_GetPlayerWearableCount(client) - 1; i >= 0; --i)
	{
		int wearable = TF2Util_GetPlayerWearable(client, i);
		if (wearable == -1)
			continue;
		
		int iItemDefinitionIndex = GetEntProp(wearable, Prop_Send, "m_iItemDefinitionIndex");
		int iSlot = TF2Econ_GetItemLoadoutSlot(iItemDefinitionIndex, TF2_GetPlayerClass(client));
		
		if (IsWearableSlot(iSlot))
			TF2_RemoveWearable(client, wearable);
	}
}
