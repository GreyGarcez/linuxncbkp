#!/bin/bash

# definir archive
ctd=$(date "+%Y-%m-%d")
archive_name="$(hostname)-ncpwg-$ctd"

# parametros salvos em arquivos
mapfile -t borgParams < /pathToConfigFiles/usbDriveBorg.details
mapfile -t sqlParams < /pathToConfigFiles/sql.details
mapfile -t xtraFiles < /pathToConfigFiles/usbDriveXtraLocations.borg

# Variáveis de ambiente para o Borg
export BORG_PASSPHRASE="${borgParams[2]}"

# borg repo
target=/media/usbdrive/"${borgParams[1]}"

echo "Iniciar backup $archive_name"

echo "[$(date '+%HH:%MM:%SS')] - Ativar modo de manutenção do Nextcloud"
cd /var/www/mydomain
sudo -u root php occ maintenance:mode --on

# Criar o backup
echo "Executar Borg create"
borg create ${borgParams[0]} \
  $target::${archive_name} \
  ${xtraFiles[@]} \
  ${sqlParams[7]}
borg_exit="$?"

echo "[$(date '+%HH:%MM:%SS')] - Desativar modo de manutenção"
cd /var/www/mydomain
sudo -u root php occ maintenance:mode --off
sudo chmod 660 /var/www/mydomain/config/config.php

# Prune backup
echo "Executar Borg prune"
borg prune --stats -v --prefix "$(hostname)-ncpwg" \
  ${borgParams[3]} $target
prune_exit="$?"

global_exit=$(( global_exit > prune_exit ? global_exit : prune_exit ))

if [ ${global_exit} -eq 0 ]; then
  echo "Backup e Prune terminados com sucesso."
elif [ ${global_exit} -eq 1 ]; then
  echo "Backup e/ou Prune terminados com ressalvas."
else
  echo "Backup e/ou Prune terminados com erros."
fi

exit ${global_exit}

echo "[$(date '+%HH:%MM:%SS')] - Backup manual concluido para $archive_name"
