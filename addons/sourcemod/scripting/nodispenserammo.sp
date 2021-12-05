#include <sourcemod>
#include <dhooks>

#pragma semicolon 1
#pragma newdecls required

static DynamicHook g_DHookDispenseAmmo;

public Plugin myinfo = 
{
	name = "No Dispenser Ammo", 
	author = "Mikusch", 
	description = "Disallows ammo gain from dispensers", 
	version = "1.0.0", 
	url = "https://github.com/Mikusch"
};

public void OnPluginStart()
{
	GameData gamedata = new GameData("nodispenserammo");
	if (gamedata == null)
		SetFailState("Could not find nodispenserammo gamedata");
	
	g_DHookDispenseAmmo = DynamicHook.FromConf(gamedata, "CObjectDispenser::DispenseAmmo");
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "obj_dispenser") || StrEqual(classname, "mapobj_cart_dispenser"))
	{
		g_DHookDispenseAmmo.HookEntity(Hook_Pre, entity, DispenseAmmoPre);
	}
}

public MRESReturn DispenseAmmoPre(int dispenser, DHookReturn ret, DHookParam param)
{
	ret.Value = false;
	return MRES_Supercede;
}
