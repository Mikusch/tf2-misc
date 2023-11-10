#include <sourcemod>
#include <tf2_stocks>

public void OnPluginStart()
{
	AddMultiTargetFilter("@random", MultiTargetFilter_TargetRandom, "a random player", false);
}

static bool MultiTargetFilter_TargetRandom(const char[] pattern, ArrayList clients)
{
	ArrayList available = new ArrayList();
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && TF2_GetClientTeam(client) > TFTeam_Spectator)
			available.Push(client);
	}
	
	clients.Push(available.Get(GetRandomInt(0, available.Length - 1)))
	delete available;
	
	return clients.Length > 0;
}
