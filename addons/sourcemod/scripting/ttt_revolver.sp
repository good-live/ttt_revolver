#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "good_live"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <ttt>
#include <ttt_shop>
#include <sdkhooks>
#include <cstrike>
#include <multicolors>

public Plugin myinfo = 
{
	name = "ttt_revolver",
	author = PLUGIN_AUTHOR,
	description = "Allows Detectives to buy a one shot Revolver",
	version = PLUGIN_VERSION,
	url = "painlessgaming.eu"
};

ConVar g_cRevolver_price;
ConVar g_cRevolver_name;
ConVar g_cRevolver_shots;
bool g_bHasRevolver[MAXPLAYERS + 1] = { false, ... };

public void OnPluginStart()
{
	g_cRevolver_price = CreateConVar("ttt_revolver_price", "6000", "The price of the revolver");
	g_cRevolver_name = CreateConVar("ttt_revolver_name", "Revolver","The name of the revolver");
	g_cRevolver_shots = CreateConVar("ttt_revolver_shots", "1", "The amount of shots that the revolver should have");
	TTT_IsGameCSGO();
	
	AutoExecConfig();
	LoadTranslations("revolver.phrases");
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

public void OnAllPluginsLoaded()
{
	char sName[64];
	g_cRevolver_name.GetString(sName, sizeof(sName));
	TTT_RegisterCustomItem("revolver", sName, g_cRevolver_price.IntValue, TTT_TEAM_DETECTIVE);
}

public Action TTT_OnItemPurchased(int client, const char[] itemshort)
{
	if(TTT_IsClientValid(client) && IsPlayerAlive(client))
	{
		if(strcmp(itemshort, "revolver", false) == 0)
		{
			if (TTT_GetClientRole(client) != TTT_TEAM_DETECTIVE)
				return Plugin_Stop;

			if (GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) != -1)
				SDKHooks_DropWeapon(client, GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY));

			int iRevolver = GivePlayerItem(client, "weapon_revolver");
			if(iRevolver != -1){
				EquipPlayerWeapon(client, iRevolver);
				SetEntProp(iRevolver, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
				SetEntProp(iRevolver, Prop_Send, "m_iClip1", g_cRevolver_shots.IntValue);
			}else{
				TTT_SetClientCredits(client, TTT_GetClientCredits(client) + 6000);
			}

			g_bHasRevolver[client] = true;
		}
	}
	return Plugin_Continue;
}

public Action OnTakeDamageAlive(int iVictim, int &iAttacker, int &inflictor, float &damage, int &damagetype)
{
	CPrintToChatAll("Checki");
	if(!TTT_IsRoundActive())
		return Plugin_Continue;

	if(!TTT_IsClientValid(iVictim) || !TTT_IsClientValid(iAttacker))
		return Plugin_Continue;
	
	if(g_bHasRevolver[iAttacker])
	{
		if(HasPlayerRevolver(iAttacker))
		{
			g_bHasRevolver[iAttacker] = false;
			if(TTT_GetClientRole(iVictim) != TTT_TEAM_TRAITOR){
				ForcePlayerSuicide(iAttacker);
				CPrintToChatAll("%t", "Detective_Suicide");
				damage = 0.0;
				return Plugin_Changed;
			}
			damage = float(GetClientHealth(iVictim) + GetClientArmor(iVictim));
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public bool HasPlayerRevolver(iClient)
{
    int iWeapon = GetPlayerWeaponSlot(iClient, 1);
    char sWeapon[64];
    GetClientWeapon(iClient, sWeapon, sizeof(sWeapon));
    if(((iWeapon == -1) ? false : (GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex") == 64)) && strcmp(sWeapon, "weapon_deagle", false) == 0)
    	return true;
    return false;
}  

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	ResetRevolver();
	return Plugin_Continue;
}

public Action TTT_OnRoundStart_Pre()
{
	ResetRevolver();
	return Plugin_Continue;
}

public void TTT_OnRoundStartFailed(int p, int r, int d)
{
	ResetRevolver();
}

public void TTT_OnRoundStart(int i, int t, int d)
{
	ResetRevolver();
}

public void TTT_OnClientDeath(int v, int a)
{
	g_bHasRevolver[v] = false;
}

void ResetRevolver()
{
	LoopValidClients(i){
		g_bHasRevolver[i] = false;
	}
}
