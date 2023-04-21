# InstrumentConnection
MATLAB scripts for simpler data acquisition routines.


## Description

A set of MATLAB scripts for connection to selected laboratory instruments, intended to enable simpler composition of data acquisition routines.

> *Note: this library is not fully completed. Notably, DSO device interaction has not been integrated into the standard functions and remains separately included in the `./routines/dev_*` files. Additionally not all interface methods are fully checked or implemented. However, it is in a functional state and has been used for years in a real laboratory setting for data acquisition*


## Install

Clone this repository and add it to your MATLAB path. Sample data collection routines are present in the [`./routines/`](./routines/) folder.

### Dependencies

Operation without modification relies on `plotStandard2D.m` and `figureSize.m` from my [general MATLAB utilities repository](https://github.com/nickersonm/MATLAB-utilities). These are plotting helpers that can be manually replaced if desired.


## Configuration

Review and modify or create instrument definitions as needed: instruments are defined in the `map<instrument>.m` files as elements of a structure array. Each instrument map includes documentation for the required fields. Several sample instruments are included.


## Usage

Use the `iface<instrument>` functions for simplified and standardized interaction with laboratory instruments.

Sample measurement "routines" are provided in the `./routines/` folder for common tasks, such as `simple_IV.m` to take an IV-measurement with DMMs.


## Extension

Additional instrument models for specific instrument types can be added by creating new `inst<instrument>_<model>` functions and assigning them in the appropriate `map<instrument>` function. They must implement the interfaces expected by `iface<instrument>` functions. Templates are provided by `inst<instrument>_Prototype` functions.

Additional capabilities for the defined instrument types can be added by extending `iface<instrument>` functions and implementing the appropriate behavior in the `inst<instrument>_<model>` functions.
