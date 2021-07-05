#!/bin/bash -ue

ctdt=$(date "+%Y-%m-%d")
logfile="/path/to/bkplog/$ctdt.log"
exec >$logfile 2>&1

# definir archive
archive_name="$(hostname)-ncpwg-$ctdt"

# Funções
function ncMaint {
  local msgSuccess="-- [INFO] Nextcloud em modo de manutenção"
  local msgFail="-- [ERROR] Falha ao entrar em modo de manutenção"
  if [ "$1" = "off" ]; then
    msgSuccess="-- [INFO] Nextcloud de volta ao modo normal"
    msgFail="-- [ERROR] Falha ao sair do modo de manutenção"
  fi
  
  sudo -u "root" php "/var/www/mydomain/occ" maintenance:mode --"$1"
  local maintresult="$?"
  if [ "$maintresult" = "0" ]; then
    echo "$msgSuccess"
    if [ "$1" = "off" ]; then
      # Após sair do modo de manutenção o arquivo de configuração também precisa ser corrigido
      sudo chmod 660 /var/www/mydomain/config/config.php
    fi
  else
    echo "$msgFail"
    cleanup
    quit
  fi
}

function sqlDumpFile {
  host=$1
  usr=$2
  pwd=$3
  db=$4
  dest=$5
  
  # Arquivo é dumped somente se não há nenhum arquivo ou se não foi feito hoje
  local filename="$dest/$db-sql.bak"
  local doDump=1
  if [ -f $filename ]; then
    local filedate=$(stat -c %y $filename)
    filedate=${filedate%% *}
    if [ $filedate = $ctdt ]; then
      doDump=0
    else
      rm $filename
    fi
  fi
  
  if [ $doDump = 0 ]; then
    echo "Arquivo $filename já existe. Dump abortado"
    return 0;
  fi
  
  echo "Dumping $db SQL database..."
  mysqldump --single-transaction -h"$host" -u"$usr" -p"$pwd" "$db" > "$filename"
  local dumpresult="$?"
  if [ "$dumpresult" = "0" ]; then
    echo "-- [SUCCESS] $db SQL dumped com sucesso."
  else
    echo "-- [ERROR] Falha no dump de $db"
    cleanup
    quit
  fi
}

# script backup local automático do servidor nextcloud e piwigo

# parametros de configuração salvos em arquivos
mapfile -t borgParams < /pathToConfigFiles/localBorg.details
mapfile -t sqlParams < /pathToConfigFiles/sql.details
mapfile -t xtraFiles < /pathToConfigFiles/localXtraLocations.borg

# Definir as variáveis de ambiente do Borg
export BORG_PASSPHRASE="${borgParams[2]}"
# por segurança, definir estes parametros para não ficar aguardando uma resposta durante execução e falhar automaticamente
export BORG_RELOCATED_REPO_ACCESS_IS_OK=no
export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=no

echo "-- [INFO] Iniciar backup $archive_name"

# Colocar servidor nextcloud em modo de manutenção
ncMaint on

# Criar novos arquivos de dump das bases de dados
sqlDumpFile ${sqlParams[0]} ${sqlParams[1]} ${sqlParams[2]} ${sqlParams[3]} ${sqlParams[7]}
sqlDumpFile ${sqlParams[0]} ${sqlParams[4]} ${sqlParams[5]} ${sqlParams[6]} ${sqlParams[7]}

# Criar o arquivo de backup
echo "-- [INFO] Iniciar backup"
borg create ${borgParams[0]} \
  ${borgParams[1]}::${archive_name} \
  ${xtraFiles[@]} \
  ${sqlParams[7]} \
  --exclude '/var/www/mydomain/data/*/files_trashbin' \
  --exclude '/var/www/mydomain/data/*/files_versions' \
  --exclude '/var/www/mydomain/data/__groupfolders/trash' \
  --exclude '/var/www/mydomain/data/__groupfolders/versions'
backup_exit="$?"

# Retirar o servidor nextcloud do modo de manutenção
ncMaint off

# Rodar o prune para rotação dos backups
echo "-- [INFO] Rotação dos arquivos de backup"
borg prune --stats -v \
  --prefix "$(hostname)-ncpwg" \
  ${borgParams[3]} \
  ${borgParams[1]}
prune_exit="$?"

# Resultado do backup e prune
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))

if [ ${global_exit} -eq 0 ]; then
  echo "-- [INFO] Backup e Prune terminado com sucesso"
elif [ ${global_exit} -eq 1 ]; then
  echo "-- [WARN] Backup e/ou Prune terminado com ressalvas"
else
  echo "-- [ERROR] Backup e/ou Prune terminado com erros"
fi

# Apaga logs com mais de 14 dias
find /path/to/bkplog -mtime +14 -type f -delete

echo "-- [INFO] Backup terminado para $archive_name"
