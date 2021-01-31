###########################################################
# Dockerfile that builds a Mordhau Gameserver
###########################################################
FROM cm2network/steamcmd:root

LABEL maintainer="walentinlamonos@gmail.com"

ENV STEAMAPPID 629800
ENV STEAMAPPDIR /home/steam/mordhau-dedicated

RUN set -x \
# Install Mordhau server dependencies and clean up
	&& apt-get update \
	&& apt-get install -y --no-install-recommends --no-install-suggests \
		libfontconfig1 \
		libpangocairo-1.0-0 \
		libnss3 \
		gconf-gsettings-backend \
		libxi6 \
		libxcursor1 \
		libxss1 \
		libxcomposite1 \
		libasound2 \
		libxdamage1 \
		libxtst6 \
		libatk1.0-0 \
		libxrandr2 \
		libcurl3-gnutls \
		libcurl4 \
		iputils-ping \
	&& apt-get clean autoclean \
	&& apt-get autoremove -y \
	&& rm -rf /var/lib/apt/lists/* \
# Run Steamcmd and install Mordhau
# Write Server Config
# {{SERVER_PW}}, {{SERVER_ADMINPW}} and {{SERVER_MAXPLAYERS}} gets replaced by entrypoint
	&& su steam -c \
		"${STEAMCMDDIR}/steamcmd.sh \
		+login anonymous \
		+force_install_dir ${STEAMAPPDIR} \
		+app_update ${STEAMAPPID} validate \
		+quit \
		&& mkdir -p ${STEAMAPPDIR}/Mordhau/Saved/Config/LinuxServer/"

ENV SERVER_PORT=7777 \
	SERVER_QUERYPORT=27015 \
	SERVER_BEACONPORT=15000

# Switch to user steam
USER steam

WORKDIR $STEAMAPPDIR

VOLUME $STEAMAPPDIR

# Set Entrypoint
# 1. Update server
# 2. Replace config parameters with ENV variables
# 3. Start the server
# You may not like it, but this is what peak Entrypoint looks like.
ENTRYPOINT ${STEAMCMDDIR}/steamcmd.sh \
			+login anonymous +force_install_dir ${STEAMAPPDIR} +app_update ${STEAMAPPID} +quit \
		&& /bin/sed -i -e 's/{{SERVER_PW}}/'"$SERVER_PW"'/g' \
			-e 's/{{SERVER_ADMINPW}}/'"$SERVER_ADMINPW"'/g' \
			-e 's/{{SERVER_MAXPLAYERS}}/'"$SERVER_MAXPLAYERS"'/g' ${STEAMAPPDIR}/Mordhau/Saved/Config/LinuxServer/Game.ini \
		&& /bin/sed -i -e 's/{{SERVER_TICKRATE}}/'"$SERVER_TICKRATE"'/g' \
			-e 's/{{SERVER_DEFAULTMAP}}/'"$SERVER_DEFAULTMAP"'/g' ${STEAMAPPDIR}/Mordhau/Saved/Config/LinuxServer/Engine.ini \
		&& ${STEAMAPPDIR}/MordhauServer.sh -log \
			-Port=$SERVER_PORT -QueryPort=$SERVER_QUERYPORT -BeaconPort=$SERVER_BEACONPORT \
			-GAMEINI=${STEAMAPPDIR}/Mordhau/Saved/Config/LinuxServer/Game.ini \
			-ENGINEINI=${STEAMAPPDIR}/Mordhau/Saved/Config/LinuxServer/Engine.ini

# Expose ports
EXPOSE 27015/udp 15000/tcp 7777/udp

ADD Engine.ini ${STEAMAPPDIR}/Mordhau/Saved/Config/LinuxServer/
ADD Game.ini ${STEAMAPPDIR}/Mordhau/Saved/Config/LinuxServer/
