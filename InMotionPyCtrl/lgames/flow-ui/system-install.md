# Robot Installation

This documents supplements the documents `creating-g2-masters.html` and `installing-g2-software.html`.

Follow the `creating-g2-masters.html` document until the step that instructs to run `bootstrap`. Instead of running that script, perform the following:

### Install node.js 8.x LTS

Add repository:

	curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -

#### Install node package

	sudo apt-get install -y nodejs

### Clone the imt git repository

	cd ~
	git clone https://wsbionik@github.com/atannen/imt.git

(You will be prompted for the github account password.)

Then `cd` into the `imt` git repo directory and checkout the `flow-ui` branch:

	cd ~/imt
	git checkout flow-ui

Install UI dependencies via npm and build:

	cd ~/imt/robot4/lgames/flow-ui
	npm install
	npm run build

### Move sources to /opt/imt

	sudo mkdir -p /opt/imt
	sudo mv robot4 /opt/imt/[version]
	sudo ln -s /opt/imt/[version] /opt/imt/robot
	sudo mv distro /opt/imt/distro

Where `[version]` is typically the version of the robot software being installed. Eg: `robot4.1.20171123`

#### Cleanup by removing the git repo

	cd ~
	rm -rf imt

## Run postinstall

	sudo /opt/imt/distro/postinstall g2 noup

(The `noup` option indicates that the "up" server does not exist on the local network.)

The actions performed by the bootstrap script have now been replicated.

Continue following `creating-g2-masters.html` and `installing-g2-software.html`.

# Final Configurations

After the above is all completed, you should have working system and home disks.

### Create a `test` patient folder

	cd ~
	mkdir therapist/test

A `test` patient folder is required. Orientation activity data (which is not desired in reports) will be redirected here instead of to the patient's folder.

## Window Manager Tweaks

The following steps will make some Window Manager configurations to better accommodate the full-screen GUI.

### UI auto-start on login

Can be added to XFCE's auto-started applications list.

Right click the desktop, from that menu select:

*Applications > Settings > Session and Startup*

Then the *Application Autostart* tab.

Add an entry called "Bionik UI" with the command:

    /opt/imt/robot/lgames/flow-ui/node_modules/.bin/electron /opt/imt/robot/lgames/flow-ui/app/index.js -fs

See: https://wiki.archlinux.org/index.php/Xfce#Startup_applications

The above can be added manually. In the directory:

	~/.config/autostart

Add a file named `BionikUI.desktop` that contains:

	[Desktop Entry]
	Encoding=UTF-8
	Version=0.9.4
	Type=Application
	Name=Bionik UI
	Comment=Launches Bionik GUI
	Exec=/opt/imt/robot/lgames/flow-ui/node_modules/.bin/electron /opt/imt/robot/lgames/flow-ui/app/index.js -fs
	OnlyShowIn=XFCE
	StartupNotify=false
	Terminal=false
	Hidden=false

### Suppress file manager window popups when inserting USB drives

To prevent file manager windows from appearing overtop the appliation, XFCE's Thunar (file manager) can be configured to suppress those.

Right click the desktop, from that menu select:

*Application > Settings > Removable Drives and Media*

On that window ensure that the "Browse removable media when inserted" is un-checked.

See: https://docs.xfce.org/xfce/thunar/using-removable-media

The above can be configured manually. In the directory:

	~/.config/xfce4/xfconf/xfce-perchannel-xml

Edit the file: `thunar-volman.xml`

Change the entry for `autobrowse` and set it to `false`.

### Disable click-to-raise

In order to prevent confusing window-stacking ordering when legacy software popups appear.

*Application > Settings > Windows*

Un-check "Click to raise"

### Set black desktop background

*Application > Desktop Settings*

Set the "style" option to "none"

Use the colour picker to choose black (rgb 0,0,0).
