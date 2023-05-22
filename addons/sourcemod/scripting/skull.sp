#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <cbasenpc>

ConVar sm_skull_speed;

int g_skull = INVALID_ENT_REFERENCE;
int g_skullTarget = -1;

public void OnPluginStart()
{
	sm_skull_speed = CreateConVar("sm_skull_speed", "100", "Speed of the skull.");
	
	HookEvent("teamplay_round_start", EventHook_TeamPlayRoundStart);
	HookEvent("player_death", EventHook_PlayerDeath);
	
	AddCommandListener(CommandListener_Suicide, "kill");
	AddCommandListener(CommandListener_Suicide, "explode");
	AddCommandListener(CommandListener_JoinTeam, "jointeam");
	AddCommandListener(CommandListener_JoinTeam, "spectate");
}

public void OnMapStart()
{
	g_skull = INVALID_ENT_REFERENCE;
	g_skullTarget = -1;
	
	PrecacheSound(")ambient/halloween/bombinomicon_loop.wav");
}

public void OnGameFrame()
{
	if (IsValidEntity(g_skull))
	{
		SkullThink(g_skull);
	}
}

public void OnEntityDestroyed(int entity)
{
	if (entity == EntRefToEntIndex(g_skull))
	{
		StopSound(entity, SNDCHAN_STATIC, ")ambient/halloween/bombinomicon_loop.wav");
	}
}

public void OnClientDisconnect(int client)
{
	// our target left, nothing we can do but to retarget
	if (client == g_skullTarget)
	{
		PrintToChatAll("%N has left the game. The skull is displeased.", client);
		SelectRandomTarget();
	}
}

static void EventHook_TeamPlayRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (GameRules_GetProp("m_bInWaitingForPlayers") && !GameRules_GetProp("m_bPlayingMannVsMachine"))
		return;
	
	CreateSkull();
}

static void EventHook_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	// in arena mode, retarget when a player dies
	if (GameRules_GetProp("m_nGameType") == 4)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		int deathflags = event.GetInt("death_flags");
		
		if (!(deathflags & TF_DEATHFLAG_DEADRINGER) && client == g_skullTarget)
		{
			PrintToChatAll("%N could not take the pressure anymore.", client);
			
			SelectRandomTarget();
		}
	}
}

static Action CommandListener_Suicide(int client, const char[] command, int argc)
{
	if (client == g_skullTarget)
	{
		PrintCenterText(client, "You are being watched. You cannot take the easy way out.");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

static Action CommandListener_JoinTeam(int client, const char[] command, int argc)
{
	bool bSpectate = false;
	
	if (client == g_skullTarget)
	{
		if (StrEqual(command, "jointeam") && argc >= 1)
		{
			char teamName[16];
			GetCmdArg(1, teamName, sizeof(teamName));
			
			if (StrEqual(teamName, "spectate") || StrEqual(teamName, "spectatearena"))
			{
				bSpectate = true;
			}
		}
		else if (StrEqual(command, "spectate"))
		{
			bSpectate = true;
		}
		
		if (bSpectate)
		{
			PrintCenterText(client, "You may not spectate now, for you are the one being spectated.");
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

void CreateSkull()
{
	int skull = CreateEntityByName("prop_dynamic");
	if (IsValidEntity(skull))
	{
		DispatchKeyValue(skull, "model", "models/props_mvm/mvm_human_skull.mdl");
		
		if (DispatchSpawn(skull))
		{
			g_skullTarget = -1;
			g_skull = EntIndexToEntRef(skull);
			
			// create spectator point
			int observer = CreateEntityByName("info_observer_point");
			if (IsValidEntity(observer))
			{
				SetVariantString("!activator");
				if (AcceptEntityInput(observer, "SetParent", skull))
				{
					float origin[3], angles[3];
					GetEntPropVector(skull, Prop_Data, "m_vecAbsOrigin", origin);
					GetEntPropVector(skull, Prop_Data, "m_angAbsRotation", angles);
					
					DispatchKeyValueVector(observer, "origin", origin);
					DispatchKeyValueVector(observer, "angles", angles);
				}
			}
			
			EmitSoundToAll(")ambient/halloween/bombinomicon_loop.wav", skull, SNDCHAN_AUTO);
		}
	}
}

bool SelectRandomTarget()
{
	g_skullTarget = -1;
	
	int[] clients = new int[MaxClients];
	int total = 0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsValidSkullTarget(client))
			continue;
		
		if (g_skullTarget == client)
			continue;
		
		clients[total++] = client;
	}
	
	if (total)
	{
		g_skullTarget = clients[GetRandomInt(0, total - 1)];
		
		PrintToChatAll("Someone is being watched...");
		
		return true;
	}
	
	return false;
}

void SkullThink(int skull)
{
	if (IsValidEntity(g_skullTarget) && IsValidSkullTarget(g_skullTarget))
	{
		float targetOrigin[3];
		CBaseEntity(g_skullTarget).WorldSpaceCenter(targetOrigin);
		
		float skullOrigin[3];
		GetEntPropVector(skull, Prop_Data, "m_vecAbsOrigin", skullOrigin);
		
		float direction[3];
		SubtractVectors(targetOrigin, skullOrigin, direction);
		NormalizeVector(direction, direction);
		
		float angles[3];
		GetVectorAngles(direction, angles);
		
		DispatchKeyValueVector(skull, "angles", angles);
		
		// outside the world? speed it up.
		float speed = TR_PointOutsideWorld(skullOrigin) ? sm_skull_speed.FloatValue * 10.0 : sm_skull_speed.FloatValue;
		ScaleVector(direction, speed * GetGameFrameTime());
		
		float newSkullOrigin[3];
		AddVectors(skullOrigin, direction, newSkullOrigin);
		DispatchKeyValueVector(skull, "origin", newSkullOrigin);
		
		// poor man's Touch()
		TR_TraceRay(skullOrigin, skullOrigin, MASK_SOLID, RayType_EndPoint);
		if (TR_DidHit() && TR_GetEntityIndex() == g_skullTarget)
		{
			PrintToChatAll("%N fell victim to the skull...", g_skullTarget);
			CrashClient(g_skullTarget);
			
			SelectRandomTarget();
		}
	}
	
	// if the round is running and we do not have a target, look for one periodically
	if (!IsValidEntity(g_skullTarget) && GameRules_GetRoundState() >= RoundState_RoundRunning)
	{
		SelectRandomTarget();
	}
}

bool IsValidSkullTarget(int client)
{
	if (!IsClientInGame(client))
		return false;
	
	if (TF2_GetClientTeam(client) <= TFTeam_Spectator)
		return false;
	
	if (!IsPlayerAlive(client))
		return false;
	
	if (TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))
		return false;
	
	return true;
}

void CrashClient(int client)
{
	RemoveEntity(client);
}
