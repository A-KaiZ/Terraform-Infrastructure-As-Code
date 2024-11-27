#!/bin/bash

# Define the marker file and the list of expected resources
marker_file=".applied_$(terraform workspace show)"
expected_resources=(
  "openstack_compute_floatingip_associate_v2.fip_master_associate"
  "openstack_compute_floatingip_associate_v2.fip_worker1_associate"
  "openstack_compute_floatingip_associate_v2.fip_worker2_associate"
  "openstack_compute_instance_v2.master_node"
  "openstack_compute_instance_v2.worker_node_1"
  "openstack_compute_instance_v2.worker_node_2"
  "openstack_networking_floatingip_v2.fip_master"
  "openstack_networking_floatingip_v2.fip_worker1"
  "openstack_networking_floatingip_v2.fip_worker2"
  "openstack_networking_network_v2.k8s_network"
  "openstack_networking_router_interface_v2.k8s_router_interface"
  "openstack_networking_router_v2.k8s_router"
  "openstack_networking_secgroup_rule_v2.allow_etcd"
  "openstack_networking_secgroup_rule_v2.allow_http"
  "openstack_networking_secgroup_rule_v2.allow_icmp"
  "openstack_networking_secgroup_rule_v2.allow_k8s_api"
  "openstack_networking_secgroup_rule_v2.allow_k8s_ports"
  "openstack_networking_secgroup_rule_v2.allow_kubelet_api"
  "openstack_networking_secgroup_rule_v2.allow_nodeport"
  "openstack_networking_secgroup_rule_v2.allow_ssh"
  "openstack_networking_secgroup_v2.k8s_secgroup"
  "openstack_networking_subnet_v2.k8s_subnet"
)

# Create variable to save resource state
all_resources_deployed=true

# Check the state for all expected resources
for resource in "${expected_resources[@]}"; do
  if ! terraform state list | grep -q "$resource"; then
    all_resources_deployed=false
    break
  fi
done

# Create or delete the marker file based on resource presence
if [ "$all_resources_deployed" = true ]; then
  touch "$marker_file"
  echo -e "Marker file created as all resources are deployed."
else
  rm -f "$marker_file"
  echo -e "Marker file removed due to incomplete deployment."
  exit 1  
fi