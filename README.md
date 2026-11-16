# XY Cartesian system with extruder and pressure compensation

A B&R Automation Studio project that simulates an XY Cartesian system with an extruder, modelled on a 3D printer. 
It runs entirely in simulation (ARsim), without physical hardware.

## 1. Tools and environment

| Tool | Version used |
|---|---|
| B&R Automation Studio | 4.12.10.39 |
| Automation Runtime | J4.93 (ARsim) |
| mapp Motion | 5.29.1 |
| mapp Services | 5.24.7 |
| mapp Control | 5.24.2 |
| mapp View | 5.24.7 |
| mapp Cockpit | 5.24.4 |

The Automation Studio version is slightly newer than the 4.12.9.18 named in the assignment. 
The hardware configuration `Sim` uses an X20CP1586 only as a simulation target. 
There are no drives: all six axes are purely virtual axes calculated on the controller.

## 2. Open and run the project

1. Open `RobozeProject.apj` in Automation Studio. The technology packages from the table above must be installed.
2. **Adjust the CNC program folder.** The file device `CNC_PrgDir` points to an absolute path, `C:\projects\RobozeProject\CncPrograms`. 
If the project is in a different folder, change the path in the Physical View: right-click `X20CP1586` → **Configuration** → **File devices**.
3. Activate the simulation.
4. Run Rebuild configuration, transfer to the target, and perform a warm restart.
5. Open the operator page in Google Chrome: `http://localhost:81/index.html?visuId=PrinterVisu`
6. Wait until the state reads **Ready**, then press **Start**. The program heats to 200 °C, waits until the temperature is stable, and prints.

mapp Cockpit (for traces) is at `http://localhost:8084/mappCockpit`.

### CNC programs

`CncPrograms/Print.cnc` - The assignment's print program (default) 
`CncPrograms/PaExample.cnc` - Single move that reproduces the assignment's numerical example
`CncPrograms/Test.cnc` - Short scratch program used during development 

The program to run is `gMotion.Par.ProgramName` (changeable in the Watch window).
