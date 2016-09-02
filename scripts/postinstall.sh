#!/bin/bash
# -*- coding: utf-8 -*-
#
#  postinstall.sh
#
#  Copyright © 2013-2016 Antergos
#
#  This file is part of Cnchi.
#
#  Cnchi is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  Cnchi is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  The following additional terms are in effect as per Section 7 of the license:
#
#  The preservation of all legal notices and author attributions in
#  the material or in the Appropriate Legal Notices displayed
#  by works containing it is required.
#
#  You should have received a copy of the GNU General Public License
#  along with Cnchi; If not, see <http://www.gnu.org/licenses/>.

# Set xorg config files
set_xorg() {
	cp /usr/share/cnchi/scripts/postinstall/50-synaptics.conf ${CN_DESTDIR}/etc/X11/xorg.conf.d/50-synaptics.conf
	cp /usr/share/cnchi/scripts/postinstall/99-killX.conf ${CN_DESTDIR}/etc/X11/xorg.conf.d/99-killX.conf

	# Fix sensitivity for chromebooks
	if lsmod | grep -q cyapa; then
		cp /usr/share/cnchi/scripts/postinstall/50-cros-touchpad.conf ${CN_DESTDIR}/etc/X11/xorg.conf.d/50-cros-touchpad.conf
	fi
}

set_xscreensaver() {
  # xscreensaver config
	cp /usr/share/cnchi/scripts/postinstall/xscreensaver ${CN_DESTDIR}/home/${CN_USER_NAME}/.xscreensaver
	cp ${CN_DESTDIR}/home/${CN_USER_NAME}/.xscreensaver ${CN_DESTDIR}/etc/skel

	if [[ -f ${CN_DESTDIR}/etc/xdg/autostart/xscreensaver.desktop ]]; then
		rm ${CN_DESTDIR}/etc/xdg/autostart/xscreensaver.desktop
	fi
}

set_gsettings() {
	CN_SCHEMA_OVERRIDE='/usr/share/cnchi/scripts/90_antergos.gschema.override'
	CN_SCHEMA_DIR="${CN_DESTDIR}/usr/share/glib-2.0/schemas"

	# Set gsettings input-source
	if [[ "${CN_KEYBOARD_LAYOUT}" != '' ]]; then
	  if [[ "${CN_KEYBOARD_VARIANT}" != '' ]]; then
		  sed -i "s/'us'/'${CN_KEYBOARD_LAYOUT}+${CN_KEYBOARD_VARIANT}'/" /usr/share/cnchi/scripts/set-settings
		  sed -i "s/'us'/'${CN_KEYBOARD_LAYOUT}+${CN_KEYBOARD_VARIANT}'/" "${CN_SCHEMA_OVERRIDE}"
	  else
		  sed -i "s/'us'/'${CN_KEYBOARD_LAYOUT}'/" /usr/share/cnchi/scripts/set-settings
		  sed -i "s/'us'/'${CN_KEYBOARD_LAYOUT}'/" "${CN_SCHEMA_OVERRIDE}"
	  fi
	fi

	sed -i "s|@_BROWSER@|${_BROWSER}|g" "${CN_SCHEMA_OVERRIDE}"
	cp "${CN_SCHEMA_OVERRIDE}" "${CN_SCHEMA_DIR}"
	glib-compile-schemas "${CN_SCHEMA_DIR}"

#	cp /usr/share/cnchi/scripts/set-settings "${CN_DESTDIR}/usr/bin/set-settings"
#	chmod +x "${CN_DESTDIR}/usr/bin/set-settings"
#
#	mkdir -p "${CN_DESTDIR}/var/run/dbus"
#	mount --rbind /var/run/dbus "${CN_DESTDIR}/var/run/dbus"
#
#	mkdir -p "${CN_DESTDIR}/var/run/user/1000"
#	chown -R 1000:100 "${CN_DESTDIR}/var/run/user/1000"
#
#	arch-chroot "${CN_DESTDIR}" \
#		/usr/bin/sudo -u "${CN_USER_NAME}" /usr/bin/set-settings "${CN_DESKTOP}" >/dev/null 2>&1
#
#	rm "${CN_DESTDIR}/usr/bin/set-settings"
#	umount -l "${CN_DESTDIR}/var/run/dbus"
}

gnome_settings() {
	# Set gsettings
	set_gsettings

	# Set gdm shell logo
	cp /usr/share/antergos/logo.png ${CN_DESTDIR}/usr/share/antergos/

	# Set skel directory
	cp -R ${CN_DESTDIR}/home/${CN_USER_NAME}/.config ${CN_DESTDIR}/etc/skel

	# xscreensaver config
	set_xscreensaver

	# Ensure that Light Locker starts before gnome-shell
	# TODO: Need to do this another way
	sed -i 's|echo "X|/usr/bin/light-locker \&\nsleep 3; echo "X|g' ${CN_DESTDIR}/etc/lightdm/Xsession
}

cinnamon_settings() {
	# Set gsettings
	set_gsettings

	# Copy menu@cinnamon.org.json to set menu icon
	mkdir -p ${CN_DESTDIR}/home/${CN_USER_NAME}/.cinnamon/configs/menu@cinnamon.org/
	cp -f /usr/share/cnchi/scripts/postinstall/menu@cinnamon.org.json ${CN_DESTDIR}/home/${CN_USER_NAME}/.cinnamon/configs/menu@cinnamon.org/

	# Copy panel-launchers@cinnamon.org.json to set launchers
	if [[ firefox = "${CN_BROWSER}" ]]; then
		sed -i 's|chromium|firefox|g' /usr/share/cnchi/scripts/postinstall/panel-launchers@cinnamon.org.json
	fi
	mkdir -p ${CN_DESTDIR}/home/${CN_USER_NAME}/.cinnamon/configs/panel-launchers@cinnamon.org/
	cp -f /usr/share/cnchi/scripts/postinstall/panel-launchers@cinnamon.org.json ${CN_DESTDIR}/home/${CN_USER_NAME}/.cinnamon/configs/panel-launchers@cinnamon.org/

	# Set Cinnamon in .dmrc
	echo "[Desktop]" > ${CN_DESTDIR}/home/${CN_USER_NAME}/.dmrc
	echo "Session=cinnamon" >> ${CN_DESTDIR}/home/${CN_USER_NAME}/.dmrc
	chroot ${CN_DESTDIR} chown ${CN_USER_NAME}:users /home/${CN_USER_NAME}/.dmrc

	# Set skel directory
	cp -R ${CN_DESTDIR}/home/${CN_USER_NAME}/.config ${CN_DESTDIR}/home/${CN_USER_NAME}/.cinnamon ${CN_DESTDIR}/etc/skel

	# Populate our wallpapers in Cinnamon Settings
	chroot ${CN_DESTDIR} "ln -s /usr/share/antergos/wallpapers/ /home/${CN_USER_NAME}/.cinnamon/backgrounds/antergos" ${CN_USER_NAME}
}

xfce_settings() {
	# Set settings
	mkdir -p ${CN_DESTDIR}/home/${CN_USER_NAME}/.config/xfce4/xfconf/xfce-perchannel-xml
	cp -R ${CN_DESTDIR}/etc/xdg/xfce4/panel ${CN_DESTDIR}/etc/xdg/xfce4/helpers.rc ${CN_DESTDIR}/home/${CN_USER_NAME}/.config/xfce4
	if [[ ${CN_BROWSER} = "chromium" ]]; then
		sed -i "s/WebBrowser=firefox/WebBrowser=chromium/" ${CN_DESTDIR}/home/${CN_USER_NAME}/.config/xfce4/helpers.rc
	fi

	# Set skel directory
	cp -R ${CN_DESTDIR}/home/${CN_USER_NAME}/.config ${CN_DESTDIR}/etc/skel
	chroot ${CN_DESTDIR} chown -R ${CN_USER_NAME}:users /home/${CN_USER_NAME}

	set_gsettings

	# Set xfce in .dmrc
	echo "[Desktop]" > ${CN_DESTDIR}/home/${CN_USER_NAME}/.dmrc
	echo "Session=xfce" >> ${CN_DESTDIR}/home/${CN_USER_NAME}/.dmrc
	chroot ${CN_DESTDIR} chown ${CN_USER_NAME}:users /home/${CN_USER_NAME}/.dmrc

	# Set gtk style for QT apps
	echo "QT_STYLE_OVERRIDE=gtk" >> ${CN_DESTDIR}/etc/environment

	# Add lxpolkit to autostart apps
	cp /etc/xdg/autostart/lxpolkit.desktop ${CN_DESTDIR}/home/${CN_USER_NAME}/.config/autostart

	# xscreensaver config
	cp /usr/share/cnchi/scripts/postinstall/xscreensaver ${CN_DESTDIR}/home/${CN_USER_NAME}/.xscreensaver
	cp ${CN_DESTDIR}/home/${CN_USER_NAME}/.xscreensaver ${CN_DESTDIR}/etc/skel

	rm ${CN_DESTDIR}/etc/xdg/autostart/xscreensaver.desktop
}

openbox_settings() {
	# Setup user defaults
	chroot ${CN_DESTDIR} /usr/share/antergos-openbox-setup/install.sh ${CN_USER_NAME}

	# Set skel directory
	cp -R ${CN_DESTDIR}/home/${CN_USER_NAME}/.config ${CN_DESTDIR}/etc/skel

	# Set openbox in .dmrc
	echo "[Desktop]" > ${CN_DESTDIR}/home/${CN_USER_NAME}/.dmrc
	echo "Session=openbox" >> ${CN_DESTDIR}/home/${CN_USER_NAME}/.dmrc
	chroot ${CN_DESTDIR} chown ${CN_USER_NAME}:users /home/${CN_USER_NAME}/.dmrc

	# xscreensaver config
	set_xscreensaver
}

lxqt_settings() {
	# Set theme
	mkdir -p ${CN_DESTDIR}/home/${CN_USER_NAME}/.config/razor/razor-panel
	echo "[General]" > ${CN_DESTDIR}/home/${CN_USER_NAME}/.config/razor/razor.conf
	echo "__userfile__=true" >> ${CN_DESTDIR}/home/${CN_USER_NAME}/.config/razor/razor.conf
	echo "icon_theme=Numix" >> ${CN_DESTDIR}/home/${CN_USER_NAME}/.config/razor/razor.conf
	echo "theme=ambiance" >> ${CN_DESTDIR}/home/${CN_USER_NAME}/.config/razor/razor.conf

	# Set panel launchers
	echo "[quicklaunch]" >> ${CN_DESTDIR}/home/${CN_USER_NAME}/.config/razor/razor-panel/panel.conf
	echo "apps\1\desktop=/usr/share/applications/razor-config.desktop" >> ${CN_DESTDIR}/home/${CN_USER_NAME}/.config/razor/razor-panel/panel.conf
	echo "apps\size=3" >> ${CN_DESTDIR}/home/${CN_USER_NAME}/.config/razor/razor-panel/panel.conf
	echo "apps\2\desktop=/usr/share/applications/kde4/konsole.desktop" >> ${CN_DESTDIR}/home/${CN_USER_NAME}/.config/razor/razor-panel/panel.conf
	echo "apps\3\desktop=/usr/share/applications/chromium.desktop" >> ${CN_DESTDIR}/home/${CN_USER_NAME}/.config/razor/razor-panel/panel.conf

	# Set Wallpaper
	echo "[razor]" >> ${CN_DESTDIR}/home/${CN_USER_NAME}/.config/razor/desktop.conf
	echo "screens\size=1" >> ${CN_DESTDIR}/home/${CN_USER_NAME}/.config/razor/desktop.conf
	echo "screens\1\desktops\1\wallpaper_type=pixmap" >> ${CN_DESTDIR}/home/${CN_USER_NAME}/.config/razor/desktop.conf
	echo "screens\1\desktops\1\wallpaper=/usr/share/antergos/wallpapers/antergos-wallpaper.png" >> ${CN_DESTDIR}/home/${CN_USER_NAME}/.config/razor/desktop.conf
	echo "screens\1\desktops\1\keep_aspect_ratio=false" >> ${CN_DESTDIR}/home/${CN_USER_NAME}/.config/razor/desktop.conf
	echo "screens\1\desktops\size=1" >> ${CN_DESTDIR}/home/${CN_USER_NAME}/.config/razor/desktop.conf

	# Set Razor in .dmrc
	echo "[Desktop]" > ${CN_DESTDIR}/home/${CN_USER_NAME}/.dmrc
	echo "Session=razor" >> ${CN_DESTDIR}/home/${CN_USER_NAME}/.dmrc
	chroot ${CN_DESTDIR} chown ${CN_USER_NAME}:users /home/${CN_USER_NAME}/.dmrc

	chroot ${CN_DESTDIR} chown -R ${CN_USER_NAME}:users /home/${CN_USER_NAME}/.config
}

kde_settings() {
	# Set KDE in .dmrc
	echo "[Desktop]" > ${CN_DESTDIR}/home/${CN_USER_NAME}/.dmrc
	echo "Session=kde-plasma" >> ${CN_DESTDIR}/home/${CN_USER_NAME}/.dmrc
	chroot ${CN_DESTDIR} chown ${CN_USER_NAME}:users /home/${CN_USER_NAME}/.dmrc

	# Force QtCurve to use our theme
	rm -R ${CN_DESTDIR}/usr/share/kstyle/themes/qtcurve.themerc

	# Setup user defaults
	chroot ${CN_DESTDIR} /usr/share/antergos-kde-setup/install.sh ${CN_USER_NAME}

	# Setup root defaults
	cp -R ${CN_DESTDIR}/etc/skel/.config ${CN_DESTDIR}/root
	cp ${CN_DESTDIR}/etc/skel/.gtkrc-2.0-kde4 ${CN_DESTDIR}/root
	chroot ${CN_DESTDIR} "ln -s /root/.gtkrc-2.0-kde4 /root/.gtkrc-2.0"

	# Set default directories
	chroot ${CN_DESTDIR} su -c xdg-user-dirs-update ${CN_USER_NAME}
}

mate_settings() {
	# Set MATE in .dmrc
	echo "[Desktop]" > "${CN_DESTDIR}/home/${CN_USER_NAME}/.dmrc"
	echo "Session=mate-session" >> "${CN_DESTDIR}/home/${CN_USER_NAME}/.dmrc"

	# Set gsettings
	set_gsettings

	# Set MintMenu Favorites
	if [[ "${CN_BROWSER}" = 'firefox' ]]; then
		sed -i 's|chromium|firefox|g' /usr/share/cnchi/scripts/postinstall/applications.list
	fi

	cp /usr/share/cnchi/scripts/postinstall/applications.list "${CN_DESTDIR}/usr/lib/linuxmint/mintMenu/applications.list"

	# Copy panel layout and make it the default
	cd "${CN_DESTDIR}/usr/share/mate-panel/layouts"
	cp /usr/share/cnchi/scripts/antergos.layout .
	rm default.layout
	ln -sr antergos.layout default.layout
	cd -
}

nox_settings() {
	echo "Done"
}

enlightenment_settings() {
	# http://git.enlightenment.org/core/enlightenment.git/plain/data/tools/enlightenment_remote

	# Setup user defaults
	chroot ${CN_DESTDIR} /usr/share/antergos-enlightenment-setup/install.sh ${CN_USER_NAME}

	# Set Keyboard layout
	E_CFG="/home/${CN_USER_NAME}/.e/e/config/standard/e.cfg"
	E_SRC="/home/${CN_USER_NAME}/.e/e/config/standard/e.src"

	${CN_DESTDIR}/usr/bin/eet -d ${E_CFG} config ${E_SRC}
	sed -i 's/"us"/"${CN_KEYBOARD_LAYOUT}"/' ${E_SRC}
	if [[ "${CN_KEYBOARD_VARIANT}" != '' ]]; then
		sed -i 's/"basic"/"${CN_KEYBOARD_VARIANT}"/' ${E_SRC}
	fi
	${CN_DESTDIR}/usr/bin/eet -e ${E_CFG} config ${E_SRC} 1

	# Set settings
	set_gsettings

	# Set skel directory
	cp -R ${CN_DESTDIR}/home/${CN_USER_NAME}/.config ${CN_DESTDIR}/etc/skel

	# Set enlightenment in .dmrc
	echo "[Desktop]" > ${CN_DESTDIR}/home/${CN_USER_NAME}/.dmrc
	echo "Session=enlightenment" >> ${CN_DESTDIR}/home/${CN_USER_NAME}/.dmrc
	chroot ${CN_DESTDIR} chown ${CN_USER_NAME}:users /home/${CN_USER_NAME}/.dmrc

	echo "QT_STYLE_OVERRIDE=gtk" >> ${CN_DESTDIR}/etc/environment

	# Add lxpolkit to autostart apps
	cp /etc/xdg/autostart/lxpolkit.desktop ${CN_DESTDIR}/home/${CN_USER_NAME}/.config/autostart

	# xscreensaver config
	set_xscreensaver
}

postinstall() {
	# Specific user configurations
	if [[ -f /usr/share/applications/firefox.desktop ]]; then
		export CN_BROWSER=firefox
	else
		export CN_BROWSER=chromium
	fi

	# Workaround for LightDM bug https://bugs.launchpad.net/lightdm/+bug/1069218
	sed -i 's|UserAccounts|UserList|g' "${CN_DESTDIR}/etc/lightdm/users.conf"

	## Unmute alsa channels
	#chroot "${CN_DESTDIR}" amixer -c 0 -q set Master playback 50% unmute

	# Configure touchpad. Skip with base installs
	if [[ "base" != "${CN_DESKTOP}" ]]; then
		set_xorg
	fi

	# Configure fontconfig
	FONTCONFIG_FILE="/usr/share/cnchi/scripts/fonts.conf"
	if [[ -f "${FONTCONFIG_FILE}" ]]; then
		FONTCONFIG_DIR="${CN_DESTDIR}/home/${CN_USER_NAME}/.config/fontconfig"
		mkdir -p "${FONTCONFIG_DIR}"
		cp "${FONTCONFIG_FILE}" "${FONTCONFIG_DIR}"
	fi

	# Set Antergos name in filesystem files
	cp /etc/arch-release "${CN_DESTDIR}/etc"
	cp /etc/os-release "${CN_DESTDIR}/etc"
	sed -i 's|Arch|Antergos|g' "${CN_DESTDIR}/etc/issue"

	# copy antergos menu icon
	mkdir -p ${CN_DESTDIR}/usr/share/antergos/
	cp -t ${CN_DESTDIR}/usr/share/antergos \
		/usr/share/antergos/antergos-menu.png \
		/usr/share/cnchi/data/images/antergos/antergos-menu-logo-dark-bg.png

	cd "${CN_DESTDIR}/usr/share/icons/Numix/24/places" \
 		&& mv start-here.svg start-here-numix.svg \
 		&& cp /usr/share/cnchi/data/images/antergos/antergos-ball-26.png start-here.png \
 		&& cd -
	cd "${CN_DESTDIR}/usr/share/icons/Numix/32/places" \
		&& mv start-here.svg start-here-numix.svg \
 		&& cp /usr/share/cnchi/data/images/antergos/antergos-menu-logo-dark-bg.png start-here.png \
 		&& cd -

	# Set desktop-specific settings
	${CN_DESKTOP}_settings

	# Set some environment vars
	env_files=("${CN_DESTDIR}/etc/environment"
				"${CN_DESTDIR}/home/${CN_USER_NAME}/.bashrc"
				"${CN_DESTDIR}/etc/skel/.bashrc"
				"${CN_DESTDIR}/etc/profile")

	for file in "${env_files[@]}"
	do
		echo "# >>>>BEGIN ADDED BY CNCHI INSTALLER<<<< #" >> "${file}"
		echo "BROWSER=/usr/bin/${CN_BROWSER}" >> "${file}"
		echo "EDITOR=/usr/bin/nano" >> "${file}"
		echo "# >>>>>END ADDED BY CNCHI INSTALLER<<<<< #" >> "${file}"
	done

	# Configure makepkg so that it doesn't compress packages after building.
	# Most users are building packages to install them locally so there's no need for compression.
	sed -i "s|^PKGEXT='.pkg.tar.xz'|PKGEXT='.pkg.tar'|g" "${CN_DESTDIR}/etc/makepkg.conf"

	# Set lightdm-webkit2-greeter in lightdm.conf. This should have been done here (not in the pkg) all along.
	sed -i 's|#greeter-session=example-gtk-gnome|greeter-session=lightdm-webkit2-greeter|g' "${CN_DESTDIR}/etc/lightdm/lightdm.conf"

	# Ensure user permissions are set in /home
	chroot "${CN_DESTDIR}" chown -R "${CN_USER_NAME}:users" "/home/${CN_USER_NAME}"

	# Start vbox client services if we are installed in vbox
	if [[ ${CN_IS_VBOX} = "True" ]] || { [[ $(systemd-detect-virt) ]] && [[ 'oracle' = $(systemd-detect-virt -v) ]]; }; then
		# TODO: This should be done differently
		sed -i 's|echo "X|/usr/bin/VBoxClient-all \&\necho "X|g' "${CN_DESTDIR}/etc/lightdm/Xsession"
	fi
}

touch /tmp/.postinstall.lock
echo "Called installation script with these parameters: [$1] [$2] [$3] [$4] [$5] [$6] [$7]" > /tmp/postinstall.log
CN_USER_NAME=$1
CN_DESTDIR=$2
CN_DESKTOP=$3
CN_LOCALE=$4
CN_IS_VBOX=$5
CN_KEYBOARD_LAYOUT=$6
CN_KEYBOARD_VARIANT=$7

# Use this to test this script (remember to mount /install manually before testing)
#chroot_setup "${CN_DESTDIR}"

{ postinstall; } >> /tmp/postinstall.log 2>&1
rm /tmp/.postinstall.lock
