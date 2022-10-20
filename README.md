# ibmcloud-vpc-vmware-ansible

Need to update vars.yml:

1. Location of files for use
2. Location of ISO for vCenter
3. How many BMS systems. (count starts at 0).

ansible-playbook ansibleit.yml -e vpc_region=us-south

You need to setup a IBM API Token

export IBMCLOUD_API_KEY=(your key here)

