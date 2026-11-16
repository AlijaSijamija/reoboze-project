
PROGRAM _INIT
	gMotion.Par.ProgramName := 'Print.cnc';

	(* Every axis homes with the mode from its configuration: direct, position 0 *)
	FOR i := 0 TO 14 DO
		fbHome.HomingMode[i] := mcHOMING_DEFAULT;
	END_FOR

	gMotion.Status.State := MOTION_INIT;
	 
END_PROGRAM

PROGRAM _CYCLIC
	(* Status of the group, read in every state *)
	fbReadStatus(AxesGroup := ADR(gCncXY), Enable := TRUE);
	fbReadInfo(AxesGroup := ADR(gCncXY), Enable := TRUE);
	fbReadError(AxesGroup := ADR(gCncXY), Enable := TRUE);

	(* A group error overrides every state *)
	IF fbReadStatus.Valid AND fbReadStatus.GroupErrorStop
		AND gMotion.Status.State <> MOTION_ERROR
		AND gMotion.Status.State <> MOTION_RESETTING THEN
		gMotion.Status.ErrorID := fbReadError.GroupErrorID;
		gMotion.Status.State := MOTION_ERROR;
	END_IF
	
	(* One reset command acknowledges all components *)
	IF gMotion.Cmd.ErrorReset THEN
		gTemp.Cmd.ErrorReset := TRUE;
		gAxes.Cmd.ErrorReset := TRUE;
	END_IF

	(* A component error during a program run stops the motion *)
	IF (gMotion.Status.State = MOTION_STARTING) OR (gMotion.Status.State = MOTION_RUNNING) THEN
		IF gTemp.Status.Error THEN
			gMotion.Status.ErrorSource := MOTION_ERR_TEMPERATURE;
			gMotion.Status.ErrorID := gTemp.Status.StatusID;
			stopToError := TRUE;
		ELSIF gAxes.Status.Error THEN
			gMotion.Status.ErrorSource := MOTION_ERR_MOTOR_AXES;
			gMotion.Status.ErrorID := gAxes.Status.ErrorID;
			stopToError := TRUE;
		END_IF
		IF stopToError THEN
			fbMoveProgram.Execute := FALSE;
			fbStop.Execute := TRUE;
			gMotion.Status.State := MOTION_STOPPING;
		END_IF
	END_IF

	CASE gMotion.Status.State OF

		MOTION_INIT:
			IF fbReadInfo.Valid THEN
				IF fbReadInfo.PowerOn THEN
					(* Group is still powered, e.g. after a program download *)
					IF fbReadInfo.IsHomed THEN
						gMotion.Status.State := MOTION_READY;
					ELSE
						gMotion.Status.State := MOTION_HOMING;
					END_IF
				ELSIF fbReadInfo.ReadyForPowerOn THEN
					gMotion.Status.State := MOTION_POWER_ON;
				END_IF
			END_IF

		MOTION_POWER_ON:
			fbPower.Enable := TRUE;
			IF fbPower.Error THEN
				gMotion.Status.ErrorID := fbPower.ErrorID;
				gMotion.Status.State := MOTION_ERROR;
			ELSIF fbPower.Status THEN
				IF fbReadInfo.IsHomed THEN
					gMotion.Status.State := MOTION_READY;
				ELSE
					gMotion.Status.State := MOTION_HOMING;
				END_IF
			END_IF

		MOTION_HOMING:
			fbHome.Execute := TRUE;
			IF fbHome.Error THEN
				gMotion.Status.ErrorID := fbHome.ErrorID;
				fbHome.Execute := FALSE;
				gMotion.Status.State := MOTION_ERROR;
			ELSIF fbHome.Done THEN
				fbHome.Execute := FALSE;
				gMotion.Status.State := MOTION_READY;
			END_IF

		MOTION_READY:
			IF gMotion.Cmd.Start AND gAxes.Status.Coupled AND NOT gTemp.Status.Error THEN
				gMotion.Status.Done := FALSE;
				fbMoveProgram.Name := gMotion.Par.ProgramName;
				fbMoveProgram.Execute := TRUE;
				gMotion.Status.State := MOTION_STARTING;
			END_IF

		MOTION_STARTING:
			IF fbMoveProgram.Error THEN
				gMotion.Status.ErrorID := fbMoveProgram.ErrorID;
				gMotion.Status.State := MOTION_ERROR;
			ELSIF fbMoveProgram.Busy OR fbMoveProgram.Done THEN
				gMotion.Status.State := MOTION_RUNNING;
			END_IF

		MOTION_RUNNING:
			IF gMotion.Cmd.Stop THEN
				fbMoveProgram.Execute := FALSE;
				fbStop.Execute := TRUE;
				gMotion.Status.State := MOTION_STOPPING;
			ELSIF fbMoveProgram.Error THEN
				gMotion.Status.ErrorID := fbMoveProgram.ErrorID;
				gMotion.Status.State := MOTION_ERROR;
			ELSIF fbMoveProgram.Done THEN
				fbMoveProgram.Execute := FALSE;
				gMotion.Status.Done := TRUE;
				gMotion.Status.State := MOTION_READY;
			END_IF

		MOTION_STOPPING:
			IF fbStop.Error THEN
				gMotion.Status.ErrorID := fbStop.ErrorID;
				fbStop.Execute := FALSE;
				stopToError := FALSE;
				gMotion.Status.State := MOTION_ERROR;
			ELSIF fbStop.Done THEN
				fbStop.Execute := FALSE;
				IF stopToError THEN
					stopToError := FALSE;
					gMotion.Status.State := MOTION_ERROR;
				ELSE
					gMotion.Status.State := MOTION_READY;
				END_IF
			END_IF

		MOTION_ERROR:
			IF gMotion.Status.ErrorSource = MOTION_ERR_NONE THEN
				gMotion.Status.ErrorSource := MOTION_ERR_GROUP;
			END_IF
			fbPower.Enable := FALSE;
			fbHome.Execute := FALSE;
			fbMoveProgram.Execute := FALSE;
			fbStop.Execute := FALSE;
			IF gMotion.Cmd.ErrorReset THEN
				IF fbReadStatus.GroupErrorStop THEN
					fbReset.Execute := TRUE;
					gMotion.Status.State := MOTION_RESETTING;
				ELSE
					(* Error came from another component: the group needs no reset *)
					gMotion.Status.ErrorID := 0;
					gMotion.Status.ErrorSource := MOTION_ERR_NONE;
					gMotion.Status.State := MOTION_INIT;
				END_IF
			END_IF

		MOTION_RESETTING:
			IF fbReset.Error THEN
				gMotion.Status.ErrorID := fbReset.ErrorID;
				fbReset.Execute := FALSE;
				gMotion.Status.State := MOTION_ERROR;
			ELSIF fbReset.Done THEN
				fbReset.Execute := FALSE;
				gMotion.Status.ErrorID := 0;
				gMotion.Status.ErrorSource := MOTION_ERR_NONE;
				gMotion.Status.State := MOTION_INIT;
			END_IF

	END_CASE
	
	(* M109: set temperature AND wait UNTIL it is stable.
		The PROGRAM writes the setpoint itself (SetTemp=...). *)
	IF fbM109.Value THEN
		gTemp.Cmd.HeaterOn := TRUE;
	END_IF
	
	tonM109(IN := fbM109.Value, PT := T#200ms);
	fbM109.Reset := fbM109.Value
	AND ((tonM109.Q AND gTemp.Status.Stable) OR NOT gMotion.Status.Running);
	fbM109(AxesGroup := ADR(gCncXY), Enable := TRUE, MFunction := 109);

	(* Command function blocks, called once per cycle *)
	fbPower(AxesGroup := ADR(gCncXY));
	fbHome(AxesGroup := ADR(gCncXY));
	fbMoveProgram(AxesGroup := ADR(gCncXY));
	fbStop(AxesGroup := ADR(gCncXY));
	fbReset(AxesGroup := ADR(gCncXY));

	(* Status for the operator page and other programs *)
	gMotion.Status.Ready := (gMotion.Status.State = MOTION_READY);
	gMotion.Status.Running := (gMotion.Status.State = MOTION_STARTING)
	OR (gMotion.Status.State = MOTION_RUNNING);
	gMotion.Status.Error := (gMotion.Status.State = MOTION_ERROR);

	(* Commands are one-shot: consumed every cycle *)
	gMotion.Cmd.Start := FALSE;
	gMotion.Cmd.Stop := FALSE;
	gMotion.Cmd.ErrorReset := FALSE;

END_PROGRAM

PROGRAM _EXIT
	(* Insert code here *)
	 
END_PROGRAM

