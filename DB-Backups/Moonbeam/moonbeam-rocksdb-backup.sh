####################################
#
# Backup Moonbeam RocksDB Database
#
####################################

#Pre-reqs zstd and azcopy -- see https://medium.com/certhum/automated-backup-of-polkadot-and-kusama-chain-database-to-azure-blob-fb3bfedb3320
#<some-text> indicates further input needed
# Chain
chain="moonbeam"
chaindb="moonbeam"

# User for backup target directory
user="<your-user>"

# Azure BLOB target URI
azure_uri='<Your-azure-URI>'

# Source RocksDB Directory.
backup_files="/var/lib/moonbeam-data/chains/$chaindb/db"

# Target is our Home Directory.
dest="/home/$user"

# Target filenames
archive_file="$chain-backup.tar.zst"
dict_file="$chain-sst.dict"

# Stop moonbeam.service
systemctl stop moonbeam.service

# Print start status message.
echo "Moonbeam service stopped"

# Create new dictionary
zstd --train `find "$backup_files" -name '*.sst' | shuf -n 200`

# Move and rename zstd dictionary file
mv dictionary $dest/$dict_file

# Print start status message.
echo "Backing up $backup_files to $dest/$archive_file"
date
echo

# Backup the files using tar and zstd
tar -I 'zstd -v -<#-of-procs-to-use> -T7 -D /home/ubuntu/moonbeam-sst.dict' -cvf $dest/$archive_file $backup_files

# Print end status message.
echo
echo "Backup finished"
date

#Start moonbeam.service
systemctl start moonbeam.service

# Print start status message.
echo "moonbeam service started"

# Print start status message.
echo "Uploading to Azure BLOB"

#Send to BLOB
azcopy copy "$dest/$archive_file" "$azure_uri"
azcopy copy "$dest/$dict_file" "$azure_uri"

# Print start status message.
echo "Uploading to Azure BLOB"

#copy to another server if you want
#sudo scp -r -i $dest/.ssh/id_rsa $dest/$archive_file backupaccnt@<your-server-IP>:~/
#sudo scp -r -i $dest/.ssh/id_rsa $dest/$dict_file backupaccnt@<your-server-IP>:~/


#Cleanup
rm $dest/$archive_file
rm $dest/$dict_file

# Print start status message.
#echo "Deleted prior backup"

# Print start status message.
echo "Upload Complete"
