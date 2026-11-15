def plc_global REAL gTemp.Par.SetTemperature as SetTemp
N1 G90
SetTemp=200
N2 M109
N3 G0 X38 Y80