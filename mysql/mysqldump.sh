#!/usr/bin/env bash

# docker-compose down --rmi local --volumes --remove-orphans
# docker-compose down --rmi all --volumes --remove-orphans

# set -xv
targetDir=$(pwd)
targetDir=./initial_data
day=`date +%Y%m%d`

mkdir -p ${targetDir}

# Delete old files?
# deleteOldfiles=`find ${targetDir} -type f -mtime +15 -exec ls -l {} \;`
deleteOldfiles=`find ${targetDir} -type f -mtime +60 -exec rm -rf {} \;`
echo $deleteOldfiles
# rm -rf ${targetDir}/* 2>&1

export $(egrep -v '^#' .env | xargs)

host=${HOSTNAME}
host=docker
port=3306
db=${MYSQL_DATABASE}
user=${MYSQL_USER}
password=${MYSQL_PASSWORD}
url="mysql://${user}:${password}@${host}:${port}/${db}?serverVersion=${MYSQL_VERSION}"
echo ${url}

echo
echo Backup Data: ${db}-${host}-90-data.sql
mysqldump --force --host=${host} --port=${port} --user=${user} --password=${password} --protocol=tcp --default-character-set=utf8 --single-transaction=TRUE --skip-triggers --skip-tz-utc --comments --no-create-info=TRUE ${db} > ${targetDir}/${day}-${db}-${host}-90-data.sql 2>/dev/null

###
sed -i "s/latin1/utf8mb4/g" ${targetDir}/${day}-${db}-${host}-90-data.sql
sed -i "s/utf8/utf8mb4/g" ${targetDir}/${day}-${db}-${host}-90-data.sql
sed -i "s/utf8mb3/utf8mb4/g" ${targetDir}/${day}-${db}-${host}-90-data.sql
sed -i "s/utf8mb4mb3/utf8mb4/g" ${targetDir}/${day}-${db}-${host}-90-data.sql
sed -i "s/utf8mb4mb4/utf8mb4/g" ${targetDir}/${day}-${db}-${host}-90-data.sql

###
sed -i "16s/^/&USE \`${db}\`;\\n\\n/" ${targetDir}/${day}-${db}-${host}-90-data.sql

echo
echo Update Users Password: ${db}-${host}-91-data.sql
password_hash=$(php -r "echo password_hash('password', PASSWORD_DEFAULT);")
# echo ${password_hash}
echo 'UPDATE `'${db}'`.`users` SET `password` = '\'${password_hash}\'';' > ${targetDir}/${day}-${db}-${host}-91-data.sql

echo
echo Backup Structure: ${db}-${host}-00-structure.sql
mysqldump --force --host=${host} --port=${port} --user=${user} --password=${password} --protocol=tcp --default-character-set=utf8mb4 --single-transaction=TRUE --routines --events --skip-tz-utc --comments --add-drop-database --add-drop-trigger --no-data ${db} > ${targetDir}/${day}-${db}-${host}-00-structure.sql 2>/dev/null

###
sed -i "s/latin1/utf8mb4/g" ${targetDir}/${day}-${db}-${host}-00-structure.sql
sed -i "s/utf8/utf8mb4/g" ${targetDir}/${day}-${db}-${host}-00-structure.sql
sed -i "s/utf8mb3/utf8mb4/g" ${targetDir}/${day}-${db}-${host}-00-structure.sql
sed -i "s/utf8mb4mb3/utf8mb4/g" ${targetDir}/${day}-${db}-${host}-00-structure.sql
sed -i "s/utf8mb4mb4/utf8mb4/g" ${targetDir}/${day}-${db}-${host}-00-structure.sql

sed -i "s/latin1_swedish_ci/utf8mb4_unicode_ci/g" ${targetDir}/${day}-${db}-${host}-00-structure.sql
sed -i "s/latin1_general_ci/utf8mb4_unicode_ci/g" ${targetDir}/${day}-${db}-${host}-00-structure.sql
sed -i "s/utf8mb4_swedish_ci/utf8mb4_unicode_ci/g" ${targetDir}/${day}-${db}-${host}-00-structure.sql
sed -i "s/utf8mb4_general_ci/utf8mb4_unicode_ci/g" ${targetDir}/${day}-${db}-${host}-00-structure.sql
# sed -i "s/utf8mb4_0900_ai_ci/utf8mb4_unicode_ci/g" ${targetDir}/${day}-${db}-${host}-00-structure.sql
sed -i "s/ CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci//g" ${targetDir}/${day}-${db}-${host}-00-structure.sql
sed -i "s/ CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci//g" ${targetDir}/${day}-${db}-${host}-00-structure.sql

###
# https://www.monolune.com/what-is-the-utf8mb4_0900_ai_ci-collation/
# para MySQL 8
sed -i "s/utf8mb4_unicode_ci/utf8mb4_0900_ai_ci/g" ${targetDir}/${day}-${db}-${host}-00-structure.sql

###
sed -i "s/ AUTO_INCREMENT=[0-9]*//g" ${targetDir}/${day}-${db}-${host}-00-structure.sql
sed -i "15s/^/&\\nCREATE SCHEMA IF NOT EXISTS \`${db}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;\\nUSE \`${db}\`;\\n/" ${targetDir}/${day}-${db}-${host}-00-structure.sql

mysql --force --host=${host} --port=${port} --user=${user} --password=${password} -e "SELECT table_name FROM information_schema.tables WHERE table_schema = '${db}' ORDER BY table_name DESC" > /tmp/${host}-${day}-${db}.sql 2>&1
tables=`tail -n +2 /tmp/${host}-${day}-${db}.sql`
echo
# echo '' | tee ${targetDir}/${day}-${db}-${host}-02-alter_tables.sql
# echo '' | tee ${targetDir}/${day}-${db}-${host}-03-alter_tables.sql
# echo '' | tee ${targetDir}/${day}-${db}-${host}-04-alter_tables.sql
# echo '' | tee ${targetDir}/${day}-${db}-${host}-05-alter_tables.sql

# for table in $tables; do

#     echo "ALTER TABLE \`${db}\`.\`${table}\`
# AUTO_INCREMENT = 0;
# " >> ${targetDir}/${day}-${db}-${host}-02-alter_tables.sql

#     echo "ALTER TABLE \`${db}\`.\`${table}\`
# ADD COLUMN \`is_active\` TINYINT NULL DEFAULT 1,
# ADD COLUMN \`created_id\` INT UNSIGNED NULL,
# ADD COLUMN \`updated_id\` INT UNSIGNED NULL,
# ADD COLUMN \`created_at\` TIMESTAMP NULL,
# ADD COLUMN \`updated_at\` TIMESTAMP NULL,
# ADD COLUMN \`deleted_at\` TIMESTAMP NULL;
# " >> ${targetDir}/${day}-${db}-${host}-03-alter_tables.sql

#     echo "ALTER TABLE \`${db}\`.\`${table}\`
# CHANGE COLUMN \`id\` \`id\` INT UNSIGNED NOT NULL AUTO_INCREMENT;
# " >> ${targetDir}/${day}-${db}-${host}-04-alter_tables.sql

#     echo "ALTER TABLE \`${db}\`.\`${table}\`
# ADD INDEX \`${table}_created_id_index\` (\`created_id\` ASC),
# ADD INDEX \`${table}_updated_id_index\` (\`updated_id\` ASC);
# " >> ${targetDir}/${day}-${db}-${host}-05-alter_tables.sql

#     echo '#' ${db} - ${tabela} > /tmp/${host}-${day}-${db}-${tabela}-columns_log.sql
#     mysql --force --host=${host} --port=${port} --user=${user} --password=${password} -e "USE ${db}; SELECT column_name AS columns FROM information_schema.columns WHERE table_name = '${tabela}';" >> /tmp/${host}-${day}-${db}-${tabela}-columns_log.sql

#     echo '#' ${db} - ${tabela} - 'log' > /tmp/${host}-${day}-${db}-${tabela}_trigger.sql
#     echo -e "USE ${db};\nDROP TABLE IF EXISTS _${tabela}_log;\nCREATE TABLE _${tabela}_log LIKE ${tabela};\nALTER TABLE _${tabela}_log\nADD COLUMN action_created_at TIMESTAMP NOT NULL FIRST,\nADD COLUMN action CHAR(1) NOT NULL AFTER action_created_at,\nADD COLUMN tbl_${tabela}_id INT(11) UNSIGNED NOT NULL AFTER action;\n" >> /tmp/${host}-${day}-${db}-${tabela}_trigger.sql

#     colunas=`tail -n +4 /tmp/${host}-${day}-${db}-${tabela}-columns_log.sql | sed ':a;$!N;s/\n/\, /;ta;'`
#     colunas_id=`tail -n +3 /tmp/${host}-${day}-${db}-${tabela}-columns_log.sql | sed 's/^/NEW./' | sed ':a;$!N;s/\n/\, /;ta;'`
#     echo '#' ${db} - ${tabela} - 'trigger after insert' >> /tmp/${host}-${day}-${db}-${tabela}_trigger.sql
#     echo -e "DROP TRIGGER IF EXISTS ${tabela}_tg_a_i;\nDELIMITER \$\$\nCREATE DEFINER = CURRENT_USER TRIGGER ${tabela}_tg_a_i AFTER INSERT ON ${tabela} FOR EACH ROW\nBEGIN\n\tINSERT INTO _${tabela}_log (action_created_at, action, tbl_${tabela}_id, ${colunas})\n\tVALUES (now(), 'I', ${colunas_id});\nEND; \$\$\nDELIMITER ;\n" >> /tmp/${host}-${day}-${db}-${tabela}_trigger.sql

#     colunas_id=`tail -n +3 /tmp/${host}-${day}-${db}-${tabela}-columns_log.sql | sed 's/^/OLD./' | sed ':a;$!N;s/\n/\, /;ta;'`
#     echo '#' ${db} - ${tabela} - 'trigger before update' >> /tmp/${host}-${day}-${db}-${tabela}_trigger.sql
#     echo -e "DROP TRIGGER IF EXISTS ${tabela}_tg_b_u;\nDELIMITER \$\$\nCREATE DEFINER = CURRENT_USER TRIGGER ${tabela}_tg_b_u BEFORE UPDATE ON ${tabela} FOR EACH ROW\nBEGIN\n\tINSERT INTO _${tabela}_log (action_created_at, action, tbl_${tabela}_id, ${colunas})\n\tVALUES (now(), 'U', ${colunas_id});\nEND; \$\$\nDELIMITER ;\n" >> /tmp/${host}-${day}-${db}-${tabela}_trigger.sql

#     echo '#' ${db} - ${tabela} - 'trigger before delete' >> /tmp/${host}-${day}-${db}-${tabela}_trigger.sql
#     echo -e "DROP TRIGGER IF EXISTS ${tabela}_tg_b_d;\nDELIMITER \$\$\nCREATE DEFINER = CURRENT_USER TRIGGER ${tabela}_tg_b_d BEFORE DELETE ON ${tabela} FOR EACH ROW\nBEGIN\n\tINSERT INTO _${tabela}_log (action_created_at, action, tbl_${tabela}_id, ${colunas})\n\tVALUES (now(), 'D', ${colunas_id});\nEND; \$\$\nDELIMITER ;" >> /tmp/${host}-${day}-${db}-${tabela}_trigger.sql

#     mysql --force --host=${host} --port=${port} --user=${user} --password=${password} < /tmp/${host}-${day}-${db}-${tabela}_trigger.sql

# done
# set +xv

# exit 0
