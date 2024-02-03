[ec2]
%{ for instance in input_list ~}
${instance}
%{ endfor ~}

[ec2:vars]
ansible_user=ec2-user 
ansible_ssh_private_key_file=/home/ec2-user/my-key.pem