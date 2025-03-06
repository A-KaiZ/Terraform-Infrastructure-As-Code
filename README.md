## **Getting Started**

This project demonstrates how to provision a Kubernetes-ready network infrastructure on OpenStack using Terraform. The setup includes three virtual machines with pre-configured networking, ready for manual Kubernetes installation or other cloud-native configurations. It showcases foundational DevOps principles, automation through custom scripts, and the flexibility of Infrastructure as Code (IaC). Make sure you have access to your own OpenStack credentials if you want to fork this project. 

Custom automation scripts are included to handle essential infrastructure tasks such as keypair validation, workspace state management, and environment configuration. These scripts are executed automatically during Terraform commands like apply, destroy, plan, and refresh. While primarily developed for educational purposes, they serve as an example of integrating automation into infrastructure workflows. Contributions are welcome—feel free to submit a pull request to improve the project!

## **Key Features**
- Automated provisioning of **three VMs** on OpenStack.
- Pre-configured networking and floating IPs for external connectivity.
- Custom shell scripts for workspace validation and keypair management.
- Flexible configurations for Kubernetes deployment.

## **Custom Scripts**

The repository includes several custom scripts executed automatically during Terraform commands (`apply`, `destroy`, `plan`, and `refresh`). These scripts are meant for managing the infrastructure safely and improving workflows:

### **Scripts Overview**
1. **`check_keypair.sh`**
   - Validates the existence of an SSH keypair in OpenStack before creating a new one.
   - Prevents duplicate keypair creation, ensuring streamlined access management.
   - Integrated within Terraform to manage two seperate keypairs, e.g. student or teacher. 

2. **`check_workspace.sh`**
   - Verifies the active state of the Terraform workspace to prevent accidental modifications.
   - Uses a marker file to indicate the readiness of the workspace.
   - Ensures that infrastructure changes occur only when the workspace is in the correct state.

3. **`manage_marker.sh`**
   - Manages the creation and removal of a marker file that signals active infrastructure.
   - Used alongside `check_workspace.sh` for safe infrastructure modifications.

4. **`openstack_credentials.sh`**
   - Loads OpenStack credentials securely from a `.env` file.
   - Simplifies credential management by externalizing sensitive details.

---

## **Prerequisites**

To use this project, ensure you have the following:

- OpenStack CLI installed.
- Access to an OpenStack environment.
- Terraform installed locally.
- A valid `.env` file containing your OpenStack credentials.

---

## **Setup Instructions**

### Step 1: Clone the Repository

```bash
git clone <repository-url>
cd <repository-folder>
```

---

### Step 2: Update Your OpenStack Credentials

1. Locate the `.env` file in the root directory of this project. This file contains placeholders for your OpenStack credentials.

2. Open the file using your preferred text editor:
    ```bash
    nano .env
    ```

3. Update the file with your OpenStack credentials:
   ```bash
   OS_USERNAME=your_openstack_username
   OS_PROJECT_NAME=your_project_name
   OS_PASSWORD=your_password
   OS_AUTH_URL=http://your_openstack_auth_url/v3
   ```

4. (Optional) If your environment uses custom domain names, you can update these fields:
   ```bash
   OS_USER_DOMAIN_NAME=your_user_domain_name
   OS_PROJECT_DOMAIN_NAME=your_project_domain_name
   ```

5. Save the file and ensure it is not committed to version control. The `.env` file is already included in the `.gitignore` for your convenience.

> **Note:** If the credentials are incorrect, Terraform will fail to authenticate with OpenStack. Make sure you validate your credentials with the OpenStack CLI (`openstack server list`) before proceeding.

4. Save the file.

---

### Step 3: Configure SSH Keys

1. Open the `variables.tf` file and provide your public SSH key(s):
   ```hcl
   variable "personal_public_key" {
     default = "your_personal_public_key_here"
   }

   variable "admin_public_key" {
     default = "your_admin_public_key_here"
   }
   ```

2. If you don’t have a public key, you can generate one using:
   ```bash
   ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
   ```

---

### Step 4: Initialize Terraform

Run the following commands to initialize Terraform and validate the setup:
```bash
terraform init
terraform validate
```

---

### **Step 5: Deploy the Infrastructure**
Run the following commands in sequence:
1. **Plan Infrastructure**
   ```bash
   terraform plan
   ```
2. **Apply Changes**
   ```bash
   terraform apply
   ```
   The custom scripts will automatically execute, managing keypairs and workspace markers. Please read the prompts carefully, and specify the terraform command used.
   
4. Review the changes and type `yes` to confirm.

---

### Step 6: Verifying the Setup

Once deployed, Terraform will output the created resources. Ensure everything is set up by:

1. Logging into the OpenStack dashboard.
2. Checking the three virtual machines and their network settings.
3. Using `ssh` to access the instances (use the private key corresponding to the public key you specified).

---

### Notes for Customization

- **Credentials:** Credentials are securely managed using a `.env` file and are not hardcoded for security reasons. Always keep the `.env` file private and excluded from version control.
- **SSH Keys:** Ensure your public SSH keys are correctly added to `variables.tf` to access the instances.
- **OpenStack Authentication:** If there are any issues, confirm your OpenStack credentials and API access using the OpenStack CLI (`openstack server list`).

---

## **Learning Outcomes**
- **Infrastructure as Code (IaC):** Streamline cloud resource provisioning using Terraform.
- **Custom Automation:** Enhance operational workflows with custom scripts.
- **Cloud Networking:** Configure secure and efficient networking for multi-node setups.
- **Kubernetes Ready:** Prepare infrastructure for Kubernetes cluster installation and management.

---

## **Acknowledgments**

This project follows DevOps best practices for infrastructure provisioning using Terraform and is designed for educational purposes to demonstrate infrastructure as code. 

For any issues or questions, feel free to raise an issue in the repository.
