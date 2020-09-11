#!/bin/bash
# created: 09-sep-2020 16:00PM (GMT)

# objective(s):
# The following script simulates the deployment of resources
# on the gcp platform using google cloud deployment manager

echo "previewing the deployment"
gcloud deployment-manager deployments create basicdep \
--config=config.yaml --preview

sleep 15

read -p "proceed(yes/no)? " proceed

if [ $proceed == 'yes' ] ; then
gcloud deployment-manager deployments update basicdep
exit 0
else
echo "usage: yes"
exit 2
fi

exit 0