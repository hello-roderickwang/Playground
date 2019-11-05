# IMT System Changes for new UI

This is a list of changes that are required to accommodate the new UI.

In order to install new packages on an *existing* robot that has a current production build, the apt sources list must be enabled.

	/etc/apt/sources.list.orig => /etc/apt/sources.list

Then update package list:

	sudo apt-get update

### 1. node.js

Node.js (version 8 or later) is now a required ubuntu package.

For installation notes via package manager, see: https://nodejs.org/en/download/package-manager/

Quick summary for Ubuntu:

	$ curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
	$ sudo apt-get install nodejs

#### Update npm

After installing or updating node.js, the package manager `npm` should be updated. This needs to be performed as root:

	sudo npm i -g npm

**NOTE:** *All other npm installs for application dependencies should be run as a normal user. The above is the only time you need to run node or npm as root.*

### 2. Install third-party node packages (application dependencies)

The application itself makes use of a number of node packages, which are installed via `npm`.

These can be installed from within the `flow-ui` directory with:

	npm install

### 3a. Modify `go` bash script

The `go` bash script in `robot/crob/go` needs a one line change. The line that spawns notifyerror must be changed from:

	./notifyerror -d

to

	./notifyerror -d &

as to not block the child process spawned by node.js.

### 3b. Modify `clock.tcl`

When spawned as a child process from node.js, output to `/dev/tty` seems to be blocked.

Current workaround is to remove 2 instances where output is directed to `/dev/tty`.

So in `robot/lgames/clock/clock.tcl` change:

	exec ./gppm2.tcl $fn4 > /dev/tty &

to:

	exec ./gppm2.tcl $fn4 &

And:

	exec ./gppm2.tcl $fn2 > /dev/tty &

to:

	exec ./gppm2.tcl $fn2 &

### 4. UI auto-start on login

Can be added to XFCE's auto-started applications list.

Right click the desktop, from that menu select:

*Applications > Settings > Settings Manager > Session and Startup*

Then the *Application Autostart* tab.

Add an entry called "Bionik UI" with the command:

    /opt/imt/robot/lgames/flow-ui/node_modules/.bin/electron /opt/imd/robot/lgames/flow-ui/app/index.js -fs

See: https://wiki.archlinux.org/index.php/Xfce#Startup_applications

The above can be added manually. In the directory:

	~/.config/autostart

add a file called, for example: `BionikUI.desktop` that contains:

	[Desktop Entry]
	Encoding=UTF-8
	Version=0.9.4
	Type=Application
	Name=Bionik UI
	Comment=Launches Bionik GUI
	Exec=/opt/imt/robot/lgames/flow-ui/node_modules/.bin/electron /opt/imd/robot/lgames/flow-ui/app/index.js -fs
	OnlyShowIn=XFCE
	StartupNotify=false
	Terminal=false
	Hidden=false

### 5. Suppress file manager window popups when inserting USB drives

To prevent file manager windows from appearing overtop the appliation, XFCE's Thunar (file manager) can be configured to suppress those.

Right click the desktop, from that menu select:

*Application > Settings > Removable Drives and Media*

On that window ensure that the "Browse removable media when inserted" is un-checked.

See: https://docs.xfce.org/xfce/thunar/using-removable-media

The above can be configured manually. In the directory:

	~/.config/xfce4/xfconf/xfce-perchannel-xml

Edit the file: `thunar-volman.xml`

Change the entry for `autobrowse` and set it to `false`.

### 6. Hiding the taskbar/panel (top bar in Ubuntu)

(If desired)

This command could be run to hide for the lifetime of the app:

	nohup xfce4-panel &
