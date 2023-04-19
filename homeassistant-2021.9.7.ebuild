# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_10 )
inherit distutils-r1

DESCRIPTION="Home automation platform"
HOMEPAGE="https://www.home-assistant.io/"
SRC_URI="https://github.com/home-assistant/home-assistant/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

#DEPEND=">=dev-python/aiohttp-3.7.4[ssl]"
DEPEND=">=dev-python/aiohttp-3.7.4"
RDEPEND="${DEPEND}
	>=dev-python/pyyaml-5.4.1
	dev-python/async-timeout
	dev-python/jinja
	dev-python/pytz
	dev-python/requests
	dev-python/websocket-client
	dev-python/zeroconf"

S="${WORKDIR}/${PN}-homeassistant-${PV}"

#pkg_setup() {
#	#enewgroup homeassistant
	#enewuser homeassistant -1 -1 /var/calculate/homeassistant homeassistant
#}

src_install() {
	distutils-r1_src_install
	dodir /var/calculate/homeassistant
	mv "${ED}/usr/lib/python3.7/site-packages/homeassistant" "/var/calculate/homeassistant"
	chown -R homeassistant:homeassistant /var/calculate/homeassistant
}

pkg_postinst() {
	elog "To start Home Assistant on boot, add the following line to /etc/conf.d/local.start:"
	elog "/etc/init.d/homeassistant start"
}

pkg_postrm() {
	elog "To stop Home Assistant on shutdown, add the following line to /etc/conf.d/local.stop:"
	elog "/etc/init.d/homeassistant stop"
}

pkg_preinst() {
	# Remove old init.d script if it exists
	rm -f "${EROOT}/etc/init.d/homeassistant"
}

pkg_postinst() {
	# Create new init.d script
	cat <<-EOF > "${EROOT}/etc/init.d/homeassistant"
	#!/sbin/openrc-run

	command="/usr/bin/hass"
	command_args="--config /var/calculate/homeassistant"

	name="homeassistant"
	pidfile="/var/run/\${RC_SVCNAME}.pid"
	command_background="yes"
	depend() {
		need net
	}

	start_pre() {
		ebegin "Starting \${RC_SVCNAME}"
	}

	start() {
		/sbin/start-stop-daemon --start --quiet --background --make-pidfile --pidfile \${pidfile} --user homeassistant --chuid homeassistant --startas \${command} -- \${command_args}
		[[ \${?} -eq 0 ]] && eend 0 || eend 1
	}

	stop_pre() {
		ebegin "Stopping \${RC_SVCNAME}"
	}

	stop() {
		/sbin/start-stop-daemon --stop --quiet --pidfile \${pidfile} --name \${command}
		[[ \${?} -eq 0 ]] && eend 0 || eend 1
	}
	EOF

	chmod 755 "${EROOT}/etc/init.d/homeassistant"
	ln -s "${EROOT}/etc/init.d/homeassistant" "${EROOT}/etc/runlevels/default/homeassistant"
}
