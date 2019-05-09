###########################################################
# Dockerfile that builds a Mordhau Gameserver
###########################################################
FROM cm2network/steamcmd:root
LABEL maintainer="walentinlamonos@gmail.com"

RUN set -x \
# Install Mordhau server dependencies and clean up
	&& apt-get install -y --no-install-recommends --no-install-suggests \
			libfontconfig1 \
			libpangocairo-1.0-0 \
			libnss3 \
			libgconf2-4 \
			libxi6 \
			libxcursor1 \
			libxss1 \
			libxcomposite1 \
			libasound2 \
			libxdamage1 \
			libxtst6 \
			libatk1.0-0 \
			libxrandr2 \
	&& apt-get clean autoclean \
        && apt-get autoremove -y \
	&& rm -rf /var/lib/{apt,dpkg,cache,log}/ \
# Run Steamcmd and install Mordhau
# Write Server Config
# {{SERVER_PW}}, {{SERVER_ADMINPW}} and {{SERVER_MAXPLAYERS}} gets replaced by entrypoint
	&& su steam -c \
		"./home/steam/steamcmd/steamcmd.sh \
		+login anonymous \
		+force_install_dir /home/steam/mordhau-dedicated \
		+app_update 629800 validate \
		+quit \
		&& mkdir -p /home/steam/mordhau-dedicated/Mordhau/Saved/Config/LinuxServer/ \
		&& { \
			echo '[/Script/Mordhau.MordhauGameMode]'; \
			echo 'PlayerRespawnTime=5.000000'; \
			echo 'BallistaRespawnTime=30.000000'; \
			echo 'CatapultRespawnTime=30.000000'; \
			echo 'HorseRespawnTime=30.000000'; \
			echo 'DamageFactor=1.000000'; \
			echo 'TeamDamageFactor=0.500000'; \
			echo 'MapRotation=FFA_Contraband'; \
			echo 'MapRotation=FFA_MountainPeak'; \
			echo 'MapRotation=FFA_Taiga'; \
			echo 'MapRotation=TDM_Contraband'; \
			echo 'MapRotation=TDM_Taiga_64'; \
			echo 'MapRotation=FFA_Camp'; \
			echo 'MapRotation=TDM_ThePit'; \
			echo 'MapRotation=FFA_Tourney'; \
			echo 'MapRotation=TDM_Grad'; \
			echo 'MapRotation=TDM_Taiga'; \
			echo 'MapRotation=SKM_Grad'; \
			echo 'MapRotation=SKM_Taiga'; \
			echo 'MapRotation=SKM_ThePit'; \
			echo 'MapRotation=TDM_Tourney'; \
			echo 'MapRotation=FFA_ThePit'; \
			echo 'MapRotation=TDM_Camp'; \
			echo 'MapRotation=SKM_Tourney'; \
			echo 'MapRotation=SKM_MountainPeak'; \
			echo 'MapRotation=TDM_Camp_64'; \
			echo 'MapRotation=SKM_Camp'; \
			echo 'MapRotation=SKM_Contraband'; \
			echo 'MapRotation=FFA_Grad'; \
			echo 'MapRotation=TDM_MountainPeak'; \
			echo ''; \
			echo '[/Script/Mordhau.MordhauGameSession]'; \
			echo 'bIsLANServer=False'; \
			echo 'MaxSlots={{SERVER_MAXPLAYERS}}'; \
			echo 'ServerName=New Mordhau Server'; \
			echo 'ServerPassword={{SERVER_PW}}'; \
			echo 'AdminPassword={{SERVER_ADMINPW}}'; \
			echo 'Admins=0'; \
			echo 'BannedPlayers=()'; \
		} > /home/steam/mordhau-dedicated/Mordhau/Saved/Config/LinuxServer/Game.All.ini"

ENV SERVER_ADMINPW="replacethisyoumadlad" SERVER_PW="" SERVER_MAXPLAYERS=32 SERVER_TICKRATE=60 SERVER_PORT=7777 SERVER_QUERYPORT=27015 

# Switch to user steam
USER steam

VOLUME /home/steam/mordhau-dedicated

# Set Entrypoint
# 1. Update server
# 2. Replace config parameters with ENV variables
# 3. Start the server
ENTRYPOINT ./home/steam/steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/steam/mordhau-dedicated +app_update 629800 +quit && \
		./bin/sed -i 's/{{SERVER_PW}}/ServerPassword='"$SERVER_PW"'/g' /home/steam/mordhau-dedicated/Mordhau/Saved/Config/LinuxServer/Game.All.ini && \
		./bin/sed -i 's/{{SERVER_ADMINPW}}/AdminPassword='"$SERVER_ADMINPW"'/g' /home/steam/mordhau-dedicated/Mordhau/Saved/Config/LinuxServer/Game.All.ini && \
		./bin/sed -i 's/{{SERVER_MAXPLAYERS}}/MaxSlots='"$SERVER_MAXPLAYERS"'/g' /home/steam/mordhau-dedicated/Mordhau/Saved/Config/LinuxServer/Game.All.ini && \
		./bin/sed -i 's/GameServerQueryPort=27015/GameServerQueryPort='"$SERVER_QUERYPORT"'/g' /home/steam/mordhau-dedicated/Mordhau/Engine/Config/BaseEngine.ini && \
		./bin/sed -i 's/Port=7777/Port='"$SERVER_PORT"'/g' /home/steam/mordhau-dedicated/Mordhau/Engine/Config/BaseEngine.ini && \
		./bin/sed -i 's/NetServerMaxTickRate=30/NetServerMaxTickRate='"$SERVER_TICKRATE"'/g' /home/steam/mordhau-dedicated/Mordhau/Engine/Config/BaseEngine.ini && \
		./home/steam/mordhau-dedicated/MordhauServer.sh -log -gameini=Game.All.ini

# Expose ports
EXPOSE 27015 7777