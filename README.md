# ibmcloud-vpc-vmware-ansible

Need to update vars.yml:

1. Location of files for use
2. Location of ISO for vCenter
3. How many BMS systems. (count starts at 0).

You need to setup a IBM API Token

export IBMCLOUD_API_KEY=(your key here)
ansible-galaxy install -r requirements.yml
ansible-playbook ansibleit.yml -e vpc_region=us-south
