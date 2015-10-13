-K: sudo password
-k: user password
-f: default num = 5
-i: hosts files. default path = /etc/ansible/

#------------------------------------------
# without ansible.cfg
#------------------------------------------
$ ansible-playbook  -i ./hosts -K ./deploy.xml

#------------------------------------------
# with ansible.cfg
#------------------------------------------
$ ansible-playbook ./deploy.xml
