
TYPE
	MotionStateEnum : 
		(
		MOTION_INIT,
		MOTION_POWER_ON,
		MOTION_HOMING,
		MOTION_READY,
		MOTION_STARTING,
		MOTION_RUNNING,
		MOTION_STOPPING,
		MOTION_ERROR,
		MOTION_RESETTING
		);
	MotionErrorSourceEnum : 
		(
		MOTION_ERR_NONE,
		MOTION_ERR_GROUP, (*CNC axes group or program*)
		MOTION_ERR_TEMPERATURE,
		MOTION_ERR_MOTOR_AXES
		);
	MotionCmdType : 	STRUCT 
		Start : BOOL; (*Start the G-code program*)
		Stop : BOOL; (*Stop the running program*)
		ErrorReset : BOOL; (*Acknowledge an error*)
	END_STRUCT;
	MotionParType : 	STRUCT 
		ProgramName : STRING[80]; (*G-code program file name*)
	END_STRUCT;
	MotionStatusType : 	STRUCT 
		State : MotionStateEnum;
		Ready : BOOL; (*Powered, homed and idle*)
		Running : BOOL; (*Program is executing*)
		Done : BOOL; (*Last program finished normally*)
		Error : BOOL;
		ErrorID : DINT; (*Error number of the failed command or group*)
		ErrorSource : MotionErrorSourceEnum; (*Component that caused the error*)
	END_STRUCT;
	MotionType : 	STRUCT 
		Cmd : MotionCmdType;
		Par : MotionParType;
		Status : MotionStatusType;
	END_STRUCT;
	TempCmdType : 	STRUCT 
		HeaterOn : BOOL; (*Switch temperature control on*)
		ErrorReset : BOOL; (*Acknowledge an error*)
	END_STRUCT;
	TempParType : 	STRUCT 
		SetTemperature : REAL; (*Setpoint [degC]*)
		Tolerance : REAL; (*Allowed deviation for "stable" [degC]*)
		StableTime : TIME; (*Time the temperature must stay in tolerance*)
		Timeout : TIME; (*Maximum time to become stable*)
	END_STRUCT;
	TempStatusType : 	STRUCT 
		ActualTemperature : REAL; (*Simulated measured temperature [degC]*)
		Heating : BOOL; (*Controller is active*)
		Stable : BOOL; (*Setpoint reached and stabilized*)
		HeatUpTimeout : BOOL; (*Not stable within the timeout*)
		Error : BOOL;
		StatusID : DINT; (*Status of the mapp component*)
	END_STRUCT;
	TempType : 	STRUCT 
		Cmd : TempCmdType;
		Par : TempParType;
		Status : TempStatusType;
	END_STRUCT;
	AxisValueType : 	STRUCT 
		Position : LREAL; (*[mm]*)
		Velocity : REAL; (*[mm/s]*)
	END_STRUCT;
	AxesCmdType : 	STRUCT 
		ErrorReset : BOOL; (*Acknowledge a motor axis error*)
		SimulateError : BOOL; (*Test aid: force a motor axis error*)
	END_STRUCT;
	AxesStatusType : 	STRUCT 
		NomX : AxisValueType; (*Nominal CNC values*)
		NomY : AxisValueType;
		NomE : AxisValueType;
		MotX : AxisValueType; (*Simulated motor values*)
		MotY : AxisValueType;
		MotE : AxisValueType;
		ECorrection : LREAL; (*Pressure advance correction added to E [mm]*)
		ECommand : LREAL; (*Compensated E position sent to the motor [mm]*)
		PaKEffective : REAL; (*K currently applied [s]*)
		Coupled : BOOL; (*All motor axes follow their setpoints*)
		Error : BOOL;
		ErrorID : DINT;
	END_STRUCT;
	AxesParType : 	STRUCT 
		PaEnable : BOOL; (*Pressure advance on/off*)
		PaK : REAL; (*Pressure advance coefficient K [s]*)
		PaKRampRate : REAL; (*Ramp rate for K changes [s/s]*)
	END_STRUCT;
	AxesType : 	STRUCT 
		Cmd : AxesCmdType;
		Par : AxesParType;
		Status : AxesStatusType;
	END_STRUCT;
END_TYPE
