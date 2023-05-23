#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <cbasenpc>

enum struct SkullData
{
	int entindex;
	int m_target;
}

ArrayList g_skulls;

ConVar sm_skull_speed;
ConVar sm_skull_count;
ConVar sm_skull_delete_self_on_contact;

public void OnPluginStart()
{
	g_skulls = new ArrayList(sizeof(SkullData));
	
	sm_skull_speed = CreateConVar("sm_skull_speed", "100", "Speed of the skull.");
	sm_skull_count = CreateConVar("sm_skull_count", "1", "Amount of skulls to spawn on round start.");
	sm_skull_delete_self_on_contact = CreateConVar("sm_skull_delete_self_on_contact", "0", "Whether the skull should delete itself on contact.");
	
	HookEvent("teamplay_round_start", EventHook_TeamPlayRoundStart);
	HookEvent("player_death", EventHook_PlayerDeath);
	
	AddCommandListener(CommandListener_Suicide, "kill");
	AddCommandListener(CommandListener_Suicide, "explode");
	AddCommandListener(CommandListener_JoinTeam, "jointeam");
	AddCommandListener(CommandListener_JoinTeam, "spectate");
}

public void OnMapStart()
{
	g_skulls.Clear();
	
	PrecacheSound(")ambient/halloween/bombinomicon_loop.wav");
}

public void OnGameFrame()
{
	for (int i = 0; i < g_skulls.Length; i++)
	{
		SkullData data;
		if (g_skulls.GetArray(i, data))
		{
			if (IsValidEntity(data.entindex))
			{
				SkullThink(i, data);
			}
		}
	}
}

public void OnEntityDestroyed(int entity)
{
	int index = g_skulls.FindValue(entity, SkullData::entindex);
	if (index != -1)
	{
		StopSound(entity, SNDCHAN_AUTO, ")ambient/halloween/bombinomicon_loop.wav");
		g_skulls.Erase(index);
	}
}

public void OnClientDisconnect(int client)
{
	// our target left, nothing we can do but to retarget
	int index = g_skulls.FindValue(client, SkullData::m_target);
	if (index != -1)
	{
		PrintToChatAll("%N has left the game. The skull is displeased.", client);
		SelectRandomTarget(index);
	}
}

static void EventHook_TeamPlayRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (GameRules_GetProp("m_bInWaitingForPlayers") && !GameRules_GetProp("m_bPlayingMannVsMachine"))
		return;
	
	for (int i = 0; i < sm_skull_count.IntValue; i++)
	{
		CreateSkull();
	}
}

static void EventHook_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	// in arena mode, retarget when a player dies
	if (GameRules_GetProp("m_nGameType") == 4)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		int deathflags = event.GetInt("death_flags");
		
		if (g_skulls.FindValue(client, SkullData::m_target) != -1)
		{
			int index = g_skulls.FindValue(client, SkullData::m_target);
			if (!(deathflags & TF_DEATHFLAG_DEADRINGER) && index != -1)
			{
				PrintToChatAll("%N could not take the pressure anymore.", client);
				
				SelectRandomTarget(index);
			}
		}
	}
}

static Action CommandListener_Suicide(int client, const char[] command, int argc)
{
	if (g_skulls.FindValue(client, SkullData::m_target) != -1)
	{
		PrintCenterText(client, "You are being watched. You cannot take the easy way out.");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

static Action CommandListener_JoinTeam(int client, const char[] command, int argc)
{
	bool bSpectate = false;
	
	if (g_skulls.FindValue(client, SkullData::m_target) != -1)
	{
		if (StrEqual(command, "jointeam") && argc >= 1)
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
		else if (StrEqual(command, "spectate"))
		{
			bSpectate = true;
		}
	}
	
	if (bSpectate)
	{
		PrintCenterText(client, "You may not spectate now, for you are the one being spectated.");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

void CreateSkull()
{
	SkullData data;
	
	int skull = CreateEntityByName("prop_dynamic");
	if (IsValidEntity(skull))
	{
		DispatchKeyValue(skull, "model", "models/props_mvm/mvm_human_skull.mdl");
		
		float worldMins[3], worldMaxs[3];
		GetEntPropVector(0, Prop_Data, "m_WorldMins", worldMins);
		GetEntPropVector(0, Prop_Data, "m_WorldMaxs", worldMaxs);
		
		float origin[3];
		origin[0] = GetRandomFloat(worldMins[0], worldMaxs[0]); origin[1] = GetRandomFloat(worldMins[1], worldMaxs[1]); origin[2] = GetRandomFloat(worldMins[2], worldMaxs[2]);
		DispatchKeyValueVector(skull, "origin", origin);
		
		float angles[3];
		angles[0] = GetRandomFloat(0.0, 360.0); angles[1] = GetRandomFloat(0.0, 360.0); angles[2] = GetRandomFloat(0.0, 360.0);
		DispatchKeyValueVector(skull, "angles", angles);
		
		if (DispatchSpawn(skull))
		{
			// create spectator point
			int observer = CreateEntityByName("info_observer_point");
			if (IsValidEntity(observer))
			{
				SetVariantString("!activator");
				if (AcceptEntityInput(observer, "SetParent", skull))
				{
					DispatchKeyValueVector(observer, "origin", origin);
					DispatchKeyValueVector(observer, "angles", angles);
				}
			}
			
			EmitSoundToAll(")ambient/halloween/bombinomicon_loop.wav", skull);
			
			data.entindex = skull;
			data.m_target = -1;
			g_skulls.PushArray(data);
		}
	}
}

bool SelectRandomTarget(int index)
{
	g_skulls.Set(index, -1, SkullData::m_target);
	
	int[] clients = new int[MaxClients];
	int total = 0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsValidSkullTarget(client))
			continue;
		
		if (g_skulls.FindValue(client, SkullData::m_target) != -1)
			continue;
		
		clients[total++] = client;
	}
	
	if (total)
	{
		g_skulls.Set(index, clients[GetRandomInt(0, total - 1)], SkullData::m_target);
		
		PrintToChatAll("Someone is being watched...");
		
		return true;
	}
	
	return false;
}

void SkullThink(int index, SkullData data)
{
	if (IsValidEntity(data.m_target) && IsValidSkullTarget(data.m_target))
	{
		float targetOrigin[3];
		CBaseEntity(data.m_target).WorldSpaceCenter(targetOrigin);
		
		float skullOrigin[3];
		GetEntPropVector(data.entindex, Prop_Data, "m_vecAbsOrigin", skullOrigin);
		
		float direction[3];
		SubtractVectors(targetOrigin, skullOrigin, direction);
		NormalizeVector(direction, direction);
		
		float angles[3];
		GetVectorAngles(direction, angles);
		
		DispatchKeyValueVector(data.entindex, "angles", angles);
		
		// outside the world? speed it up.
		float speed = TR_PointOutsideWorld(skullOrigin) ? sm_skull_speed.FloatValue * 10.0 : sm_skull_speed.FloatValue;
		ScaleVector(direction, speed * GetGameFrameTime());
		
		float newSkullOrigin[3];
		AddVectors(skullOrigin, direction, newSkullOrigin);
		DispatchKeyValueVector(data.entindex, "origin", newSkullOrigin);
		
		// poor man's Touch()
		TR_TraceRay(skullOrigin, skullOrigin, MASK_SOLID, RayType_EndPoint);
		if (TR_DidHit() && TR_GetEntityIndex() == data.m_target)
		{
			PrintToChatAll("%N fell victim to the skull...", data.m_target);
			CrashClient(data.m_target);
			
			if (sm_skull_delete_self_on_contact.BoolValue)
			{
				RemoveEntity(data.entindex);
			}
			else
			{
				SelectRandomTarget(index);
			}
		}
	}
	
	// if the round is running and we do not have a target, look for one periodically
	if (!IsValidEntity(data.m_target) && GameRules_GetRoundState() >= RoundState_RoundRunning)
	{
		SelectRandomTarget(index);
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
