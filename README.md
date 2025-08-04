# Projects-AWS

Rental Car Web App on AWS with Terraform, Docker, Amazon ECR, and ECS
Excited to share the completion of my latest project: a fully functional Dynamic Web Application deployed and hosted on AWS using Terraform, Docker, Amazon ECR, and Amazon ECS!

This project stands out for its use of a wide array of AWS services, ensuring high availability, scalability, and security. It demonstrates the ability to architect and deploy complex infrastructure with modern DevOps practices.

![VPC Architecture Diagram](architecture_diagram.png)

Create a new repository on GitHub.
I’ve named mine: “car_rental_dynamic_web_app”

Create the remote backend
Open the location of the repository in VS Code

Create a new folder: mkdir remote_backend

Navigate to it: cd remote_backend

Create a new file: touch s3_dynamodb_state.tf

Copy it from the provided GitHub repository

Run:

· terraform init

· terraform apply

Create variables and tfvars files
Navigate to your repository directory: cd ..

Create 2 new files: touch variables.tf terraform.tfvars

Copy them from the provided GitHub repository

Create a .igitignore file
touch .gitignore

add the “terraform.tfvars” file inside it

Create new resource files
Create 6 new files:
· touch providers.tf backend.tf vpc.tf natgateway.tf security_groups.tf rds.tf

· Copy them from the provided GitHub repository

Run: terraform apply
Register a domain name on the AWS console
Register a domain name if you don’t have it still on Route53. This will cost around 14 dollars.


Create a private repository to store the application codes
Go to GitHub and create a new repository.

I’ve named mine “application-codes-autorentify-project”


Add it to the repository folder in your local machine

Open the repository “application-codes-autorentify-project” on VS code

Push it to GitHub “application-codes-autorentify-project”

Create a personal access token on github
This token will be used by docker to clone the application codes repository when we build our docker image

Github -> select your profile -> settings -> Developer settings -> Personal access tokens -> Tokens (classic) → Generate new token -> Generate new token classic

Edit it as you see in the following example:

![Access token diagram](picture1.png)


Remember to copy your personal access token and save it anywhere
Create a Dockerfile for a Dynamic Web App
Crete a new repository on GitHub and call it “docker-projects”

Open the repository docker-projects in VS Code

Create a new folder for the application.

· Run: mkdir rentzone

· cd rentzone

· touch Dockerfile


We will use a LAMP stack to build this application. A lamp stack is a group of open-source software that we can use to build a dynamic web application:



· Linux is the operating system we will use to run the stack.

· Apache is the software we will use to serve the website.

· MySQL is the engine we will use to run our database.

· php is the programming language used to build web applications.

On line 93 we will replace the file named “AppServiceProvider.php” on our server.
We do this because we want to upload a value in it, so when we redirect our traffic from http to https our website function properly.

· Create the replacement file in our project folder

o Copy “AppServiceProvider.php”

o In VS code navigate to rentzone folder

o Create a new file and name it “AppServiceProvider.php”


o This file is to redirect http traffic to https

Create a script to build the Docker image
Navigate to the “rentzone” directory in VS Code

Create a new file

o Run: touch build_image.ps1 (build_image.sh for mac)

Create a “.gitignore” file and add into it the “build_images.ps1”

Make the script executable
Windows:

· Open powershell by running it as administrator in your computer

· Run the following command: Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process

Mac:

· Run: chmod +x build_image.sh

Build the Docker Image
Make sure you have Docker running on your machine

Navigate to rentzone directory on VS Code

Use powershell terminal and run:

.\build.image.ps1 (build_image.sh for mac)

Run: docker image ls

Now we can see the image we just built

Create a repository in Amazon ECR
aws cli command to create an amazon ecr repository:
o aws ecr create-repository — repository-name — region

Navigate to rentzone directory on VS Code and run:
o aws ecr create-repository — repository-name rentzone — region eu-west-2

Push the Docker image to the Amazon ECR repository
Retag docker image
o Run: docker tag

· You can check the tag name you gave to your image by running “docker image ls”. In this case you will see the name “rentzone”

· In order to get the repository uri, go to ECR in the AWS console

login to ecr
Run: aws ecr get-login-password | docker login — username AWS — password-stdin <aws_account_id>.dkr.ecr..amazonaws.com

push docker image to ecr repository
Run: docker push

Run: docker tag rentzone 381491868231.dkr.ecr.eu-west-2.amazonaws.com/rentzone
If you run “docker image ls” you can check that the image was retagged succefully

Push the image into Amazon ECR
For this, first we need to login into ECR.

Run: aws ecr get-login-password | docker login — username AWS — password-stdin 381491868231.dkr.ecr.eu-west-2.amazonaws.com

Push the docker image into the ECR repository
Run: docker push 381491868231.dkr.ecr.eu-west-2.amazonaws.com/rentzone

Create Key pairs in AWS
touch key_pairs.tf

Copy it from the provided GitHub repository

Add the “my-ec2key.pem” to the .gitignore file

Set up a Bastion Host
touch bastion_host.tf

Copy it from the provided GitHub repository

We will use this bastion host to SSH into our RDS instance in the private subnet, so we can migrate our SQL data in to the RDS database.

Download and install Flyway into your computer
https://documentation.red-gate.com/fd/command-line-184127404.html?_ga=2.227219800.439967574.1689438755-1087648319.1689438670

If the sql folder is not included, you can create the folder yourself. Make sure to name the folder “sql”.

![sql](picture2.png)

Update flyway configuration file
It’s in this file where we enter the credentials of the database we want to connect to.

Open the flyway folder in VS Code

In the “conf” folder create a new file and name it “flyway.conf”

· touch flyway.conf

Write into it the following:


Add the SQL script to the SQL directory within the Flyway folder
Download it here:

https://drive.google.com/file/d/1H5Rdb15QsyaXF_Xauj9ODDP0O-yy3H5a/view

Move it to the SQL folder within the Flyway folder in your computer

Go to VS Code and rename this file to: V1__rentzone-db.sql (press 2 times on “underscore” between V1 and rentzone)

![sql](picture3.png)

Set up an SSH tunnel from our local computer to the Bastion Host
Once we do so, we can then use Flyway to migrate our data into the RDS database.

To create an ssh tunnel in linux or macOS, execute the following commands:
Be sure to replace YOUR_EC2_KEY, LOCAL_PORT, RDS_ENDPOINT, REMOTE_PORT, EC2_USER, and EC2_HOST with your relevant information.

To create an ssh tunnel in powershell, execute the following command:
ssh -i <key_pier.pem> ec2-user@ -L 3306::3306 -N

· <key_pier.pem> replace it with your key pair name

· replace it with the public ipv4 address of your Bastion Host

· replace with your rds endpoint



In VS Code navigate to the Flyway directory

Open a terminal and on the terminal, navigate into the directory where you stored your key pair. In my case was in the “autorentify-terraform-ecs” folder.

Run: ssh -i my-ec2key.pem ec2-user@3.10.19.71 -L 3306:dev-rds-db.c5emse6yqmwp.eu-west-2.rds.amazonaws.com:3306 -N

Then, without closing that terminal, open a new one. Make sure this new terminal is open on the Flyway directory.

Now, we will run the flyway migrate command to migrate our data into the rds database.

Run: .\flyway migrate

Create ALB and SSL Certificate
Navigate to your repository directory in VS Code

Create 2 new files:

· touch acm.tf alb.tf

Copy them from the provided GitHub repository
Create an environment file
We will now create an environment file to store the environment variables we defined in our Dockerfile.

Open “rentzone-dockerfile” directory in VS Code

cd rentzone

touch rentzone.env


Replace it with your own information

Add “rentzone.env” to the .gitignore

git add .

git commit -m “created environment files”

git push

Create a S3 bucket
This bucket will be used to upload the environment file we created.

When we create the ECS tags, the ECS tag will retrieve the environment variables from the file in the S3 bucket.

Copy the “rentzone.env” file that is in docker-projects > rentzone to your repository directory in VS Code


Add “rentzone.env” to .gitignore

Navigate to your repository directory in VS Code

touch s3.tf

Copy it from the provided GitHub repository

Create the task execution role for the ECS service
Navigate to your repository directory in VS Code

touch ecs_role.tf

Copy it from the provided GitHub repository

Launch the ECS service
Navigate to your repository directory in VS Code

touch ecs_role.tf

Copy it from the provided GitHub repository

Create an auto scaling group
We will now create an auto scaling group and connect it to the ECS service we created in the previously lecture.

Navigate to your repository directory in VS Code

touch asg.tf

Copy it from the provided GitHub repository

Create a Record Set in Route53
Navigate to your repository directory in VS Code

touch route53.tf

Copy it from the provided GitHub repository

Create an output to print the domain name
touch outputs.tf

Copy it from the provided GitHub repository

terraform init

terraform apply

![website](picture4.png)

Push the changes to GitHub
git add.

git commit -m “created project files”

git push