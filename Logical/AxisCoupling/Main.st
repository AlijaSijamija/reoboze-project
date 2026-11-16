
PROGRAM _INIT

	nomAxis[0] := ADR(gAxisQX);
	nomAxis[1] := ADR(gAxisQY);
	nomAxis[2] := ADR(gAxisQE);
	motAxis[0] := ADR(gAxisMX);
	motAxis[1] := ADR(gAxisMY);
	motAxis[2] := ADR(gAxisME);
	state := COUPLING_INIT;
	fbRTInfo(enable := TRUE);
	cycleTime := UDINT_TO_REAL(fbRTInfo.cycle_time) / 1000000.0;
	gAxes.Par.PaKRampRate := 1.0;

END_PROGRAM

PROGRAM _CYCLIC

	(* Read nominal and motor values *)
	nominalValid := TRUE;
	FOR i := 0 TO 2 DO
		fbNomPos[i](Axis := nomAxis[i], Enable := TRUE, ValueSource := mcVALUE_SET);
		fbNomVel[i](Axis := nomAxis[i], Enable := TRUE);
		fbMotPos[i](Axis := motAxis[i], Enable := TRUE, ValueSource := mcVALUE_SET);
		fbMotVel[i](Axis := motAxis[i], Enable := TRUE);
		fbMotStatus[i](Axis := motAxis[i], Enable := TRUE);
		nominalValid := nominalValid AND fbNomPos[i].Valid AND fbNomVel[i].Valid;
	END_FOR

	gAxes.Status.NomX.Position := fbNomPos[0].CyclicPosition;
	gAxes.Status.NomX.Velocity := fbNomVel[0].Velocity;
	gAxes.Status.NomY.Position := fbNomPos[1].CyclicPosition;
	gAxes.Status.NomY.Velocity := fbNomVel[1].Velocity;
	gAxes.Status.NomE.Position := fbNomPos[2].CyclicPosition;
	gAxes.Status.NomE.Velocity := fbNomVel[2].Velocity;
	gAxes.Status.MotX.Position := fbMotPos[0].CyclicPosition;
	gAxes.Status.MotX.Velocity := fbMotVel[0].Velocity;
	gAxes.Status.MotY.Position := fbMotPos[1].CyclicPosition;
	gAxes.Status.MotY.Velocity := fbMotVel[1].Velocity;
	gAxes.Status.MotE.Position := fbMotPos[2].CyclicPosition;
	gAxes.Status.MotE.Velocity := fbMotVel[2].Velocity;

	fbPressureAdvance(Enable := gAxes.Par.PaEnable, K := gAxes.Par.PaK,
	Velocity := gAxes.Status.NomE.Velocity,
	KRampRate := gAxes.Par.PaKRampRate, CycleTime := cycleTime);
	gAxes.Status.ECorrection := fbPressureAdvance.Correction;
	gAxes.Status.PaKEffective := fbPressureAdvance.KEffective;
	setpoint[0] := gAxes.Status.NomX.Position;
	setpoint[1] := gAxes.Status.NomY.Position;
	setpoint[2] := gAxes.Status.NomE.Position + gAxes.Status.ECorrection;
	gAxes.Status.ECommand := setpoint[2];

	(* Any motor axis error stops the coupling *)
	IF state <> COUPLING_ERROR AND state <> COUPLING_RESETTING THEN
		FOR i := 0 TO 2 DO
			IF fbPower[i].Error THEN
				gAxes.Status.ErrorID := fbPower[i].ErrorID;
				state := COUPLING_ERROR;
			ELSIF fbHome[i].Error THEN
				gAxes.Status.ErrorID := fbHome[i].ErrorID;
				state := COUPLING_ERROR;
			ELSIF fbCyclic[i].Error THEN
				gAxes.Status.ErrorID := fbCyclic[i].ErrorID;
				state := COUPLING_ERROR;
			ELSIF fbMotStatus[i].Valid AND fbMotStatus[i].ErrorStop THEN
				state := COUPLING_ERROR;
			END_IF
		END_FOR
	END_IF
	
	(* Test aid: force a motor axis error *)
	IF gAxes.Cmd.SimulateError THEN
		IF state = COUPLING_ACTIVE THEN
			gAxes.Status.ErrorID := -1;
			state := COUPLING_ERROR;
		END_IF
		gAxes.Cmd.SimulateError := FALSE;
	END_IF

	CASE state OF

		COUPLING_INIT:
			IF nominalValid THEN
				state := COUPLING_POWER_ON;
			END_IF

		COUPLING_POWER_ON:
			allPowered := TRUE;
			FOR i := 0 TO 2 DO
				fbPower[i].Enable := TRUE;
				allPowered := allPowered AND fbPower[i].Status;
			END_FOR
			IF allPowered THEN
				state := COUPLING_HOMING;
			END_IF
			
		COUPLING_HOMING:
			(* Direct homing to the nominal position: motor and nominal start aligned *)
			allHomed := TRUE;
			FOR i := 0 TO 2 DO
				fbHome[i].Position := setpoint[i];
				fbHome[i].HomingMode := mcHOMING_DIRECT;
				fbHome[i].Execute := TRUE;
				allHomed := allHomed AND fbHome[i].Done;
			END_FOR
			IF allHomed THEN
				FOR i := 0 TO 2 DO
					fbHome[i].Execute := FALSE;
				END_FOR
				state := COUPLING_ACTIVE;
			END_IF

		COUPLING_ACTIVE:
			FOR i := 0 TO 2 DO
				fbCyclic[i].Enable := TRUE;
			END_FOR

		COUPLING_ERROR:
			FOR i := 0 TO 2 DO
				fbCyclic[i].Enable := FALSE;
				fbPower[i].Enable := FALSE;
				fbHome[i].Execute := FALSE;
			END_FOR
			IF gAxes.Cmd.ErrorReset THEN
				FOR i := 0 TO 2 DO
					fbReset[i].Execute := TRUE;
				END_FOR
				state := COUPLING_RESETTING;
			END_IF

		COUPLING_RESETTING:
			allReset := TRUE;
			FOR i := 0 TO 2 DO
				allReset := allReset AND (fbReset[i].Done OR fbReset[i].Error);
			END_FOR
			IF allReset THEN
				FOR i := 0 TO 2 DO
					fbReset[i].Execute := FALSE;
				END_FOR
				gAxes.Status.ErrorID := 0;
				state := COUPLING_INIT;
			END_IF

	END_CASE

	(* Command function blocks *)
	allCoupled := TRUE;
	FOR i := 0 TO 2 DO
		fbPower[i](Axis := motAxis[i]);
		fbHome[i](Axis := motAxis[i]);
		fbCyclic[i](Axis := motAxis[i], InterpolationMode := mcIPLM_DEFAULT,
		CyclicPosition := setpoint[i]);
		fbReset[i](Axis := motAxis[i]);
		allCoupled := allCoupled AND fbCyclic[i].Valid;
	END_FOR

	gAxes.Status.Coupled := allCoupled;
	gAxes.Status.Error := (state = COUPLING_ERROR);
	gAxes.Cmd.ErrorReset := FALSE;

END_PROGRAM