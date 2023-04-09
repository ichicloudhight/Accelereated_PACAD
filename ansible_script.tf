locals {
  ansible_user_data = <<-EOF
#!/bin/bash
sudo yum update -y
sudo yum upgrade -y
sudo yum install python3.8 -y
sudo alternatives --set python /usr/bin/python3.8
sudo yum -y install python3-pip
sudo yum install ansible -y
pip3 install ansible --user
sudo chown ec2-user:ec2-user /etc/ansible
ansible-galaxy collection install amazon.aws
pip3 install boto3
#NEW RELIC SETUP
echo "license_key: eu01xx7f52e170948bda373b5b56692bc00aNRAL" | sudo tee -a /etc/newrelic-infra.yml
sudo curl -o /etc/yum.repos.d/newrelic-infra.repo https://download.newrelic.com/infrastructure_agent/linux/yum/el/7/x86_64/newrelic-infra.repo
sudo yum -q makecache -y --disablerepo='*' --enablerepo='newrelic-infra'
sudo yum install newrelic-infra -y
echo "PubkeyAcceptedKeyTypes=+ssh-rsa" >> /etc/ssh/ssh_config.d/10-insecure-rsa-keysig.conf
sudo service sshd reload
sudo bash -c ' echo "StrictHostKeyChecking No" >> /etc/ssh/ssh_config'
echo "${tls_private_key.client3_key.private_key_pem}" >> /home/ec2-user/.ssh/anskey_rsa
sudo chmod 400 anskey_rsa
sudo chmod -R 700 .ssh/
sudo chown -R ec2-user:ec2-user .ssh/
sudo yum install -y yum-utils
#DOCKER HUB CONFIGURATION
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce -y
sudo systemctl start docker
sudo usermod -aG docker ec2-user
#CHANGE OWNERSHIP OF DIRECTORY TO EC2-USER
cd /etc
sudo chown ec2-user:ec2-user hosts
cat <<EOT>> /etc/ansible/hosts
localhost ansible_connection=local
[docker_stage]
${data.aws_instance.client3_docker_stage.private_ip}  ansible_ssh_private_key_file=/home/ec2-user/.ssh/anskey_rsa
[docker_prod]
${data.aws_instance.client3_docker_prod.private_ip}  ansible_ssh_private_key_file=/home/ec2-user/.ssh/anskey_rsa
EOT
sudo mkdir /opt/docker
sudo chown -R ec2-user:ec2-user /opt/docker
sudo chmod -R 700 /opt/docker
touch /opt/docker/Dockerfile
cat <<EOT>> /opt/docker/Dockerfile
# pull tomcat image from docker hub
FROM tomcat
FROM openjdk:8-jre-slim
#copy war file on the container
COPY spring-petclinic-2.4.2.war app/
WORKDIR app/
RUN pwd
RUN ls -al
ENTRYPOINT [ "java", "-jar", "spring-petclinic-2.4.2.war", "--server.port=8085"]
EOT
touch /opt/docker/docker-image.yml
cat <<EOT>> /opt/docker/docker-image.yml
---
 - hosts: localhost
  #root access to user
   become: true
   tasks:
   - name: login to dockerhub
     command: docker login -u cloudhight -p CloudHight_Admin123@
   - name: Create docker image from Pet Adoption war file
     command: docker build -t pet-adoption-image .
     args:
       chdir: /opt/docker
   - name: Add tag to image
     command: docker tag pet-adoption-image cloudhight/pet-adoption-image
   - name: Push image to docker hub
     command: docker push cloudhight/pet-adoption-image
   - name: Remove docker image from Ansible node
     command: docker rmi pet-adoption-image cloudhight/pet-adoption-image
     ignore_errors: yes
EOT
touch /opt/docker/docker-prod.yml
cat <<EOT>> /opt/docker/docker-prod.yml
---
 - hosts: docker_prod
   become: true
   tasks:
   - name: login to dockerhub
     command: docker login -u cloudhight -p CloudHight_Admin123@
   - name: Stop any container running
     command: docker stop pet-adoption-container
     ignore_errors: yes
   - name: Remove stopped container
     command: docker rm pet-adoption-container
     ignore_errors: yes
   - name: Remove docker image
     command: docker rmi cloudhight/pet-adoption-image
     ignore_errors: yes
   - name: Pull docker image from dockerhub
     command: docker pull cloudhight/pet-adoption-image
     ignore_errors: yes
   - name: Create container from pet adoption image
     command: docker run -it -d --name pet-adoption-container -p 8080:8085 cloudhight/pet-adoption-image
     ignore_errors: yes
EOT

touch /opt/docker/docker-stage.yml
cat <<EOT>> /opt/docker/docker-stage.yml
---
 - hosts: docker_stage
   become: true
   tasks:
   - name: login to dockerhub
     command: docker login -u cloudhight -p CloudHight_Admin123@
   - name: Stop any container running
     command: docker stop pet-adoption-container
     ignore_errors: yes
   - name: Remove stopped container
     command: docker rm pet-adoption-container
     ignore_errors: yes
   - name: Remove docker image
     command: docker rmi cloudhight/pet-adoption-image
     ignore_errors: yes
   - name: Pull docker image from dockerhub
     command: docker pull cloudhight/pet-adoption-image
     ignore_errors: yes
   - name: Create container from pet adoption image
     command: docker run -it -d --name pet-adoption-container -p 8080:8085 cloudhight/pet-adoption-image
     ignore_errors: yes
EOT

touch /opt/docker/ASG-container.yml
cat <<EOT>> /opt/docker/ASG-container.yml
---
 - hosts: asg-servers
   become: true
   tasks:
   - name: login to dockerhub
     command: docker login -u cloudhight -p CloudHight_Admin123@
   - name: Stop any container running
     command: docker stop pet-adoption-container
     ignore_errors: yes
   - name: Remove stopped container
     command: docker rm pet-adoption-container
     ignore_errors: yes
   - name: Remove docker image
     command: docker rmi cloudhight/pet-adoption-image
     ignore_errors: yes
   - name: Pull docker image from dockerhub
     command: docker pull cloudhight/pet-adoption-image
     ignore_errors: yes
   - name: Create container from pet adoption image
     command: docker run -it -d --name pet-adoption-container -p 8080:8085 cloudhight/pet-adoption-image
     ignore_errors: yes
EOT

# touch /opt/docker/ASG-container.yml
# cat <<EOT>> /opt/docker/Autodiscovery.yml
# ---
#  - hosts: localhost
#    connection: local
#    user: ec2-user
#    tasks:

#    - name: Get IP Address in  Inventory Host File /etc/ansible/hosts
#      set_fact:
#        stage="{{ groups['docker_stage'] | join(',')}}"
#        prod="{{ groups['docker_prod']  | join (',')}}"

#    - name: Store Oringinal IP Address of Inventory Host File in a file
#      shell: |
#         echo "{{stage}} ansible_ssh_private_key_file=/home/ec2-user/.ssh/anskey_rsa" > /home/ec2-user/yml/stageIp.yml
#         echo "{{prod}}  ansible_ssh_private_key_file=/home/ec2-user/.ssh/anskey_rsa" > /home/ec2-user/yml/prodIp.yml

#    - name: Get list of running new EC2 instances created by ASG
#      amazon.aws.ec2_instance_info:
#        region: eu-west-2
#        filters:
#          "tag:Name": ["client3-asg"]
#      register: ec2_instance_info

#    - set_fact:
#        msg: "{{ ec2_instance_info | json_query('instances[*].private_ip_address') }}"
#    - debug:
#         var: msg
#      register: ec2_ip

#    - name : Store new ec2 by ASG IP in a file
#      shell: |
#         echo "{{msg}}" > ~/yml/asg-serversIP.yml

#    - name: update new ec2 IP in inventory file
#      become: yes
#      shell: |
#          echo  "[client3-asg]" > /etc/ansible/hosts;
#          {% for ip in range(ec2_ip['msg']|length)%}
#          echo "{{ec2_ip['msg'][ip]}} ansible_ssh_private_key_file=/home/ec2-user/.ssh/anskey_rsa
#          {%endfor%}
#          echo  "[docker_stage]" >> /etc/ansible/hosts
#          cat   /home/ec2-user/yml/stageIp.yml >> /etc/ansible/hosts
#          echo  "[docker_prod]" >> /etc/ansible/hosts
#          cat   /home/ec2-user/yml/prodIp.yml >> /etc/ansible/hosts


#    - name: echo
#      shell: |
#         echo "New Ip address in Inventory File"
#         echo "Ready to deploy App to new Ip"

#    - name: Deploying Application to New ASG Servers
#      shell: |
#         ansible-playbook -i /etc/ansible/hosts /opt/docker/ASG-container.yml
#      register: deploying

#    - debug:
#         msg: "{{ deploying.stdout }}"
        
# EOT 

# cd
# cat << EOT > /opt/docker/newrelic.yml
# ---
#  - hosts: docker_host
#    become: true
#    tasks:
#    - name: install newrelic agent
#      command: docker run \
#                      -d \
#                      --name newrelic-infra \
#                      --network=host \
#                      --cap-add=SYS_PTRACE \
#                      --privileged \
#                      --pid=host \
#                      -v "/:/host:ro" \
#                      -v "/var/run/docker.sock:/var/run/docker.sock" \
#                      -e NRIA_LICENSE_KEY=eu01xx7f52e170948bda373b5b56692bc00aNRAL \
#                      newrelic/infrastructure:latest
# EOT
sudo hostnamectl set-hostname Ansible
EOF
}

