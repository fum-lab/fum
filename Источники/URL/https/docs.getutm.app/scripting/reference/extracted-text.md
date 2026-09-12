# Извлечённый текст

Источник: <https://docs.getutm.app/scripting/reference/>

## Содержимое

Reference | UTM Documentation Skip to main content
Home
Installation
iOS
macOS
Basics
Actions
Controls
Settings (QEMU)
Devices
Display
Network
Port Forwarding
Serial
Sound
Drive
Resize and Compress
Information
Input
QEMU
Sharing
System
Settings (Apple)
Boot
Devices
Display
Network
Port Forwarding
Serial
Drive
Information
Sharing
System
Virtualization
Preferences
iOS
macOS
Guest Support
Dynamic Resolution
Linux
Sharing
Clipboard
Directory
USB
Windows
macOS
Advanced
Disposable
Headless
Multiple Displays
Recovery (macOS)
Remote Control
Rosetta
Serial
Version
Scripting
Cheat Sheet
Reference
Remote
UTM Server
Guides
Classic Mac OS
Classic Windows
Debian 11 + Rosetta
Fedora 36
Kali Linux 2022
Ubuntu 22.04
Windows 10
Windows 11
Updates
v4.0
v4.1
v4.2
v4.3
v4.4
v4.5
v4.6
v4.7
UTM for macOS
UTM for iOS
Discord
GitHub
This site uses Just the Docs , a documentation theme for Jekyll.
Scripting
Reference
UTM Suite UTM virtual machines scripting suite.
make v : Create a new virtual machine.
make
new type : Specify 'virtual machine' here.
with properties record : You must specify the backend as well as a configuration with a name. If this is a QEMU virtual machine, you must specify the architecture in the configuration as well.
→ specifier : The new virtual machine (as a specifier).
application n [see also UTM USB Devices Suite ] : An application's top level scripting object.
Elements
contains virtual machines .
Properties
auto terminate (boolean) : Auto terminate the application when all windows are closed?
UTM version (text, r/o) : The version number of UTM.
backend enum : Backend type.
apple : Apple Virtualization.framework backend.
qemu : QEMU backend.
unavailable : The virtual machine is not currently available.
status enum : Status type.
stopped : VM is not running.
starting : VM is starting up.
started : VM is running.
pausing : VM is going to pause.
paused : VM is paused.
resuming : VM is resuming from pause.
stopping : VM is stopping.
stop method enum : Stop by method.
force : Force stop VM by sending stop request to the backend.
kill : Force kill VM by terminating the backend.
request : Send a power down request to the guest OS which may be ignored.
serial interface enum : Serial port interface.
ptty : Pseudo TTY port.
tcp : TCP port.
unavailable : Serial interface is currently unavailable or is in use by the GUI.
start v : Start a virtual machine or resume a suspended virtual machine.
start virtual machine : Virtual machine to start.
[ saving boolean] : When false, do not save the VM changes to disk. Default value is true.
[ recovery boolean] : When true, start the VM in recovery mode. Default value is false.
suspend v : Suspend a running virtual machine to memory.
suspend virtual machine : Virtual machine to suspend.
[ saving boolean] : Save VM state to disk after suspend. Default value is false.
stop v : Shuts down a running virtual machine.
stop virtual machine : Virtual machine to stop.
[ by force/‌kill/‌request] : Method to stop the VM.
delete v : Delete a virtual machine. All data will be deleted, there is no confirmation!
delete virtual machine : The virtual machine to delete.
duplicate v : Copy an virtual machine and all its data.
duplicate virtual machine : The virtual machine to copy.
[ with properties record] : Only the configuration can be changed.
import v : Import a new virtual machine from a file.
import
new type : Specify 'virtual machine' here.
from file : The virtual machine file (.utm) to import.
→ specifier : The new virtual machine (as a specifier).
export v : Export a virtual machine to a specified location.
export virtual machine : The virtual machine to export.
to file : Location to export the VM to.
virtual machine n [see also UTM Guest Suite , UTM Configuration Suite , UTM USB Devices Suite , UTM Registry Suite , UTM Input Automation Suite ] : A virtual machine registered in UTM.
Elements
contains serial ports ; contained by application .
Properties
id (text, r/o) : The unique identifier of the VM.
name (text, r/o) : The name of the VM.
backend (apple/‌qemu/‌unavailable, r/o) : Emulation/virtualization engine used.
status (stopped/‌starting/‌started/‌pausing/‌paused/‌resuming/‌stopping, r/o) : Current running status.
responds to
start , suspend , stop , delete .
serial port n : A serial port in the guest that can be connected to from the host.
Elements
contained by virtual machines .
Properties
id (integer, r/o) : The unique identifier of the tag.
interface (ptty/‌tcp/‌unavailable, r/o) : The type of serial interface on the host.
address (text, r/o) : Host address of the serial port (determined by the interface type).
port (integer, r/o) : Port number of the serial port (not used in some interface types).
UTM Guest Suite UTM virtual machine guest scripting suite. In order to use these commands, QEMU guest agent must be running.
virtual machine n [see also UTM Suite , UTM Configuration Suite , UTM USB Devices Suite , UTM Registry Suite , UTM Input Automation Suite ] : Guest agent access.
Elements
contains guest files , guest processes .
responds to
open file , execute , query ip .
open mode enum : File open mode.
reading : Open the file as read only. The file must exist.
writing : Open the file for writing. If the file does not exist, it will be created. If the file exists, it will be overwritten.
appending : Open the file for writing at the end. Offsets are ignored for writes. If the file does not exist, it will be created.
open file v : Open a file on the guest. You must close the file when you are done to prevent leaking guest resources.
open file virtual machine : Virtual machine of the guest.
at text : The guest path of the file to open.
[ for reading/‌writing/‌appending] : Open mode.
[ updating boolean] : If true, will open for both reading and writing. The file existance requirement and creation is still governed by the open mode. Default is false.
→ guest file : Guest file to operate on.
execute v : Execute a command or script on the guest.
execute virtual machine : Virtual machine of the guest.
at text : Either the full path of the executable to run or an executable found in the guest's PATH environment.
[ with arguments list of text] : List of arguments to pass to the executable.
[ with environment list of text] : List of environment variables to pass to the executable. Each entry should be in the format NAME=VALUE.
[ using input text] : Data to feed into the process's standard input. If using base64 encoding, this should be a valid base64 string.
[ base64 encoding boolean] : Input data is base64 encoded. The data will be decoded before being passed to the executable. Default is false.
[ output capturing boolean] : If true, the standard output and error will be captured and accessible in the returned object. You need to call update on the object to get the data. Default is false.
→ guest process : Guest process that can be used to fetch the return value and outputs (if captured).
query ip v : Query the guest for all IP addresses on its network interfaces (excluding loopback).
query ip virtual machine : Virtual machine of the guest.
→ list of text : List of IP addresses on all network interfaces (excluding loopback). Both IPv4 and IPv6 addresses can be returned. IPv4 addresses will show up before IPv6 addresses if any are available.
guest file n : A file that resides on the guest.
Elements
contained by virtual machines .
Properties
id (integer, r/o) : The handle for the file.
responds to
read , pull , write , push , close .
whence enum : Where to offset from.
start position : The start of the file (only positive offsets).
current position : The current pointer (both positive and negative offsets).
end position : The end of the file (only negative offsets for reads, both for writes).
read v : Reads text data from a guest file.
read guest file : Guest file to read.
[ at offset integer] : Specify the offset to start reading from. Default value is zero.
[ from start position/‌current position/‌end position] : Specify where the offset is from. Default value is from the current file pointer.
[ for length integer] : Amount of bytes to read. The limit is 48 MB. Default is to read until the end.
[ base64 encoding boolean] : If true, then the result will be base64 encoded. This is recommended if you are reading a binary file. Default is false.
[ closing boolean] : If true, the file will be closed after reading and must be opened again to perform more operations. If false, you can perform multiple reads on the same open file. The default is true.
→ text : Data read from the guest file.
pull v : Pulls a file from the guest to the host.
pull guest file : Guest file to pull.
to file : The host file in which to save the guest file.
[ closing boolean] : If true, the file will be closed after reading and must be opened again to perform more operations. If false, you can perform multiple reads on the same open file. The default is true.
write v : Writes text data to a guest file.
write guest file : Guest file to write.
with data text : Data to write to the guest file. If base64 encoding is specified, this should be a valid base64 string which will be decoded before writing.
[ at offset integer] : Specify the offset to start writing to. Default value is zero.
[ from start position/‌current position/‌end position] : Specify where the offset is from. Default value is from the current file pointer.
[ base64 encoding boolean] : If true, then the input data is base64 encoded. This is recommended if you are writing a binary file. Default is false.
[ closing boolean] : If true, the file will be closed after writing and must be opened again to perform more operations. If false, you can perform multiple reads on the same open file. The default is true.
push v : Pushes a file from the host to the guest and closes it.
push guest file : Guest file to push.
from file : The host file in which to send to the guest.
[ closing boolean] : If true, the file will be closed after writing and must be opened again to perform more operations. If false, you can perform multiple reads on the same open file. The default is true.
close v : Closes the file and prevent further operations.
close guest file : Guest file to close.
guest process n , pl guest processes : A process on the guest.
Elements
contained by virtual machines .
Properties
id (integer, r/o) : The PID of the process.
responds to
get result .
execute result n : Process results after execution.
Properties
exited (boolean, r/o) : If true, the process has terminated.
exit code (integer, r/o) : Exit code if it was normally terminated.
signal code (integer, r/o) : Signal number (Linux) or unhandled exception code (Windows) if the process was abnormally terminated.
output text (text, r/o) : If capture is enabled, the stdout of the process as text.
error text (text, r/o) : If capture is enabled, the stderr of the process as text.
output data (text, r/o) : If capture is enabled, the stdout of the process as base64 encoded data.
error data (text, r/o) : If capture is enabled, the stderr of the process as base64 encoded data.
get result v : Fetch execution result from the guest.
get result guest process : Guest process to fetch result from.
→ execute result : Result from the guest.
UTM Configuration Suite UTM virtual machine configuration suite. Use this to create and configurate virtual machines.
virtual machine n [see also UTM Suite , UTM Guest Suite , UTM USB Devices Suite , UTM Registry Suite , UTM Input Automation Suite ] : Virtual machine configuration.
Properties
configuration ( qemu configuration or apple configuration , r/o) : The configuration of the virtual machine.
responds to
update configuration .
update configuration v : Update the configuration of the virtual machine. The VM must be in the stopped state.
update configuration virtual machine : Virtual machine to configure.
with qemu configuration or apple configuration : The configuration to update the virtual machine. You cannot change the backend with this!
qemu configuration n : QEMU virtual machine configuration.
Properties
name (text) : Virtual machine name.
icon (text) : Virtual machine icon.
notes (text) : User-specified notes.
architecture (text) : QEMU system architecture.
machine (text) : QEMU target machine (if empty, the default will be used).
memory (integer) : RAM size (in mebibytes).
cpu cores (integer) : Number of CPU cores (0 is the default for this host).
hypervisor (boolean) : Use the hypervisor (if supported)?
uefi (boolean) : Use UEFI boot?
directory share mode (none/‌WebDAV/‌VirtFS) : Mode for directory sharing.
drives (list of qemu drive configuration ) : List of drive configuration.
network interfaces (list of qemu network configuration ) : List of network configuration.
serial ports (list of qemu serial configuration ) : List of serial configuration.
displays (list of qemu display configuration ) : List of display configuration.
qemu additional arguments (list of qemu argument ) : List of qemu arguments.
qemu directory share mode enum : Method for sharing directory in QEMU.
none : Do not enable directory sharing.
WebDAV : Use SPICE WebDav (SPICE guest tools required).
VirtFS : Use VirtFS mount tagged 'share' (VirtFS guest drivers required).
qemu drive configuration n : QEMU virtual existing drive configuration.
Properties
id (text, r/o) : The unique identifier for this drive (if empty, a new drive will be created).
removable (boolean, r/o) : Is this drive removable (cannot be changed after creation)?
interface (none/‌IDE/‌SCSI/‌SD/‌MTD/‌Floppy/‌PFlash/‌VirtIO/‌NVMe/‌USB) : The hardware interface this drive is attached to (if empty, the default will be used).
host size (integer, r/o) : The size of this drive as seen by the host (in MiB).
guest size (integer) : The size of this drive as seen by the guest (in MiB).
raw (boolean) : Is this disk image raw format (only for newly created drives)?
source (file) : An existing file to use as the source image.
qemu network configuration n : QEMU virtual network configuration.
Properties
index (integer) : The position of the configuration to update. It can be empty to create a new device. Index is invalid after updating the configuration and must be reset to the current position.
hardware (text) : Name of the emulated network card (if empty, the default will be used).
mode (emulated/‌shared/‌host/‌bridged) : This determines how the network device is attached to the host.
address (text) : MAC address (formatted as XX:XX:XX:XX:XX:XX, if empty a random address will be genertaed)
host interface (text) : Only used in bridged mode. Specify the interface name to bridge to.
port forwards (list of qemu port forward ) : Only used in emulated mode. Allows port forwarding from guest to host.
qemu network mode enum : Mode for networking device.
emulated : Emulate a VLAN.
shared : NAT based sharing with the host.
host : NAT based sharing with no WAN routing.
bridged : Bridged to a host interface.
qemu port forward n : QEMU port forward configuration.
Properties
protocol (TCP/‌UDP) : Protocol of the port that will be forwarded.
host address (text) : The host interface IP address to forward to (if empty, it will forward to any interface).
host port (integer) : Port number on the host.
guest address (text) : The IP address on the guest subnet to forward from (if empty, any guest IP will be accepted).
guest port (integer) : Port number on the guest.
qemu serial configuration n : QEMU virtual serial configuration.
Properties
index (integer) : The position of the configuration to update. It can be empty to create a new device. Index is invalid after updating the configuration and must be reset to the current position.
hardware (text) : Name of the emulated serial device (if empty, the default will be used).
interface (ptty/‌tcp/‌unavailable) : The type of serial interface on the host.
port (integer) : The port number to listen on when the interface is a TCP server.
qemu display configuration n : QEMU virtual display configuration.
Properties
index (integer) : The position of the configuration to update. It can be empty to create a new device. Index is invalid after updating the configuration and must be reset to the current position.
hardware (text) : Name of the emulated display card (required. if given hardware not found, the default will be used).
dynamic resolution (boolean) : If true, attempt to use SPICE guest agent to change the display resolution automatically.
native resolution (boolean) : If true, use the true (retina) resolution of the display. Otherwise, use the percieved resolution.
upscaling filter (linear/‌nearest) : Filter to use when upscaling.
downscaling filter (linear/‌nearest) : Filter to use when downscaling.
qemu argument n : QEMU argument configuration.
Properties
argument string (text) : The QEMU argument as a string.
file urls (list of file) : Optional URLs associated with this argument.
apple configuration n : Apple virtual machine configuration.
Properties
name (text) : Virtual machine name.
icon (text) : Virtual machine icon.
notes (text) : User-specified notes.
memory (integer) : RAM size (in mebibytes).
cpu cores (integer) : Number of CPU cores (0 is the default for this host).
directory shares (list of apple directory share configuration ) : List of directory share configuration.
drives (list of apple drive configuration ) : List of drive configuration.
network interfaces (list of apple network configuration ) : List of network configuration.
serial ports (list of apple serial configuration ) : List of serial configuration.
displays (list of apple display configuration ) : List of display configuration.
apple directory share configuration n : Apple directory share configuration.
Properties
index (integer) : The position of the configuration to update. It can be empty to create a new device. Index is invalid after updating the configuration and must be reset to the current position.
read only (boolean, r/o) : Is this directory read-only?
apple drive configuration n : Apple virtual existing drive configuration.
Properties
id (text, r/o) : The unique identifier for this drive (if empty, a new drive will be created).
removable (boolean, r/o) : Is this drive removable (cannot be changed after creation)?
host size (integer, r/o) : The size of this drive as seen by the host (in MiB).
guest size (integer) : The size of this drive as seen by the guest (in MiB).
source (file) : An existing file to use as the source image.
apple network configuration n : Apple virtual network configuration.
Properties
index (integer) : The position of the configuration to update. It can be empty to create a new device. Index is invalid after updating the configuration and must be reset to the current position.
mode (shared/‌bridged) : This determines how the network device is attached to the host.
address (text) : MAC address (formatted as XX:XX:XX:XX:XX:XX, if empty a random address will be genertaed)
host interface (text) : Only used in bridged mode. Specify the interface name to bridge to.
apple network mode enum : Mode for networking device.
shared : NAT based sharing with the host.
bridged : Bridged to a host interface.
apple serial configuration n : Apple virtual serial configuration.
Properties
index (integer) : The position of the configuration to update. It can be empty to create a new device. Index is invalid after updating the configuration and must be reset to the current position.
interface (ptty/‌tcp/‌unavailable) : The type of serial interface on the host (only PTTY is supported).
apple display configuration n : Apple virtual display configuration.
Properties
id (text, r/o) : The unique identifier for this display (if empty, a new display will be created).
dynamic resolution (boolean) : Dynamic Resolution.
UTM USB Devices Suite UTM virtual machine USB devices suite. Use this to connect USB devices from the host to the guest.
application n [see also UTM Suite ] : An application's top level scripting object.
Elements
contains usb devices .
usb device n : A host USB device that is shared with the guest.
Elements
contained by application , virtual machines .
Properties
id (integer, r/o) : A unique identifier corrosponding to the USB bus and port number.
name (text, r/o) : The name of the USB device.
manufacturer name (text, r/o) : The product name described by the iManufacturer descriptor.
product name (text, r/o) : The product name described by the iProduct descriptor.
vendor id (integer, r/o) : The vendor ID described by the idVendor descriptor.
product id (integer, r/o) : The product ID described by the idProduct descriptor.
responds to
connect , disconnect .
virtual machine n [see also UTM Suite , UTM Guest Suite , UTM Configuration Suite , UTM Registry Suite , UTM Input Automation Suite ] : Virtual machine USB devices.
Elements
contains usb devices .
connect v : Connect a USB device to a running VM and remove it from the host.
connect usb device : The USB device to connect to the VM.
to virtual machine : The virtual machine to connect. The virtual machine must be running. Not all backends support USB sharing.
disconnect v : Disconnect a USB device from the guest and re-assign it to the host.
disconnect usb device : The USB device to disconnect.
UTM Registry Suite UTM virtual machine registry suite. Use this to update virtual machine registry.
virtual machine n [see also UTM Suite , UTM Guest Suite , UTM Configuration Suite , UTM USB Devices Suite , UTM Input Automation Suite ] : Virtual machine registry.
Properties
registry (list of file, r/o) : The registry of the virtual machine.
responds to
update registry .
update registry v : Update the registry of the virtual machine.
update registry virtual machine : Virtual machine to update.
with list of file : The registry to update the virtual machine. Currently you can only change the shared directory with this!
UTM Input Automation Suite UTM virtual machine input automation suite. Only supported on QEMU backend.
virtual machine n [see also UTM Suite , UTM Guest Suite , UTM Configuration Suite , UTM USB Devices Suite , UTM Registry Suite ] : Input automation.
responds to
input scan code , input keystroke , input mouse click .
input scan code v : Send raw PC AT scan codes. Only supported on QEMU backend.
input scan code virtual machine : Virtual machine to send scan code to.
codes list of integer : List of PC AT scan codes.
modifier key enum : Modifier key to send with keystroke.
caps lock : Caps Lock (⇪)
shift : Shift (⇧)
control : Control (⌃)
option : Option (⌥)
command : Command (⌘)
escape : Escape (⎋)
input keystroke v : Send text as a sequence of keystrokes to the virtual machine. Only supported on QEMU backend.
input keystroke virtual machine : Virtual machine to send keystrokes to.
text text : ASCII characters to send as a sequence.
[ with modifiers list of caps lock/‌shift/‌control/‌option/‌command/‌escape] : List of modifier keys to hold down while sending key sequence.
mouse button enum : Mouse button.
left : Left Click
right : Right Click
middle : Middle Click
input mouse click v : Send a mouse position and click to the virtual machine. Only supported on QEMU backend.
input mouse click virtual machine : Virtual machine to send scan code to.
at list of integer : X-Y coordinate of the absolute position on screen to perform the click. Must be a list of two numbers.
[ to integer] : Which monitor to target (starting at 1). If omitted, the first monitor will be used.
[ with mouse button left/‌right/‌middle] : Mouse button to click. If omitted, a left click will be used.
Edit this page on GitHub

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 03:39:53 MSK -->
<!-- content-sha256: sha256:84c7744e9c11cfc4c832d93b936a06b9417349a5b6f8547f8676d66191fb0515 -->
<!-- FUM-MD-RECENCY:END -->
