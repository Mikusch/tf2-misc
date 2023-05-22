#include <sourcemod>
#include <sdktools>

static float g_NextTimescaleTime;

ConVar host_timescale;
ConVar sv_cheats;

float g_currentTimescale = 1.0;

public void OnPluginStart()
{
	host_timescale = FindConVar("host_timescale");
	sv_cheats = FindConVar("sv_cheats");
	
	AddNormalSoundHook(NormalSoundHook);
	AddAmbientSoundHook(AmbientSoundHook);
}

Action NormalSoundHook(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	pitch = Clamp(RoundToNearest(pitch * g_currentTimescale), 0, 255);
	return Plugin_Changed;
}

Action AmbientSoundHook(char sample[PLATFORM_MAX_PATH], int &entity, float &volume, int &level, int &pitch, float pos[3], int &flags, float &delay)
{
	pitch = Clamp(RoundToNearest(pitch * g_currentTimescale), 0, 255);
	return Plugin_Changed;
}

any Min(any a, any b)
{
	return (a <= b) ? a : b;
}

any Max(any a, any b)
{
	return (a >= b) ? a : b;
}

any Clamp(any val, any min, any max)
{
	return Min(Max(val, min), max);
}

public void OnPluginEnd()
{
	EndTimescale();
}

public void OnMapEnd()
{
	EndTimescale();
}

public void OnMapStart()
{
	PrecacheSound("replay/enterperformancemode.wav");
	PrecacheSound("replay/exitperformancemode.wav");
	
	g_currentTimescale = 1.0;
	g_NextTimescaleTime = GetGameTime();
}

public void OnGameFrame()
{
	if (GameRules_GetProp("m_bInWaitingForPlayers"))
		return;
	
	if (g_NextTimescaleTime != 0.0 && g_NextTimescaleTime <= GetGameTime())
	{
		if (GetRandomInt(0, 1) == 0)
		{
			g_currentTimescale = GetRandomFloat(0.2, 1.0);
		}
		else
		{
			g_currentTimescale = GetRandomFloat(1.0, 5.0);
		}
		
		g_NextTimescaleTime = GetGameTime() + (30.0 * g_currentTimescale);
		
		SetTimeScale(g_currentTimescale);
	}
}

void SetTimeScale(float value)
{
	if (value < 0.0)
	{
		EmitSoundToAll("replay/enterperformancemode.wav", _, SNDCHAN_STATIC);
	}
	else
	{
		EmitSoundToAll("replay/exitperformancemode.wav", _, SNDCHAN_STATIC);
	}
	
	PrintCenterTextAll("The game now runs at %0.f%% speed.", value * 100.0);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (IsFakeClient(client))
		{
			SetFakeClientConVar(client, "sv_cheats", "1");
		}
		else
		{
			sv_cheats.ReplicateToClient(client, "1");
		}
	}
	
	host_timescale.FloatValue = value;
}

void EndTimescale()
{
	for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client))
			{
				if (IsFakeClient(client))
				{
					SetFakeClientConVar(client, "sv_cheats", "0");
				}
				else
				{
					sv_cheats.ReplicateToClient(client, "0");
				}
			}
		}
	
	host_timescale.RestoreDefault();
}
