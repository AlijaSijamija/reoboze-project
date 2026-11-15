
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
	END_STRUCT;
	MotionType : 	STRUCT 
		Cmd : MotionCmdType;
		Par : MotionParType;
		Status : MotionStatusType;
	END_STRUCT;
END_TYPE
