
FUNCTION_BLOCK PressureAdvance

	(* Requested coefficient: zero when disabled, never negative *)
	IF Enable AND (K > 0.0) THEN
		kTarget := K;
	ELSE
		kTarget := 0.0;
	END_IF

	(* Ramp the effective coefficient so the command stays continuous *)
	IF KRampRate > 0.0 THEN
		kStep := KRampRate * CycleTime;
		IF kTarget > KEffective + kStep THEN
			KEffective := KEffective + kStep;
		ELSIF kTarget < KEffective - kStep THEN
			KEffective := KEffective - kStep;
		ELSE
			KEffective := kTarget;
		END_IF
	ELSE
		KEffective := kTarget;
	END_IF

	Correction := REAL_TO_LREAL(KEffective * Velocity);

END_FUNCTION_BLOCK