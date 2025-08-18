# Population Website Practice Project
<b>Description</b>: Practice project to deploy a full-stack population data web app on GCP using Terraform and Cloudflare.

<b> Resources used:</b>
* GCP: VPC, subnets, firewall rules, Compute Engine, IAM, Cloud Storage
* Terraform (remote state in GCS)
* Cloudflare (DNS + proxy)

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
    gcloud storage buckets update gs://<BUCKET_NAME> --public-access-prevention
    gsutil uniformbucketlevelaccess set on gs://<BUCKET_NAME>

    # Verify
    gsutil ls -Lb gs://<BUCKET_NAME> | egrep 'Uniform bucket-level access|Public access prevention|Versioning'
    ```

3. Create the Terraform Service Account (SA), grant state-bucket access, allow impersonation
    ```bash
    # Create SA
    gcloud iam service-accounts create terraform --display-name="Terraform SA"

    # Grant bucket access for state (UBLA requires bucket-level IAM)
    gcloud storage buckets add-iam-policy-binding gs://<BUCKET_NAME> \
    --member=serviceAccount:terraform@<PROJECT_ID>.iam.gserviceaccount.com \
    --role=roles/storage.objectAdmin

    # Let you impersonate the SA to run terraform locally or Cloud Shell
    gcloud iam service-accounts add-iam-policy-binding terraform@<PROJECT_ID>.iam.gserviceaccount.com \
    --member="user:<YOUR_GG_EMAIL>" \
    --role="roles/iam.serviceAccountTokenCreator"

    # Tell Cloud SDK / client libraries (Terraform provider, GCS backend) to impersonate the above SA when making APIs 
    # Avoid using your Gmail identity
    export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=terraform@population-website.iam.gserviceaccount.com
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

    # Full control over bucket
    gcloud projects add-iam-policy-binding <PROJECT_ID> \
    --member="serviceAccount:terraform@<PROJECT_ID>.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

    # Read-only access to everything in the project
    gcloud projects add-iam-policy-binding <PROJECT_ID> \
    --member=serviceAccount:terraform@<PROJECT_ID>.iam.gserviceaccount.com \
    --role=roles/viewer

    # Let the caller USE services in the project
    gcloud projects add-iam-policy-binding <PROJECT_ID> \
    --member="serviceAccount:terraform@<PROJECT_ID>.iam.gserviceaccount.com" \
    --role="roles/serviceusage.serviceUsageConsumer"

    # Let the caller ENABLE/DISABLE services (needed by google_project_service)
    gcloud projects add-iam-policy-binding <PROJECT_ID> \
    --member="serviceAccount:terraform@<PROJECT_ID>.iam.gserviceaccount.com" \
    --role="roles/serviceusage.serviceUsageAdmin"
    ```

5. Clone the repo: `git clone https://github.com/hantnnb/population-website.git`
6. Add your tfvars file to `terraform/envs/<ENVIRONMENT>`
7. Replace hardcoded variables with your own values
8. Change into `terraform/envs/<ENVIRONMENT>` directory and run `terraform init`
9. Run `terraform plan` first to see detail or `terraform apply`

## Github Actions
1. Generate SSH key for Github -> VM and add the public key to VM's authorized_keys
    ```bash
    # Generate a key
    ssh-keygen -t ed25519 -C "gh-actions -> vm" -f ./vm_deploy_key -N ""

2. Add Github Actions workflow `.github/workflows/deploy.yml`