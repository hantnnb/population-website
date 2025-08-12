# population-website

1. Enable required APIs
2. Create bucket for backend storage
    ```bash
    # Create a bucket for Terraform state
    gsutil mb gs://YOUR_PROJECT_ID-terraform-state
    
    # Enable versioning for state backup
    gsutil versioning set on gs://YOUR_PROJECT_ID-terraform-state
    ``` 
3. Clone the app from: https://gitlab.com/vuagia/population.git
4. Write terraform configuration files
      