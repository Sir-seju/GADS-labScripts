#!/bin/bash

# objective
# Write a script that can create a vpc network in  GCP through the Google cloud shell SDK.
# VPC network is in custom mode with basic firewall rules.
# create a virtual machine within the vpc's subnet in region us-central 1.
# test the setup

read -p "Enter project ID" project_ID

read -p "Enter vpc network name " custom_vpc_network

# create a custom vpc network
echo "creating a custom vpoc network..."
gcloud compute networks create $custom_vpc_network --project =$project_ID -- subnet-mode=custom \
    --bgp-routing-mode= regional

# create subnetwork for custom vpc created
#using a CIDR range of 10.150.0.0/20
read -p "enter name of subentwork to create: " vpc_custom_subnet
echo "creating subnetwork $vpc_custom_subnet in $custom_vpc_network..."
gcloud compute networks create $vpc_custom_subnet --project=$project_ID --range=10.150.0.0/20 \
    --network=$custom_vpc_network -- region=us-central1

# create a firewall rule to alow ping (ICMP), ssh
# and rdp connections to instances in the network
# **NOTE: CIDR range should be modified to allow selected ranges**
gcloud compute firewall-rules create privatenet-allow-icmp-ssh-rdp --direction=INGRESS \
    --priority=1000 --network=$custom_vpc_network --action=ALLOW --rules=icmp,tcp:22,tcp:3389 \
    --source-ranges=0.0.0.0/0

#view the existing firewall rules
gcloud compute firewall-rules-list --sort-by=NETWORK

# create a vm to utilize the created vpc network
gcloud compute instances create vpc-custom-subnet-net-vm --zone=us-central1-c --project=$project_ID \
    --machine type=f1-micro --subnet=$vpc_custom_subnet
