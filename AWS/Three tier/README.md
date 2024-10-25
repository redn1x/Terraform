## Three Tier Terraform setup

## Overview 

 Qty   | Servers | Role                                                                                                  
--- | --- | ---
| 1     |  Application server  | This server run and manage the application code, processing user requests and generating responses.
| 1     | MSSQL server        | This server for transactional database. This server stores data related to day-to-day transactions such as sales or user activity.
| 1     |MSSQL server        | This  server is  for reporting database. This server stores data used for generating reports and performing analytics.
| 1     | license server      | This server manages licenses for software applications, verifying that users have valid licenses and controlling access.

## File Structure

* main.tf - call modules, locals, and data sources to create all resources
* variables.tf - contains declarations of variables used in main.tf
* outputs.tf - contains outputs from the resources created in main.tf
* windows-versions.tf - contains windows version requirements for Terraform and providers
* provider.tf - contains cloud provider, dynamo db , s3 bucket  and aws region


## Network Diagram

![image](https://github.com/user-attachments/assets/841596df-62b6-46a0-8e63-6e5a1dde9495)



## Prerequisite

[1. Install WSL subsystem](https://pureinfotech.com/install-windows-subsystem-linux-2-windows-10/#:~:text=To%20install%20WSL2%20on%20Windows,%E2%80%9Cwsl%20%E2%80%93update%E2%80%9D%20command.)

[2. Install Visual Studio](https://learn.microsoft.com/en-us/visualstudio/install/install-visual-studio?view=vs-2022)

[3. Install git](https://phoenixnap.com/kb/how-to-install-git-on-ubuntu)

[4. Generate programmatic access to AWS account](https://www.simplified.guide/aws/iam/create-programmatic-access-user)


## Install terraform

[What is terraform?](https://developer.hashicorp.com/terraform/intro)

[Download and install terraform on windows](https://phoenixnap.com/kb/how-to-install-terraform)


## Install Terraform on Ubuntu 

1. Open Ubuntu application (or your installed distro)
2. Update repository and other prerequisite

   `sudo apt-get update && sudo apt-get install -y gnupg software-properties-common`
    
3. Add terraform repository
```
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
    gpg --no-default-keyring     --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
```
3. Update respository again and download terraform: 
 
   `sudo apt update && udo apt-get install terraform`
   
4. Check terraform version:  

   ```
   francis@DESKTOP-9G1F39L:/mnt/c/Users/Desktop/cert$ terraform version                            
    Terraform v1.3.9
    on linux_amd64
   ```
   
    :+1:<i>***Terraform version should be Terraform v1.3.9***</i>

## Install AWS CLI

1. Update repository

   `sudo apt-get update`
  
2. Install aws cli

   `sudo apt-get install awscli` 
  
3. Check aws cli version
   ```
   francis@DESKTOP-9G1F39L:/mnt/c/Users/cert$ aws --version
   aws-cli/1.18.69 Python/3.6.9 Linux/4.4.0-19041-Microsoft botocore/1.16.19
   ```   

## Execute terraform

1. Input  access keys from AWS SSO [URL](https://oksy.awsapps.com/start/#/?tab=accounts)

2. Test programmatic access by doing this
   
     ```
     francis@DESKTOP-9G1F39L:/mnt/c/Users/cert$ aws s3 ls
     2023-04-03 17:17:58 fls-storage
  
     ```
3. Git clone repository:

   ```
   francis@DESKTOP-9G1F39L:/mnt/c/Users/ManuelFrancisDelgado/Desktop/testgit$ git clone git@github.com:Oksy-Tech-Group/Oksy.git
   Cloning into 'Oksy'...
   remote: Enumerating objects: 57, done.
   remote: Counting objects: 100% (57/57), done.
   remote: Compressing objects: 100% (55/55), done.
   remote: Total 57 (delta 30), reused 0 (delta 0), pack-reused 0
   Receiving objects: 100% (57/57), 18.13 KiB | 232.00 KiB/s, done.
   Resolving deltas: 100% (30/30), done.
   ```

4. Verify if the correct values are set in the providers.tf

```
terraform {
 backend "s3" {
    bucket         = "oksy-terraform-files"
    key            = "oksy/<env>/terraform.tfstate"
    region         = "us-west-1"
    dynamodb_table = "terraform-lock-table"
  }
}

```
5. Initialize s3 bucket

```
terraform init -backend-config="bucket=oksy-terraform-files"
```
6. Execute apply using terraform command below:

   ```
   terraform plan
   terraform apply
   ```
   
   
[🔼 Back to top](#oksy-stg)
