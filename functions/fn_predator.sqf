params [["_mode","Launch"],["_params",[]]];

switch (_mode) do {
	case "Launch": {
		_params params [["_launchMode",""]];
		
		_pos = getPos player;
		
		if (_launchMode == "fromMap") then {
			"DrPredatorMapHint" cutText ["<t font='PuristaBold' size='2'>SELECT POSITION ON THE MAP</t>", "PLAIN DOWN", 1, true, true];
			_mapEH = addMissionEventHandler ["MapSingleClick",{
				DrPredatorMapPos = _this # 1;
			}];
			openMap true;
			waitUntil {!isNil "DrPredatorMapPos"};
			_pos = [] + DrPredatorMapPos;
			DrPredatorMapPos = nil;
			"DrPredatorMapHint" cutText ["", "PLAIN DOWN", -1, true, true];
			removeMissionEventHandler ["MapSingleClick",_mapEH];
		};
		
		
		_pos set [2, (_pos # 2) + DrStartHeight];

		[0, "BLACK", 0.5, 1] spawn BIS_fnc_fadeEffect;

		UiSleep 1;

		DrPredatorMissile = "ammo_Missile_Cruise_01" createVehicle _pos;
		DrPredatorMissile setDir getDir player;
		[DrPredatorMissile, -85, 0] call BIS_fnc_setPitchBank;

		"DrPredatorScreen" cutRsc ["DrPredatorScreen", "PLAIN"];
		DrPredatorPP_chrom = ppEffectCreate ["ChromAberration",200];
		DrPredatorPP_chrom ppEffectEnable true;
		DrPredatorPP_chrom ppEffectAdjust [0.01,0.01,true];
		DrPredatorPP_chrom ppEffectCommit 0;
		DrPredatorPP_colorC = ppEffectCreate ["ColorCorrections",1500];
		DrPredatorPP_colorC ppEffectEnable true;
		DrPredatorPP_colorC ppEffectAdjust [1,1,0,[0,0,0,0],[1,1,1,0.1],[0.33,0.33,0.33,0],[0,0,0,0,0,0,4]];
		DrPredatorPP_colorC ppEffectCommit 0;
		DrPredatorPP_film = ppEffectCreate ["FilmGrain",2000];
		DrPredatorPP_film ppEffectEnable true;
		DrPredatorPP_film ppEffectAdjust [0.15,0.1,0.28,0.7,0.42,false];
		DrPredatorPP_film ppEffectCommit 0;

		DrPredatorCamera = "camera" camCreate getPos DrPredatorMissile;
		DrPredatorCamera attachTo [DrPredatorMissile, [0,0,-2.2], "rudder_axis"];
		showCinemaBorder false;
		DrPredatorCamera cameraEffect ["internal", "BACK"];

		[1, "BLACK", 0.1, 1] spawn BIS_fnc_fadeEffect;

		playSound "DrSound_LaunchRocket";

		DrLastMousePosition = ["0","0"];

		_mouseClickEH = (findDisplay 46) displayAddEventHandler ["MouseButtonUp",{
			if ((_this # 1) == 1) then {
				_bool = !(player getVariable ["isZoom",false]);
				DrPredatorCamera camSetFov ([0.2,0.7] select _bool);
				player setVariable ["isZoom",_bool];
			};
		}];
		_keyUpEH = (findDisplay 46) displayAddEventHandler ["KeyUp",{	
			if ((_this # 1) == 49) then {
				_bool = !(player getVariable ["isThermal",false]);
				_bool setCamUseTI 1;
				player setVariable ["isThermal",_bool];
				DrPredatorPP_chrom ppEffectEnable !_bool;
				DrPredatorPP_colorC ppEffectEnable !_bool;
				DrPredatorPP_film ppEffectEnable !_bool;
			};
		}];
		_mouseMovingEH = (findDisplay 46) displayAddEventHandler ["MouseMoving",{
			params ["","_x","_y"];
			if (DrLastMousePosition isEqualTo ([_x,_y] apply {_x toFixed 1})) exitWith {};
			
			_force 	= linearConversion [DrStartHeight,0,(getPos DrPredatorMissile) # 2,100,1, true];
			_dirX 	=  _force * ([-1,1] select (_x > 0));
			_dirY 	= _force * ([1,-1] select (_y > 0));
			_vel 	= velocityModelSpace DrPredatorMissile;
			
			DrLastMousePosition = [_x toFixed 1,_y toFixed 1];
			DrPredatorMissile setVelocityModelSpace [(_vel # 0) + _dirX,_vel # 1,(_vel # 2) + _dirY];
		}];
		
		["Proceed",[_mouseMovingEH, _keyUpEH, _mouseClickEH]] spawn Dr_fnc_Predator;
	};
	case "Proceed": {
		_params params ["_mmEH", "_keyUpEH", "_mouseClickEH"];
		_display 		= uiNamespace getVariable ["DrPredatorScreen",displayNull];
		_coordControl 	= _display displayCtrl 1102;
		_textFormat 	= "<t align='left' font='EtelkaMonospaceProBold' size='0.7'>%1 %2 %3<br />%4 : %5<br />0 13004 [0x0000045]</t>";
		
		while {alive DrPredatorMissile} do {
			_pos 		= (getPos DrPredatorMissile) apply {round _x};
			_velocity 	= (velocity DrPredatorMissile) apply {round _x};

			_coordControl ctrlSetStructuredText parseText format [_textFormat,_pos # 0, _pos # 1, _pos # 2, _velocity # 1, round((_velocity # 0) * (_velocity # 2))];
			sleep 0.01;
		};
		player setVariable ["isThermal",nil];
		player setVariable ["isZoom",nil];
		"RscNoise" cutrsc ["RscNoise","black"]; 
		false setCamUseTI 1;
		PPEffectDestroy [DrPredatorPP_chrom, DrPredatorPP_colorC, DrPredatorPP_film];
		UiSleep 1;
		DrPredatorCamera cameraEffect ["terminate","back"];
		camDestroy DrPredatorCamera;
		"RscNoise" cutText ["","PLAIN"];
		"DrPredatorScreen" cutText ["", "PLAIN"];
		[1, "BLACK", 1, 1] spawn BIS_fnc_fadeEffect;
		
		//cleaning
		(findDisplay 46) displayRemoveEventHandler ["MouseMoving",_mmEH];
		(findDisplay 46) displayRemoveEventHandler ["KeyUp",_keyUpEH];
		(findDisplay 46) displayRemoveEventHandler ["MouseButtonUp",_mouseClickEH];
		DrPredatorCamera = nil;
		DrPredatorPP_chrom = nil;
		DrPredatorPP_colorC = nil;
		DrPredatorPP_film = nil;
		DrPredatorMissile = nil;
		DrLastMousePosition = nil;
	};
};