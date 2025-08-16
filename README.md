# population-website
<b>Description</b>: A practice project to deploy full-stack population data web application on GCP using Terraform and Cloudflare.

<b> Resources used:</b>
* GCP: VPC network, Compute Engine, IAM, Cloud Storage
* Terraform
* Cloudflare

<b> Sources: </b>
* https://gitlab.com/vuagia/population
* https://gitlab.com/vuagia/population_terraform


## Initial Setup
1. Create a project on GCP & enable required APIs:
    ```bash
    gcloud config set project <PROJECT_NAME>
    gcloud services enable compute.googleapis.com
    gcloud services enable iam.googleapis.com
    gcloud services enable iamcredentials.googleapis.com
    gcloud services enable storage.googleapis.com
    ```

2. Create a GCP bucket for terraform state + protect it:
    ```bash
    # Ex: BUCKET_NAME: <YOUR_PROJECT_ID>-terraform-state
    gcloud storage buckets create gs://<BUCKET_NAME> --location=ASIA-SOUTHEAST1
    gcloud storage buckets update gs://<BUCKET_NAME> --versioning
    gcloud storage buckets update gs://<BUCKET_NAME> --public-access-prevention=enforced
    gsutil uniformbucketlevelaccess set on gs://<BUCKET_NAME>

    # Verify
    gsutil ls -Lb gs://<BUCKET_NAME> | egrep 'Uniform bucket-level access|Public access prevention|Versioning'
    ```
    (Optional) - Set CMEK for bucket

3. Create the terraform service account + grant least-privilege
    ```bash
    # Create SA
    gcloud iam service-accounts create terraform --display-name="Terraform SA"

    # Grant bucket access for state
    gcloud storage buckets add-iam-policy-binding gs://<BUCKET_NAME> \
    --member=serviceAccount:terraform@<PROJECT_ID>.iam.gserviceaccount.com \
    --role=roles/storage.objectAdmin
    ```
    (Optional) If CMEK is enable, you have to allow KMS encrypt/decrypt

4. Grant project roles Terraform needs
    ```bash
    # Full control over VM instances
    gcloud projects add-iam-policy-binding <PROJECT_ID> \
    --member=serviceAccount:terraform@<PROJECT_ID>.iam.gserviceaccount.com \
    --role=roles/compute.instanceAdmin.v1

    # Full control over network (VPC, subnets, firewalls, routes)
    gcloud projects add-iam-policy-binding <PROJECT_ID> \
    --member=serviceAccount:terraform@<PROJECT_ID>.iam.gserviceaccount.com \
    --role=roles/compute.networkAdmin

    # Read-only access to everything in the project
    gcloud projects add-iam-policy-binding <PROJECT_ID> \
    --member=serviceAccount:terraform@<PROJECT_ID>.iam.gserviceaccount.com \
    --role=roles/viewer
    ```

5. Clone the repo: `git clone https://github.com/hantnnb/population-website.git`
6. Add your tfvars file to `terraform/envs/<ENVIRONMENT>`
7. Replace hardcoded variables with your own values
8. Change into `terraform/envs/<ENVIRONMENT>` directory and run `terraform init`s
9. Run `terraform apply`

## Github Actions
1. Generate SSH key for Github -> VM and add the public key to VM's authorized_keys
    ```bash
    # Generate a key
    ssh-keygen -t ed25519 -C "gh-actions -> vm" -f ./vm_deploy_key -N ""

    # Copy public key to VM's ~/.ssh/authorized_keys
    cat vm_deploy_key.pub | ssh <VM_USER>@<VM_IP> 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys'

    # Clean up SSH's known_hosts files (if prompt):
    ssh-keygen -f "/home/<YOUR_GG_USERNAME>/.ssh/known_hosts" -R "<VM_IP>"
    ```

2. Add Github Action secrets (manully in repo Settings -> Secrets -> Actions)
    * VM_HOST: <VM_IP> (or your DNS)
    * VM_USER: <VM_USER>
    * VM_PATH: <PATH_TO_REPO> (e.g., /opt/population-website)
    * VM_SSH_KEY: <VM_DEPLOY_KEY> (private key)

3. Create a deploy.sh script (so YAML stay cleans), put it in:
    * Root directory for a centralize script
    * OR terraform/envs/dev directory for separate environment, but need to duplicate for other environments

4. Make the deploy.sh executable (one-time on VM)
    ```bash
    ssh <VM_USER>@<VM_HOST> 'chmod +x /opt/population-website/terraform/envs/dev/deploy.sh'

    # If permission denied, do the following:
    gcloud compute ssh <VM_NAME> --zone=<ZONE>
    sudo -u ubuntu mkdir -p /home/ubuntu/.ssh
    sudo -u ubuntu chmod 700 /home/ubuntu/.ssh
    echo "<contents of vm_deploy_key.pub>" | sudo tee -a /home/ubuntu/.ssh/authorized_keys
    sudo -u ubuntu chmod 600 /home/ubuntu/.ssh/authorized_keys

    # Go back to your terminal or cloudshell to run this:
    ssh -i vm_deploy_key ubuntu@<VM_IP>
    ```
5. Add Github Actions workflow `.github/workflows/deploy.yml`