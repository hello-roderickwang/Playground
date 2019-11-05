# Cache Server Setup

This readme supplements the documents `creating-g2-masters.html` and `installing-g2-software.html`.

To create master disks on a robot, a server is needed to host certain files that are downloaded during installation.

For convenience this can be hosted locally on the office network.

## Recommended setup:

### Install Ubuntu Linux on a PC

Ideally this PC will have a static IP address on the network.

Create a USB install stick from https://www.ubuntu.com/

### Install net-tools

	sudo apt-get install net-tools

This installs `ifconfig` which will show you your IP and mac addresses.

### Install git

	sudo apt-get install git

### Install Apache

	sudo apt-get install apache2

This will auto-configure and start the apache server. It will serve files from:

	/var/www/html

### Clone git repo:

	git clone https://[username]@gitub.com/atannen/imt.git

(You will need to supply the git account's password when prompted.)

Then you will have the repo in `~/imt`. We will want to serve the files in `imt/distro`. To do that add a symlink in the directory apache is serving:

	cd /var/www/html
	sudo ln -s /home/imt/imt/distro distro

To test that your server is accessible within your network, try visiting:

	http://[server ip address]/distro/

The browser should display the list of files in the `distro` folder of the git repo.

Now you will need to make some changes to files in this repo. `cd` into this directory and create a new branch:

	cd ~/imt
	git checkout -b toronto-cache

(Tailor the branch name to suit your purposes.)

### Determine local server IP address

	ifconfig

Ideally this will be a static IP so the IP address only needs to be configure once for the steps below.

### Modify iso to use local cache server IP address

Edit the iso file in the `distro` folder using `isomaster`:

	isomaster 'ubuntu 1404 mini.iso'

Edit the file within that iso file called `txt.cfg`. Change the url from the address `10.192...` to your local cache server IP address.

Save a new ISO with this updated IP address baked into it.

### Modify preseed.cfg to use local cache serve IP address

Use a text editor to edit the file `distro/preseed.cfg`

Comment out the line:

	d-i mirror/http/proxy string http://10.218.158.1:3142/

i.e., change it to:

	# d-i mirror/http/proxy string http://10.218.158.1:3142/

Find the line with:

	http://10.218.158.1/distro/localdebs

And change that IP address to your local server's address.

### Burn ISO to bootable CD/DVD

If using Ubuntu, use the software manager to install `Brasero` to perform DVD burning. Burn your modified .iso file to a blank DVD.

### Boot the robot using the DVD to install its system disk

Follow steps in original documentation in `creating-g2-masters.html`
