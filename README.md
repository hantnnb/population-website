# population-website

1. Enable required APIs
2. Create bucket for backend storage
    ```bash
    # Create a bucket for Terraform state
    gsutil mb gs://YOUR_PROJECT_ID-terraform-state
    
    # Enable versioning for state backup
    gsutil versioning set on gs://YOUR_PROJECT_ID-terraform-state
    ``` 
3. Clone the app from: https://github.com/hantnnb/population-website.git
4. Add tfvars to envs/<env-name> folders
5. Review code files to change hardcoded variables to yours
6. Generate SSH Key (run on local or Cloud Shell)
    ```bash
    # This create 2 files: 
    #   - github_action_key -> private key (keep safe, add to Github secret)
    #   - github_actions_key.pub → public key (goes on VM)
    ssh-keygen -t ed25519 -C "github-actions" -f ./github_actions_key -N ""
    ``` 
7. Add public key to VM
    ```bash
    # Run this on local or Cloud Shell, replace VM_IP with your VM's IP
    # Copy the public key file to the VM
    gcloud compute scp ./github_actions_key.pub ubuntu@<your-vm-name>:/tmp/gh_key.pub --zone=<your-zone>

    # SSH into the VM using your GCP account
    gcloud compute ssh ubuntu@pplt-dev-vm --zone=asia-southeast1-a

    # On the VM:
    mkdir -p ~/.ssh
    cat /tmp/gh_key.pub >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    rm /tmp/gh_key.pub
    ```    
8. Add Github secrets/variables
