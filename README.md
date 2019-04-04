[1]: https://github.com/lmco/tlrb_aib_phy
[2]: https://www.intel.com/content/www/us/en/architecture-and-technology/programmable/heterogeneous-integration/overview.html

# axi4_aib_bridge

This project builds on the Advanced Interface Bus (AIB) by adding a protocol bridge to convert Advanced
Microcontroller Bus Architecture (AMBA) Advanced eXtensible Interface 4 (AXI4) to AIB and vice versa. To achieve this,
AXI4 is converted to the lightweight Chiplet Protocol Interface (CPI) which is then directly mapped to AIB. The AXI4/AIB
Bridge enables the extension of the standard AXI4 interface across physically separate chiplets by leveraging AIB.
Converting AXI4 to AIB allows for a standard, low-power, low-latency, parallel chip-to-chip interface while maintaining
a high pin efficiency and at a minimal performance impact.

The AIB Register-Transfer Level (RTL) used in this project is leveraged from [tlrb_aib_phy][1]. To validate compliance
with AXI4, New Wave Design and Verification performed the functional test and simulation of the design and their full
report can be found in the 'doc' directory.

More information on the AIB and its specification can be found on Intel's website [here][2].

## Cloning

Since this repository uses git submodules, it's recommended to use the --recurse-submodules flag when cloning:
```
git clone --recurse-submodules https://github.com/lmco/axi4_aib_bridge.git
```

Otherwise the submodules can be pulled in to an already cloned repository by running the following git command:
```
git submodule update --init --recursive
```

## Dependencies

* [tlrb_aib_phy][1]

This project also requires the AXI4/CPI Bridge RTL source code from Micron to compile and run. Please contact Micron to 
request a copy of that code.

## Directory Structure

```
.
|   LICENSE                                             # License file
|   README.md                                           # This file
|   
+---doc                                                 # Documentation
|       DARPA_CHIPS_FinalTestAndIntegrationReport.pdf   # Test & Integration Report for AXI4/AIB Bridge
|       
+---lib                                                 # Submodules
|   \---tlrb_aib_phy
|                   
\---rtl                                                 # AXI4/AIB Bridge source files
        axim_cpi_aib_aib_cpi_axis.v
        master_cpi_aib.sv
        slave_cpi_aib.sv
```

## Authors

* Lockheed Martin Corporation
* New Wave Design and Verification

## License

This project is licensed under the Apache 2.0 License - see the LICENSE file for more details

## Distribution Statement

DISTRIBUTION STATEMENT A. Approved for public release.

The views, opinions and/or findings expressed are those of the author and should not be interpreted as representing the
official views or policies of the Department of Defense or the U.S. Government.
