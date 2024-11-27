# -----------------------------------------------------------------------------------
# Initializing VM Instances for Kubernetes Cluster w/ Terraform Config and OpenStack.             ~ z o e n i X 
# -----------------------------------------------------------------------------------

# This Terraform configuration sets up the necessary network infrastructure and VM instances for Kubernetes deployment.

# Defining required providers Terraform:
    terraform {
      required_version = ">= 0.14.0"
      required_providers {
        openstack = {
          source  = "terraform-provider-openstack/openstack"
          version = "~> 1.53.0"
        }
      }
    }

    provider "openstack" {
      user_name        = "group_27_IKT210"
      tenant_name      = "group_27_IKT210_7c9c72b9"
      password         = "7c9c72b9f6b3420abb965b4fd4565538"
      auth_url         = "http://kaun.uia.no:5000/v3"
      domain_name      = "Default"
      user_domain_name = "Default"
    }


# _____________________________________________________________ ADDITIONAL CONFIGURATIONS _____________________________________________________________

# ---------------------------
# Check & Validate Workspace 
# ---------------------------

#   - Validates the user's workspace using an external script (check_workspace.sh).
#   - Issues a warning and exits if current workspace already has a configured infrastructure. 

# Define command_type for interactive prompts (apply, plan).
variable "command_type" {
  description = "\n\n Configuration check! Only accepted input is: 'apply' or 'plan' or 'destroy', or 'skip' for other terraform commands. \n\n This is an interactive command prompt that enables a custom script to validates your workspace.\n\n"
  validation {
    condition     = contains(["apply", "plan", "destroy", "refresh", "skip"], var.command_type)
    error_message = "\n\n Invalid command. Type the string identical without <>: <apply>, <plan>, <destroy>, or type <skip> for other commands."
  }
}

# Pass both command_type and prompt_answer to the script.
data "external" "check_workspace" {
  program = ["bash", "${path.module}/check_workspace.sh", var.command_type]
}

# Output to display custom messages from the workspace check script.
output "workspace_check_message" {
  value       = data.external.check_workspace.result.custom_output
  description = "Shows custom output messages from the workspace check script."
}

# Output for warnings from the workspace check script
output "workspace_warning_message" {
  value       = data.external.check_workspace.result.warning_message
  description = "Shows warning messages from the workspace check script."
}


# ---------------------------
# Marker File Management
# ---------------------------

# Execute the marker management script to check if marker file exists
resource "null_resource" "manage_marker_file" {
  provisioner "local-exec" {
    command = "bash ${path.module}/manage_marker.sh"
  }

  # Define dependencies to ensure this runs only after all critical resources are created
  depends_on = [
    openstack_compute_floatingip_associate_v2.fip_master_associate,
    openstack_compute_floatingip_associate_v2.fip_worker1_associate,
    openstack_compute_floatingip_associate_v2.fip_worker2_associate,
    openstack_compute_instance_v2.master_node,
    openstack_compute_instance_v2.worker_node_1,
    openstack_compute_instance_v2.worker_node_2,
    openstack_networking_floatingip_v2.fip_master,
    openstack_networking_floatingip_v2.fip_worker1,
    openstack_networking_floatingip_v2.fip_worker2,
    openstack_networking_network_v2.k8s_network,
    openstack_networking_router_interface_v2.k8s_router_interface,
    openstack_networking_router_v2.k8s_router,
    openstack_networking_secgroup_rule_v2.allow_etcd,
    openstack_networking_secgroup_rule_v2.allow_http,
    openstack_networking_secgroup_rule_v2.allow_icmp,
    openstack_networking_secgroup_rule_v2.allow_k8s_api,
    openstack_networking_secgroup_rule_v2.allow_k8s_ports,
    openstack_networking_secgroup_rule_v2.allow_kubelet_api,
    openstack_networking_secgroup_rule_v2.allow_nodeport,
    openstack_networking_secgroup_rule_v2.allow_ssh,
    openstack_networking_secgroup_v2.k8s_secgroup,
    openstack_networking_subnet_v2.k8s_subnet
  ]
}

# --------------------------
# Creating Unique Resources  
# --------------------------

# Assigning Unique ID to Resources in Non-Default Workspaces:
resource "random_id" "unique_id" {
  count       = terraform.workspace != "default" ? 1 : 0
  byte_length = 2
}

locals {
  resource_suffix = terraform.workspace != "default" && length(random_id.unique_id) > 0 ? "~:${random_id.unique_id[0].hex}" : ""
}      

#   - This guarantees that each new workspace creates uniquely named resources, avoiding infrastructure conflicts.
#   - Example usage: <name = "k8s_network${local.resource_suffix}">
#   - Apply the unique suffix with local variables.


# --------------------------
# SSH Keypair Configuration
# --------------------------

#   - Check if the combined keypair already exists in OpenStack:
data "external" "check_combined_keypair" {
  program = ["bash", "${path.module}/check_keypair.sh", "combined-keypair"]
}

# Create the keypair for student & teacher if it doesn’t exist
resource "openstack_compute_keypair_v2" "combined_key" {
  count      = data.external.check_combined_keypair.result.exists == "false" ? 1 : 0
  name       = "combined-keypair${local.resource_suffix}"
  public_key = <<EOF
${var.personal_public_key}
${var.admin_public_key}
EOF
}

# Reference combined_key without indexing
locals {
  combined_key_name = length(openstack_compute_keypair_v2.combined_key) > 0 ? openstack_compute_keypair_v2.combined_key[0].name : ""
}

# __________________________________________________________ END OF ADDITIONAL CONFIGURATIONS __________________________________________________________


# ---------------------------------------------
# Networking Configurations
# ---------------------------------------------

# Query the external network
data "openstack_networking_network_v2" "external" {
  name = "provider"                                
}                                                 

# Create a network with port security enabled
resource "openstack_networking_network_v2" "k8s_network" {
  name                  = "k8s-network${local.resource_suffix}"
  port_security_enabled = true

}

# Create a router
resource "openstack_networking_router_v2" "k8s_router" {
  name               = "k8s-router${local.resource_suffix}"
  external_network_id = data.openstack_networking_network_v2.external.id
}

# Create a subnet within the network
resource "openstack_networking_subnet_v2" "k8s_subnet" {
  network_id      = openstack_networking_network_v2.k8s_network.id
  name            = "k8s-subnet${local.resource_suffix}"
  cidr            = "172.16.0.0/24" 
  ip_version      = 4
  dns_nameservers = ["158.37.218.20", "158.37.218.21", "158.37.242.20", "158.37.242.21", "128.39.54.10"]
}


# Connect router to the subnet
resource "openstack_networking_router_interface_v2" "k8s_router_interface" {
  router_id = openstack_networking_router_v2.k8s_router.id
  subnet_id = openstack_networking_subnet_v2.k8s_subnet.id
}


# ---------------------------------------------
# Create VM Instances (Master and Worker Nodes)
# ---------------------------------------------

# Create security group
resource "openstack_networking_secgroup_v2" "k8s_secgroup" {
  name = "k8s-secgroup${local.resource_suffix}"
}

# Floating IP for master node
resource "openstack_networking_floatingip_v2" "fip_master" {
  pool = "provider"
}

# Master node configuration
resource "openstack_compute_instance_v2" "master_node" {
  name            = "master-node${local.resource_suffix}"
  image_name      = "ubuntu-noble"
  flavor_name     = "medium"
  key_pair        = local.combined_key_name
  security_groups = [openstack_networking_secgroup_v2.k8s_secgroup.name]
  network {
    uuid = openstack_networking_network_v2.k8s_network.id
  }
}

# Associate floating IP with master node
resource "openstack_compute_floatingip_associate_v2" "fip_master_associate" {
  floating_ip = openstack_networking_floatingip_v2.fip_master.address
  instance_id = openstack_compute_instance_v2.master_node.id
}

# Floating IP for worker node 1
resource "openstack_networking_floatingip_v2" "fip_worker1" {
  pool = "provider"
}

# Worker node 1 configuration
resource "openstack_compute_instance_v2" "worker_node_1" {
  name            = "worker-node-1${local.resource_suffix}"
  image_name      = "ubuntu-noble"
  flavor_name     = "medium"
  key_pair        = local.combined_key_name
  security_groups = [openstack_networking_secgroup_v2.k8s_secgroup.name]
  network {
    uuid = openstack_networking_network_v2.k8s_network.id
  }
}

# Associate floating IP with worker node 1
resource "openstack_compute_floatingip_associate_v2" "fip_worker1_associate" {
  floating_ip = openstack_networking_floatingip_v2.fip_worker1.address
  instance_id = openstack_compute_instance_v2.worker_node_1.id
}

# Floating IP for worker node 2
resource "openstack_networking_floatingip_v2" "fip_worker2" {
  pool = "provider"
}

# Worker node 2 configuration
resource "openstack_compute_instance_v2" "worker_node_2" {
  name            = "worker-node-2${local.resource_suffix}"
  image_name      = "ubuntu-noble"
  flavor_name     = "medium"
  key_pair        = local.combined_key_name
  security_groups = [openstack_networking_secgroup_v2.k8s_secgroup.name]
  network {
    uuid = openstack_networking_network_v2.k8s_network.id
  }
}

# Associate floating IP with worker node 2
resource "openstack_compute_floatingip_associate_v2" "fip_worker2_associate" {
  floating_ip = openstack_networking_floatingip_v2.fip_worker2.address
  instance_id = openstack_compute_instance_v2.worker_node_2.id
}


# -------------------------------
# Security Groups Rules for Nodes
# -------------------------------

# Defining individual port-rules for the security group:

  # Allow SSH access (port 22)
  resource "openstack_networking_secgroup_rule_v2" "allow_ssh" {
    direction         = "ingress"
    ethertype         = "IPv4"
    protocol          = "tcp"
    port_range_min    = 22
    port_range_max    = 22
    remote_ip_prefix  = "0.0.0.0/0"
    security_group_id = openstack_networking_secgroup_v2.k8s_secgroup.id
  }

  # Allow Kubernetes API (port 6443)
  resource "openstack_networking_secgroup_rule_v2" "allow_k8s_api" {
    direction         = "ingress"
    ethertype         = "IPv4"
    protocol          = "tcp"
    port_range_min    = 6443
    port_range_max    = 6443
    remote_ip_prefix  = "0.0.0.0/0"
    security_group_id = openstack_networking_secgroup_v2.k8s_secgroup.id
  }

  # Allow Kubelet API (port 10250)
  resource "openstack_networking_secgroup_rule_v2" "allow_kubelet_api" {
    direction         = "ingress"
    ethertype         = "IPv4"
    protocol          = "tcp"
    port_range_min    = 10250
    port_range_max    = 10250
    remote_ip_prefix  = "172.16.0.0/24"
    security_group_id = openstack_networking_secgroup_v2.k8s_secgroup.id
  }

  # Allow NodePort services (ports 30000-32767)
  resource "openstack_networking_secgroup_rule_v2" "allow_nodeport" {
    direction         = "ingress"
    ethertype         = "IPv4"
    protocol          = "tcp"
    port_range_min    = 30000
    port_range_max    = 32767
    remote_ip_prefix  = "0.0.0.0/0"
    security_group_id = openstack_networking_secgroup_v2.k8s_secgroup.id
  }

  # Allow additional Kubernetes ports (e.g., scheduler, controller manager)
  resource "openstack_networking_secgroup_rule_v2" "allow_k8s_ports" {
    direction         = "ingress"
    ethertype         = "IPv4"
    protocol          = "tcp"
    port_range_min    = 10257
    port_range_max    = 10259
    remote_ip_prefix  = "0.0.0.0/0"
    security_group_id = openstack_networking_secgroup_v2.k8s_secgroup.id
  }

  # Allow etcd access (ports 2379-2380)
  resource "openstack_networking_secgroup_rule_v2" "allow_etcd" {
    direction         = "ingress"
    ethertype         = "IPv4"
    protocol          = "tcp"
    port_range_min    = 2379
    port_range_max    = 2380
    remote_ip_prefix  = "172.16.0.0/24"
    security_group_id = openstack_networking_secgroup_v2.k8s_secgroup.id
  }

  # Allow HTTP traffic (port 80)
  resource "openstack_networking_secgroup_rule_v2" "allow_http" {
    direction         = "ingress"
    ethertype         = "IPv4"
    protocol          = "tcp"
    port_range_min    = 80
    port_range_max    = 80
    remote_ip_prefix  = "0.0.0.0/0"
    security_group_id = openstack_networking_secgroup_v2.k8s_secgroup.id
  }

  # Allow ICMP (ping) within the security group
  resource "openstack_networking_secgroup_rule_v2" "allow_icmp" {
    direction         = "ingress"
    ethertype         = "IPv4"
    protocol          = "icmp"
    remote_ip_prefix  = "172.16.0.0/24"  # Restrict to the private subnet range
    security_group_id = openstack_networking_secgroup_v2.k8s_secgroup.id
  }