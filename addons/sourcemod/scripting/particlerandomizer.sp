#include <sourcemod>
#include <dhooks>

#pragma semicolon 1
#pragma newdecls required

static int g_ParticleEffectNamesTable;

public Plugin myinfo = 
{
	name = "Particle Randomizer",
	author = "Mikusch",
	description = "",
	version = "1.0.0",
	url = "https://github.com/Mikusch"
};

public void OnPluginStart()
{
	g_ParticleEffectNamesTable = FindStringTable("ParticleEffectNames");
	
	GameData gamedata = new GameData("particlerandomizer");
	if (gamedata == null)
		SetFailState("Could not find particlerandomizer gamedata");
	
	DynamicDetour.FromConf(gamedata, "GetParticleSystemIndex").Enable(Hook_Pre, DHookCallback_GetParticleSystemIndex_Pre);
}

public MRESReturn DHookCallback_GetParticleSystemIndex_Pre(DHookReturn ret, DHookParam param)
{
	int num = GetStringTableNumStrings(g_ParticleEffectNamesTable);
	int index = GetRandomInt(0, num);
	
	ret.Value = index;
	return MRES_Supercede;
}
