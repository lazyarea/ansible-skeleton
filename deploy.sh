#!/bin/sh

#ansible-playbook -i ./hosts -K deploy.yml
ansible-playbook -i ./hosts deploy.yml
