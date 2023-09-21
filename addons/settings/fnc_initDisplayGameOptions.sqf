#include "script_component.hpp"

params ["_display"];
uiNamespace setVariable [QGVAR(display), _display];

private _ctrlAddonsGroup = _display displayCtrl IDC_ADDONS_GROUP;
private _ctrlServerButton = _display displayCtrl IDC_BTN_SERVER;
private _ctrlMissionButton = _display displayCtrl IDC_BTN_MISSION;
private _ctrlClientButton = _display displayCtrl IDC_BTN_CLIENT;

// ----- hide and disable the custom controls by default
{
    _x ctrlEnable false;
    _x ctrlShow false;
} forEach [_ctrlAddonsGroup, _ctrlServerButton, _ctrlMissionButton, _ctrlClientButton];

// ----- disable in main menu
if (isNil QUOTE(ADDON)) exitWith {
    private _ctrlToggleButton = _display displayCtrl IDC_BTN_CONFIGURE_ADDONS;

    _ctrlToggleButton ctrlEnable false;
    _ctrlToggleButton ctrlSetTooltip LELSTRING(common,need_mission_start);
};

// ----- situational tooltips
if (!isMultiplayer) then {
    _ctrlServerButton ctrlSetTooltip LLSTRING(ButtonClient_tooltip);
};

if (is3DEN) then {
    _ctrlMissionButton ctrlSetTooltip LLSTRING(ButtonMission_tooltip_3den);
};

if (isServer) then {
    _ctrlClientButton ctrlSetTooltip "";
};

// ----- reload settings file if in editor
if (is3DEN && {FILE_EXISTS(MISSION_SETTINGS_FILE)}) then {
    GVAR(missionConfig) call CBA_fnc_deleteNamespace;
    GVAR(missionConfig) = [] call CBA_fnc_createNamespace;

    private _missionConfig = preprocessFile MISSION_SETTINGS_FILE;

    {
        _x params ["_setting", "_value", "_priority"];

        GVAR(missionConfig) setVariable [_setting, [_value, _priority]];
    } forEach ([_missionConfig, false] call FUNC(parse));

    {
        private _setting = _x;

        (GVAR(missionConfig) getVariable [_setting, []]) params ["_value", "_priority"];

        if (!isNil "_value") then {
            [_setting, _value, _priority, "mission"] call FUNC(set);
        };
    } forEach GVAR(allSettings);
};

// ----- create temporary setting namespaces
with uiNamespace do {
    GVAR(clientTemp)  = _display ctrlCreate ["RscText", -1];
    GVAR(missionTemp) = _display ctrlCreate ["RscText", -1];
    GVAR(serverTemp)  = _display ctrlCreate ["RscText", -1];
};

GVAR(awaitingRestartTemp) = + GVAR(awaitingRestart);

// ----- create addons list (filled later)
private _ctrlAddonList = _display ctrlCreate [QGVAR(AddonsList), IDC_ADDONS_LIST, _ctrlAddonsGroup];

_ctrlAddonList ctrlAddEventHandler ["LBSelChanged", {_this call FUNC(gui_addonChanged)}];

// ----- Add lists
_display setVariable [QGVAR(lists),[]];
_display setVariable [QGVAR(createdCategories), createHashMap];

// ----- fill addons list
[_display, _ctrlAddonList] call FUNC(gui_fillAddonList);

private _listIndex = 0;
private _lastAddon = uiNamespace getVariable [QGVAR(addon), ""];
if (_lastAddon != "") then {
    for "_lbIndex" from 0 to (lbSize _ctrlAddonList - 1) do {
        if ((_display getVariable [(_ctrlAddonList lbData _lbIndex), ""]) == _lastAddon) exitWith {
            _listIndex = _lbIndex;
        };
    };
};
_ctrlAddonList lbSetCurSel _listIndex;

// ----- source buttons (server, mission, client)
{
    _x ctrlAddEventHandler ["ButtonClick", FUNC(gui_sourceChanged)];
} forEach [_ctrlServerButton, _ctrlMissionButton, _ctrlClientButton];

// ----- configure addons/base button
(_display displayCtrl IDC_BTN_CONFIGURE_ADDONS) ctrlAddEventHandler ["ButtonClick", {_this call FUNC(gui_configure)}];

// ----- scripted OK button
(_display displayCtrl 999) ctrlAddEventHandler ["ButtonClick", {call FUNC(gui_saveTempData)}];
