/**
 * ============================================================================
 * SF2 Sub Plugin: Proxy Spawn Unstuck Fix
 * ============================================================================
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <cbasenpc>
#include <cbasenpc/util>

#define SF2
#include <sf2>

#define SF2PROXYUNSTUCK_PLUGIN_VERSION "1.0.0"

#define TFTeam_Red 2

// ---------------------------------------------------------------------------
// ConVars
// ---------------------------------------------------------------------------
ConVar g_cvEnabled;
ConVar g_cvDebug;

public Plugin myinfo =
{
	name = "SF2 Sub Plugin - Proxy Spawn Unstuck Fix",
	author = "Paste",
	description = "Detects and fixes proxies spawning stuck inside world geometry.",
	version = SF2PROXYUNSTUCK_PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	g_cvEnabled = CreateConVar("sf2_proxy_unstuck_enabled", "1", "Enable/disable the proxy spawn unstuck fix.", _, true, 0.0, true, 1.0);
	g_cvDebug   = CreateConVar("sf2_proxy_unstuck_debug", "0", "Log to server console every time a stuck proxy is detected or fixed, and how.", _, true, 0.0, true, 1.0);
	AutoExecConfig(true, "sf2_proxy_unstuck");
}

// ---------------------------------------------------------------------------
// SF2 forwards
// ---------------------------------------------------------------------------
public void SF2_OnClientSpawnedAsProxy(int client)
{
	if (!g_cvEnabled.BoolValue || !IsValidClient(client))
	{
		return;
	}

	RequestFrame(Frame_CheckProxyStuck, GetClientUserId(client));
}

public void Frame_CheckProxyStuck(any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client))
	{
		return;
	}

	if (!IsPlayerStuck(client))
	{
		return; // spawned clean, nothing to do
	}

	float origin[3];
	GetClientAbsOrigin(client, origin);

	float fixedPos[3];
	if (FindNearbyClearSpot(client, origin, fixedPos))
	{
		TeleportEntity(client, fixedPos, NULL_VECTOR, NULL_VECTOR);
		if (g_cvDebug.BoolValue)
		{
			LogMessage("[Proxy Unstuck] Client %N spawned stuck as a proxy, moved to nearby clear spot.", client);
		}
		return;
	}

	if (TeleportToRedSpawn(client))
	{
		if (g_cvDebug.BoolValue)
		{
			LogMessage("[Proxy Unstuck] Client %N spawned stuck as a proxy, no clear spot found nearby, fell back to a RED spawn point.", client);
		}
	}
	else
	{
		LogError("[Proxy Unstuck] Client %N spawned stuck as a proxy and no fix could be applied (no clear spot found, and no RED info_player_teamspawn on this map to fall back to).", client);
	}
}

// ---------------------------------------------------------------------------
// Stuck detection
// ---------------------------------------------------------------------------
bool IsPlayerStuck(int client)
{
	float pos[3], mins[3], maxs[3];
	GetClientAbsOrigin(client, pos);
	GetEntPropVector(client, Prop_Data, "m_vecMins", mins);
	GetEntPropVector(client, Prop_Data, "m_vecMaxs", maxs);

	TR_TraceHullFilter(pos, pos, mins, maxs, MASK_PLAYERSOLID, Filter_IgnorePlayers, client);
	return TR_StartSolid();
}

public bool Filter_IgnorePlayers(int entity, int contentsMask, any data)
{
	return entity != data && (entity < 1 || entity > MaxClients);
}

bool TestPositionClear(const float pos[3], const float mins[3], const float maxs[3], int client)
{
	TR_TraceHullFilter(pos, pos, mins, maxs, MASK_PLAYERSOLID, Filter_IgnorePlayers, client);
	return !TR_StartSolid();
}

// ---------------------------------------------------------------------------
// Search for the nearest clear spot
// ---------------------------------------------------------------------------
bool FindNearbyClearSpot(int client, const float origin[3], float outPos[3])
{
	float mins[3], maxs[3];
	GetEntPropVector(client, Prop_Data, "m_vecMins", mins);
	GetEntPropVector(client, Prop_Data, "m_vecMaxs", maxs);

	float candidate[3];

	for (int upStep = 0; upStep <= 4; upStep++)
	{
		candidate = origin;
		candidate[2] += upStep * 16.0;
		if (TestPositionClear(candidate, mins, maxs, client))
		{
			outPos = candidate;
			return true;
		}
	}

	float radii[] = { 16.0, 32.0, 48.0, 64.0, 96.0, 128.0, 192.0 };
	for (int r = 0; r < sizeof(radii); r++)
	{
		for (int a = 0; a < 16; a++)
		{
			float angle = a * (360.0 / 16.0);
			candidate[0] = origin[0] + radii[r] * Cosine(DegToRad(angle));
			candidate[1] = origin[1] + radii[r] * Sine(DegToRad(angle));
			candidate[2] = origin[2];
			if (TestPositionClear(candidate, mins, maxs, client))
			{
				outPos = candidate;
				return true;
			}
		}
	}

	return false;
}

// ---------------------------------------------------------------------------
// Last resort fallback, a random RED info_player_teamspawn.
// ---------------------------------------------------------------------------
bool TeleportToRedSpawn(int client)
{
	int[] spawns = new int[64];
	int count = 0;
	int ent = -1;

	while ((ent = FindEntityByClassname(ent, "info_player_teamspawn")) != -1 && count < 64)
	{
		if (GetEntProp(ent, Prop_Data, "m_iTeamNum") == TFTeam_Red)
		{
			spawns[count++] = ent;
		}
	}

	if (count == 0)
	{
		return false;
	}

	int chosen = spawns[GetRandomInt(0, count - 1)];
	float pos[3], ang[3];
	GetEntPropVector(chosen, Prop_Data, "m_vecAbsOrigin", pos);
	GetEntPropVector(chosen, Prop_Data, "m_angAbsRotation", ang);
	pos[2] += 16.0; // small lift to avoid clipping the ground on arrival

	TeleportEntity(client, pos, ang, NULL_VECTOR);
	return true;
}

// ---------------------------------------------------------------------------
// Utility stocks
// ---------------------------------------------------------------------------
bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}
