#!/bin/bash

# objectives
# Write a script to create a custom VPC network with some firewall rules and a VM instance that has no external IP address, and connect to the instance using an IAP tunnel.
# Enable Private Google Access
# Create a Cloud Storage bucketand copy an image from a public Cloud  Storage bucket to your own bucket.
# Access the imagein the storage bucket through your VM to
# Configure a Cloud NAT gateway

read -p "Enter project ID" project_ID

read -p "Enter vpc network name " custom_vpc_network

# create a custom vpc network
echo "creating a custom vpc network..."
gcloud compute networks create $custom_vpc_network --project $project_ID --subnet-mode custom \
    --bgp-routing-mode regional

# create subnetwork for custom vpc created
# using a CIDR range of 10.130.0.0/20
#enable private ip google access
read -p "enter name of subnetwork to create: " vpc_custom_subnet
echo "creating subnetwork $vpc_custom_subnet in $custom_vpc_network..."
gcloud compute networks subnets create $vpc_custom_subnet --project $project_ID --range 10.130.0.0/20 \
    --network $custom_vpc_network --region us-central1 --enable-private-ip-google-access

# create a firewall rule to alow ping (ICMP) and ssh connections to instances in the network
# **NOTE: In order to connect to your private instance using SSH, you need to open an appropriate port on the firewall. IAP connections come from a specific set of IP addresses (35.235.240.0/20)**
gcloud compute firewall-rules create privatenet-allow-icmp-ssh --direction INGRESS \
    --priority 1000 --network $custom_vpc_network --action ALLOW --rules=icmp,tcp:22 \
    --source-ranges 35.235.240.0/20

# Create the VM instance with no public IP address.
gcloud compute instances create vm-internal --zone us-central1-c --project $project_ID \
    --machine-type n1-standard-1 --subnet $vpc_custom_subnet --no-address

# Create a Cloud Storage bucket to test access to Google APIs and services.
read -p "Enter unique bucket name" bucket_name
gsutil mb -c standard -l us-central1 gs://$bucket_name

# Copy an image from a public Cloud Storage bucket to your bucket.
gsutil cp gs://cloud-training/gcpnet/private/access.svg gs://$bucket_name

#SSH to vm_internal to test the IAP tunnel and copy the image in your created bucket to to vm-internal
# If prompted about continuing, type Y.
# When prompted for a passphrase, press ENTER.
# When prompted for the same passphrase, press ENTER.

gcloud compute ssh vm-internal --zone us-central1-c --command "gsutil cp gs://$bucket_name/*.svg" --tunnel-through-iap 

# This should work because vm-internal's subnet has Private Google Access enabled!
# Return to the Cloud Shell instance
# Create a NAT router
gcloud compute routers create nat-router \
    --network $custom_vpc_network \
    --region us-central1

# Configure a Cloud NAT gateway
gcloud compute routers nats create nat_config \
    --router=nat-router --router-region us-central1\
    --auto-allocate-nat-external-ips \
    --nat-all-subnet-ip-ranges 

read -p "Waiting 1minute for the NAT gateway to propagate to the vm...." -t 60
echo "continuing"
# In Cloud Shell, re-synchronize the package index
sudo apt-get update

# reconnect to vm-internal.
# If prompted, type Y to continue.
#re-synchronize the package index of vm-internal
gcloud compute ssh vm-internal --zone us-central1-c \
--command "sudo apt-get update" --tunnel-through-iap
echo "connection from vm-internal to the internet through the NAT gateway was a success!"
