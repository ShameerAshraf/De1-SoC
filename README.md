# De1-SoC Programs
> These programs were written as part of a course on Computer Organization in either the ARM Assembly Language or in C.

## Hardware
* **The [De1-SoC Board](http://www.de1-soc.terasic.com/)**

## Software
* **Intel Monitor Program available through the [Intel FPGA University Program](https://www.intel.com/content/www/us/en/programmable/support/training/university/overview.html)**
* **A Text Editor. Or not.**

## Testing using the Monitor Program
#### Copy one of the code examples into a new folder. Make note of the language (C/Assembly) and the program type (Basic/Exceptions)
#### Create a New Project

* Select the directory with the code file(s), enter a project name, choose the **ARM Cortex-A9 architecture**
* Choose the **De1-SoC Computer System** (The system details should automatically load into their fields).
* Choose the program type (C/Assembly).
* Add the project file(s) of either **.c** or **.s** or both. For programs from the **Assembly - Exceptions** folder, add the main file along with the **config_GIC.s** file.
* Make sure the board is ON and connected to the computer with the USB Blaster Cable, click refresh and select the following:

> **Host Connection**: De-SoC
> **Processor**: ARM\_A9\_HPS\_arm\_a9\_0
> **Terminal Device**: JTAG\_UART\_for\_ARM\_0

* Choose **basic** or **exceptions** in the **Linker Section Presets** field depending on the type of program files included in the project.
* Click **Save**

#### The Monitor Program will load the De1-SoC Computer System onto the board.
#### Go to actions -> Compile & Load or actions -> Compile to quickly check for any syntax errors.
#### Run the program. For smaller programs in the Assembly Language, use step-by-step execution to observe the changes in the process registers, in memory and on the De1-SoC board.

*Refer to Intel FPGA University Program for documents on ARM Assembly Language, De1-SoC Board and Intel Monitor Program*

