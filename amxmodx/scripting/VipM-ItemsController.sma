#include <amxmodx>
#include <VipModular>

#pragma semicolon 1
#pragma compress 1

public stock const PluginName[] = "[VipM] Items Controller";
public stock const PluginAuthor[] = "ArKaNeMaN";
public stock const PluginURL[] = "https://arkanaplugins.ru/plugin/9";
public stock const PluginDescription[] = "Vip modular`s items controller";

#include "VipM/ArrayTrieUtils"
#include "VipM/ArrayMap"
#include "VipM/Utils"

#include "VipM/ItemsController/Structs"
#include "VipM/ItemsController/Forwards"
#include "VipM/ItemsController/Utils"

DefineArrayMap(Types); // S_ItemType
new Array:Items;

public plugin_precache() {
    PluginInit();
}

public VipM_OnInitModules() {
    PluginInit();
}

PluginInit() {
    static bool:bIsInited;
    if (bIsInited) {
        return;
    }
    bIsInited = true;

    register_plugin(PluginName, VIPM_VERSION, PluginAuthor);
    Fwds_Init();
    SrvCmds_Init();

    InitArrayMap(Types, S_ItemType, 8);
    FwdExec(InitTypes);

    Items = ArrayCreate(S_Item, 16);
    FwdExec(Loaded);
}

#include "VipM/ItemsController/Natives"
#include "VipM/ItemsController/Configs"
#include "VipM/ItemsController/SrvCmds"
