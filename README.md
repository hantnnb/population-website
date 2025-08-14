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
4. Add tfvars to envs folders
5. Review code files to change hardcoded variables to yours
      