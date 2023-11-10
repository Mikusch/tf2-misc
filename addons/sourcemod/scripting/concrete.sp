#include <sdktools>

bool g_bPlayingScrapeSound[MAXPLAYERS + 1];

#define SOUND ")physics/concrete/concrete_scrape_smooth_loop1.wav"

public void OnMapStart()
{
	PrecacheSound(SOUND);
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	bool bMovingMouse = mouse[0] != 0 || mouse[1] != 0;
	
	if (!g_bPlayingScrapeSound[client] && bMovingMouse)
	{
		g_bPlayingScrapeSound[client] = true;
		EmitSoundToAll(SOUND, client);
	}
	else if (!bMovingMouse)
	{
		g_bPlayingScrapeSound[client] = false;
		StopSound(client, SNDCHAN_AUTO, SOUND);
	}
}
