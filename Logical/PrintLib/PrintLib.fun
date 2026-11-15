
FUNCTION_BLOCK PressureAdvance (*Extrusion pressure compensation: Correction = K * Velocity*)
	VAR_INPUT
		Enable : BOOL; (*Compensation on/off*)
		K : REAL; (*Compensation coefficient [s], values below 0 are treated as 0*)
		Velocity : REAL; (*Nominal E velocity [mm/s]*)
		KRampRate : REAL; (*Maximum change of the effective K per second [s/s], 0 = no ramp*)
		CycleTime : REAL; (*Cycle time of the calling task [s]*)
	END_VAR
	VAR_OUTPUT
		Correction : LREAL; (*Position correction for the E motor [mm]*)
		KEffective : REAL; (*K currently applied [s]*)
	END_VAR
	VAR
		kTarget : REAL;
		kStep : REAL;
	END_VAR
END_FUNCTION_BLOCK