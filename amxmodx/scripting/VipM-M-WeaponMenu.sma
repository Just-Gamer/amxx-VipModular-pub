#include <amxmodx>
#include <reapi>
#include <VipModular>
#include "VipM/Utils"
#include "VipM/DebugMode"

#pragma semicolon 1
#pragma compress 1

public stock const PluginName[] = "[VipM][M] Weapon Menu";
public stock const PluginVersion[] = _VIPM_VERSION;
public stock const PluginAuthor[] = "ArKaNeMaN";
public stock const PluginURL[] = _VIPM_PLUGIN_URL;
public stock const PluginDescription[] = "Vip modular`s module - Weapon Menu";

new const MODULE_NAME[] = "WeaponMenu";

new const CMD_WEAPON_MENU[] = "vipmenu";
new const CMD_WEAPON_MENU_SILENT[] = "vipmenu_silent";
new const CMD_SWITCH_AUTOOPEN[] = "vipmenu_autoopen";

#include "VipM/ArrayTrieUtils"
#include "VipM/Utils"
#include "VipM/CommandAliases"

enum {
    TASK_OFFSET_AUTO_OPEN = 100,
    TASK_OFFSET_AUTO_CLOSE = 200,
}

new gUserLeftItems[MAX_PLAYERS + 1] = {0, ...};
new Trie:g_tUserMenuItemsCounter[MAX_PLAYERS + 1] = {Invalid_Trie, ...};

new bool:gUserAutoOpen[MAX_PLAYERS + 1] = {true, ...};

#include "VipM/WeaponMenu/KeyValueCounter"
#include "VipM/WeaponMenu/Structs"
#include "VipM/WeaponMenu/Configs"
#include "VipM/WeaponMenu/Menus"

public VipM_OnInitModules() {
    RegisterPluginByVars();
    register_dictionary("VipM-WeaponMenu.ini");

    VipM_IC_Init();

    VipM_Modules_Register(MODULE_NAME, true);
    VipM_Modules_AddParams(MODULE_NAME,
        "MainMenuTitle", ptString, false,
        "Menus", ptCustom, true,
        "Count", ptInteger, false
    );
    VipM_Modules_AddParams(MODULE_NAME,
        "Limits", ptLimits, false
    );
    VipM_Modules_AddParams(MODULE_NAME,
        "AutoopenLimits", ptLimits, false,
        "AutoopenDelay", ptFloat, false,
        "AutoopenCloseDelay", ptFloat, false
    );
    VipM_Modules_RegisterEvent(MODULE_NAME, Module_OnActivated, "@OnModuleActivate");
    VipM_Modules_RegisterEvent(MODULE_NAME, Module_OnRead, "@OnReadConfig");
}

@OnReadConfig(const JSON:jCfg, Trie:Params) {
    if (!json_object_has_value(jCfg, "Menus", JSONArray)) {
        log_amx("[WARNING] Param `Menus` required for module `%s`.", MODULE_NAME);
        return VIPM_STOP;
    }

    new JSON:jMenus = json_object_get_value(jCfg, "Menus");
    new Array:aMenus = Cfg_ReadMenus(jMenus);
    TrieSetCell(Params, "Menus", aMenus);

    if (!TrieKeyExists(Params, "MainMenuTitle")) {
        TrieSetString(Params, "MainMenuTitle", Lang("MENU_MAIN_TITLE"));
    }

    return VIPM_CONTINUE;
}

@OnModuleActivate() {
    RegisterHookChain(RG_CBasePlayer_Spawn, "@OnPlayerSpawn", true);
    
    CommandAliases_Open(GET_FILE_JSON_PATH("Cmds/WeaponMenu"), true);
    CommandAliases_RegisterClient(CMD_WEAPON_MENU, "@Cmd_Menu");
    CommandAliases_RegisterClient(CMD_WEAPON_MENU_SILENT, "@Cmd_MenuSilent");
    CommandAliases_RegisterClient(CMD_SWITCH_AUTOOPEN, "@Cmd_SwitchAutoOpen");
    CommandAliases_Close();
}

@OnPlayerSpawn(const UserId) {
    if (!IsUserValidA(UserId)) {
        return;
    }

    new Trie:Params = VipM_Modules_GetParams(MODULE_NAME, UserId);
    gUserLeftItems[UserId] = VipM_Params_GetInt(Params, "Count", 0);
    g_tUserMenuItemsCounter[UserId] = KeyValueCounter_Reset(g_tUserMenuItemsCounter[UserId]);

    if (!gUserAutoOpen[UserId]) {
        return;
    }

    if (VipM_Params_GetArr(Params, "Menus") == Invalid_Array) {
        return;
    }

    if (!VipM_Params_ExecuteLimitsList(Params, "AutoopenLimits", UserId, Limit_Exec_AND)) {
        return;
    }

    set_task(VipM_Params_GetFloat(Params, "AutoopenDelay", 0.0), "@Task_AutoOpen", TASK_OFFSET_AUTO_OPEN + UserId);
}

@Task_AutoOpen(UserId) {
    UserId -= TASK_OFFSET_AUTO_OPEN;
    CommandAliases_ClientCmd(UserId, CMD_WEAPON_MENU_SILENT);
    
    new Float:fAutoCloseDelay = VipM_Params_GetFloat(VipM_Modules_GetParams(MODULE_NAME, UserId), "AutoopenCloseDelay", 0.0);
    Dbg_PrintServer("@Task_AutoOpen(%d): fAutoCloseDelay = %.2f", UserId, fAutoCloseDelay);
    if (fAutoCloseDelay > 0.0) {
        Dbg_PrintServer("@Task_AutoOpen(%d): Start auto close task", UserId);
        set_task(fAutoCloseDelay, "@Task_AutoClose", TASK_OFFSET_AUTO_CLOSE + UserId);
    }
}

@Task_AutoClose(UserId) {
    Dbg_PrintServer("@Task_AutoClose(%d)", UserId);
    UserId -= TASK_OFFSET_AUTO_CLOSE;
    menu_cancel(UserId);
    show_menu(UserId, 0, "");
}

// TODO: Придумать как лучше использовать...
// AbortAutoCloseMenu(const UserId) {
//     if (task_exists(TASK_OFFSET_AUTO_CLOSE + UserId)) {
//         remove_task(TASK_OFFSET_AUTO_CLOSE + UserId);
//     }
// }

@Cmd_SwitchAutoOpen(const UserId) {
    gUserAutoOpen[UserId] = !gUserAutoOpen[UserId];
    ChatPrintL(UserId, gUserAutoOpen[UserId] ? "MSG_AUTOOPEN_TURNED_ON" : "MSG_AUTOOPEN_TURNED_OFF");
    return PLUGIN_HANDLED;
}

@Cmd_Menu(const UserId) {
    _Cmd_Menu(UserId);
    return PLUGIN_HANDLED;
}

@Cmd_MenuSilent(const UserId) {
    _Cmd_Menu(UserId, true);
    return PLUGIN_HANDLED;
}

_Cmd_Menu(const UserId, const bool:bSilent = false) {
    if (!IsUserValid(UserId)) {
        return;
    }

    if (!is_user_alive(UserId)) {
        if (!bSilent) {
            ChatPrintL(UserId, "MSG_YOU_DEAD");
        }

        return;
    }

    new Trie:Params = VipM_Modules_GetParams(MODULE_NAME, UserId);
    new Array:aMenus = VipM_Params_GetArr(Params, "Menus");

    if (ArraySizeSafe(aMenus) < 1) {
        if (!bSilent) {
            ChatPrintL(UserId, "MSG_NO_ACCESS");
        }

        return;
    }
    
    if (!VipM_Params_ExecuteLimitsList(Params, "Limits", UserId, Limit_Exec_AND)) {
        if (!bSilent) {
            ChatPrintL(UserId, "MSG_MAIN_NOT_PASSED_LIMIT");
        }

        return;
    }

    CMD_INIT_PARAMS();

    if (CMD_ARG_NUM() < 1) {
        if (ArraySizeSafe(aMenus) == 1) {
            CommandAliases_ClientCmd(UserId, CMD_WEAPON_MENU, "0");
        } else {
            static MainMenuTitle[128];
            VipM_Params_GetStr(Params, "MainMenuTitle", MainMenuTitle, charsmax(MainMenuTitle));
            Menu_MainMenu(UserId, MainMenuTitle, aMenus);
        }
        return;
    }

    new MenuId = read_argv_int(CMD_ARG(1));
    if (
        ArraySizeSafe(aMenus) <= MenuId
        || MenuId < 0
    ) {
        return;
    }

    static Menu[S_WeaponMenu];
    ArrayGetArray(aMenus, MenuId, Menu);

    if (!VipM_Limits_ExecuteList(Menu[WeaponMenu_Limits], UserId)) {
        if (!bSilent) {
            ChatPrintL(UserId, "MSG_MENU_NOT_PASSED_LIMIT");
        }

        return;
    }
    
    if (CMD_ARG_NUM() < 2) {
        Menu_WeaponsMenu(UserId, MenuId, Menu);
        return;
    }

    new ItemId = read_argv_int(CMD_ARG(2));
    if (
        ArraySizeSafe(Menu[WeaponMenu_Items]) <= ItemId
        || ItemId < 0
    ) {
        return;
    }

    static MenuItem[S_MenuItem];
    ArrayGetArray(Menu[WeaponMenu_Items], ItemId, MenuItem);

    if (
        MenuItem[MenuItem_UseCounter]
        && GetUserLeftItems(UserId, MenuId, Menu) <= 0
    ) {
        if (!bSilent) {
            ChatPrintL(UserId, "MSG_NO_LEFT_ITEMS");
        }
        
        return;
    }

    if (
        !VipM_Limits_ExecuteList(MenuItem[MenuItem_ShowLimits], UserId)
        || !VipM_Limits_ExecuteList(MenuItem[MenuItem_ActiveLimits], UserId)
        || !VipM_Limits_ExecuteList(MenuItem[MenuItem_Limits], UserId)
    ) {
        if (!bSilent) {
            ChatPrintL(UserId, "MSG_MENUITEM_NOT_PASSED_LIMIT");
        }
        
        return;
    }
    
    if (
        VipM_IC_GiveItems(UserId, MenuItem[MenuItem_Items])
        && MenuItem[MenuItem_UseCounter]
    ) {
        gUserLeftItems[UserId]--;

        if (Menu[WeaponMenu_Count]) {
            KeyValueCounter_Inc(g_tUserMenuItemsCounter[UserId], IntToStr(MenuId));
            Dbg_Log("After inc menu limit counter: KeyValueCounter_Get(g_tUserMenuItemsCounter[UserId], IntToStr(MenuId)) = %d", KeyValueCounter_Get(g_tUserMenuItemsCounter[UserId], IntToStr(MenuId)));
        }
    }
}

GetUserLeftItems(const UserId, const MenuId, const Menu[S_WeaponMenu]) {
    new iUserItemsLeft = gUserLeftItems[UserId];
    new iMenuItemsLeft = Menu[WeaponMenu_Count] - KeyValueCounter_Get(g_tUserMenuItemsCounter[UserId], IntToStr(MenuId));

    Dbg_Log("GetUserLeftItems(%n, %d, ...):", UserId, MenuId);
    Dbg_Log("    KeyValueCounter_Get(g_tUserMenuItemsCounter[UserId], IntToStr(MenuId)) = %d", KeyValueCounter_Get(g_tUserMenuItemsCounter[UserId], IntToStr(MenuId)));
    Dbg_Log("    Menu[WeaponMenu_Count] = %d", Menu[WeaponMenu_Count]);
    Dbg_Log("    gUserLeftItems[UserId] = %d", gUserLeftItems[UserId]);
    Dbg_Log("    iUserItemsLeft = %d", iUserItemsLeft);
    Dbg_Log("    iMenuItemsLeft = %d", iMenuItemsLeft);
    
    if (Menu[WeaponMenu_Count]) {
        return min(iUserItemsLeft, iMenuItemsLeft);
    } else {
        return iUserItemsLeft;
    }
}
