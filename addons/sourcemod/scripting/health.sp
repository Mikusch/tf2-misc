#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

static Handle g_SDKCall_CTFPowerup_DropSingleInstance;

public void OnPluginStart()
{
	GameData gamedata = new GameData("health");
	g_SDKCall_CTFPowerup_DropSingleInstance = PrepSDKCall_CTFPowerup_DropSingleInstance(gamedata);
	delete gamedata;
	
	RegAdminCmd("dropeverything", ConCmd_DropEverything, ADMFLAG_CHEATS);
}

char items[][] =
{
	"item_healthkit_small",
	"item_healthkit_medium",
	"item_healthkit_full",
	"item_ammopack_small",
	"item_ammopack_medium",
	"item_ammopack_full",
	"item_currencypack_small",
	"item_currencypack_medium",
	"item_currencypack_large",
	"tf_spell_pickup",
	"item_powerup_rune",
	"item_powerup_crit",
	"item_powerup_uber",
}

Action ConCmd_DropEverything(int client, int args)
{
	float origin[3];
	GetClientAbsOrigin(client, origin);
	
	for (int i = 0; i < 100; i++)
	{
		int entity = CreateEntityByName(items[GetRandomInt(0, sizeof(items) - 1)]);
		if (!IsValidEntity(entity))
			return Plugin_Handled;
		
		DispatchSpawn(entity);
		TeleportEntity(entity, origin);
		
		float vecLaunchVel[3];
		vecLaunchVel[0] = GetRandomFloat(-500.0, 500.0);
		vecLaunchVel[1] = GetRandomFloat(-500.0, 500.0);
		vecLaunchVel[2] = GetRandomFloat(1000.0, 1500.0);
		
		SDKCall_CTFPowerup_DropSingleInstance(entity, vecLaunchVel, client, 0.3);
	}
	
	return Plugin_Handled;
}

static Handle PrepSDKCall_CTFPowerup_DropSingleInstance(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPowerup::DropSingleInstance");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_ByValue);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFPowerup::DropSingleInstance");
	
	return call;
}

void SDKCall_CTFPowerup_DropSingleInstance(int entity, const float vecLaunchVel[3], int thrower, float flThrowerTouchDelay, float flResetTime = 0.0)
{
	if (g_SDKCall_CTFPowerup_DropSingleInstance)
	{
		SDKCall(g_SDKCall_CTFPowerup_DropSingleInstance, entity, vecLaunchVel, thrower, flThrowerTouchDelay, flResetTime);
	}
}
