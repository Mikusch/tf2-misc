#include <sdktools>

public void OnPluginStart()
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		
		SetClientViewEntity(i, i);
	}
}
