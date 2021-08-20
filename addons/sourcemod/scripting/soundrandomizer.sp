#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

static int g_SoundPrecacheTable;

public Plugin myinfo = 
{
	name = "Sound Randomizer", 
	author = "Mikusch", 
	description = "", 
	version = "1.0.0", 
	url = "https://github.com/Mikusch"
};

public void OnPluginStart()
{
	g_SoundPrecacheTable = FindStringTable("soundprecache");
	
	AddNormalSoundHook(NormalSoundHook);
}

public Action NormalSoundHook(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	int num = GetStringTableNumStrings(g_SoundPrecacheTable);
	int index = GetRandomInt(0, num);
	
	char sound[PLATFORM_MAX_PATH];
	ReadStringTable(g_SoundPrecacheTable, index, sound, PLATFORM_MAX_PATH);
	
	strcopy(sample, sizeof(sample), sound);
	return Plugin_Changed;
}
