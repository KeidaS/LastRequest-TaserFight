#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <lastrequest>
#include <hosties>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "LastRequest - Taser Fight",
	author = "KeidaS",
	description = "Taser fight for !lr plugin",
	version = "1.0",
	url = "www.hermandadfenix.es"
};

new lrId;
new prisoner;
new guard;

bool isOnTaser[MAXPLAYERS + 1] = false;
bool lrActive = false;

public void OnConfigsExecuted() {
	static bool:addedCustomLr = false;
	if (!addedCustomLr) {
		lrId = AddLastRequestToList(LrStart, LrStop, "Taser Fight", true);
		addedCustomLr = true;
	}
}


public LrStart(Handle:array, LrNumber) {
	new lrType = GetArrayCell(array, LrNumber, _:Block_LRType);
	if (lrType == lrId) {
		char namePrisoner[64];
		char nameGuard[64];
		prisoner = GetArrayCell(array, LrNumber, _:Block_Prisoner);
		guard = GetArrayCell(array, LrNumber, _:Block_Guard);
		
		isOnTaser[prisoner] = true;
		isOnTaser[guard] = true;
		
		RemoveWeapons(prisoner);
		RemoveWeapons(guard);
		
		GivePlayerItem(prisoner, "weapon_taser");
		GivePlayerItem(guard, "weapon_taser");
		
		HookEvent("weapon_fire", Event_WeaponFire);
		
		SetEntityHealth(prisoner, 100);
		SetEntityHealth(guard, 100);
		
		GetClientName(prisoner, namePrisoner, sizeof(namePrisoner));
		GetClientName(guard, nameGuard, sizeof(nameGuard));
		
		PrintToChatAll("%s chose to have a Taser Fight with %s", namePrisoner, nameGuard);
		lrActive = true;
	}
}

public LrStop(type, Prisoner, Guard) {
	if (lrActive && type == lrId) {
		prisoner = Prisoner;
		guard = Guard;
		
		isOnTaser[prisoner] = false;
		isOnTaser[guard] = false;
		
		RemoveWeapons(prisoner);
		RemoveWeapons(guard);
		
		lrActive = false;
	}
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast) {
	char weapon[64];
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int weaponEnt = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (lrActive && isOnTaser[client]) {
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		if (StrEqual(weapon, "weapon_taser")) {
			CreateTimer(1.5, GiveTaser, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(3.0, RemoveTaser, EntIndexToEntRef(weaponEnt), TIMER_FLAG_NO_MAPCHANGE);
			GivePlayerItem(client, "weapon_taser");
		}
	}
}
public Action:RemoveTaser(Handle timer, int entity) {
	int entity1 = EntRefToEntIndex(entity);
	AcceptEntityInput(entity1, "Kill");
}

public Action:GiveTaser(Handle timer, int data) {
	int client = GetClientOfUserId(data);
	if (IsPlayerAlive(client) && lrActive && isOnTaser[client]) {
		GivePlayerItem(client, "weapon_taser");
	}
	
}

stock void RemoveWeapons(int client) {
	int weapon;
	for (int i = 0; i <= 5; i++) {
		if (i > 2 && GetClientTeam(client) == 3) continue;
		while((weapon = GetPlayerWeaponSlot(client, i)) != -1) {
			RemovePlayerItem(client, weapon);
			AcceptEntityInput(weapon, "Kill");
		}
	}
}
public void OnPluginEnd() {
	RemoveLastRequestFromList(LrStart, LrStop, "Taser Fight");
}