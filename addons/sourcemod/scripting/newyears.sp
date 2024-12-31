#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define SECONDS_IN_YEAR			(365 * 24 * 3600)
#define SECONDS_IN_LEAP_YEAR	(366 * 24 * 3600)

enum ParticleAttachment_t
{
	PATTACH_ABSORIGIN = 0,			// Create at absorigin, but don't follow
	PATTACH_ABSORIGIN_FOLLOW,		// Create at absorigin, and update to follow the entity
	PATTACH_CUSTOMORIGIN,			// Create at a custom origin, but don't follow
	PATTACH_POINT,					// Create on attachment point, but don't follow
	PATTACH_POINT_FOLLOW,			// Create on attachment point, and update to follow the entity

	PATTACH_WORLDORIGIN,			// Used for control points that don't attach to an entity

	PATTACH_ROOTBONE_FOLLOW,		// Create at the root bone of the entity, and update to follow

	MAX_PATTACH_TYPES,
};

static const int g_aTzOffsets[] = { -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 };
static const char g_aTzNames[][] =
{
	"UTC-12 (Baker Island Time)",
	"UTC-11 (Niue Time)",
	"UTC-10 (Hawaii-Aleutian Standard Time)",
	"UTC-9 (Alaska Standard Time)",
	"UTC-8 (Pacific Standard Time)",
	"UTC-7 (Mountain Standard Time)",
	"UTC-6 (Central Standard Time)",
	"UTC-5 (Eastern Standard Time)",
	"UTC-4 (Atlantic Standard Time)",
	"UTC-3 (Argentina Time)",
	"UTC-2 (South Georgia Islands Time)",
	"UTC-1 (Cape Verde Time)",
	"UTC (Greenwich Mean Time)",
	"UTC+1 (Central European Time)",
	"UTC+2 (Eastern European Time)",
	"UTC+3 (Moscow Standard Time)",
	"UTC+4 (Azerbaijan Standard Time)",
	"UTC+5 (Pakistan Standard Time)",
	"UTC+6 (Bangladesh Standard Time)",
	"UTC+7 (Indochina Time)",
	"UTC+8 (China Standard Time)",
	"UTC+9 (Japan Standard Time)",
	"UTC+10 (Australian Eastern Standard Time)",
	"UTC+11 (Solomon Islands Time)",
	"UTC+12 (Fiji Time)"
};

static int s_iStringTableParticleEffectNames = INVALID_STRING_TABLE;
static Handle g_hHudSync;

public void OnPluginStart()
{
	g_hHudSync = CreateHudSynchronizer();
	
	CreateTimer(1.0, CountdownTimer, _, TIMER_REPEAT);
}

static void CountdownTimer(Handle timer)
{
	int iUnixTime = GetTime();
	
	for (int i = 0; i < sizeof(g_aTzOffsets); i++)
	{
		int iTzOffsetSeconds = g_aTzOffsets[i] * 3600;
		int iTzTime = iUnixTime + iTzOffsetSeconds;
		
		int iSecondsLeft = GetSecondsUntilNewYear(iTzTime);
		if (iSecondsLeft <= 60)
		{
			LogMessage("Countdown in %s: %d", g_aTzNames[i], iSecondsLeft);
			
			if (iSecondsLeft == 45)
			{
				EmitGameSoundToAll("RD.FinaleMusic");
			}
			
			if (iSecondsLeft == 0)
			{
				SetHudTextParamsEx(-1.0, -1.0, 30.0, { 136, 71, 255, 255 }, { 255, 255, 255, 255 }, 2);
				
				for (int client = 1; client <= MaxClients; client++)
				{
					if (!IsClientInGame(client))
						continue;
					
					ShowSyncHudText(client, g_hHudSync, "Happy New Year in %s!", g_aTzNames[i]);
					
					float vecOrigin[3], angRotation[3];
					GetClientAbsOrigin(client, vecOrigin);
					GetClientAbsAngles(client, angRotation);
					
					char szParticleName[32];
					if (Format(szParticleName, sizeof(szParticleName), "utaunt_firework_teamcolor_%s", TF2_GetClientTeam(client) == TFTeam_Red ? "red" : "blue"))
						TE_TFParticleEffect(szParticleName, vecOrigin, angRotation);
					
					EmitGameSoundToAll("Summer.Fireworks", client);
					FakeClientCommand(client, "taunt");
				}
			}
			else
			{
				SetHudTextParams(-1.0, -1.0, 1.0, 255, 255, 255, 255, 0, 0.0, 0.0);
				
				char szSound[32];
				if (Format(szSound, sizeof(szSound), "Announcer.RoundEnds%dseconds", iSecondsLeft) && PrecacheScriptSound(szSound))
					EmitGameSoundToAll(szSound);
				
				for (int client = 1; client <= MaxClients; client++)
				{
					if (!IsClientInGame(client))
						continue;
					
					ShowSyncHudText(client, g_hHudSync, "████ %s ████ \n▒▒▒▒ %d ▒▒▒▒", g_aTzNames[i], iSecondsLeft);
				}
			}
		}
	}
}

bool IsLeapYear(int iYear)
{
	return (iYear % 4 == 0 && (iYear % 100 != 0 || iYear % 400 == 0));
}

int GetSecondsUntilNewYear(int iUnixTime)
{
	int iYear = 1970;
	int iSecondsInYear;
	
	while (iUnixTime > 0)
	{
		// Check for leap years
		if (IsLeapYear(iYear))
		{
			iSecondsInYear = SECONDS_IN_LEAP_YEAR;
		}
		else
		{
			iSecondsInYear = SECONDS_IN_YEAR;
		}
		
		iUnixTime -= iSecondsInYear;
		iYear++;
	}
	
	return (iUnixTime * -1);
}

static int GetParticleSystemIndex(const char[] szParticleSystemName)
{
	if (szParticleSystemName[0])
	{
		if (s_iStringTableParticleEffectNames == INVALID_STRING_TABLE)
		{
			if ((s_iStringTableParticleEffectNames = FindStringTable("ParticleEffectNames")) == INVALID_STRING_TABLE)
			{
				LogError("Missing string table 'ParticleEffectNames'");
				return INVALID_STRING_INDEX;
			}
		}
		
		int nIndex = FindStringIndex(s_iStringTableParticleEffectNames, szParticleSystemName);
		if (nIndex == INVALID_STRING_INDEX)
		{
			LogError("Missing precache for particle system '%s'", szParticleSystemName);
			return 0;
		}
		
		return nIndex;
		
	}
	
	return 0;
}

void TE_TFParticleEffect(const char[] szParticleName, float vecOrigin[3], float vecAngles[3], int entity = -1, ParticleAttachment_t eAttachType = PATTACH_CUSTOMORIGIN, float vecStart[3] = NULL_VECTOR)
{
	TE_Start("TFParticleEffect");
	
	TE_WriteNum("m_iParticleSystemIndex", GetParticleSystemIndex(szParticleName));
	TE_WriteFloat("m_vecOrigin[0]", vecOrigin[0]);
	TE_WriteFloat("m_vecOrigin[1]", vecOrigin[1]);
	TE_WriteFloat("m_vecOrigin[2]", vecOrigin[2]);
	TE_WriteVector("m_vecAngles", vecAngles);
	TE_WriteFloat("m_vecStart[0]", vecStart[0]);
	TE_WriteFloat("m_vecStart[1]", vecStart[1]);
	TE_WriteFloat("m_vecStart[2]", vecStart[2]);
	
	if (IsValidEntity(entity))
	{
		TE_WriteNum("entindex", entity);
		TE_WriteNum("m_iAttachType", view_as<int>(eAttachType));
	}
	
	TE_SendToAll();
}
