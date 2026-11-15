
PROGRAM _INIT
	gTemp.Par.Tolerance := 2.0;
	gTemp.Par.StableTime := T#3s;
	gTemp.Par.Timeout := T#5m;

	fbController.MpLink := ADR(gTempController_1);
	fbController.Parameters := ADR(controllerPar);
	fbController.Simulate := TRUE;
	fbController.Enable := TRUE;
	 
END_PROGRAM

PROGRAM _CYCLIC
	(* Controller with built-in simulated heater *)
	fbController.SetTemperature := gTemp.Par.SetTemperature;
	fbController.ActualTemperature := fbController.Info.Simulation.ActualTemperature;
	fbController.Control := gTemp.Cmd.HeaterOn AND NOT gTemp.Status.HeatUpTimeout;
	fbController.ErrorReset := gTemp.Cmd.ErrorReset;
	fbController();

	gTemp.Status.ActualTemperature := fbController.Info.Simulation.ActualTemperature;
	gTemp.Status.Heating := fbController.ControlActive;

	(* Stabilization criterion: in tolerance for the whole stable time *)
	deviation := ABS(gTemp.Status.ActualTemperature - gTemp.Par.SetTemperature);
	tonStable(IN := fbController.ControlActive AND (deviation <= gTemp.Par.Tolerance),
	PT := gTemp.Par.StableTime);
	gTemp.Status.Stable := tonStable.Q;

	(* Heat-up timeout *)
	tonTimeout(IN := gTemp.Cmd.HeaterOn AND NOT gTemp.Status.Stable
	AND NOT gTemp.Status.HeatUpTimeout, PT := gTemp.Par.Timeout);
	IF tonTimeout.Q THEN
		gTemp.Status.HeatUpTimeout := TRUE;
	END_IF
	IF gTemp.Cmd.ErrorReset THEN
		gTemp.Status.HeatUpTimeout := FALSE;
	END_IF

	gTemp.Status.Error := fbController.Error OR gTemp.Status.HeatUpTimeout;
	gTemp.Status.StatusID := fbController.StatusID;

	(* One-shot command *)
	gTemp.Cmd.ErrorReset := FALSE;
	 
END_PROGRAM

PROGRAM _EXIT
	fbController.Enable := FALSE;
	fbController();
	 
END_PROGRAM

